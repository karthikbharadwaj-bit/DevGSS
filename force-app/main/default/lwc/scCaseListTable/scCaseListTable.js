import { track, api } from "lwc";
import BaseService from "c/lwcBaseService";
import { Col } from "./col";
import { labels } from "c/scCaseListLabels";
import { Case } from "./case";
const MIN_LIMIT = 25;
export default class ScCaseListTable extends BaseService {
    @api caseDetailsPageUrl = "case-detail?Id=";
    @track limit = MIN_LIMIT;
    @track offset = 0;
    @track cols = [];
    @track count = 0;
    @track loading = true;
    @track rows = [];
    @track labels = labels;
    @track isSearch = false;
    @track limitOptions = [];
    eventsName = {
        info: "SCCaseListTable",
        limit: "SCCaseListLimit",
        page: "SCCaseListPage",
        load: "SCCaseListLoad",
        order: "SCCaseListOrder",
        export: "SCCaseListExport",
        clearSearch: "SCCaseListCSearch",
    };
    colsValue = {
        caseNumber: this.labels.caseNumber,
        subject: this.labels.subject,
        dateCreated: this.labels.dateCreated,
        mainContact: this.labels.mainContact,
        caseStatus: this.labels.caseStatus,
    };
    defaultOrder = { col: "dateCreated", dir: "asc" };
    get emptyText() {
        return this.loading ? "" : this.labels.empty;
    }
    get from() {
        return this.count > 0 ? this.offset + 1 : 0;
    }
    get currentPage() {
        return Math.floor(this.offset / this.limit) + 1;
    }
    set currentPage(val) {
        const res = (val - 1) * this.limit;
        this.offset = res < this.count ? res : 0;
    }
    get pagesLen() {
        return this.count > 0 ? Math.ceil(this.count / this.limit) : 1;
    }
    get to() {
        const res = this.offset + this.limit;
        return res > this.count ? this.count : res;
    }
    handleChangeLimit({ detail }) {
        this.limit = detail.value * 1;
        this.loading = true;
        BaseService.pushEvent(this.eventsName.limit, this.limit, window);
    }
    handleChangePage({ detail }) {
        this.currentPage = detail.page;
        this.loading = true;
        BaseService.pushEvent(this.eventsName.page, this.currentPage, window);
    }
    handleExportCSV() {
        BaseService.pushEvent(this.eventsName.export, {}, window);
    }
    handleClearSearch() {
        this.loading = true;
        BaseService.pushEvent(this.eventsName.clearSearch, {}, window);
    }
    handleChangeSort(evt) {
        const curInx = evt.currentTarget.getAttribute("data-inx") * 1;
        let currentCol;
        this.cols.forEach((item, inx) => {
            if (inx === curInx) {
                currentCol = this.cols[inx];
            }
        });
        const curState = currentCol.sort;
        this.cols = [];
        let inx = 0;
        for (let key in this.colsValue) {
            this.cols.push(new Col(this.colsValue[key], key, inx === curInx ? curState : null, inx === curInx));
            inx++;
        }
        this.loading = true;
        BaseService.pushEvent(
            this.eventsName.order,
            { orderByField: currentCol.value, descending: currentCol.sort === "desc" },
            window
        );
    }
    onInfoLoad({ detail }) {
        this.loading = false;
        this.limit = detail.limit;
        this.count = detail.count;
        this.rows = JSON.parse(detail.cases).map(item => new Case(item, this.caseDetailsPageUrl));
        this.limitOptions = detail.limitOptions;
        this.offset = detail.offset;
        this.isSearch = detail.isSearch;
    }
    onLoad({ detail }) {
        this.loading = detail;
    }
    constructor() {
        super();
        window.addEventListener(this.eventsName.info, this.onInfoLoad.bind(this));
        window.addEventListener(this.eventsName.load, this.onLoad.bind(this));
        this.cols = [];
        for (let key in this.colsValue) {
            this.cols.push(
                new Col(this.colsValue[key], key, this.defaultOrder.col === key ? this.defaultOrder.dir : null)
            );
        }
    }
}