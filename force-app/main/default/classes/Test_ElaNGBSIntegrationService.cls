@IsTest
public with sharing class Test_ElaNGBSIntegrationService {
    private static final String SERVICE_ACCOUNT_BILLING_ID = '4571600002';
    private static final String SERVICE_PACKAGE_ID = '4526708002';
    private static final String BILLING_PACKAGE_ID = '4526708003';
    private static final String BILLING_ACCOUNT_NAME = 'Billing Account';
    private static final String SERVICE_ACCOUNT_NAME = 'Service Account';
    private static final String EMPTY_RESULT_EXPECTED = 'Result list should contain no Accounts';
    private static final String NOT_EMPTY_RESULT_EXPECTED = 'Result list should contain at least one Account';

    private static Boolean wasCalloutDone = false;

    @TestSetup
    private static void createTestData() {
        Account billingAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, String>{
                Account.Name => BILLING_ACCOUNT_NAME,
                Account.ELA_Account_Type__c => AccountHelper.ACCOUNT_TYPE_ELA_BILLING,
                Account.RC_Account_Status__c => AccountHelper.PAID_STATUS
            })
            .create()
            .getRecord();

        Account serviceAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, String>{
                Account.Name => SERVICE_ACCOUNT_NAME,
                Account.Billing_ID__c => SERVICE_ACCOUNT_BILLING_ID,
                Account.ELA_Account_Type__c => AccountHelper.ACCOUNT_TYPE_ELA_SERVICE,
                Account.RC_Account_Status__c => AccountHelper.PAID_STATUS
            })
            .create()
            .getRecord();

        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.FirstName => 'Test1',
                Contact.LastName => 'Test1',
                Contact.AccountId => serviceAccount.Id,
                Contact.Email => 'test1@test.com',
                Contact.Phone => '1234567890',
                Contact.Preferred_Language__c => 'en_US'
            })
            .create()
            .getRecord();

        AccountContactRole accountContactRole1 = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                AccountContactRole.AccountId => billingAccount.Id,
                AccountContactRole.ContactId => testContact.Id
            })
            .create()
            .getRecord();

        AccountContactRole accountContactRole2 = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                AccountContactRole.AccountId => serviceAccount.Id,
                AccountContactRole.ContactId => testContact.Id
            })
            .create()
            .getRecord();

        new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, String>{
                Package__c.Account_Package_Id__c => BILLING_PACKAGE_ID,
                Package__c.Account__c => billingAccount.Id
            })
            .create();

        new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, String>{
                Package__c.Account_Package_Id__c => SERVICE_PACKAGE_ID,
                Package__c.Account__c => serviceAccount.Id
            })
            .create();

        new SObjectBuilder(AccountRelation__c.SObjectType)
            .setFields(new Map<SObjectField, String>{
                AccountRelation__c.Parent_Account__c => billingAccount.Id,
                AccountRelation__c.Child_Account__c => serviceAccount.Id,
                AccountRelation__c.Relation_Type__c => AccountHelper.RELATION_TYPE_ELA
            })
            .create();

        insert new NGBS_Settings__c(
            BaseEndpoint__c ='http://185.23.251.118:8080',
            AccountManagerPath__c = '/restapi/account-manager/v1.0',
            Login__c='salesforce',
            Password__c='salesforce'
        );
    }

    public class MockApiNGBS implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {

            wasCalloutDone = true;

            String elaSettingsUrlNGBS =  String.format(
                NGBSAPI.NGBS_PACKAGE_ELA_SETTINGS_UPDATE,
                new List<String>{SERVICE_ACCOUNT_BILLING_ID, SERVICE_PACKAGE_ID}
            );

            String requestBody = '{"type":"Service","parentId":"' + BILLING_PACKAGE_ID + '"}';

            System.assertEquals(elaSettingsUrlNGBS, req.getEndpoint(), 'Request URL formed with issues');
            System.assertEquals(HttpHelper.METHOD_POST, req.getMethod(), 'Wrong request method');
            System.assertEquals(requestBody, req.getBody(), 'Body formed with issues');

            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"OK"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @IsTest
    private static void testHandleElaDataSending() {
        Test.setMock(HttpCalloutMock.class, new MockApiNGBS());

        List<Account> billingAccounts = getAccountsByName(BILLING_ACCOUNT_NAME);

        update new Account(
            Id = billingAccounts[0].Id,
            RC_Account_Status__c = null
        );

        Test.startTest();

        update new Account(
            Id = billingAccounts[0].Id,
            RC_Account_Status__c = AccountHelper.PAID_STATUS
        );

        Test.stopTest();

        System.assert(wasCalloutDone, 'Some issue canceled callout sending');
    }

    @IsTest
    private static void testGetBillingPaidAccountsWithPackages() {
        ElaNGBSIntegrationService elaNGBSIntegrationService = new ElaNGBSIntegrationService();

        List<Account> billingAccounts = getAccountsByName(BILLING_ACCOUNT_NAME);

        List<Account> billingPaidAccounts = elaNGBSIntegrationService.getBillingPaidAccountsWithPackages(new Map<Id, Account>(billingAccounts).keySet());

        System.assert( ! billingPaidAccounts.isEmpty(), NOT_EMPTY_RESULT_EXPECTED);

        for (Account billingPaidAccount : billingPaidAccounts) {
            System.assert( ! billingPaidAccount.Service_Accounts__r.isEmpty(), 'All billing accounts should have related package');
        }
    }

    @IsTest
    private static void testGetParentAccountsWithPackages() {
        ElaNGBSIntegrationService elaNGBSIntegrationService = new ElaNGBSIntegrationService();

        List<Account> serviceAccounts = getAccountsByName(SERVICE_ACCOUNT_NAME);

        List<Account> billingPaidAccounts = elaNGBSIntegrationService.getParentAccountsWithPackages(new Map<Id, Account>(serviceAccounts).keySet());

        System.assert( ! billingPaidAccounts.isEmpty(), NOT_EMPTY_RESULT_EXPECTED);

        for (Account billingPaidAccount : billingPaidAccounts) {
            System.assert( ! billingPaidAccount.Service_Accounts__r.isEmpty(), 'All service accounts should have related package');
        }
    }

    @IsTest
    private static void testGetServiceHasNoPack() {
        ElaNGBSIntegrationService elaNGBSIntegrationService = new ElaNGBSIntegrationService();

        List<Account> serviceAccounts = getAccountsByName(BILLING_ACCOUNT_NAME);

        delete [SELECT Id FROM Package__c WHERE Account_Package_Id__c = :BILLING_PACKAGE_ID];

        List<Account> billingPaidAccounts = elaNGBSIntegrationService.getBillingPaidAccountsWithPackages(new Map<Id, Account>(serviceAccounts).keySet());

        System.assert(billingPaidAccounts.isEmpty(), EMPTY_RESULT_EXPECTED);
    }

    @IsTest
    private static void testServiceAccountWasNotPaid() {
        ElaNGBSIntegrationService elaNGBSIntegrationService = new ElaNGBSIntegrationService();

        List<Account> billingAccounts = getAccountsByName(BILLING_ACCOUNT_NAME);
        List<Account> serviceAccounts = getAccountsByName(SERVICE_ACCOUNT_NAME);

        update new Account(
            Id = serviceAccounts[0].Id,
            RC_Account_Status__c = null
        );

        List<Account> servicePaidAccounts = elaNGBSIntegrationService.getServiceAccountsWithPackages(new Map<Id, Account>(billingAccounts).keySet());

        System.assert(servicePaidAccounts.isEmpty(), EMPTY_RESULT_EXPECTED);
    }

    @IsTest
    private static void testParentAccountWasNotPaid() {
        ElaNGBSIntegrationService elaNGBSIntegrationService = new ElaNGBSIntegrationService();

        List<Account> billingAccounts = getAccountsByName(BILLING_ACCOUNT_NAME);
        List<Account> serviceAccounts = getAccountsByName(SERVICE_ACCOUNT_NAME);

        update new Account(
            Id = billingAccounts[0].Id,
            RC_Account_Status__c = null
        );

        List<Account> billingPaidAccounts = elaNGBSIntegrationService.getParentAccountsWithPackages(new Map<Id, Account>(serviceAccounts).keySet());

        System.assert(billingPaidAccounts.isEmpty(), EMPTY_RESULT_EXPECTED);
    }

    private static List<Account> getAccountsByName(String accountName) {
        return (List<Account>) new AccountSelector()
            .selectAccountByName(new List<String>{accountName})
            .executeQuery();
    }
}