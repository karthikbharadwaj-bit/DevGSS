@isTest
private class Test_AccountPaymentLimitsNGBSSync
{

    @testSetup
    static void commonTestSetup() {
        upsert new NGBS_Settings__c(
            BaseEndpoint__c = 'https://testapi/',
            AccountManagerPath__c = '/restapi/account-manager/v1.0',
            Login__c = '123',
            Password__c = '456'
        );
        Feature_Toggle__c toggle = Feature_Toggle__c.getOrgDefaults();
        toggle.AccountInvoiceBillingNGBSSync__c = true;
        insert toggle;
    }

    public class NgbsOkMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody('');
            return res;
        }
    }

    public class NgbsExceptionMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            throw new DmlException();
        }
    }

    public class NgbsNotSuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatus('ERROR');
            res.setStatusCode(400);
            res.setBody('');
            return res;
        }
    }

    @isTest
    static void testNormalFlow() {
        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new NgbsOkMock());
        QueueableBase.enqueJob('AccountPaymentLimitsNGBSSync', new List<Account>{getAccountForTests()});

        Test.stopTest();
        System.assertEquals(0, ([SELECT Id FROM PlatformLog__c WHERE Source__c = 'AccountPaymentLimitsNGBSSync']).size(), 'should not create any log records upon successfull run');
    }

    @isTest
    static void testExceptionFlow() {
        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new NgbsExceptionMock());
        QueueableBase.enqueJob('AccountPaymentLimitsNGBSSync', new List<Account>{getAccountForTests()});

        Test.stopTest();
        System.assertEquals(1, ([SELECT Id FROM PlatformLog__c WHERE Source__c = 'AccountPaymentLimitsNGBSSync']).size(), 'should create a log record when an exception occurs');
    }

    @isTest
    static void testNotSuccessFlow() {
        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new NgbsNotSuccessMock());
        QueueableBase.enqueJob('AccountPaymentLimitsNGBSSync', new List<Account>{getAccountForTests()});

        Test.stopTest();
        System.assertEquals(1, ([SELECT Id FROM PlatformLog__c WHERE Source__c = 'AccountPaymentLimitsNGBSSync']).size(), 'should create a log record when ngbs returned not 200 success message');
    }


    static Account getAccountForTests() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'testAcc',
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.RC_Account_Status__c => AccountHelper.PAID_STATUS
            })
            .create()
            .getRecord();


        Account acc2 = new Account(
            Name = 'testAcc2',
            Billing_ID__c = '54321',
            BillingStreet = 'street',
            BillingState = 'state',
            BillingPostalCode = '123',
            BillingCountry = 'USA',
            BillingCity = 'City',
            Phone = '123467445'
        );
        insert acc2;

        Package__c pack = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Account__c => acc.Id,
                Package__c.Enterprise_Account_ID__c => acc2.Id,
                Package__c.Account_Package_Id__c => acc2.Billing_ID__c
            })
            .build()
            .getRecord();
        insert pack;

        return acc;
    }

}