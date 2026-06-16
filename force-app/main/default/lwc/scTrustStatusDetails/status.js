/**
 * Created on 27.05.2019
 */

import { Incident } from "./incident";
import StatusHelper from "c/scTrustStatusHelper";

export class Status {
    constructor(title, apiName, children, parentName) {
        this.title = title;
        this.apiName = apiName;
        this.status = null;
        this.incidentList = [];
        this.parentName = parentName || null;
        this.inx = 0;
        if (children && Array.isArray(children))
            this.children = children.map(item => new Status(item.title, item.apiName, item.children, this.title));
        else this.children = [];
    }
    normalizeStatus(status) {
        return StatusHelper.getByLabel(status).name;
    }
    get uid() {
        return this.apiName || this.title;
    }
    setData(data) {
        if (data) {
            if (data.serviceWarning) this.status = this.normalizeStatus(data.serviceWarning);
            if (data.incidentList && Array.isArray(data.incidentList) && data.incidentList.length > 0)
                this.incidentList = data.incidentList.map(
                    item =>
                        new Incident(
                            this.title,
                            this.parentName,
                            item.Date__c,
                            item.Description__c,
                            item.Message__c,
                            StatusHelper.getByLabel(item.Level__c)
                        )
                );
        }
    }
}