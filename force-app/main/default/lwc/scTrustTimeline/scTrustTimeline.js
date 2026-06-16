import { LightningElement, track, api } from "lwc";
import labelNewCaseTitle from "@salesforce/label/c.SC_CreateNewCase";
import labelAllFilter from "@salesforce/label/c.SC_AllFilter";
import labelAllCases from "@salesforce/label/c.SC_allCases";
import labelOpenCases from "@salesforce/label/c.SC_openCases";
import labelMaintenance from "@salesforce/label/c.SC_maintenance";
import labelOpenCasePortal from "@salesforce/label/c.SC_TrustSite_openCasePortal";
import labelFilterBy from "@salesforce/label/c.SC_TrustSite_filterBy";
import getCasesFeed from "@salesforce/apex/SupportCommunityUsers.getCasesFeed";
import { Case } from "./case";

export default class ScTrustTimeline extends LightningElement {
    @api title;
    @api createNew = "./new-case";
    @api caseLink = "./case-detail?caseId=";
    @api caseListLink = "./case-list";
    @track filters;
    @track cases;
    @track error;
    @track counts = { Case: 0, Maintenance: 0 };
    @track reload = false;
    labels = {
        newCaseTitle: labelNewCaseTitle || "Create New Case",
        allFilter: labelAllFilter || "All",
        allCases: labelAllCases || "All Cases",
        openCases: labelOpenCases || "Open Cases",
        maintenance: labelMaintenance || "Maintenance",
        openCasePortal: labelOpenCasePortal || "Open Case Portal",
        filterBy: labelFilterBy || "Filter by",
    };
    isSupportType(value) {
        return value === "Case" || value === "Maintenance";
    }
    get reloadCSS() {
        return "sc-trust-timeline__cases-wrapper" + (this.reload ? " reload" : "");
    }
    get activeFilter() {
        return Array.isArray(this.filters) ? this.filters.filter(item => item.active)[0] : null;
    }
    get activeFilterValue() {
        return this.activeFilter ? this.activeFilter.id : 0;
    }
    get filter() {
        return this.activeFilter ? this.activeFilter.filters : [];
    }
    get filterStr() {
        return JSON.stringify(
            this.filter.map(item => {
                if (this.isSupportType(item.type)) return Object.assign(item, { offset: this.counts[item.type] });
            })
        );
    }
    get isLoaded() {
        return !!this.filters;
    }
    get loading() {
        return !this.filters;
    }
    get filterOptions() {
        return this.filters ? this.filters.map(item => {
            return { label: item.title, value: item.id };
        }) : [];
    }
    doPreloader() {
        const cases = [];
        for (let i = 0; i < 10; i++) {
            const caseItem = { isPreloader: true, uid: new Date().getTime() + Math.random() };
            cases.push(caseItem);
        }
        this.cases = cases;
    }
    loadMore() {
        this.reload = true;
        this.getCases(false);
    }
    scroll(e) {
        if (e.target.scrollTop + e.target.clientHeight >= e.target.scrollHeight) {
            this.loadMore();
        }
    }
    getCases(clear) {
        const this_ = this;
        if (clear) {
            this.counts = { Case: 0, Maintenance: 0 };
        }
        getCasesFeed({ filters: this.filterStr })
            .then(result => {
                if (result) {
                    if (clear) {
                        this.cases = [];
                        try {
                            this.template.querySelectorAll(".sc-trust-timeline__cases")[0].scrollTop = 0;
                        } catch (e) {
                            console.warn(error);
                        }
                    }
                    const newCases = result.map(function(item) {
                        if (item) {
                            if (this_.isSupportType(item.RecordTypeName)) this_.counts[item.RecordTypeName]++;
                            return new Case(
                                Object.assign({}, item.Case, { isOpen: item.isOpen }, { type: item.RecordTypeName }),
                                this_.caseLink
                            );
                        }
                        return null;
                    });
                    this.cases = this.cases.filter(item => !item.isPreloader).concat(newCases);
                    this.reload = false;
                }
                this.error = undefined;
            })
            .catch(error => {
                console.warn(error);
                this.error = error;
                this.reload = false;
                this.doPreloader();
            });
    }
    doActive({ detail }) {
        const id = detail.value * 1 || 0;
        if(this.filters) {
            this.filters.forEach(item => {
                item.active = item.id === id;
            });
        }
        this.getCases(true);
    }
    handleOpen() {
        location.href = this.caseListLink;
    }
    handleNew() {
        location.href = this.createNew;
    }

    constructor() {
        super();
        this.doPreloader();
        this.filters = [];
        const all = {
            id: 0,
            title: this.labels.allFilter,
            filters: [{ type: "Case" }, { type: "Maintenance" }],
            active: true,
        };
        const all_cases = { id: 1, title: this.labels.allCases, filters: [{ type: "Case" }], active: false };
        const open_cases = {
            id: 2,
            title: this.labels.openCases,
            filters: [{ type: "Case", isOpen: true }],
            active: false,
        };
        const maintenance = {
            id: 3,
            title: this.labels.maintenance,
            filters: [{ type: "Maintenance" }],
            active: false,
        };
        this.filters.push(all);
        this.filters.push(all_cases);
        this.filters.push(open_cases);
        this.filters.push(maintenance);
    }
    connectedCallback() {
        this.doActive({ detail: { value: null } });
    }
}