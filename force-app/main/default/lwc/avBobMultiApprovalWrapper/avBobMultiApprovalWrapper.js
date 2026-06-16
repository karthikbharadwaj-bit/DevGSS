import { LightningElement, api, track, wire } from 'lwc';
import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import { App } from './App';
import getLayout from '@salesforce/apex/BobMultiApprovalHelper.getLayout';
import createAndSubmitApprovals from '@salesforce/apex/BobMultiApprovalHelper.createAndSubmitApprovals';
import populatePartnerInfoOnAccounts from '@salesforce/apex/BobMultiApprovalHelper.populatePartnerInfoOnAccounts';
import getAccountLimits from '@salesforce/apex/BobMultiApprovalHelper.getAccountLimits';
import getAccountSummary from '@salesforce/apex/BobMultiApprovalHelper.getAccountSummary';

export default class AvBobMultiApprovalWrapper extends LightningElement {
    @api approvalDetailsRaw;

    get hasErrors() {
        return this.hasErrorMessages || this.hasFieldsErrors;
    }

    get hasErrorMessages() {
        return this.errorMessages.length != 0;
    }

    get saveLabel() {
        return this.isSingleApproval(this.approvalDetails) ? 'Save' : 'Save All';
    }

    _hrefTabs = [];
    get hrefTabs() {
        return this._hrefTabs;
    }
    set hrefTabs(value) {
        this._hrefTabs = value;
    }

    @track tabs = [];
    @track layoutItems = [];
    @track approvalDetails = [];
    @track isShowButtons = false;

    @track hasFieldsErrors = false;
    @track errorMessages = [];
    isErrorPopoverOpened = false;

    @wire(getPicklistValuesByRecordType, { objectApiName: 'Approval__c', recordTypeId: '$recordTypeId'})
    ApprovalPickListValues({error, data}) {
        if (data) {
            this.pickListOptions = data.picklistFieldValues;
        }
    }

