import { LightningElement, api, track, wire } from 'lwc';
import makeCalloutForCaseComments
    from '@salesforce/apex/CaseAIInsightsProcessor.makeGCPCallout';
import logAIHEvent from '@salesforce/apex/CaseAIInsightsProcessor.logAIHEvent';
import USER_ID from '@salesforce/user/Id';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import CASENUM_FIELD from '@salesforce/schema/Case.CaseNumber';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CaseCommentSummary extends LightningElement {
    _recordId;
    _hasFetched = false;                 // <-- prevents repeated calls in this instance

    @track isLoading = false;
    @track summary = '';
    @track error = '';

    // reaction/feedback (per card)
    selectedAction = null;
    isLiked = false;
    isDisliked = false;
    reviewed = false;
    busy = false;
    likeVariant = 'border';
    dislikeVariant = 'border';
    @track copyIcon = 'utility:copy';

    showFeedback = false;
    feedback = '';
    sendDisabled = true;
    inputError = false;
    feedbackClass = 'feedback-textarea';

    caseNumber = '';

    @wire(getRecord, { recordId: '$_recordId', fields: [CASENUM_FIELD] })
    wiredCase({ data }) {
        this.caseNumber = data ? (getFieldValue(data, CASENUM_FIELD) || '') : '';
    }

    connectedCallback() {
        this._applyIconVariants();
    }

    _applyIconVariants() {
        this.likeVariant = this.isLiked ? 'border-filled' : 'border';
        this.dislikeVariant = this.isDisliked ? 'border-filled' : 'border';
    }


    get hasContent() {
        return !this.error && !!(this.summary && this.summary.trim().length) && !isTrivialSummary(this.summary);
    }


    @api
    set recordId(v) {
        this._recordId = v;
    }   // no auto-fetch; parent will call load()
    get recordId() {
        return this._recordId;
    }

    /** Public: parent calls this once the FIRST time the card is expanded */
    @api load() {
        if (this._hasFetched || !this._recordId) return;
        this._hasFetched = true;
        this.fetchSummary();
        logAIHEvent({ eventType: 'aih_view', subfeature: 'ExploreMore - Case Comment Summary', feedback: null }).catch(err => {
            // eslint-disable-next-line no-console
            console.warn('AIH view log failed (ExploreMore - Case Comment Summary)', {
                recordId: this._recordId,
                error: err?.message || err
            });

            // Optional: let the user know analytics didn’t record (non-blocking)
            this.dispatchEvent(new ShowToastEvent({
                title: 'Heads up',
                message: 'We couldn’t record a view for analytics. You can continue using the feature.',
                variant: 'info'
            }));
        });
    }

    async fetchSummary() {
        this.isLoading = true;
        this.error = '';
        this.summary = '';

        this.dispatchEvent(new CustomEvent('ccsloading', { bubbles: true, composed: true }));
        try {
            const res = await makeCalloutForCaseComments({
                userId: USER_ID,
                caseId: this._recordId,
                purpose: 'casecomment'
            });
            let responseData = JSON.parse(res);
            
            if (responseData.success == 'false') {
                this.error = 'We’re having trouble loading your summary data. Please try again later.';
                console.error('Case Comment Summary module - response error:', responseData.message);
            } else {
                this.summary = responseData.summary;
            }
        } catch (err) {
            this.error = 'We’re having trouble loading your summary data. Please try again later.';
            console.error('Case Comment Summary module - caught error:', err);
        } finally {
            this.isLoading = false;
            this.dispatchEvent(new CustomEvent('ccsloaded', { bubbles: true, composed: true }));
        }
    }

    _payload(choice) {
        return {
            feature: 'CaseCommentSummary',
            parentNumber: this.caseNumber || '',
            action: choice
        };
    }
    async onLike() {
        await this._react('aih_like', 'like');
    }

    async onDislike() {
        await this._react('aih_dislike', 'dislike');
    }

    async _react(type, choice) {
        if (!this.hasContent) return;
        this.selectedAction = choice;
        this.isLiked = choice === 'like';
        this.isDisliked = choice === 'dislike';
        this._applyIconVariants();
        try {
            this.busy = true;
            await logAIHEvent({ eventType: type, subfeature: 'ExploreMore - Case Comment Summary', feedback: JSON.stringify(this._payload(choice)) });
        } catch (err) {
            // eslint-disable-next-line no-console
            console.warn('AIH reaction log failed (Case Comment Summary)', {
                choice,
                error: err?.body?.message || err?.message || err
            });
            // Optional: let user know analytics logging failed, but don’t block UX
            this.dispatchEvent(new ShowToastEvent({
                title: 'Heads up',
                message: 'We couldn’t record your reaction for analytics. You can continue.',
                variant: 'info'
            }));
        } finally { this.busy = false; }
    }

    toggleFeedback() {
        if (!this.hasContent) return;
        this.showFeedback = !this.showFeedback;
        this.inputError = false;
        this._updateFeedback();
    }
    onFeedbackChange(e) {
        this.feedback = e.target.value || '';
        this.inputError = false;
        this._updateFeedback();
    }

    onFeedbackKeydown(e) {
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            if (this.sendDisabled) {
                this.inputError = true;
                this._updateFeedback();
                return;
            }
            this.onSendFeedback();
        }
        else if (e.key === 'Escape') {
            e.preventDefault();
            this.onCancelFeedback();
        }
    }
    onCancelFeedback() {
        this.showFeedback = false;
        this.inputError = false;
        this._updateFeedback();
    }

    _updateFeedback() {
        const canSend = !!(this.feedback && this.feedback.trim().length > 0);
        this.sendDisabled = this.busy || !canSend;
        this.feedbackClass = (this.inputError && !canSend) ? 'feedback-textarea invalid' : 'feedback-textarea';
    }

    async onSendFeedback() {
        if (this.sendDisabled) {
            this.inputError = true;
            this._updateFeedback();
            return;
        }

        try {
            this.busy = true; this._updateFeedback();
            const payload = { feature: 'CaseCommentSummary', parentNumber: this.caseNumber || '', reason: (this.feedback || '').trim() };
            await logAIHEvent({ eventType: 'aih_feedback', subfeature: 'ExploreMore - Case Comment Summary', feedback: JSON.stringify(payload) });
            this.reviewed = true; this.showFeedback = false;
            this.dispatchEvent(new ShowToastEvent({ title: 'Thank you!', message: 'Your feedback was submitted.', variant: 'success' }));
        } catch {
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: 'Could not submit feedback.', variant: 'error' }));
        } finally {
            this.busy = false; this._updateFeedback();
        }
    }

    /* Since navigator.clipboard cannot be used due to LWS being disabled in org, the 
    deprecated method for copy is used here */
    async handleCopy() {
        const container = document.createElement('div');
        container.setAttribute('contenteditable', 'true');
        this.summary = this.summary.replace(/\n/g, '<br/>');
        // keep it visually hidden and out of flow but still selectable
        container.style.position = 'fixed';
        container.style.left = '-9999px';
        container.style.top = '0';
        container.style.width = '1px';
        container.style.height = '1px';
        container.style.overflow = 'hidden';
        container.style.opacity = '0';

        container.innerHTML = this.summary;

        document.body.appendChild(container);

        const range = document.createRange();
        range.selectNodeContents(container);

        const selection = window.getSelection();
        selection.removeAllRanges();
        selection.addRange(range);
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
        // Cleanup: remove selection and the temp element
        selection.removeAllRanges();
        document.body.removeChild(container);
    }

    hideCopiedMsg() {
        this.copyIcon = 'utility:copy';
    }
}

function normalize(s = '') {
    return String(s).toLowerCase().replace(/\s+/g, ' ').trim();
}

function isTrivialSummary(text = '') {
    const t = normalize(text).replace(/[–—-]/g, '-');
    const phrases = [
        'no case comments available',
        'there are no case comments available',
        'no comments available',
        'no comments to summarize',
        'no data available'
    ];
    if (phrases.some(p => t.includes(p))) return true;
    if (t.length <= 25 && /^no\b/.test(t)) return true;
    return false;
}