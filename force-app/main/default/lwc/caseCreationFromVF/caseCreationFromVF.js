import { LightningElement, track, api } from 'lwc';
import getCustomFormVisibility from '@salesforce/apex/CaseCreateLWCController.getFormVisibility';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getDealAndOrderSupportRecordTypeId from '@salesforce/apex/CaseHelper.getDealAndOrderSupportRecordTypeId';
import deserializeToMap from '@salesforce/apex/CaseCreateLWCController.deserializeToMap';
import insertCaseAndFiles from '@salesforce/apex/CaseCreateLWCController.insertCaseAndFile';
import { CurrentPageReference } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import { NavigationMixin } from 'lightning/navigation';
import Id from '@salesforce/user/Id';

export default class CaseCreationFromVf extends NavigationMixin(LightningElement) {
    showPrevButton = false;
    showNextButton = false;
    isModalOpen = true;
    spinner = false;
    @track showBanner = true;
    @track showForm = false;
    refSectionFieldList;
    caseInfoSectionFieldList;
    descSectionFieldList;
    mandatoryFieldList;
    showMandatoryDescField = false;
    @track filesData = [];
    @track dealAndOrderSupportRecordTypeId;
    @api origin;
    @api mapParam;
    caseMap;
    @track filesData = [];
    runAssignmentRule = true;
    @track showButton = false;
    showCaseButton = false;
    descIndex;
    descFieldObj;

    connectedCallback() {
        this.getDealAndOrderSupportRecordTypeId();
        if (this.mapParam && this.mapParam.length > 0) {
            this.deserializeStringToMap(this.mapParam);
        }
    }

