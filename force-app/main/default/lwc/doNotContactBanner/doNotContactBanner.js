import { LightningElement, api, wire } from 'lwc';
import getAccount from '@salesforce/apex/DoNotContactBannerController.getAccount';
import { refreshApex } from '@salesforce/apex';

export default class DoNotContactBanner extends LightningElement {
    @api recordId;
    @api objectApiName;

    partAccountName = "";
    partAccountUrl = "";
    doNotContact = false;
    error = null;
    accountResult;

    @wire(getAccount, { recordId: '$recordId' })
    wiredAccount(result) {
        this.accountResult = result; 
        const { error, data } = result;
        if (this.objectApiName === 'Account') {
            if (data) {
                const partAccount = data.Partner_Account__r ? data.Partner_Account__r.Name : null;
                if (partAccount){
                this.partAccountName = data.Partner_Account__r.Name;
                this.partAccountUrl = `/lightning/r/Account/${data.Partner_Account__c}/view`;
                } else {
                    console.error('Partner Account property is undefined');
                }
                this.doNotContact = data.PartnerAccountDoNotContact__c;
            } else if (error) {
                this.error = error;
                console.error(error);
            }
        }
    }
    connectedCallback() {
        let that = this;
        let intervalID = setInterval(function () {
            that.refreshData();
        }, 10000);
    }
    refreshData() {
        refreshApex(this.accountResult);
    }
}