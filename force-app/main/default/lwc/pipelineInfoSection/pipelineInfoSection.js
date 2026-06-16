import { LightningElement, api, wire, track  } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { updateRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import getPipelineWrapper from "@salesforce/apex/PipelineInfoController.getPipelineInfo";
import OPPORTUNITY_OBJECT from '@salesforce/schema/Opportunity';
import FORECASTED_OFFICE_USERS from '@salesforce/schema/Opportunity.Forecasted_Users__c';
import FORECASTED_GLOBAL_OFFICE_USERS from '@salesforce/schema/Opportunity.Forecasted_Global_Office_Users__c';
import FORECASTED_CONTACT_CENTER_USERS from '@salesforce/schema/Opportunity.Forecast_Contact_Center_Users__c';
import FORECASTED_RC_VIDEO_USERS from '@salesforce/schema/Opportunity.Forecasted_RingCentral_Video_Users__c';
import FORECASTED_ENGAGE_DIGITAL_USERS from '@salesforce/schema/Opportunity.ForcastedDimeloUsers__c';
import FORECASTED_EVENT_USERS from '@salesforce/schema/Opportunity.Forecasted_Events_Users__c';
import FORECASTED_ENGAGE_VOICE_USERS from '@salesforce/schema/Opportunity.Forecast_Connect_First_Users__c';
import ESTIMATED_ARR from '@salesforce/schema/Opportunity.Estimated_12M_Total_Pipeline__c';
import ESTIMATED_12M_CX from '@salesforce/schema/Opportunity.Estimated_12M_Engagement_Pipeline__c';
import ESTIMATED_HARDWARE from '@salesforce/schema/Opportunity.Estimated_Hardware__c';
import ESTIMATED_OFFICE from '@salesforce/schema/Opportunity.Estimated_12M_Office_Pipeline__c';
import ESTIMATED_CONTACT_CENTER from '@salesforce/schema/Opportunity.Estimated_12M_Contact_Center_Pipeline__c';
import ESTIMATED_GLOBAL_OFFICE from '@salesforce/schema/Opportunity.Estimated_12M_Global_Office_Pipeline__c';
import ESTIMATED_ENGAGE_DIGITAL from '@salesforce/schema/Opportunity.Estimated_12M_Engage_Digital_Pipeline__c';
import ESTIMATED_EVENTS  from '@salesforce/schema/Opportunity.Estimated_12M_RC_Events_Pipeline__c';
import ESTIMATED_ENGAGE_VOICE from '@salesforce/schema/Opportunity.Estimated_12M_Engage_Voice_Pipeline__c';
import ESTIMATED_RC_VIDEO from '@salesforce/schema/Opportunity.Estimated_12M_RingCentral_Video_Pipeline__c';
import CALCULATED_ARR from '@salesforce/schema/Opportunity.Calculated_12M_Total_Pipeline__c';
import ESTIMATED_ONE_TIME from '@salesforce/schema/Opportunity.Estimated_One_Time_Pipeline__c';
import ESTIMATED_PRO_SERV from '@salesforce/schema/Opportunity.EstimatedProfessionalServices12Month__c';
import CALCULATED_MRR from '@salesforce/schema/Opportunity.Calculated_Total_MRR__c';
import ESTIMATED_CX_MRR from '@salesforce/schema/Opportunity.Estimated_CX_MRR__c';
import ESTIMATED_MRR from '@salesforce/schema/Opportunity.Estimated_Total_MRR__c';
import SOURCE_CONTACT_CENTER from '@salesforce/schema/Opportunity.Source_For_Contact_Center_Pipeline__c';
import SOURCE_ENGAGE_DIGITAL from '@salesforce/schema/Opportunity.Source_For_Engage_Digital_Pipeline__c';
import SOURCE_RC_EVENT from '@salesforce/schema/Opportunity.Source_for_RC_Event_Pipeline__c';
import SOURCE_ENGAGE_VOICE from '@salesforce/schema/Opportunity.Source_For_Engage_Voice_Pipeline__c';
import SOURCE_GLOBAL_OFFICE from '@salesforce/schema/Opportunity.Source_For_Global_Office_Pipeline__c';
import SOURCE_HARDWARE from '@salesforce/schema/Opportunity.Source_For_Hardware_Pipeline__c';
import SOURCE_OFFICE from '@salesforce/schema/Opportunity.Source_For_Office_Pipeline__c';
import SOURCE_ONE_TIME from '@salesforce/schema/Opportunity.Source_For_One_Time_Pipeline__c';
import SOURCE_PRO_SERV from '@salesforce/schema/Opportunity.Source_For_ProServ_Pipeline__c';
import SOURCE_RC_VIDEO from '@salesforce/schema/Opportunity.Source_For_RingCentral_Video_Pipeline__c';
import SOURCE_TOTAL from '@salesforce/schema/Opportunity.Source_For_Total_Pipeline__c';
import AVISO_FORECAST_VALUE from '@salesforce/schema/Opportunity.Seller_Forecast_Value__c';

const LAYOUT_FIELDS = [FORECASTED_OFFICE_USERS, ESTIMATED_OFFICE, FORECASTED_CONTACT_CENTER_USERS, ESTIMATED_CONTACT_CENTER,
    FORECASTED_GLOBAL_OFFICE_USERS, ESTIMATED_GLOBAL_OFFICE, FORECASTED_ENGAGE_DIGITAL_USERS, ESTIMATED_ENGAGE_DIGITAL,
    FORECASTED_ENGAGE_VOICE_USERS, ESTIMATED_ENGAGE_VOICE, FORECASTED_RC_VIDEO_USERS, ESTIMATED_RC_VIDEO,FORECASTED_EVENT_USERS,ESTIMATED_EVENTS,
    ESTIMATED_ARR, CALCULATED_ARR, SOURCE_TOTAL, ESTIMATED_12M_CX,  ESTIMATED_ONE_TIME, ESTIMATED_HARDWARE, ESTIMATED_PRO_SERV,
    ESTIMATED_CX_MRR, ESTIMATED_MRR, CALCULATED_MRR, AVISO_FORECAST_VALUE];

const TYPE_CURRENCY = 'Currency';
const OVERRIDDEN = 'Overridden';
const WEAK_OVERRIDDEN = 'Weak Overridden';
const OVERRIDDEN_HELP_TEXT = 'Overridden until stage 5';
const WEAK_OVERRIDDEN_HELP_TEXT = 'Overridden until stage 2';
const USERS_NOT_FROM_QUOTES = 'Quotes don\'t contain this type of Users';
const VALID_STAGES = ['3. Solution', '4. Proof', '5. Agreement', '6. Order', '7. Closed Won'];

export default class PipelineInfoSection extends LightningElement {

    fields;
    editMode = false;
    oppToUpdate = {};
    isSpinnerShown;
    spinnerText = '';
    wiredPipelineInfo;
    forecastedUsersByQuotes;
    sourceValues;
    recordValues;
    convertedValues;
    currencyIsoCode;
    stageName;
    quoteUsers;
    error;
    showPopover = false;
    pinPopover = false;
    popoverClass;

    forecastedUsers = new Map([
        [FORECASTED_OFFICE_USERS.fieldApiName, 'officeUsers'],
        [FORECASTED_CONTACT_CENTER_USERS.fieldApiName, 'contactCenterUsers'],
        [FORECASTED_GLOBAL_OFFICE_USERS.fieldApiName, 'globalOfficeUsers'],
        [FORECASTED_ENGAGE_DIGITAL_USERS.fieldApiName, 'engageDigitalUsers'],
        [FORECASTED_ENGAGE_VOICE_USERS.fieldApiName, 'engageVoiceUsers'],
        [FORECASTED_RC_VIDEO_USERS.fieldApiName, 'ringCentralVideoUsers'],
        [FORECASTED_EVENT_USERS.fieldApiName, 'forecastedEventUsers']
        
    ]);

    estimatedToSourceMap = new Map([
        [ESTIMATED_ARR.fieldApiName, SOURCE_TOTAL.fieldApiName],
        [ESTIMATED_HARDWARE.fieldApiName, SOURCE_HARDWARE.fieldApiName],
        [ESTIMATED_OFFICE.fieldApiName, SOURCE_OFFICE.fieldApiName],
        [ESTIMATED_CONTACT_CENTER.fieldApiName, SOURCE_CONTACT_CENTER.fieldApiName],
        [ESTIMATED_GLOBAL_OFFICE.fieldApiName, SOURCE_GLOBAL_OFFICE.fieldApiName],
        [ESTIMATED_ENGAGE_DIGITAL.fieldApiName, SOURCE_ENGAGE_DIGITAL.fieldApiName],
        [ESTIMATED_ENGAGE_VOICE.fieldApiName, SOURCE_ENGAGE_VOICE.fieldApiName],
        [ESTIMATED_RC_VIDEO.fieldApiName, SOURCE_RC_VIDEO.fieldApiName],
        [ESTIMATED_ONE_TIME.fieldApiName, SOURCE_ONE_TIME.fieldApiName],
        [ESTIMATED_PRO_SERV.fieldApiName, SOURCE_PRO_SERV.fieldApiName],
        [ESTIMATED_MRR.fieldApiName, SOURCE_TOTAL.fieldApiName],
        [ESTIMATED_EVENTS.fieldApiName,SOURCE_RC_EVENT.fieldApiName],
        
    ]);

    @api recordId;
    @api isVFpage;

    @wire(getObjectInfo, { objectApiName: OPPORTUNITY_OBJECT })
    oppInfo;

    @wire(getPipelineWrapper, { oppId: '$recordId' })
    getWrapper(result) {
        this.showSpinner();
        this.wiredPipelineInfo = result;
        if(result.data) {
            this.sourceValues = result.data.sourceFields;
            this.recordValues = result.data.recordFields;
            this.convertedValues = result.data.convertedEstimatedFields;
            this.currencyIsoCode = result.data.currencyIsoCode;
            this.stageName = result.data.stageName;
            this.quoteUsers = result.data.quoteUsers;
            this.hideSpinner();
        }
    }

    get showInfo(){
        if (this.oppInfo.data && this.wiredPipelineInfo.data) {
            return true;
        }
        return false;
    }

    get rowClass() {
        return this.viewMode ? 'slds-col slds-p-top_small slds-size_1-of-2 slds-align-bottom slds-has-flexi-truncate'
                            : 'slds-col slds-size_1-of-2 slds-align-bottom slds-has-flexi-truncate';
    }

    get sectionClass() {
        return this.isVFpage ? 'slds-grid slds-wrap slds-gutters_small info-section'
                            : 'slds-grid slds-wrap slds-gutters_small';
    }

    get mainClass() {
        return this.isVFpage ? 'slds-is-relative'
                            : 'slds-is-relative slds-p-around_small';
    }

    get viewMode() {
        return !this.editMode;
    }

    get oppFields() {
        this.fields = [];
        let opportunityInfo = this.oppInfo.data.fields;

        LAYOUT_FIELDS.forEach(item => {
            if (!opportunityInfo[item.fieldApiName]) {
                return;
            }

            let overridenHelpText;
            let forecastedHelpText;
            let fieldValue = this.recordValues[item.fieldApiName];
            if (this.estimatedToSourceMap.has(item.fieldApiName)) {
                if (this.sourceValues[this.estimatedToSourceMap.get(item.fieldApiName)] === OVERRIDDEN) {
                    overridenHelpText = OVERRIDDEN_HELP_TEXT;
                }
                if (this.sourceValues[this.estimatedToSourceMap.get(item.fieldApiName)] === WEAK_OVERRIDDEN) {
                    overridenHelpText = WEAK_OVERRIDDEN_HELP_TEXT;
                }
            }

            if (this.forecastedUsers.has(item.fieldApiName)
                && !this.quoteUsers.hasOwnProperty(this.forecastedUsers.get(item.fieldApiName))
                && VALID_STAGES.includes(this.stageName)) {
                forecastedHelpText = USERS_NOT_FROM_QUOTES;
            }
            if(item.fieldApiName == SOURCE_TOTAL.fieldApiName){
                fieldValue = this.sourceValues[item.fieldApiName];
            }

            this.fields.push({
                key: opportunityInfo[item.fieldApiName].apiName,
                value: fieldValue,
                convertedValue: this.convertedValues['Converted_' + item.fieldApiName],
                label: opportunityInfo[item.fieldApiName].label,
                helpText: opportunityInfo[item.fieldApiName].inlineHelpText,
                updateable: opportunityInfo[item.fieldApiName].updateable,
                type: opportunityInfo[item.fieldApiName].dataType,
                isCurrencyType: opportunityInfo[item.fieldApiName].dataType === TYPE_CURRENCY,
                overriddenText: overridenHelpText,
                usersHelpText: forecastedHelpText,
                totalSource: opportunityInfo[item.fieldApiName].apiName === SOURCE_TOTAL.fieldApiName
            })
        });

        return this.fields;
    }

    showSpinner() {
        this.isSpinnerShown = true;
    }

    hideSpinner() {
        this.isSpinnerShown = false;
    }

    handleInputChange(event) {
        let apiName = event.target.dataset.apiName;
        let value = event.detail.value;
        this.setIfMrrOrArrTotalChanged(apiName, value);
        this.oppToUpdate[apiName] = value;
    }

    setIfMrrOrArrTotalChanged(apiName, value) {
        let totalInputToChange;
        let newValue;
        if (apiName === ESTIMATED_MRR.fieldApiName) {
            totalInputToChange = this.template.querySelector(`[data-api-name="${ESTIMATED_ARR.fieldApiName}"]`);
            newValue = value * 12;
        } else if (apiName === ESTIMATED_ARR.fieldApiName) {
            totalInputToChange = this.template.querySelector(`[data-api-name="${ESTIMATED_MRR.fieldApiName}"]`);
            newValue = value / 12 
        }
        if (!totalInputToChange) return;

        totalInputToChange.value = parseFloat(newValue).toFixed(2);
        this.oppToUpdate[totalInputToChange.dataset.apiName] = parseFloat(totalInputToChange.value);
    }

    handleEditClick(event) {
        this.editMode = true;
        this.oppToUpdate = {};
    }

    handleCancelClick(event) {
        this.editMode = false;
        this.error = '';
    }

    handlePopoverClose() {
        this.showPopover = false;
    }

    handlePopoverShow() {
        let saveButton = this.template.querySelector(".save-button");
        this.popoverClass = "position: absolute; top: " + (saveButton.offsetTop - 140) + "px;";
        this.showPopover = true;
    }

    handleSaveClick(event) {
        this.oppToUpdate['Id'] = this.recordId;
        let fields = this.oppToUpdate;

        const recordToUpdate = { fields };
        this.showSpinner();
        updateRecord(recordToUpdate)
            .then(() => {
                // Display fresh data in the form
                return this.refresh();
            })
            .catch(error => {
                this.error = error.body.output.errors[0].message;
                this.handlePopoverShow();
            })
            .finally(() => {
                this.hideSpinner();
            });
    }

    async refresh() {
        this.editMode = false;
        await refreshApex(this.wiredPipelineInfo);
    }
}