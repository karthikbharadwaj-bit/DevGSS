import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import NAME_FIELD from '@salesforce/schema/Account.Name';
import ACCOUNTNUMBER_FIELD from '@salesforce/schema/Account.AccountNumber';

import generateSummary from '@salesforce/apex/AISummaryController.generateAccountSummary';
import logAIHEvent from '@salesforce/apex/AISummaryController.logAIHEvent';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const SUBFEATURE = 'Account Summary';

export default class AccountAISummary extends LightningElement {
    @api recordId;

    @track bulletPoints = [];
    @track activeSections = [];
    @track isLoading = false;
    hasFetched = false;
    aihViewLogged = false;

    // reaction state
    summaryIsLiked = false;
    summaryIsDisliked = false;
    likeVariant = 'border';
    dislikeVariant = 'border';
    summaryBusy = false;
    showFeedback = false;
    summaryReviewed = false;
    feedback = '';
    sendDisabled = true;
    inputError = false;
    feedbackClass = 'feedback-textarea';
    @track copyIcon = 'utility:copy';

    // identifiers for analytics payload
    acctName = '';
    acctNumber = '';

    @wire(getRecord, { recordId: '$recordId', fields: [NAME_FIELD, ACCOUNTNUMBER_FIELD] })
    wiredAccount({ data }) {
        this.acctName = data ? (getFieldValue(data, NAME_FIELD) || '') : '';
        this.acctNumber = data ? (getFieldValue(data, ACCOUNTNUMBER_FIELD) || '') : '';
    }

    get visiblePoints() {
        return this.bulletPoints;
    }

    connectedCallback() {
        // start collapsed (like Case)
        this.activeSections = [];
    }

    closeAccordion = () => {
        this.activeSections = [];
    };

    // ===== accordion open -> fetch + log view once =====
    async handleAccordionToggle(evt) {
        const opened = evt.detail.openSections || [];
        const nowOpen = opened.includes('Summary');

        if (nowOpen) {
            this._ensureViewLogged();
            if (!this.hasFetched) {
                this.isLoading = true;
                await this.fetchSummary();
            }
        }
    }

    _ensureViewLogged() {
        if (this.aihViewLogged) return;
        this.aihViewLogged = true;
        logAIHEvent({ eventType: 'aih_view', subfeature: SUBFEATURE, feedback: null })
            .catch(err => {
                // allow retry next time if logging fails
                this.aihViewLogged = false;
                // (optional) surface as debug only
                console.warn('AIH view log failed', { subfeature: SUBFEATURE, error: err?.message || err });
            });
    }

    async fetchSummary() {
        try {
            const result = await generateSummary({ recordId: this.recordId });
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

    // ===== reactions (like/dislike) =====
    async submitLike() { await this._react('aih_like', 'like'); }
    async submitDislike() { await this._react('aih_dislike', 'dislike'); }

    _applyIconVariants() {
        this.likeVariant = this.summaryIsLiked ? 'border-filled' : 'border';
        this.dislikeVariant = this.summaryIsDisliked ? 'border-filled' : 'border';
    }

    _buildReactionPayload(choice) {
        return {
            feature: 'AccountSummary',
            parentNumber: this.acctNumber || this.acctName || this.recordId,
            itemType: 'Account',              // NEW
            itemNumber: this.recordId, 
            action: choice // 'like' | 'dislike'
        };
    }

    async _react(eventType, choice) {
        const prevLiked = this.summaryIsLiked;
        const prevDisliked = this.summaryIsDisliked;

        // optimistic UI
        this.summaryIsLiked = choice === 'like';
        this.summaryIsDisliked = choice === 'dislike';
        this._applyIconVariants();

        try {
            this.summaryBusy = true;
            const payload = this._buildReactionPayload(choice);
            await logAIHEvent({
                eventType,
                subfeature: SUBFEATURE,
                feedback: JSON.stringify(payload)
            });
        } catch (err) {
            // rollback on failure
            this.summaryIsLiked = prevLiked;
            this.summaryIsDisliked = prevDisliked;
            console.warn('Failed to log Account Summary reaction', {
                eventType, choice, error: err?.message || err
            });
            this.dispatchEvent(new ShowToastEvent({
                title: 'Couldn’t save your reaction',
                message: 'Network hiccup or server issue. You can try again.',
                variant: 'info'
            }));
        } finally {
            this.summaryBusy = false;
            this._applyIconVariants();
        }
    }

    // ===== feedback =====
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

    onCancelFeedback = () => {
        this.showFeedback = false;
        this.inputError = false;
        this._updateFeedbackState();
    };

    _updateFeedbackState() {
        const canSend = !!(this.feedback && this.feedback.trim().length > 0);
        this.sendDisabled = this.summaryBusy || !canSend;
        this.feedbackClass = (this.inputError && !canSend) ? 'feedback-textarea invalid' : 'feedback-textarea';
    }

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
                feature: 'AccountSummary',
                parentNumber: this.acctNumber || this.acctName || this.recordId,
                itemType: 'Account',
                itemNumber: this.recordId, 
                reason: (this.feedback || '').trim()
            };

            await logAIHEvent({
                eventType: 'aih_feedback',
                subfeature: SUBFEATURE,
                feedback: JSON.stringify(payload)
            });

            this.summaryReviewed = true;
            this.showFeedback = false;
            this.dispatchEvent(new ShowToastEvent({
                title: 'Thank you!',
                message: 'Your feedback was submitted.',
                variant: 'success'
            }));
        } catch (err) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Could not submit feedback.',
                variant: 'error'
            }));
            console.warn('Account feedback submit failed', err?.message || err);
        } finally {
            this.summaryBusy = false;
            this._updateFeedbackState();
            this._applyIconVariants();
        }
    }

    // ===== copy (LWS workaround) =====
    async handleCopy() {
        const copyText = this.bulletPoints
            .map(point => `• ${point}`)
            .join('\n');
        const txtArea = document.createElement('textarea');
        txtArea.value = copyText;
        txtArea.style.position = 'fixed';
        txtArea.style.left = '-999999px';
        document.body.appendChild(txtArea);
        txtArea.focus();
        txtArea.select();
        try {
            document.execCommand('copy');
            this.copyIcon = 'utility:check';
            setTimeout(() => { 
                this.copyIcon = 'utility:copy'; 
            }, 2000);
        } catch (err) {
            console.error('Fallback copy failed:', err);
        }
        document.body.removeChild(txtArea);
    }
}