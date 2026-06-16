import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import ACCOUNT_MASTER_ID from '@salesforce/schema/Account.Master_Account__c';
import OPPTY_MASTER_ID from '@salesforce/schema/Opportunity.MasterOpportunity__c';
import QUOTE_MASTER_ID from '@salesforce/schema/Quote.MasterQuote__c';
    
const ACCOUNT_FIELDS = [ACCOUNT_MASTER_ID];
const OPPORTUNITY_FIELDS = [OPPTY_MASTER_ID];
const QUOTE_FIELDS = [QUOTE_MASTER_ID];

let objectFields = [];
export default class TechnicalObjectWarning extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api url;
    @api showSpinner;

    @wire(getRecord, { recordId: '$recordId', fields: objectFields })
    wireRecord({data}){
        if (data) {
            if (this.objectApiName === 'Account') {
                this.url = window.location.origin + "/lightning/r/" + this.objectApiName + '/' + data.fields.Master_Account__c.value + "/view";
            }
            if (this.objectApiName === 'Opportunity') {
                this.url = window.location.origin + "/lightning/r/" + this.objectApiName + '/' + data.fields.MasterOpportunity__c.value + "/view";
            }
            if (this.objectApiName === 'Quote') {
                this.url = window.location.origin + "/lightning/r/" + this.objectApiName + '/' + data.fields.MasterQuote__c.value + "/view";
            }
        }
        this.showSpinner = false;
    }

    connectedCallback() {
        if (this.objectApiName === 'Account') {
            objectFields = ACCOUNT_FIELDS;
        }
        if (this.objectApiName === 'Opportunity') {
            objectFields = OPPORTUNITY_FIELDS;
        }
        if (this.objectApiName === 'Quote') {
            objectFields = QUOTE_FIELDS;
        }
        
        this.showSpinner = true;
    }
}