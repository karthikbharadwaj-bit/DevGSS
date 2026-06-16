import {LightningElement, api} from "lwc";

const TYPE_GLOBAL = 'global';
const TYPE_LOCAL = 'local';
export default class LwcSpinner extends LightningElement {

    @api text = '';
    @api isShown = false;
    @api type = TYPE_GLOBAL;
    @api spinnerStyle = '';
    @api theme = '';

    get isGlobal() {
        return this.type === TYPE_GLOBAL;
    }

    get cssClass() {
        return [
            "slds-spinner_container",
            this.isGlobal ? "slds-is-fixed" : "slds-is-absolute",
            this.theme
        ].join(' ');
    }

    get cssSpinner() {
        return [
            "slds-spinner",
            "slds-spinner--medium",
            this.spinnerStyle
        ].join(' ');
    }

    connectedCallback() {
        if (this.isGlobal) {
            window.addEventListener("ShowSpinnerEvent", this.onShowSpinnerEvent.bind(this));
        }
    }

    onShowSpinnerEvent(event) {
        this.text = event.detail.text;
        this.isShown = !!event.detail.isShown;
    }
}