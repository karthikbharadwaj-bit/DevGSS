import { LightningElement, track, wire, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import getQuickTaskInfo from '@salesforce/apex/QuickTaskCreation.getQuickTaskInfo';

export default class QuickTaskCreation extends NavigationMixin(LightningElement) {
    @track quickTaskRecTypeId;
    @api objectApiName;
    @api recordId;

    @wire(getQuickTaskInfo , {recId : '$recordId' , objectNm : '$objectApiName'})
    checkAccess({data, error }) {
        if (data) {
            if(data.errorMsg === 'success') {
                this.quickTaskRecTypeId  = data.quickTaskRecTypeId;
                this.createNewQuickCase();
            } else {
                this.showErrorToast(data.errorMsg);
            }
        } else if (error) {
            this.showErrorToast(error.body.message);
        }
    }

    createNewQuickCase() {
        let defaultFieldsValues;
        if (this.objectApiName === 'Account') {
                defaultFieldsValues = encodeDefaultFieldValues({
                    WhatId: this.recordId
            });
        } else if (this.objectApiName === 'Contact') {
            defaultFieldsValues = encodeDefaultFieldValues({
                WhoId: this.recordId
            });
        } else if (this.objectApiName === 'Opportunity') {
            defaultFieldsValues = encodeDefaultFieldValues({
                WhatId: this.recordId
            });
        }

        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Task',
                actionName: 'new'
            },
            state: {
                recordTypeId: this.quickTaskRecTypeId,
                nooverride: '1',
                count: '1',
                defaultFieldValues: defaultFieldsValues,
                navigationLocation: 'RELATED_LIST'
            }
        }, true);
    }

    async showErrorToast(message) {
        const evt = new ShowToastEvent({
            title: 'Error creating Quick Task',
            message: message,
            variant: 'error'
        });
        await this.dispatchEvent(evt);
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}