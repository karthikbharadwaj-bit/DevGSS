import { LightningElement, api, track } from 'lwc';
import USER_ID from '@salesforce/user/Id';
import generateSummary from '@salesforce/apex/AISummaryController.generateRedAccountSummary';
import logAIHEvent from '@salesforce/apex/AISummaryController.logAIHEvent';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const SUBFEATURE = 'Red Account Summary Option A';

export default class RedAccountSummaryOptionA extends LightningElement {
    @api recordId;

    @track bulletPoints = [];
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

    _extractOverallBullets(summaryText) {
        const ALL_HEADERS = new Set(['Overall Summary', 'Risk Reason', 'Current Status', 'Next Steps']);
        const lines = summaryText.split('\n').map(l => l.trim()).filter(Boolean);
        let current = null;
        const overallPoints = [];
        const riskPoints = [];
        for (const line of lines) {
            if (ALL_HEADERS.has(line)) { current = line; }
            else if (current === 'Overall Summary') { overallPoints.push(line.replace(/^-\s*/, '')); }
            else if (current === 'Risk Reason')     { riskPoints.push(line.replace(/^-\s*/, '')); }
        }
        if (overallPoints.length > 0) return overallPoints;
        if (riskPoints.length > 0)    return riskPoints;
        return lines.filter(l => !ALL_HEADERS.has(l)).map(l => l.replace(/^-\s*/, ''));
    }

    async handleFetch() {
        if (this.hasFetched || this.isLoading) return;
        this.isLoading = true;
        this._ensureViewLogged();
        await this.fetchSummary();
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
                this.bulletPoints = this._extractOverallBullets(parsed.summary);
            } else {
                const msg = (parsed && parsed.message)
                    ? parsed.message
                    : 'We\'re having trouble loading your summary data. Please try again later.';
                this.bulletPoints = [msg];
            }
            this.hasFetched = true;
        } catch (_e) {
            this.bulletPoints = ['We\'re having trouble loading your summary data. Please try again later.'];
            this.hasFetched = true;
        } finally {
            this.isLoading = false;
        }
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