export class Case {
    id;
    caseNumber;
    subject;
    createdDate;
    contactName;
    status;
    caseDetailsPageUrl;
    get link() {
        return this.caseDetailsPageUrl + this.id;
    }
    constructor(params, caseDetailsPageUrl) {
        try {
            this.id = params.id;
            this.caseNumber = params.caseNumber;
            this.subject = params.subject;
            this.createdDate = params.createdDate;
            this.contactName = params.contactName;
            this.status = params.status;
        } catch (e) {
            console.error(e);
        }
        this.caseDetailsPageUrl = caseDetailsPageUrl;
    }
}