import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import CASENUMBER_FIELD from '@salesforce/schema/Case.CaseNumber';
import generateSummary from '@salesforce/apex/AISummaryController.generateCaseSummary';
import logAIHEvent from '@salesforce/apex/AISummaryController.logAIHEvent';
import getHighRiskConfig from '@salesforce/apex/CaseAIInsightsProcessor.getHighRiskConfig';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CASE_ACCOUNT_BRAND from '@salesforce/schema/Case.Account.RC_Brand__c';

export default class CaseAISummary extends LightningElement {
    @api recordId;
    @api objectApiName;

    @track bulletPoints = [];
    @track isLoading = false;
    @track likeBtnSetVisible = false;
    @track copyIcon = 'utility:copy';
    @track rawResult;

    // show/hide like Similar Cases
    @track isVisible = false;
    hasFetched = false;
    aihViewLogged = false;

    // Case number for payloads
    caseNumber = '';

    // Single-summary reaction/feedback state
    summaryIsLiked = false;
    summaryIsDisliked = false;
    likeVariant = 'border';
    dislikeVariant = 'border';
    summaryReviewed = false;
    summaryBusy = false;
    showFeedback = false;
    feedback = '';
    sendDisabled = true;
    inputError = false;
    feedbackClass = 'feedback-textarea';

    // Pull CaseNumber for analytics payloads
    caseBrand = '';

    // High Risk brand config from Custom Setting (GCP_Feature_Toggle__c)
    highRiskBrands = [];
    escalationEnabled = false;
    _configLoaded = false;

    @wire(getRecord, { recordId: '$recordId', fields: [CASENUMBER_FIELD, CASE_ACCOUNT_BRAND] })
    wiredCase({ data, error }) {
        if (data) {
            this.caseNumber = getFieldValue(data, CASENUMBER_FIELD) || '';
            this.caseBrand = getFieldValue(data, CASE_ACCOUNT_BRAND) || '';
        }
        if (error) {
            console.error('[CaseAISummary] wiredCase ERROR →', JSON.stringify(error));
        }
    }

    /**
     * Check if case brand matches any configured High Risk brands
     * AND the escalation feature is enabled for the running user.
     * Both conditions must be true to show the caseBannerAtt component.
     * Brands are configurable via GCP_Feature_Toggle__c.High_Risk_Brands__c
     * Access is controlled via GCP_Feature_Toggle__c.High_Risk_Escalation_Switch__c
     */
    get isHighRiskBrandCase() {
        if (!this.escalationEnabled) {
            return false;
        }
        const currentBrand = (this.caseBrand || '').toLowerCase();
        return this.highRiskBrands.some(configuredBrand => 
            currentBrand.includes(configuredBrand)
        );
    }

    connectedCallback() {
        this._applyIconVariants?.();
        this.loadHighRiskConfig();
    }

    /**
     * Load High Risk brands from GCP_Feature_Toggle__c Custom Setting
     */
    async loadHighRiskConfig() {
        try {
            const config = await getHighRiskConfig();
            this.escalationEnabled = config?.escalationEnabled === true;
            const brandsStr = config?.brands || '';
            this.highRiskBrands = brandsStr
                .split(',')
                .map(b => b.trim().toLowerCase())
                .filter(b => b.length > 0);
        } catch (e) {
            console.error('[CaseAISummary] Error loading High Risk config:', e);
            this.escalationEnabled = false;
            this.highRiskBrands = [];
        } finally {
            this._configLoaded = true;
        }
    }


    get visiblePoints() {
        return this.bulletPoints;
    }

    // Log view once per mount/display
    _ensureViewLogged() {
        if (this.aihViewLogged) return;
        this.aihViewLogged = true;

        logAIHEvent({ eventType: 'aih_view', subfeature: 'Case Summary', feedback: null })
            .catch(err => {
                // allow a retry on the next toggle if logging fails
                this.aihViewLogged = false;
                console.warn('AIH view log failed', {
                    subfeature: 'Case Summary',
                    error: err?.message || err
                });
            });
    }


    // called by header rows
    toggleContent = async () => {
        this.isVisible = !this.isVisible;
        if (this.isVisible && !this.hasFetched) {
            this._ensureViewLogged();
            await this.fetchSummary();
        } else if (this.isVisible) {
            this._ensureViewLogged();
        }
    };

    // allow parent (GcpTabs) to open it programmatically
    @api
    async autoExpandSummary() {
        if (!this.isVisible) {
            this.isVisible = true;
        }
        this._ensureViewLogged();
        if (!this.hasFetched) {
            await this.fetchSummary();
        }
    }

    async fetchSummary() {
        try {
            this.isLoading = true;
            const result = await generateSummary({recordId: this.recordId});
            this.rawResult = result;
            this.bulletPoints = result
                .split('\n')
                .map(line => line.trim().replace(/^[-\s]*/, ''))
                .filter(Boolean);

            this.hasFetched = true;

        } catch (_e) {
            this.bulletPoints = ['We’re having trouble loading your summary data. Please try again later.'];
        } finally {
            this.isLoading = false;
        }
    }

