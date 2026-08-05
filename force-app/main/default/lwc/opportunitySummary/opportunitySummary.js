import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import OPPORTUNITY_OBJECT from '@salesforce/schema/Opportunity';
import STAGE_NAME_FIELD from '@salesforce/schema/Opportunity.StageName';
import aiInsightsLogo from '@salesforce/resourceUrl/AI_Insights';
import Processing from '@salesforce/resourceUrl/Processing';
import USER_ID from '@salesforce/user/Id';
import makeGCPCallout from '@salesforce/apex/GCPCalloutForOpportunitySummary.makeGCPCallout';
import logAIHEvent from '@salesforce/apex/GCPCalloutForOpportunitySummary.logAIHEvent';
import isOpportunitySummaryEnabled from '@salesforce/apex/GCPCalloutForOpportunitySummary.isOpportunitySummaryEnabled';

const SUBFEATURE = 'Opportunity Summary';
const GENERIC_ERROR = "We're having trouble generating this summary right now. Please try again later.";
const EMPTY_MESSAGE = 'No summary is available for this opportunity yet.';

// Progress narration shown under the spinner while the Cloud Run call is in flight.
const LOADING_MESSAGES = [
    'Gathering opportunity details and stage history…',
    'Reviewing recent activities, tasks, and meetings…',
    'Mapping the buying group and stakeholder engagement…',
    'Checking related cases and prior opportunities on this account…',
    'Securing sensitive details with advanced protection checks…',
    'Activating Gemini to score deal health, risks, and win factors…',
    'Shaping your next best actions and close plan…',
    'Almost there — assembling your decision-ready summary.'
];
const LOADING_INTERVAL_MS = 3900;

// Circumference of the gauge arc (2 * PI * r) for the r=42 circle in the template.
const GAUGE_CIRCUMFERENCE = 264;
const CLOCK_INTERVAL_MS = 60000;

// A leading "Label: value" prefix is only treated as a label when it is short
// enough to read as one; longer prefixes are almost always prose.
const LABEL_MAX_LENGTH = 42;

const HEALTH_VARIANTS = [
    { pattern: /(at risk|off track|critical|poor|weak|unhealthy|low)/i, variant: 'risk' },
    { pattern: /(healthy|strong|excellent|on track|good|high)/i, variant: 'success' },
    { pattern: /(moderate|medium|fair|watch|caution)/i, variant: 'warning' }
];

function normalizeTitle(title) {
    return String(title || '')
        .toLowerCase()
        .replace(/&/g, 'and')
        .replace(/[^a-z0-9 ]/g, ' ')
        .replace(/\s+/g, ' ')
        .trim();
}

// Maps a section heading coming back from the model onto the panel that renders it.
function bucketFor(title) {
    const normalized = normalizeTitle(title);
    if (!normalized) {
        return null;
    }
    if (normalized.includes('deal score')) {
        return 'score';
    }
    if (normalized.includes('win factor')) {
        return 'win';
    }
    if (normalized.includes('risk')) {
        return 'risk';
    }
    if (normalized.includes('next best action')) {
        return 'actions';
    }
    if (normalized.includes('close plan')) {
        return 'plan';
    }
    if (normalized.includes('stage journey') || normalized.includes('history')) {
        return 'history';
    }
    if (normalized.includes('executive summary')) {
        return 'executive';
    }
    return null;
}

function toStrings(value) {
    const list = Array.isArray(value) ? value : value == null ? [] : [value];
    return list.map((item) => (item == null ? '' : String(item)).trim()).filter(Boolean);
}

export function splitLabel(text) {
    let delimiter = ':';
    let separatorIndex = text.indexOf(delimiter);

    if (separatorIndex <= 0 || separatorIndex > LABEL_MAX_LENGTH) {
        delimiter = '—';
        separatorIndex = text.indexOf(delimiter);
    }

    if (separatorIndex > 0 && separatorIndex <= LABEL_MAX_LENGTH) {
        const label = text.slice(0, separatorIndex).trim();
        const remainder = text.slice(separatorIndex + delimiter.length).trim();
        if (label && remainder && !label.includes('.')) {
            return { label, text: remainder, hasLabel: true };
        }
    }
    return { label: '', text, hasLabel: false };
}

function healthVariant(label) {
    const match = HEALTH_VARIANTS.find((entry) => entry.pattern.test(label));
    return match ? match.variant : 'info';
}

export default class OpportunitySummary extends LightningElement {
    Processing = Processing;
    @api recordId;

    aiInsightsLogo = aiInsightsLogo;
    loggedInUserId = USER_ID;

    isFeatureEnabled = false;
    isModalOpen = false;
    isLoading = false;
    isError = false;
    errorMessage = '';
    hasFetched = false;
    aihViewLogged = false;

    scoreCard = null;
    executiveFacts = [];
    winFactors = [];
    riskFlags = [];
    nextActions = [];
    closePlan = [];
    history = [];
    extraSections = [];

    generatedAt = null;
    generatedLabel = '';
    loadingMessage = LOADING_MESSAGES[0];

