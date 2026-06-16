import { LightningElement, api } from "lwc";
import { COMPLETED, READY } from "c/snUtils";

export default class SnProgressSection extends LightningElement {
    @api header;
    @api last;
    currentSetting;
    @api setting;
    @api currentStatus;
    @api set status(status) {
        this.currentStatus = status || READY;
    }

    get status() {
        return this.currentStatus;
    }

    get isCompleted() {
        return COMPLETED === this.currentStatus;
    }

    get lineClasses() {
        return "line line-" + (this.last ? "off" : this.currentStatus);
    }

    get liFirstClasses() {
        return "slds-progress__item progress-container slds-is-" + this.currentStatus;
    }

    get stepHeaderTextClasses() {
        return "step-header header-" + this.currentStatus;
    }
}