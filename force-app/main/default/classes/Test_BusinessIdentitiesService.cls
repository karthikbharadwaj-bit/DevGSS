/**
 * Created by Dmitriy.Borisov on 3/21/2020.
 */

@IsTest
private class Test_BusinessIdentitiesService {

    private static String billingIdentitiesResponse = '[{"id": 1,"name": "RingCentral, Ltd (France)",' +
        '"address": {"label": null,"firstName": "RingCentral France","lastName": "",' +
        '"phone": "","street1": "3-5 rue Saint Georges","street2": "",' +
        '"city": "Paris","county": "","state": "","zip": "75009","country": "FRA"},' +
        '"isDefault": true}]';

    @TestSetup
    static void createData() {
        List<Account> accounts = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'Test Account',
                    Account.RecordTypeId => AccountHelper.RT_ID_CUSTOMER_ACCOUNT,
                    Account.BillingCountry => ValueProviderBuilder.provideList(new List<String>{'AUT', 'USA'}),
                    Account.BillingStreet => 'Lenin',
                    Account.BillingCity => 'Chicago',
                    Account.BillingState => 'Alabama',
                    Account.BillingPostalCode => '12345'})
            .create()
            .getRecords();

        List<Contact> contacts = (List<Contact>) new SObjectBuilder(Contact.SObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.RecordTypeId => ContactHelper.RT_ID_VAR_VISIBLE,
                    Contact.LastName => 'test',
                    Contact.FirstName => 'test',
                    Contact.Preferred_Language__c => 'en_US',
                    Contact.AccountId => ValueProviderBuilder.provideList(new List<Id>{accounts[0].Id, accounts[1].Id})
                })
            .create()
            .getRecords();

        List<Opportunity> opportunities = (List<Opportunity>) new SObjectBuilder(Opportunity.SObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => ValueProviderBuilder.provideList(new List<String> {OpportunityHelper.BRAND_RINGCENTRAL_EU, OpportunityHelper.BRAND_RINGCENTRAL}),
                    Opportunity.AccountId => ValueProviderBuilder.provideList(new List<Id>{accounts[0].Id, accounts[1].Id})})
            .create()
            .getRecords();

        List <Approval__c> approvals =  (List <Approval__c>) new SObjectBuilder(Approval__c.SObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Name => 'Tax Exempt Approval',
                    Approval__c.RecordTypeId => ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL,
                    Approval__c.Account__c => ValueProviderBuilder.provideList(new List<Id>{accounts[0].Id, accounts[1].Id}),
                    Approval__c.Contact__c => ValueProviderBuilder.provideList(new List<Id>{contacts[0].Id, contacts[1].Id}),
                    Approval__c.Status__c => ApprovalHelper.STATUS_APPROVED,
                    Approval__c.VATExemption__c => ValueProviderBuilder.provideList(new List<String>{ApprovalHelper.STATUS_APPROVED, null}),
                    Approval__c.CountyTaxExemption__c => ValueProviderBuilder.provideList(new List<String>{null, ApprovalHelper.STATUS_APPROVED}),
                    Approval__c.FederalTaxExemption__c => ValueProviderBuilder.provideList(new List<String>{null, ApprovalHelper.STATUS_APPROVED}),
                    Approval__c.LocalTaxExemption__c => ValueProviderBuilder.provideList(new List<String>{null, ApprovalHelper.STATUS_APPROVED}),
                    Approval__c.SalesTaxExemption__c => ValueProviderBuilder.provideList(new List<String>{null, ApprovalHelper.STATUS_APPROVED}),
                    Approval__c.StateTaxExemption__c => ValueProviderBuilder.provideList(new List<String>{null, ApprovalHelper.STATUS_APPROVED}),
                    Approval__c.SEZWOPExemption__c => ValueProviderBuilder.provideList(new List<String>{null, ApprovalHelper.STATUS_APPROVED}),
                    Approval__c.VATNumber__c => ValueProviderBuilder.provideList(new List<String> {'23423255', ''}),
                    Approval__c.Opportunity__c => ValueProviderBuilder.provideList(new List<Id> {opportunities[0].Id, opportunities[1].Id}),
                    Approval__c.VATCountryForCheck__c => ValueProviderBuilder.provideList(new List<String> {'AT', ''})})
            .create()
            .getRecords();

        new SObjectBuilder(NGBS_Settings__c.SObjectType)
            .setField(NGBS_Settings__c.BaseEndpoint__c, 'http://185.23.251.118:8080')
            .setField(NGBS_Settings__c.AccountManagerPath__c, '/restapi/account-manager/v1.0')
            .setField(NGBS_Settings__c.Login__c, 'login')
            .setField(NGBS_Settings__c.Password__c, 'password')
            .create();

        new SObjectBuilder(CountryCodes__c.SObjectType)
            .setField(CountryCodes__c.CountryName__c, 'aut;austria')
            .setField(CountryCodes__c.CountryNameShort__c, 'AT')
            .setField(CountryCodes__c.Name, 'AUT')
            .create();
    }

    @isTest
    static void testGetResponseBody() {
        Test.setMock(HttpCalloutMock.class, new MockBusinessIdentitites());
        String response;
        Test.startTest();
        response = BusinessIdentitiesService.getResponseBody('65');
        Test.stopTest();

        System.assertEquals(response, billingIdentitiesResponse);
    }

    @isTest
    static void testParseResponseBody() {
        Test.setMock(HttpCalloutMock.class, new MockBusinessIdentitites());
        String response;
        List<BillingWrappers.BusinessIdentity> bidentities;
        Test.startTest();
        response = BusinessIdentitiesService.getResponseBody('65');
        bidentities = BusinessIdentitiesService.parseResponseBody(response);
        Test.stopTest();

        System.assertEquals(1, bidentities.size());
    }

    @isTest
    static void testUpdateApproval() {
        Test.setMock(HttpCalloutMock.class, new MockBusinessIdentitites());
        List<Approval__c> approvalList = new ApprovalSelector()
            .selectTaxExemptionApprovals()
            .executeQuery();

        Id jobId;
        AsyncApexJob jobInfo;
        String comment = 'Test';
        BusinessIdentitiesService bis = new BusinessIdentitiesService(approvalList, comment);

        Test.startTest();
        jobId = System.enqueueJob(bis);
        jobInfo = [SELECT Id, Status, NumberOfErrors FROM AsyncApexJob WHERE Id = :System.enqueueJob(bis)];
        Test.stopTest();

        List<Approval__c> approvalListRejected = new ApprovalSelector()
            .selectTaxExemptionApprovals()
            .executeQuery();

        if(jobInfo.Status == 'Completed') {
            System.assertEquals(ApprovalHelper.STATUS_REJECTED, approvalListRejected[0].Status__c);
            System.assertEquals(ApprovalHelper.STATUS_REJECTED, approvalListRejected[1].Status__c);
            System.assertEquals(ApprovalHelper.STATUS_REJECTED, approvalListRejected[0].VATExemption__c);
            System.assertEquals(ApprovalHelper.STATUS_REJECTED, approvalListRejected[1].CountyTaxExemption__c);
            System.assertEquals(ApprovalHelper.STATUS_REJECTED, approvalListRejected[1].FederalTaxExemption__c);
            System.assertEquals(ApprovalHelper.STATUS_REJECTED, approvalListRejected[1].LocalTaxExemption__c);
            System.assertEquals(ApprovalHelper.STATUS_REJECTED, approvalListRejected[1].SalesTaxExemption__c);
            System.assertEquals(ApprovalHelper.STATUS_REJECTED, approvalListRejected[1].StateTaxExemption__c);
            System.assertEquals(ApprovalHelper.STATUS_REJECTED, approvalListRejected[1].SEZWOPExemption__c);
        }
    }

    public class MockBusinessIdentitites implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody(billingIdentitiesResponse);
            return res;
        }
    }
}