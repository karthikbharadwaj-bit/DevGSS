import { LightningElement, track, wire, api } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

const FIELDS = ['Case.Status','Case.RecordTypeName__c'];

export default class MedalliaCloseCaseLoop extends LightningElement {
    @api recordId;
    @track implementationRootCause;
    @track missedExpectationsRootCause;
    @track productRootCause;
    @track supportRootCause;
    @track isLoading = false;
    @track managementRootCause;
    @track policyRootCause;
    @track smsRootCause;
    @track otherRootCause;
    @track csmRootCause;
    @track billingRootCause;
    @track caseStatusClosed = false; 
    @track isRS = '';



    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (error) {
            let message = 'Unknown error';
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error loading Case',
                    message,
                    variant: 'error',
                }),
            );
        } else if (data) {
            console.log(JSON.stringify(data));
            console.log('RecordType:',data.fields.RecordTypeName__c.value);
            this.caseStatusClosed  = false;
            if(data.fields.RecordTypeName__c.value === 'Close_Loop_Feedback_Medallia_Relationship')
                this.isRS = true;
            if (data.fields.Status.value === 'Closed') 
                this.caseStatusClosed = true;
            console.log('Case Status : ' + this.caseStatusClosed)
        }
    }


    implementationRootCauseValues (event) {
        this.implementationRootCause = event.detail;
        console.log ('Implementation Root Cause : ' + this.implementationRootCause);
    }

    selectedRootCauseValues(event) { 
        this.missedExpectationsRootCause = event.detail;
        console.log ('Missed Expectations Root Cause : ' + this.missedExpectationsRootCause);
    }

    productRootCauseValues(event) { 
        this.productRootCause = event.detail;
        console.log ('Product Root Cause : ' + this.productRootCause);
    }

    supportRootCauseValues(event) { 
        this.supportRootCause = event.detail;
        console.log ('Support Root Cause : ' + this.supportRootCause);
    }

    managementRootCauseValues(event) { 
        this.managementRootCause = event.detail;
        console.log ('Account Management Root Cause : ' + this.managementRootCause);
    }

    policyRootCauseValues(event) { 
        this.policyRootCause = event.detail;
        console.log ('Policy Root Cause : ' + this.policyRootCause);
    }

    csmRootCauseValues(event) { 
        this.csmRootCause = event.detail;
        console.log ('CSM Root Cause : ' + this.csmRootCause);
    }

    billingRootCauseValues(event) { 
        this.billingRootCause = event.detail;
        console.log ('Billing Root Cause : ' + this.billingRootCause);
    }
    smsRootCauseValues(event) { 
        this.smsRootCause = event.detail;
        console.log ('SMS Root Cause : ' + this.smsRootCause);
    }
    otherRootCauseValues(event) { 
        this.otherRootCause = event.detail;
        console.log ('Other Root Cause : ' + this.otherRootCause);
    }
    handleSave(event) { 
        // stop the Lightning Record Edit Form from submitting
        event.preventDefault();
        // show spinner while submitting information to the server
        this.isLoading = true;
        let fields = event.detail.fields;
        this.template.querySelector('c-medallia-implementation-root-cause').selectedValues();
        this.template.querySelector('c-medallia-case-root-cause').selectedValues();
        this.template.querySelector('c-medallia-product-root-cause').selectedValues();
        this.template.querySelector('c-medallia-support-root-cause').selectedValues();
        this.template.querySelector('c-medallia-management-root-cause').selectedValues();
        this.template.querySelector('c-medallia-policy-root-cause').selectedValues();
        this.template.querySelector('c-medallia-c-s-m-root-cause').selectedValues();
        this.template.querySelector('c-medallia-billing-root-cause').selectedValues();
        this.template.querySelector('c-medallia-s-m-s-root-cause').selectedValues();
        this.template.querySelector('c-medallia-other-root-cause').selectedValues();
        console.log('Implementation Root Cause (Parent): ' + this.implementationRootCause);


        fields['Id'] = this.recordId;
        let rootCause = "";

        if (this.implementationRootCause) {
            rootCause = rootCause + this.implementationRootCause + ";";
        }
        
        if (this.missedExpectationsRootCause) {
            rootCause = rootCause + this.missedExpectationsRootCause + ";";
        }

        if (this.productRootCause) {
            rootCause = rootCause + this.productRootCause + ";";
        }

        if (this.supportRootCause) {
            rootCause = rootCause + this.supportRootCause + ";";
        }

        if (this.managementRootCause) {
            rootCause = rootCause + this.managementRootCause + ";";
        }

        if (this.policyRootCause) {
            rootCause = rootCause + this.policyRootCause + ";";
        }
        if (this.csmRootCause) {
            rootCause = rootCause + this.csmRootCause + ";";
        }
        if (this.billingRootCause) {
            rootCause = rootCause + this.billingRootCause + ";";
        }
        if (this.smsRootCause) {
            rootCause = rootCause + this.smsRootCause + ";";
        }
        if (this.otherRootCause) {
            rootCause = rootCause + this.otherRootCause + ";";
        }
        console.log ('Root Cause : ' + rootCause);
        // var questName = rootCause.substring(0,rootCause.length-1);
        // console.log('questName: '+rootCause.substring(0,rootCause.length-1));
        if (rootCause) {
            rootCause = rootCause.substring(0,rootCause.length-1);
            fields['Root_Cause__c'] = rootCause;
        }
        const recordInput = {  fields };
    
        updateRecord(recordInput)
            .then(caseUpdate => {
                console.log('Successfully updated Case ' );
                this.isLoading = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'The Information was successfully saved.',
                        variant: 'success'
                    })
                );
            })
            .catch(error => {
                this.isLoading = false;
                if (error) {
                    let message = 'Unknown error';
                    if (Array.isArray(error.body)) {
                        message = error.body.map(e => e.message).join(', ');
                    } else if (error.body.output != null && Array.isArray(error.body.output.errors)) {
                        message = error.body.output.errors.map(e => e.message).join(', ');
                    } else if (typeof error.body.message === 'string') {
                        message = error.body.message;
                    }
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'An error occurred while trying to update the record. Please try again.',
                            message,
                            variant: 'error',
                        }),
                    );
                }
            });        
            
    }
}