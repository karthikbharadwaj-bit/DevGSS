import { track } from "lwc";
import { CsvReader } from "./csvReader";
import { Case } from "./case";
import { Error } from "./error";
import BaseService from "c/lwcBaseService";
import getMapUIDAndAccountId from "@salesforce/apex/MaintenanceCasesCreate.getMapUIDAndAccountId";
import getPicklistValuesForFields from "@salesforce/apex/MaintenanceCasesCreate.getPicklistValuesForFields";
import insertMaintenance from "@salesforce/apex/MaintenanceCasesCreate.insertMaintenance";

const CHUNK_SIZE = 20;
const CASE_SIZE = 100;
const LOADER_EVENT_NAME = "imLoader";
const CSV_FIELDS = [
    "Subject",
    "Description",
    "Priority",
    "Date_Assigned",
    "Date_Completed",
    "Status",
    "Account_POD",
    "Origin",
    "Initial",
    "UID",
    "inContact_Cluster",
];
const MIN_LIMIT = 25;
const MAX_LIMIT = 200;
const LIMIT_COOKIE = "imCaseListLimit";
export default class ImCases extends BaseService {
    @track loading = false;
    @track errors = [];
    @track loadedChunks = 0;
    @track hasErrors = false;
    @track importErrors = 0;
    @track sortedBy = "id";
    @track sortedDirection = "desc";
    @track picklists = {};
    @track steps = [];

    @track limit = MIN_LIMIT;
    @track currentPage = 1;
    @track uiSteps = Array(3).fill(false);

    get limitOptions() {
        const res = [];
        for (let i = MIN_LIMIT; i <= MAX_LIMIT; i += i) {
            res.push({ label: i, value: i });
        }
        return res;
    }

    get hasWarnings() {
        return this.errors.length > 0;
    }

    get caseCount() {
        return this.cases.length;
    }

    get hasData() {
        return this.caseCount > 0;
    }

    get disableInsert() {
        return this.cases.length === 0 || this.hasErrors || this.loadedChunks > 0;
    }

    get chunksCount() {
        return this.steps.reduce((total, item) => {
            return total + item.length;
        }, 0);
    }

    get sortedData() {
        const sortData = this.cases.slice(0);
        let sortedBy = this.sortedBy;
        if(sortedBy === "wIconVal") {
            sortedBy = "wIconLevel";
        }
        sortData.sort((a, b) => {
            const aVal = a[sortedBy] === null ? "" : a[sortedBy];
            const bVal = b[sortedBy] === null ? "" : b[sortedBy];
            if (aVal > bVal) {
                return this.sortedDirection === "asc" ? -1 : 1;
            } else if (bVal > aVal) {
                return this.sortedDirection === "asc" ? 1 : -1;
            } else {
                return 0;
            }
        });
        return sortData;
    }

    get pagesLen() {
        return Math.ceil(this.caseCount / this.limit);
    }

    get offset() {
        return (this.currentPage - 1) * this.limit;
    }

    get page() {
        return this.sortedData.slice(this.offset, this.offset + this.limit);
    }

    get uiValidChoose() {
        return this.uiSteps[0];
    }

    set uiValidChoose(val) {
        this.uiSteps[0] = val;
    }

    get uiValidCheckErrors() {
        return this.uiSteps[1];
    }

    set uiValidCheckErrors(val) {
        this.uiSteps[1] = val;
    }

    get uiDisabledCheckErrors() {
        return !this.uiValidChoose || this.hasErrors;
    }

    get uiValidImport() {
        return this.uiSteps[2];
    }

    set uiValidImport(val) {
        this.uiSteps[2] = val;
    }

    get uiDisabledImport() {
        return !this.uiValidCheckErrors || this.disableInsert;
    }

    uiValidClear(from) {
        for (let i = from; i < this.uiSteps.length; i++) {
            this.uiSteps[i] = false;
        }
    }

    previewText(file) {
        return new Promise((resolve, reject) => {
            let oFReader = new FileReader();
            oFReader.readAsText(file);
            oFReader.onload = oFREvent => {
                resolve(oFREvent.target.result);
            };
            oFReader.onerror = e => {
                reject(e);
            };
        });
    }

    checkDuplicate() {
        this.cases.forEach(item => {
            if (item.accountId) {
                const duplicate = this.cases.filter(cs => cs.caseUniqData === item.caseUniqData && cs.id !== item.id);
                if (duplicate.length > 0) {
                    this.errors.push(
                        new Error(item.id, `[${item.id} = ${duplicate[0].id}] Maintenance is duplicated.`, "error"),
                    );
                }
            }
        });
    }