    // ===== Reactions (single summary) =====
    async submitLike() { await this._react('aih_like', 'like'); }
    async submitDislike() { await this._react('aih_dislike', 'dislike'); }


    _buildReactionPayload(choice) {
        return {
            feature: 'CaseSummary',
            parentNumber: this.caseNumber || '',
            action: choice                       // 'like' | 'dislike'
        };
    }

    _applyIconVariants() {
        this.likeVariant = this.summaryIsLiked ? 'border-filled' : 'border';
        this.dislikeVariant = this.summaryIsDisliked ? 'border-filled' : 'border';
    }

    async _react(eventType, choice) {
        const prevLiked = this.summaryIsLiked;
        const prevDisliked = this.summaryIsDisliked;

        this.summaryIsLiked = choice === 'like';
        this.summaryIsDisliked = choice === 'dislike';
        this._applyIconVariants();
        try {
            this.summaryBusy = true;
            const payload = this._buildReactionPayload(choice);
            await logAIHEvent({
                eventType,
                subfeature: 'Case Summary',
                feedback: JSON.stringify(payload)
            });
        } catch (err) {
            // rollback optimistic state
            this.summaryIsLiked = prevLiked;
            this.summaryIsDisliked = prevDisliked;
            console.warn('Failed to log Case Summary reaction', {
                eventType,
                choice,
                error: err?.message || err
            });
            this.dispatchEvent(new ShowToastEvent({
                title: 'Couldn’t save your reaction',
                message: 'Network hiccup or server issue. You can try again.',
                variant: 'info'
            }));
        } finally {
            this.summaryBusy = false;
        }
    }

    // ===== Feedback (single summary) =====
    _updateFeedbackState() {
        const canSend = !!(this.feedback && this.feedback.trim().length > 0);
        this.sendDisabled = this.summaryBusy || !canSend;
        this.feedbackClass = (this.inputError && !canSend) ? 'feedback-textarea invalid' : 'feedback-textarea';
    }

    toggleFeedback = () => {
        this.showFeedback = !this.showFeedback;
        this.inputError = false;
        this._updateFeedbackState();
    };

    onFeedbackChange = (e) => {
        this.feedback = e.target.value || '';
        this.inputError = false;
        this._updateFeedbackState();
    };

    onCancelFeedback = () => {
        this.showFeedback = false;
        this.inputError = false;
        this._updateFeedbackState();
    };

    onFeedbackKeydown = (e) => {
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            if (this.sendDisabled) {
                this.inputError = true;
                this._updateFeedbackState();
                return;
            }
            this.onSendFeedback();
        } else if (e.key === 'Escape') {
            e.preventDefault();
            this.onCancelFeedback();
        }
    };

    async onSendFeedback() {
        if (this.sendDisabled) {
            this.inputError = true;
            this._updateFeedbackState();
            return;
        }
        try {
            this.summaryBusy = true;
            this._updateFeedbackState();
            const payload = {
                feature: 'CaseSummary',
                parentNumber: this.caseNumber || '',
                reason: (this.feedback || '').trim()
            };
            await logAIHEvent({
                eventType: 'aih_feedback',
                subfeature: 'Case Summary',
                feedback: JSON.stringify(payload)
            });
            this.summaryReviewed = true;
            this.showFeedback = false;
            this.dispatchEvent(new ShowToastEvent({
                title: 'Thank you!',
                message: 'Your feedback was submitted.',
                variant: 'success'
            }));
        } catch {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Could not submit feedback.',
                variant: 'error'
            }));
        } finally {
            this.summaryBusy = false;
            this._updateFeedbackState();
            this._applyIconVariants();
        }
    }

    openNewWindow() {
        const summaryWindow = window.open(
            `/apex/CaseAISummaryWrapper?recordId=${this.recordId}`,
            '_blank',
            'width=1000,height=800,scrollbars=yes,resizable=yes'
        );
        if (summaryWindow) {
            summaryWindow.focus();
        } else {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Popup Blocked',
                    message: 'Please allow popups for this site to view the full summary.',
                    variant: 'warning'
                })
            );
        }
    }

    /* Since navigator.clipboard cannot be used due to LWS being disabled in org, the 
    deprecated method for copy is used here */
    async handleCopy() {
        const copyText = this.bulletPoints
            .map(point => `• ${point}`)
            .join('\n');
        const textArea = document.createElement("textarea");
        textArea.value = copyText;
        // Position textarea off-screen
        textArea.style.position = "fixed";
        textArea.style.left = "-999999px";
        document.body.appendChild(textArea);
        textArea.focus();
        textArea.select();
        try {
            document.execCommand('copy');
            this.copyIcon = 'utility:check';
            // Pause for 2 seconds before executing the next action
            setTimeout(() => {
                this.hideCopiedMsg();
            }, 2000);
        } catch (err) {
            console.error('Fallback copy failed: ', err);
        }
        document.body.removeChild(textArea);
    }

    hideCopiedMsg() {
        this.copyIcon = 'utility:copy';
    }

}