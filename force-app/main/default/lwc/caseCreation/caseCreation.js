import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import { CloseActionScreenEvent } from 'lightning/actions';
import { CurrentPageReference } from 'lightning/navigation';
import getDealAndOrderSupportRecordTypeId from '@salesforce/apex/CaseHelper.getDealAndOrderSupportRecordTypeId';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import getCustomFormVisibility from '@salesforce/apex/CaseCreateLWCController.getFormVisibility';
import insertCaseAndFiles from '@salesforce/apex/CaseCreateLWCController.insertCaseAndFile';
import Id from '@salesforce/user/Id';

import ACCOUNT_FIELD_ID from '@salesforce/schema/Account.Id';
import ACCOUNT_FIELD_OWNER_ID from '@salesforce/schema/Account.OwnerId';
import ACCOUNT_FIELD_CSM from '@salesforce/schema/Account.CSM__c';
import ACCOUNT_FIELD_PARENT_PARTNER_ACCOUNT from '@salesforce/schema/Account.Parent_Partner_Account__c';

import CASE_FIELD_ACCOUNT_ID from '@salesforce/schema/Case.AccountId';
import CASE_FIELD_CSM from '@salesforce/schema/Case.CSM__c';
import CASE_FIELD_ACCOUNT_OWNER from '@salesforce/schema/Case.AccountOwner__c';
import CASE_FIELD_OPPORTUNITY_REFERENCE from '@salesforce/schema/Case.Opportunity_Reference__c';
import CASE_FIELD_OPPORTUNITY_MRR from '@salesforce/schema/Case.OpportunityMRR__c';
import CASE_FIELD_LEAD from '@salesforce/schema/Case.Lead__c';
import CASE_FIELD_CASE_CATEGORY from '@salesforce/schema/Case.Case_Category__c';
import CASE_FIELD_CASE_SUBCATEGORY from '@salesforce/schema/Case.Case_Subcategory__c';
import CASE_FIELD_PARENT_PARTNER_ACCOUNT from '@salesforce/schema/Case.ParentPartnerAccount__c';

import LEAD_FIELD_ID from '@salesforce/schema/Lead.Id';

import OPPORTUNITY_FIELD_ACCOUNT_ID from '@salesforce/schema/Opportunity.AccountId';
import OPPORTUNITY_FIELD_ACCOUNT_OWNER_ID from '@salesforce/schema/Opportunity.Account.OwnerId';
import OPPORTUNITY_FIELD_ACCOUNT_CSM from '@salesforce/schema/Opportunity.Account.CSM__c';
import OPPORTUNITY_FIELD_ACCOUNT_PARENT_PARTNER_ACCOUNT from '@salesforce/schema/Opportunity.Account.Parent_Partner_Account__c';

const ACCOUNT_FIELDS = [
    ACCOUNT_FIELD_ID,
    ACCOUNT_FIELD_OWNER_ID,
    ACCOUNT_FIELD_CSM,
    ACCOUNT_FIELD_PARENT_PARTNER_ACCOUNT
];
const CASE_FIELDS = [
    CASE_FIELD_ACCOUNT_ID,
    CASE_FIELD_CSM,
    CASE_FIELD_ACCOUNT_OWNER,
    CASE_FIELD_OPPORTUNITY_REFERENCE,
    CASE_FIELD_OPPORTUNITY_MRR,
    CASE_FIELD_LEAD,
    CASE_FIELD_CASE_CATEGORY,
    CASE_FIELD_CASE_SUBCATEGORY,
    CASE_FIELD_PARENT_PARTNER_ACCOUNT
];
const LEAD_FIELDS = [LEAD_FIELD_ID];
const OPPORTUNITY_FIELDS = [
    OPPORTUNITY_FIELD_ACCOUNT_ID,
    OPPORTUNITY_FIELD_ACCOUNT_OWNER_ID,
    OPPORTUNITY_FIELD_ACCOUNT_CSM,
    OPPORTUNITY_FIELD_ACCOUNT_PARENT_PARTNER_ACCOUNT
];
let FIELDS = [];


export default class CaseCreation extends NavigationMixin(LightningElement) {
    showCaseButton = false;
    showPrevButton = false;
    showNextButton = false;
    @track dealAndOrderSupportRecordTypeId;
    @track targetRecordId;
    @track targetObjectApiName;
    targetRecord;
    @track showBanner = true;
    @track showButton = false;
    @track showForm = false;
    spinner = false;
    refSectionFieldList;
    caseInfoSectionFieldList;
    descSectionFieldList;
    mandatoryFieldList;
    showMandatoryDescField = false;
    @track filesData = [];
    userId = Id;
    runAssignmentRule = true;
    descIndex;
    descFieldObj;

