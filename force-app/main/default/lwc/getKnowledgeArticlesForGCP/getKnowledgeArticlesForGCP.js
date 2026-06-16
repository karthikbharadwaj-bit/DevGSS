import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import SUBJECT_FIELD from '@salesforce/schema/Case.Subject';
import DESCRIPTION_FIELD from '@salesforce/schema/Case.Description';
import CASENUMBER_FIELD from '@salesforce/schema/Case.CaseNumber';
import OPEN_L1 from '@salesforce/schema/Case.OpenCustomerSupportLevel1__c';
import INT_L1 from '@salesforce/schema/Case.OpenInternalWorkflowLevel1__c';
import OPEN_L2 from '@salesforce/schema/Case.OpenCustomerSupportLevel2__c';
import INT_L2 from '@salesforce/schema/Case.OpenInternalWorkflowLevel2__c';
import OPEN_L3 from '@salesforce/schema/Case.OpenCustomerSupportLevel3__c';
import INT_L3 from '@salesforce/schema/Case.OpenInternalWorkflowLevel3__c';
import PRODUCT_TYPE from '@salesforce/schema/Case.ProductType__c';
import MODEL_PLATFORM from '@salesforce/schema/Case.ProductVersionModelPlatform__c';

import makeGCPCallout from '@salesforce/apex/GCPCalloutForKnowledgeArticles.makeGCPCallout';
import getArticleIdsByArticleNumbers from '@salesforce/apex/GCPCalloutForKnowledgeArticles.getArticleIdsByArticleNumbers';
import logAIHEvent from '@salesforce/apex/GCPCalloutForKnowledgeArticles.logAIHEvent';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const SUBFEATURE = 'Similar Articles';

