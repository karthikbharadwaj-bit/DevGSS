import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import hasSupportAgent from '@salesforce/customPermission/Support_Agent_AI_GCP';
import USER_ID from '@salesforce/user/Id';
import identifyCaseSentimentEscalation
    from '@salesforce/apex/CaseAIInsightsProcessor.identifyCaseSentimentEscalation';

// (we still use Case fields for age & visibility)
import CASE_AGE from '@salesforce/schema/Case.Case_Age__c';
import CASE_CREATED from '@salesforce/schema/Case.CreatedDate';
import CASE_IS_CLOSED from '@salesforce/schema/Case.IsClosed';
import CASE_STATUS from '@salesforce/schema/Case.Status';
const FIELDS = [CASE_CREATED, CASE_IS_CLOSED, CASE_STATUS];

export default class CaseBanner extends LightningElement {
    @api recordId;
    @api maxWidth = '760px';
    @api align = 'center';
    get shellStyle() {
        return `max-width:${this.maxWidth}; margin:${this.align === 'left' ? '0' : '0 auto'};`;
    }

    hasSupportAgent = hasSupportAgent;

    // for age & visibility
    createdDateISO = null;
    isClosed = null;
    status = null;

    // GCP data (truth source)
    _requestedGcp = false;
    gcpLoaded = false;

    gcpSentiment;          // 'Positive' | 'Neutral' | 'Negative'
    gcpSentimentReason;    // explanation text
    gcpSentimentError;     // error text (if any)

    gcpEscMetric;          // 'Stable' | 'Likely to Escalate' | 'Escalated'
    gcpEscReason;          // explanation text
    gcpEscError;           // error text (if any)

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredCase({ data, error }) {
        if (data) {
            this.createdDateISO = getFieldValue(data, CASE_CREATED) || null;
            this.isClosed = getFieldValue(data, CASE_IS_CLOSED);
            this.status = getFieldValue(data, CASE_STATUS);
            this.maybeLoadGcp();
        } else if (error) {
            // if LDS fails, hide banner safely
            this.isClosed = true;
        }
    }

    maybeLoadGcp() {
        if (this.shouldShow && !this._requestedGcp) {
            this._requestedGcp = true;
            this.loadGcpMetrics();
        }
    }

    async loadGcpMetrics() {
        try {
            const raw = await identifyCaseSentimentEscalation({ userId: USER_ID, caseId: this.recordId });
            const res = JSON.parse(raw || '{}') || {};

            // sentiment (api1)
            if (res.sentiment) this.gcpSentiment = res.sentiment;
            if (res.sentiment_reason) this.gcpSentimentReason = res.sentiment_reason;
            if (res.sentiment_error) this.gcpSentimentError = String(res.sentiment_error);

            // escalation (api2)
            if (res.escalation_metric) this.gcpEscMetric = res.escalation_metric;
            if (res.escalation_reason) this.gcpEscReason = res.escalation_reason;
            if (res.escalation_error) this.gcpEscError = String(res.escalation_error);

            // Back-compat: if older Apex returns {success:false,message}
            if (!res.sentiment && !res.escalation_metric && res.success === false && res.message) {
                this.gcpSentimentError = this.gcpSentimentError || res.message;
                this.gcpEscError = this.gcpEscError || res.message;
            }
        } catch (_e) {
            // hard failure – show generic errors for both
            const msg = 'AI service unavailable';
            this.gcpSentimentError = this.gcpSentimentError || msg;
            this.gcpEscError = this.gcpEscError || msg;
        } finally {
            this.gcpLoaded = true;
        }
    }

    /* visibility */
    get shouldShow() {
        const isResolved = this.status === 'Resolved';
        return this.hasSupportAgent && this.isClosed === false && !isResolved;
    }
    get waitingGcp() {
        return this.shouldShow && !this.gcpLoaded;
    }

    /* age */
    get caseAgeLabel() {
        if (this.createdDateISO) {
            const days = this.daysBetween(new Date(this.createdDateISO), new Date());
            return `${days} day${days === 1 ? '' : 's'}`;
        }
        return '—';
    }
    daysBetween(s, e) {
        try {
            return Math.floor(Math.max(0, e - s) / 86400000);
        } catch {
            return 0;
        }
    }

    /* sentiment getters – ONLY use GCP */
    get hasSentiment() {
        return !!this.gcpSentiment;
    }
    get sentimentLabel() {
        return this.gcpSentiment || '—';
    }
    get sentimentReason() {
        return this.gcpSentiment ? (this.gcpSentimentReason || '') : '';
    }
    get sentimentError() {
        return !this.gcpSentiment ? (this.gcpSentimentError || '') : '';
    }
    get sentimentClass() {
        return `sentiment-pill ${(this.gcpSentiment || '').toLowerCase()}`;
    }

    /* escalation getters – ONLY use GCP */
    get hasEscalation() {
        return !!this.gcpEscMetric;
    }
    get escalationLabel() {
        return this.gcpEscMetric || '—';
    }
    get escalationReason() {
        return this.gcpEscMetric ? (this.gcpEscReason || '') : '';
    }
    get escalationError() {
        return !this.gcpEscMetric ? (this.gcpEscError || '') : '';
    }
    get escalationClass() {
        const v = (this.gcpEscMetric || '').toLowerCase();
        let tone = '';
        if (v.includes('escalated')) tone = 'escalated';
        else if (v.includes('likely')) tone = 'likely';
        else if (v.includes('stable')) tone = 'stable';
        return `escalation-pill ${tone}`.trim();
    }
}