    get disableCreateButton() {
        return !this.showCaseButton;
    }

    @wire(CurrentPageReference)
    getObjectParameters(currentPageReference) {
        if (currentPageReference) {
            this.targetRecordId = currentPageReference.state.recordId;
            this.targetObjectApiName = currentPageReference.attributes.apiName.split('.')[0];
            this.getFieldsList(this.targetObjectApiName);
        }
    }

    @wire(getRecord, {
        recordId: '$targetRecordId',
        fields: FIELDS
    })
    handleGetRecord({ data }) {
        if (data) {
            this.targetRecord = data.fields;
        }
    }

    connectedCallback(){
        this.getDealAndOrderSupportRecordTypeId();
    }

    handleBannerDisplay(event){
        this.showButton = !event.detail.noRecords;
        if(event.detail.noRecords){
            this.showBanner = false;
            this.getFormVisibility();
        } else if(event.detail.showCreateButton){
            this.showCaseButton = true;
        }
        this.showPrevButton = !event.detail.navigationData.isFirst;
        this.showNextButton = !event.detail.navigationData.isLast;
    }

    handleNavigation(event) {
        this.showPrevButton = !event.detail.navigationData.isFirst;
        this.showNextButton = !event.detail.navigationData.isLast;
    }

    handleClick(event) {
        this.showBanner = false;
        this.getFormVisibility();
    }

    handlePreviousClick(event) {
        this.template.querySelector("c-banner-for-outage").hanldePrevious();
    }

    handleNextClick(event) {
        this.template.querySelector("c-banner-for-outage").hanldeNext();
    }

    get showCreateCaseButton() {
        return (!this.showPrevButton && !this.showNextButton)
            || (this.showPrevButton && !this.showNextButton);
    }

    getFormVisibility() {
        let origin = '';
        if (this.targetObjectApiName == 'Case') {
            origin = 'Case';
        }
        this.spinner = true;
        getCustomFormVisibility({ caseOrigin: origin })
            .then(response => {
                this.showBanner = false;
                if (response == null) {
                    this.showForm = false;
                    this.dispatchEvent(new CloseActionScreenEvent());
                    this.navigateToNewCasePage();
                }
                else {
                    this.showForm = true;
                    this.refSectionFieldList = this.prepopulateFields(response['Reference Information'], this.targetObjectApiName);
                    this.refSectionFieldList = this.refSectionFieldList.map(obj => {
                        if (obj.fieldName === 'OpportunityMRR__c') {
                            return { ...obj, isMRR: true };
                        }
                        return { ...obj, isMRR: false };;
                    });
                    this.caseInfoSectionFieldList = this.prepopulateFields(response['Case Information'], this.targetObjectApiName);
                    this.descSectionFieldList = this.prepopulateFields(response['Description Information'], this.targetObjectApiName);
                    this.mandatoryFieldList = response['Mandatory Information'];
                    let category = this.caseInfoSectionFieldList.find((caseInfo) => caseInfo.fieldName === "Case_Category__c");
                    if (category && category.value === 'System Issue') {
                        this.showMandatoryDescField = true;
                        let index = this.descSectionFieldList.findIndex(obj => obj.fieldName === 'Description');
                        this.descIndex = index;
                        this.descFieldObj = this.descSectionFieldList[index];
                        if (index !== -1) {
                            this.descSectionFieldList.splice(index, 1);
                        }
                    }
                    else {
                        this.showMandatoryDescField = false;
                        this.descSectionFieldList = this.descSectionFieldList.map(obj => {
                            if (obj.fieldName === 'Description') {
                                return { ...obj, isRequired: true };
                            }
                            return obj;
                        });
                    }
                }
            })
            .catch(error => {
                this.spinner = false;
                if (error.body?.message) {
                    this.showNotification('Error', error.body.message, 'Error');
                }
            });
    }

    getDealAndOrderSupportRecordTypeId() {
        getDealAndOrderSupportRecordTypeId()
            .then(response => {
                this.dealAndOrderSupportRecordTypeId = response.data.dealAndOrderSupportRecordTypeId;

            })
            .catch(error => {
                if (error.body?.message) {
                    this.showNotification('Error', error.body.message, 'Error');
                }
            });
    }