    checkValidCSV(record) {
        const hasValidFields = !CSV_FIELDS.every(item => record[item] === null);
        if (hasValidFields) {
            let hasOtherFields = false;
            const otherFields = [];
            for (let key in record) {
                if (record.hasOwnProperty(key) && CSV_FIELDS.indexOf(key) < 0) {
                    hasOtherFields = true;
                    otherFields.push(key);
                }
            }
            if (hasOtherFields) {
                this.errors.push(new Error(0, `CSV contains unsupported fields: ${otherFields.join(",")}`, "error"));
            }
            return !hasOtherFields;
        } else {
            return false;
        }
    }

    sortErrors() {
        this.errors = this.errors.sort((a, b) => {
            const diff = a.levelNum - b.levelNum;
            if (diff === 0) {
                return a.id - b.id;
            } else {
                return diff;
            }
        });
        const errorsCount = this.errors.filter(item => item.levelNum === 1);
        this.hasErrors = errorsCount.length > 0;
    }
    clearFileInput(fileEl) {
        try {
            fileEl.value = "";
            if (fileEl.value) {
                fileEl.type = "text";
                fileEl.type = "file";
            }
        } catch (e) {
        }
    }
    async readFile() {
        const fileEl = this.template.querySelector(".im-input-file");
        if (fileEl.files.length > 0) {
            this.loading = true;
            this.uiValidChoose = true;
            this.uiValidClear(2);
            this.loadedChunks = 0;
            const sourceFile = await this.previewText(fileEl.files[0]);
            let csv = [];
            try {
                csv = this.csv.toObjects(sourceFile);
            }catch (e) {
                let message = null;
                try {
                    message = e.message.replace("CSVDataError:","");
                    message = message.substr(0,message.indexOf("[")).trim();
                }catch (e) {

                }
                BaseService.showToast("error","Invalid CSV file",message);
                this.loading = false;
                this.uiValidClear(0);
                this.clearFileInput(fileEl);
                return null;
            }
            if (csv && csv.length > 0 && this.checkValidCSV(csv[0])) {
                const cases = csv.map((item, id) => new Case(item, id + 1, this.picklists));
                const accountIds = await BaseService.invokeServiceMethod(
                    getMapUIDAndAccountId,
                    cases.filter(item => !!item.uid).map(item => item.uid),
                ).then(res => {
                    return res.mapUIDAndAccountId;
                });
                cases.forEach(item => item.addAccountId(accountIds));
                this.cases = cases;
                this.errors = this.cases.map(item => item.errors).filter(item => !!item);
                this.checkDuplicate();
                this.sortErrors();
                this.clearFileInput(fileEl);
            } else {
                this.errors.push(new Error(0, "CSV is not valid!", "error"));
            }
            this.loading = false;
        }
    }

    chunkInsert(chunk) {
        return new Promise((resolve, reject) => {
            BaseService.invokeServiceMethod(insertMaintenance, chunk)
                .then(res => {
                    this.loadedChunks++;
                    console.warn(`loaded ${this.loadedChunks}/${this.chunksCount}`);
                    BaseService.pushEvent(
                        LOADER_EVENT_NAME,
                        { action: "loaded", loaded: this.loadedChunks, count: this.chunksCount },
                        window,
                    );
                    resolve(res);
                })
                .catch(e => {
                    BaseService.pushEvent(
                        LOADER_EVENT_NAME,
                        { action: "loaded", loaded: this.loadedChunks, count: this.chunksCount },
                        window,
                    );
                    console.warn(`loaded ${this.loadedChunks}/${this.chunksCount}`);
                    reject(e);
                });
        });
    }

    stepChunks(step, stepInx) {
        return Promise.all(step.map(chunk => this.chunkInsert(chunk.map(item => item.apex))))
            .then(values => {
                if (Array.isArray(values)) {
                    values.forEach((item, chunkInx) => {
                        for (let key in item) {
                            if (item.hasOwnProperty(key)) {
                                let itemCase = { id: "" };
                                try {
                                    itemCase = this.steps[stepInx][chunkInx][key * 1];
                                } catch (e) {
                                    console.error(e);
                                }
                                const itemInx = itemCase.id;
                                this.errors.push(new Error(itemInx, `[${itemInx}] ${item[key]}`, "error"));
                                this.importErrors++;
                            }
                        }
                    });
                }
                this.sortErrors();
                return values;
            })
            .catch(e => {
                console.error(e);
                return e;
            });
    }

    min(a, b) {
        return a < b ? a : b;
    }

    emptySlots(len) {
        let emptySlots = CASE_SIZE - len;
        return this.min(emptySlots, CHUNK_SIZE);
    }

