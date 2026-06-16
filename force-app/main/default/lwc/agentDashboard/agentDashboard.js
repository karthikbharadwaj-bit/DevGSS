import { LightningElement, track } from 'lwc';
import getBatchCasesWithInsights from '@salesforce/apex/AgentDashboardController.getBatchCasesWithInsights';
import getClosedCasesCountLastMonth from '@salesforce/apex/AgentDashboardController.getClosedCasesCountLastMonth';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import USER_ID from '@salesforce/user/Id';
import aiInsightsLogo from '@salesforce/resourceUrl/AI_Insights';
import Processing from '@salesforce/resourceUrl/Processing';

export default class AgentDashboard extends LightningElement {
    @track caseList = [];
    @track isDashboardLoading = false;
    @track currentPage = 1;
    @track pageSize = 10;
    @track totalRecords = 0;
    @track sortField = 'lastModifiedDate';
    @track sortDirection = 'DESC';
    @track allCases = [];
    @track isSectionOpen = false;
    @track closedCasesLastMonth = 0;
    @track loadingMessage = 'Processing your request';

    _tooltipVisible = false;
    _tooltipText = '';
    _tooltipStyle = '';

    aiInsightsLogo = aiInsightsLogo;
    Processing=Processing;
    hasLoadedOnce = false;
    loadingIntervalId = null;
    static LOADING_MESSAGES = ["Preparing your case insights…",
                                "Pulling in the latest case activity and updates…",
                                "Retrieving the latest analysis history and prior computations…",
                                "Securing sensitive details with advanced protection checks…",
                                "Activating Gemini to analyze sentiment and escalation insights…",
                                "Arranging everything you need into one clear, decision-ready view…",
                                "All set — explore your case insights."];
    static LOADING_INTERVAL_MS = 3900;

    get chevronIcon() {
        return this.isSectionOpen ? 'utility:chevronup' : 'utility:chevrondown';
    }

    get isContentHidden() {
        return !this.isSectionOpen;
    }

    toggleSection() {
        this.isSectionOpen = !this.isSectionOpen;
        if (this.isSectionOpen && !this.hasLoadedOnce) {
            this.hasLoadedOnce = true;
            this.loadCases();
        }
    }

    startLoadingMessages() {
        let index = 0;
        this.loadingMessage = AgentDashboard.LOADING_MESSAGES[0];
        this.loadingIntervalId = setInterval(() => {
            index = (index + 1) % AgentDashboard.LOADING_MESSAGES.length;
            this.loadingMessage = AgentDashboard.LOADING_MESSAGES[index];
        }, AgentDashboard.LOADING_INTERVAL_MS);
    }

    stopLoadingMessages() {
        if (this.loadingIntervalId) {
            clearInterval(this.loadingIntervalId);
            this.loadingIntervalId = null;
        }
    }

