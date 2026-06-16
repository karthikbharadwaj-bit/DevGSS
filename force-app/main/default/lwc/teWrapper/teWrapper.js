import { LightningElement, api, track } from 'lwc';
import { loadScript} from "lightning/platformResourceLoader";
import { NavigationMixin } from 'lightning/navigation';

import TaxExemptionDependencies from '@salesforce/resourceUrl/TaxExemptionDependencies';
import { App } from './App';

import BaseService from "c/lwcBaseService";
import {TE_CONSTANTS} from 'c/teConstants';

import initTaxExemptionPage from '@salesforce/apex/TaxExemptionController.initTaxExemptionPage';
import getPermissions from '@salesforce/apex/TaxExemptionController.getPermissions';
import setApprovalAction from '@salesforce/apex/TaxExemptionController.setApprovalAction';
import getTaxExemptionOptions from '@salesforce/apex/TaxExemptionController.getTaxExemptionOptions';
import saveApproval from '@salesforce/apex/TaxExemptionController.saveApproval';
import isShowVATExemption from '@salesforce/apex/TaxExemptionController.isShowVATExemption';
import submitForApproval from '@salesforce/apex/TaxExemptionController.submitForApproval';
import updateVATNumberOnAccount from '@salesforce/apex/TaxExemptionController.updateVATNumberOnAccount';
import validateExemptions from '@salesforce/apex/TaxExemptionController.validateExemptions';
import isVATFieldsEnabled from '@salesforce/apex/TaxExemptionController.isVATFieldsEnabled';
import validateVATNumber from '@salesforce/apex/TaxExemptionController.validateVATNumber';
import isShowIndianTaxExemption from '@salesforce/apex/TaxExemptionController.isShowIndianTaxExemption';
import isShowSalesTaxExemption from '@salesforce/apex/TaxExemptionController.isShowSalesTaxExemption';
import getAttachmentsName from '@salesforce/apex/TaxExemptionController.getAttachmentsName';


const SWITZERLAND_COUNTRY_CODE = 'CH';
export default class TeWrapper extends NavigationMixin(LightningElement) {
    @api approvalId;
    @api opportunityBI;
    @api opportunityType;

    @track options = [];
    @track showLoadingPlaceHolder;
    @track approvalStatus;

    @track isShowSubmitButton;
    @track isShowSubmitForApprovalButton;
    @track isShowSaveButton;
    @track isShowVatExemption;
    @track isVATFieldsEnabled;
    @track VATExemptionChecked;

    @track isSubmitForApprovalDisabled;
    @track isSaveDisabled;
    @track isSubmitDisabled;
    @track VATNumber;
    @track VATCountry;
    @track brand;
    @track isDisabledVatCountyNumber;

    @track GSTNumber = '';
    @track isDisabledIndianTax;
    @track IndianExemptionChecked;
    @track isGSTNumberInvalid = false;
    @track sezids = [];

    NA_RELATED_LIST_SEZ_CERTIFICATE_ORDER = 5;

    connectedCallback() {
        loadScript(this, TaxExemptionDependencies + "/TE.js")
            .then(() => {
                this.createApp();
                this.teAppReady(this.onTEAppReady.bind(this));
            })
            .catch(error => {
                console.error(error);
            });
    }

    createApp() {
        window.app = new App();
        window.dispatchEvent(new CustomEvent('teAppInit'));
    }