    convertCasesToSteps() {
        const grouped = this.cases.reduce(function(r, a) {
            r[a.accountId] = r[a.accountId] || [];
            r[a.accountId].push(a);
            return r;
        }, Object.create(null));
        let steps = [];
        let transformed = this.caseCount;
        let step_inx = 0;
        while (transformed > 0) {
            let chunk_inx = 0;
            steps[step_inx] = [[]];
            for (let key in grouped) {
                let emptySlotsInStep = this.emptySlots(steps[step_inx][chunk_inx].length);
                let emptySlotsInChunk = this.min(CHUNK_SIZE - steps[step_inx][chunk_inx].length, emptySlotsInStep);
                if (emptySlotsInStep === 0) {
                    step_inx++;
                    chunk_inx = 0;
                    steps[step_inx] = [[]];
                    emptySlotsInStep = this.emptySlots(steps[step_inx][chunk_inx].length);
                }
                if (emptySlotsInChunk === 0) {
                    chunk_inx++;
                    steps[step_inx][chunk_inx] = [];
                    emptySlotsInChunk = this.min(CHUNK_SIZE - steps[step_inx][chunk_inx].length, emptySlotsInStep);
                }
                if (grouped[key].length > emptySlotsInChunk) {
                    steps[step_inx][chunk_inx] = steps[step_inx][chunk_inx].concat(
                        grouped[key].slice(0, emptySlotsInChunk),
                    );
                    transformed -= emptySlotsInChunk;
                    grouped[key] = grouped[key].slice(emptySlotsInChunk);
                    if (grouped[key].length === 0) {
                        delete grouped[key];
                    }
                } else {
                    steps[step_inx][chunk_inx] = steps[step_inx][chunk_inx].concat(grouped[key]);
                    transformed -= grouped[key].length;
                    delete grouped[key];
                }
            }
            step_inx++;
        }
        this.steps = steps;
    }

    async insertCases() {
        this.uiValidImport = true;
        this.loadedChunks = 0;
        this.importErrors = 0;
        this.convertCasesToSteps();
        this.errors = [];
        BaseService.pushEvent(LOADER_EVENT_NAME, { action: "show", count: this.caseCount }, window);
        for (let i = 0; i < this.steps.length; i++) {
            await this.stepChunks(this.steps[i], i);
        }
        BaseService.pushEvent(LOADER_EVENT_NAME, { action: "hide" }, window);
        if (this.importErrors === 0) {
            BaseService.showToast("success", "Imported successfully!");

            this.cases = [];
        } else if (this.cases.length > this.importErrors) {
            BaseService.showToast("warning", "Imported successfully, but with errors.");
        } else {
            BaseService.showToast("error", "Imported unsuccessfully!");
        }
        this.uiValidClear(0);
    }

    updateColumnSorting(event) {
        const fieldName = event.detail.fieldName;
        const sortDirection = event.detail.sortDirection;
        this.sortedBy = fieldName;
        this.sortedDirection = sortDirection;
    }

    handleChangeLimit({ detail }) {
        this.limit = detail.value * 1;
        this.currentPage = 1;
        BaseService.setCookie(LIMIT_COOKIE, this.limit);
    }

    handleChangePage({ detail }) {
        this.currentPage = detail.page;
    }

    handleChangeFile(evt) {
        const hasFile = evt.target.files.length > 0;
        this.uiSteps[0] = hasFile;
        if (hasFile) {
            this.cases = [];
            this.errors = [];
            this.uiValidClear(1);
            this.readFile();
        } else {
            this.uiValidClear(0);
        }

    }

    handleChangeCheck(evt) {
        this.uiValidCheckErrors = evt.target.checked;
        this.uiValidClear(2);
    }

    constructor() {
        super();
        this.csv = new CsvReader();
        this.cases = [];
        this.columns = [
            { label: "Id", fieldName: "id", type: "number", fixedWidth: 65, sortable: true },
            {
                label: "Warn",
                fixedWidth: 65,
                fieldName: "wIconVal",
                type: "string",
                sortable: true,
                cellAttributes:
                    {
                        iconName: { fieldName: "wIconName" },
                        iconAlternativeText: { fieldName: "wIconLabel" },
                    },
            },
            { label: "Subject", fieldName: "subject", initialWidth: 200, sortable: true },
            { label: "Description", fieldName: "description", initialWidth: 500, sortable: true },
            { label: "Date Assigned", fieldName: "dateAssigned", type: "date-local", sortable: true },
            { label: "Date Completed", fieldName: "dateCompleted", type: "date-local", sortable: true },
            { label: "Status", fieldName: "status", sortable: true },
            { label: "Priority", fieldName: "priority", sortable: true },
            { label: "Account POD", fieldName: "accountPOD", sortable: true },
            { label: "Origin", fieldName: "origin", sortable: true },
            { label: "Initial", fieldName: "initial", sortable: true },
            { label: "UID", fieldName: "uid", sortable: true },
            { label: "AccountId", fieldName: "accountId", sortable: true },
            { label: "inContact Cluster", fieldName: "inContactCluster", sortable: true },
        ];
        BaseService.invokeServiceMethodWithoutParameters(getPicklistValuesForFields)
            .then(res => res.picklistNameAndValues)
            .then(res => {
                this.picklists = res;
            });
        const cookie = BaseService.getCookie(LIMIT_COOKIE);
        if (cookie && this.limitOptions.filter(item => item.value === cookie * 1)) {
            this.limit = cookie * 1;
        }
    }
}