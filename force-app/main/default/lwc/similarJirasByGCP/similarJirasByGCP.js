import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import SUBJECT_FIELD from '@salesforce/schema/Case.Subject';
import DESCRIPTION_FIELD from '@salesforce/schema/Case.Description';
import CASENUMBER_FIELD from '@salesforce/schema/Case.CaseNumber';
import makeGCPCallout from '@salesforce/apex/GCPCalloutForSimilarJiras.makeGCPCallout';
import generateJiraSummary from '@salesforce/apex/GCPCalloutForSimilarJiras.generateJiraSummary';
import logAIHEvent from '@salesforce/apex/GCPCalloutForSimilarJiras.logAIHEvent';
import getJiraBaseUrl from '@salesforce/apex/GCPCalloutForSimilarJiras.getJiraBaseUrl';
import jiraIconResource from '@salesforce/resourceUrl/jiraIcon';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const SUBFEATURE = 'Similar Jiras';

const BAR_OPACITIES = [0.85, 0.7, 0.58, 0.48, 0.38];

function priorityBadgeClass(p) {
    const m = String(p || '').toLowerCase();
    if (m === 'highest') return 'priority priority--highest';
    if (m === 'high')    return 'priority priority--high';
    if (m === 'medium')  return 'priority priority--medium';
    if (m === 'low')     return 'priority priority--low';
    if (m === 'lowest')  return 'priority priority--lowest';
    return 'priority priority--medium';
}

function safeParse(maybeJson) {
    try {
        return JSON.parse(maybeJson);
    } catch {
        return undefined;
    }
}

function hash24(s) {
    let h1 = 0;
    let h2 = 0;
    for (let i = 0; i < s.length; i++) {
        const c = s.charCodeAt(i);
        h1 = (h1 * 31 + c) >>> 0;
        h2 = (h2 * 131 + c) >>> 0;
    }
    return (h1.toString(36) + h2.toString(36)).slice(0, 24);
}

function cleanSummaryStrings(arr) {
    return (arr || [])
        .filter(v => typeof v === 'string')
        .map(v => v.replace(/\s+/g, ' ').trim())
        .filter(v => v && v.toLowerCase() !== 'null' && v.toLowerCase() !== 'undefined');
}

function toSummaryRows(texts) {
    return texts.map((t, i) => ({ id: `${i}-${hash24(t)}`, text: t }));
}

/**
 * Mirrors chatTranscriptSummary: arrays become a bullet list; strings fall back to
 * paragraph or parsed list (avoids assigning Array to innerHTML, which joins with commas).
 */
