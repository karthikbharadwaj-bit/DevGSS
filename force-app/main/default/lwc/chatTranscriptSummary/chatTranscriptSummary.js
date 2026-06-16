import { LightningElement, api, track, wire } from 'lwc';
import makeCalloutForChatTranscripts
    from '@salesforce/apex/CaseAIInsightsProcessor.makeGCPCallout';
import logAIHEvent from '@salesforce/apex/CaseAIInsightsProcessor.logAIHEvent';
import USER_ID from '@salesforce/user/Id';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import CASENUM_FIELD from '@salesforce/schema/Case.CaseNumber';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ChatTranscriptSummary extends LightningElement {
    _recordId;
    _hasFetched = false;                 // <-- prevents repeated calls in this instance

    @track isLoading = false;
    @track summary = '';
    @track summaryItems = [];
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
    }   // no auto-fetch; parent will call load()
    get recordId() {
        return this._recordId;
    }

    get hasItems() {
        return Array.isArray(this.summaryItems) && this.summaryItems.length > 0;
    }

    /** Public: parent calls this once the FIRST time the card is expanded */
    @api load() {
        if (this._hasFetched || !this._recordId) return;
        this._hasFetched = true;
        this.fetchSummary();
        logAIHEvent({ 
            eventType: 'aih_view', 
            subfeature: 'ExploreMore - Chat Transcript Summary', 
            feedback: null 
        })
            .catch(err => {
            // eslint-disable-next-line no-console
            console.warn('AIH view log failed (ExploreMore - Chat Transcript Summary)', {
                recordId: this._recordId,
                error: err?.message || err
            });

            // Optional: let the user know analytics didn't record (non-blocking)
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

        this.dispatchEvent(new CustomEvent('ctsloading', { bubbles: true, composed: true }));
        try {
            const res = await makeCalloutForChatTranscripts({
                userId: USER_ID,
                caseId: this._recordId,
                purpose: 'chatTranscriptSummary'
            });
            const payload = safeParse(res) ?? {};
            const summaryText = payload && payload.summary;
            const errMessage = payload && payload.message;

            console.log(errMessage);
            if (payload.success === false) {
                this.error = errMessage;
            } else if (summaryText !== undefined && summaryText !== null) {
                this.applySummary(summaryText);
            } else {
                this.summary = '';
            }
        } catch (e) {
            this.error =  e.message;
        } finally {
            this.isLoading = false;
            this.dispatchEvent(new CustomEvent('ctsloaded', { bubbles: true, composed: true }));
        }
    }


    _payload(choice) {
        return {
            feature: 'ChatTranscriptSummary',
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
        // keep previous state to rollback on failure
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
            await logAIHEvent({ eventType: type, subfeature: 'ExploreMore - Chat Transcript Summary', feedback: JSON.stringify(this._payload(choice)) });
        } catch (err) {
            // rollback optimistic UI
            this.selectedAction = prev.selectedAction;
            this.isLiked = prev.isLiked;
            this.isDisliked = prev.isDisliked;
            this._applyIconVariants();

            // eslint-disable-next-line no-console
            console.warn('AIH reaction log failed (ExploreMore - Chat Transcript Summary)', {
                recordId: this._recordId,
                eventType: type,
                choice,
                error: err?.message || err
            });

            // optional: let the user know analytics wasn't recorded
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
            const payload = { feature: 'ChatTranscriptSummary', parentNumber: this.caseNumber || '', reason: (this.feedback || '').trim() };
            await logAIHEvent({ eventType: 'aih_feedback', subfeature: 'ExploreMore - Chat Transcript Summary', feedback: JSON.stringify(payload) });
            this.reviewed = true; this.showFeedback = false;
            this.dispatchEvent(new ShowToastEvent({ title: 'Thank you!', message: 'Your feedback was submitted.', variant: 'success' }));
        } catch {
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: 'Could not submit feedback.', variant: 'error' }));
        } finally {
            this.busy = false; this._updateFeedback();
        }
    }

    applySummary(raw) {
        this.summary = '';
        this.summaryItems = [];
        this.contentAvailable = false;

        // Case 1: already an array
        if (Array.isArray(raw)) {
            const cleaned = this.cleanTexts(raw).filter(v => !isTrivialSummary(v));
            this.summaryItems = this.toRows(cleaned);
            this.contentAvailable = cleaned.length > 0;
            if (!this.contentAvailable) {
                this.summary = ''; // keep empty
            }
            return;
        }

        let text = String(raw == null ? '' : raw).trim();
        if (!text) return;
        // Normalize smart quotes before attempting to parse
        text = text.replace(/[""]/g, '"').replace(/['']/g, "'");

        // Try strict JSON first
        const arr1 = safeParse(text);
        if (Array.isArray(arr1)) {
            const cleaned = this.cleanTexts(arr1).filter(v => !isTrivialSummary(v));
            this.summaryItems = this.toRows(cleaned);
            this.contentAvailable = cleaned.length > 0;
            return;
        }

        // For array which looks like a bracketed array but not valid JSON
        if (text.startsWith('[') && text.endsWith(']')) {
            const quoted = text.match(/"([^"\\]|\\.)*"|'([^'\\]|\\.)*'/g);
            if (quoted?.length) {
                const cleaned = quoted
                    .map(q => q.slice(1, -1).replace(/\\"/g, '"').replace(/\\'/g, "'").replace(/\\n/g, ' ').replace(/\s+/g, ' ').trim())
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

        // If the text contains multiple lines/bullets, promote to list
        const lines = text.split(/\n+/)
            .map(s => s.replace(/^[•\-]\s*/, '').trim())
            .filter(Boolean);
        if (lines.length > 1) {
            const cleaned = this.cleanTexts(lines).filter(v => !isTrivialSummary(v));
            this.summaryItems = this.toRows(cleaned);
            this.contentAvailable = cleaned.length > 0;
            return;
        }

        // Last resort: render as a single paragraph
        if (isTrivialSummary(text)) {
            this.summary = '';          // keep the UI's "No chat transcripts…" block
            this.contentAvailable = false;
        } else {
            this.summary = text;
            this.contentAvailable = true;
        }
    }

    /**
     * Remove empty / non-string values and normalize whitespace.
     * Also skips literal "null"/"undefined" strings that sometimes leak through.
     */
    cleanTexts(arr) {
        return (arr || [])
            .filter(v => typeof v === 'string')
            .map(v => v.replace(/\s+/g, ' ').trim())
            .filter(v => v && v.toLowerCase() !== 'null' && v.toLowerCase() !== 'undefined');
    }

    /**
     * Convert an array of strings into the shape expected by the template.
     * Adds a stable (but non-cryptographic) id for each item.
     */
    toRows(texts) {
        return texts.map((t, i) => ({ id: `${i}-${hash24(t)}`, text: t }));
    }

    /* Since navigator.clipboard cannot be used due to LWS being disabled in org, the 
    deprecated method for copy is used here */
    async handleCopy() {
        let items = this.summaryItems || [];

        const lines = items.map(i => typeof i === 'string' ? i : i.text);

        // Create HTML content with bullets that preserves formatting
        const htmlContent = lines.map(l => `• ${l}`).join('<br/>');

        // Create a contenteditable div to copy rich text with formatting
        const container = document.createElement('div');
        container.setAttribute('contenteditable', 'true');
        container.style.position = 'fixed';
        container.style.left = '-9999px';
        container.style.top = '0';
        container.style.width = '1px';
        container.style.height = '1px';
        container.style.overflow = 'hidden';
        container.style.opacity = '0';

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

/**
 * Safely attempt JSON.parse; return `undefined` if parsing fails.
 * Helps keep the main flow clean without try/catch noise.
 */
function safeParse(maybeJson) {
    try {
        return JSON.parse(maybeJson);
    } catch {
        return undefined;
    }
}

/**
 * Lightweight, deterministic 24-char hash for list item keys.
 * Not cryptographically secure; only used to keep stable keys across rerenders.
 */
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
    .replace(/[–—−]/g, '-')   // various dash characters -> hyphen
    .replace(/[·••]/g, '');   // optional: remove odd bullets if present
    // Add any "no data" phrasings you use in GCP or UI
    const phrases = [
        'cannot generate summary for this chat transcript', //used in case of other errors by GCP 
        'there are no chat transcripts available',
        'no chat transcripts were found for your case.', //used for no comments error from GCP
        'no data available',
        'no chat transcript data available'
    ];
    if (phrases.some(p => t.includes(p))) {
        return true;
    }
    // Single very short generic sentence ≈ not real content
    if (t.length <= 25 && /^no\b/.test(t)) {
        return true;
    }
    return false;
}