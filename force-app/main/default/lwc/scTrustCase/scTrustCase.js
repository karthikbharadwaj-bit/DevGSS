import { LightningElement, api, track } from "lwc";

export default class ScTrustCase extends LightningElement {
    @api type;
    @api title;
    @api inx;
    @api url;
    @api number;
    @api details;
    @api modify;
    @api labels;
    @api status;
    @track minimize = true;

    get formatedModify() {
        return (
            ("0" + (this.modify.getMonth() + 1)).slice(-2) +
            "/" +
            ("0" + this.modify.getDate()).slice(-2) +
            "/" +
            ("0" + this.modify.getFullYear()).slice(-2)
        );
    }
    get typeLabel() {
        return this.labels[this.type.toLowerCase()] || "";
    }
    get isCase() {
        return this.type === "Case";
    }
    get isEmpty() {
        return !!this.title;
    }
    get classMain() {
        return "sc-trust-case__main" + (this.minimize ? " minimize" : "") + (!this.hasDetails ? " no-details" : "");
    }
    get hasDetails() {
        return !!this.details;
    }
    doMinimize(e) {
        if (e.target.tagName.toLowerCase() !== "a") {
            if (this.hasDetails) {
                this.minimize = !this.minimize;
            } else this.minimize = true;
        }
    }
    clickNumber(evt) {
        evt.stopPropagation();
        location.href = evt.target.getAttribute("data-url");
    }
    clickLink(evt) {
        evt.stopPropagation();
    }
}