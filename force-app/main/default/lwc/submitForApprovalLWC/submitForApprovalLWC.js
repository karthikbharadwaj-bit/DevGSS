import { LightningElement,wire,track,api } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import APPROVAL_OBJECT from '@salesforce/schema/Approval__c';
import INDUSTRY_FIELD from '@salesforce/schema/Approval__c.Industry__c';
import TAXEXEMPT_FIELD from '@salesforce/schema/Approval__c.Tax_Exempt_Approval__c';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import submitApproval from "@salesforce/apex/SubmitforInvoiceApproval.submitApproval";
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';
const fields = [TAXEXEMPT_FIELD];

export default class SubmitForApprovalLWC extends LightningElement {

    @api recordId;
    value ='';
    isSpinner = false;
    isTaxExempt = false;
    isSubmitForApprovalScr = false;
    

    @track industryRecordTypId = '';
    @track defaultTaxExempCheckValues = ['Education','Government','Life Sciences','Non-Profit','Transportation','Utilities'];

    @wire(getObjectInfo, { objectApiName: APPROVAL_OBJECT })
    getApprovalObjData({data,error}){
        if(data){
            if(data.recordTypeInfos){
                const rtis = data.recordTypeInfos;
                this.industryRecordTypId =  Object.keys(rtis).find(rti => rtis[rti].name === 'Invoicing Request');
                
            }
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields })
    approval;

    get taxexempt() {
        this.isTaxExempt = getFieldValue(this.approval.data, TAXEXEMPT_FIELD);
        return getFieldValue(this.approval.data, TAXEXEMPT_FIELD);
    }
    @wire(getPicklistValues,{recordTypeId: '$industryRecordTypId',fieldApiName: INDUSTRY_FIELD})industryPicklist;
        
    handleClickIndus(){
       // alert('j');
       // this.template.querySelector('[data-id="dynamicHeightDiv"]').style.height='18rem';

        //this.template.querySelector('.slds-card').style.height='18rem';
        
    }
    handleChange(event) {        
            this.value = event.detail.value;
          //  this.template.querySelector('[data-id="submitBtn"]').disabled=false;
            if(this.defaultTaxExempCheckValues.includes(this.value)){
                this.isTaxExempt = true;
                this.template.querySelector('[data-id="TaxExemptInput"]').checked=true;
            }else{
               // this.template.querySelector('[data-id="submitBtn"]').disabled=true;
                this.template.querySelector('[data-id="TaxExemptInput"]').checked=false;
                this.isTaxExempt = false;
            }
          //  this.template.querySelector('[data-id="dynamicHeightDiv"]').style.height='5rem';            

    }   
   
    changeToggle(event){
        if(event.target.checked === false){
            event.target.checked = false; 
            this.isTaxExempt = false;
            //this.template.querySelector('[data-id="submitBtn"]').disabled=true;
        }else{
            event.target.checked = true;
            this.isTaxExempt = true;
           // if(this.value){
              //  this.template.querySelector('[data-id="submitBtn"]').disabled=false;            
            //}
        }
    }
    closeAction(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    submit(event){
        this.isSpinner = true;
        this.isSubmitForApprovalScr = true;
        this.isSpinner = false;
    }
    submitApproval(event){
        this.isSpinner = true;
        this.isSubmitForApprovalScr = true;
        console.log(JSON.stringify(this.template.querySelector('[data-id="comments"]').value));
        //if(this.isTaxExempt){
            event.target.disabled = false;
            submitApproval({recrdId: this.recordId, comments:this.template.querySelector('[data-id="comments"]').value})
            .then(response => {
                console.log('Approval Response:' +JSON.stringify(response));
                this.isSpinner = false;
                if(response == 'Invoice Request Submitted Successfully'){
                    var toastEvent = new ShowToastEvent({
                        message: 'Invoicing Request Record is Submitted For Approval Successfully',
                        title : 'Success',
                        variant: 'success'
                    });
                    this.dispatchEvent(toastEvent);
                    this.dispatchEvent(new CloseActionScreenEvent());
                }
                
                else if(response == 'No Approved Tax Exempt Approval Record'){
                    var toastEvent = new ShowToastEvent({
                        message: 'The Approval Flow for Invoicing Requests cannot begin until the Tax Team has Approved the Tax Exemption Approval Request',
                        title : 'Error',
                        variant: 'warning'
                    });
                    this.dispatchEvent(toastEvent);
                }

                else{
                    var toastEvent = new ShowToastEvent({
                        message: response,
                        title : 'Error',
                        variant: 'warning'
                    });
                    this.dispatchEvent(toastEvent);
                }

                /* Modify the Apex Class Method to Remove unwanted code
                if(response.length>0){
                    if(response.length == 1){
                        this.isSpinner = false;
                        if(response[0] === "Exist Tax Exempt Approval 1"){
                            var toastEvent = new ShowToastEvent({
                                message: 'Record is Submitted For Approval Successfully',
                                title : 'Success',
                                variant: 'success'
                            });
                            this.dispatchEvent(toastEvent);
                            this.dispatchEvent(new CloseActionScreenEvent());
                        }
                        else if(response[0] === 'Tax Exempt Approval Not Required'){
                            var toastEvent = new ShowToastEvent({
                                message: 'Record is Submitted For Approval Successfully',
                                title : 'Success',
                                variant: 'success'
                            });
                            this.dispatchEvent(toastEvent);
                            this.dispatchEvent(new CloseActionScreenEvent());
                        }
                        else{
                            var toastEvent = new ShowToastEvent({
                                message: response[0],
                                title : 'Error',
                                variant: 'warning'
                            });
                            this.dispatchEvent(toastEvent);
                         // this.dispatchEvent(new CloseActionScreenEvent());

                        }
                    }

                    else{
                        this.isSpinner = false;

                        if(response.includes("Exist Tax Exempt Approval")){
                            var toastEvent = new ShowToastEvent({
                                message: 'Record is Submitted For Approval Successfully',
                                title : 'Success',
                                variant: 'success'
                            });
                            this.dispatchEvent(toastEvent);
                            this.dispatchEvent(new CloseActionScreenEvent());

                        }else{
                            var toastEvent = new ShowToastEvent({
                                message: response[0],
                                title : 'Error',
                                variant: 'warning'
                            });
                            this.dispatchEvent(toastEvent);
                           // this.dispatchEvent(new CloseActionScreenEvent());

                        }
                      
                    }
                }else{
                    var toastEvent = new ShowToastEvent({
                        message: response[0],
                        title : 'Error',
                        variant: 'warning'
                    });
                    this.dispatchEvent(toastEvent);
                } */
            })
      /*  }else{
            this.isSpinner = false;
            var toastEvent = new ShowToastEvent({
                message: 'Please Checked Tax Exempt Approval to Start Submit For Approval!!',
                title : 'Error',
                variant: 'Error'
            });
            this.dispatchEvent(toastEvent);
           // this.dispatchEvent(new CloseActionScreenEvent());
        }*/
    }
}