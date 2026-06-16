export class Case {
    get caseNumber() {return this.record.CaseNumber || null;}
    get contactName() {return this.record.Contact.Name || null;}
    get contactEmail() {return this.record.Contact.Email || null;}
    get Id() {return this.record.Id || null;}
    get uid() { return this.Id || new Date().getTime() + Math.random();}
    get caseLink() {
        return (this.Id && !this.isMaintenance) ? (this.link + this.Id) : null;
    }
    get title() {return this.record.Subject || this.caseNumber;}
    get severityLevel() {return this.record.Case_Severity__c || '';}
    get details(){return this.record.Description || '';}
    get type(){return this.record.type || 'Case';}
    get created() {return new Date(this.record.CreatedDate) || new Date();}
    get modify() {
        return ( this.isMaintenance ? this.created : new Date(this.record.LastModifiedDate)) || new Date();
    }
    get opened() { return Math.round((this.created.getTime() + 1000) / 1000);}
    get status() {return this.record.Status || '';}
    get isOpen() {return this.record.isOpen || '';}
    get isMaintenance() {
        return this.type === 'Maintenance';
    }
    constructor(sObject, link){
        this.record = sObject || {Contact:{}, RecordType: {}};
        this.link = link || './case-detail?caseId=';
    }
}