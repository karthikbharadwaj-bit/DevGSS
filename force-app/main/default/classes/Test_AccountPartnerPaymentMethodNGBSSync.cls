@isTest
private class Test_AccountPartnerPaymentMethodNGBSSync
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

    @isTest
    static void testPositiveScenario()
    {
        Account parentPartnerAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ValueProviderBuilder.provideUniqueString(),
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.RC_Account_Status__c => AccountHelper.PAID_STATUS,
                Account.Partner_ID__c => '123',
                Account.NGBS_Partner_ID__c => ValueProviderBuilder.provideUniqueNumber(),
                Account.Partner_Type__c =>  AccountHelper.ACCOUNT_PARTNER_BILL_ON_BEHALF
            })
            .create()
            .getRecord();

        Account billingAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ValueProviderBuilder.provideUniqueString(),
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.RC_Account_Status__c => AccountHelper.PAID_STATUS,
                Account.Partner_ID__c => '1234',
                Account.Partner_Type__c =>  AccountHelper.ACCOUNT_PARTNER_BILL_ON_BEHALF,
                Account.Partner_Account__c => parentPartnerAcc.Id,
                Account.BillingStreet => 'street',
                Account.BillingState => 'state',
                Account.BillingPostalCode => '123',
                Account.BillingCountry => 'USA',
                Account.BillingCity => 'City',
                Account.Phone => '123467445'
            })
            .create()
            .getRecord();

        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => billingAcc.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
        AccountContactRole testAccountContactRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => billingAcc.Id,
                    AccountContactRole.ContactId => testContact.Id,
                    AccountContactRole.IsPrimary => true,
                    AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_SIGNATORY
                }
            )
            .create()
            .getRecord();

        BillingHttpRequestMock.GET_PAYMENT_METHOD_RESPONSE = '[]';
        BillingHttpRequestMock tstMock = new BillingHttpRequestMock();
        Test.setMock(HttpCalloutMock.class, tstMock);

        Test.startTest();
        List<Account> reselectedAcc = (List<Account>) new AccountSelector()
            .selectAccountsForApproval(new List<Object>{new Set<Id>{billingAcc.Id}})
            .executeQuery();

        Map<String, List<Object>> agrumentsMap = new Map<String, List<Object>>{
            'accounts' => new List<Account>{reselectedAcc[0]}
        };
        List<Object> agrumentsList = new List<Object>{agrumentsMap};
        System.debug('testAccountContactRole' + testAccountContactRole);
        QueueableBase.enqueJob('AccountPartnerPaymentMethodNGBSSync', agrumentsList);
        Test.stopTest();
        List<PlatformLog__c> logs = [SELECT Id, StackTrace__c FROM PlatformLog__c WHERE Source__c = 'AccountPartnerPaymentMethodNGBSSync'];
        System.assertEquals(0, logs.size(), 'should not create any logs');
    }

    @isTest
    static void testErrorsHandling()
    {
        Account parentPartnerAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.RC_Account_Status__c => AccountHelper.PAID_STATUS,
                Account.Partner_ID__c => '123',
                Account.NGBS_Partner_ID__c => ValueProviderBuilder.provideUniqueNumber(),
                Account.Partner_Type__c =>  AccountHelper.ACCOUNT_PARTNER_BILL_ON_BEHALF
            })
            .create()
            .getRecord();
        Account billingAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Billing_ID__c => '',
                Account.RC_Account_Status__c => AccountHelper.PAID_STATUS,
                Account.Partner_ID__c => '123',
                Account.Partner_Type__c =>  AccountHelper.ACCOUNT_PARTNER_BILL_ON_BEHALF,
                Account.Partner_Account__c => parentPartnerAcc.Id,
                Account.BillingStreet => 'street',
                Account.BillingState => 'state',
                Account.BillingPostalCode => '123',
                Account.BillingCountry => 'USA',
                Account.BillingCity => 'City',
                Account.Phone => '123467445'
            })
            .create()
            .getRecord();
        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => billingAcc.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
        AccountContactRole testAccountContactRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => billingAcc.Id,
                    AccountContactRole.ContactId => testContact.Id,
                    AccountContactRole.IsPrimary => true,
                    AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_SIGNATORY
                }
            )
            .create()
            .getRecord();

        Map<String, List<Object>> agrumentsMap = new Map<String, List<Object>>{
            'accounts' => new List<Account>{billingAcc}
        };
        List<Object> agrumentsList = new List<Object>{agrumentsMap};

        BillingHttpRequestMock.GET_PAYMENT_METHOD_RESPONSE = '[]';
        BillingHttpRequestMock tstMock = new BillingHttpRequestMock();
        Test.setMock(HttpCalloutMock.class, tstMock);

        Test.startTest();
            QueueableBase.enqueJob('AccountPartnerPaymentMethodNGBSSync', new List<Object>{agrumentsMap});
        Test.stopTest();
        List<PlatformLog__c> logs = [SELECT Id, StackTrace__c FROM PlatformLog__c WHERE Source__c = 'AccountPartnerPaymentMethodNGBSSync'];
        System.assertEquals(1, logs.size(), 'should throw error when Billing ID is empty');
    }
}