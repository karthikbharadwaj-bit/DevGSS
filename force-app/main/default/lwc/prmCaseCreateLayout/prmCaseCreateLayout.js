import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import getLayout from '@salesforce/apex/PrmCaseCreateHelper.getLayout';
import createCases from '@salesforce/apex/PrmCaseCreateHelper.createCases';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { App } from './App';
import CASE_OBJECT from '@salesforce/schema/Case';

export default class PrmCaseCreateLayout extends NavigationMixin(LightningElement) {

    get hasErrors() {
        return this.hasErrorMessages || this.hasFieldsErrors;
    }

    get hasErrorMessages() {
        return this.errorMessages.length != 0;
    }

    _hrefTabs = [];
    get hrefTabs() {
        return this._hrefTabs;
    }
    set hrefTabs(value) {
        this._hrefTabs = value;
    }

    @track caseDetails;
    @track tabs = [];
    @track layoutItems = [];
    @track isShowButtons = true;

    @track hasFieldsErrors = false;
    @track errorMessages = [];
    isErrorPopoverOpened = false;
    dosRecordTypeId;

    objectInfo;

    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    wireObject(result) {
        if (result.data) {
            this.objectInfo = result.data;
            const recordTypeInfos = this.objectInfo.recordTypeInfos;
            this.dosRecordTypeId = Object.keys(recordTypeInfos).find(recordType => recordTypeInfos[recordType].name === 'Deal and Order Support');
        }
    }

    @wire(getPicklistValuesByRecordType, { objectApiName: 'Case', recordTypeId: '$dosRecordTypeId'})
    CasePickListValues({error, data}) {
        if (data) {
            this.pickListOptions = data.picklistFieldValues;
            this.initComponentData();
        }
    }

    pickListOptions = {};

    fieldTypeMap = {
        TEXTAREA: 'text',
        URL: 'text',
        STRING: 'text',
        REFERENCE: 'lookUp',
        DOUBLE: 'number',
        DATE: 'date',
        BOOLEAN: 'checkbox',
        PICKLIST: 'picklist',
        CURRENCY: 'number'
    };

    connectedCallback() {}

    initComponentData() {
        window.app = new App();
        const queryString = window.location.search;
        const urlParams = new URLSearchParams(queryString);
        const encodedData = urlParams.get('encodedData');
        this.caseDetails = JSON.parse(atob(encodedData));

        getLayout()
            .then(resp => {
                const sections = JSON.parse(resp?.data?.layout);
                const detailGuid = this.generateGuid();
                this.tabs.push(this.buildTab(detailGuid));
                this.layoutItems.push(this.buildLayoutItem(this.caseDetails, detailGuid, sections));
                this.isShowButtons = true;
            })
            .catch(err => {
                this.checkErrors(err);
            });
    }

    buildLayoutItem(detail, detailGuid, sections) {
        let caseFieldValues = detail;
        const hiddenSections = ['System Information', 'Requestor Information'];
        const readOnlyFields = [
            'AccountId',
            'Opportunity_Reference__c',
            'RecordTypeId',
            'OwnerId',
            'ContactId',
            'CaseDependencies__c',
            'Status',
            'Lead__c'
        ];

        const hiddenFields = [
            'OpportunityMRR__c',
            'ParentId',
            'PreviousCaseSubCategory__c',
            'PreviousCaseCategory__c',
            'ParentPartnerAccount__c',
            'ContactId',
            'SuppliedEmail'
        ];

        let _sections = JSON.parse(JSON.stringify(sections))
            .filter(section => !hiddenSections.includes(section.sectionName))
            .map(section => {
                section.columns = section.columns.map(column => {
                    column.items = column.items
                        .map(field => {
                            const guid = this.generateGuid();
                            const value = this.getFieldValue(detail, field);
                            window.app.addCaseFieldData(detailGuid, {
                                id: guid,
                                name: field.fieldName,
                                label: field.label,
                                value: value,
                                isRequired: field.isRequired,
                                isValid: true
                            });

                            caseFieldValues = this.filterLayoutFields(caseFieldValues, field.fieldName);

                            return this.setFieldParams(field, guid, value, readOnlyFields, hiddenFields);
                        });
                    return {
                        ...column,
                        ...{id: this.generateGuid()}
                    };
                });
                return {
                    ...section,
                    ...{
                        id: this.generateGuid(),
                        style: 'slds-col ' + this.getColumnWidth(section.columns),
                        isShown: section.columns.length,
                    }
                };
            });

        this.updateNonLayoutFields(caseFieldValues, detailGuid);

        const result = {
            sections: _sections,
            guid: detailGuid,
            recordTypeName: 'Deal And Order Support',
            headerLabel: 'Case',
            contentClass: [
            "slds-tabs_default__content",
            "slds-m-top_x-small",
            "slds-m-bottom_x-small"]
        };

        return result;
    }

