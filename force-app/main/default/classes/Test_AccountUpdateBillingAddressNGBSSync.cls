@isTest
public class Test_AccountUpdateBillingAddressNGBSSync {
    private static final String BILLING_ID = '1234567';
    private static final String WRONG_BILLING_ID = '0000000';
    private static final String ACCOUNT_NAME = 'Test Account';
    private static final String BILLING_ACCOUNT_NAME = 'Test Billing Account';
    private static final String WRONG_BILLING_ACCOUNT_NAME = 'Test Wrong Billing Account';


    @testSetup
    static void generateData() {
        insert new NGBS_Settings__c(
            BaseEndpoint__c = 'https://testapi/',
            AccountManagerPath__c = '/restapi/account-manager/v1.0',
            Login__c = '123',
            Password__c = '123'
        );

        List<Account> accList = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ValueProviderBuilder.provideList(new List<String> {
                    ACCOUNT_NAME, BILLING_ACCOUNT_NAME, WRONG_BILLING_ACCOUNT_NAME
                }),
                Account.Billing_ID__c => ValueProviderBuilder.provideList(new List<String> {
                    '', BILLING_ID, WRONG_BILLING_ID
                })
            })
            .quantity(3)
            .create()
            .getRecords();

        List<Contact> testContact = (List<Contact>) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.FirstName => 'Test Name',
                Contact.LastName => 'Test Last Name',
                Contact.AccountId => ValueProviderBuilder.provideList(new List<Id>{accList[1].Id, accList[2].Id}),
                Contact.Email => 'test@test.com',
                Contact.Phone => '1234567890',
                Contact.Preferred_Language__c => 'en_US'
            })
            .quantity(2)
            .create()
            .getRecords();

        List<AccountContactRole> testAccountContactRole = (List<AccountContactRole>) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                AccountContactRole.AccountId => ValueProviderBuilder.provideList(new List<Id>{accList[1].Id, accList[2].Id}),
                AccountContactRole.ContactId => ValueProviderBuilder.provideList(new List<Id>{testContact[0].Id, testContact[1].Id}),
                AccountContactRole.IsPrimary => true,
                AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_SIGNATORY
            })
            .quantity(2)
            .create()
            .getRecords();
    }

    public class Mock implements HttpCalloutMock {
        private final String BILLING_ADDRESS_RESP = '{' +
            '    "label": null,' +
            '    "firstName": "Frank",' +
            '    "lastName": "Test",' +
            '    "phone": "",' +
            '    "email": null,' +
            '    "street1": "34 Test Street",' +
            '    "street2": null,' +
            '    "city": "Bangalore",' +
            '    "county": null,' +
            '    "state": "AR",' +
            '    "zip": "11221",' +
            '    "country": "India"' +
            '}';
        private final String GST_NO_RESP = '{' +
            '  "GSTNumber": "",' +
            '  "SEZWOPExemption": true,' +
            '  "VATExemption": true,' +
            '  "VATNumber": "",' +
            '  "VATCountry": "IND",' +
            '  "federalTaxExemption": true,' +
            '  "stateTaxExemption": true,' +
            '  "countyTaxExemption": true,' +
            '  "localTaxExemption": true' +
            '}';

        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatus('OK');
            res.setStatusCode(200);

            String endpoint = req.getEndpoint();
            if (endpoint.endsWith(BILLING_ID + '/tax-settings')) {
                res.setBody(GST_NO_RESP);
            }
            if (endpoint.endsWith(BILLING_ID + '/address?type=Billing')) {
                res.setBody(BILLING_ADDRESS_RESP);
            }
            if (endpoint.endsWith(WRONG_BILLING_ID + '/address?type=Billing')) {
                res.setStatusCode(400);
                res.setStatus('BadRequest');
            }
            return res;
        }
    }

    @isTest
    static void testSyncWithoutBillingId() {
        Account acc = (Account) new AccountSelector()
            .selectAccountByName(new List<Object>{ACCOUNT_NAME})
            .executeQuery()
            .get(0);

        Test.startTest();
        QueueableBase.enqueJob('AccountUpdateBillingAddressNGBSSync', new List<sObject>{acc});
        List<PlatformLog__c> logs = (List<PlatformLog__c>) new QueryFactory(PlatformLog__c.SObjectType)
            .selectFields(new Set<String> {'Id', 'Error__c', 'InboundMessage__c', 'OutboundMessage__c', 'Source__c', 'StackTrace__c'})
            .executeQuery();
        Test.stopTest();

        System.assert(logs.isEmpty(), 'Account without BillingId shouldn\'t be synced with NGBS');
    }

    @isTest
    static void testSyncWithoutBillingAddress() {
        Account acc = (Account) new AccountSelector()
            .selectAccountByName(new List<Object>{ BILLING_ACCOUNT_NAME })
            .selectFields(new Set<String> {'BillingStreet', 'BillingCity', 'BillingPostalCode', 'Phone'})
            .subselect(new AccountContactRoleSelector().selectAccountContactRolesForOpportunityClose().setCondition('isPrimary = true'))
            .executeQuery()
            .get(0);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new Mock());
        QueueableBase.enqueJob('AccountUpdateBillingAddressNGBSSync', new List<sObject>{acc});
        Test.stopTest();

        List<PlatformLog__c> logs = (List<PlatformLog__c>) new QueryFactory(PlatformLog__c.SObjectType)
            .selectFields(new Set<String> {'Id', 'Error__c', 'InboundMessage__c', 'OutboundMessage__c', 'Source__c', 'StackTrace__c'})
            .executeQuery();

        System.assertEquals(
            1,
            logs.size(),
            'Should create logs as no billing address on account and account was not updated in Salesforce'
        );
        System.assert(logs[0].StackTrace__c.contains('Address information not valid for updating Billing Address'), 'Account has invalid Billing Address');
    }

    @isTest
    static void testAccountUpdateBillingAddressNGBSSync() {
        Account acc = (Account) new AccountSelector()
            .selectAccountByName(new List<Object>{BILLING_ACCOUNT_NAME})
            .selectFields(new Set<String> {'BillingStreet', 'BillingCity', 'BillingPostalCode', 'Phone', 'VATNumber__c'})
            .subselect(new AccountContactRoleSelector().selectAccountContactRolesForOpportunityClose().setCondition('isPrimary = true'))
            .executeQuery()
            .get(0);
        acc.BillingStreet = '34 Test Street';
        acc.BillingCity = 'Mumbai';
        acc.BillingState = 'Bihar';
        acc.BillingCountry = 'India';
        acc.BillingPostalCode = '12345';
        update acc;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new Mock());
        QueueableBase.enqueJob('AccountUpdateBillingAddressNGBSSync', new List<sObject>{acc});
        Test.stopTest();

        List<PlatformLog__c> logs = (List<PlatformLog__c>) new QueryFactory(PlatformLog__c.SObjectType)
            .selectFields(new Set<String> {'Id', 'Error__c', 'InboundMessage__c', 'OutboundMessage__c', 'Source__c', 'StackTrace__c'})
            .executeQuery();

        System.assertEquals(0, logs.size(), 'Log wasn\'t created. Account updated succesfully');
    }

    @isTest
    static void testAccountUpdateBillingAddressNGBSSyncCalloutFailed() {
        Account acc = (Account) new AccountSelector()
            .selectAccountByName(new List<Object>{WRONG_BILLING_ACCOUNT_NAME})
            .selectFields(new Set<String> {'BillingStreet', 'BillingCity', 'BillingPostalCode', 'Phone'})
            .subselect(new AccountContactRoleSelector().selectAccountContactRolesForOpportunityClose())
            .executeQuery()
            .get(0);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new Mock());
        QueueableBase.enqueJob('AccountUpdateBillingAddressNGBSSync', new List<sObject>{acc});
        Test.stopTest();

        List<PlatformLog__c> logs = (List<PlatformLog__c>) new QueryFactory(PlatformLog__c.SObjectType)
            .selectFields(new Set<String> {'Id', 'Error__c', 'InboundMessage__c', 'OutboundMessage__c', 'Source__c', 'StackTrace__c'})
            .executeQuery();

        System.assertEquals(
            1,
            logs.size(),
            'Should create logs for unexpected response from NGBS system and wrong or empty Billing Id on Account');
    }
}