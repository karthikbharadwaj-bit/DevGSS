export class BillingAddress {
    /*
     * Billing Address data stored in auto-created Local Subscribed Address record
     */
    constructor(record) {
        this.Id = record.Id;
        this.billingStreet = record.StreetAddress__c;
        this.billingCity = record.City__c;
        this.billingState = record.State__c;
        this.billingCountry = record.District__c;
        this.billingPostalCode = record.PinCode__c;
    }
}