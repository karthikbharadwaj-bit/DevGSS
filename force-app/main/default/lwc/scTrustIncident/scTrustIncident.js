import { LightningElement, api } from "lwc";

export default class ScTrustIncident extends LightningElement {
    @api incidents = [];

    get title() {
        return this.incidents && Array.isArray(this.incidents) && this.incidents.length > 0
            ? this.incidents[0].title
            : "";
    }
}