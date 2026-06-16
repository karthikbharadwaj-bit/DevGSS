/**
 * @description Support Manager Dashboard LWC.
 *              Displays team summary tiles and a workload distribution table
 *              for the logged-in manager's direct-report support agents.
 *              Clicking an agent name opens the AgentDashboardModal with
 *              that agent's cases and AI-powered insights.
 */
import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import USER_ID from '@salesforce/user/Id';
import aiInsightsLogo from '@salesforce/resourceUrl/AI_Insights';
import Processing from '@salesforce/resourceUrl/Processing';
import AgentDashboardModal from 'c/agentDashboardModal';

// Apex methods
import isManagerDashboardEnabled from '@salesforce/apex/SupportManagerDashboardController.isManagerDashboardEnabled';
import getTeamSummary from '@salesforce/apex/SupportManagerDashboardController.getTeamSummary';
import getTeamWorkload from '@salesforce/apex/SupportManagerDashboardController.getTeamWorkload';
import getBatchCasesWithInsights from '@salesforce/apex/AgentDashboardController.getBatchCasesWithInsights';

export default class SupportManagerDashboard extends LightningElement {

    // ========== Reactive Properties ==========

    /** Access control — set from GCP_Feature_Toggle__c user-level custom setting */
    isAccessEnabled = false;

    /** Team summary tile values (primitives — reactive without @track) */
    totalAgents   = 0;
    teamBacklog   = 0;
    closedCases   = 0;
    slaBreachRisk = 0;

    /** Pre-computed AI insight totals, updated once when agentList is finalised */
    aiNegativeSentimentTotal = 0;
    aiEscalationRiskTotal    = 0;

    /** Team workload table data — @track required for array-mutation reactivity */
    @track agentList = [];

    /** Loading & accordion state */
    isDashboardLoading = false;
    isSectionOpen      = false;
    loadingMessage     = 'Loading team data';

    // ========== Non-tracked Properties ==========

    aiInsightsLogo = aiInsightsLogo;
    Processing = Processing;
    hasLoadedOnce = false;
    loadingIntervalId = null;

    /** Rotating loading messages shown while data is being fetched */
    static LOADING_MESSAGES = [
        'Gathering your team data…',
        'Pulling agent workload details…',
        'Calculating team metrics…',
        'Preparing the dashboard…',
        'Almost there…'
    ];
    static LOADING_INTERVAL_MS = 2200;

    /** Max simultaneous GCP calls per batch. Keeps browser + GCP load safe at scale. */
    static INSIGHT_CHUNK_SIZE = 10;

    // ========== Lifecycle ==========

    /**
     * @description On component mount, check whether the running user has the
     *              Support Manager Dashboard Switch enabled in their custom setting record.
     *              The component renders nothing if access is not granted.
     */
    async connectedCallback() {
        try {
            this.isAccessEnabled = await isManagerDashboardEnabled();
        } catch (e) {
            this.isAccessEnabled = false;
        }
    }

    // ========== Accordion Toggle ==========

    get chevronIcon() {
        return this.isSectionOpen ? 'utility:chevronup' : 'utility:chevrondown';
    }

    get isContentHidden() {
        return !this.isSectionOpen;
    }

    /**
     * @description Toggle the accordion section.
     *              On first expand, triggers data load (lazy loading pattern).
     */
    toggleSection() {
        this.isSectionOpen = !this.isSectionOpen;
        if (this.isSectionOpen && !this.hasLoadedOnce) {
            this.hasLoadedOnce = true;
            this.loadDashboardData();
        }
    }

    // ========== Loading Messages ==========

    startLoadingMessages() {
        let index = 0;
        this.loadingMessage = SupportManagerDashboard.LOADING_MESSAGES[0];
        this.loadingIntervalId = setInterval(() => {
            index = (index + 1) % SupportManagerDashboard.LOADING_MESSAGES.length;
            this.loadingMessage = SupportManagerDashboard.LOADING_MESSAGES[index];
        }, SupportManagerDashboard.LOADING_INTERVAL_MS);
    }

    stopLoadingMessages() {
        if (this.loadingIntervalId) {
            clearInterval(this.loadingIntervalId);
            this.loadingIntervalId = null;
        }
    }

    // ========== Data Loading ==========

