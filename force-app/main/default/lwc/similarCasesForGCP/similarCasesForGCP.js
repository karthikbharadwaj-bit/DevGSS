import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import SUBJECT_FIELD from '@salesforce/schema/Case.Subject';
import DESCRIPTION_FIELD from '@salesforce/schema/Case.Description';
import CASENUMBER_FIELD from '@salesforce/schema/Case.CaseNumber';
import makeGCPCallout from '@salesforce/apex/GCPCalloutForSimilarCases.makeGCPCallout';
import getCaseIdsByCaseNumbers from '@salesforce/apex/GCPCalloutForSimilarCases.getCaseIdsByCaseNumbers';
import logAIHEvent from '@salesforce/apex/GCPCalloutForSimilarCases.logAIHEvent';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SimilarCasesForGCP extends LightningElement {
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

    @wire(getRecord, { recordId: '$recordId', fields: [SUBJECT_FIELD, DESCRIPTION_FIELD, CASENUMBER_FIELD] })
    wiredCase({ error, data }) {
        if (data) {
            this.subject = getFieldValue(data, SUBJECT_FIELD) || '';
            this.description = getFieldValue(data, DESCRIPTION_FIELD) || '';
            this.caseNumber = getFieldValue(data, CASENUMBER_FIELD) || '';
            this.caseDataLoaded = true;
            
            // If user already expanded while waiting for data
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
            // 🔹 Fire-and-forget async view log for this subfeature
            if (!this.aihViewLogged) {
                this.aihViewLogged = true;
                logAIHEvent({ eventType: 'aih_view', subfeature: 'Similar Cases', feedback: null })
                    .catch(err => {
                        const msg = (err && (err.body && err.body.message)) || err?.message || 'Unknown error';
                        // eslint-disable-next-line no-console
                        console.warn('AIH view log failed:', msg, { recordId: this.recordId });
                    });
            }

            if (!this.isDataRetrieved) {
                // If case data hasn't loaded yet, show loading state and wait for wire
                if (!this.caseDataLoaded) {
                    this.isLoading = true;
                    // The wire will trigger makeCallout() when data arrives
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
    autoExpandSimilarCases() {
        if (!this.isVisible) {
            this.toggleContent();
        }
    }

    _applyRenderState(row) {
        // Variant: border vs border-filled
        row.likeVariant = row.isLiked ? 'border-filled' : 'border';
        row.dislikeVariant = row.isDisliked ? 'border-filled' : 'border';

        // Optional class for your subtle fill styling
        row.likeClass = row.isLiked ? 'icon-selected' : '';
        row.dislikeClass = row.isDisliked ? 'icon-selected' : '';

        // Keep both clickable; only block while busy
        row.likeDisabled = !!row.actionBusy;
        row.dislikeDisabled = !!row.actionBusy;
    }


    async makeCallout() {
        this.isLoading = true;
        this.isError = false;
        this.formattedResponse = [];
        this.rawResponse = '';

        try {
            const result = await makeGCPCallout({
                userId: this.loggedInUserId,
                subject: this.subject,
                recordId: this.recordId,
                description: this.description
            });

            let parsed;
            try {
                parsed = JSON.parse(result);
            } catch {
                this.rawResponse = 'Failed to parse response:\n' + result;
                this.isError = true;
                return;
            }

            if (parsed.success === true && Array.isArray(parsed.cases)) {
                const caseList = parsed.cases;
                const caseNumbers = caseList.map(c => c.case_number);
                const idMap = await getCaseIdsByCaseNumbers({ caseNumbers });

                if (!idMap) {
                    this.rawResponse = 'Unable to resolve case IDs.';
                    this.isError = true;
                    return;
                }

                this.formattedResponse = parsed.cases.map(c => {
                    const row = {
                        case_number: c.case_number,
                        subject: c.subject,
                        caseId: idMap[c.case_number] || null,
                        caseUrl: idMap[c.case_number] ? '/' + idMap[c.case_number] : null,

                        feedback: '',
                        showFeedback: false,
                        actionBusy: false,
                        reviewed: false,

                        selectedAction: null,   // 'like' | 'dislike' | null
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
                    if (maybeError.error || maybeError.details) {
                        isRealError = true;
                    }
                } catch (e) {
                    console.warn('SimilarCases: non-JSON error payload in parsed.message', {
                        message: parsed.message,
                        error: e?.message
                    });
                }
                if (isRealError) {
                    this.rawResponse = "We're facing a temporary issue retrieving similar cases, Please contact your administrator if the issue persists.";
                } else {
                    this.rawResponse = parsed.message;
                }
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
        row.feedbackClass = row.inputError && !row.canSend
            ? 'feedback-textarea invalid'
            : 'feedback-textarea';
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
        await this._send(idx, 'aih_feedback');
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

    // builds the tiny identifier payload for like/dislike
    _buildReactionPayload(row, choice) {
        return {
            feature: 'SimilarCases',
            parentNumber: this.caseNumber, // current record's CaseNumber
            itemType: 'Case',
            itemNumber: row.case_number,   // suggested CaseNumber
            action: choice                 // 'like' | 'dislike'
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

        // Remember previous state for rollback
        const prevSelected = row.selectedAction;
        const prevLiked = row.isLiked;
        const prevDisliked = row.isDisliked;

        // Optimistic UI
        row.selectedAction = choice || row.selectedAction;
        row.isLiked = row.selectedAction === 'like';
        row.isDisliked = row.selectedAction === 'dislike';
        this._applyRenderState(row);
        this.formattedResponse = [...this.formattedResponse];

        try {
            row.actionBusy = true;

            this.formattedResponse = [...this.formattedResponse];

            // 🔹 Send a small payload so the server can dedupe per item
            const feedbackPayload = this._buildReactionPayload(row, row.selectedAction);
            await logAIHEvent({
                eventType: type, // 'aih_like' | 'aih_dislike'
                subfeature: 'Similar Cases',
                feedback: JSON.stringify(feedbackPayload)
            });
        } catch (e) {
            // Roll back optimistic UI
            row.selectedAction = prevSelected;
            row.isLiked = prevLiked;
            row.isDisliked = prevDisliked;
            this._applyRenderState(row);
            this.formattedResponse = [...this.formattedResponse];

            // Soft-log for diagnostics
            // eslint-disable-next-line no-console
            console.warn('SimilarCases: failed to log reaction', {
                eventType: type,
                selectedAction: choice,
                caseNumber: row.case_number,
                error: e?.message || e
            });

            // Let the user know the log didn’t stick
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Couldn’t record your reaction',
                    message: 'Please try again in a moment.',
                    variant: 'warning'
                })
            );
        } finally {
            row.actionBusy = false;
            this._applyRenderState(row);
            this.formattedResponse = [...this.formattedResponse];
        }
    }

    async _send(idx, type) {
        const row = this.formattedResponse[idx];
        row.actionBusy = true;
        this._updateFeedbackState(row);

        try {
            if (type === 'aih_feedback') {
                // Build structured feedback for this row
                const reason = (row.feedback || '').trim();
                const feedbackPayload = {
                    feature: 'SimilarCases',
                    parentNumber: this.caseNumber,       // current CaseNumber (not Id)
                    itemType: 'Case',
                    itemNumber: row.case_number,         // row CaseNumber (not Id)
                    reason: reason
                };

                await logAIHEvent({
                    eventType: 'aih_feedback',
                    subfeature: 'Similar Cases',
                    feedback: JSON.stringify(feedbackPayload)
                });


                row.reviewed = true;
                row.showFeedback = false;
                this._applyRenderState(row);
            }

            this.dispatchEvent(new ShowToastEvent({
                title: 'Thank you!',
                message: 'Your review was submitted.',
                variant: 'success'
            }));
        } catch (e) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Could not submit review.',
                variant: 'error'
            }));
        } finally {
            row.actionBusy = false;
            this._updateFeedbackState(row);
            this.formattedResponse = [...this.formattedResponse];
        }
    }
}