    onTEAppReady() {
        window.app.setBI(this.opportunityBI);
        window.app.setLoadingStatus({isApprovalLoading: true});
        Promise.all([
                getPermissions(),
                initTaxExemptionPage({approvalId: this.approvalId}),
                getTaxExemptionOptions(),
                isShowVATExemption({approvalId: this.approvalId}),
                isVATFieldsEnabled({approvalId: this.approvalId}),
                isShowIndianTaxExemption({approvalId: this.approvalId}),
                isShowSalesTaxExemption({approvalId: this.approvalId}),
            ])
            .then(result => {
                window.app.setPermissions(result[0]);
                window.app.setApproval(result[1]);
                if(window.app.isAmazon && this.opportunityType === TE_CONSTANTS.NEW_BUSINESS) {
                    window.app.setSalesTaxExemption(TE_CONSTANTS.APPROVAL.TAX_EXEMPTION_STATE.APPROVED);
                    window.app.setSalesExemptionDisabled(true);
                }
                window.app.setOptions(result[2]);
                window.app.setLoadingStatus({isApprovalLoading: false});
                window.app.setShowVATExemption(result[3]);
                window.app.setVATFieldsEnabled(result[4]);
                window.app.setVATNumber(result[1].data.record.VATNumber__c);
                window.app.setVATCountry(result[1].data.record.VATCountryForCheck__c);
                window.app.setGSTNumber(result[1].data.record.GstNo__c);
                window.app.setBrand(result[1].data.record.Account__r.RC_Brand__c);
                window.app.setShowIndianExemption(result[5]);
                window.app.setShowSalesTaxExemption(result[6]);
                this.checkApprovalIsBlocked();
                this.checkApprovalIsProcessing();
                console.log('TEA info::', result);

                // view attach links for indian TEA:
                const attachSections = result[5] && result[1].data.record.KycFiles__c.split(';') || [];
                if (attachSections.length > this.NA_RELATED_LIST_SEZ_CERTIFICATE_ORDER) {
                    const sezids = attachSections[this.NA_RELATED_LIST_SEZ_CERTIFICATE_ORDER]
                        .split(',')
                        .filter(Boolean)
                        .map(id => ({
                            id: id,
                            link: window.location.origin + '/sfc/servlet.shepherd/document/download/' + id,
                            name: id,
                        }));

                    Promise.all([getAttachmentsName({attachmentIds: sezids.map(({id}) => id)})])
                        .then(([mapNames]) => {
                            this.sezids = sezids.map(x => ({...x, name: mapNames[x.id] || x.name}))
                        });
                }
            })

        window.app.rx.options.subscribe(options => {this.options = options;});
        window.app.rx.VATNumber.subscribe(VATNumber => {this.VATNumber = VATNumber});
        window.app.rx.VATCountry.subscribe(VATCountry => {this.VATCountry = VATCountry});

        window.app.rx.isShowVATExemption.subscribe(isShowVatExemption => {this.isShowVatExemption = isShowVatExemption;});
        window.app.rx.isVATFieldsEnabled.subscribe(value => {
            this.isVATFieldsEnabled = value;
            this.validateButtons();
        });

        window.app.rx.loadingStatus.subscribe(loadingStatus => {this.showLoadingPlaceHolder = loadingStatus.isApprovalLoading});

        window.app.rx.taxExemptionState.subscribe(taxExemptionState => {
            window.app.isUnsavedChanges = window.app.isUnsavedChanges ||
                taxExemptionState.federal != this.record.FederalTaxExemption__c ||
                taxExemptionState.state != this.record.StateTaxExemption__c ||
                taxExemptionState.county != this.record.CountyTaxExemption__c ||
                taxExemptionState.local != this.record.LocalTaxExemption__c ||
                taxExemptionState.indian != this.record.SEZWOPExemption__c ||
                taxExemptionState.vat != this.record.VATExemption__c ||
                taxExemptionState.sales != this.record.SalesTaxExemption__c;
            window.app.isUnableToClearExemptOnSubmit = window.app.isPendingApproval() &&
                (this.record.FederalTaxExemption__c && !taxExemptionState.federal ||
                this.record.StateTaxExemption__c && !taxExemptionState.state ||
                this.record.CountyTaxExemption__c && !taxExemptionState.county ||
                this.record.LocalTaxExemption__c && !taxExemptionState.local ||
                this.record.SEZWOPExemption__c && !taxExemptionState.indian ||
                this.record.VATExemption__c && !taxExemptionState.vat ||
                this.record.SalesTaxExemption__c && !taxExemptionState.sales);

            this.VATExemptionChecked = !!taxExemptionState.vat;
            this.IndianExemptionChecked = !!taxExemptionState.indian;
            this.validateButtons();
        });

        window.app.rx.approval.subscribe(approval => {
            this.approvalStatus = approval.record.Status__c;
            this.VATNumber = approval.record.VATNumber__c;
            this.VATCountry = approval.record.VATCountryForCheck__c;
            this.GSTNumber = approval.record.GstNo__c;
        });

        window.app.rx.VATNumber.subscribe(VATNumber => {
            window.app.isUnsavedChanges = window.app.isUnsavedChanges || VATNumber !== (this.record.VATNumber__c || '');
            this.validateButtons();
        });

        window.app.rx.VATCountry.subscribe(VATCountry => {
            window.app.isUnsavedChanges = window.app.isUnsavedChanges || VATCountry !== (this.record.VATCountryForCheck__c || '');
            this.validateButtons();
        });

        window.app.rx.GSTNumber.subscribe(GSTNumber => {
            this.GSTNumber = GSTNumber;
            this.isGSTNumberInvalid = false;
            this.validateButtons();
        });

    }

