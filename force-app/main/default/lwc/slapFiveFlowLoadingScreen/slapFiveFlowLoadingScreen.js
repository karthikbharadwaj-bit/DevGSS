import { LightningElement, api } from 'lwc';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';
import getAsyncApexJobStatus
    from '@salesforce/apex/SlapFiveQueueableJobStatusController.getAsyncApexJobStatus';

export default class SlapFiveFlowLoadingScreen extends LightningElement {
    // INPUT from Flow
    @api jobId;

    // OUTPUT to Flow
    @api flowResult;

    // Polling config
    pollIntervalMs = 3000;     // check every 3s
    maxWaitMs = 60000;        // stop after 1 minute
    _pollTimer;
    _startedAt;

    connectedCallback() {
        console.log('SlapFive spinner started. JobId:', this.jobId);

        this.flowResult = null;

        if (!this.jobId) {
            this.flowResult = 'MissingJobId';
            this.dispatchEvent(new FlowNavigationNextEvent());
            return;
        }

        this._startedAt = Date.now();
        this.startPolling();
    }

    disconnectedCallback() {
        this.stopPolling();
    }

    startPolling() {
        // run immediately, then on interval
        this.pollOnce();

        this._pollTimer = window.setInterval(() => {
            this.pollOnce();
        }, this.pollIntervalMs);
    }

    stopPolling() {
        if (this._pollTimer) {
            window.clearInterval(this._pollTimer);
            this._pollTimer = null;
        }
    }

    isTerminal(status) {
        return status === 'Completed' || status === 'Failed' || status === 'Aborted';
    }

    async pollOnce() {
        // Timeout guard
        const elapsed = Date.now() - this._startedAt;
        if (elapsed >= this.maxWaitMs) {
            console.warn('SlapFive job polling timed out after ms:', elapsed);
            this.stopPolling();
            this.flowResult = 'Timeout';
            this.dispatchEvent(new FlowNavigationNextEvent());
            return;
        }

        try {
            const status = await getAsyncApexJobStatus({ jobId: this.jobId });
            console.log('SlapFive job status (poll):', status);

            if (this.isTerminal(status)) {
                this.stopPolling();
                this.flowResult = status;
                this.dispatchEvent(new FlowNavigationNextEvent());
                return;
            }

            // still running: Queued / Processing / Holding, etc.
            // do nothing and keep polling
        } catch (e) {
            console.error('SlapFive job status poll failed:', e);
            this.stopPolling();
            this.flowResult = 'Error';
            this.dispatchEvent(new FlowNavigationNextEvent());
        }
    }
}