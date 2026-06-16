@isTest
public class TestPartner_UpdateDSOwner_V1 { 
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')   
    @isTest
    public static void changeownerpartnerqueue() {
    
            // Creating Account Record for Var Opportunity
            Account accountRecordcc = new Account();
            accountRecordcc.Permitted_Brands__c = 'RingCentral'; 
            accountRecordcc.Name = 'Test Customer Account';
            accountRecordcc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account').getRecordTypeId();
            insert accountRecordcc;
    
            // Creating Partner Account Record
            Account accountRecord = new Account();
            accountRecord.Permitted_Brands__c = 'RingCentral'; 
            accountRecord.Name = 'Test';
            accountRecord.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner Account').getRecordTypeId();
            insert accountRecord;
    
            
            //Creating Opportunity
            Opportunity OppRecord = new Opportunity();
            OppRecord.Name = 'Test Opportunity';
            OppRecord.AccountId = accountRecordcc.Id;
            OppRecord.LeadSource = 'Partner';
            OppRecord.Type = 'Existing Business';
            OppRecord.StageName = '1. Qualify';
            OppRecord.Sales_Model__c = 'Direct';
            OppRecord.CloseDate = System.Today() + 10;
            OppRecord.CurrencyIsoCode = 'USD';
            OppRecord.Brand_Name__c= 'RingCentral';
            OppRecord.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('VAR Opportunity').getRecordTypeId();
            insert OppRecord;
            
           
            Deal_Support__c dealRecord1 = new Deal_Support__c(Partner_Account__c = accountRecord.Id, Opportunity__c = OppRecord.Id);
            insert dealRecord1;
            Partner_UpdateDSOwner_V1.changeownerpartnerqueue(dealRecord1.Id, '', true);
            Partner_UpdateDSOwner_V1.changeownerdealdesk(dealRecord1.Id, true);
        
            Account accountRecord2 = new Account();
            accountRecord2.Permitted_Brands__c = 'RingCentral'; 
            accountRecord2.Name = 'Test';
            accountRecord2.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner Account').getRecordTypeId();
            insert accountRecord2;
            
            Deal_Support__c dealRecord2 = new Deal_Support__c(Partner_Account__c = accountRecord2.Id);
            insert dealRecord2;
            Partner_UpdateDSOwner_V1.changeownerpartnerqueue(dealRecord2.Id, '', true);
            Partner_UpdateDSOwner_V1.changeownerdealdesk(dealRecord2.Id, true);
            
            Partner_UpdateDSOwner_V1.changeownerpartnerqueue(dealRecord2.Id, '', false);
            Partner_UpdateDSOwner_V1.changeownerdealdesk(dealRecord2.Id, false);
    }
}