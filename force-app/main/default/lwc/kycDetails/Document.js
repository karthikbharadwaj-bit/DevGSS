export class Document {
    constructor(record) {
        this.id = record.Id;
        this.approvalId = record.Approval__c;
        this.dateOfIssue = record.DateOfIssue__c;
        this.documentNo = record.DocumentNo__c;
        this.issuingAuthority = record.IssuingAuthority__c;
        this.placeOfIssue = record.PlaceOfIssue__c;
        this.type = record.Type__c;
    }
}