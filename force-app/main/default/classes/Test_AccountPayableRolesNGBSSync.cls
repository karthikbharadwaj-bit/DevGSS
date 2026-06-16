@isTest
private class Test_AccountPayableRolesNGBSSync
{
    @testSetup
    static void prepare() {
        upsert new NGBS_Settings__c(
            BaseEndpoint__c = 'https://testapi/',
            AccountManagerPath__c = '/restapi/account-manager/v1.0',
            Login__c = '123',
            Password__c = '456'
        );
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
    static void testNormalFlow()
    {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new NgbsOkMock());
            QueueableBase.enqueJob('AccountPayableRolesNGBSSync', new List<Approval__c>{getNormalApprovalRec()});
        Test.stopTest();
        System.assertEquals(0, ([SELECT Id FROM PlatformLog__c WHERE Source__c = 'AccountPayableRolesNGBSSync']).size(), 'should not create any log records upon successfull run');
    }

    @isTest
    static void testExceptionFlow()
    {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new NgbsExceptionMock());
            QueueableBase.enqueJob('AccountPayableRolesNGBSSync', new List<Approval__c>{getNormalApprovalRec()});
        Test.stopTest();
        System.assertEquals(1, ([SELECT Id FROM PlatformLog__c WHERE Source__c = 'AccountPayableRolesNGBSSync']).size(), 'should create a log record when an exception occurs');
    }

    @isTest
    static void testNgbsNotSuccess()
    {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new NgbsNotSuccessMock());
            QueueableBase.enqueJob('AccountPayableRolesNGBSSync', new List<Approval__c>{getNormalApprovalRec()});
        Test.stopTest();
        System.assertEquals(1, ([SELECT Id FROM PlatformLog__c WHERE Source__c = 'AccountPayableRolesNGBSSync']).size(), 'should create a log record when ngbs returned not 200 success message');
    }

    static Approval__c getNormalApprovalRec() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc',
                    Account.BillingPostalCode => 'testCode',
                    Account.BillingCity => 'testCity',
                    Account.BillingCountry => 'testCountry',
                    Account.BillingState => 'testState',
                    Account.BillingStreet => 'testStreet',
                    Account.Billing_ID__c => '1111222222'
                }
            )
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

        Approval__c approvalRecord = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Account__c => acc.Id,
                    Approval__c.AccountPayableContact__c => contact.Id
                }
            )
            .create()
            .getRecord();
        
        return approvalRecord;
    }
}