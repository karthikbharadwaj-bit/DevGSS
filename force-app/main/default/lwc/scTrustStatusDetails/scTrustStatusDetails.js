import { track } from "lwc";
import SC_good from "@salesforce/label/c.SC_good";
import SC_warning from "@salesforce/label/c.SC_warning";
import SC_information from "@salesforce/label/c.SC_information";
import SC_error from "@salesforce/label/c.SC_error";
import getSystemStatus from "@salesforce/apex/SupportCommunityStatus.getSystemStatus";
import { Status } from "./status";
import StatusHelper from "c/scTrustStatusHelper";
import BaseService from "c/lwcBaseService";

export default class ScTrustStatusDetails extends BaseService {
    @track statuses = [];
    label = {
        SC_good: SC_good || "Good",
        SC_warning: SC_warning || "Warning",
        SC_error: SC_error || "Issue",
        SC_information: SC_information || "Information",
    };
    eventsName = {
        status: "SCTrustStatus",
        incidents: "SCTrustIncidents",
    };
    get col_1() {
        return this.statuses.filter(function(item, inx) {
            return (inx + 1) & 1;
        });
    }
    get col_2() {
        return this.statuses.filter(function(item, inx) {
            return !((inx + 1) & 1);
        });
    }

    getSumStatus(statuses) {
        let max = 0;
        for (let key in statuses) {
            const statusValue = StatusHelper.getByLabel(statuses[key].serviceWarning).level;
            if (statusValue > max) max = statusValue;
        }
        BaseService.pushEvent(this.eventsName.status, StatusHelper.getByLevel(max).name, window);
    }
    setData(items, data) {
        for (let i = 0; i < items.length; i++) {
            try {
                if (items[i].apiName) items[i].setData(data[items[i].apiName]);
                else if (items[i].children.length > 0) {
                    this.setData(items[i].children, data);
                }
            } catch (e) {
                console.error(e);
                items[i].setData({ serviceWarning: "Error", incidentList: [] });
            }
        }
    }
    groupIncidents(incidents, key) {
        return incidents.reduce(function(result, item) {
            (result[item[key]] = result[item[key]] || []).push(item);
            return result;
        }, {});
    }
    getIncidents(stList) {
        let incidents = [];
        stList.forEach(status => {
            incidents = incidents.concat(
                status.children.length > 0 ? this.getIncidents(status.children) : status.incidentList
            );
        });
        return incidents;
    }
    loadStatuses() {
        getSystemStatus()
            .then(result => {
                try {
                    result = JSON.parse(result);
                } catch (e) {
                    console.error(e);
                    result = null;
                }
                if (result) {
                    this.getSumStatus(result);
                    this.statuses = [
                        new Status("Calling", null, [
                            { title: "Inbound", apiName: "inboundCall" },
                            { title: "Outbound", apiName: "outboundCall" },
                        ]),
                        new Status("SMS", null, [
                            { title: "Inbound", apiName: "inboundSms" },
                            { title: "Outbound", apiName: "outboundSms" },
                        ]),
                        new Status("Phones", null, [
                            { title: "Deskphone", apiName: "registration" },
                            { title: "Soft Phone", apiName: "spRegistration" },
                        ]),
                        new Status("Fax", null, [
                            { title: "Inbound", apiName: "inboundFax" },
                            { title: "Outbound", apiName: "outboundFax" },
                        ]),
                        new Status("Meetings", "meetings"),
                        new Status("Service Portal", "serviceWeb"),
                        new Status("Contact Center", "contactCenter"),
                        new Status("Connect Platform", "platform"),
                        new Status("Glip Messaging", "glip"),
                        new Status("Developer Sandbox", "devSandbox"),
                    ];
                    this.setData(this.statuses, result);
                    this.incidents = this.groupIncidents(this.getIncidents(this.statuses), "groupByValue");
                    BaseService.pushEvent(this.eventsName.incidents, this.incidents, window);
                }
                this.error = undefined;
            })
            .catch(error => {
                this.error = error;
            });
    }
    connectedCallback() {
        this.statuses = [];
        for (let i = 0; i < 10; i++) {
            this.statuses.push(new Status(null, i + 1));
        }
        this.loadStatuses();
    }
}