    teAppReady(callback) {
        window.app
            ? callback()
            : window.addEventListener('teAppInit', callback);
    }

    checkApprovalIsBlocked() {
        if (window.app.isApprovalBlocked()) {
            const title = TE_CONSTANTS.MESSAGES.APPROVAL_BLOCKED;
            const message = '';
            this.showToast({title, message, type: 'warning', duration: 0});
        }
    }

    checkApprovalIsProcessing() {
        if (window.app.isApprovalProcessing()) {
            const title = TE_CONSTANTS.MESSAGES.APPROVAL_PROCESSING;
            const message = this.isShowIndianTaxExemption ? TE_CONSTANTS.MESSAGES.INDIA_REFRESH_PAGE : TE_CONSTANTS.MESSAGES.REFRESH_PAGE;
            this.showToast({title, message, type: 'warning', duration: 0});
        }
    }

    setApprovalAction(action) {
        return setApprovalAction({
                app: this.record,
                approvalParams: {
                    action: action
                }
            })
    }

    showSpinner(text) {
        this.fireSpinnerEvent({text, isShown: true});
    }

    hideSpinner() {
        this.fireSpinnerEvent({isShown: false});
    }

    fireSpinnerEvent({text = '', isShown}) {
        window.dispatchEvent(new CustomEvent('ShowSpinnerEvent', {
            detail: {text, isShown}
        }));
    }

    showToast({title, message, type = 'info', duration}) {
        window.dispatchEvent(new CustomEvent('ShowToastEvent', {
            detail: {title, message, type, duration}
        }));
    }

    saveApprovalErrorHandler(err) {
            console.log('Error::', err);
            this.hideSpinner();
            this.showToast({
                title: 'Error',
                message: err && err.body && err.body.message || 'Internal Server Error',
                type: 'error',
                duration: 0
            });
    }

    onSaveButton() {
        this.showSpinner('Validating Approval');
        this.validateAccountExemptions()
        .then((validateResult) => {
            if (validateResult.data.isExemptExist && validateResult.data.record.VATCountryForCheck__c !== SWITZERLAND_COUNTRY_CODE) {
                this.validateResponse(validateResult);
                if (validateResult.data && validateResult.data.record) {
                    validateResult.data.record.VATNumber__c = window.app.VATNumber;
                }
                return Promise.resolve(validateResult);
            } else {
                this.showSpinner('Saving approval');
                return this.saveApproval();
            }
        })
        .then((result) => {
            window.app.setApproval(result);
            window.app.isUnsavedChanges = !(result && result.status === 'success');
            this.validateButtons();
            this.hideSpinner();
        })
        .catch((err) => this.saveApprovalErrorHandler(err));
    }

    onSubmitforApproval() {
        this.showSpinner('Validating Approval');
        this.validateVATGSTNumber()
         .then((validateVATResult) => {
             const data = validateVATResult && validateVATResult.data;
             if (data && data.isValid && !data.error) {
                 return this.validateAccountExemptions();
             } else {
                 return Promise.reject({body: {message: 'Validation error: ' + (data && data.error || '')}});
             }
         })
        .then((validateResult) => {
            this.hideSpinner();
            if (validateResult && validateResult.data && validateResult.data.isExemptExist) {
                this.validateResponse(validateResult);
                window.app.setApproval(validateResult);
            } else {
                if (window.app.isUnsavedExempts()) {
                    this.showModalOnSubmitforApproval();
                } else {
                    this.showSpinner('Submit for approval');
                    return this.processFastComplete();
                }
            }
        })
        .catch((err) => this.saveApprovalErrorHandler(err));
    }

