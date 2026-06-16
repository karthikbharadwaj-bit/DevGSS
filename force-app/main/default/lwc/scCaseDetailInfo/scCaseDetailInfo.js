import { track, api } from "lwc";
import BaseService from "c/lwcBaseService";
import { labels } from "c/scCaseDetailLabels";
import getCaseDetail from "@salesforce/apex/SupportCommunityViewCase.getCaseDetail";

export default class ScCaseDetailInfo extends BaseService {
    @api newCaseLink = "new-case";
    @track subject;
    @track desc;
    @track id;
    @track comments = [];
    @track attachments = [];
    @track isClosed = false;
    @track loading = false;
    @track labels = labels;
    @track isGDPR = false;
    @track selectedOptions = { l1: null, l2: null, l3: null };
    @track severityLevel = null;
    @track userId;
    @track GDPRInfo = {};
    eventsName = {
        summary: "SCCaseDetailSummary",
        attachments: "SCCaseDetailAttachments",
    };
    gdprMarkers = {
        view: "View",
        change: "Change",
        download: "Download",
        delete: "Delete",
        analytics: "Retain Analytics Data",
        glip: "Retain Glip Messages",
        name: "Name of user requiring privacy action",
        email: "Email of user requiring privacy action",
        phone: "RC Phone Number (if applicable) of the user requiring privacy action",
        citizen: "Is this user a Citizen or legal resident within the EU (including UK)",
        comments: "Comments",
    };
    describeOptionList = ["view", "download", "change", "delete"];
    describeAdlOptionList = ["analytics", "glip"];
    parseGDPR(txt) {
        try {
            txt = txt.replace("====================\n\n", "");
            let comInx = txt.indexOf(this.gdprMarkers.comments);
            let comment;
            if(comInx < 0) {
                comInx = txt.length;
                comment = "";
            } else {
                const comLen = this.gdprMarkers.comments.length + 2;
                comment = txt.substring(comInx + comLen);
            }
            const boolVals = ["view", "change", "download", "delete", "analytics", "glip", "citizen"];
            const request = txt.substring(0, comInx - 1).split("\n");
            let bufGDPR = {};
            request.forEach(item => {
                const colon = item.indexOf(": ");
                const name = item.substring(0, colon).toLowerCase();
                let ckey;
                const value = item.substring(colon + 2);
                for (let key in this.gdprMarkers) {
                    if (this.gdprMarkers[key].toLowerCase() === name) {
                        ckey = key;
                        break;
                    }
                }
                if (!ckey) {
                    console.warn("Not parsed:", name, value);
                } else {
                    bufGDPR[ckey] =
                        boolVals.filter(item => item === ckey).length > 0
                            ? value.trim().toLowerCase() === "yes"
                            : value;
                }
            });
            if (bufGDPR.name) {
                bufGDPR.firstName = bufGDPR.name
                    .split(" ")
                    .slice(0, -1)
                    .join(" ");
                bufGDPR.lastName = bufGDPR.name
                    .split(" ")
                    .slice(-1)
                    .join(" ");
                delete bufGDPR.name;
            }
            this.GDPRInfo = bufGDPR;
            this.isGDPR = true;
            return comment;
        } catch (e) {
            console.warn("Parse GDPR request failed!", e);
            return txt;
        }
    }
    set description(val) {
        const descEl = this.template.querySelector(".sc-case-info__description");
        if (this.subject.indexOf("GDPR Request:") === 0) {
            val = this.parseGDPR(val);
        }
        this.desc = val;
        const paragraphs = val.split("\n");
        if (descEl) {
            descEl.innerHTML = paragraphs.map(item => `<p>${item}</p>`).join("");
        }
    }
    get describeOptions() {
        return this.describeOptionList.map(item => {
            return { label: this.labels[item], value: item };
        });
    }
    get describeDeleteSelected() {
        return this.GDPRInfo.delete;
    }
    get describeAdlOptions() {
        return this.describeAdlOptionList.map(item => {
            return { label: this.labels[item], value: item };
        });
    }
    get describeValue() {
        let describeVal = [];
        for (let val of this.describeOptionList) {
            if (this.GDPRInfo[val]) {
                describeVal.push(val);
            }
        }
        return describeVal;
    }
    get describeAdlValue() {
        let describeVal = [];
        for (let val of this.describeAdlOptionList) {
            if (this.GDPRInfo[val]) {
                describeVal.push(val);
            }
        }
        return describeVal;
    }

    getCaseInfo() {
        this.loading = true;
        BaseService.invokeServiceMethod(getCaseDetail, { caseId: this.id })
            .then(result => {
                this.loading = false;
                if (result.caseDetail) {
                    this.subject = result.caseDetail.subject || "";
                    this.userId = result.currentUserId;
                    this.description = result.caseDetail.description  || "";
                    this.isClosed = result.caseDetail.isClosed;
                    this.attachments = result.caseDetail.attachments;
                    this.comments = result.caseDetail.comments;
                    this.selectedOptions.l1 = result.caseDetail.selectedProduct;
                    this.selectedOptions.l2 = result.caseDetail.selectedProduct2;
                    this.selectedOptions.l3 = result.caseDetail.selectedProduct3;
                    this.severityLevel = result.caseDetail.severityLevel;
                    BaseService.pushEvent(
                        this.eventsName.summary,
                        {
                            name: result.caseDetail.creatorName,
                            accountName: result.caseDetail.accountName,
                            caseNumber: result.caseDetail.caseNumber,
                            created: result.caseDetail.createdDate,
                            status: result.caseDetail.status,
                        },
                        window
                    );
                    BaseService.pushEvent(
                        this.eventsName.attachments,
                        {
                            attachments: this.attachments,
                            caseId: this.id,
                            userId: this.userId,
                            isClosed: this.isClosed,
                        },
                        window
                    );
                } else {
                    throw new Error("Case not found!");
                }
            })
            .catch(error => {
                console.error(error);
                BaseService.errorToast(this.labels.errorMessage, error);
            });
    }
    handleNewComment(evt) {
        const bufComments = JSON.parse(JSON.stringify(this.comments));
        bufComments.unshift(JSON.parse(JSON.stringify(evt.detail)));
        this.comments = bufComments;
    }
    duplicate() {
        const caseInfo = Object.assign(
            {
                isGDPR: this.isGDPR,
                selectedOptions: this.selectedOptions,
                severityLevel: this.severityLevel,
                description: this.desc,
                subject: this.subject,
            },
            this.GDPRInfo
        );
        try {
            window.open(this.newCaseLink + "#" + encodeURIComponent(window.btoa(encodeURIComponent(JSON.stringify(caseInfo)))));
        } catch (e) {
            BaseService.errorToast(this.labels.errorMessage, e);
        }
    }
    connectedCallback() {}
    constructor() {
        super();
        this.id = BaseService.getUrlParameter("Id");
        this.getCaseInfo();
    }
}