export default class GetKnowledgeArticlesForGCP extends LightningElement {
    @api recordId;
    @api embedded = false;
    loggedInUserId = USER_ID;
    subject = '';
    description = '';
    caseNumber = '';
    functionVal = '';
    specificIssue = '';
    issueOccurrence = '';
    product = '';
    modelVersionPlatform = '';
    customerSentiment = '';
    managerSentiment = '';
    _viewLogRetryScheduled = false;
    @track formattedResponse = [];
    @track rawResponse = '';
    @track isLoading = false;
    @track isError = false;
    @track isVisible = false;
    isDataRetrieved = false;
    aihViewLogged = false;
    wiredDataLoaded = false;
    _wiredDataResolve = null;
    _wiredDataPromise = null;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [
            SUBJECT_FIELD, DESCRIPTION_FIELD, CASENUMBER_FIELD,
            OPEN_L1, INT_L1, OPEN_L2, INT_L2, OPEN_L3, INT_L3,
            PRODUCT_TYPE, MODEL_PLATFORM
        ]
    })
    wiredCase({ error, data }) {
        if (data) {
            const getVal = (field1, field2 = null) => {
                const val1 = getFieldValue(data, field1);
                const val2 = field2 ? getFieldValue(data, field2) : null;
                return val1 || val2 || '';
            };
            this.subject = getFieldValue(data, SUBJECT_FIELD) || '';
            this.description = getFieldValue(data, DESCRIPTION_FIELD) || '';
            this.caseNumber = getFieldValue(data, CASENUMBER_FIELD) || '';
            this.functionVal = getVal(OPEN_L1, INT_L1);
            this.specificIssue = getVal(OPEN_L2, INT_L2);
            this.issueOccurrence = getVal(OPEN_L3, INT_L3);
            this.product = getVal(PRODUCT_TYPE);
            this.modelVersionPlatform = getVal(MODEL_PLATFORM);
            this.wiredDataLoaded = true;

            // resolve the promise for awaiting to proceed
            if (this._wiredDataResolve) {
                this._wiredDataResolve();
            }
        } else if (error) {
            this.rawResponse = 'Error loading case data: ' + JSON.stringify(error);
            this.isError = true;
            this.wiredDataLoaded = true;

            // resolve promise error to prevent waiting
            if (this._wiredDataResolve) {
                this._wiredDataResolve();
            }
        }
    }

    async _ensureWiredDataLoaded() {
        if (this.wiredDataLoaded) {
            return; // Already loaded
        }

        // preventive promise
        if (!this._wiredDataPromise) {
            this._wiredDataPromise = new Promise((resolve) => {
                this._wiredDataResolve = resolve;
            });
        }

        await this._wiredDataPromise;
    }

    // 🔸 log-once helper
    _ensureViewLogged() {
        if (this.aihViewLogged || this._viewLogRetryScheduled) return;

        this.aihViewLogged = true;

        logAIHEvent({ eventType: 'aih_view', subfeature: SUBFEATURE, feedback: null })
            .catch((e) => {
                // Soft-log for diagnostics
                // eslint-disable-next-line no-console
                console.warn('SimilarCases: failed to log aih_view', {
                    subfeature: SUBFEATURE,
                    error: e?.message || e
                });

                // Allow a retry later
                this.aihViewLogged = false;

                // Schedule ONE silent retry if the section is still visible
                this._viewLogRetryScheduled = true;
                window.setTimeout(() => {
                    this._viewLogRetryScheduled = false;
                    if (this.isVisible && !this.aihViewLogged) {
                        // try again once
                        this._ensureViewLogged();
                    }
                }, 3000);
            });
    }

    async toggleContent() {
        this.isVisible = !this.isVisible;
        if (this.isVisible) {
            this._ensureViewLogged();               // ✅ counts views when user clicks the chevron
            
            if (!this.isDataRetrieved && !this.isLoading) {
                this.isLoading = true; // Show loading
                await this._ensureWiredDataLoaded(); // to wait
                this.makeCallout();
            }
        }
    }

    @api async load() {
        if (!this.isVisible) this.isVisible = true;
        this._ensureViewLogged();
        if (!this.isDataRetrieved && !this.isLoading) {
            this.dispatchEvent(new CustomEvent('kaloading'));
            this.isLoading = true;
            await this._ensureWiredDataLoaded();
            await this.makeCallout();
            this.dispatchEvent(new CustomEvent('kaloaded'));
        }
    }

    @api async autoOpenArticles() {
        // auto-open path from gcp_tab togglecontent not called
        if (!this.isVisible) this.isVisible = true;
        this._ensureViewLogged();                 // ✅ counts views for programmatic open
        
        if (!this.isDataRetrieved && !this.isLoading) {
            this.isLoading = true; // Show loading immediately
            await this._ensureWiredDataLoaded(); // Wait for case data
            this.makeCallout();
        }
    }

    @api resetData() {
        this.isDataRetrieved = false;
        this.formattedResponse = [];
        this.rawResponse = '';
        this.isError = false;
        this.isVisible = false;
        this.aihViewLogged = false;
    }

    async makeCallout() {
        this._ensureViewLogged();
        this.isLoading = true;
        this.isError = false;
        this.formattedResponse = [];
        this.rawResponse = '';

        // check that subject and description are not empty
        const hasSubject = this.subject && this.subject.trim().length > 0;
        const hasDescription = this.description && this.description.trim().length > 0;

        if (!hasSubject || !hasDescription) {
            this.rawResponse = 'Case Subject or Description is missing.';
            this.isError = true;
            this.isDataRetrieved = true;
            this.isLoading = false;
            return;
        }
        try {
            const result = await makeGCPCallout({
                userId: this.loggedInUserId,
                subject: this.subject,
                description: this.description,
                recordId: this.recordId,
                functionVal: this.functionVal,
                specificIssue: this.specificIssue,
                issueOccurrence: this.issueOccurrence,
                product: this.product,
                modelVersionPlatform: this.modelVersionPlatform,
                customerSentiment: this.customerSentiment,
                managerSentiment: this.managerSentiment
            });
            let parsed;
            try {
                parsed = JSON.parse(result);
            } catch (parseError) {
                this.rawResponse = 'Failed to parse response:\n' + result;
                this.isError = true;
                this.isDataRetrieved = true;
                return;
            }
            if (parsed.success === true && Array.isArray(parsed.articles)) {
                const articleList = parsed.articles;
                const articleNumbers = articleList.map(k => k.article_number);
                const idMap = await getArticleIdsByArticleNumbers({ articleNumbers });
                this.formattedResponse = articleList.map(k => {
                    const articleId = idMap[k.article_number] || null;
                    const row = {
                        article_number: k.article_number,
                        title: k.title,
                        summary: k.summary,
                        articleId,
                        articleUrl: articleId ? `/lightning/r/Knowledge__kav/${articleId}/view` : null,

                        // UI state
                        feedback: '',
                        showFeedback: false,
                        actionBusy: false,
                        reviewed: false,

                        // reactions
                        selectedAction: null, // 'like' | 'dislike' | null
                        isLiked: false,
                        isDisliked: false,

                        // feedback controls
                        canSend: false,
                        inputError: false,
                        feedbackClass: 'feedback-textarea',
                        sendDisabled: true,

                        // icon variants
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
                    // Not JSON: log for diagnostics and try a lightweight heuristic
                    // eslint-disable-next-line no-console
                    console.warn('SimilarArticles: non-JSON error payload in parsed.message', {
                        message: parsed.message,
                        error: e?.message || e
                    });

                    // Heuristic: treat as a real error if it looks like a server/stack message
                    const msg = String(parsed.message).toLowerCase();
                    if (
                        msg.includes('exception') ||
                        msg.includes('stack') ||
                        msg.includes('timeout') ||
                        msg.includes('failed') ||
                        msg.includes('error')
                    ) {
                        isRealError = true;
                    }
                }
                if (isRealError) {
                    this.rawResponse = "We're facing a temporary issue retrieving articles, Please contact your administrator if the issue persists.";
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
            this.isDataRetrieved = true;
        } finally {
            this.isLoading = false;
        }
    }

    _applyRenderState(row) {
        row.likeVariant = row.isLiked ? 'border-filled' : 'border';
        row.dislikeVariant = row.isDisliked ? 'border-filled' : 'border';
        // actionBusy already disables both buttons via template binding
    }

    _updateFeedbackState(row) {
        row.canSend = !!(row.feedback && row.feedback.trim().length > 0);
        row.sendDisabled = row.actionBusy || !row.canSend;
        row.feedbackClass = row.inputError && !row.canSend ? 'feedback-textarea invalid' : 'feedback-textarea';
    }


    /* ===== UI handlers ===== */

    onFeedbackChange(e) {
        const idx = Number(e.currentTarget.dataset.idx);
        if (!Number.isInteger(idx) || !this.formattedResponse[idx]) return;
        const row = this.formattedResponse[idx];
        row.feedback = e.target.value || '';
        row.inputError = false;
        this._updateFeedbackState(row);
        this.formattedResponse = [...this.formattedResponse];
    }

    onCancelFeedback(e) {
        const idx = Number(e.currentTarget.dataset.idx);
        if (!Number.isInteger(idx) || !this.formattedResponse[idx]) return;
        const row = this.formattedResponse[idx];
        row.showFeedback = false;
        row.inputError = false;           // keep what they typed; set to '' if you want to clear
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
            feature: 'SimilarArticles',
            parentNumber: this.caseNumber, // current Case Number (not Id)
            itemType: 'Article',
            itemNumber: row.article_number, // suggested Article Number
            action: choice                  // 'like' | 'dislike'
        };
    }

    async onLike(e) {
        await this._tapReaction(e, 'aih_like', 'like');
    }

    async onDislike(e) {
        await this._tapReaction(e, 'aih_dislike', 'dislike');
    }

    async _tapReaction(e, eventType, choice) {
        const idx = Number(e.currentTarget.dataset.idx);
        if (!Number.isInteger(idx) || !this.formattedResponse[idx]) return;

        const row = this.formattedResponse[idx];
        row.selectedAction = choice;
        row.isLiked = choice === 'like';
        row.isDisliked = choice === 'dislike';
        this._applyRenderState(row);
        this.formattedResponse = [...this.formattedResponse];

        try {
            row.actionBusy = true;
            // Send a compact payload so the platform can identify & dedupe reactions per article
            const payload = this._buildReactionPayload(row, choice);
            await logAIHEvent({
                eventType,                     // 'aih_like' | 'aih_dislike'
                subfeature: SUBFEATURE,        // 'Similar Articles'
                feedback: JSON.stringify(payload)
            });
        } catch (err) {
            // rollback optimistic UI
            row.selectedAction = prev.selectedAction;
            row.isLiked = prev.isLiked;
            row.isDisliked = prev.isDisliked;
            // eslint-disable-next-line no-console
            console.warn('AIH reaction log failed', {
                eventType,
                choice,
                rowKey: row.article_number || row.case_number,
                error: err?.message || err
            });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Could not record your reaction',
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
                feature: 'SimilarArticles',
                parentNumber: this.caseNumber,
                itemType: 'Article',
                itemNumber: row.article_number,
                reason: row.feedback.trim()
            };
            await logAIHEvent({
                eventType: 'aih_feedback',
                subfeature: SUBFEATURE,
                feedback: JSON.stringify(payload)
            });
            row.reviewed = true;
            row.showFeedback = false;
            this.dispatchEvent(new ShowToastEvent({
                title: 'Thank you!',
                message: 'Your review was submitted.',
                variant: 'success'
            }));
        } catch {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Could not submit review.',
                variant: 'error'
            }));
        } finally {
            row.actionBusy = false;
            this._updateFeedbackState(row);
            this._applyRenderState(row);
            this.formattedResponse = [...this.formattedResponse];
        }
    }
}