    stageOptions = [];
    currentStage = null;

    _clockId = null;
    _loadingMessageId = null;
    _escapeHandler = null;

    connectedCallback() {
        isOpportunitySummaryEnabled()
            .then((enabled) => {
                this.isFeatureEnabled = enabled === true;
            })
            .catch(() => {
                this.isFeatureEnabled = false;
            });
    }

    @wire(getRecord, { recordId: '$recordId', fields: [STAGE_NAME_FIELD] })
    wiredOpportunity({ data }) {
        if (data) {
            this.currentStage = getFieldValue(data, STAGE_NAME_FIELD);
        }
    }

    @wire(getObjectInfo, { objectApiName: OPPORTUNITY_OBJECT })
    opportunityInfo;

    @wire(getPicklistValues, {
        recordTypeId: '$opportunityInfo.data.defaultRecordTypeId',
        fieldApiName: STAGE_NAME_FIELD
    })
    wiredStages({ data }) {
        if (data) {
            this.stageOptions = data.values.map((entry) => ({
                label: entry.label,
                value: entry.value
            }));
        }
    }

    get hasContent() {
        return Boolean(
            this.scoreCard ||
                this.executiveFacts.length ||
                this.winFactors.length ||
                this.riskFlags.length ||
                this.nextActions.length ||
                this.closePlan.length ||
                this.history.length ||
                this.extraSections.length
        );
    }

    get showEmptyState() {
        return !this.isLoading && !this.isError && !this.hasContent;
    }

    get emptyMessage() {
        return EMPTY_MESSAGE;
    }

    get hasInsightColumn() {
        return Boolean(this.winFactors.length || this.riskFlags.length);
    }

    get stageTrail() {
        if (!this.stageOptions.length) {
            return [];
        }

        // Without the record's stage the rail would render as a row of
        // indistinguishable grey chips, so wait until it resolves.
        const currentIndex = this.stageOptions.findIndex((stage) => stage.value === this.currentStage);
        if (currentIndex === -1) {
            return [];
        }

        return this.stageOptions.map((stage, index) => {
            const isComplete = index < currentIndex;
            const isCurrent = index === currentIndex;
            let modifier = ' is-upcoming';
            if (isComplete) {
                modifier = ' is-complete';
            } else if (isCurrent) {
                modifier = ' is-current';
            }

            return {
                key: `stage-${index}`,
                label: stage.label,
                showCheck: isComplete,
                chipClass: `stage-chip${modifier}`
            };
        });
    }

    get hasStageTrail() {
        return this.stageTrail.length > 0;
    }

    disconnectedCallback() {
        this._stopClock();
        this._stopLoadingMessages();
        this._unbindEscape();
    }

    openModal() {
        this.isModalOpen = true;
        this._logView();
        this._bindEscape();
        this._startClock();

        if (!this.hasFetched) {
            this.fetchSummary();
        }
    }

    closeModal() {
        this.isModalOpen = false;
        this._stopClock();
        this._unbindEscape();
    }

