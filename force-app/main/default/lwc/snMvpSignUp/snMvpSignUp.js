import {LightningElement, api, track} from 'lwc';
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

export default class SnMvpSignUp extends LightningElement {
    @api expanded;
    @api sldsModalEl;
    stepName;
    @api isSigned;
    @api isInProcess;
    @api isActiveAccount;
    @api packageId;
    @api packageVersion;
    @api tier;
    @api hasAdminPreviewPermission;
    @api signupJsonFormatted;
    @api
    get step() {
        return this.stepName;
    }

    set step(stepName) {
        this.stepName = [FUNNEL_REQUEST, SYNCED].includes(stepName)
            ? READY_TO_FUNNEL
            : stepName;

        if (this.stepName === READY_TO_FUNNEL && !this.isTimezonesLoaded && !this.isMVPSignedUp) {
            this.getTimezonesInfo();
        }
    }
    @api status;
    @api signupBody;

    @track options = [];
    timezoneId;
    isTimezonesLoaded = false;
    ADMIN_PREVIEW = ADMIN_PREVIEW;
    SIGN_UP = SIGN_UP;
    REQUEST_PREVIEW_PLACEHOLDER = REQUEST_PREVIEW_PLACEHOLDER;

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
        this.options = response.data.timezones?.map(timezone => ( { label: timezone.label, value: timezone.id.toString(), } ));
        this.isTimezonesLoaded = true;
    }

    addMessage(message) {
        window.dispatchEvent(new CustomEvent("AddNotificationBarMessage", {
              detail: message
        }));
    }

    get disableTimezone() {
        return !Boolean(this.status) || this.isSignedUp || this.isProcessing || !this.isTimezonesLoaded || this.isMVPSignedUp;
    }

    get isProcessing() {
        return this.status === PROCESSING;
    }

    get isStartedSignUp() {
        return this.isProcessing || this.isSignedUp;
    }

    get isServiceReady() {
        return [ACTIVE, COMPLETED].includes(this.status);
    }

    get isSignedUp() {
        return this.status === COMPLETED;
    }

    get firstStepStatus() {
        return Boolean(this.status) ? COMPLETED : ACTIVE;
    }

    get secondStepStatus() {
        if (Boolean(this.timezoneId) || this.isMVPSignedUp || this.isSignedUp) {
            return COMPLETED;
        }
        return Boolean(this.status) ? ACTIVE : READY;
    }

    get lastStepActive() {
        return Boolean(this.timezoneId) && this.hasAdminPreviewPermission;
    }

    get isMVPSignedUp() {
        return this.firstStepStatus === COMPLETED && (this.isInProcess || this.isSigned);
    }

    get helpSignUpLabel() {
        if (this.isStartedSignUp || this.isActiveAccount) {
            return '';
        } else if (this.isMVPSignedUp) {
            return this.isInProcess ? SIGN_UP_IN_PROCESS(this.tier) : SIGNED_UP(this.tier);
        } else {
            return 'Not started';
        }
    }

    get lastStepStatus() {
        if (this.isSignedUp) {
            return COMPLETED;
        }
        return this.secondStepStatus === COMPLETED ? ACTIVE : READY;
    }

    get mvpSectionClasses() {
        return this.expanded ? 'expandable expanded' : 'expandable';
    }

    get placeholder() {
        return this.isTimezonesLoaded || this.isMVPSignedUp ? 'Search...' : 'Loading...';
    }

    get signUpSectionHeader() {
        return `Sign Up ${this.tier}`;
    }

    handleChangeTimezone(event) {
        this.timezoneId = event.detail.value;

        this.dispatchEvent(new CustomEvent('mvptimezonechanged', {
            detail: {timezoneId: this.timezoneId}
        }));
    }

    handleSelectedSignUpTab(event) {
        this.dispatchEvent(new CustomEvent('selectedsignuptab', {
            detail: {selectedSignUpTab: event.target.label}
        }));
    }

    @api
    clearTimezone() {
        this.timezoneId = null;
        // Also clear the searchable dropdown display
        const dropdown = this.template.querySelector("c-searchable-dropdown");
        console.log("dropdown--> ", dropdown);
        if (dropdown) {
            dropdown.clearSelection();
        }
    }
}