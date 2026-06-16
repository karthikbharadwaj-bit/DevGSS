import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import OPP_NAME from '@salesforce/schema/Opportunity.Name';

import generateSummary from '@salesforce/apex/AISummaryController.generateOpptySummary';
import logAIHEvent from '@salesforce/apex/AISummaryController.logAIHEvent';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const SUBFEATURE = 'Opportunity Summary';

export default class OpportunityAISummary extends LightningElement {
    @api recordId;

    @track bulletPoints = [];
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
    oppName = '';

    @wire(getRecord, { recordId: '$recordId', fields: [OPP_NAME] })
    wiredOpp({ data }) {
        this.oppName = data ? (getFieldValue(data, OPP_NAME) || '') : '';
    }

    get visiblePoints() {
        return this.bulletPoints;
    }

    closeAccordion = () => {
        // collapses the only section
        this.template.querySelector('lightning-accordion').activeSectionName = [];
    };

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
            .catch(() => { this.aihViewLogged = false; });
    }

    async fetchSummary() {
        try {
            const result = await generateSummary({ recordId: this.recordId });
            this.bulletPoints = result
                .split('\n')
                .map(l => l.trim().replace(/^[-\s]*/, ''))
                .filter(Boolean);
            this.hasFetched = true;
        } catch (_e) {
            this.bulletPoints = ['We’re having trouble loading your summary data. Please try again later.'];
        } finally {
            this.isLoading = false;
        }
    }

    // ===== reactions =====
    async submitLike() { await this._react('aih_like', 'like'); }
    async submitDislike() { await this._react('aih_dislike', 'dislike'); }

    _applyIconVariants() {
        this.likeVariant = this.summaryIsLiked ? 'border-filled' : 'border';
        this.dislikeVariant = this.summaryIsDisliked ? 'border-filled' : 'border';
    }

    _buildReactionPayload(choice) {
        return {
            feature: 'OpportunitySummary',
            parentNumber: this.oppName || this.recordId,
            itemType: 'Opportunity',
            itemNumber: this.recordId,
            action: choice
        };
    }

    async _react(eventType, choice) {
        const prevLiked = this.summaryIsLiked;
        const prevDisliked = this.summaryIsDisliked;

        this.summaryIsLiked = (choice === 'like');
        this.summaryIsDisliked = (choice === 'dislike');
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
            this.summaryIsLiked = prevLiked;
            this.summaryIsDisliked = prevDisliked;
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
                this.inputError = true; this._updateFeedbackState(); return;
            }
            this.onSendFeedback();
        } else if (e.key === 'Escape') {
            e.preventDefault(); this.onCancelFeedback();
        }
    };
    onCancelFeedback = () => {
        this.showFeedback = false; this.inputError = false; this._updateFeedbackState();
    };
    _updateFeedbackState() {
        const canSend = !!(this.feedback && this.feedback.trim().length > 0);
        this.sendDisabled = this.summaryBusy || !canSend;
        this.feedbackClass = (this.inputError && !canSend) ? 'feedback-textarea invalid' : 'feedback-textarea';
    }
    async onSendFeedback() {
        if (this.sendDisabled) { this.inputError = true; this._updateFeedbackState(); return; }
        try {
            this.summaryBusy = true; this._updateFeedbackState();
            const payload = {
                feature: 'OpportunitySummary',
                parentNumber: this.oppName || this.recordId,
                itemType: 'Opportunity',
                itemNumber: this.recordId,
                reason: (this.feedback || '').trim()
            };
            await logAIHEvent({
                eventType: 'aih_feedback',
                subfeature: SUBFEATURE,
                feedback: JSON.stringify(payload)
            });
            this.summaryReviewed = true; this.showFeedback = false;
            this.dispatchEvent(new ShowToastEvent({ title: 'Thank you!', message: 'Your feedback was submitted.', variant: 'success' }));
        } catch (err) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: 'Could not submit feedback.', variant: 'error' }));
        } finally {
            this.summaryBusy = false; this._updateFeedbackState(); this._applyIconVariants();
        }
    }

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
            console.error('Fallback copy failed: ', err);
        }
        document.body.removeChild(txtArea);
    }
}