    setFieldParams(field, fieldGuid, value, readOnlyFields, hiddenFields) {
        const type = this.fieldTypeMap[field.fieldType];
        const label = window.app.LABELS.fieldLabels[field.fieldName] || field.label;

        return {
            ...field,
            ...{
                id: fieldGuid,
                type: type,
                isSimpleInput:  this.isSimpleInput(field.fieldType),
                isLookUp: type === 'lookUp',
                isPickList: type === 'picklist',
                isCheckBox: type === 'checkbox',
                options: this.getPickListOptions(field.fieldName),
                step: this.getStep(field.scale),
                lookUpPlaceHolder: this.getLookUpPlaceHolder(field),
                lookUpParams: this.getLookUpParams(field),
                value: value,
                icon: this.getIcon(field),
                fieldClass: 'slds-m-left_x-small slds-m-right_x-small fieldValidity ' + this.getFieldHeight(type),
                isShown: !hiddenFields.includes(field.fieldName) && field.isShown,
                isReadOnly: readOnlyFields.includes(field.fieldName) ? true : field.isReadOnly,
                controllerValues: this.getOptionsByControllerValues(field.fieldName),
                label: label,
                isDisableLink: type === 'lookUp'
            }
        };
    }

    getPickListOptions(fieldName) {
        return this.pickListOptions[fieldName] && this.pickListOptions[fieldName].values;
    }

    getStep(scale) {
        return scale > 0 && '.' + '0'.repeat(scale - 1) + '1';
    }

    getIcon(field) {
        const iconMap = {
            'Account':  'standard:account',
            'Opportunity':  'standard:opportunity',
            'Contact':  'standard:contact',
            'User': 'standard:user',
            'Group': 'standard:groups',
            'RecordType': 'standard:record'
        }
        return this.fieldTypeMap[field.fieldType] === 'lookUp' && (iconMap[field.sObjectName] || 'standard:screen');
    }

    getFieldValue(detail, field) {
        const previousCaseValue = detail[field.fieldName];
        const defaultFieldValue = this.pickListOptions[field.fieldName]
            && this.pickListOptions[field.fieldName].defaultValue
            && this.pickListOptions[field.fieldName].defaultValue.value;

        return defaultFieldValue ?? previousCaseValue;
    }

    getColumnWidth(columns) {
        return columns && columns.length > 1 ? 'slds-size_1-of-2' : 'slds-size_1-of-1';
    }

    getFieldHeight(fieldType) {
        return fieldType === 'checkbox' ? 'checkbox-height' : '';
    }

    getLookUpParams(field) {
        return {
            'sObjectName': field.sObjectName
        };
    }

    isSimpleInput(sfFieldType) {
        const type = this.fieldTypeMap[sfFieldType];
        return type !== 'picklist'
            && type !== 'lookUp'
            && type !== 'checkbox';
    }

    getLookUpPlaceHolder(field) {
        const placeHolderMap = {
            'AccountId': 'Search Accounts...',
            'Opportunity_Reference__c': 'Search Opportunities...',
            'ContactId': 'Search Contacts...'
        }
        return this.fieldTypeMap[field.fieldType] === 'lookUp'
            && (placeHolderMap[field.fieldName] || 'Search records...');
    }

    showButtons(event) {
        this.isShowButtons = true;
    }

    onSave() {
        this.errorMessages = [];
        this.showSpinner('Creating Case record');
        this.checkFieldsValidity()
            .then(res => {
                this.checkErrors(res);
                let sfdcCase = window.app.getCasesInSFDSFormat();
                return createCases({
                    caseListJSON: JSON.stringify(sfdcCase)
                });
            })
            .then(res => {
                this.checkErrors(res);
                this.showToast();
                this.showSpinner('Closing page');
                setTimeout(() => {
                    this.hideSpinner();
                    this.emitCloseWindowAction();
                }, 6000);
            })
            .catch(res => {
                this.hideSpinner();
                let error = {
                    guid: (this.generateGuid()),
                    message: res?.message || res?.body?.message
                };
                if (error.message) {
                    this.errorMessages.push(error);
                }
                this.openErrorPopover();
            });
    }

    onCancel() {
        this.emitCloseWindowAction();
    }

