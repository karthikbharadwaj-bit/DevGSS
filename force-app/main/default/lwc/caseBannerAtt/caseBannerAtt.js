import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import hasSupportAgent from '@salesforce/customPermission/Support_Agent_AI_GCP';
import USER_ID from '@salesforce/user/Id';

import identifyCaseSentimentEscalation
    from '@salesforce/apex/CaseAIInsightsProcessor.identifyCaseSentimentEscalation';
import getSlaStatus
    from '@salesforce/apex/CaseAIInsightsProcessor.getSlaStatus';
import getHighRiskConfig
    from '@salesforce/apex/CaseAIInsightsProcessor.getHighRiskConfig';
import checkEscalateClickAccess
    from '@salesforce/apex/CaseAIInsightsProcessor.checkEscalateClickAccess';
import getAccountMrrInCorporateCurrency
    from '@salesforce/apex/CaseAIInsightsProcessor.getAccountMrrInCorporateCurrency';

import CASE_CREATED from '@salesforce/schema/Case.CreatedDate';
import CASE_IS_CLOSED from '@salesforce/schema/Case.IsClosed';
import CASE_STATUS from '@salesforce/schema/Case.Status';

// Brand field
import CASE_ACCOUNT_BRAND from '@salesforce/schema/Case.Account.RC_Brand__c';

// High Risk criteria field - MRR from Account (Severity removed - GCP AI already factors it in)
import CASE_MRR from '@salesforce/schema/Case.Account.MRR__c';

import sendHighRiskEmail from '@salesforce/apex/CaseHighRiskEmailController.sendHighRiskEmail';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const FIELDS = [CASE_CREATED, CASE_IS_CLOSED, CASE_STATUS, CASE_ACCOUNT_BRAND, CASE_MRR];

export default class CaseBannerAtt extends LightningElement {
    @api recordId;
    @api maxWidth = '760px';
    @api align = 'center';

    get shellStyle() {
        return `max-width:${this.maxWidth}; margin:${this.align === 'left' ? '0' : '0 auto'};`;
    }

    hasSupportAgent = hasSupportAgent;

    // base case info
    createdDateISO = null;
    isClosed = null;
    status = null;
    brand = '';
    
    // High Risk criteria fields
    accountMrr = 0;            // Raw MRR in Account's local currency (for display)
    accountMrrUsd = 0;         // MRR normalized to corporate currency / USD (for threshold comparison)
    _mrrUsdLoaded = false;
    
    // High Risk config from Custom Setting (GCP_Feature_Toggle__c)
    mrrThreshold = 500;              // Default, will be overwritten by config
    highRiskBrands = [];             // Array of brand names from config
    _configLoaded = false;
    
    // SLA status (from Apex call)
    hasMilestones = false;  // true if case has an SLA entitlement process
    slaViolated = false;    // true if any milestone is violated
    _slaLoaded = false;

    // GCP data
    _requestedGcp = false;
    gcpLoaded = false;

    // Escalate button click access (from Apex — dynamic field path resolution)
    _canClickEscalate = false;
    _clickAccessLoaded = false;

    // Email sending state
    sendingEmail = false;
    emailSent = false;  // Dedupe: true after successful send

    // Inline toast fallback (for VF page / Lightning Out where ShowToastEvent is unsupported)
    inlineToastVisible = false;
    inlineToastMessage = '';
    inlineToastVariant = 'success';  // 'success' | 'error'
    _toastTimer = null;

    gcpSentiment;
    gcpSentimentReason;
    gcpSentimentError;

    gcpEscMetric;
    gcpEscReason;
    gcpEscError;

    /**
     * Load High Risk configuration on component initialization
     */
    connectedCallback() {
        this.loadHighRiskConfig();
    }

