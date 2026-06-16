import { LightningElement, track, api, wire } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import { getRecord } from 'lightning/uiRecordApi';

import ID_FIELD from '@salesforce/schema/Survey__c.Id';
import LIKELY_TO_RECOMMEND_FIELD from '@salesforce/schema/Survey__c.LikelyToRecommend_IT__c';
import COMMENTS_FIELD from '@salesforce/schema/Survey__c.Comments_ITHelpdesk__c';
import RESPONDED_FIELD from '@salesforce/schema/Survey__c.Responded__c';
import SURVEY_TYPE_FIELD from '@salesforce/schema/Survey__c.SurveyType__c';
import RESPONSE_DATE_FIELD from '@salesforce/schema/Survey__c.Response_Date__c';

import SMILEY_NEG from '@salesforce/resourceUrl/Smiley1';
import SMILEY_POS from '@salesforce/resourceUrl/Smiley5';
import RING_IT_LOGO from '@salesforce/resourceUrl/RingItLogo';

const FIELDS = [LIKELY_TO_RECOMMEND_FIELD, COMMENTS_FIELD, RESPONDED_FIELD, SURVEY_TYPE_FIELD, RESPONSE_DATE_FIELD];
const SURVEY_TYPES_FOR_IT_TO_SEND_SURVEYS = [
    'IT Helpdesk CSAT'.toLowerCase(),
    'IT Deskside Support'.toLowerCase(),
    'IT Infrastructure'.toLowerCase(),
    'BizServ CRM'.toLowerCase()
];

export default class ItCsatSurveyNew extends LightningElement {
    @track radioValue = '';
    @track radioStyle = 'radio-group';

    @track commentsValue = '';

    @track isSurveyCompleted;
    @track isHasError;

    @api surveyId = new URL(window.location.href).searchParams.get('id');

    @track record;

    @track errorMessage = '';
    surveyCompletedMessage = 'Thank you for filling out our survey';

    negativeSmiley = SMILEY_NEG;
    positiveSmiley = SMILEY_POS;
    ringItLogo = RING_IT_LOGO;

    @wire(getRecord, { recordId: '$surveyId', fields: FIELDS })
    wiredSurvey({ error, data }) {
        if (data) {
            this.invalidSurveyType = !(data.fields.SurveyType__c.value
                && SURVEY_TYPES_FOR_IT_TO_SEND_SURVEYS.includes(data.fields.SurveyType__c.value.toLowerCase()));
            if (this.invalidSurveyType) {
                this.isHasError = true;
                this.errorMessage = 'Invalid Survey Type';
                return;
            }

            this.surveyAlreadyCompleted = data.fields.Responded__c.value == 1;
            if (this.surveyAlreadyCompleted) {
                this.isHasError = true;
                this.errorMessage = 'You have already filled this survey';
                return;
            }

            this.record = data;

        } else if (error) {
            this.record = null;
            this.isHasError = true;
            this.errorMessage = 'Incorrect Survey ID';

        } else if (!this.surveyId) {
            this.isHasError = true;
            this.errorMessage = 'Please provide Survey ID';
        }
    }

    get options() {
        return [
            { label: '0', value: '0', },
            { label: '1', value: '1', },
            { label: '2', value: '2', },
            { label: '3', value: '3', },
            { label: '4', value: '4', },
            { label: '5', value: '5', },
            { label: '6', value: '6', },
            { label: '7', value: '7', },
            { label: '8', value: '8', },
            { label: '9', value: '9', },
            { label: '10', value: '10' },
        ];
    }

    get isSurveyLoaded() {
        return this.isSurveyCompleted !== undefined || this.isHasError !== undefined || this.record !== undefined;
    }

    get isSurveyIdCorrect() {
        return this.surveyId != null && this.record !== null;
    }

    saveForm() {
        if (this.validateForm()) {
            // update record
            const fields = {};
            fields[ID_FIELD.fieldApiName] = this.surveyId;
            fields[LIKELY_TO_RECOMMEND_FIELD.fieldApiName] = this.radioValue;
            fields[COMMENTS_FIELD.fieldApiName] = this.commentsValue;
            fields[RESPONSE_DATE_FIELD.fieldApiName] = this.currentDate();
            fields[RESPONDED_FIELD.fieldApiName] = 1;

            updateRecord({ fields })
                .catch(error => {
                    this.isHasError = true;
                    this.errorMessage = 'Error saving survey results';
                });

            this.isSurveyCompleted = true;
        }
    }

    validateForm() {
        if (this.radioValue === '') {
            this.radioStyle = 'radio-group radio-has-error';
            return false;
        } else {
            this.radioStyle = 'radio-group';
            return true;
        }
    }

    currentDate() {
        var now = new Date();

        const yyyy = now.getFullYear().toString();
        const mm = this.formatWithZero(now.getMonth() + 1);
        const dd = this.formatWithZero(now.getDate());
        const hh = this.formatWithZero(now.getHours());
        const mins = this.formatWithZero(now.getMinutes());
        const secs = this.formatWithZero(now.getSeconds());
        const tail = '000+0000';

        return yyyy + '-' + mm + '-' + dd + 'T' + hh + ':' + mins + ':' + secs + '.' + tail; // Example: 2019-11-08T13:52:32.000+0000
    }

    formatWithZero(number) {
        return (number < 10 ? '0' : '') + number.toString();
    }

    handleRadioChange(evt) {
        this.radioValue = evt.detail.value;
        this.validateForm();
    }

    handleCommentsChange(evt) {
        this.commentsValue = evt.detail.value;
    }
}