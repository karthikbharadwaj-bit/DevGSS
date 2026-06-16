import { LightningElement, api } from 'lwc';
import {
    ACTIVE,
    COMPLETED,
    READY,
    READY_TO_CREATE_MAIN_COST_CENTER,
    COST_CENTER_CREATED,
    READY_TO_FUNNEL,
    SYNCED,
    SIGN_UP_IN_PROCESS,
    PROSERV_SIGNUP_REQUEST_SEND,
} from "c/snUtils";

export default class SnProServSignUp extends LightningElement {
    @api expanded;
    @api status;
    @api isSigned;
    @api step;
    @api isInProcess;
    @api tier;

    get proServSectionClasses() {
        return this.expanded ? 'expandable expanded' : 'expandable';
    }

    get firstStepStatus() {
        return this.step === READY_TO_CREATE_MAIN_COST_CENTER
            || this.step === COST_CENTER_CREATED
            || this.step === PROSERV_SIGNUP_REQUEST_SEND
            || this.isSignedUp
            || this.step === SYNCED
        ? COMPLETED
        : ACTIVE;
    }

    get secondStepStatus() {
        if (this.step === COST_CENTER_CREATED || this.isSignedUp || this.step === SYNCED || this.step === PROSERV_SIGNUP_REQUEST_SEND) {
            return COMPLETED;
        }

        return this.step === READY_TO_CREATE_MAIN_COST_CENTER ? ACTIVE : READY;
    }

    get isSignedUp() {
        return this.status === COMPLETED;
    }

    get isProcessing() {
        return this.step === PROSERV_SIGNUP_REQUEST_SEND;
    }

    get lastStepStatus() {
        if (this.isSignedUp) {
            return COMPLETED;
        }
       
        if (this.step === READY_TO_CREATE_MAIN_COST_CENTER || this.step === READY_TO_FUNNEL || !this.step) {
            return READY;
        }
        if (this.step === COST_CENTER_CREATED && !this.isSignedUp) {
            return ACTIVE;
        }
        return ACTIVE;
    }

    handleSelectedSignUpTab(event) {
        this.dispatchEvent(new CustomEvent('selectedsignuptab', {
            detail: {selectedSignUpTab: event.target.label}
        }));
    }

    get helpSignUpLabel() {
        if (this.isProcessing && !this.isSignedUp) {
            return SIGN_UP_IN_PROCESS(this.tier);
        }
    }
}