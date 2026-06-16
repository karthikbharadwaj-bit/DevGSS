import { LightningElement, api } from 'lwc';
import { ACTIVE, PROCESSING, COMPLETED } from "c/snUtils";
export default class SnTierOption extends LightningElement {
    @api tier;
    @api get status() {
        return this._status;
    };
    set status(value) {
        if (value) {
            this._status = value;
        }
    }
    @api opened;
    @api isExistingBusiness;
    @api isSyncCompleted;
    @api hasMultipleQuoteTypes;
    @api hasSingleQuoteType;
    @api singleQuoteTypeMessage;
    @api quoteSelectionOptions;
    @api selectedQuoteType;
    @api isQuoteTypeDisabled;
    _status = ACTIVE;

    statusToTextMap = new Map([
        [ACTIVE, { syncText: 'Not Synced', signUpText: 'Not Signed Up', style: 'text-not-active' }],
        [PROCESSING, { syncText: 'Syncing', signUpText: 'Signing Up', style: 'text-active' }],
        [COMPLETED, { syncText: 'Synced with NGBS', signUpText: 'Signed Up', style: 'text-completed' }]
    ]);

    get isProcessing() {
        return PROCESSING === this.status;
    }

    get isSigned() {
        return this.isSyncCompleted || COMPLETED === this.status;
    }

    get chevron() {
        return this.opened ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get currentStatusText() {
        return this.statusToTextMap.get(this.status)[this.isExistingBusiness ? 'syncText' : 'signUpText'];
    }

    get currentStatusStyle() {
        return (this.isSigned ? 'signed-margin ' : 'margin ') + this.statusToTextMap.get(this.status).style;
    }

    get titleStyle() {
        return "slds-page-header__title step-title tier-block " + (this.opened ? "opened-tier" : "closed-tier");
    }

    get containerStyle() {
        return "tier-container tier-head";
    }

    get isSelectedQuoteTypePOC() {
        return this.selectedQuoteType === "POC";
    }

    get showSingleQuoteTypeMessage() {
        return this.hasSingleQuoteType && this.isSelectedQuoteTypePOC;
    }

    handleQuoteTypeChange(event) {
        event.stopPropagation();
        const selectedQuoteType = event.target.value;
        this.dispatchEvent(
            new CustomEvent("quotetypechange", {
                detail: {
                    tier: this.tier,
                    selectedQuoteType: selectedQuoteType,
                },
            })
        );
    }

    stopPropagation(event) {
        event.stopPropagation();
    }
}