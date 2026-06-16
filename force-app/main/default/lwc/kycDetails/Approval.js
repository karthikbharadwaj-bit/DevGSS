import { Document } from './Document';
export class Approval {
    rawDocuments = [];
    constructor(record) {
        this.id = record.Id;
        this.name = record.Name;
        this.coDoSoWoHo = record.CoDoSoWoHo__c;
        this.houseNo = record.HouseNo__c;
        this.streetAddress = record.StreetAddress__c;
        this.landmark = record.Landmark__c;
        this.landmark = record.Area__c;
        this.city = record.City__c;
        this.disctrict = record.District__c;
        this.state = record.State__c;
        this.pinCode = record.PinCode__c;
        this.kycFiles = record.KycFiles__c;
        this.gstNo = record.GstNo__c;
        this.gstStateCodeOfCustomer = record.GstStateCodeOfCustomer__c;
        this.dateOfSign = record.DateOfSignOff__c;
        this.account = record.Account__r;
        this.status = record.Status__c;

        if (record.Documents__r) {
             record.Documents__r.forEach(doc => {
                this.rawDocuments.push(new Document(doc));
            });
        }
    }
}