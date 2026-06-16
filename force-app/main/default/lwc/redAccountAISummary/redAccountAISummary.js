import { LightningElement, api, track } from 'lwc';
import USER_ID from '@salesforce/user/Id';
import generateSummary from '@salesforce/apex/AISummaryController.generateRedAccountSummary';
import logAIHEvent from '@salesforce/apex/AISummaryController.logAIHEvent';
import isRedAccountSummaryEnabled from '@salesforce/apex/AISummaryController.isRedAccountSummaryEnabled';
import hasAIReporting from '@salesforce/customPermission/AI_Reporting_Access';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const SUBFEATURE = 'Red Account Summary';

export default class RedAccountAISummary extends LightningElement {
    @api recordId;

    @track overallPoints = [];
    @track riskPoints = [];
    @track statusPoints = [];
    @track nextStepsPoints = [];
    @track isLoading = false;
    @track isExpanded = false;
    @track canShowSummary = false;
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
    @track hasError = false;
    @track infoMessage = '';
    @track hasInfoMessage = false;

    connectedCallback() {
        this.initializeAccess();
    }

    async initializeAccess() {
        if (!hasAIReporting) {
            this.canShowSummary = false;
            return;
        }

        try {
            this.canShowSummary = await isRedAccountSummaryEnabled();
            // Removed fetchSummary() — will be called on accordion expand (lazy load)
        } catch (err) {
            this.canShowSummary = false;
            // eslint-disable-next-line no-console
            console.warn('Red Account AI Summary access check failed', { error: err?.message || err });
        }
    }

    handleAccordionToggle() {
        if (this.isExpanded && !this.hasFetched) {
            this.isLoading = true;
            this._ensureViewLogged();
            this.fetchSummary();
        }
    }

    get previewText() {
        if (this.isLoading) return 'Loading summary…';
        return this.overallPoints.length ? this.overallPoints[0] : (this.riskPoints[0] || '');
    }

    get toggleLabel() {
        return this.isExpanded ? '▲ Hide' : '▼ Show more';
    }

    toggleExpand() {
        this.isExpanded = !this.isExpanded;
        if (this.isExpanded) {
            this.handleAccordionToggle();
        }
    }

    _parseSections(summaryText) {
        const MAP = { 'Overall Summary': 'overall', 'Risk Reason': 'risk', 'Current Status': 'status', 'Next Steps': 'nextSteps' };
        const sections = { overall: [], risk: [], status: [], nextSteps: [] };
        let current = null;
        for (const raw of summaryText.split('\n')) {
            const line = raw.trim();
            if (!line) continue;
            if (MAP[line] !== undefined) { current = MAP[line]; }
            else if (current) { sections[current].push(line.replace(/^-\s*/, '')); }
        }
        return sections;
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
                this.overallPoints = sections.overall;
                this.riskPoints = sections.risk;
                this.statusPoints = sections.status;
                this.nextStepsPoints = sections.nextSteps;
                this.hasError = false;
                this.infoMessage = '';
                this.hasInfoMessage = false;
            } else if (parsed && parsed.success) {
                this.overallPoints = [];
                this.riskPoints = [];
                this.statusPoints = [];
                this.nextStepsPoints = [];
                this.hasError = false;
                this.infoMessage = parsed.message || '';
                this.hasInfoMessage = true;
            } else {
                this.overallPoints = [];
                this.riskPoints = [];
                this.statusPoints = [];
                this.nextStepsPoints = [];
                this.hasError = true;
                this.infoMessage = '';
                this.hasInfoMessage = false;
            }
            this.hasFetched = true;
        } catch (_e) {
            this.hasError = true;
            this.overallPoints = [];
            this.riskPoints = [];
            this.statusPoints = [];
            this.nextStepsPoints = [];
            this.infoMessage = '';
            this.hasInfoMessage = false;
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
        return { feature: 'RedAccountSummary', parentNumber: this.recordId, itemType: 'RedAccount', itemNumber: this.recordId, action: choice };
    }

    async _react(eventType, choice) {
        const prevLiked = this.summaryIsLiked;
        const prevDisliked = this.summaryIsDisliked;
        this.summaryIsLiked = choice === 'like';
        this.summaryIsDisliked = choice === 'dislike';
        this._applyIconVariants();
        try {
            this.summaryBusy = true;
            await logAIHEvent({ eventType, subfeature: SUBFEATURE, feedback: JSON.stringify(this._buildReactionPayload(choice)) });
        } catch (err) {
            this.summaryIsLiked = prevLiked;
            this.summaryIsDisliked = prevDisliked;
            this.dispatchEvent(new ShowToastEvent({ title: 'Couldn\'t save your reaction', message: 'Network hiccup or server issue. You can try again.', variant: 'info' }));
        } finally {
            this.summaryBusy = false;
            this._applyIconVariants();
        }
    }

    toggleFeedback = () => { this.showFeedback = !this.showFeedback; this.inputError = false; this._updateFeedbackState(); };
    onFeedbackChange = (e) => { this.feedback = e.target.value || ''; this.inputError = false; this._updateFeedbackState(); };
    onCancelFeedback = () => { this.showFeedback = false; this.inputError = false; this._updateFeedbackState(); };

    onFeedbackKeydown = (e) => {
        if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); if (this.sendDisabled) { this.inputError = true; this._updateFeedbackState(); return; } this.onSendFeedback(); }
        else if (e.key === 'Escape') { e.preventDefault(); this.onCancelFeedback(); }
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
            const payload = { feature: 'RedAccountSummary', parentNumber: this.recordId, itemType: 'RedAccount', itemNumber: this.recordId, reason: (this.feedback || '').trim() };
            await logAIHEvent({ eventType: 'aih_feedback', subfeature: SUBFEATURE, feedback: JSON.stringify(payload) });
            this.summaryReviewed = true; this.showFeedback = false;
            this.dispatchEvent(new ShowToastEvent({ title: 'Thank you!', message: 'Your feedback was submitted.', variant: 'success' }));
        } catch (err) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: 'Could not submit feedback.', variant: 'error' }));
        } finally { this.summaryBusy = false; this._updateFeedbackState(); this._applyIconVariants(); }
    }

    async handleCopy() {
        const allPoints = [
            ...this.overallPoints.map(p => `• ${p}`),
            ...this.riskPoints.map(p => `• ${p}`),
            ...this.statusPoints.map(p => `• ${p}`),
            ...this.nextStepsPoints.map(p => `• ${p}`)
        ];
        const txtArea = document.createElement('textarea');
        txtArea.value = allPoints.join('\n');
        txtArea.style.position = 'fixed'; txtArea.style.left = '-999999px';
        document.body.appendChild(txtArea); txtArea.focus(); txtArea.select();
        try { document.execCommand('copy'); this.copyIcon = 'utility:check'; setTimeout(() => { this.copyIcon = 'utility:copy'; }, 2000); }
        catch (err) { console.error('Fallback copy failed:', err); }
        document.body.removeChild(txtArea);
    }
}