    validateResponse(response) {
        if (response.data.isMissedEntryCriteria) {
            const message = response.data.isMissedEntryCriteria;
            const title = '';
            this.showToast({title, message, type: 'error', duration: 0});
        }
        if (response.data.isExemptChangedOnNGBS) {
            const message = response.data.isExemptChangedOnNGBS;
            const title = '';
            this.showToast({title, message, type: 'warning', duration: 0});
        }
        if (response.data.isExemptExist) {
            const message = response.data.isExemptExist;
            const title = '';
            this.showToast({title, message, type: 'error', duration: 0});
        }
        if (response.data.error) {
            const message = response.data.error;
            const title = '';
            this.showToast({title, message, type: 'error', duration: 0});
        }
    }

    showModalOnSubmitforApproval() {
        BaseService.showModal(
            null,
            '<h2 class="slds-text-heading_small">You have unsaved changes.</h2>',
            [
                {
                    label: "Discard",
                    callback: () => {
                        window.app.presetStatuses();
                    },
                },
                {
                    variant: "brand",
                    label: "Save changes and submit for approval",
                    callback: () => {
                        this.showSpinner('Saving approval');
                        this.saveApproval()
                        .then((saveResult) => {
                            this.validateResponse(saveResult);
                            window.app.setApproval(saveResult);
                            this.checkApprovalIsBlocked();
                        })
                        .then(() => this.processFastComplete());
                    },
                },
            ],
            () => {
                window.app.presetStatuses();
            }
        )
    }