    get disableCreateButton() {
        return !this.showCaseButton;
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

    getFormVisibility() {
        let origin = '';
        this.spinner = true;
        getCustomFormVisibility({ caseOrigin: this.origin })
            .then(response => {
                this.showBanner = false;
                const csmap = new Map(Object.entries(this.caseMap));
                console.log(csmap);
                if (response == null) {
                    this.showForm = false;
                    this.navigateToNewCasePage(csmap);
                }
                else {
                    this.showForm = true;
                    this.refSectionFieldList = this.prepopulateFields(response['Reference Information'], csmap, this.origin);
                    this.refSectionFieldList = this.refSectionFieldList.map(obj => {
                        if (obj.fieldName === 'OpportunityMRR__c') {
                            return { ...obj, isMRR: true };
                        }
                        return { ...obj, isMRR: false };;
                    });
                    this.caseInfoSectionFieldList = this.prepopulateFields(response['Case Information'], csmap, this.origin);
                    this.descSectionFieldList = this.prepopulateFields(response['Description Information'], csmap, this.origin);
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
        getDealAndOrderSupportRecordTypeId({})
            .then(response => {
                this.dealAndOrderSupportRecordTypeId = response.data.dealAndOrderSupportRecordTypeId;
            })
            .catch(error => {
                if (error.body?.message) {
                    this.showNotification('Error', error.body.message, 'Error');
                }
            });
    }

    deserializeStringToMap(mapParam) {
        deserializeToMap({ encodedString: mapParam })
            .then(response => {
                this.caseMap = response;
            })
            .catch(error => {
                if (error.body?.message) {
                    this.showNotification('Error', error.body.message, 'Error');
                }
            });
    }

    closeModal() {
        this.isModalOpen = false;
        window.close();
    }

    showNotification(title, message, variant) {
        window.parent.postMessage(
            {
                action: 'showToast',
                title: title,
                message: message,
                variant: variant
            },
            '*'
        );
    }

    prepopulateFields(fieldList, csMap, origin) {
        let recordTypeId = this.dealAndOrderSupportRecordTypeId;
        let userId = this.userId;
        let fieldArr = [];
        fieldList.forEach(function (data) {
            let res = { ...data };
            let val;
            if (res.fieldName == 'Case_Category__c' && csMap.has('Case_Category__c')) {
                val = {
                    value: csMap.get('Case_Category__c')
                };
            }
            else if (res.fieldName == 'Case_Subcategory__c' && csMap.has('Case_Subcategory__c')) {
                val = {
                    value: csMap.get('Case_Subcategory__c')
                };
            }
            else if (res.fieldName == 'AccountId' && csMap.has('AccountId')) {
                val = {
                    value: csMap.get('AccountId')
                };
            }
            else if (res.fieldName == 'Origin' && csMap.has('Origin')) {
                val = {
                    value: csMap.get('Origin')
                };
            }
            else if (res.fieldName == 'AccountOwner__c' && csMap.has('AccountOwner__c')) {
                val = {
                    value: csMap.get('AccountOwner__c')
                };
            }
            else if (res.fieldName == 'CSM__c' && csMap.has('CSM__c')) {
                val = {
                    value: csMap.get('CSM__c')
                };
            }
            else if (res.fieldName == 'ParentPartnerAccount__c' && csMap.has('ParentPartnerAccount__c')) {
                val = {
                    value: csMap.get('ParentPartnerAccount__c')
                };
            }
            else if (res.fieldName == 'Opportunity_Reference__c' && csMap.has('Opportunity_Reference__c')) {
                val = {
                    value: csMap.get('Opportunity_Reference__c')
                };
            }
            else if (res.fieldName == 'Lead__c' && csMap.has('Lead__c')) {
                val = {
                    value: csMap.get('Lead__c')
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

    navigateToNewCasePage(csmap) {
        let encodedString = this.getDefaultFieldsValues(this.origin, csmap);
        let url = '/lightning/o/Case/new?recordTypeId=' + this.dealAndOrderSupportRecordTypeId + '&nooverride=1&defaultFieldValues=' + encodedString;
        window.open(url, '_self');
    }

    getDefaultFieldsValues(origin, csMap) {
        let caseMap = new Map();
        caseMap.set('Case_Category__c', csMap.has('Case_Category__c') ? csMap.get('Case_Category__c') : '');
        caseMap.set('Origin', csMap.has('Origin') ? csMap.get('Origin') : '');
        caseMap.set('AccountId', csMap.has('AccountId') ? csMap.get('AccountId') : null);
        caseMap.set('Opportunity_Reference__c', csMap.has('Opportunity_Reference__c') ? csMap.get('Opportunity_Reference__c') : null);
        caseMap.set('CSM__c', csMap.has('CSM__c') ? csMap.get('CSM__c') : null);
        caseMap.set('ParentPartnerAccount__c', csMap.has('ParentPartnerAccount__c') ? csMap.get('ParentPartnerAccount__c') : null);
        caseMap.set('AccountOwner__c', csMap.has('AccountOwner__c') ? csMap.get('AccountOwner__c') : null);
        caseMap.set('Case_Subcategory__c', csMap.has('Case_Subcategory__c') ? csMap.get('Case_Subcategory__c') : null);
        caseMap.set('Lead__c', csMap.has('Lead__c') ? csMap.get('Lead__c') : null);
        let encodedString = this.encodeDefaultFieldValues(caseMap);
        return encodedString;
    }

    encodeDefaultFieldValues(caseMap) {
        const encodedString = encodeURIComponent(
            Array.from(caseMap.keys()).reduce((result, key) => {
                const value = caseMap.get(key);
                return value ? `${result}${key}=${value},` : result;
            }, "")
        );
        return encodedString;
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

    handleCancel(e) {
        this.closeModal();
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

    handleOnLoad(e) {
        this.spinner = false;
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

    navigateToRecord(recId) {
        window.open('/lightning/r/Case/' + recId + '/view', '_self');
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

    get showCreateCaseButton() {
        return (!this.showPrevButton && !this.showNextButton)
            || (this.showPrevButton && !this.showNextButton);
    }

}