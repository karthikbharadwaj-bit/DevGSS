import { LightningElement, track } from "lwc";
import SC_good from "@salesforce/label/c.SC_good";
import SC_warn from "@salesforce/label/c.SC_warning";
import SC_err from "@salesforce/label/c.SC_error";
import SC_info from "@salesforce/label/c.SC_information";

export default class ScTrustStatus extends LightningElement {
    @track status = "";
    label = {
        SC_good: SC_good || "Good",
        SC_warn: SC_warn || "Warning",
        SC_err: SC_err || "Issue",
        SC_info: SC_info || "Information",
    };
    eventsName = {
        status: "SCTrustStatus",
    };
    get classes() {
        return "sc-trust-status " + this.status;
    }
    get loaded() {
        return this.status.length > 0;
    }
    get statusText() {
        switch (this.status) {
            case "good":
                return this.label["SC_" + this.status];
            case "info":
                return this.label["SC_" + this.status];
            case "warn":
                return this.label["SC_" + this.status];
            case "err":
                return this.label["SC_" + this.status];
            default:
                console.error("Unknow status:", this.status);
                this.status = "";
                return "";
        }
    }
    connectedCallback() {
        window.addEventListener(
            this.eventsName.status,
            ({ detail }) => {
                this.status = detail;
            },
            false
        );
    }
}