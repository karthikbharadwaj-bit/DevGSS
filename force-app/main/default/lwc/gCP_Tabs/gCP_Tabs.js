import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import checkFeatureToggle from '@salesforce/apex/GCPFeatureToggle.isFeatureEnabled';
import checkSimilarJirasToggle from '@salesforce/apex/GCPCalloutForSimilarJiras.isSimilarJirasEnabled';
import hasAIReporting from '@salesforce/customPermission/AI_Reporting_Access';
import hasSupportAgent from '@salesforce/customPermission/Support_Agent_AI_GCP';
import aiInsightsLogo from '@salesforce/resourceUrl/AI_Insights';


export default class GcpTabs extends LightningElement {
    @api recordId;
    isFeatureEnabled = false;
    similarJirasEnabled = false;
    activeTab;
    lastRealTab;

    hasAIReporting = hasAIReporting;
    hasSupportAgent = hasSupportAgent;
    aiInsightsLogo = aiInsightsLogo;

    get hasAnyPermission() {
        return this.hasAIReporting || this.hasSupportAgent;
    }

    get showExploreMore() {
        return this.hasAnyPermission;
    }

    get showSimilarJiras() {
        return this.hasSupportAgent && this.similarJirasEnabled;
    }

    connectedCallback() {
        checkFeatureToggle()
            .then((enabled) => {
                this.isFeatureEnabled = enabled;
                if (enabled && this.hasAnyPermission) {
                    if (this.hasAIReporting) {
                        this.activeTab = 'caseSummary';
                        this.lastRealTab = 'caseSummary';
                    } else if (this.hasSupportAgent) {
                        this.activeTab = 'similarCases';
                        this.lastRealTab = 'similarCases';
                    }
                }
            })
            .catch((err) => console.warn('[GcpTabs] feature toggle error:', err));

        checkSimilarJirasToggle()
            .then((enabled) => {
                this.similarJirasEnabled = enabled;
            })
            .catch((err) => console.warn('[GcpTabs] similar jiras toggle error:', err));
    }

    handleTabsetActive(event) {
        const value = event.detail && event.detail.value;
        if (value && value !== 'ExploreMore') {
            this.activeTab = value;
            this.lastRealTab = value;
        }
    }

    handleSimilarCasesTabActive() {
        // Only auto-expand if this is NOT the first tab
        // If user only has hasSupportAgent (not hasAIReporting), similarCases is the first tab
        const isFirstTab = !this.hasAIReporting && this.hasSupportAgent;
        if (!isFirstTab) {
            setTimeout(() => {
                this.tryAutoExpandSimilarCases();
            }, 0);
        }
    }

    tryAutoExpandSimilarCases(retryCount = 0) {
        const childComponent = this.template.querySelector('c-similar-cases-for-g-c-p');
        if (childComponent && typeof childComponent.autoExpandSimilarCases === 'function') {
            childComponent.autoExpandSimilarCases();
        } else if (retryCount < 3) {
            setTimeout(() => {
                this.tryAutoExpandSimilarCases(retryCount + 1);
            }, 50 * (retryCount + 1));
        } else {
            console.warn('[GcpTabs] Failed to find similar cases component after retries');
        }
    }

    handleSimilarJirasTabActive() {
        setTimeout(() => {
            this.tryAutoExpandSimilarJiras();
        }, 0);
    }

    tryAutoExpandSimilarJiras(retryCount = 0) {
        const childComponent = this.template.querySelector('c-similar-jiras-by-g-c-p');
        if (childComponent && typeof childComponent.autoExpandSimilarJiras === 'function') {
            childComponent.autoExpandSimilarJiras();
        } else if (retryCount < 3) {
            setTimeout(() => {
                this.tryAutoExpandSimilarJiras(retryCount + 1);
            }, 50 * (retryCount + 1));
        } else {
            console.warn('[GcpTabs] Failed to find similar jiras component after retries');
        }
    }

    handleExploreActive() {
        this.openPopup();
        const backTo = this.lastRealTab || 'similarCases';
        setTimeout(() => {
            const tabset = this.template.querySelector('lightning-tabset');
            if (tabset) tabset.activeTabValue = backTo;
            this.activeTab = backTo;
        }, 0);
    }

    openPopup() {
        const url = `/apex/CaseAISummaryWrapper?recordId=${this.recordId}`;
        const win = window.open(
            url,
            '_blank',
            'width=1000,height=800,scrollbars=yes,resizable=yes'
        );
        if (win) {
            try {
                 win.focus(); 
                } catch (e) {
                    
                }
        } else {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Popup Blocked',
                    message: 'Please allow popups for this site to view the full summary.',
                    variant: 'warning'
                })
            );
        }
    }
}