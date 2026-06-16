// apexContactsForAccount.js
import { LightningElement, api, wire } from "lwc";
import getRelatedDFRs from "@salesforce/apex/DemandFunnelComponentController.getRelatedDFRs";
import { refreshApex } from "@salesforce/apex";
import { NavigationMixin } from "lightning/navigation";
import PROFILE_NAME_FIELD from "@salesforce/schema/User.Profile.Name";
import strUserId from "@salesforce/user/Id";
import { getRecord } from "lightning/uiRecordApi";
const hostname = window.location.hostname;
const COLS = [
    {
        label: "DFR",
        fieldName: "linkName",
        type: "url",
        typeAttributes: {
            label: {
                fieldName: "Name",
            },
            target: "_blank",
        },
        hideDefaultActions: "true",
    },
    {
        label: "Created Date",
        fieldName: "DET_DFR_Created_Date__c",
        hideDefaultActions: "true",
    },
    {
        label: "DFR Status",
        fieldName: "DET_DFR_Status__c",
        hideDefaultActions: "true",
    },
    {
        label: "Current Funnel Status",
        fieldName: "DET_Current_Funnel_Status__c",
        hideDefaultActions: "true",
    },
];

const MARKETING_COLS = [
    {
        label: "DFR",
        fieldName: "linkName",
        type: "url",
        typeAttributes: {
            label: {
                fieldName: "Name",
            },
            target: "_blank",
        },
        hideDefaultActions: "true",
    },
    {
        label: "Created Date",
        fieldName: "DET_DFR_Created_Date__c",
        hideDefaultActions: "true",
    },
    {
        label: "DFR Status",
        fieldName: "DFR_Active_Status__c",
        hideDefaultActions: "true",
    },
    {
        label: "Current Funnel Status",
        fieldName: "DET_Current_Funnel_Status__c",
        hideDefaultActions: "true",
    },
    {
        label: "Current Sub-Status",
        fieldName: "DET_Current_Sub_Status__c",
        hideDefaultActions: "true",
    },
    {
        label: "Contact",
        fieldName: "Contact__c",
        hideDefaultActions: "true",
    },
    {
        label: "Account",
        fieldName: "Account__c",
        hideDefaultActions: "true",
    },
    {
        label: "Opportunity",
        fieldName: "Opportunity__c",
        hideDefaultActions: "true",
    },
];
const objectRelationship = {
    Contact: "DFR_Contact__r",
    Opportunity: "DFR_Opportunity__r",
    Lead: "DFR_Lead__r",
};

export default class demmandFunnelComponent extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;
    @api rowActionHandler;
    profileName;
    columns;
    @wire(getRelatedDFRs, { objectId: "$recordId" })
    dfrs;
    isLoading = true;
    @wire(getRecord, {
        recordId: strUserId,
        fields: [PROFILE_NAME_FIELD],
    })
    wireuser({ error, data }) {
        if (error) {
            this.error = error;
        } else if (data) {
            this.profileName = data.fields.Profile.value.fields.Name.value;
            this.columns = this.getColumnsBasedOnProfile;
        }
    }

    get dfrsAvailable() {
        return this.dfrs.length > 0;
    }
    get getTotalDFR() {
        return this.dfrs.length;
    }
    get getCurrentObjectRelationship() {
        return objectRelationship[this.objectApiName];
    }

    get getColumnsBasedOnProfile() {
        return this.profileName.includes("Marketing") || this.profileName.includes("System Administrator")
            ? MARKETING_COLS
            : COLS;
    }

    connectedCallback() {
        let that = this;
        let intervalID = setInterval(function () {
            that.loadDFRs();
        }, 10000);
    }

    loadDFRs() {
        let that = this;
        getRelatedDFRs({ objectId: that.recordId })
            .then((result) => {
                result.forEach((record) => {
                    record.linkName = `https://${hostname}/${record.Id}`;
                });
                that.dfrs = result;
                refreshApex();
                this.isLoading = false;
            })
            .catch((error) => {
                console.log(error);
            });
        console.log(this.getColumnsBasedOnProfile);
    }

    handleGotoRelatedList() {
        this[NavigationMixin.Navigate]({
            type: "standard__recordRelationshipPage",
            attributes: {
                recordId: this.recordId,
                relationshipApiName: this.getCurrentObjectRelationship,
                actionName: "view",
                objectApiName: this.objectApiName,
            },
        });
    }
}