import { LightningElement, api, track } from 'lwc';
import USER_ID from '@salesforce/user/Id';
import generateSummary from '@salesforce/apex/AISummaryController.generateRedAccountSummary';
import logAIHEvent from '@salesforce/apex/AISummaryController.logAIHEvent';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const SUBFEATURE = 'Red Account Summary Option D';

export default class RedAccountSummaryOptionD extends LightningElement {
    @api recordId;

    @track riskPoints = [];
    @track statusPoints = [];
    @track nextStepsPoints = [];
    @track isLoading = false;
    hasFetched = false;
    aihViewLogged = false;

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

    connectedCallback() {
        this.isLoading = true;
        this._ensureViewLogged();
        this.fetchSummary();
    }

    _ensureViewLogged() {
        if (this.aihViewLogged) return;
        this.aihViewLogged = true;
        logAIHEvent({ eventType: 'aih_view', subfeature: SUBFEATURE, feedback: null })
            .catch(err => {
                this.aihViewLogged = false;
                console.warn('AIH view log failed', { subfeature: SUBFEATURE, error: err?.message || err });
            });
    }

    async fetchSummary() {
        try {
            const result = await generateSummary({ recordId: this.recordId, userId: USER_ID });
            const parsed = JSON.parse(result);
            if (parsed && parsed.success && parsed.summary) {
                const sections = this._parseSections(parsed.summary);
                this.riskPoints = sections.risk;
                this.statusPoints = sections.status;
                this.nextStepsPoints = sections.nextSteps;
            } else {
                const msg = (parsed && parsed.message)
                    ? parsed.message
                    : 'We\'re having trouble loading your summary data. Please try again later.';
                this.riskPoints = [msg];
                this.statusPoints = [];
                this.nextStepsPoints = [];
            }
            this.hasFetched = true;
        } catch (_e) {
            this.riskPoints = ['We\'re having trouble loading your summary data. Please try again later.'];
            this.statusPoints = [];
            this.nextStepsPoints = [];
            this.hasFetched = true;
        } finally {
            this.isLoading = false;
        }
    }

    _parseSections(summaryText) {
        const MAP = { 'Overall Summary': null, 'Risk Reason': 'risk', 'Current Status': 'status', 'Next Steps': 'nextSteps' };
        const sections = { risk: [], status: [], nextSteps: [] };
        let current = null;
        for (const raw of summaryText.split('\n')) {
            const line = raw.trim();
            if (!line) continue;
            if (MAP[line] !== undefined) { current = MAP[line]; }
            else if (current) { sections[current].push(line.replace(/^-\s*/, '')); }
        }
        return sections;
    }

    async submitLike() { await this._react('aih_like', 'like'); }
    async submitDislike() { await this._react('aih_dislike', 'dislike'); }

    _applyIconVariants() {
        this.likeVariant = this.summaryIsLiked ? 'border-filled' : 'border';
        this.dislikeVariant = this.summaryIsDisliked ? 'border-filled' : 'border';
    }

    _buildReactionPayload(choice) {
        return {
            feature: 'RedAccountSummary',
            parentNumber: this.recordId,
            itemType: 'RedAccount',
            itemNumber: this.recordId,
            action: choice
        };
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
                subfeature: SUBFEATURE,
                feedback: JSON.stringify(payload)
            });
        } catch (err) {
            this.summaryIsLiked = prevLiked;
            this.summaryIsDisliked = prevDisliked;
            console.warn('Failed to log Red Account Summary reaction', {
                eventType, choice, error: err?.message || err
            });
            this.dispatchEvent(new ShowToastEvent({
                title: 'Couldn\'t save your reaction',
                message: 'Network hiccup or server issue. You can try again.',
                variant: 'info'
            }));
        } finally {
            this.summaryBusy = false;
            this._applyIconVariants();
        }
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
                feature: 'RedAccountSummary',
                parentNumber: this.recordId,
                itemType: 'RedAccount',
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
            console.warn('Red Account feedback submit failed', err?.message || err);
        } finally {
            this.summaryBusy = false;
            this._updateFeedbackState();
            this._applyIconVariants();
        }
    }

    async handleCopy() {
        const allPoints = [
            ...this.riskPoints.map(p => `• ${p}`),
            ...this.statusPoints.map(p => `• ${p}`),
            ...this.nextStepsPoints.map(p => `• ${p}`)
        ];
        const copyText = allPoints.join('\n');
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