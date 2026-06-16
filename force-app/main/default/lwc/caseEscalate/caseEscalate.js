import { LightningElement, api, wire } from 'lwc';
import { getRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

import isEscalatable from'@salesforce/apex/CaseHelper.isEscalatable';
import getEscalateErrorMessage from'@salesforce/apex/CaseHelper.getEscalateErrorMessage';
import escalateACase from'@salesforce/apex/EscalateCaseController.escalateACase';

import FIELD_ESCALATED from '@salesforce/schema/Case.IsEscalated';
import FIELD_CREATEDDATE from '@salesforce/schema/Case.CreatedDate';
import FIELD_ISCLOSED from '@salesforce/schema/Case.IsClosed';

const FIELDS = [FIELD_ESCALATED, FIELD_CREATEDDATE, FIELD_ISCLOSED];

export default class CaseEscalate extends LightningElement {
    @api recordId;
    justification = '';
    _isEscalatable;
    cannotBeEscalatedReason;
    isJustificationInvalid = false;
    justificationErrorMessage;

    loading;

    get textareaStyle(){
        return `slds-form-element ${this.isJustificationInvalid ? 'slds-has-error' : ''}`;
    }

    @wire(getRecord, {
        recordId: '$recordId', 
        fields: FIELDS
    })
    async getRecordHandler({data}) {
        if (data) {
            const caseRecord = {
                sobjectType: 'Case',
                CreatedDate: data.fields.CreatedDate.value,
                IsEscalated: data.fields.IsEscalated.value,
                IsClosed: data.fields.IsClosed.value
            }
    
            this._isEscalatable = await isEscalatable({cs: caseRecord});
            if (!this._isEscalatable) {
                this.cannotBeEscalatedReason = await getEscalateErrorMessage({cs: caseRecord});
            }
        }
    }

    justificationChange(event) {
        this.justification= event.target.value;
        this.isJustificationInvalid = false;
    }

    handleSubmit() {
        this.loading = true;
        this.justification = this.justification.replace(/\s+/g, ' ').trim();
        
        if (this.justification.length < 50) {
            this.isJustificationInvalid = true;
            this.justificationErrorMessage = "Justification must be at least 50 characters.";
            this.loading = false;
            return;
        } else if (this.justification.length > 2000) {
            this.isJustificationInvalid = true;
            this.justificationErrorMessage = "Justification must be less than 2000 characters.";
            this.loading = false;
            return;
        }

        let message = 'You have escalated the case.';
        let variant = 'success';
        let title = 'Case has been escalated';

        const caseToUpdate = {
            sobjectType: 'Case',
            Id:this.recordId,
            IsEscalated: true
        }

        escalateACase({
            justification: this.justification,
            caseRecord: caseToUpdate
        })
        .catch(e => {
            message = 'Error: ' + e.message;
            title = 'Failed to escalate case.';
            variant = 'error';
        })
        .finally(() => {
            this.showToast(title, message, variant);
            this.closeModal();
            this.loading = false;
            getRecordNotifyChange([{recordId: this.recordId}])
        })
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({title, message, variant});
        this.dispatchEvent(evt);
    }

    closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}