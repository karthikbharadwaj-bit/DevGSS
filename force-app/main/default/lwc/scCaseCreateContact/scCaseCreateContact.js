import { track, wire, api } from "lwc";
import BaseService from "c/lwcBaseService";
import getContactInfo from "@salesforce/apex/SupportCommunityNewCase.getContactInfo";
import { labels } from "c/scCaseCreateLabels";
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import CASE_OBJECT from "@salesforce/schema/Case";
import TIMEZONE_FIELD from "@salesforce/schema/Case.Timezone__c";

export default class ScCaseCreateContact extends BaseService {
    @api title = "Contact information";
    labels = labels;
    eventsName = {
        toast: "ShowToastEvent",
        validate: "SCCaseCreateValidateContact",
        info: "SCCaseCreateInfo",
    };
    contactId;
    maxValueSize = 28;
    @track isCorrect;
    @track isCorrectPhone = true;
    @track phone;
    @track extension;
    @track addTimezone;
    @track email;
    @track firstName;
    @track lastName;
    @track callbackPhone;
    @track callbackExtension;
    @track loading = true;
    @track timezone;

    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    getobjectInfo(result) {
        if (result.data) {
            const rtis = result.data.recordTypeInfos;
            this.recordTypeId = Object.keys(rtis).find((rti) => rtis[rti].name === 'Support-Case');
        }
    }

    @wire(getPicklistValues, { recordTypeId: '01280000000UIfJAAW', fieldApiName: TIMEZONE_FIELD})
    TimezonePicklistValues;

    get isIncorrect() {
        return this.isCorrect === false;
    }
    get options() {
        return [{ label: this.labels.yes, value: true }, { label: this.labels.no, value: false }];
    }
    get isLongEmail() {
        return this.email ? this.email.length > this.maxValueSize : false;
    }
    get cbPhone() {
        return this.callbackPhone || this.phone;
    }
    get timezone() {
        return this.timezone || this.timezone;
    }
    get cbPhoneExt() {
        return this.callbackExtension || this.extension;
    }
    get cbFullPhone() {
        return this.callbackPhone
            ? this.callbackPhone + (this.callbackExtension ? ` ext.${this.callbackExtension}` : "")
            : "";
    }
    get summaryInfo() {
        return {
            firstName: this.firstName,
            lastName: this.lastName,
            contactId: this.contactId,
            email: this.email,
            phone: this.phone,
            extension: this.extension,
            callbackPhone: this.cbFullPhone,
            timezone: this.timezone,
        };
    }
    handleChangeTimezone(event) {
        this.timezone = event.detail.value;
    }
    callbackPhoneIsCorrectChange(evt) {
        this.isCorrectPhone = evt.target.checked;
    }
    copyEmail() {
        const copyTextarea = this.template.querySelector(".sc-case-contact__email-input");
        copyTextarea.focus();
        copyTextarea.select();
        try {
            const successful = document.execCommand("copy");
            if (successful) {
                BaseService.showToast("info", this.labels.copySuccessful);
            } else {
                throw new Error(this.labels.copyNotSupport);
            }
        } catch (error) {
            console.warn(error);
            BaseService.errorToast(error);
        }
    }
    isCorrectChange(evt) {
        this.isCorrect = evt.detail.value === "true";
    }
    handleInfoChange(evt) {
        const name = evt.target.name;
        if (evt.target.checkValidity()) {
            this[name] = evt.detail.value;
        }
    }

    checkContact() {
        return BaseService.lightningValidate(this.template.querySelectorAll("lightning-input, lightning-radio-group, lightning-combobox"));
    }
    async doValidate({ detail }) {
        try {
            detail({ valid: this.checkContact(), data: this.summaryInfo });
        } catch (e) {
            console.warn(e);
        }
    }
    getUserInfo() {
        BaseService.invokeServiceMethodWithoutParameters(getContactInfo)
            .then(result => {
                if (result.contactInfo) {
                    const cInfo = result.contactInfo;
                    this.firstName = cInfo.firstName;
                    this.lastName = cInfo.lastName;
                    this.email = cInfo.email;
                    this.phone = cInfo.phone;
                    this.extension = cInfo.extension;
                    this.contactId = cInfo.contactId;
                    BaseService.pushEvent(this.eventsName.info, "loaded", window);
                    this.loading = false;
                } else {
                    throw new Error("Empty contact");
                }
            })
            .catch(error => {
                console.error(error);
                BaseService.errorToast(this.labels.errorMessage, error);
            });
    }
    connectedCallback() {
        this.getUserInfo();
    }
    onInfoCheck({ detail }) {
        if (detail === "init" && this.contactId) {
            BaseService.pushEvent(this.eventsName.info, "loaded", window);
        }
    }
    constructor() {
        super();
        window.addEventListener(this.eventsName.info, this.onInfoCheck.bind(this));
        window.addEventListener(this.eventsName.validate, this.doValidate.bind(this));
    }
}