    get recordTypeId() {
        return this.approvalDetails.length && this.approvalDetails[0].recordTypeId;
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

    connectedCallback() {
        window.app = new App();

        this.sortApprovalDetails();

        this.getLimits()
            .then(resp => {
                window.app.accountLimits = resp;
                return getLayout({recordTypeId: this.approvalDetails[0].recordTypeId});
            })
            .then(resp => {
                const sections = JSON.parse(resp?.data?.layout);
                let layoutSections = [];
                this.approvalDetails.forEach(detail => {
                    const detailGuid = this.generateGuid();
                    window.app.addAccount(detail);

                    this.tabs.push(this.buildTab(detail, detailGuid));
                    layoutSections.push(this.buildLayoutItem(detail, detailGuid, sections));
                });

                //need to clone layoutSections array into layoutItems to avoid error in child component
                this.layoutItems = JSON.parse(JSON.stringify(layoutSections));
                this.isShowButtons = true;
            })
    }

    sortApprovalDetails() {
        this.approvalDetails = [...this.approvalDetailsRaw];
        this.approvalDetails.sort((a, b) => {
            if (a.isMasterApproval) {
                return -1;
            } else {
                return 1;
            }
        });
    }

    getLimits() {
        let accLimitsResult = {};
        return new Promise((resolve, reject) => {

            const nextOrResolve = (counter) => {
                if (counter < this.approvalDetails.length) {
                    doNextCall(counter);
                } else {
                    resolve(accLimitsResult);
                }
            };

            const doNextCall = (counter = 0) => {
                const ad = this.approvalDetails[counter];
                const billingId = ad.account.Billing_ID__c;

                getAccountSummary({billingId: billingId})
                    .then((resp) => {
                        const packageId = resp.data?.packageId;
                        return getAccountLimits({billingId: billingId, packageId: packageId});
                    })
                    .then((resp) => {
                        accLimitsResult = {
                            ...accLimitsResult,
                            ...{
                                [ad.defaultFieldValues.Account__c]: {'Monthly_Credit_Limit__c': resp.data?.limit}
                            }
                        };
                        nextOrResolve(++counter);
                    })
                    .catch(ex => {
                        nextOrResolve(++counter);
                    })
            };

            doNextCall();
        });
    }

    buildTab(detail, detailGuid) {
        return {
            guid: detailGuid,
            tabClass: [ "slds-tabs_default__item", this.isActiveTab(detail.isMasterApproval) ].join(' '),
            name: this.truncName(detail.accountName, 50),
            title: detail.accountName,
            isMasterApproval: detail.isMasterApproval,
        };
    }

    buildLayoutItem(detail, detailGuid, sections) {
        let approvalFieldValues = detail?.defaultFieldValues;
        const hiddenSections = ['System Information'];

        let _sections = JSON.parse(JSON.stringify(sections))
            .filter(section => !hiddenSections.includes(section.sectionName))
            .map(section => {
                section.columns = section.columns.map(column => {
                    column.items = column.items
                        .filter(field => field.isEditable)
                        .map(field => {
                            const guid = this.generateGuid();
                            const value = this.getFieldValue(detail, field, window.app.accountLimits);
                            window.app.addApprovalFieldData(detailGuid, {
                                id: guid,
                                name: field.fieldName,
                                label: field.label,
                                value: value,
                                isRequired: field.isRequired,
                                isValid: true
                            });

                            approvalFieldValues = this.filterLayoutFields(approvalFieldValues, field.fieldName);

                            return this.setFieldParams(field, guid, value);
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

        this.updateNonLayoutFields(approvalFieldValues, detailGuid);

        return {
            sections: _sections,
            guid: detailGuid,
            recordTypeName: detail.recordTypeName,
            headerLabel: 'Approval',
            contentClass: [
                "slds-tabs_default__content",
                "slds-m-top_x-small",
                "slds-m-bottom_x-small",
                this.isActiveContent(detail.isMasterApproval)].join(' '),
        };
    }

    setFieldParams(field, fieldGuid, value) {
        const type = this.fieldTypeMap[field.fieldType];
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
                isShown: field.isShown,
                isReadOnly: field.isReadOnly,
                controllerValues: this.getOptionsByControllerValues(field.fieldName),
                isDisableLink: false
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
            'Approval__c': 'standard:approval',
            'User': 'standard:user',
            'Group': 'standard:groups',
            'RecordType': 'standard:record'
        }
        return this.fieldTypeMap[field.fieldType] === 'lookUp' && (iconMap[field.sObjectName] || 'standard:screen');
    }

    getFieldValue(detail, field, accountLimits) {
        const accLimit = accountLimits[detail?.defaultFieldValues.Account__c];

        const ngbsValue = accLimit && accLimit[field.fieldName];
        const previousApprovalValue = detail?.defaultFieldValues[field.fieldName];
        const defaultFieldValue = this.pickListOptions[field.fieldName]
            && this.pickListOptions[field.fieldName].defaultValue
            && this.pickListOptions[field.fieldName].defaultValue.value;

        return ngbsValue ?? previousApprovalValue ?? defaultFieldValue;
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
            'Account__c': 'Search Accounts...',
            'Opportunity__c': 'Search Opportunities...',
            'Contact__c': 'Search Contacts...',
            'Prior_Approval__c': 'Search Approvals...'
        }
        return this.fieldTypeMap[field.fieldType] === 'lookUp'
            && (placeHolderMap[field.fieldName] || 'Search records...');
    }

    isActiveTab(isMasterApproval) {
        return isMasterApproval || this.isSingleApproval(this.approvalDetails) ? 'slds-is-active' : '';
    }

    isActiveContent(isMasterApproval) {
        return isMasterApproval || this.isSingleApproval(this.approvalDetails) ? 'slds-show' : 'slds-hide';
    }

    truncName(name, num) {
        if (name.length <= num) {
            return name;
        }
        return name.slice(0, num) + '...';
    }

    toggle(event) {
        this.setActiveLayout(event.currentTarget.dataset.id);
    }

    setActiveLayout(layoutItemId) {
        this.layoutItems.forEach(item => {
            if (item.guid == layoutItemId) {
                item.contentClass = item.contentClass.replace('slds-hide', 'slds-show');
            } else {
                item.contentClass = item.contentClass.replace('slds-show', 'slds-hide');
            }
        });

        this.tabs.forEach(tab => {
            if (tab.guid == layoutItemId) {
                tab.tabClass += !tab.tabClass.includes('slds-is-active')
                    ? 'slds-is-active'
                    : '';
            } else {
                tab.tabClass = tab.tabClass.replace('slds-is-active', '');
            }
        });

        this.closeErrorPopover();
    }

    showButtons(event) {
        this.isShowButtons = true;
    }

    onSave() {
        this.errorMessages = [];
        this.showSpinner('Creating Approval records');
        this.checkFieldsValidity()
            .then(res => {
                this.checkErrors(res);

                let SFDCApprovals = window.app.getApprovalsInSFDSFormat();
                let accMonthlyCreditLimits = window.app.getMonthlyCreditLimitsForAccounts();

                return createAndSubmitApprovals({
                    approvalsListJSON: JSON.stringify(SFDCApprovals),
                    accIdToMonthlyCreditLimitMapJSON: JSON.stringify(accMonthlyCreditLimits)
                });
            })
            .then(res => {
                this.checkErrors(res);
                this.hideSpinner();
                if (this.isSingleApproval(this.approvalDetails)) {
                    return;
                } else {
                    this.showSpinner('Updating Account Partner data');

                    return populatePartnerInfoOnAccounts({accountListJSON: JSON.stringify(window.app.accounts)});
                }
            })
            .then(res => {
                this.checkErrors(res);
                this.hideSpinner();
                this.emitCloseWindowAction();
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

            Object.keys(window.app.approvals).forEach(approvalId => {
                const approvalData = window.app.approvals[approvalId];
                Object.keys(approvalData.fields).forEach(fieldId => {
                    const fieldData = approvalData.fields[fieldId];
                    if (!fieldData.isValid) {
                        this.addFieldToErrorsList(approvalId, fieldId, fieldData.label);
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

    isBlank(obj) {
        return obj === null || obj === undefined || obj === '';
    }

    emitCloseWindowAction() {
        const closeAction = new CustomEvent('closeBobMultiApprovalPage', {});
        this.dispatchEvent(closeAction);
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

    fireToastEvent(res) {
        const message = res && res.messages[0] && res.messages[0].message
            || 'Approval records were successfully created';
        const type = res && res.messages[0] && res.messages[0].message
            ? 'error'
            : 'success';
        window.dispatchEvent(new CustomEvent('ShowToastEvent', {
            detail: {
                title: 'Approval creation',
                message: message,
                type: type,
                duration: 15000,
            },
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

    updateNonLayoutFields(approvalNonLayoutFieldValues, detailGuid) {
        if (approvalNonLayoutFieldValues) {
            for (let fieldName in approvalNonLayoutFieldValues) {
                const guid = this.generateGuid();
                const name = fieldName;
                const value = approvalNonLayoutFieldValues[fieldName];

                window.app.addApprovalFieldData(detailGuid, {
                    id: guid,
                    name: name,
                    value: value,
                    isValid: true
                });
            }
        }
    }

    onFieldClick(event) {
        let tabNum;
        Object.keys(window.app.approvals).forEach(approvalId => {
            if (
                Object.keys(window.app.approvals[approvalId].fields)
                    .find(fieldId => fieldId === event.target.dataset.id)
            ) {
                this.setActiveLayout(approvalId);
                tabNum = Object.keys(window.app.approvals).indexOf(approvalId);
            }
        });
        const fieldId = event.target.dataset.id;
        setTimeout(() => {
            this.template.querySelectorAll("c-av-create-layout")[tabNum].cScrollTo(fieldId)
        }, 0);
    }

    isSingleApproval(approvalDetails) {
        return approvalDetails.length === 1;
    }

    generateGuid() {
        return String(new Date().getTime() + Math.random());
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