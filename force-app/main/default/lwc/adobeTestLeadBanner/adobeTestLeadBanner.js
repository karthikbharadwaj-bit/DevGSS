import { LightningElement, api, wire } from 'lwc';
import isAdobeTest from "@salesforce/apex/AdobeTestLeadBannerController.isAdobeTest";
export default class AdobeTestLeadBanner extends LightningElement {
    @api recordId;
    @api objectApiName;
    isAdobeTest;
    textMessage;
    adobeName;
    adobeDescription;

    connectedCallback() {
        this.loadBanner();
    }

    loadBanner() {
        let that = this;
        isAdobeTest({ objectId: that.recordId, objectType: that.objectApiName })
            .then((value) => {
                if (value.Id != null) {
                    that.isAdobeTest = true;
                    that.textMessage = 'Note: This record is part of a test. ';
                    that.adobeDescription = value.Description__c;
                }
            })
            .catch((error) => {
                console.log(error);
            });
    }
}