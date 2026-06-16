import { LightningElement,api,track} from 'lwc';
import {
    ACTIVE,
    COMPLETED,
    READY,
    PROCESSING,
    FUNNEL_REQUEST,
    SYNCED,
    READY_TO_FUNNEL,
    SIGN_UP_IN_PROCESS,
    SIGNED_UP,
    ADMIN_PREVIEW,
    SIGN_UP,
    REQUEST_PREVIEW_PLACEHOLDER,
} from "c/snUtils";
import getTimezones from '@salesforce/apex/FunnelAPI.getTimezones';
export default class SnSignUpEvents extends LightningElement {
    @api expanded;
    stepName;
    @api isInProcess;
    @api isActiveAccount;
    @api packageId;
    @api packageVersion;
    @api tier; 
    @api status;
    @api isMultiProd;
    @track options = [];
    @track optionsWithNameMap;
    @api sldsModalEl;
    //@api hasAdminPreviewPermission;
    @api
    get step() {
        return this.stepName;
    }
    set step(stepName) {
        this.stepName = [FUNNEL_REQUEST, SYNCED].includes(stepName)
            ? READY_TO_FUNNEL
            : stepName;

        if (this.stepName === READY_TO_FUNNEL && !this.isTimezonesLoaded ){//&& !this.isEventSignedUp) {
            this.getTimezonesInfo();
        }
    }

    get firstStepStatus() {
        return Boolean(this.status) ? COMPLETED : ACTIVE;
    }

    get secondStepStatus() {
        if (Boolean(this.timezoneName) || this.isSignedUp || this.isMultiProd) {
            return COMPLETED;
        }
        return Boolean(this.status) ? ACTIVE : READY;
    }

    get isEventSignedUp() {
        return this.firstStepStatus === COMPLETED && this.isInProcess;
    }

    get eventSectionClasses() {
        return this.expanded ? 'expandable expanded' : 'expandable';
    }

    get disableTimezone() {
        return !Boolean(this.status) || this.isSignedUp || this.isProcessing || !this.isTimezonesLoaded ;
    }

    get isProcessing() {
        return this.status === PROCESSING;
    }

    get timezonePlaceholder() {
        return this.isTimezonesLoaded || this.isEventSignedUp ? 'Select timezone' : 'Loading...';
    }

    get isServiceReady() {
        return [ACTIVE, COMPLETED].includes(this.status);
    }

    get signUpSectionHeader() {
        return `Sign Up ${this.tier}`;
    }

    get isStartedSignUp() {
        return this.isProcessing || this.isSignedUp;
      }
    
      get isSignedUp() {
        return this.status === COMPLETED;
      }

    get lastStepStatus() {
        if (this.isSignedUp) {
            return COMPLETED;
        }
        return this.secondStepStatus === COMPLETED ? ACTIVE : READY;
    }

    get lastStepActive() {
        return (Boolean(this.timezoneName) || this.isMultiProd); //&& this.hasAdminPreviewPermission;
    }


    timezoneName;
    isTimezonesLoaded = false;
    SIGN_UP = SIGN_UP;

    getTimezonesInfo() {
            getTimezones({
                packageId: this.packageId,
                packageVersion: this.packageVersion
            }).then(res => { this.handleResponse(res, this.handleGetTimezoneInfo.bind(this)); });
        }

    handleResponse(res, handler) {
        const response = JSON.parse(res);
        if (response.messages && response.messages.length > 0) {
            this.addMessage(response.messages[0]);
            return;
        }

        handler(response);
    } 
    
    handleGetTimezoneInfo(response) {
        this.options = response.data.timezones?.map(timezone => ( { label: timezone.label, value: timezone.id.toString()} ));
        this.optionsWithNameMap = new Map(response.data.timezones?.map(timezone => [timezone.id.toString(), timezone.name ]));
        this.isTimezonesLoaded = true;
    }

    addMessage(message) {
        window.dispatchEvent(new CustomEvent("AddNotificationBarMessage", {
              detail: message
        }));
    }

    handleChangeTimezone(event) {
        this.timezoneName = event.detail.value;
        const timeZoneNameToSend = this.timezoneName!=null && this.optionsWithNameMap.has(this.timezoneName) ? this.optionsWithNameMap.get(this.timezoneName) : null;
        this.dispatchEvent(new CustomEvent('eventstimezonechanged', {
            detail: {timezoneName: timeZoneNameToSend}
        }));
    }

    handleSelectedSignUpTab(event) {
        this.dispatchEvent(new CustomEvent('selectedsignuptab', {
            detail: {selectedSignUpTab: event.target.label}
        }));
    }

}