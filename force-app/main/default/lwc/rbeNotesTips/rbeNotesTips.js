import { LightningElement, track, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import getSuccessPlanWire from '@salesforce/apex/SuccessPlanController.getSuccessPlanWire';
import RBENOTES_FIELD from '@salesforce/schema/Success_Plan__c.RBE_Notes__c';
import ID_FIELD from '@salesforce/schema/Success_Plan__c.Id';

export default class RbeNotesTips extends LightningElement {
  
    disabled = true; // updated by Thejasvi
    @track error;
    @api accid;
    @api items;
    @api rbeNotes;
    @api sucessid; 
    @api canEdit; 
   
    @wire(getSuccessPlanWire, {accId: '$accid'})
    successPlan;

    handleChange(event) {
        if(event.target.value){
            this.disabled=false;
        }else if (!event.target.value) {
            event.target.reportValidity();
            this.disabled = true;
        }      
    }

    updateNotes() {
        const allValid = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputFields) => {
                inputFields.reportValidity();
                return validSoFar && inputFields.checkValidity();
            }, true);

        if (allValid) {
            // Create the recordInput object
            const fields = {};          
            fields[ID_FIELD.fieldApiName] = this.sucessid;
            
            fields[RBENOTES_FIELD.fieldApiName] = this.template.querySelector("[data-field='RBE_Notes__c']").value;

            const recordInput = { fields };

            updateRecord(recordInput)
                .then(() => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'RBE Notes updated',
                            variant: 'success'
                        })
                    );
                    this.disabled = true; // Added by Thejasvi
                    // Display fresh data in the form
                    return refreshApex(this.successPlan);
                   
                })
                .catch(error => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error creating record',
                            message: error.body.message,
                            variant: 'error'
                        })
                    );
                });
            }
        else {
            // The form is not valid
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Something is wrong',
                    message: 'Check your input and try again.',
                    variant: 'error'
                })
             );
        }
    }
}