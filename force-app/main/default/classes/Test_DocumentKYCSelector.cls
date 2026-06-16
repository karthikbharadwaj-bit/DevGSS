@IsTest
public with sharing class  Test_DocumentKYCSelector {
    @testSetup
    static void setup() {
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Opportunity.CurrencyIsoCode => OpportunityHelper.CURRENCY_NAME_INR,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL_EU
            })
            .create()
            .getRecord();
    }

    @IsTest
    private static void testSelectDocuments() {
        /* 1) KYC Approval is autocreated when Opportunity is created
         * 2) 3 Document records are autocreated when KYC Approval record is created
         */
        Test.startTest();
            List<Document__c> documents = (List<Document__c>) new DocumentKYCSelector()
                .selectDocuments()
                .executeQuery();
        Test.stopTest();
        System.assertEquals(3, documents.size(), 'All available Document records should be retrieved');
    }

    @IsTest
    private static void testSelectDocumentsByApprovalId() {
        /* 1) KYC Approval is autocreated when Opportunity is created
         * 2) 3 Document records are autocreated when KYC Approval record is created
         */
        Approval__c app = (Approval__c) new ApprovalSelector()
            .selectApprovals()
            .executeQuery()
            .get(0);
        Test.startTest();
            List<Document__c> documents = (List<Document__c>) new DocumentKYCSelector()
                .selectDocumentsByApprovalId(new List<Object>{new Set<Id>{app.Id}})
                .executeQuery();
        Test.stopTest();
        System.assertEquals(3, documents.size(), 'There should exist 3 documents under the Approval record');
    }
}