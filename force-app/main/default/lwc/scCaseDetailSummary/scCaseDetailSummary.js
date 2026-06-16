import { track, api } from "lwc";
import BaseService from "c/lwcBaseService";
import { labels } from "c/scCaseDetailLabels";
import Status from "./status";
export default class ScCaseDetailSummary extends BaseService {
    @track name;
    @track accountName;
    @track caseNumber;
    @track created;
    @track status;
    @track loading = true;
    labels = labels;
    eventsName = {
        info: "SCCaseDetailSummary",
    };
    phSize = {
        default: {
            width: "205px",
            height: "21px",
        },
        created: { width: "150px" },
        accountName: { width: "140px" },
        caseNumber: { width: "100px" },
        status: {
            width: "57px",
            height: "24px",
        },
    };
    onInfoLoad({ detail }) {
        this.loading = false;
        this.name = detail.name;
        this.accountName = detail.accountName;
        this.caseNumber = detail.caseNumber;
        this.created = detail.created;
        this.status = new Status(detail.status, "sc-case-summary");
    }

    connectedCallback() {}
    constructor() {
        super();
        window.addEventListener(this.eventsName.info, this.onInfoLoad.bind(this));
    }
}