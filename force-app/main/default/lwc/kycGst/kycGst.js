import { LightningElement, track, api}  from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import checkGstNo from '@salesforce/apex/KycDetailsHelper.validateGstNumber';
import validateBillingState from '@salesforce/apex/KycDetailsHelper.validateBillingState';

export default class KycGst extends LightningElement {
    _approval;
    @api files;
    @api isFormLocked;
@api billingAddress;
    _isValidValue;
isGstNotCorrect = false;
isGstIsCorrect = false;
gstErrorText = '';
hasInitialValue = false;
hasUserInteracted = false;

@api
get approval() {
    return this._approval;
}
set approval(value) {
    this._approval = value;
    if (!this.hasUserInteracted && value && value.gstNo && value.gstNo.trim() !== '') {
        this.hasInitialValue = true;
    }
}

    @api
    get isValidGstNo() {
        return this._isValidValue;
    }
    set isValidGstNo(value) {
        const inputCmp = this.template.querySelector('.gstNo');
        if (!value) {
        if (!this.approval?.gstNo || this.approval.gstNo.trim() === '') {
            inputCmp?.setCustomValidity("Value is required if there is a Certificate");
        } else if (this.isGstNotCorrect === true) {
            inputCmp?.setCustomValidity(this.gstErrorText);
        }
            inputCmp?.reportValidity();
    } else {
            inputCmp?.setCustomValidity('');
            inputCmp?.reportValidity();
        }
        this._isValidValue = value;
    this.dispatchEvent(new CustomEvent('gstvalidation', {
        detail: { isGstCorrect: this._isValidValue }
    }));
    }

connectedCallback() {
    if (this.approval?.gstNo && this.approval.gstNo.trim() !== '') {
        this.hasInitialValue = true;
    }
}

    get gstNo() {
        return this.approval && this.approval.gstNo;
    }
    get stateCode() {
        return this.approval && this.approval.gstStateCodeOfCustomer;
    }

    get isGstNoDisable() {
    return this.isFormLocked 
        || (this.files && window.app?.isNoActiveFilesForSection(window.app.sections.GST_ATTACHMENT))
        || (this.hasInitialValue && !this.hasUserInteracted);
    }

    onChange(event) {
        const app = {...this.approval};
        switch (event.target.dataset.id) {
            case 'gst-no':
            this.hasUserInteracted = true;
                app.gstNo = event.target.value || '';
            if (!app.gstNo || app.gstNo.trim() === '') {
                this.isGstNotCorrect = false;
                this.isGstIsCorrect = false;
                this.gstErrorText = '';
                this.isValidGstNo = true;
            }
            else if(app.gstNo.length !== 15){
                this.isGstNotCorrect = true;
                this.isGstIsCorrect = false;
                this.gstErrorText = 'GST No. must be 15 digits';
                this.isValidGstNo = false;
            }
            else{
                this.validateStateBeforeGst(app.gstNo)
                .then(stateValidation => {
                    if (stateValidation.isValidState && stateValidation.isValidGstNoForState) {
                       
                        return checkGstNo({gstNo: app.gstNo});
                    } else {
                        
                        throw new Error(stateValidation.errorMessage || 'GST state code does not match billing state');
                    }
                })
                .then(result => {
                    if(result == true){
                        this.isGstNotCorrect = false;
                        this.isGstIsCorrect = true;
                        this.gstErrorText = '';
                        this.isValidGstNo = true;
                    }
                    else{
                        this.isGstNotCorrect = true;
                        this.isGstIsCorrect = false;
                        this.gstErrorText = 'Please enter a valid GST No.';
                        this.isValidGstNo = false;
                    }
                })
                .catch(error => {
                    this.isGstNotCorrect = true;
                    this.isGstIsCorrect = false;
                    this.isValidGstNo = false;
                    
                    const errMsg = 'Error validating GST No.';
                    const errorTitle = 'GST Validation Error';
                    const toastEvent = new ShowToastEvent({
                        title: errorTitle,
                        message: error.body?.message || error.message || errMsg,
                        variant: 'error',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(toastEvent);
                })
            }
                break;
        }
        window.app.updateApproval(app);
    }

validateStateBeforeGst(gstNo) {
    return new Promise((resolve, reject) => {
        if (!this.billingAddress?.billingState || !gstNo) {
            
            resolve({ isValidState: true, isValidGstNoForState: true });
            return;
        }

        const params = {
            accountId: this.approval?.account?.Id,
            gstNo: gstNo,
            billingState: this.billingAddress.billingState
        };
        
        validateBillingState({params: JSON.stringify(params)})
        .then(result => {
            if (result?.data?.isValidState && result?.data?.isValidGstNoForState) {
                
                if (result.data.primaryTaxCode) {
                    const updatedApproval = {...this.approval};
                    updatedApproval.gstStateCodeOfCustomer = result.data.primaryTaxCode;
                    window.app.updateApproval(updatedApproval);
                }
                resolve({ 
                    isValidState: true, 
                    isValidGstNoForState: true,
                    primaryTaxCode: result.data.primaryTaxCode
                });
            } else {
                resolve({ 
                    isValidState: false, 
                    isValidGstNoForState: false,
                    errorMessage: 'GST state code does not match billing state'
                });
            }
        })
        .catch(error => {
            reject(error);
        });
    });
}
}