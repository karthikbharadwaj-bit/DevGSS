import { LightningElement, api } from "lwc";
import empty from "@salesforce/label/c.SC_yourTimelineIsCurrentlyEmpty";
import caseNumber from "@salesforce/label/c.SC_TrustSite_caseNumber";
import maintenance from "@salesforce/label/c.SC_maintenance";
import labelCase from "@salesforce/label/c.SC_case";
export default class ScTrustCases extends LightningElement {
    @api cases;
    @api filters;
    labels = {
        empty: empty || "Your timeline is currently empty",
        caseNumber: caseNumber || "Case number",
        case: labelCase || "Case",
        maintenance: maintenance || "Maintenance",
    };
    get isLoaded() {
        return !!this.cases;
    }
}