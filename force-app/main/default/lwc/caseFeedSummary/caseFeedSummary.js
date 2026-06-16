import { LightningElement, api, track, wire } from 'lwc';
import makeCalloutForFeedSummary
    from '@salesforce/apex/CaseAIInsightsProcessor.makeGCPCallout';
import logAIHEvent from '@salesforce/apex/CaseAIInsightsProcessor.logAIHEvent';
import USER_ID from '@salesforce/user/Id';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import CASENUM_FIELD from '@salesforce/schema/Case.CaseNumber';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CaseFeedSummary extends LightningElement {
    _recordId;
    _hasFetched = false;

    @track isLoading = false;
    @track summary = '';
    @track summaryItems = [];
    @track error = '';

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
    contentAvailable = false;

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

    @api
    set recordId(v) {
        this._recordId = v;
    }
    get recordId() {
        return this._recordId;
    }

    get hasItems() {
        return Array.isArray(this.summaryItems) && this.summaryItems.length > 0;
    }

    /** Public: parent calls this once the first time the card is expanded. */
    @api load() {
        if (this._hasFetched || !this._recordId) return;
        this._hasFetched = true;
        this.fetchSummary();
        logAIHEvent({
            eventType: 'aih_view',
            subfeature: 'ExploreMore - Feed Summary',
            feedback: null
        }).catch(err => {
            // eslint-disable-next-line no-console
            console.warn('AIH view log failed (ExploreMore - Feed Summary)', {
                recordId: this._recordId,
                error: err?.message || err
            });
            this.dispatchEvent(new ShowToastEvent({
                title: 'Heads up',
                message: 'We could not record a view for analytics. You can continue using the feature.',
                variant: 'info'
            }));
        });
    }

    async fetchSummary() {
        this.isLoading = true;
        this.error = '';
        this.summary = '';
        this.summaryItems = [];
        this.contentAvailable = false;

        this.dispatchEvent(new CustomEvent('fssloading', { bubbles: true, composed: true }));
        try {
            const res = await makeCalloutForFeedSummary({
                userId: USER_ID,
                caseId: this._recordId,
                purpose: 'feedSummary'
            });
            const payload = safeParse(res) ?? {};
            const summaryText = payload && payload.summary;
            const errMessage  = payload && payload.message;

            if (payload.success === false) {
                this.error = errMessage;
            } else if (summaryText !== undefined && summaryText !== null) {
                this.applySummary(summaryText);
            } else {
                this.summary = '';
            }
        } catch (e) {
            this.error = e.message;
        } finally {
            this.isLoading = false;
            this.dispatchEvent(new CustomEvent('fssloaded', { bubbles: true, composed: true }));
        }
    }

    _payload(choice) {
        return {
            feature: 'FeedSummary',
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
        if (!this.contentAvailable) return;
        const prev = {
            selectedAction: this.selectedAction,
            isLiked: this.isLiked,
            isDisliked: this.isDisliked,
            busy: this.busy
        };
        this.selectedAction = choice;
        this.isLiked = choice === 'like';
        this.isDisliked = choice === 'dislike';
        this._applyIconVariants();
        try {
            this.busy = true;
            await logAIHEvent({
                eventType: type,
                subfeature: 'ExploreMore - Feed Summary',
                feedback: JSON.stringify(this._payload(choice))
            });
        } catch (err) {
            this.selectedAction = prev.selectedAction;
            this.isLiked = prev.isLiked;
            this.isDisliked = prev.isDisliked;
            this._applyIconVariants();
            // eslint-disable-next-line no-console
            console.warn('AIH reaction log failed (ExploreMore - Feed Summary)', {
                recordId: this._recordId,
                eventType: type,
                choice,
                error: err?.message || err
            });
            this.dispatchEvent(new ShowToastEvent({
                title: 'Heads up',
                message: 'We could not record your reaction. You can try again.',
                variant: 'info'
            }));
        } finally {
            this.busy = false;
        }
    }

    toggleFeedback() {
        if (!this.contentAvailable) return;
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
        } else if (e.key === 'Escape') {
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
            this.busy = true;
            this._updateFeedback();
            const payload = {
                feature: 'FeedSummary',
                parentNumber: this.caseNumber || '',
                reason: (this.feedback || '').trim()
            };
            await logAIHEvent({
                eventType: 'aih_feedback',
                subfeature: 'ExploreMore - Feed Summary',
                feedback: JSON.stringify(payload)
            });
            this.reviewed = true;
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
            this.busy = false;
            this._updateFeedback();
        }
    }

    applySummary(raw) {
        this.summary = '';
        this.summaryItems = [];
        this.contentAvailable = false;

        if (Array.isArray(raw)) {
            const cleaned = this.cleanTexts(raw).filter(v => !isTrivialSummary(v));
            this.summaryItems = this.toRows(cleaned);
            this.contentAvailable = cleaned.length > 0;
            return;
        }

        let text = String(raw == null ? '' : raw).trim();
        if (!text) return;
        text = text.replace(/[""]/g, '"').replace(/['']/g, "'");

        const arr1 = safeParse(text);
        if (Array.isArray(arr1)) {
            const cleaned = this.cleanTexts(arr1).filter(v => !isTrivialSummary(v));
            this.summaryItems = this.toRows(cleaned);
            this.contentAvailable = cleaned.length > 0;
            return;
        }

        if (text.startsWith('[') && text.endsWith(']')) {
            const quoted = text.match(/"([^"\\]|\\.)*"|'([^'\\]|\\.)*'/g);
            if (quoted?.length) {
                const cleaned = quoted
                    .map(q => q.slice(1, -1)
                        .replace(/\\"/g, '"')
                        .replace(/\\'/g, "'")
                        .replace(/\\n/g, ' ')
                        .replace(/\s+/g, ' ')
                        .trim())
                    .filter(Boolean)
                    .filter(v => !isTrivialSummary(v));
                this.summaryItems = this.toRows(cleaned);
                this.contentAvailable = cleaned.length > 0;
                return;
            }
            let parts = text.slice(1, -1).split(/"\s*,\s*"|'\s*,\s*'/g)
                .map(s => s.replace(/^["'\s]+|["'\s]+$/g, ''));
            parts = this.cleanTexts(parts).filter(v => !isTrivialSummary(v));
            this.summaryItems = this.toRows(parts);
            this.contentAvailable = parts.length > 0;
            return;
        }

        const lines = text.split(/\n+/)
            .map(s => s.replace(/^[•\-]\s*/, '').trim())
            .filter(Boolean);
        if (lines.length > 1) {
            const cleaned = this.cleanTexts(lines).filter(v => !isTrivialSummary(v));
            this.summaryItems = this.toRows(cleaned);
            this.contentAvailable = cleaned.length > 0;
            return;
        }

        if (isTrivialSummary(text)) {
            this.summary = '';
            this.contentAvailable = false;
        } else {
            this.summary = text;
            this.contentAvailable = true;
        }
    }

    cleanTexts(arr) {
        return (arr || [])
            .filter(v => typeof v === 'string')
            .map(v => v.replace(/\s+/g, ' ').trim())
            .filter(v => v && v.toLowerCase() !== 'null' && v.toLowerCase() !== 'undefined');
    }

    toRows(texts) {
        return texts.map((t, i) => ({ id: `${i}-${hash24(t)}`, text: t }));
    }

    /* Since navigator.clipboard is not available in LWS context, use the deprecated execCommand. */
    async handleCopy() {
        const items = this.summaryItems || [];
        const lines = items.map(i => (typeof i === 'string' ? i : i.text));
        const htmlContent = lines.map(l => `• ${l}`).join('<br/>');

        const container = document.createElement('div');
        container.setAttribute('contenteditable', 'true');
        container.style.cssText = 'position:fixed;left:-9999px;top:0;width:1px;height:1px;overflow:hidden;opacity:0';
        container.innerHTML = htmlContent;
        document.body.appendChild(container);

        const range = document.createRange();
        range.selectNodeContents(container);
        const selection = window.getSelection();
        selection.removeAllRanges();
        selection.addRange(range);

        try {
            document.execCommand('copy');
            this.copyIcon = 'utility:check';
            setTimeout(() => { this.copyIcon = 'utility:copy'; }, 2000);
        } catch (err) {
            // eslint-disable-next-line no-console
            console.error('Fallback copy failed:', err);
        }

        selection.removeAllRanges();
        document.body.removeChild(container);
    }
}

function safeParse(maybeJson) {
    try {
        return JSON.parse(maybeJson);
    } catch {
        return undefined;
    }
}

function hash24(s) {
    let h1 = 0, h2 = 0;
    for (let i = 0; i < s.length; i++) {
        const c = s.charCodeAt(i);
        h1 = (h1 * 31 + c) >>> 0;
        h2 = (h2 * 131 + c) >>> 0;
    }
    return (h1.toString(36) + h2.toString(36)).slice(0, 24);
}

function isTrivialSummary(text = '') {
    const t = text
        .toLowerCase()
        .trim()
        .replace(/\s+/g, ' ')
        .replace(/[–—−]/g, '-')
        .replace(/[·••]/g, '');
    const phrases = [
        'no feed data available',
        'cannot generate summary for this case feed',
        'no case feed entries found',
        'no data available',
        'unable to generate summary'
    ];
    if (phrases.some(p => t.includes(p))) {
        return true;
    }
    if (t.length <= 25 && /^no\b/.test(t)) {
        return true;
    }
    return false;
}