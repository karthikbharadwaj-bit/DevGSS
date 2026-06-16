import { LightningElement, api, track } from "lwc";

const baseStyle = "slds-col slds-grid slds-wrap breakword";
const twoColumnStyle = " slds-size_5-of-12 slds-p-around_medium";

export default class LeadHighlighterComponent extends LightningElement {
    @api recordId;
    @api appData;
    @api contactParentAccount;
    @track componentData;

    get showAlerts() {
        return (
            this.componentData.isDoNotDirectMail ||
            this.componentData.isBTApproved ||
            this.componentData.domainType != null ||
            this.componentData.emailTitle != null ||
            this.componentData.emailMessage != null ||
            this.componentDataisDoNotCall ||
            this.componentData.isHasOptedOutOfEmail ||
            this.componentData.isDoNotSMS
        );
    }

    get isSia() {
        return this.componentData && this.componentData.isSia;
    }

    get columnSizeSecond() {
        const threeColumnStyle = " slds-size_1-of-3 slds-m-top_medium slds-m-bottom_medium";
        return this.isSia ? baseStyle + threeColumnStyle : baseStyle + twoColumnStyle;
    }

    get columnSizeFirst() {
        const threeColumnStyle = " slds-size_1-of-3 slds-m-top_medium slds-m-bottom_medium slds-p-left_medium";
        return this.isSia ? baseStyle + threeColumnStyle : baseStyle + twoColumnStyle;
    }

    get showDoNotEmailGermany() {
        this.componentData.contact.Account.BillingCountry == "Germany";
    }

    connectedCallback() {
        this.setComponentData(this.appData);
    }

    @api
    setComponentData(data) {
        this.componentData = data;
    }
}