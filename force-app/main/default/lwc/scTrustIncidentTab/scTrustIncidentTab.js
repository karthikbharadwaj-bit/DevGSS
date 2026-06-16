import { api } from "lwc";
import BaseService from "c/lwcBaseService";

export default class ScTrustIncidentTab extends BaseService {
    @api incidents = {};
    @api inx = 0;
    get hasIncidents() {
        return this.incidents && Array.isArray(this.incidents) && this.incidents.length > 0;
    }
    get title() {
        return this.hasIncidents ? this.incidents[0].fullTitle : "";
    }
    get status() {
        return this.hasIncidents ? this.incidents[0].level : "";
    }
    get iconCls() {
        return `have-info-icon ${this.status.name}`;
    }
}