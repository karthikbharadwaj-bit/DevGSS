import { LightningElement, api, wire, track } from "lwc";
import getDataForYellowBannerComponent from "@salesforce/apex/YellowBannerComponentController.getDataForYellowBannerComponent";
import { refreshApex } from "@salesforce/apex";
export default class YellowBannerComponent extends LightningElement {
    @api recordId;
    @api objectApiName;
    @track componentData = {
        leadSourceDescription: "",
        domainType: "",
        emailTitle: "",
        emailMessage: "",
        isBTApproved: false,
        isDoNotDirectMail: false,
        isDoNotCall: false,
        isHasOptedOutOfEmail: false,
        isDoNotSMS: false,
        isFreeTrialLead: false,
        mostRecentCampaignDescription: "",
        parentPartnerAccount: "",
        contactParentAccount: "",
    };
    isLoaded = false;
    BookCalClass = "slds-section slds-is-open";
    wireContainer;

    @wire(getDataForYellowBannerComponent, { recordId: "$recordId", obj: "$objectApiName" })
    getDataForYellowBannerComponent(value) {
        this.wireContainer = value;
        if (value.data != null) {
            this.componentData = value.data;
            this.hideSpinner();
        } else if (value.error) {
            console.log(value.error);
        }
    }

    connectedCallback() {
        let that = this;
        let intervalID = setInterval(function () {
            that.refreshComponentData();
        }, 10000);
    }

    get sectionTitle() {
        return this.objectApiName + " Highlights";
    }

    get showLeadComponent() {
        return this.objectApiName == "Lead" && this.isLoaded;
    }

    get showContactComponent() {
        return this.objectApiName == "Contact" && this.isLoaded;
    }

    refreshComponentData() {
        refreshApex(this.wireContainer).then(() => {
            this.componentData = this.wireContainer.data;
            if (this.showLeadComponent) {
                this.template.querySelectorAll("c-lead-highlighter-component")[0].setComponentData(this.componentData);
            } else if (this.showContactComponent) {
                this.template
                    .querySelectorAll("c-contact-highlighter-component")[0]
                    .setComponentData(this.componentData);
            }
        });
    }

    manageSection() {
        if (this.BookCalClass.includes("slds-is-open")) {
            this.BookCalClass = "slds-section";
        } else {
            this.BookCalClass = "slds-section slds-is-open";
        }
    }

    hideSpinner() {
        this.isLoaded = true;
    }
}