    checkFieldsValidity() {
        this._hrefTabs = [];

        return new Promise((resolve, reject) => {
            this.template.querySelectorAll("c-av-create-layout").forEach(item => {
                item.checkApprovalFieldsValidity();
            });

            Object.keys(window.app.cases).forEach(caseId => {
                const caseData = window.app.cases[caseId];
                Object.keys(caseData.fields).forEach(fieldId => {
                    const fieldData = caseData.fields[fieldId];
                    if (!fieldData.isValid) {
                        this.addFieldToErrorsList(caseId, fieldId, fieldData.label);
                    }
                });
            });

            this.hasFieldsErrors = this._hrefTabs.length > 0;
            this.hasFieldsErrors
                ? reject({status: window.app.LABELS.error})
                : resolve();
        });
    }

    addFieldToErrorsList(approvalId, fieldId, fieldLabel) {
        let tabData = this._hrefTabs.find(item => item.guid === approvalId);
        if (!tabData) {
            const tab = this.tabs.find(item => item.guid === approvalId);
            if (tab) {
                tabData = {guid: tab.guid, name: tab.name, fields: [], hrefId: '#' + tab.guid};
                this._hrefTabs.push(tabData);
            }
        }
        if (!tabData.fields.find(field => field.id === fieldId)) {
            tabData.fields.push({id: fieldId, label: fieldLabel});
        }
    }

    emitCloseWindowAction() {
       window.close();
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

    onErrorButtonClick() {
        this.isErrorPopoverOpened
            ? this.closeErrorPopover()
            : this.openErrorPopover();
    }

    openErrorPopover() {
        this.isErrorPopoverOpened = true;
        let popover = this.template.querySelector('.slds-popover');
        popover?.classList.add('slds-rise-from-ground');
        popover?.classList.remove('slds-fall-into-ground');
    }

    closeErrorPopover() {
        this.isErrorPopoverOpened = false;
        let popover = this.template.querySelector('.slds-popover');
        popover?.classList.add('slds-fall-into-ground');
        popover?.classList.remove('slds-rise-from-ground');
    }

    checkErrors(result) {
        if (result?.status === window.app.LABELS.error.toLowerCase()) {
            throw new getCustomError(result);
        }
    }

    filterLayoutFields(obj, fieldName) {
        return Object.keys(obj)
            .filter(key => key !== fieldName)
            .reduce((res, key) => (res[key] = obj[key], res), {});
    }

    updateNonLayoutFields(caseNonLayoutFieldValues, detailGuid) {
        if (caseNonLayoutFieldValues) {
            for (let fieldName in caseNonLayoutFieldValues) {
                const guid = this.generateGuid();
                const name = fieldName;
                const value = caseNonLayoutFieldValues[fieldName];

                window.app.addCaseFieldData(detailGuid, {
                    id: guid,
                    name: name,
                    value: value,
                    isValid: true
                });
            }
        }
    }

    buildTab(detailGuid) {
        return {
            guid: detailGuid,
            tabClass: "slds-tabs_default__item slds-is-active"
        };
    }

    onFieldClick(event) {
        let tabNum;
        Object.keys(window.app.cases).forEach(caseId => {
            if (
                Object.keys(window.app.cases[caseId].fields)
                    .find(fieldId => fieldId === event.target.dataset.id)
            ) {
                tabNum = Object.keys(window.app.cases).indexOf(caseId);
            }
        });
        const fieldId = event.target.dataset.id;
        setTimeout(() => {
            this.template.querySelectorAll("c-av-create-layout")[tabNum].cScrollTo(fieldId)
        }, 0);
    }

    generateGuid() {
        return String(new Date().getTime() + Math.random());
    }

    showToast() {
        const event = new ShowToastEvent({
            message: 'Case record was created. Current tab will be closed.',
            variant: 'success',
            mode: 'dismissable',
            duration: 5000
        });
        this.dispatchEvent(event);
    }

    getOptionsByControllerValues(fieldName) {
        let controllValues = this.pickListOptions[fieldName]?.controllerValues;
        let mapControllValueToFilteredOptions = {};

        if (controllValues) {
            Object.keys(controllValues).forEach(value => {
                let index = controllValues[value];
                const filteredOptionsByIndex = this.pickListOptions[fieldName].values.filter(value => value.validFor.includes(index));
                mapControllValueToFilteredOptions[value] = {...mapControllValueToFilteredOptions[value], [fieldName]: filteredOptionsByIndex};
            });
        }

        return mapControllValueToFilteredOptions;
    }
}

export function getCustomError(error) {
    this.name = error.typeName;
    this.data = error.data;
    if (Array.isArray(error.messages) && error.messages.length) {
        this.message = error.messages.map(e => {
            if (error.stackTrace) {
                return `${this.name}: ${e.message} \n ${error.stackTrace}`;
            }
            return e.message;
        }).join(', \n');
    } else {
        this.message = error.messages;
    }
    if (Error.captureStackTrace) {
        Error.captureStackTrace(this, this.constructor);
    } else {
        this.stack = error.stackTrace;
    }
}