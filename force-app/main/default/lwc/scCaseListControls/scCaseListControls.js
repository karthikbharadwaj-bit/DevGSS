import { track } from "lwc";
import BaseService from "c/lwcBaseService";
import getCases from "@salesforce/apex/SupportCommunityCaseList.getCases";
import downloadAsCSV from "@salesforce/apex/SupportCommunityCaseList.downloadAsCSV";
import checkAdmin from "@salesforce/apex/SupportCommunityCaseList.isCurrentUserSCAdmin";
import { labels } from "c/scCaseListLabels";
const LIMIT_COOKIE = "scCaseListLimit";
const MIN_LIMIT = 25;
const MAX_LIMIT = 200;
const MIN_SEARCH_LENGTH = 3;
const MAX_SEARCH_LENGTH = 255;
const DEFAULT_SEARCH_BY = "subject";
export default class ScCaseListControls extends BaseService {
    @track loading = false;
    @track limit = MIN_LIMIT;
    @track offset = 0;
    @track totalCases = 0;
    @track cases = [];
    @track order = { orderByField: "dateCreated", descending: true };
    @track isAdmin = false;
    searchLength = { max: MAX_SEARCH_LENGTH, min: MIN_SEARCH_LENGTH };
    eventsName = {
        table: "SCCaseListTable",
        limit: "SCCaseListLimit",
        page: "SCCaseListPage",
        order: "SCCaseListOrder",
        user: "sc-app_user",
        load: "SCCaseListLoad",
        export: "SCCaseListExport",
        clearSearch: "SCCaseListCSearch",
    };
    @track labels = labels;
    @track valueView = "myCases";
    @track searchByOptions = [
        { label: this.labels.subject, value: "subject" },
        { label: this.labels.caseNumber, value: "caseNumber" },
        { label: this.labels.contact, value: "contact" },
    ];
    @track valueSearchBy = DEFAULT_SEARCH_BY;
    @track searchVal = "";
    @track lastSearchVal = "";
    @track lastSearchBy = this.valueSearchBy;
    get disabledSearch() {
        return this.loading || this.searchVal.length < MIN_SEARCH_LENGTH;
    }
    get isSearch() {
        return this.lastSearchVal.length > 0;
    }
    get limitOptions() {
        const res = [];
        for (let i = MIN_LIMIT; i <= MAX_LIMIT; i += i) {
            res.push({ label: i, value: i });
        }
        return res;
    }
    get viewOptions() {
        const res = [{ label: this.labels.myCases, value: "myCases" }];
        if (this.isAdmin) {
            res.push({ label: this.labels.accountCases, value: "accountCases" });
        }
        // if(1 === 2) {   //TODO: Make real IF in CRM-412
        //     res.push({ label: this.labels.favoriteCases, value: "favoriteCases" });
        // }
        return res;
    }
    sendDataToTable() {
        BaseService.pushEvent(
            this.eventsName.table,
            {
                limit: this.limit,
                count: this.totalCases,
                cases: JSON.stringify(this.cases),
                limitOptions: this.limitOptions,
                offset: this.offset,
                isSearch: this.isSearch,
            },
            window
        );
    }
    getParams() {
        return {
            listView: this.valueView,
            offset: this.offset,
            searchLimit: this.limit,
            orderByField: this.order.orderByField,
            descending: this.order.descending,
        };
    }
    getCSV() {
        this.loading = true;
        let params = Object.assign(
            { searchByField: this.lastSearchBy, searchPart: this.lastSearchVal },
            this.getParams()
        );
        BaseService.invokeServiceMethod(downloadAsCSV, params)
            .then(result => {
                this.loading = false;
                if (result.csv) {
                    const hiddenElement = document.createElement("a");
                    hiddenElement.href = "data:text/csv;charset=utf-8," + encodeURIComponent(result.csv);
                    hiddenElement.target = "_self";
                    hiddenElement.download = "ExportCases.csv";
                    const hiddenManual = this.template.querySelector(".slds-hidden");
                    hiddenManual.appendChild(hiddenElement);
                    hiddenElement.click();
                } else {
                    throw new Error("Wrong response from the server!");
                }
            })
            .catch(error => {
                console.error(error);
                this.loading = false;
                BaseService.errorToast(this.labels.errorMessage, error);
            });
    }
    getCaseList(count, search) {
        this.loading = true;
        let params = Object.assign({ count }, this.getParams());
        if (search) {
            this.lastSearchVal = this.searchVal;
            this.lastSearchBy = this.valueSearchBy;
        }
        if (search || this.lastSearchVal.length > 0) {
            Object.assign(params, {
                searchByField: this.lastSearchBy,
                searchPart: this.lastSearchVal,
            });
        }

        BaseService.invokeServiceMethod(getCases, params)
            .then(result => {
                this.loading = false;
                if (result.caseManagement) {
                    if (result.caseManagement.caseDetails) {
                        this.cases = result.caseManagement.caseDetails;
                    } else {
                        throw new Error("Cases not found!");
                    }
                    if (result.caseManagement.totalCases && result.caseManagement.totalCases >= 0) {
                        this.totalCases = result.caseManagement.totalCases;
                    }
                    this.sendDataToTable();
                } else {
                    throw new Error("Wrong response from the server!");
                }
            })
            .catch(error => {
                console.error(error);
                BaseService.errorToast(this.labels.errorMessage, error);
            });
    }
    loadTable(val) {
        BaseService.pushEvent(this.eventsName.load, val, window);
    }
    checkAdmin() {
        BaseService.invokeServiceMethodWithoutParameters(checkAdmin)
            .then(result => {
                this.isAdmin = result.isAdmin;
            })
            .catch(error => {
                console.error(error);
                BaseService.errorToast(this.labels.errorMessage, error);
            });
    }
    onLimitChange({ detail }) {
        this.limit = detail;
        this.offset = 0;
        BaseService.setCookie(LIMIT_COOKIE, detail);
        this.getCaseList(false);
    }
    onOrderChange({ detail }) {
        this.order = { orderByField: detail.orderByField, descending: detail.descending };
        this.getCaseList(false);
    }
    onPageChange({ detail }) {
        this.offset = (detail - 1) * this.limit;
        this.getCaseList(false);
    }
    searchValueChange({ detail }) {
        this.searchVal = detail.value.trim();
    }
    handleChangeView({ detail }) {
        this.offset = 0;
        this.valueView = detail.value;
        this.loadTable(true);
        this.getCaseList(true);
    }
    handleChangeSearch({ detail }) {
        this.valueSearchBy = detail.value;
    }
    searchKeyUp(evt) {
        if (evt.keyCode === 13 && !this.disabledSearch) {
            this.doSearch();
        }
    }
    doSearch() {
        this.offset = 0;
        this.loadTable(true);
        this.getCaseList(true, true);
    }
    clearSearch() {
        this.offset = 0;
        this.lastSearchVal = "";
        this.searchVal = "";
        this.lastSearchBy = DEFAULT_SEARCH_BY;
        this.loadTable(true);
        this.getCaseList(true);
    }
    constructor() {
        super();
        this.getCaseList(true);
        this.checkAdmin();
        const cookie = BaseService.getCookie(LIMIT_COOKIE);
        if (cookie && this.limitOptions.filter(item => item.value === cookie * 1)) {
            this.limit = cookie * 1;
        }
        window.addEventListener(this.eventsName.limit, this.onLimitChange.bind(this));
        window.addEventListener(this.eventsName.order, this.onOrderChange.bind(this));
        window.addEventListener(this.eventsName.page, this.onPageChange.bind(this));
        window.addEventListener(this.eventsName.export, this.getCSV.bind(this));
        window.addEventListener(this.eventsName.clearSearch, this.clearSearch.bind(this));
    }
}