    processFastComplete() {
        this.showSpinner('Submitting for approval');

        return submitForApproval({
            app: this.record
        })
        .then((submitResult) => {
            this.validateResponse(submitResult);
            window.app.setApproval(submitResult);
            this.checkApprovalIsBlocked();
        })
        .then(() => {
            this.showSpinner('Updating VAT Number on Account');
            return updateVATNumberOnAccount({
                app: this.record
            })
        })
        .then((validateResult) => {
            window.app.setApproval(validateResult);
            this.hideSpinner();
            this.validateResponse(validateResult);
            this.checkApprovalIsBlocked();
        })
        .then(() => {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                  objectApiName: 'Approval__c',
                  recordId: this.record.Id,
                  actionName: 'view',
                },
              });
        })
        .catch((err) => this.saveApprovalErrorHandler(err));
    }

    getApprovalAction() {
        var approvalActionWrapper = {};
        if (window.app.isApprovedAny()) {
            approvalActionWrapper.action = 'Approve';
            approvalActionWrapper.message = 'Process Approve';
        } else if (window.app.isRejectedAny()) {
            approvalActionWrapper.action = 'Reject';
            approvalActionWrapper.message = 'Process Reject';
        }
        return approvalActionWrapper;
    }

    onSubmit() {
        let approvalActionWrapper = this.getApprovalAction();

        if (window.app.isUnsavedExempts()) {
            this.showPromptOnSubmit();
        } else {
            this.showSpinner(approvalActionWrapper.message);
            this.setApprovalAction(approvalActionWrapper.action)
                .then((submitResult) => {
                    window.app.setApproval(submitResult);
                    this.validateResponse(submitResult);
                    this.hideSpinner();
                    this.checkApprovalIsBlocked();
                })
        }
    }

    showPromptOnSubmit() {
        BaseService.showModal(
            null,
            '<h2 class="slds-text-heading_small">You have unsaved changes.</h2>',
            [
                {
                    label: "Discard",
                    callback: () => {
                        window.app.presetStatuses();
                    },
                },
                {
                    variant: "brand",
                    label: "Save changes and submit",
                    callback: () => {
                        this.showSpinner('Save approval');

                        this.saveApproval()
                        .then((saveResult) => {
                            window.app.setApproval(saveResult);
                            let approvalActionWrapper = this.getApprovalAction();
                            this.showSpinner(approvalActionWrapper.message);
                            return this.setApprovalAction(approvalActionWrapper.action)
                        })
                        .then((submitResult) => {
                            window.app.setApproval(submitResult);
                            this.hideSpinner();
                            this.validateResponse(submitResult);
                            this.checkApprovalIsBlocked();
                        })
                        .catch((err) => this.saveApprovalErrorHandler(err));
                    },
                },
            ],
            () => {
                window.app.presetStatuses();
            }
        )
    }

    validateButtons() {
        this.validateSaveButton();
        this.validateSubmitForApprovalButton();
        this.validateSubmitButton();

        this.isDisabledVatCountyNumber = !this.isVATFieldsEnabled || !window.app.isNewStatus() || !this.VATExemptionChecked;
        this.isDisabledIndianTax = true;
    }

    validateSaveButton() {
        this.isShowSaveButton = !window.app.isApprovalApproved() &&
            !window.app.isApprovalRejected() &&
            !(!window.app.isTaxTeamMember && window.app.isPendingApproval());
        this.isSaveDisabled = !window.app.isUnsavedExempts() || window.app.isRestricetedToClearExemptsOnSubmit();
    }

    validateSubmitForApprovalButton() {
        this.isShowSubmitForApprovalButton = window.app.isNewStatus();
        this.isSubmitForApprovalDisabled = window.app.isRequestedAny() && !window.app.isRequestedAnyAndNotSaved() ||
            !window.app.isRequestedAny() && !window.app.isRequestedAnyAndNotSaved();
    }

    validateSubmitButton() {
        this.isShowSubmitButton = window.app.isTaxTeamMember && window.app.isPendingApproval();
        this.isSubmitDisabled = window.app.isExemptionPendingApproval() || window.app.isRestricetedToClearExemptsOnSubmit();
    }

    validateVATGSTNumber() {
        if (this.VATExemptionChecked && this.isShowVATTaxExemption && this.VATCountry !== 'CH') {
            return validateVATNumber({
                VATNumber: window.app.VATNumber,
                VATCountry: window.app.VATCountry,
                brand: window.app.brand,
            })
        }
        return Promise.resolve({data: {isValid: true}});
    }

    validateAccountExemptions() {
        return validateExemptions({
            app: this.record,
            exemptionStateParams: {
                federal: window.app.taxExemptionState.federal,
                state: window.app.taxExemptionState.state,
                county: window.app.taxExemptionState.county,
                local: window.app.taxExemptionState.local,
                indian: window.app.taxExemptionState.indian,
                vat: window.app.taxExemptionState.vat,
                sales: window.app.taxExemptionState.sales,
            }
        });
    }

    saveApproval() {
        var params = {
                     app: this.record,
                     exemptionStateParams: {
                         federal: window.app.taxExemptionState.federal,
                         state: window.app.taxExemptionState.state,
                         county: window.app.taxExemptionState.county,
                         local: window.app.taxExemptionState.local,
                         vat: window.app.taxExemptionState.vat,
                         VATNumber: window.app.VATNumber,
                         VATCountry: window.app.VATCountry,
                         GSTNumber: window.app.GSTNumber,
                         indian: window.app.taxExemptionState.indian,
                         sales: window.app.taxExemptionState.sales,
                     }
                 };
        console.log('params: ', params);
        return saveApproval(params);
    }

    onChangeVATNumber(event) {
        window.app.setVATNumber(event.target.value || '');
    }

    get record() {
        return window.app.approval.record;
    }

    get isShowUSTaxExemption() {
        return window.app && window.app.isShowUSTaxExemption();
    }

    get isShowVATTaxExemption() {
        return window.app && window.app.isShowVATTaxExemption();
    }

    get isShowIndianTaxExemption() {
        return window.app && window.app.isShowIndianTaxExemption();
    }

    get isSwitzerland() {
        return window.app && window.app.VATCountry == SWITZERLAND_COUNTRY_CODE;
    }

    get isShowSalesTaxExemption() {
        return window.app && window.app.isShowSalesTaxExemption();
    }

    get statusSLDSClass() {
        return this.isShowSalesTaxExemption ? 'slds-col slds-size_2-of-7' : 'slds-col slds-size_4-of-12';
    }

    get taxSLDSClass() {
        return this.isShowSalesTaxExemption ? 'slds-col slds-size_1-of-7' : 'slds-col slds-size_2-of-12';
    }
}