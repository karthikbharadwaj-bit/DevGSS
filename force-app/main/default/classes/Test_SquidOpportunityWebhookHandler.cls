@isTest
public class Test_SquidOpportunityWebhookHandler {
    public class SquidServiceErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatus('Internal Server Error');
            res.setStatusCode(500);
            res.setBody('Error happened in processing the request');
            return res;
        }
    }
    @isTest
    static void testErrorResponseFunctionality() {
        Account testAccount = new Account(
            Name = 'Opty test account'
        );
        insert testAccount;
        Opportunity testOpp = new Opportunity(
            AccountId = testAccount.Id,
            Name = 'MyTestOpportunity',
            Type = 'Existing Business',
            CurrencyIsoCode = 'USD',
            StageName = '1. Qualify',
            Is_Billing_Opportunity__c = true
        );
        insert testOpp; 
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SquidServiceErrorMock());
        SquidOpportunityWebhookHandler.sendWebhook(new List<Id> {testOpp.Id});
        Opportunity result = [SELECT StageName FROM Opportunity WHERE Id = :testOpp.Id];
        System.assertEquals('1. Qualify', result.StageName, 'The Opportunity stage should remain as "1. Qualify" after the error');
        Test.stopTest();
    }
    @isTest
    static void testInvalidInputFunctionality() {
        List<Id> OpptyIDs = null;
        try {
            SquidOpportunityWebhookHandler.sendWebhook(OpptyIDs);
            System.assert(true, 'No exception should be thrown for null input');
        } catch (Exception e) {
            System.assert(false, 'Exception should not have been thrown for null input');
        }
        OpptyIDs = new List<Id>();
        try {
            SquidOpportunityWebhookHandler.sendWebhook(OpptyIDs);
            System.assert(true, 'No exception should be thrown for empty input');
        } catch (Exception e) {
            System.assert(false, 'Exception should not have been thrown for empty input');
        }
    }
}