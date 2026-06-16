import { LightningElement, api, wire } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import STATUS_FIELD from '@salesforce/schema/Case_Activity__c.Status__c';
import CASE_CREATED_DATE_FIELD from '@salesforce/schema/Case_Activity__c.Case__r.CreatedDate';
import ID_FIELD from '@salesforce/schema/Case_Activity__c.Id';
import ATTEMPT_INTERVAL_DAYS_FIELD from '@salesforce/schema/Case_Activity__c.Attempt_Interval_Days__c';

const FIELDS = [STATUS_FIELD, CASE_CREATED_DATE_FIELD];

export default class ChangeCaseActivityStatusToSuccessful extends LightningElement {
    @api recordId;
    
    @wire(getRecord, {
        recordId: '$recordId',
        fields: FIELDS
    })
    record;

    updateCaseActivityRecord(attemptIntervalDays) {
        const fields  = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[STATUS_FIELD.fieldApiName] = 'Succeded';
        fields[ATTEMPT_INTERVAL_DAYS_FIELD.fieldApiName] = attemptIntervalDays;
        const recordInput = { fields };
        updateRecord(recordInput)
            .then(() => {
                this.showNotification(
                    'Case Activity updated.',
                    'Status and Attempt Interval (Days) have been updated.',
                    'success'
                );
            })
            .catch((e) => {
                this.showNotification(
                    'Error when updating Case Activity. Contact your salesforce administrator',
                    e.body.message,
                    'error'
                );
            })
    } 

    showNotification(title, message, variant) {
        const evt = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(evt);
    }

    @api invoke() {
        const caseActivityStatus = this.record.data.fields.Status__c.value;
        if (caseActivityStatus != 'New') {
            this.showNotification(
                'It is not possible to mark as successful.',
                'This case activity has already been updated from "New" to another status.',
                'error'
            );
            return;
        }
        const caseCreatedDate = new Date(this.record.data.fields.Case__r.value.fields.CreatedDate.value);
        const today = new Date(Date.now())
        const attemptIntervalDays = today.getDate() - caseCreatedDate.getDate();
        this.updateCaseActivityRecord(attemptIntervalDays)
    }
}