    navigateToNewCasePage() {
        let defaultFieldsValues = this.getDefaultFieldsValues(this.targetObjectApiName);
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Case',
                actionName: 'new'
            },
            state: {
                recordTypeId: this.dealAndOrderSupportRecordTypeId,
                nooverride: '1',
                defaultFieldValues: defaultFieldsValues
            }
        }).then((url) => {
            window.open(url);
        });
    }

    getDefaultFieldsValues(objectApiName) {
        let defaultFieldsValues;
        if (objectApiName === 'Account') {
            defaultFieldsValues = encodeDefaultFieldValues({
                Case_Category__c: 'Account Updates',
                AccountId: this.targetRecordId,
                Origin: 'Account',
                AccountOwner__c: this.targetRecord[ACCOUNT_FIELD_OWNER_ID.fieldApiName].value,
                CSM__c: this.targetRecord[ACCOUNT_FIELD_CSM.fieldApiName].value,
                ParentPartnerAccount__c: this.targetRecord[ACCOUNT_FIELD_PARENT_PARTNER_ACCOUNT.fieldApiName].value
            });
        } else if (objectApiName === 'Lead') {
            defaultFieldsValues = encodeDefaultFieldValues({
                Case_Category__c: 'System Issue',
                Case_Subcategory__c: 'Lead',
                Lead__c: this.targetRecordId,
                Origin: 'Lead'
            });
        } else if (objectApiName === 'Opportunity') {
            defaultFieldsValues = encodeDefaultFieldValues({
                Case_Category__c: 'Approval Request',
                Opportunity_Reference__c: this.targetRecordId,
                Origin: 'Opportunity',
                AccountId: this.targetRecord[OPPORTUNITY_FIELD_ACCOUNT_ID.fieldApiName].value,
                AccountOwner__c: this.targetRecord.Account.value.fields[ACCOUNT_FIELD_OWNER_ID.fieldApiName].value,
                CSM__c: this.targetRecord.Account.value.fields[ACCOUNT_FIELD_CSM.fieldApiName].value,
                ParentPartnerAccount__c: this.targetRecord.Account.value.fields[ACCOUNT_FIELD_PARENT_PARTNER_ACCOUNT.fieldApiName].value
            });
        } else if (objectApiName === 'Case') {
            defaultFieldsValues = encodeDefaultFieldValues({
                Case_Category__c: 'System Issue',
                Origin: 'Case',
                ParentId: this.targetRecordId,
                AccountId: this.targetRecord[CASE_FIELD_ACCOUNT_ID.fieldApiName].value,
                CSM__c: this.targetRecord[CASE_FIELD_CSM.fieldApiName].value,
                AccountOwner__c: this.targetRecord[CASE_FIELD_ACCOUNT_OWNER.fieldApiName].value,
                Opportunity_Reference__c: this.targetRecord[CASE_FIELD_OPPORTUNITY_REFERENCE.fieldApiName].value,
                OpportunityMRR__c: this.targetRecord[CASE_FIELD_OPPORTUNITY_MRR.fieldApiName].value,
                Lead__c: this.targetRecord[CASE_FIELD_LEAD.fieldApiName].value,
                PreviousCaseCategory__c: this.targetRecord[CASE_FIELD_CASE_CATEGORY.fieldApiName].value,
                PreviousCaseSubCategory__c: this.targetRecord[CASE_FIELD_CASE_SUBCATEGORY.fieldApiName].value,
                ParentPartnerAccount__c: this.targetRecord[CASE_FIELD_PARENT_PARTNER_ACCOUNT.fieldApiName].value
            });
        }
        return defaultFieldsValues;
    }

    showNotification(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

    getFieldsList(objectApiName) {
        if (objectApiName === 'Account') {
            FIELDS = ACCOUNT_FIELDS;
        } else if (objectApiName === 'Lead') {
            FIELDS = LEAD_FIELDS;
        } else if (objectApiName === 'Opportunity') {
            FIELDS = OPPORTUNITY_FIELDS;
        } else if (objectApiName === 'Case') {
            FIELDS = CASE_FIELDS;
        }
    }

    handleSubmit(e) {
        e.preventDefault();
        this.spinner = true;
        let isValid = this.validateFields();
        let fileData = this.filesData.length > 0 ? JSON.stringify(this.filesData) : '';
        if (isValid) {
            var fields = e.detail.fields;
            insertCaseAndFiles({ runAssignmentRule: this.runAssignmentRule, caseJsonBody: JSON.stringify(fields), fileJsonBody: fileData })
                .then(response => {
                    this.spinner = false;
                    if (response.status === 'Success') {
                        this.showNotification('Success', 'Case created successfully.', 'success');
                        this.navigateToRecord(response.msg);
                    }
                    else {
                        this.showNotification('Error', response.msg, 'error');
                    }
                })
                .catch(error => {
                    this.spinner = false;
                    if (error.body?.message) {
                        this.showNotification('Error', error.body.message, 'Error');
                    }
                });
        }
        return;
    }

    validateFields() {
        return [...this.template.querySelectorAll("lightning-input-field")].reduce((validSoFar, field) => {
            return (validSoFar && field.reportValidity());
        }, true);
    }

    handleChange(e) {
        e.preventDefault();
        if (e.target.fieldName === 'Case_Category__c' && e.target.value === 'System Issue' && this.showMandatoryDescField === false) {
            this.showMandatoryDescField = true;
            let index = this.descSectionFieldList.findIndex(obj => obj.fieldName === 'Description');
            this.descIndex = index;
            this.descFieldObj = this.descSectionFieldList[index];
            if (index !== -1) {
                this.descSectionFieldList.splice(index, 1);
            }
        }
        else if (e.target.fieldName === 'Case_Category__c' && e.target.value !== 'System Issue' && this.showMandatoryDescField) {
            this.showMandatoryDescField = false;
            this.filesData = [];
            let obj = this.descFieldObj;
            obj = {...obj, isRequired: true };
            if(this.descIndex !== -1 && this.descFieldObj){
                this.descSectionFieldList.splice(this.descIndex, 0, obj);
            }
        }
    }

    prepopulateFields(fieldList, objectApiName) {
        let targetId = this.targetRecordId;
        let targetRecord = this.targetRecord;
        let recordTypeId = this.dealAndOrderSupportRecordTypeId;
        let userId = this.userId;
        let fieldArr = [];
        fieldList.forEach(function (data) {
            let res = { ...data };
            let val;

            if (objectApiName === 'Account') {
                if (res.fieldName == 'Case_Category__c') {
                    val = {
                        value: 'Account Updates'
                    };
                }
                else if (res.fieldName == 'AccountId') {
                    val = {
                        value: targetId
                    };
                }
                else if (res.fieldName == 'Origin') {
                    val = {
                        value: 'Account'
                    };
                }
                else if (res.fieldName == 'AccountOwner__c') {
                    val = {
                        value: targetRecord[ACCOUNT_FIELD_OWNER_ID.fieldApiName].value
                    };
                }
                else if (res.fieldName == 'CSM__c') {

                    val = {
                        value: targetRecord[ACCOUNT_FIELD_CSM.fieldApiName].value
                    };

                }
                else if (res.fieldName == 'ParentPartnerAccount__c') {
                    val = {
                        value: targetRecord[ACCOUNT_FIELD_PARENT_PARTNER_ACCOUNT.fieldApiName].value
                    };
                }
                else if (res.fieldName == 'OpportunityMRR__c') {
                    val = {
                        value: 0
                    };
                }
                else {
                    val = {
                        value: null
                    };
                }
            }
            else if (objectApiName === 'Lead') {
                if (res.fieldName == 'Case_Category__c') {
                    val = {
                        value: 'System Issue'
                    };
                }
                else if (res.fieldName == 'Case_Subcategory__c') {
                    val = {
                        value: 'Lead'
                    };
                }
                else if (res.fieldName == 'Lead__c') {
                    val = {
                        value: targetId
                    };
                }
                else if (res.fieldName == 'Origin') {
                    val = {
                        value: 'Lead'
                    };
                }
                else if (res.fieldName == 'OpportunityMRR__c') {
                    val = {
                        value: 0
                    };
                }
                else {
                    val = {
                        value: null
                    };
                }
            }
            else if (objectApiName === 'Opportunity') {
                if (res.fieldName == 'Case_Category__c') {
                    val = {
                        value: 'Approval Request'
                    };
                }
                else if (res.fieldName == 'Opportunity_Reference__c') {
                    val = {
                        value: targetId
                    };
                }
                else if (res.fieldName == 'AccountId') {
                    val = {
                        value: targetRecord[OPPORTUNITY_FIELD_ACCOUNT_ID.fieldApiName].value
                    };
                }
                else if (res.fieldName == 'AccountOwner__c') {
                    val = {
                        value: targetRecord.Account.value.fields[ACCOUNT_FIELD_OWNER_ID.fieldApiName].value
                    };
                }
                else if (res.fieldName == 'CSM__c') {
                    val = {
                        value: targetRecord.Account.value.fields[ACCOUNT_FIELD_CSM.fieldApiName].value
                    };
                }
                else if (res.fieldName == 'ParentPartnerAccount__c') {
                    val = {
                        value: targetRecord.Account.value.fields[ACCOUNT_FIELD_PARENT_PARTNER_ACCOUNT.fieldApiName].value
                    };
                }
                else if (res.fieldName == 'Origin') {
                    val = {
                        value: 'Opportunity'
                    };
                }
                else if (res.fieldName == 'OpportunityMRR__c') {
                    val = {
                        value: 0
                    };
                }
                else {
                    val = {
                        value: null
                    };
                }
            }
            else if (objectApiName === 'Case') {
                if (res.fieldName == 'Case_Category__c') {
                    val = {
                        value: 'System Issue'
                    };
                }
                else if (res.fieldName == 'Origin') {
                    val = {
                        value: 'Case'
                    };
                }
                else if (res.fieldName == 'ParentId') {
                    val = {
                        value: targetId
                    };
                }
                else if (res.fieldName == 'AccountId') {
                    val = {
                        value: targetRecord[CASE_FIELD_ACCOUNT_ID.fieldApiName].value
                    };
                }
                else if (res.fieldName == 'CSM__c') {
                    val = {
                        value: targetRecord[CASE_FIELD_CSM.fieldApiName].value
                    };
                }
                else if (res.fieldName == 'AccountOwner__c') {
                    val = {
                        value: targetRecord[CASE_FIELD_ACCOUNT_OWNER.fieldApiName].value
                    };
                }
                else if (res.fieldName == 'Opportunity_Reference__c') {
                    val = {
                        value: targetRecord[CASE_FIELD_OPPORTUNITY_REFERENCE.fieldApiName].value
                    };
                }
                else if (res.fieldName == 'OpportunityMRR__c') {
                    val = {
                        value: targetRecord[CASE_FIELD_OPPORTUNITY_MRR.fieldApiName].value
                    };
                }
                else if (res.fieldName == 'Lead__c') {
                    val = {
                        value: targetRecord[CASE_FIELD_LEAD.fieldApiName].value
                    };
                }
                else if (res.fieldName == 'PreviousCaseCategory__c') {
                    val = {
                        value: targetRecord[CASE_FIELD_CASE_CATEGORY.fieldApiName].value
                    };
                }
                else if (res.fieldName == 'PreviousCaseSubCategory__c') {
                    val = {
                        value: targetRecord[CASE_FIELD_CASE_SUBCATEGORY.fieldApiName].value
                    };
                }
                else if (res.fieldName == 'ParentPartnerAccount__c') {
                    val = {
                        value: targetRecord[CASE_FIELD_PARENT_PARTNER_ACCOUNT.fieldApiName].value
                    };
                }
                else {
                    val = {
                        value: null
                    };
                }
            }
            if (res.fieldName == 'Status') {
                val = {
                    value: 'New'
                };
            }
            if (res.fieldName == 'RecordTypeId') {
                val = {
                    value: recordTypeId
                };
            }
            if (res.fieldName == 'OwnerId') {
                val = {
                    value: userId
                };
            }
            if (res.fieldName == 'Priority') {
                val = {
                    value: 'Medium'
                };
            }
            res = { ...res, ...val }
            fieldArr.push(res);
        });
        return fieldArr;
    }

    handleFileUploaded(event) {
        if (event.target.files.length > 0) {
            for (var i = 0; i < event.target.files.length; i++) {
                let file = event.target.files[i];
                let reader = new FileReader();
                reader.onload = e => {
                    var fileContents = reader.result.split(',')[1]
                    this.filesData.push({ 'fileName': file.name, 'fileContent': fileContents });
                };
                reader.readAsDataURL(file);
            }
        }
    }

    removeFile(event) {
        var index = event.currentTarget.dataset.id;
        this.filesData.splice(index, 1);
    }

    handleCheckboxChange(event) {
        this.runAssignmentRule = event.target.checked;
    }

    handleCancel(e) {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    navigateToRecord(recId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recId,
                actionName: 'view'
            }
        });
    }

    handleOnLoad(e) {
        this.spinner = false;
    }
}