import { LightningElement, api, wire } from 'lwc';
import { getRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

import isReopenable from'@salesforce/apex/CaseHelper.isReopenable';
import getReopenErrorMessage from'@salesforce/apex/CaseHelper.getReopenErrorMessage';
import getFunctionValues from '@salesforce/apex/CaseHelper.getFunctionValues';
import reopenACase from'@salesforce/apex/ReopenCaseController.reopenACase';

import FIELD_ISCLOSED from '@salesforce/schema/Case.IsClosed';
import FIELD_STATUS from '@salesforce/schema/Case.Status';
import FIELD_CLOSEDDATE from '@salesforce/schema/Case.ClosedDate';

const FIELDS = [FIELD_ISCLOSED, FIELD_STATUS, FIELD_CLOSEDDATE];

export default class CaseReopen extends LightningElement {
    @api recordId;
    justification = '';
    _isReopenable;

    cannotBeReopenedReason;
    
    justificationErrorMessage;
    isJustificationInvalid = false;
    functionValuesStrings = [];
    functionValues = [];
    function = '';

    loading;

    get isJustificationRequired(){
        return this.function == 'Other reason';
    }

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
                IsClosed: data.fields.IsClosed.value,
                ClosedDate: data.fields.ClosedDate.value,
                Status: data.fields.Status.value
            }
    
            this._isReopenable = await isReopenable({cs: caseRecord});
            if (!this._isReopenable) {
                this.cannotBeReopenedReason = await getReopenErrorMessage({cs: caseRecord});
            } else {
                this.functionValuesStrings = await getFunctionValues();
                this.functionValues = this.functionValuesStrings.map( v => {
                    return {
                        value: v,
                        label: v
                    }
                })
            }
        }
    }

    justificationChange(event) {
        this.justification= event.target.value;
        this.isJustificationInvalid = false;
    }
    
    functionChange(event) {
        this.function = event.target.value;
        event.target.setCustomValidity("")
        event.target.reportValidity()
        this.isJustificationInvalid = false;
    }

    validateInputs() {
        let allValid = true;

        if(this.function == 'Other reason') {
            if (this.justification.length < 50) {
                this.justificationErrorMessage = "Justification must be at least 50 characters.";
                this.isJustificationInvalid = true;
                allValid = false;
            } else if (this.justification.length > 2000) {
                this.justificationErrorMessage = "Justification must be less than 2000 characters.";
                this.isJustificationInvalid = true;
                allValid = false;
            }
        }
        
        if (!this.functionValuesStrings.some(funcValue => funcValue == this.function)) {
            const combobox = this.template.querySelector("lightning-combobox");
            combobox.setCustomValidity("Invalid function value.");
            combobox.reportValidity();
            allValid = false;
        }
        return allValid;
    }

    handleSubmit() {
        this.loading = true;
        this.justification = this.justification.replace(/\s+/g, '').trim();

        const allValid = this.validateInputs();

        if (allValid) {
            let message = 'You have escalated the case.';
            let variant = 'success';
            let title = 'Case has been escalated';
    
            const caseToUpdate = {
                sobjectType: 'Case',
                Id:this.recordId
            }
    
            reopenACase({
                function: this.function,
                justification: this.justification,
                aCase: caseToUpdate
            })
            .catch(e => {
                message = 'Error: ' + e.message;
                title = 'Failed to reopen case.';
                variant = 'error';
            })
            .finally(() => {
                this.showToast(title, message, variant);
                this.closeModal();
                this.loading = false;
                getRecordNotifyChange([{recordId: this.recordId}])
            })
        } else {
            this.loading = false;
        }
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({title, message, variant});
        this.dispatchEvent(evt);
    }

    closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}