import { LightningElement, wire, track, api } from "lwc";
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import IN_CONTRACT from "@salesforce/schema/Lead_Qualification__c.In_Contract__c";
import CONTRACTEXPIRESINFO from "@salesforce/schema/Lead_Qualification__c.ContractExpiresInfo__c";
import NEWTIMEFRAME from "@salesforce/schema/Lead_Qualification__c.NewTimeFrame__c";
import NEWSOLUTIONTIMEFRAME from "@salesforce/schema/Lead_Qualification__c.NewSolutionUpTimeFrame__c";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import LEAD_QUALIFICATION_OBJECT from "@salesforce/schema/Lead_Qualification__c";
import Id from "@salesforce/user/Id";
import getUserInfo from "@salesforce/apex/SmartSearchForLwc.getUserInfo";
import getSalesAgentProfileId from "@salesforce/apex/SmartSearchForLwc.getSalesAgentProfileId";
import getSalesManagerProfileId from "@salesforce/apex/SmartSearchForLwc.getSalesManagerProfileId";

export default class SmartSearchLeadQualification extends LightningElement {
    @track inContractValues = [];
    @track contractExpiresInfoValues = []; 
    @track newTimeframeValues = [];
    @track newSolutionTimeframeValues = [];
    @track disableContractExpires = true;

    @track textAreaValues = {
        currentSituation: '' ,
        problems: '' ,
        impact: '' ,
        idealSituation: '' ,
        nextSteps: '' ,
        benefits: '' ,
        decisionMaking: '' ,
        competitiveLandscape: '',
        relationshipBuildingExtras: '',
        coachingNotes: '',
        contractAdditionalInfo: '',
        decMakersAdditionalInfo: '',
        timeframeAdditionalInfo: '',
        qualConvCheckbox: false
    };

    @track comboValues = {
        leadQualTimeframe: '',
        leadQualNewSolutionUpTimeframe: '',
        leadQualContract: '',
        leadQualContractExpires: '',
    };

    @track
    asterisks = {
        currentSituation: "",
        problems: "",
        decisionMaking: "",
        nextSteps: "",
    };

    @wire(getSalesManagerProfileId)
    salesManagerProfileId;

    @wire(getSalesAgentProfileId)
    salesAgentProfileId;

    @wire(getUserInfo, { userId: Id })
    userData({ error, data }) {
        if (data) {
            if (data.ProfileId === this.salesManagerProfileId.data) {
                let newAsterisks = {
                    currentSituation: "(*) ",
                    problems: "(*) ",
                    decisionMaking: "(*) ",
                    nextSteps: "(*) ",
                };
                this.asterisks = newAsterisks;
            } else if (data.ProfileId === this.salesAgentProfileId.data) {
                let newAsterisks = {
                    currentSituation: "",
                    problems: "",
                    decisionMaking: "",
                    nextSteps: "(*) ",
                };
                this.asterisks = newAsterisks;
            }
        } else if (error) {
            console.log(error);
        }
    }

    @wire(getObjectInfo, { objectApiName: LEAD_QUALIFICATION_OBJECT })
    leadQualificationInfo;

    @wire(getPicklistValues, {
        recordTypeId: "$leadQualificationInfo.data.defaultRecordTypeId",
        fieldApiName: IN_CONTRACT,
    })
    getInContractValues(result) {
        if (result.data) {
            this.inContractValues = [{ label: "--None--", value: "", selected: true }, ...result.data.values];
        } else if (result.error) {
            this.error = result.error;
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: "$leadQualificationInfo.data.defaultRecordTypeId",
        fieldApiName: CONTRACTEXPIRESINFO,
    })
    getContractExpiresInfoValues(result) {
        if (result.data) {
            this.contractExpiresInfoValues = [{ label: "--None--", value: "", selected: true }, ...result.data.values];
        } else if (result.error) {
            this.error = result.error;
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: "$leadQualificationInfo.data.defaultRecordTypeId",
        fieldApiName: NEWTIMEFRAME,
    })
    getNewTimeframeValues(result) {
        if (result.data) {
            this.newTimeframeValues = [{ label: "--None--", value: "", selected: true }, ...result.data.values];
        } else if (result.error) {
            this.error = result.error;
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: "$leadQualificationInfo.data.defaultRecordTypeId",
        fieldApiName: NEWSOLUTIONTIMEFRAME,
    })
    getNewSolutionTimeframeValues(result) {
        if (result.data) {
            this.newSolutionTimeframeValues = [{ label: "--None--", value: "", selected: true }, ...result.data.values];
        } else if (result.error) {
            this.error = result.error;
        }
    }

    leadQualificationObj = {
        QualityConversation__c : false
    };
    showSection = false;
    icon = "utility:right";

    showLeadQualificationSection() {
        this.showSection = !this.showSection;
        if (this.showSection) {
            this.icon = "utility:down";
        } else {
            this.icon = "utility:right";
        }
    }

    handleInContractValuesChange(event) {
        this.comboValues[event.target.name] = event.target.value
        if (event.detail.value === "Yes") {
            this.disableContractExpires = false;
        } else {
            this.disableContractExpires = true;
            this.template.querySelector('.change-value').value = '--None--';
        }
    }

    handleComboBoxChange(event) {
        this.comboValues[event.target.name] = event.target.value
    }

    handleInputChange(event) {
        this.textAreaValues[event.target.name] = event.target.value;
    }

    handleKeyPress(event) {
        if (event.keyCode === 13){
            event.stopPropagation();
        }
    }

    handleCheckBoxChange(event) {
        this.textAreaValues.qualConvCheckbox = event.target.checked;
    }

    @api
    getLeadQualificationObj(){
        this.leadQualificationObj.Current_Situation__c = this.textAreaValues.currentSituation;
        this.leadQualificationObj.Benefits__c = this.textAreaValues.benefits;
        this.leadQualificationObj.Problems__c = this.textAreaValues.problems;
        this.leadQualificationObj.Decision_Making_Process__c = this.textAreaValues.decisionMaking;
        this.leadQualificationObj.Impact__c = this.textAreaValues.impact;
        this.leadQualificationObj.Competitive_Landscape__c = this.textAreaValues.competitiveLandscape;
        this.leadQualificationObj.Ideal_Situation__c = this.textAreaValues.idealSituation;
        this.leadQualificationObj.Relationship_Building_Extras__c = this.textAreaValues.relationshipBuildingExtras;
        this.leadQualificationObj.NextSteps__c = this.textAreaValues.nextSteps;
        this.leadQualificationObj.CoachingNotes__c = this.textAreaValues.coachingNotes;
        this.leadQualificationObj.In_Contract__c = this.comboValues.leadQualContract;
        this.leadQualificationObj.ContractExpiresInfo__c = this.comboValues.leadQualContractExpires;
        this.leadQualificationObj.ContractAdditionalInfo__c = this.textAreaValues.contractAdditionalInfo;
        this.leadQualificationObj.Decision_makers_Additional_Information__c = this.textAreaValues.decMakersAdditionalInfo;
        this.leadQualificationObj.NewTimeFrame__c = this.comboValues.leadQualTimeframe;
        this.leadQualificationObj.NewSolutionUpTimeFrame__c = this.comboValues.leadQualNewSolutionUpTimeframe;
        this.leadQualificationObj.TimeframeAdditionalInfo__c = this.textAreaValues.timeframeAdditionalInfo;
        this.leadQualificationObj.QualityConversation__c = this.textAreaValues.qualConvCheckbox;
        return this.leadQualificationObj;
    }

}