    async loadCases() {
        this.isDashboardLoading = true;
        this.startLoadingMessages();
        try {
            const result = await getBatchCasesWithInsights({
                userId: USER_ID
            });

            const parsed = JSON.parse(result);

            if (!parsed.success) {
                throw new Error(parsed.message || 'Failed to load cases');
            }

            this.allCases = (parsed.cases || []).map(caseItem => ({
                caseId: caseItem.caseId,
                caseNumber: caseItem.caseNumber,
                priority: caseItem.priority || 'N/A',
                priorityClass: this.getPriorityClass(caseItem.priority),
                status: caseItem.status || 'N/A',
                caseAge: this.formatCaseAge(caseItem.caseAge),
                caseAgeValue: caseItem.caseAge || 0,
                assignedDate: this.formatDate(caseItem.assignedDate),
                assignedDateValue: caseItem.assignedDate,
                sentiment: caseItem.sentiment || 'N/A',
                sentimentClass: this.getSentimentClass(caseItem.sentiment),
                sentimentReason: caseItem.sentimentReason || '',
                escalationSentiment: caseItem.escalationMetric || 'N/A',
                escalationSentimentClass: this.getEscalationSentimentClass(caseItem.escalationMetric),
                escalationReason: caseItem.escalationReason || '',
                lastModifiedByName: caseItem.lastModifiedByName || 'N/A',
                lastModifiedDate: this.formatDate(caseItem.lastModifiedDate),
                lastModifiedDateValue: caseItem.lastModifiedDate,
                recordTypeName: caseItem.recordTypeName || 'N/A',
                caseLink: `/${caseItem.caseId}`
            }));

            this.totalRecords = this.allCases.length;
            this.sortCases();
            this.updatePaginatedCases();
        } catch (error) {
            console.error('Error loading cases:', error);
            this.caseList = [];
            this.allCases = [];
            this.totalRecords = 0;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Unable to load cases with AI insights. Please try again.',
                    variant: 'error'
                })
            );
        } finally {
            this.stopLoadingMessages();
            this.isDashboardLoading = false;
            await this.loadClosedCasesCount();
        }
    }

    async loadClosedCasesCount() {
        try {
            const count = await getClosedCasesCountLastMonth({ userId: USER_ID });
            this.closedCasesLastMonth = count;
        } catch (err) {
            console.error('Error loading closed cases count:', err);
            this.closedCasesLastMonth = 0;
        }
    }

    formatCaseAge(days) {
        if (days === undefined || days === null) return 'N/A';
        return `${days} day${days === 1 ? '' : 's'}`;
    }

    formatDate(dateString) {
        if (!dateString) return 'N/A';
        try {
            const date = new Date(dateString);
            return date.toLocaleDateString('en-US', {
                year: 'numeric',
                month: 'short',
                day: 'numeric'
            });
        } catch (e) {
            return 'N/A';
        }
    }

    getSentimentClass(sentiment) {
        const basClass = 'sentiment-badge';
        if (!sentiment || sentiment === 'N/A') return `${basClass} sentiment-na`;

        const sentimentLower = sentiment.toLowerCase();
        if (sentimentLower.includes('positive')) return `${basClass} sentiment-positive`;
        if (sentimentLower.includes('negative')) return `${basClass} sentiment-negative`;
        if (sentimentLower.includes('neutral')) return `${basClass} sentiment-neutral`;

        return `${basClass} sentiment-na`;
    }

    getEscalationSentimentClass(escalationSentiment) {
        const baseClass = 'escalation-badge';
        if (!escalationSentiment || escalationSentiment === 'N/A') return `${baseClass} escalation-na`;

        const lower = String(escalationSentiment).toLowerCase();
        if (lower.includes('stable')) return `${baseClass} escalation-stable`;
        if (lower.includes('likely') || lower.includes('escalate')) return `${baseClass} escalation-likely`;

        return `${baseClass} escalation-na`;
    }

    getPriorityClass(priority) {
        if (!priority || priority === 'N/A') return 'priority-badge priority-na';
        const p = String(priority).toLowerCase();
        if (['high', 'critical', 'p0','3 – High','1 – Critical'].some(x => p.includes(x))) return 'priority-badge priority-high';
        if (['medium', 'med'].some(x => p.includes(x))) return 'priority-badge priority-medium';
        return 'priority-badge priority-low';
    }

    sortCases() {
        this.allCases.sort((a, b) => {
            let aVal = a[this.sortField];
            let bVal = b[this.sortField];

            if (this.sortField === 'caseAge') {
                aVal = a.caseAgeValue;
                bVal = b.caseAgeValue;
            } else if (this.sortField === 'assignedDate') {
                aVal = a.assignedDateValue;
                bVal = b.assignedDateValue;
            } else if (this.sortField === 'lastModifiedDate') {
                aVal = a.lastModifiedDateValue;
                bVal = b.lastModifiedDateValue;
            }

            if (aVal === bVal) return 0;
            if (aVal == null) return 1;
            if (bVal == null) return -1;

            const comparison = aVal < bVal ? -1 : 1;
            return this.sortDirection === 'ASC' ? comparison : -comparison;
        });
    }

    updatePaginatedCases() {
        const startIndex = (this.currentPage - 1) * this.pageSize;
        const endIndex = startIndex + this.pageSize;
        this.caseList = this.allCases.slice(startIndex, endIndex);
    }

    handleSort(event) {
        const field = event.currentTarget.dataset.field;

        if (this.sortField === field) {
            this.sortDirection = this.sortDirection === 'ASC' ? 'DESC' : 'ASC';
        } else {
            this.sortField = field;
            this.sortDirection = 'ASC';
        }

        this.currentPage = 1;
        this.sortCases();
        this.updatePaginatedCases();
    }

    handlePrevious() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.updatePaginatedCases();
        }
    }

    handleNext() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.updatePaginatedCases();
        }
    }

    get hasCases() {
        return this.caseList && this.caseList.length > 0;
    }

    get openCasesCount() {
        return this.totalRecords;
    }

    get highPriorityCount() {
        if (!this.allCases || !this.allCases.length) return 0;
        const highPriorities = ['high', 'critical', 'urgent', 'p0', '3 – high', '1 – critical'];
        return this.allCases.filter(
            c => c.priority && highPriorities.some(x => String(c.priority).toLowerCase().includes(x))
        ).length;
    }

    get openCasesOverOneMonthCount() {
        if (!this.allCases || !this.allCases.length) return 0;
        return this.allCases.filter(c => (c.caseAgeValue != null && c.caseAgeValue > 30)).length;
    }

    get totalPages() {
        return Math.ceil(this.totalRecords / this.pageSize);
    }

    get startRecord() {
        return this.totalRecords === 0 ? 0 : (this.currentPage - 1) * this.pageSize + 1;
    }

    get endRecord() {
        const end = this.currentPage * this.pageSize;
        return end > this.totalRecords ? this.totalRecords : end;
    }

    get isFirstPage() {
        return this.currentPage === 1;
    }

    get isLastPage() {
        return this.currentPage >= this.totalPages;
    }

    get getSortIcon() {
        return {
            caseNumber: this.getSortIconForField('caseNumber'),
            priority: this.getSortIconForField('priority'),
            status: this.getSortIconForField('status'),
            caseAge: this.getSortIconForField('caseAge'),
            assignedDate: this.getSortIconForField('assignedDate'),
            recordTypeName: this.getSortIconForField('recordTypeName'),
            sentiment: this.getSortIconForField('sentiment'),
            escalationSentiment: this.getSortIconForField('escalationSentiment'),
            lastModifiedByName: this.getSortIconForField('lastModifiedByName'),
            lastModifiedDate: this.getSortIconForField('lastModifiedDate')
        };
    }

    get getSortIconClass() {
        return {
            caseNumber: this.getSortIconClassForField('caseNumber'),
            priority: this.getSortIconClassForField('priority'),
            status: this.getSortIconClassForField('status'),
            caseAge: this.getSortIconClassForField('caseAge'),
            assignedDate: this.getSortIconClassForField('assignedDate'),
            recordTypeName: this.getSortIconClassForField('recordTypeName'),
            sentiment: this.getSortIconClassForField('sentiment'),
            escalationSentiment: this.getSortIconClassForField('escalationSentiment'),
            lastModifiedByName: this.getSortIconClassForField('lastModifiedByName'),
            lastModifiedDate: this.getSortIconClassForField('lastModifiedDate')
        };
    }

    handleReasonHover(event) {
        const reason = event.currentTarget.dataset.reason;
        if (!reason) return;

        const rect = event.currentTarget.getBoundingClientRect();
        const spaceBelow = window.innerHeight - rect.bottom;
        const spaceRight = window.innerWidth - rect.right;

        let top, bottom, left, right;

        if (spaceBelow < 120) {
            bottom = `${window.innerHeight - rect.top + 8}px`;
        } else {
            top = `${rect.bottom + 8}px`;
        }

        if (spaceRight < 300) {
            right = `${window.innerWidth - rect.right}px`;
        } else {
            left = `${rect.left}px`;
        }

        this._tooltipStyle = [
            top ? `top:${top}` : '',
            bottom ? `bottom:${bottom}` : '',
            left ? `left:${left}` : '',
            right ? `right:${right}` : ''
        ].filter(Boolean).join(';');
        this._tooltipText = reason;
        this._tooltipVisible = true;
    }

    handleReasonLeave() {
        this._tooltipVisible = false;
    }

    getSortIconForField(field) {
        if (this.sortField === field) {
            return this.sortDirection === 'ASC' ? 'utility:arrowup' : 'utility:arrowdown';
        }
        return 'utility:sort';
    }

    getSortIconClassForField(field) {
        return this.sortField === field ? 'sort-icon-active' : 'sort-icon';
    }
}