    handleShowKeydown(event) {
        if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            this.openModal();
        }
    }

    async fetchSummary() {
        if (!this.recordId) {
            this.isError = true;
            this.errorMessage = 'No opportunity record is available.';
            return;
        }

        this.isLoading = true;
        this.isError = false;
        this.errorMessage = '';
        this._resetSections();
        this._startLoadingMessages();

        try {
            const result = await makeGCPCallout({
                userId: this.loggedInUserId,
                recordId: this.recordId
            });

            let parsed;
            try {
                parsed = JSON.parse(result);
            } catch (e) {
                this.isError = true;
                this.errorMessage = GENERIC_ERROR;
                return;
            }

            if (parsed && parsed.success === true && Array.isArray(parsed.cards)) {
                this._buildSections(parsed.cards);
                this.hasFetched = true;
                this.generatedAt = Date.now();
                this._updateGeneratedLabel();
            } else if (parsed && parsed.success === false && parsed.message) {
                this.isError = true;
                this.errorMessage = parsed.message;
            } else {
                this.isError = true;
                this.errorMessage = GENERIC_ERROR;
            }
        } catch (error) {
            this.isError = true;
            this.errorMessage = (error && error.body && error.body.message) || GENERIC_ERROR;
        } finally {
            this._stopLoadingMessages();
            this.isLoading = false;
        }
    }

    _resetSections() {
        this.scoreCard = null;
        this.executiveFacts = [];
        this.winFactors = [];
        this.riskFlags = [];
        this.nextActions = [];
        this.closePlan = [];
        this.history = [];
        this.extraSections = [];
        this.generatedAt = null;
        this.generatedLabel = '';
    }

    _buildSections(rawCards) {
        this._resetSections();

        rawCards.forEach((raw, index) => {
            if (!raw || typeof raw !== 'object') {
                return;
            }

            const title = raw.title || raw.heading || raw.name || '';
            const items = toStrings(raw.items || raw.points || raw.bullets);
            const badge = (raw.badge || raw.label || '').toString().trim();

            switch (bucketFor(title)) {
                case 'score':
                    this.scoreCard = this._buildScoreCard(badge, items);
                    break;
                case 'executive':
                    this.executiveFacts = items.map((text, i) => ({
                        key: `fact-${i}`,
                        ...splitLabel(text)
                    }));
                    break;
                case 'win':
                    this.winFactors = items.map((text, i) => ({ key: `win-${i}`, text }));
                    break;
                case 'risk':
                    this.riskFlags = items.map((text, i) => ({ key: `risk-${i}`, text }));
                    break;
                case 'actions':
                    this.nextActions = items.map((text, i) => ({
                        key: `action-${i}`,
                        number: i + 1,
                        text
                    }));
                    break;
                case 'plan':
                    this.closePlan = items.map((text, i) => ({
                        key: `plan-${i}`,
                        ...splitLabel(text)
                    }));
                    break;
                case 'history':
                    this.history = items.map((text, i) => ({ key: `history-${i}`, text }));
                    break;
                default:
                    if (title || items.length) {
                        this.extraSections = [
                            ...this.extraSections,
                            {
                                key: `extra-${index}`,
                                title,
                                items: items.map((text, i) => ({ key: `extra-${index}-${i}`, text }))
                            }
                        ];
                    }
            }
        });
    }

    // The score arrives as free text such as "76/100 (Healthy)", with the
    // headline in either the badge or the first bullet depending on the payload.
    _buildScoreCard(badge, items) {
        const headline = badge || items[0] || '';
        const notes = badge ? items : items.slice(1);

        const scoreMatch = /(\d+(?:\.\d+)?)\s*\/\s*(\d+(?:\.\d+)?)/.exec(headline);
        const labelMatch = /\(([^)]+)\)/.exec(headline);
        const healthLabel = labelMatch ? labelMatch[1].trim() : '';
        const variant = healthVariant(healthLabel || headline);

        const value = scoreMatch ? Number(scoreMatch[1]) : null;
        const max = scoreMatch ? Number(scoreMatch[2]) : 100;
        const ratio = value !== null && max > 0 ? Math.min(Math.max(value / max, 0), 1) : 0;

        return {
            hasValue: value !== null,
            headline,
            value,
            max,
            healthLabel,
            hasHealthLabel: Boolean(healthLabel),
            healthClass: `health-pill health-pill_${variant}`,
            gaugeClass: `gauge-value gauge-value_${variant}`,
            dashArray: GAUGE_CIRCUMFERENCE,
            dashOffset: GAUGE_CIRCUMFERENCE * (1 - ratio),
            notes: notes.map((text, i) => ({ key: `score-note-${i}`, text }))
        };
    }

    _updateGeneratedLabel() {
        if (!this.generatedAt) {
            this.generatedLabel = '';
            return;
        }

        const minutes = Math.floor((Date.now() - this.generatedAt) / 60000);
        if (minutes < 1) {
            this.generatedLabel = 'Generated just now';
        } else if (minutes < 60) {
            this.generatedLabel = `Generated ${minutes} minute${minutes === 1 ? '' : 's'} ago`;
        } else {
            const hours = Math.floor(minutes / 60);
            this.generatedLabel = `Generated ${hours} hour${hours === 1 ? '' : 's'} ago`;
        }
    }

    // Steps through the narration once and holds on the last line, rather than
    // looping, so a slow callout never appears to restart from the beginning.
    _startLoadingMessages() {
        this._stopLoadingMessages();

        let index = 0;
        this.loadingMessage = LOADING_MESSAGES[0];
        this._loadingMessageId = setInterval(() => {
            index += 1;
            this.loadingMessage = LOADING_MESSAGES[index];
            if (index >= LOADING_MESSAGES.length - 1) {
                this._stopLoadingMessages();
            }
        }, LOADING_INTERVAL_MS);
    }

    _stopLoadingMessages() {
        if (this._loadingMessageId) {
            clearInterval(this._loadingMessageId);
            this._loadingMessageId = null;
        }
    }

    _startClock() {
        if (this._clockId) {
            return;
        }
        this._clockId = setInterval(() => this._updateGeneratedLabel(), CLOCK_INTERVAL_MS);
    }

    _stopClock() {
        if (this._clockId) {
            clearInterval(this._clockId);
            this._clockId = null;
        }
    }

    _bindEscape() {
        if (this._escapeHandler) {
            return;
        }
        this._escapeHandler = (event) => {
            if (event.key === 'Escape') {
                this.closeModal();
            }
        };
        document.addEventListener('keydown', this._escapeHandler);
    }

    _unbindEscape() {
        if (this._escapeHandler) {
            document.removeEventListener('keydown', this._escapeHandler);
            this._escapeHandler = null;
        }
    }

    _logView() {
        if (this.aihViewLogged) {
            return;
        }
        this.aihViewLogged = true;
        logAIHEvent({ eventType: 'aih_view', subfeature: SUBFEATURE, feedback: null }).catch(() => {
            this.aihViewLogged = false;
        });
    }
}