    /**
     * Load High Risk configuration from GCP_Feature_Toggle__c Custom Setting.
     * Fetches configurable brands and MRR threshold.
     */
    async loadHighRiskConfig() {
        try {
            const config = await getHighRiskConfig();
            
            // Parse MRR threshold (default to 500 if not set)
            this.mrrThreshold = config?.mrrThreshold || 500;
            
            // Parse brands (comma-separated string to array)
            const brandsStr = config?.brands || '';
            this.highRiskBrands = brandsStr
                .split(',')
                .map(b => b.trim().toLowerCase())
                .filter(b => b.length > 0);
                
        } catch (e) {
            console.error('[CaseBannerAtt] Error loading High Risk config:', e);
            // Use defaults on error - empty brands array lets config determine eligibility
            this.mrrThreshold = 500;
            this.highRiskBrands = [];
        } finally {
            this._configLoaded = true;
            this.maybeLoadGcp();
            this.maybeLoadSlaStatus();
            this.maybeLoadClickAccess();
            this.maybeLoadMrrUsd();
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredCase({ data, error }) {
        if (data) {
            this.createdDateISO = getFieldValue(data, CASE_CREATED) || null;
            this.isClosed = getFieldValue(data, CASE_IS_CLOSED);
            this.status = getFieldValue(data, CASE_STATUS);
            this.brand = getFieldValue(data, CASE_ACCOUNT_BRAND) || '';
            
            // High Risk criteria field
            this.accountMrr = getFieldValue(data, CASE_MRR) || 0;

            this.maybeLoadGcp();
            this.maybeLoadSlaStatus();
            this.maybeLoadClickAccess();
            this.maybeLoadMrrUsd();
        } else if (error) {
            console.error('[CaseBannerAtt] Error loading case record:', error);
            this.isClosed = true; // hide safely
            this.brand = '';     // reset brand to prevent stale data
        }
    }

    /**
     * Check if current case brand matches any configured High Risk brands.
     * Brands are configurable via GCP_Feature_Toggle__c.High_Risk_Brands__c
     */
    get isHighRiskBrand() {
        const currentBrand = (this.brand || '').toLowerCase();
        // Check if current brand contains any of the configured high risk brands
        return this.highRiskBrands.some(configuredBrand => 
            currentBrand.includes(configuredBrand)
        );
    }

    /**
     * Show this banner ONLY for:
     * - User has Support Agent AI permission
     * - Case is not closed
     * - Case brand matches configured High Risk brands
     */
    get shouldShow() {
        const isResolved = this.status === 'Resolved';
        return this.hasSupportAgent && this.isClosed === false && !isResolved && this.isHighRiskBrand;
    }

    get waitingGcp() {
        return this.shouldShow && (!this.gcpLoaded || !this._slaLoaded || !this._configLoaded || !this._mrrUsdLoaded);
    }

    /**
     * High Risk Button Visibility — criteria:
     * 1. AI Sentiment = Negative OR Neutral
     * 2. AI Escalation Insight = Likely to Escalate OR Escalated
     * 3. MRR >= threshold (configurable via Custom Setting)
     * 4. SLA Violated — ONLY required if the case has an SLA entitlement
     *    process (i.e. CaseMilestone records exist). If no milestones exist,
     *    the SLA check is skipped and criteria 1-3 are sufficient.
     */
    get showHighRiskButton() {
        if (!this.gcpLoaded || !this._slaLoaded || !this._configLoaded || !this._mrrUsdLoaded) {
            return false;
        }
        
        const sentimentMatch = ['negative', 'neutral'].includes((this.gcpSentiment || '').toLowerCase());
        
        const esc = (this.gcpEscMetric || '').toLowerCase();
        const escalationRisky = esc.includes('likely') || esc.includes('escalated');
        
        const mrrOk = (this.accountMrrUsd || 0) >= this.mrrThreshold;
        
        const slaOk = !this.hasMilestones || this.slaViolated;

        return sentimentMatch && escalationRisky && mrrOk && slaOk;
    }

    /**
     * Criteria checklist tooltip for High Risk button explanation.
     * Shows which criteria are met with checkmarks.
     * SLA line adapts based on whether milestones exist for the case.
     */
    get highRiskCriteriaTooltip() {
        const sentiment = (this.gcpSentiment || '').toLowerCase();
        const esc = (this.gcpEscMetric || '').toLowerCase();
        
        const sentimentOk = ['negative', 'neutral'].includes(sentiment);
        const escalationOk = esc.includes('likely') || esc.includes('escalated');
        const mrrUsd = this.accountMrrUsd || 0;
        const mrrOk = mrrUsd >= this.mrrThreshold;
        
        const check = '✅';
        const cross = '❌';
        
        const mrrDisplay = `MRR ≥ $${this.mrrThreshold} (USD $${Math.round(mrrUsd)})`;
        const lines = [
            `${sentimentOk ? check : cross} Negative / Neutral sentiment (AI)`,
            `${escalationOk ? check : cross} Likely to Escalate / Escalated (AI)`,
            `${mrrOk ? check : cross} ${mrrDisplay}`
        ];

        if (this.hasMilestones) {
            lines.push(`${this.slaViolated ? check : cross} SLA violated`);
        } else {
            lines.push(`➖ SLA (no entitlement process)`);
        }

        return lines.join('\n');
    }

    get bannerGridClass() {
        return 'case-banner-grid';
    }

    maybeLoadGcp() {
        if (this.shouldShow && !this._requestedGcp) {
            this._requestedGcp = true;
            this.loadGcpMetrics();
        }
    }

    /**
     * Load SLA milestone status for High Risk calculation.
     * Determines if the case has an SLA process and if any milestone is violated.
     */
    async maybeLoadSlaStatus() {
        if (!this.shouldShow || this._slaLoaded) {
            return;
        }
        try {
            const status = await getSlaStatus({ caseId: this.recordId });
            this.hasMilestones = status?.hasMilestones === true;
            this.slaViolated = status?.isViolated === true;
        } catch (e) {
            console.error('[CaseBannerAtt] Error loading SLA status:', e);
            this.hasMilestones = false;
            this.slaViolated = false;
        } finally {
            this._slaLoaded = true;
        }
    }

    /**
     * Check if logged-in user is allowed to click the Escalate button.
     * Delegates to Apex which dynamically resolves configured Case field paths
     * (e.g. OwnerId, Owner.ManagerId) and compares against the running user.
     */
    async maybeLoadClickAccess() {
        if (!this.shouldShow || this._clickAccessLoaded) {
            return;
        }
        try {
            this._canClickEscalate = await checkEscalateClickAccess({ caseId: this.recordId });
        } catch (e) {
            console.error('[CaseBannerAtt] Error checking escalate click access:', e);
            this._canClickEscalate = false;
        } finally {
            this._clickAccessLoaded = true;
        }
    }

    /**
     * Load MRR value normalized to corporate currency (USD) from Apex.
     * Uses CurrencyType.ConversionRate to convert from Account's local currency.
     */
    async maybeLoadMrrUsd() {
        if (!this.shouldShow || this._mrrUsdLoaded) {
            return;
        }
        try {
            this.accountMrrUsd = await getAccountMrrInCorporateCurrency({ caseId: this.recordId });
        } catch (e) {
            console.error('[CaseBannerAtt] Error loading MRR in corporate currency:', e);
            this.accountMrrUsd = this.accountMrr || 0;
        } finally {
            this._mrrUsdLoaded = true;
        }
    }

    async loadGcpMetrics() {
        try {
            const raw = await identifyCaseSentimentEscalation({ userId: USER_ID, caseId: this.recordId });
            
            // Safe JSON parse with validation
            let res = {};
            try {
                res = JSON.parse(raw || '{}') || {};
            } catch (parseError) {
                console.error('[CaseBannerAtt] Failed to parse GCP response:', parseError, raw);
                this.gcpSentimentError = 'Unable to process AI response. Please try again later.';
                this.gcpEscError = 'Unable to process AI response. Please try again later.';
                return;
            }

            // --- Sentiment (api1) ---
            if (res.sentiment) {
                this.gcpSentiment = res.sentiment;
                this.gcpSentimentReason = res.sentiment_reason || '';
            } else if (res.sentiment_error) {
                console.error('Sentiment API error:', res.sentiment_error);
                this.gcpSentimentError = 'We are facing a temporary issue retrieving sentiment insights. Please try again later.';
            } else if (res.api1_result && res.api1_result.body) {
                try {
                    const api1Body = typeof res.api1_result.body === 'string'
                        ? JSON.parse(res.api1_result.body)
                        : res.api1_result.body;

                    if (api1Body.error || api1Body.details) {
                        console.error('Sentiment API error details:', api1Body);
                        this.gcpSentimentError = 'We are facing a temporary issue retrieving sentiment insights. Please try again later.';
                    }
                } catch (parseErr) {
                    console.error('Failed to parse sentiment error body:', res.api1_result.body);
                    this.gcpSentimentError = 'Sentiment insights unavailable. Please try again later.';
                }
            }

            // --- Escalation (api2) ---
            if (res.escalation_metric) {
                this.gcpEscMetric = res.escalation_metric;
                this.gcpEscReason = res.escalation_reason || '';
            } else if (res.api2_result && res.api2_result.body) {
                try {
                    const api2Body = typeof res.api2_result.body === 'string'
                        ? JSON.parse(res.api2_result.body)
                        : res.api2_result.body;

                    if (api2Body.error || api2Body.details) {
                        console.error('Escalation API error details:', api2Body);
                        this.gcpEscError = 'We are facing a temporary issue retrieving escalation insights. Please try again later.';
                    } 
                } catch (parseErr) {
                    console.error('Failed to parse escalation body:', res.api2_result.body);
                    this.gcpEscError = 'Escalation insights unavailable. Please try again later.';
                }
            }

            // --- Back-compat: {success:false,message} ---
            if (!this.gcpSentiment && !this.gcpEscMetric && res.success === false && res.message) {
                console.error('Legacy Apex error:', res.message);
                const msg = 'We are facing a temporary issue retrieving insights. Please try again later.';
                this.gcpSentimentError = this.gcpSentimentError || msg;
                this.gcpEscError = this.gcpEscError || msg;
            }

        } catch (e) {
            console.error('Hard failure loading GCP metrics:', e);
            const msg = 'AI service is currently unavailable. Please try again later.';
            this.gcpSentimentError = this.gcpSentimentError || msg;
            this.gcpEscError = this.gcpEscError || msg;
        } finally {
            this.gcpLoaded = true;
        }
    }

    /* age */
    get caseAgeLabel() {
        if (this.createdDateISO) {
            const days = this.daysBetween(new Date(this.createdDateISO), new Date());
            return `${days} day${days === 1 ? '' : 's'}`;
        }
        return '—';
    }

    daysBetween(s, e) {
        try {
            return Math.floor(Math.max(0, e - s) / 86400000);
        } catch {
            return 0;
        }
    }

    /* sentiment getters */
    get hasSentiment() { return !!this.gcpSentiment; }
    get sentimentLabel() { return this.gcpSentiment || '—'; }
    get sentimentReason() { return this.gcpSentiment ? (this.gcpSentimentReason || '') : ''; }
    get sentimentError() { return !this.gcpSentiment ? (this.gcpSentimentError || 'Sentiment insights unavailable.') : ''; }
    get sentimentClass() { return `sentiment-pill ${(this.gcpSentiment || '').toLowerCase()}`; }

    /* escalation getters */
    get hasEscalation() { return !!this.gcpEscMetric; }
    get escalationLabel() { return this.gcpEscMetric || '—'; }
    get escalationReason() { return this.gcpEscMetric ? (this.gcpEscReason || '') : ''; }
    get escalationError() { return !this.gcpEscMetric ? (this.gcpEscError || `We're facing a temporary issue retrieving escalation insights. Please try again later.`) : ''; }

    get escalationClass() {
        const v = (this.gcpEscMetric || '').toLowerCase();
        let tone = '';
        if (v.includes('escalated')) tone = 'escalated';
        else if (v.includes('likely')) tone = 'likely';
        else if (v.includes('stable')) tone = 'stable';
        return `escalation-pill ${tone}`.trim();
    }

    /**
     * Disable button when:
     * - Email is being sent (in-flight)
     * - Email already sent (dedupe)
     * - User does not have click access (not Case Owner or Owner's Manager per config)
     */
    get highRiskButtonDisabled() {
        return this.sendingEmail || this.emailSent || !this._canClickEscalate;
    }

    /**
     * Tooltip for the Escalate button — shows reason when disabled due to access.
     */
    get escalateButtonTooltip() {
        if (!this._canClickEscalate) {
            return 'Only the Case Owner or their Manager can escalate this case.';
        }
        if (this.emailSent) {
            return 'Escalation email already sent for this case.';
        }
        return 'Click to send high risk escalation email.';
    }

    /**
     * Build escalation reasons summary for the email body.
     * Includes the 4 High Risk criteria with their AI-generated reason details
     * and an AI disclaimer for business transparency.
     */
    _buildEscalationReasons() {
        const sentiment = (this.gcpSentiment || '').toLowerCase();
        const esc = (this.gcpEscMetric || '').toLowerCase();

        const sentimentOk = ['negative', 'neutral'].includes(sentiment);
        const escalationOk = esc.includes('likely') || esc.includes('escalated');
        const mrrUsd = this.accountMrrUsd || 0;
        const mrrOk = mrrUsd >= this.mrrThreshold;
        const slaOk = this.slaViolated === true;

        const check = '✅';
        const cross = '❌';

        const lines = [];

        const sentimentDetail = this.gcpSentimentReason ? ` — ${this.gcpSentimentReason}` : '';
        lines.push(`${sentimentOk ? check : cross} Negative / Neutral sentiment (AI)${sentimentDetail}`);

        const escLabel = this.gcpEscMetric || 'Unknown';
        const escDetail = this.gcpEscReason ? ` — ${this.gcpEscReason}` : '';
        lines.push(`${escalationOk ? check : cross} ${escLabel} (AI)${escDetail}`);

        lines.push(`${mrrOk ? check : cross} MRR ≥ $${this.mrrThreshold} (USD $${Math.round(mrrUsd)})`);

        // 4. SLA — contextual based on whether milestones exist
        if (this.hasMilestones) {
            lines.push(`${this.slaViolated ? check : cross} SLA violated`);
        } else {
            lines.push(`➖ SLA (no entitlement process — not applicable)`);
        }

        const reasons = lines.join('\n');

        // AI disclaimer — agreed-upon text for business transparency
        const disclaimer =
            '\n\n⚠ Disclaimer: The insights above are AI generated. ' +
            'Please review the case details before taking action.';

        return reasons + disclaimer;
    }

    /**
     * High Risk button click handler - sends escalation email.
     * Passes AI-generated escalation reasons to include in the email body.
     * Uses ShowToastEvent (Lightning Experience) or inline toast (VF page).
     */
    async handleHighRiskClick() {
        this.sendingEmail = true;
        try {
            const escalationReasons = this._buildEscalationReasons();
            await sendHighRiskEmail({
                caseId: this.recordId,
                escalationReasons: escalationReasons
            });
            this.emailSent = true;  // Dedupe: prevent multiple sends
            this._notify('success', 'Email sent', 'High risk escalation email sent successfully.');
        } catch (err) {
            const msg = err?.body?.message || 'Unable to send escalation email.';
            this._notify('error', 'Email failed', msg);
        } finally {
            this.sendingEmail = false;
        }
    }

    /**
     * Show notification — platform toast in Lightning Experience,
     * inline toast in VF page / Lightning Out (Explore More popup).
     * Detects context via URL so only ONE notification style is shown.
     */
    _notify(variant, title, message) {
        const isVfPage = window.location.pathname.includes('/apex/');

        if (!isVfPage) {
            // Lightning Experience — use standard platform toast
            this.dispatchEvent(
                new ShowToastEvent({ title, message, variant })
            );
        } else {
            // VF page / Lightning Out — use inline toast (auto-dismisses after 4s)
            this.inlineToastMessage = `${title}: ${message}`;
            this.inlineToastVariant = variant;
            this.inlineToastVisible = true;

            if (this._toastTimer) {
                clearTimeout(this._toastTimer);
            }
            this._toastTimer = setTimeout(() => {
                this.inlineToastVisible = false;
                this._toastTimer = null;
            }, 4000);
        }
    }

    /**
     * Dismiss inline toast manually (close button)
     */
    dismissInlineToast() {
        this.inlineToastVisible = false;
        if (this._toastTimer) {
            clearTimeout(this._toastTimer);
            this._toastTimer = null;
        }
    }

    get inlineToastClass() {
        return `inline-toast inline-toast-${this.inlineToastVariant}`;
    }

    get inlineToastIconName() {
        return this.inlineToastVariant === 'success'
            ? 'utility:success'
            : 'utility:error';
    }
}