    /**
     * @description Loads both team summary tiles and workload table data in parallel.
     */
    async loadDashboardData() {
        this.isDashboardLoading = true;
        this.startLoadingMessages();
        try {
            // Fire both calls in parallel for better performance
            const [summaryResult, workloadResult] = await Promise.all([
                getTeamSummary({ managerId: USER_ID }),
                getTeamWorkload({ managerId: USER_ID })
            ]);

            // Process team summary tiles
            if (summaryResult) {
                this.totalAgents            = summaryResult.totalAgents            || 0;
                this.teamBacklog            = summaryResult.teamBacklog            || 0;
                this.closedCases            = summaryResult.closedCases            || 0;
                this.slaBreachRisk          = summaryResult.slaBreachRisk          || 0;
            }

            // Process team workload table
            if (workloadResult) {
                const parsed = JSON.parse(workloadResult);

                if (parsed.success) {
                    this.agentList = (parsed.agents || []).map(agent => ({
                        agentId: agent.agentId,
                        agentName: agent.agentName,
                        agentPhoto: agent.agentPhoto,
                        casesOpen: agent.casesOpen || 0,
                        casesResolved: agent.casesResolved || 0,
                        agentLink: `/${agent.agentId}`,
                        atRiskSentimentCount: null,
                        escalationRiskCount: null
                    }));
                    // Await AI insight counts so everything renders at once
                    await this.loadAgentInsightCounts();
                } else {
                    throw new Error(parsed.message || 'Failed to load team workload');
                }
            }
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Unable to load team dashboard data. Please try again.',
                    variant: 'error'
                })
            );
        } finally {
            this.stopLoadingMessages();
            this.isDashboardLoading = false;
        }
    }

    // ========== Agent AI Insight Counts ==========

    /**
     * @description Fetches GCP AI insights (sentiment + escalation) for every agent's
     *              open cases in chunks of CHUNK_SIZE, then merges per-agent counts into agentList.
     *              Chunked batching prevents overloading the browser's concurrent Apex call
     *              queue and GCP rate limits when a manager has many direct reports.
     *              Uses the existing AgentDashboardController.getBatchCasesWithInsights
     *              endpoint — no Apex or GCP changes required.
     */
    async loadAgentInsightCounts() {
        if (!this.agentList || this.agentList.length === 0) return;

        const chunkSize   = SupportManagerDashboard.INSIGHT_CHUNK_SIZE;
        const totalAgents = this.agentList.length;
        const totalChunks = Math.ceil(totalAgents / chunkSize);

        try {
            const countByAgentId = {};

            for (let i = 0; i < totalAgents; i += chunkSize) {
                const chunk       = this.agentList.slice(i, i + chunkSize);
                const chunkNumber = Math.floor(i / chunkSize) + 1;

                // Fire this chunk in parallel, await before starting the next chunk
                const chunkResults = await Promise.all(
                    chunk.map(agent =>
                        getBatchCasesWithInsights({ userId: agent.agentId })
                            .then(raw => {
                                const parsed = JSON.parse(raw || '{}');
                                const cases  = parsed.cases || [];
                                return {
                                    agentId: agent.agentId,
                                    atRiskSentimentCount: cases.filter(c =>
                                        (c.sentiment || '').toLowerCase() === 'negative'
                                    ).length,
                                    escalationRiskCount: cases.filter(c => {
                                        const esc = (c.escalationMetric || '').toLowerCase();
                                        return esc.includes('likely') || esc.includes('escalated');
                                    }).length
                                };
                            })
                            .catch(err => {
                                return { agentId: agent.agentId, atRiskSentimentCount: 0, escalationRiskCount: 0 };
                            })
                    )
                );

                chunkResults.forEach(r => { countByAgentId[r.agentId] = r; });
            }

            this.agentList = this.agentList.map(agent => ({
                ...agent,
                atRiskSentimentCount: countByAgentId[agent.agentId]?.atRiskSentimentCount ?? 0,
                escalationRiskCount:  countByAgentId[agent.agentId]?.escalationRiskCount  ?? 0
            }));

            // Compute totals once here rather than recalculating on every render via getters
            this.aiNegativeSentimentTotal = this.agentList.reduce(
                (sum, agent) => sum + (agent.atRiskSentimentCount || 0), 0
            );
            this.aiEscalationRiskTotal = this.agentList.reduce(
                (sum, agent) => sum + (agent.escalationRiskCount || 0), 0
            );
        } catch (e) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'AI Insights Unavailable',
                    message: 'Could not load sentiment and escalation counts. Please refresh to try again.',
                    variant: 'warning'
                })
            );
        }
    }

    // ========== Agent Drill-Down ==========

    /**
     * @description Opens the AgentDashboardModal for a specific agent.
     *              Passes the agentUserId and agentName so the modal
     *              loads that agent's cases (with AI insights from GCP).
     * @param {Event} event - Click event from agent name hyperlink.
     */
    async handleAgentClick(event) {
        event.preventDefault();
        const agentId   = event.currentTarget.dataset.agentId;
        const agentName = event.currentTarget.dataset.agentName;

        await AgentDashboardModal.open({
            size: 'large',
            agentUserId: agentId,
            agentName: agentName
        });
    }

    // ========== Computed Getters ==========

    /** True when the workload table has agent rows */
    get hasAgents() {
        return this.agentList && this.agentList.length > 0;
    }
}