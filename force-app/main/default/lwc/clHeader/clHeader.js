/* globals CL */
import {LightningElement, api, track, wire} from "lwc";
import {clAppReady} from "c/clService";
import Brand from '@salesforce/label/c.clHeaderBrand';
import RecordType from '@salesforce/label/c.clHeaderRecordType';
import ConvertLead from '@salesforce/label/c.clHeaderConvertLead';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import CASE_OBJECT from '@salesforce/schema/Case';

const DOS_RECORD_TYPE_NAME = 'Deal and Order Support';

export default class ClHeader extends LightningElement {
    @track leadName;
    @track leadRecordType;
    @track leadBrand;
    @track leadUrl;
    @track leadPhotoUrl;
    @track objectInfo;
    @track isLoading = false;
    @track isLoaded = false;
    @track label = {
        Brand,
        ConvertLead,
        RecordType
    };
    @track leadId;
    @track oppId;
    @track accId;
    @api isPrmFlow = false;

    connectedCallback() {
        clAppReady(this.onClAppReady.bind(this));

        window.addEventListener('getSelectedAccount', event => {this.accId = event.detail});
        window.addEventListener('getSelectedOpportunity', event => {this.oppId = event.detail});
    }

    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    objectInfo;

    get dOSRecordTypeId() {
        const recordTypeInfos = this.objectInfo.data.recordTypeInfos;
        return Object.keys(recordTypeInfos).find(recordType => recordTypeInfos[recordType].name === DOS_RECORD_TYPE_NAME);
    }

    onClAppReady() {
        CL.app.rx.lead.subscribe(lead => {
            this.leadName = lead && lead.name;
            this.leadRecordType = lead && lead.recordType;
            this.leadBrand = lead && lead.brand;
            this.leadUrl = lead && lead.url;
            this.leadPhotoUrl = lead && lead.photoUrl;
            this.leadId = lead && lead.id;
        });
        CL.app.rx.loadingStatus.subscribe(loadingStatus => {
            this.isLoading = loadingStatus.isLeadLoading;
            this.isLoaded = loadingStatus.isLeadLoaded;
        });
    }

    openCreateCase() {
        const isPrmPortal = window.location.href.includes('RCPartnerProgram');
        if (isPrmPortal) {
            let defaultFieldValues = {};
            defaultFieldValues.AccountId = CL.app.accId;
            defaultFieldValues.Opportunity_Reference__c = CL.app.oppId;
            defaultFieldValues.Lead__c = CL.app.leadId;
            defaultFieldValues.Case_Category__c = 'Ignite Partner';
            defaultFieldValues.Origin = 'Lead';
            defaultFieldValues.RecordTypeId = this.dOSRecordTypeId;
            let encodedData = btoa(JSON.stringify(defaultFieldValues));

            const baseURL = window.location.origin + "/RCPartnerProgram/s/partner-create-case?encodedData=" + encodedData;
            window.open(baseURL, '_blank');
        } else {
            let caseMap = new Map();
            caseMap.set('Case_Category__c', 'System Issue');
            caseMap.set('Lead__c', CL.app.leadId);
            caseMap.set('Origin', 'Lead');
            caseMap.set('Case_Subcategory__c', 'Lead Convert');

            let encodedString = this.getDefaultFieldValueString(caseMap);
            window.open('/apex/CaseCreationRedirect?mapParam=' + encodedString);
        }
    }

    getDefaultFieldValueString(defaultFieldValuesMap) {
        return encodeURIComponent(Array.from(defaultFieldValuesMap.keys()).reduce((result, key) => {
            return `${result}${key}=${defaultFieldValuesMap.get(key)},`
        }, ''));
    }
}