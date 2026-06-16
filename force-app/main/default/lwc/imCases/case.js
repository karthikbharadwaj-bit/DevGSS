import { Error } from "./error";

export class Case {
    err = [];

    get apex() {
        return {
            "Subject": this.subject,
            "Description": this.description,
            "Priority": this.priority,
            "Date_Assigned__c": this.dateAssigned,
            "Date_Completed__c": this.dateCompleted,
            "Status": this.status,
            "Account_POD__c": this.accountPOD,
            "Origin": this.origin,
            "Initial__c": this.initial,
            "AccountId": this.accountId,
            "inContact_Cluster__c": this.inContactCluster,
        };
    }

    get fields() {
        return Object.keys(this.apex);
    }

    get errors() {
        if (this.err.length > 0) {
            return new Error(
                this.id,
                `[${this.id}] Field(s) ${this.err.join(",")} is not valid!`,
                this.canImport ? "warning" : "error",
            );
        } else {
            return null;
        }
    }

    get caseUniqData() {
        return `${this.accountId} ${this.dateAssigned} ${this.subject}`;
    }

    set errors(val) {
        this.err.push(val);
    }

    get wIconName() {
        return this.canImport ? (this.valid ? null : "utility:warning") : "utility:error";
    }

    get wIconLabel() {
        return this.canImport ? (this.valid ? null : "Warning") : "Error";
    }

    get wIconLevel() {
        return this.canImport ? (this.valid ? 3 : 2) : 1;
    }

    get wIconVal() {
        return "";
    }

    pZ(a) {
        return a < 10 ? `0${a}` : a;
    }

    getStringDate(date) {
        return `${date.getFullYear()}-${this.pZ(date.getMonth() + 1)}-${this.pZ(date.getDate())}`;
    }

    hasValidFormat(date) {
        // Case10406239: Checks that date is of format (in order) MM-dd-YYYY, MM/dd/YYYY, YYYY-MM-dd or YYYY/MM/dd
        return /^((\d{1,2})[\-](\d{1,2})[\-](\d{4}))$/.test(date)
            || /^((\d{1,2})[\/](\d{1,2})[\/](\d{4}))$/.test(date)
            || /^((\d{4})[\-](\d{1,2})[\-](\d{1,2}))$/.test(date)
            || /^((\d{4})[\/](\d{1,2})[\/](\d{1,2}))$/.test(date);
    }

    validateDate(date, field) {
        try {
            const d = new Date(date);
            const parsedDate = this.getStringDate(d);
            if (this.hasValidFormat(date)) {
                return parsedDate;
            } else {
                throw new Error("Date is not valid");
            }
        } catch (e) {
            console.error(e);
            this.valid = false;
            this.canImport = false;
            this.errors = field;
            return null;
        }
    }

    addAccountId(listIds) {
        if (this.uid) {
            this.accountId = listIds[this.uid] || null;
            if (!this.accountId) {
                this.valid = false;
                this.errors = "AccountId";
            }
        }
    }

    checkValueInPicklist(field, value) {
        if (this.picklists.hasOwnProperty(field) && value !== null) {
            return this.picklists[field].filter(item => item.toLowerCase() === value.toLowerCase()).length > 0;
        } else {
            return true;
        }
    }

    checkPicklists() {
        const apex = this.apex;
        const fields = this.fields;
        fields.forEach(field => {
            const fieldName = field.replace("__c", "");
            if (!this.checkValueInPicklist(fieldName, apex[field])) {
                this.canImport = false;
                this.errors = fieldName;
            }
        });
    }

    constructor({ Subject, Description, Priority, Date_Assigned, Date_Completed, Status, Account_POD, Origin, Initial, UID, inContact_Cluster }, id, picklists) {
        this.picklists = picklists || {};
        this.id = id;
        this.accountId = null;
        this.valid = true;
        this.canImport = true;
        this.subject = Subject || null;
        this.description = Description || null;
        this.priority = Priority || null;
        this.dateAssigned = (Date_Assigned && this.validateDate(Date_Assigned, "Date Assigned")) || this.getStringDate(new Date());
        this.dateCompleted = (Date_Completed && this.validateDate(Date_Completed, "Date Completed")) || null;
        this.status = Status || "New";
        this.accountPOD = Account_POD || null;
        this.origin = Origin || null;
        this.initial = Initial || "N/A";
        this.uid = UID || null;
        this.inContactCluster = inContact_Cluster || null;
        this.checkPicklists();
    }

}