function applyJiraAiSummary(row, raw) {
    row.summaryItems = [];
    row.summaryParagraph = '';
    row.hasSummaryList = false;
    if (raw === undefined || raw === null) {
        return;
    }

    if (Array.isArray(raw)) {
        const cleaned = cleanSummaryStrings(raw);
        if (cleaned.length > 0) {
            row.summaryItems = toSummaryRows(cleaned);
            row.hasSummaryList = true;
        }
        return;
    }

    let text = String(raw).trim();
    if (!text) {
        return;
    }
    text = text.replace(/[""]/g, '"').replace(/['']/g, "'");

    const asJsonArray = safeParse(text);
    if (Array.isArray(asJsonArray)) {
        const cleaned = cleanSummaryStrings(asJsonArray);
        if (cleaned.length > 0) {
            row.summaryItems = toSummaryRows(cleaned);
            row.hasSummaryList = true;
        }
        return;
    }

    if (text.startsWith('[') && text.endsWith(']')) {
        const quoted = text.match(/"([^"\\]|\\.)*"|'([^'\\]|\\.)*'/g);
        if (quoted?.length) {
            const cleaned = quoted
                .map(q => q.slice(1, -1).replace(/\\"/g, '"').replace(/\\'/g, "'").replace(/\\n/g, ' ').replace(/\s+/g, ' ').trim())
                .filter(Boolean);
            const parts = cleanSummaryStrings(cleaned);
            if (parts.length > 0) {
                row.summaryItems = toSummaryRows(parts);
                row.hasSummaryList = true;
            }
            return;
        }
        let parts = text.slice(1, -1).split(/"\s*,\s*"|'\s*,\s*'/g).map(s => s.replace(/^["'\s]+|["'\s]+$/g, ''));
        parts = cleanSummaryStrings(parts);
        if (parts.length > 0) {
            row.summaryItems = toSummaryRows(parts);
            row.hasSummaryList = true;
        }
        return;
    }

    const lines = text.split(/\n+/).map(s => s.replace(/^[•\-]\s*/, '').trim()).filter(Boolean);
    if (lines.length > 1) {
        const cleaned = cleanSummaryStrings(lines);
        if (cleaned.length > 0) {
            row.summaryItems = toSummaryRows(cleaned);
            row.hasSummaryList = true;
        }
        return;
    }

    row.summaryParagraph = text;
}

export default class SimilarJirasByGCP extends LightningElement {
    @api recordId;
    loggedInUserId = USER_ID;
    subject = '';
    description = '';
    caseNumber = '';
    @track formattedResponse = [];
    @track rawResponse = '';
    @track isLoading = false;
    @track isError = false;
    @track isVisible = false;
    isDataRetrieved = false;
    aihViewLogged = false;
    caseDataLoaded = false;
    /** Set from Apex when similar Jiras return; false when case product did not match any mapping. */
    productMatched = true;

    jiraIconUrl = jiraIconResource;
    jiraBaseUrl = '';

    @wire(getJiraBaseUrl)
    wiredJiraBaseUrl({ error, data }) {
        if (data !== undefined && data !== null) {
            this.jiraBaseUrl = data;
        } else if (error) {
            console.warn('SimilarJiras: could not load Jira base URL', error?.message || error);
        }
    }

    get showNoProductNotice() {
        return this.productMatched === false;
    }

    get hasJiraResults() {
        return Array.isArray(this.formattedResponse) && this.formattedResponse.length > 0;
    }

    get showNoJiraResults() {
        return this.isDataRetrieved && !this.isError && !this.hasJiraResults && !this.rawResponse && this.productMatched !== false;
    }

    @wire(getRecord, { recordId: '$recordId', fields: [SUBJECT_FIELD, DESCRIPTION_FIELD, CASENUMBER_FIELD] })
    wiredCase({ error, data }) {
        if (data) {
            this.subject = getFieldValue(data, SUBJECT_FIELD) || '';
            this.description = getFieldValue(data, DESCRIPTION_FIELD) || '';
            this.caseNumber = getFieldValue(data, CASENUMBER_FIELD) || '';
            this.caseDataLoaded = true;

            if (this.isVisible && !this.isDataRetrieved) {
                if (this.subject && this.description) {
                    this.makeCallout();
                } else {
                    this.rawResponse = 'Case Subject or Description is missing.';
                    this.isError = true;
                    this.isLoading = false;
                }
            }
        } else if (error) {
            this.rawResponse = 'Error loading case data: ' + JSON.stringify(error);
            this.isError = true;
            this.caseDataLoaded = true;
            this.isLoading = false;
        }
    }

    toggleContent() {
        this.isVisible = !this.isVisible;

        if (this.isVisible) {
            if (!this.aihViewLogged) {
                this.aihViewLogged = true;
                logAIHEvent({ eventType: 'aih_view', subfeature: SUBFEATURE, feedback: null })
                    .catch(err => {
                        console.warn('AIH view log failed:', err?.message || err);
                    });
            }

            if (!this.isDataRetrieved) {
                if (!this.caseDataLoaded) {
                    this.isLoading = true;
                } else if (this.subject && this.description) {
                    this.makeCallout();
                } else {
                    this.rawResponse = 'Case Subject or Description is missing.';
                    this.isError = true;
                }
            }
        }
    }

    @api
    autoExpandSimilarJiras() {
        if (!this.isVisible) {
            this.toggleContent();
        }
    }

    _applyRenderState(row) {
        row.likeVariant = row.isLiked ? 'border-filled' : 'border';
        row.dislikeVariant = row.isDisliked ? 'border-filled' : 'border';
    }

    async onGenerateSummary(event) {
        const idx = Number(event.currentTarget.dataset.idx);
        if (!Number.isInteger(idx) || !this.formattedResponse[idx]) return;

        const row = this.formattedResponse[idx];

        if (row.summaryGenerated) {
            row.showSummary = !row.showSummary;
            row.summaryButtonLabel = row.showSummary ? 'Hide Summary' : 'Generate Summary';
            this.formattedResponse = [...this.formattedResponse];
            return;
        }

        row.isSummaryLoading = true;
        this.formattedResponse = [...this.formattedResponse];

        try {
            const payload = {
                jira_id: row.jira_key,
                subject: row.summary,
                description: row.rawDescription,
                priority: row.priority,
                labels: row.rawLabels,
                components: row.rawComponents
            };

            const result = await generateJiraSummary({
                jiraPayloadJson: JSON.stringify(payload)
            });

            const parsed = JSON.parse(result);
            const aiRaw = parsed.ai_summary ?? parsed.body?.ai_summary;
            if (parsed.success === true && aiRaw !== undefined && aiRaw !== null) {
                applyJiraAiSummary(row, aiRaw);
                row.summaryGenerated = true;
                row.showSummary = true;
                row.summaryButtonLabel = 'Hide Summary';
            } else {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Summary Unavailable',
                    message: parsed.message || 'Could not generate summary.',
                    variant: 'warning'
                }));
            }
        } catch (err) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Failed to generate summary. Please try again.',
                variant: 'error'
            }));
        } finally {
            row.isSummaryLoading = false;
            this.formattedResponse = [...this.formattedResponse];
        }
    }

    async makeCallout() {
        this.isLoading = true;
        this.isError = false;
        this.formattedResponse = [];
        this.rawResponse = '';
        this.productMatched = true;

        try {
            const result = await makeGCPCallout({
                userId: this.loggedInUserId,
                subject: this.subject,
                description: this.description,
                recordId: this.recordId
            });

            let parsed;
            try {
                parsed = JSON.parse(result);
            } catch {
                this.rawResponse = 'Failed to parse response:\n' + result;
                this.isError = true;
                return;
            }

            if (parsed.success === true && Array.isArray(parsed.jiras)) {
                this.productMatched = parsed.productMatched !== false;
                this.formattedResponse = parsed.jiras.map((j, idx) => {
                    const jiraKey = j.jira_key || j.jira_id || j.key || j.id || j.case_number || '';
                    const row = {
                        jira_key: jiraKey,
                        jiraUrl: jiraKey && this.jiraBaseUrl ? this.jiraBaseUrl.replace(/\/$/, '') + '/browse/' + jiraKey : '',
                        summary: j.summary || j.subject || '',
                        status: j.status || '',
                        priority: j.priority || '',
                        priorityClass: priorityBadgeClass(j.priority),
                        barStyle: `opacity: ${BAR_OPACITIES[Math.min(idx, BAR_OPACITIES.length - 1)]}`,

                        rawDescription: j.description || '',
                        rawLabels: j.labels || [],
                        rawComponents: j.components || '',

                        summaryItems: [],
                        summaryParagraph: '',
                        hasSummaryList: false,
                        isSummaryLoading: false,
                        showSummary: false,
                        summaryGenerated: false,
                        summaryButtonLabel: 'Generate Summary',

                        feedback: '',
                        showFeedback: false,
                        actionBusy: false,
                        reviewed: false,

                        selectedAction: null,
                        isLiked: false,
                        isDisliked: false,

                        canSend: false,
                        inputError: false,
                        feedbackClass: 'feedback-textarea',
                        sendDisabled: true,
                        likeVariant: 'border',
                        dislikeVariant: 'border'
                    };
                    this._applyRenderState(row);
                    return row;
                });
                this.isDataRetrieved = true;
            } else if (parsed.success === false && parsed.message) {
                let isRealError = false;
                try {
                    const maybeError = JSON.parse(parsed.message);
                    if (maybeError.error || maybeError.details) isRealError = true;
                } catch (e) {
                    const msg = String(parsed.message).toLowerCase();
                    if (msg.includes('exception') || msg.includes('timeout') || msg.includes('failed') || msg.includes('error')) {
                        isRealError = true;
                    }
                }
                this.rawResponse = isRealError
                    ? "We're facing a temporary issue retrieving similar Jiras. Please contact your administrator if the issue persists."
                    : parsed.message;
                this.isError = true;
                this.isDataRetrieved = true;
            } else {
                this.rawResponse = 'Unexpected response format:\n' + result;
                this.isError = true;
                this.isDataRetrieved = true;
            }
        } catch (error) {
            this.rawResponse = 'Apex Callout Error: ' + error.message;
            this.isError = true;
        } finally {
            this.isLoading = false;
        }
    }

    _updateFeedbackState(row) {
        row.canSend = !!(row.feedback && row.feedback.trim().length > 0);
        row.sendDisabled = row.actionBusy || !row.canSend;
        row.feedbackClass = row.inputError && !row.canSend ? 'feedback-textarea invalid' : 'feedback-textarea';
    }

    onFeedbackChange(e) {
        const idx = Number(e.currentTarget.dataset.idx);
        if (!Number.isInteger(idx) || !this.formattedResponse[idx]) return;
        const row = this.formattedResponse[idx];
        row.feedback = e.target.value || '';
        row.inputError = false;
        this._updateFeedbackState(row);
        this.formattedResponse = [...this.formattedResponse];
    }

    toggleFeedback(e) {
        const idx = Number(e.currentTarget.dataset.idx);
        if (!Number.isInteger(idx) || !this.formattedResponse[idx]) return;
        const row = this.formattedResponse[idx];
        row.showFeedback = !row.showFeedback;
        row.inputError = false;
        this._updateFeedbackState(row);
        this.formattedResponse = [...this.formattedResponse];
    }

    onCancelFeedback(e) {
        const idx = Number(e.currentTarget.dataset.idx);
        if (!Number.isInteger(idx) || !this.formattedResponse[idx]) return;
        const row = this.formattedResponse[idx];
        row.showFeedback = false;
        row.inputError = false;
        this._updateFeedbackState(row);
        this.formattedResponse = [...this.formattedResponse];
    }

    onFeedbackKeydown(e) {
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            const idx = Number(e.currentTarget.dataset.idx);
            const row = this.formattedResponse[idx];
            if (!row || row.sendDisabled) {
                row.inputError = true;
                this._updateFeedbackState(row);
                this.formattedResponse = [...this.formattedResponse];
                return;
            }
            this.onSendFeedback(e);
        } else if (e.key === 'Escape') {
            e.preventDefault();
            this.onCancelFeedback(e);
        }
    }

    _buildReactionPayload(row, choice) {
        return {
            feature: 'SimilarJiras',
            parentNumber: this.caseNumber,
            itemType: 'Jira',
            itemNumber: row.jira_key,
            action: choice
        };
    }

    async onLike(event) {
        await this._sendByEvent(event, 'aih_like', 'like');
    }

    async onDislike(event) {
        await this._sendByEvent(event, 'aih_dislike', 'dislike');
    }

    async _sendByEvent(event, type, choice) {
        const idx = Number(event.currentTarget.dataset.idx);
        if (Number.isNaN(idx) || !this.formattedResponse[idx]) return;

        const row = this.formattedResponse[idx];
        const prevSelected = row.selectedAction;
        const prevLiked = row.isLiked;
        const prevDisliked = row.isDisliked;

        row.selectedAction = choice;
        row.isLiked = choice === 'like';
        row.isDisliked = choice === 'dislike';
        this._applyRenderState(row);
        this.formattedResponse = [...this.formattedResponse];

        try {
            row.actionBusy = true;
            this.formattedResponse = [...this.formattedResponse];

            const feedbackPayload = this._buildReactionPayload(row, choice);
            await logAIHEvent({
                eventType: type,
                subfeature: SUBFEATURE,
                feedback: JSON.stringify(feedbackPayload)
            });
        } catch (err) {
            row.selectedAction = prevSelected;
            row.isLiked = prevLiked;
            row.isDisliked = prevDisliked;
            this._applyRenderState(row);

            console.warn('SimilarJiras: failed to log reaction', { eventType: type, error: err?.message || err });
            this.dispatchEvent(
                new ShowToastEvent({ title: 'Could not record your reaction', message: 'Please try again in a moment.', variant: 'warning' })
            );
        } finally {
            row.actionBusy = false;
            this._applyRenderState(row);
            this.formattedResponse = [...this.formattedResponse];
        }
    }

    async onSendFeedback(e) {
        const idx = Number(e.currentTarget.dataset.idx);
        if (!Number.isInteger(idx) || !this.formattedResponse[idx]) return;

        const row = this.formattedResponse[idx];
        if (row.sendDisabled) {
            row.inputError = true;
            this._updateFeedbackState(row);
            this.formattedResponse = [...this.formattedResponse];
            return;
        }

        row.actionBusy = true;
        this._updateFeedbackState(row);

        try {
            const payload = {
                feature: 'SimilarJiras',
                parentNumber: this.caseNumber,
                itemType: 'Jira',
                itemNumber: row.jira_key,
                reason: (row.feedback || '').trim()
            };
            await logAIHEvent({
                eventType: 'aih_feedback',
                subfeature: SUBFEATURE,
                feedback: JSON.stringify(payload)
            });

            row.reviewed = true;
            row.showFeedback = false;
            this._applyRenderState(row);

            this.dispatchEvent(new ShowToastEvent({ title: 'Thank you!', message: 'Your review was submitted.', variant: 'success' }));
        } catch {
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: 'Could not submit review.', variant: 'error' }));
        } finally {
            row.actionBusy = false;
            this._updateFeedbackState(row);
            this.formattedResponse = [...this.formattedResponse];
        }
    }
}