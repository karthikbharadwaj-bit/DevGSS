@isTest
private class Test_SyncAccountWsBilling {

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testConstructor() {
        SyncAccountWsBilling syncAccWsBilling = new SyncAccountWsBilling();
    }

    @isTest
    private static void testSearchAccountByUID() {
        insert new Feature_Toggle__c(RC_User_Id_Sync__c = true);

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Account',
                Account.RC_User_ID__c => '21331231',
                Account.Billing_ID__c => '3120888001'
            })
            .create()
            .getRecord();

        SyncAccountWsBilling.syncAcctInputParamBilling params = new SyncAccountWsBilling.syncAcctInputParamBilling();
        params.In_RCUserID = '21331231';
        params.proc_debugmsg = '';
        params.In_BillingID = '3120888001';

        Boolean result;

        Test.startTest();
        result = SyncAccountWsBilling.searchAccountByUID(params);
        Test.stopTest();

        System.assert(
            result,
            'Method should return true'
        );
        System.assertEquals(
            acc.Id,
            params.proc_AccountId,
            'Field proc_AccountId populated incorrectly'
        );
    }

    @isTest
    private static void testSearchAccountByUIDWithoutCustomSetting() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Account',
                Account.RC_User_ID__c => '21331231',
                Account.Billing_ID__c => '3120888001'
            })
            .create()
            .getRecord();

        SyncAccountWsBilling.syncAcctInputParamBilling params = new SyncAccountWsBilling.syncAcctInputParamBilling();
        params.In_RCUserID = '21331231';
        params.proc_debugmsg = '';
        params.In_BillingID = '3120888001';

        Boolean result;

        Test.startTest();
        result = SyncAccountWsBilling.searchAccountByUID(params);
        Test.stopTest();

        System.assert(
            result,
            'Method should return true'
        );
        System.assertEquals(
            acc.Id,
            params.proc_AccountId,
            'Field proc_AccountId populated incorrectly'
        );
    }

    @isTest
    private static void testSearchAccountByUIDWithoutBillingId() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Account',
                Account.RC_User_ID__c => '21331231',
                Account.Billing_ID__c => '3120888001'
            })
            .create()
            .getRecord();

        SyncAccountWsBilling.syncAcctInputParamBilling params = new SyncAccountWsBilling.syncAcctInputParamBilling();
        params.In_RCUserID = '21331231';
        params.proc_debugmsg = '';

        Boolean result;

        Test.startTest();
        result = SyncAccountWsBilling.searchAccountByUID(params);
        Test.stopTest();

        System.assert(
            result,
            'Method should return true'
        );
        System.assertEquals(
            acc.Id,
            params.proc_AccountId,
            'Field proc_AccountId populated incorrectly'
        );
    }

    @isTest
    private static void testSearchAccountByUIDWithoutRCUserId() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Account'
            })
            .create()
            .getRecord();

        SyncAccountWsBilling.syncAcctInputParamBilling params = new SyncAccountWsBilling.syncAcctInputParamBilling();
        params.In_RCUserID = '21331231';
        params.proc_debugmsg = '';

        Boolean result;

        Test.startTest();
        result = SyncAccountWsBilling.searchAccountByUID(params);
        Test.stopTest();

        System.assert(
            !result,
            'Method should return false'
        );
    }

    @isTest
    private static void testGetAccountByRCUserId() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Account',
                Account.RC_User_ID__c => '21331231'
            })
            .create()
            .getRecord();

        List<Account> result;

        Test.startTest();
        result = SyncAccountWsBilling.getAccountByRCUserId('21331231');
        Test.stopTest();

        System.assertEquals(
            1,
            result.size(),
            'List should contain only 1 element'
        );
        System.assertEquals(
            acc.Id,
            result[0].Id,
            'List populated incorrectly'
        );
    }

    @isTest
    private static void testSearchContactandLeadByDealId() {
        SyncAccountWsBilling.syncAcctInputParamBilling params = new SyncAccountWsBilling.syncAcctInputParamBilling();
        params.In_Partner_Deal_Registration_Id = '11';
        params.proc_debugmsg = '';

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString()
            })
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.FirstName => 'test fname',
                Contact.LastName => 'test lname',
                Contact.Email => 'testemail@emailvendor.com',
                Contact.AccountId => acc.Id,
                Contact.PartnerDeal_Registration_Id__c => 11
            })
            .create()
            .getRecord();

        Boolean result;

        Test.startTest();
        result = SyncAccountWsBilling.searchContactandLeadByDealId(params);
        Test.stopTest();

        System.assert(
            result,
            'Method should return true'
        );
        System.assertEquals(
            1,
            params.searchContact.size(),
            'List searchContact should contain only 1 element'
        );
        System.assertEquals(
            contact.Id,
            params.searchContact[0].Id,
            'List searchContact populated incorrectly'
        );
    }

    @isTest
    private static void testSearchContactandLeadByDealIdWithoutContacts() {
        SyncAccountWsBilling.syncAcctInputParamBilling params = new SyncAccountWsBilling.syncAcctInputParamBilling();
        params.In_Partner_Deal_Registration_Id = '11';
        params.proc_debugmsg = '';

        Lead lead = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Lead.LastName => 'TestLead',
                Lead.PartnerDeal_Registration_Id__c => 11,
                Lead.IsConverted => false,
                Lead.email => 'testLead@gmail.com'
            })
            .create()
            .getRecord();

        Boolean result;

        Test.startTest();
        result = SyncAccountWsBilling.searchContactandLeadByDealId(params);
        Test.stopTest();

        System.assert(
            result,
            'Method should return true'
        );
        System.assertEquals(
            1,
            params.searchlead.size(),
            'List searchlead should contain only 1 element'
        );
        System.assertEquals(
            lead.Id,
            params.searchlead[0].Id,
            'List searchlead populated incorrectly'
        );
    }

    @isTest
    private static void testSearchOppertunityByOID() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString()
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => acc.Id,
                Opportunity.Is_Billing_Opportunity__c => true
            })
            .create()
            .getRecord();

        SyncAccountWsBilling.syncAcctInputParamBilling params = new SyncAccountWsBilling.syncAcctInputParamBilling();
        params.In_LastName = 'test last name';
        params.In_ContactEmail = 'testemail@emailvendor.com';
        params.In_FirstName = '12345678901234567890123456789012345678901';
        params.In_OpportunityID = opp.Id;
        params.proc_debugmsg = '';

        Boolean result;

        Test.startTest();
        result = SyncAccountWsBilling.searchOppertunityByOID(params);
        Test.stopTest();

        System.assert(
            !result,
            'Method should return false'
        );
        System.assertEquals(
            'IN searchOppertunityByOID::',
            params.proc_debugmsg,
            'Field proc_debugmsg populated incorrectly'
        );
    }

    @isTest
    private static void testSearchContactByMail() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Account',
                Account.RecordTypeId => Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account').getRecordTypeId()
            })
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.FirstName => 'test fname',
                Contact.LastName => 'test lname',
                Contact.Email => 'testemail@emailvendor.com',
                Contact.AccountId => acc.Id
            })
            .create()
            .getRecord();

        SyncAccountWsBilling.syncAcctInputParamBilling params = new SyncAccountWsBilling.syncAcctInputParamBilling();
        params.In_ContactID = contact.Id;
        params.In_LastName = 'test last name';
        params.In_ContactEmail = 'testemail@emailvendor.com';
        params.In_FirstName = '12345678901234567890123456789012345678901';
        params.In_ContactPhone = '123456789';
        params.proc_debugmsg = '';

        Boolean result;

        Test.startTest();
        result = SyncAccountWsBilling.searchContactByMail(params);
        Test.stopTest();

        System.assert(
            result,
            'Method should return true'
        );
        System.assertEquals(
            'IN searchContactByMail::',
            params.proc_debugmsg,
            'Field proc_debugmsg populated incorrectly'
        );
        System.assertEquals(
            acc.Id,
            params.proc_AccountId,
            'Field proc_AccountId populated incorrectly'
        );
        System.assertEquals(
            contact.Id,
            params.proc_ContactId,
            'Field proc_ContactId populated incorrectly'
        );
    }

    @isTest
    private static void testSearchContactByMailMultipleContacts() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Account'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => acc.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.RecordTypeId => Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId()
            })
            .create()
            .getRecord();

        Contact contact1 = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.FirstName => 'test fname',
                Contact.LastName => 'test lname',
                Contact.Email => 'testemail@emailvendor.com',
                Contact.AccountId => acc.Id
            })
            .build()
            .getRecord();

        Contact contact2 = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.FirstName => 'test fname2',
                Contact.LastName => 'test lname2',
                Contact.Email => 'testemail@emailvendor.com',
                Contact.AccountId => acc.Id
            })
            .build()
            .getRecord();

        insert new List<Contact>{contact1, contact2};

        Test.setCreatedDate(contact2.Id, DateTime.newInstance(3012,12,12));

        SyncAccountWsBilling.syncAcctInputParamBilling params = new SyncAccountWsBilling.syncAcctInputParamBilling();
        params.In_ContactID = contact1.Id;
        params.In_LastName = 'test last name';
        params.In_ContactEmail = 'testemail@emailvendor.com';
        params.In_FirstName = '12345678901234567890123456789012345678901';
        params.In_ContactPhone = '123456789';
        params.proc_debugmsg = '';

        Boolean result;

        Test.startTest();
        result = SyncAccountWsBilling.searchContactByMail(params);
        Test.stopTest();

        System.assert(
            result,
            'Method should return true'
        );
        System.assertEquals(
            'IN searchContactByMail::',
            params.proc_debugmsg,
            'Field proc_debugmsg populated incorrectly'
        );
        System.assertEquals(
            acc.Id,
            params.proc_AccountId,
            'Field proc_AccountId populated incorrectly'
        );
        System.assertEquals(
            contact2.Id,
            params.proc_ContactId,
            'Field proc_ContactId populated incorrectly'
        );
    }

    @isTest
    private static void testSearchLeadByEmail() {
        Lead lead = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Lead.LastName => 'TestLead',
                Lead.PartnerDeal_Registration_Id__c => 11,
                Lead.IsConverted => false,
                Lead.email => 'testLead@gmail.com'
            })
            .create()
            .getRecord();

        SyncAccountWsBilling.syncAcctInputParamBilling params = new SyncAccountWsBilling.syncAcctInputParamBilling();
        params.proc_debugmsg = '';
        params.In_ContactEmail = 'testLead@gmail.com';

        Boolean result;

        Test.startTest();
        result = SyncAccountWsBilling.searchLeadByEmail(params);
        Test.stopTest();

        System.assert(
            !result,
            'Method should return false'
        );
        System.assertEquals(
            'IN searchLeadByEmail::',
            params.proc_debugmsg,
            'Field proc_debugmsg populated incorrectly'
        );
    }

    @isTest
    private static void testHandleUpdateAccount() {

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Account',
                Account.Billing_ID__c => '1111'
            })
            .create()
            .getRecord();

        SyncAccountWsBilling.syncAcctInputParamBilling params = new SyncAccountWsBilling.syncAcctInputParamBilling();
        params.In_AccountID = acc.Id;
        params.In_Company = acc.Name;
        params.In_BillingID = acc.Billing_ID__c;
        params.In_Industry = 'Insurance';
        params.proc_debugmsg = '';

        SyncAccountWsBilling.syncAcctInputParamBilling result;

        Test.startTest();
        result = SyncAccountWsBilling.synAccountNew(params);
        Test.stopTest();

        System.assert(
            result.proc_debugmsg.contains('IN handleUpdateAccount::'),
            'Field proc_debugmsg populated incorrectly'
        );
        System.assert(
            result.proc_debugmsg.contains('IN handleReturn::'),
            'Field proc_debugmsg populated incorrectly'
        );

        System.assertEquals(
            acc.Id,
            result.Out_AccountID,
            'Field Out_AccountID is not equal to Id of updated Account'
        );

        Account reselectedAcc = (Account) new AccountSelector()
            .selectAccounts()
            .selectFields(new List<Schema.SObjectField>{
                Account.Industry
            })
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{ acc.Id })
            .executeQuery()
            .get(0);

        System.assertEquals(
            params.In_Industry,
            reselectedAcc.Industry,
            'In_Industry value not written to Account.Industry'
        );
    }

    @isTest
    private static void testHandleUpdateAccountMethod() {

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Account',
                Account.Billing_ID__c => '1111'
            })
            .create()
            .getRecord();

        SyncAccountWsBilling.syncAcctInputParamBilling params = new SyncAccountWsBilling.syncAcctInputParamBilling();
        params.In_AccountID = acc.Id;
        params.In_Company = acc.Name;
        params.In_BillingID = acc.Billing_ID__c;
        params.In_Industry = 'Insurance';
        params.proc_debugmsg = '';

        Boolean result;

        Test.startTest();
        SyncAccountWsBilling.initializeIds(params);
        result = SyncAccountWsBilling.handleUpdateAccount(params);
        Test.stopTest();

        System.assert(
            result,
            'Method should return true'
        );
        System.assertEquals(
            'IN handleUpdateAccount::IN upsertServiceAccounts::',
            params.proc_debugmsg,
            'Field proc_debugmsg populated incorrectly'
        );

        Account reselectedAcc = (Account) new AccountSelector()
            .selectAccounts()
            .selectFields(new List<Schema.SObjectField>{
                Account.Industry
            })
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{ acc.Id })
            .executeQuery()
            .get(0);

        System.assertEquals(
            params.In_Industry,
            reselectedAcc.Industry,
            'In_Industry value not written to Account.Industry'
        );
    }

    @isTest
    private static void testHandleUpdateAccountByCCB() {

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test Account',
                Account.Billing_ID__c => '1111'
            })
            .create()
            .getRecord();

        SyncAccountWsBilling.syncAcctInputParamBilling params = new SyncAccountWsBilling.syncAcctInputParamBilling();
        params.In_AccountID = acc.Id;
        params.In_RCUserID = '123456789';
        params.In_BillingID = '987654321';

        params.In_EngageAccountId = 'Test In_EngageAccountId';
        params.In_EVAccountId = 'Test In_EVAccountId';
        params.In_EVPlatform = 'Test In_EVPlatform';
        params.In_EDAccountId = 'Test In_EDAccountId';
        params.In_EDDomainId = 'Test In_EDDomainId';
        params.In_EDPlatform = 'Test In_EDPlatform';

        SyncAccountWsBilling.syncAcctInputParamBilling result;

        Test.startTest();
        result = SyncAccountWsBilling.synAccountNew(params);
        Test.stopTest();

        Account rAcc = (Account) new AccountSelector()
            .selectAccounts()
            .selectFields(new List<Schema.SObjectField>{
                Account.Rc_User_Id__c, Account.Billing_ID__c,
                Account.RC_Engage_Account_ID__c, Account.EV_Account_ID__c, Account.EV_Platform__c,
                Account.ED_Account_ID__c, Account.Engage_Domain__c, Account.ED_Platform__c
            })
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{ acc.Id })
            .executeQuery()
            .get(0);

        System.assertEquals('123456789', rAcc.Rc_User_Id__c, 'Account.Rc_User_Id__c value not updated');
        System.assertEquals('987654321', rAcc.Billing_ID__c, 'Account.Billing_ID__c value not updated');

        System.assertEquals('Test In_EngageAccountId', rAcc.RC_Engage_Account_ID__c, 'Account.RC_Engage_Account_ID__c value not updated');
        System.assertEquals('Test In_EVAccountId', rAcc.EV_Account_ID__c, 'Account.EV_Account_ID__c value not updated');
        System.assertEquals('Test In_EVPlatform', rAcc.EV_Platform__c, 'Account.EV_Platform__c value not updated');
        System.assertEquals('Test In_EDAccountId', rAcc.ED_Account_ID__c, 'Account.ED_Account_ID__c value not updated');
        System.assertEquals('Test In_EDDomainId', rAcc.Engage_Domain__c, 'Account.Engage_Domain__c value not updated');
        System.assertEquals('Test In_EDPlatform', rAcc.ED_Platform__c, 'Account.ED_Platform__c value not updated');
    }

    @isTest
    private static void testHandleUpdateAccountByDWHAfterCCB() {

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test Account',
                Account.Billing_ID__c => '1111',
                Account.RC_Engage_Account_ID__c => 'RC_Engage_Account_ID__c value',
                Account.EV_Account_ID__c => 'EV_Account_ID__c value',
                Account.EV_Platform__c => 'EV_Platform__c value',
                Account.ED_Account_ID__c => 'ED_Account_ID__c value',
                Account.Engage_Domain__c => 'Engage_Domain__c value',
                Account.ED_Platform__c => 'ED_Platform__c value'
            })
            .create()
            .getRecord();

        SyncAccountWsBilling.syncAcctInputParamBilling params = new SyncAccountWsBilling.syncAcctInputParamBilling();
        params.In_AccountID = acc.Id;
        params.In_RCUserID = '123456789';
        params.In_BillingID = '987654321';

        params.In_EngageAccountId = null;
        params.In_EVAccountId = '';

        SyncAccountWsBilling.syncAcctInputParamBilling result;

        Test.startTest();
        result = SyncAccountWsBilling.synAccountNew(params);
        Test.stopTest();

        Account rAcc = (Account) new AccountSelector()
            .selectAccounts()
            .selectFields(new List<Schema.SObjectField>{
                Account.Rc_User_Id__c, Account.Billing_ID__c,
                Account.RC_Engage_Account_ID__c, Account.EV_Account_ID__c, Account.EV_Platform__c,
                Account.ED_Account_ID__c, Account.Engage_Domain__c, Account.ED_Platform__c
            })
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{ acc.Id })
            .executeQuery()
            .get(0);

        System.assertEquals('123456789', rAcc.Rc_User_Id__c, 'Account.Rc_User_Id__c value not updated');
        System.assertEquals('987654321', rAcc.Billing_ID__c, 'Account.Billing_ID__c value not updated');

        System.assertEquals('RC_Engage_Account_ID__c value', rAcc.RC_Engage_Account_ID__c, 'Account.RC_Engage_Account_ID__c value should not be erased');
        System.assertEquals('EV_Account_ID__c value', rAcc.EV_Account_ID__c, 'Account.EV_Account_ID__c value should not be erased');
        System.assertEquals('EV_Platform__c value', rAcc.EV_Platform__c, 'Account.EV_Platform__c value should not be erased');
        System.assertEquals('ED_Account_ID__c value', rAcc.ED_Account_ID__c, 'Account.ED_Account_ID__c value should not be erased');
        System.assertEquals('Engage_Domain__c value', rAcc.Engage_Domain__c, 'Account.Engage_Domain__c value should not be erased');
        System.assertEquals('ED_Platform__c value', rAcc.ED_Platform__c, 'Account.ED_Platform__c value should not be erased');
    }

    @isTest
    private static void testSubstringStr() {
        String result;

        Test.startTest();
        result = SyncAccountWsBilling.substringStr('testString', 4);
        Test.stopTest();

        System.assertEquals(
            'test',
            result,
            'Method should return correct value'
        );
    }

    @isTest
    private static void testHandleConverLead() {
        Lead lead = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Lead.LastName => 'TestLead',
                Lead.PartnerDeal_Registration_Id__c => 11,
                Lead.IsConverted => false
            })
            .create()
            .getRecord();

        SyncAccountWsBilling.syncAcctInputParamBilling params = new SyncAccountWsBilling.syncAcctInputParamBilling();
        params.proc_debugmsg = '';
        params.searchlead = new List<Lead>{lead};

        Boolean result;

        Test.startTest();
        result = SyncAccountWsBilling.handleConverLead(params);
        Test.stopTest();

        System.assert(
            result,
            'Method should return true'
        );
    }

    @isTest
    private static void testHandleCreateAccount() {

        SyncAccountWsBilling.syncAcctInputParamBilling params = new SyncAccountWsBilling.syncAcctInputParamBilling();
        params.proc_debugmsg = '';
        params.In_Industry = 'Insurance';

        Boolean result;

        Test.startTest();
        result = SyncAccountWsBilling.handleCreateAccount(params);
        Test.stopTest();

        System.assert(
            result,
            'Method should return true'
        );
        System.assertEquals(
            'IN handleCreateAccount::IN upsertServiceAccounts::',
            params.proc_debugmsg,
            'Field proc_debugmsg populated incorrectly'
        );

        Account reselectedAcc = (Account) new AccountSelector()
            .selectAccounts()
            .selectFields(new List<Schema.SObjectField>{
                Account.Industry
            })
            .executeQuery()
            .get(0);

        System.assertEquals(
            params.In_Industry,
            reselectedAcc.Industry,
            'In_Industry value not written to Account.Industry'
        );
    }

    @isTest
    private static void testHandleCreateAccountEngage() {

        SyncAccountWsBilling.syncAcctInputParamBilling params = new SyncAccountWsBilling.syncAcctInputParamBilling();
        params.proc_debugmsg = '';
        params.In_Industry = 'Insurance';

        params.In_EngageAccountId = 'Test In_EngageAccountId';
        params.In_EVAccountId = 'Test In_EVAccountId';
        params.In_EVPlatform = 'Test In_EVPlatform';
        params.In_EDAccountId = 'Test In_EDAccountId';
        params.In_EDDomainId = 'Test In_EDDomainId';
        params.In_EDPlatform = 'Test In_EDPlatform';

        Boolean result;

        Test.startTest();
        result = SyncAccountWsBilling.handleCreateAccount(params);
        Test.stopTest();

        System.assert(
            result,
            'Method should return true'
        );
        System.assertEquals(
            'IN handleCreateAccount::IN upsertServiceAccounts::',
            params.proc_debugmsg,
            'Field proc_debugmsg populated incorrectly'
        );

        Account reselectedAcc = (Account) new AccountSelector()
            .selectAccounts()
            .selectFields(new List<Schema.SObjectField>{
                Account.Industry,
                Account.RC_Engage_Account_ID__c, Account.EV_Account_ID__c, Account.EV_Platform__c,
                Account.ED_Account_ID__c, Account.Engage_Domain__c, Account.ED_Platform__c
            })
            .executeQuery()
            .get(0);

        System.assertEquals('Insurance', reselectedAcc.Industry, 'Account.Industry not populated');
        System.assertEquals('Test In_EngageAccountId', reselectedAcc.RC_Engage_Account_ID__c, 'Account.RC_Engage_Account_ID__c not populated');
        System.assertEquals('Test In_EVAccountId', reselectedAcc.EV_Account_ID__c, 'Account.EV_Account_ID__c not populated');
        System.assertEquals('Test In_EVPlatform', reselectedAcc.EV_Platform__c, 'Account.EV_Platform__c not populated');
        System.assertEquals('Test In_EDAccountId', reselectedAcc.ED_Account_ID__c, 'Account.ED_Account_ID__c not populated');
        System.assertEquals('Test In_EDDomainId', reselectedAcc.Engage_Domain__c, 'Account.Engage_Domain__c not populated');
    }

    @isTest
    private static void testUpsertServiceAccounts() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Account',
                Account.RC_User_Id__c => '21331231'
            })
            .create()
            .getRecord();

        Package__c pack = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Name => 'serviceAccId',
                Package__c.Account__c => acc.Id,
                Package__c.Enterprise_Account_ID__c => acc.Id,
                Package__c.Account_Package_Id__c => '21331231'
            })
            .create()
            .getRecord();

        SyncAccountWsBilling.syncAcctInputParamBilling params = new SyncAccountWsBilling.syncAcctInputParamBilling();
        params.proc_debugmsg = '';
        params.serviceAccounts = new List<Package__c>{pack};
        params.proc_AccountId = acc.Id;

        Boolean result;

        Test.startTest();
        result = SyncAccountWsBilling.upsertServiceAccounts(params);
        Test.stopTest();

        System.assert(
            result,
            'Method should return true'
        );
        System.assertEquals(
            'IN upsertServiceAccounts::',
            params.proc_debugmsg,
            'Field proc_debugmsg populated incorrectly'
        );
    }

    @isTest
    private static void testGetOfferTypeForAccount() {

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Account',
                Account.RC_User_Id__c => '21331231'
            })
            .create()
            .getRecord();

        Package__c pack = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Name => 'serviceAccId',
                Package__c.Account__c => acc.Id,
                Package__c.Account_Package_Id__c => '21331231',
                Package__c.Offer_Type__c => 'test offer type',
                Package__c.Enterprise_Account_ID__c => acc.Id
            })
            .create()
            .getRecord();

        SyncAccountWsBilling.syncAcctInputParamBilling params = new SyncAccountWsBilling.syncAcctInputParamBilling();
        params.serviceAccounts = new List<Package__c>{pack};

        String result;

        Test.startTest();
        result = SyncAccountWsBilling.getOfferTypeForAccount(params);
        Test.stopTest();

        System.assertEquals(
            'test offer type',
            result,
            'Method should return correct value'
        );
    }

    @isTest
    private static void testGetPurchasedLicensesNumber() {

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Account',
                Account.RC_User_Id__c => '21331231'
            })
            .create()
            .getRecord();

        Package__c pack = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Name => 'serviceAccId',
                Package__c.Account__c => acc.Id,
                Package__c.Account_Package_Id__c => '21331231',
                Package__c.Licenses_Purchased__c => 1,
                Package__c.Enterprise_Account_ID__c => acc.Id
            })
            .create()
            .getRecord();

        SyncAccountWsBilling.syncAcctInputParamBilling params = new SyncAccountWsBilling.syncAcctInputParamBilling();
        params.serviceAccounts = new List<Package__c>{pack};

        Decimal result;

        Test.startTest();
        result = SyncAccountWsBilling.getPurchasedLicensesNumber(params);
        Test.stopTest();

        System.assertEquals(
            1,
            result,
            'Method should return correct value'
        );
    }

    @isTest
    private static void testHandleCreateContact() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Account'
            })
            .create()
            .getRecord();

        SyncAccountWsBilling.syncAcctInputParamBilling params = new SyncAccountWsBilling.syncAcctInputParamBilling();
        params.proc_AccountId = acc.Id;
        params.In_LastName = 'test last name';
        params.In_ContactEmail = 'testemail@emailvendor.comcomcomcomcomcomcomcomcomomcomcomcomcomcomomcomcomcomcomcom';
        params.In_FirstName = '12345678901234567890123456789012345678901';
        params.In_ContactPhone = '123456789';
        params.proc_debugmsg = '';

        Boolean result;

        Test.startTest();
        result = SyncAccountWsBilling.handleCreateContact(params);
        Test.stopTest();

        List<Contact> contactList = new ContactSelector().selectContacts().executeQuery();

        System.assert(
            result,
            'Method should return true'
        );
        System.assertEquals(
            'IN handleCreateContact::',
            params.proc_debugmsg,
            'Field proc_debugmsg populated incorrectly'
        );
        System.assertEquals(
            contactList[0].Id,
            params.proc_ContactId,
            'Field proc_ContactId populated incorrectly'
        );
        System.assertEquals(
            params.In_LastName,
            contactList[0].LastName,
            'Field LastName populated incorrectly'
        );
    }

    @isTest
    private static void testHandleUpdateContact() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Account'
            })
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.FirstName => 'test fname',
                Contact.LastName => 'test lname',
                Contact.Email => 'testemail@emailvendor.com',
                Contact.AccountId => acc.Id
            })
            .create()
            .getRecord();

        SyncAccountWsBilling.syncAcctInputParamBilling params = new SyncAccountWsBilling.syncAcctInputParamBilling();
        params.In_ContactID = contact.Id;
        params.In_LastName = 'test last name';
        params.In_ContactEmail = 'testemail@emailvendor.com';
        params.In_FirstName = '12345678901234567890123456789012345678901';
        params.In_ContactPhone = '123456789';

        Boolean result;

        Test.startTest();
        result = SyncAccountWsBilling.handleUpdateContact(params);
        Test.stopTest();

        List<Contact> contactList = new ContactSelector().selectContacts().executeQuery();

        System.assert(
            result,
            'Method should return true'
        );
        System.assertEquals(
            params.In_LastName,
            contactList[0].LastName,
            'Field LastName populated incorrectly'
        );
        System.assertEquals(
            params.In_ContactEmail,
            contactList[0].Email,
            'Field Email populated incorrectly'
        );
    }

    @isTest
    private static void testAccountMatchingContactEmail() {

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Account'
            })
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.FirstName => 'test fname',
                Contact.LastName => 'test lname',
                Contact.Email => 'testemail@emailvendor.com',
                Contact.AccountId => acc.Id
            })
            .create()
            .getRecord();

        SyncAccountWsBilling.syncAcctInputParamBilling params = new SyncAccountWsBilling.syncAcctInputParamBilling();
        params.proc_AccountId = acc.Id;
        params.In_ContactEmail = 'testemail@emailvendor.com';
        params.proc_debugmsg = '';

        Boolean result;

        Test.startTest();
        result = SyncAccountWsBilling.accountMatchingContactEmail(params);
        Test.stopTest();

        System.assert(
            result,
            'Method should return true'
        );
        System.assertEquals(
            'IN accountMatchingContactEmail::',
            params.proc_debugmsg,
            'Field proc_debugmsg populated incorrectly'
        );
        System.assertEquals(
            contact.Id,
            params.proc_ContactId,
            'Field proc_ContactId populated incorrectly'
        );
    }

    @isTest
    private static void testAccountMatchingContactEmailWithoutContacts() {

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Account'
            })
            .create()
            .getRecord();

        SyncAccountWsBilling.syncAcctInputParamBilling params = new SyncAccountWsBilling.syncAcctInputParamBilling();
        params.proc_AccountId = acc.Id;
        params.In_ContactEmail = 'testemail@emailvendor.com';
        params.proc_debugmsg = '';

        Boolean result;

        Test.startTest();
        result = SyncAccountWsBilling.accountMatchingContactEmail(params);
        Test.stopTest();

        System.assert(
            !result,
            'Method should return false'
        );
        System.assertEquals(
            'IN accountMatchingContactEmail::',
            params.proc_debugmsg,
            'Field proc_debugmsg populated incorrectly'
        );
    }

    @isTest
    private static void testContactHavingUserRecord() {

        SyncAccountWsBilling.syncAcctInputParamBilling params = new SyncAccountWsBilling.syncAcctInputParamBilling();
        params.In_BillingID = '3120888001';
        params.In_ContactEmail = 'testemail@emailvendor.com';
        params.proc_debugmsg = '';

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Account',
                Account.Billing_ID__c => params.In_BillingID
            })
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.FirstName => 'test fname',
                Contact.LastName => 'test lname',
                Contact.Email => params.In_ContactEmail,
                Contact.AccountId => acc.Id
            })
            .create()
            .getRecord();

        User user  = (User) new SObjectBuilder(User.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
            .setFields(
                new Map<SObjectField, Object> {
                    User.ContactId => contact.Id,
                    User.ProfileId => ProfileHelper.PROFILE_ID_CUSTOMER_PORTAL_USER,
                    User.IsActive => true
                }
            )
            .create()
            .getRecord();

        insert new RingCentralVariousSettings__c(Use_Community_Licenses_on_portal__c = true);

        Boolean result;

        Test.startTest();
        result = SyncAccountWsBilling.contactHavingUserRecord(params);
        Test.stopTest();

        System.assert(
            result,
            'Method should return true'
        );
        System.assertEquals(
            'IN contactHavingUserRecord::',
            params.proc_debugmsg,
            'Field proc_debugmsg populated incorrectly'
        );
        System.assertEquals(
            user.Id,
            params.proc_UserId,
            'Field proc_UserId populated incorrectly'
        );
    }

    @isTest
    private static void testContactHavingUserRecordShouldReturnFalse() {

        SyncAccountWsBilling.syncAcctInputParamBilling params = new SyncAccountWsBilling.syncAcctInputParamBilling();
        params.In_BillingID = '3120888001';
        params.In_ContactEmail = 'testemail@emailvendor.com';
        params.proc_debugmsg = '';

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Account',
                Account.Billing_ID__c => params.In_BillingID
            })
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.FirstName => 'test fname',
                Contact.LastName => 'test lname',
                Contact.Email => params.In_ContactEmail,
                Contact.AccountId => acc.Id
            })
            .create()
            .getRecord();

        Boolean result;

        Test.startTest();
        result = SyncAccountWsBilling.contactHavingUserRecord(params);
        Test.stopTest();

        System.assert(
            !result,
            'Method should return false'
        );
        System.assertEquals(
            'IN contactHavingUserRecord::',
            params.proc_debugmsg,
            'Field proc_debugmsg populated incorrectly'
        );
    }

    @isTest
    private static void testContactHavingUserRecordShouldReturnFalseWithoutContacts() {

        SyncAccountWsBilling.syncAcctInputParamBilling params = new SyncAccountWsBilling.syncAcctInputParamBilling();
        params.proc_debugmsg = '';

        Boolean result;

        Test.startTest();
        result = SyncAccountWsBilling.contactHavingUserRecord(params);
        Test.stopTest();

        System.assert(
            !result,
            'Method should return false'
        );
        System.assertEquals(
            'IN contactHavingUserRecord::',
            params.proc_debugmsg,
            'Field proc_debugmsg populated incorrectly'
        );
    }

    @isTest
    private static void testHandleCreateUser() {
        SyncAccountWsBilling.syncAcctInputParamBilling params = new SyncAccountWsBilling.syncAcctInputParamBilling();
        params.proc_debugmsg = 'proc';

        Boolean result;

        Test.startTest();
        result = SyncAccountWsBilling.handleCreateUser(params);
        Test.stopTest();

        System.assert(
            result,
            'Method should return true'
        );
        System.assertEquals(
            'procIN handleCreateUser::',
            params.proc_debugmsg,
            'Field proc_debugmsg populated incorrectly'
        );

        System.assertEquals(
            '-1',
            params.proc_UserRecCreation,
            'Field proc_UserRecCreation populated incorrectly'
        );
    }

    @isTest
    private static void testHandleReturn() {
        SyncAccountWsBilling.syncAcctInputParamBilling params = new SyncAccountWsBilling.syncAcctInputParamBilling();
        params.proc_debugmsg = 'proc';
        params.proc_AccountId = 'AccId';
        params.proc_ContactId = 'ContId';
        params.proc_UserId = 'UserId';

        Test.startTest();
        SyncAccountWsBilling.handleReturn(params);
        Test.stopTest();

        System.assertEquals(
            'procIN handleReturn::',
            params.proc_debugmsg,
            'Field proc_debugmsg populated incorrectly'
        );
        System.assertEquals(
            'AccId',
            params.Out_AccountID,
            'Field Out_AccountID populated incorrectly'
        );
        System.assertEquals(
            'ContId',
            params.Out_ContactID,
            'Field Out_ContactID populated incorrectly'
        );
        System.assertEquals(
            'UserId',
            params.Out_UserID,
            'Field Out_UserID populated incorrectly'
        );
    }

    @isTest
    private static void testInitializeIds() {
        SyncAccountWsBilling.syncAcctInputParamBilling params = new SyncAccountWsBilling.syncAcctInputParamBilling();
        params.In_AccountID = 'AccId';
        params.In_ContactID = 'ContId';

        Test.startTest();
        SyncAccountWsBilling.initializeIds(params);
        Test.stopTest();

        System.assertEquals(
            params.In_AccountID,
            params.proc_AccountId,
            'proc_AccountId field populated incorrectly'
        );
        System.assertEquals(
            params.In_ContactID,
            params.proc_ContactId,
            'proc_ContactId field populated incorrectly'
        );
    }

    @isTest
    private static void testLogProcess() {
        SyncAccountWsBilling.syncAcctInputParamBilling params = new SyncAccountWsBilling.syncAcctInputParamBilling();
        params.proc_AccountId = 'AccId';
        params.In_Company = 'Comp';
        params.In_RCUserID = 'RCUserId';
        params.In_BillingID = 'BillingId';
        params.In_ContactEmail = 'Email';
        params.In_OpportunityID = 'OppId';
        params.In_Partner_Deal_Registration_Id = 'RegId';

        Test.startTest();
        SyncAccountWsBilling.LogProcess(params, 'action');
        Test.stopTest();

        CustomLog__c log = [SELECT Name, InputParameterFileds__c FROM CustomLog__c LIMIT 1];

        String result = 'In_proc_AccountId: ' + params.proc_AccountId + '\n' +
                        'In_Company: ' + params.In_Company + '\n' +
                        'In_RCUserID: ' + params.In_RCUserID + '\n' +
                        'In_BillingID: ' + params.In_BillingID + '\n' +
                        'In_ContactEmail: ' + params.In_ContactEmail + '\n' +
                        'In_OpportunityID: ' + params.In_OpportunityID + '\n' +
                        'In_Partner_Deal_Registration_Id: ' + params.In_Partner_Deal_Registration_Id;

        System.assert(
            log.Name.contains('action Account'),
            'Name in log populated incorrectly'
        );
        System.assertEquals(
            result,
            log.InputParameterFileds__c,
            'InputParameterFileds__c field in log populated incorrectly'
        );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testForCoverage() {
        try {
            SyncAccountWsBilling.initializeIds(null);
        } catch (Exception e) {}
        try {
            SyncAccountWsBilling.contactHavingUserRecord(null);
        } catch (Exception e) {}
        try {
            SyncAccountWsBilling.upsertServiceAccounts(null);
        } catch (Exception e) {}
        try {
            SyncAccountWsBilling.handleCreateAccount(null);
        } catch (Exception e) {}
        try {
            SyncAccountWsBilling.handleConverLead(null);
        } catch (Exception e) {}
        try {
            SyncAccountWsBilling.searchLeadByEmail(null);
        } catch (Exception e) {}
        try {
            SyncAccountWsBilling.searchContactByMail(null);
        } catch (Exception e) {}
        try {
            SyncAccountWsBilling.searchOppertunityByOID(null);
        } catch (Exception e) {}
        try {
            SyncAccountWsBilling.searchContactandLeadByDealId(null);
        } catch (Exception e) {}
        try {
            SyncAccountWsBilling.accountMatchingContactEmail(null);
        } catch (Exception e) {}
        try {
            SyncAccountWsBilling.handleUpdateContact(null);
        } catch (Exception e) {}
        try {
            SyncAccountWsBilling.handleCreateContact(null);
        } catch (Exception e) {}
        try {
            SyncAccountWsBilling.handleUpdateAccount(null);
        } catch (Exception e) {}
        try {
            SyncAccountWsBilling.searchAccountByUID(null);
        } catch (Exception e) {}
    }

    //LEGACY TESTS
    static void setup() {
        new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => ValueProviderBuilder.provideList(new List<String> {
                    'new customer',
                    'existing RC customer',
                    'existing RC customer billing only 1',
                    'existing RC customer billing only 2'
                }),
                Account.RC_User_ID__c => ValueProviderBuilder.provideList(new List<String> { null , '1234', null, null}),
                Account.Billing_ID__c => ValueProviderBuilder.provideList(new List<String> { null , '12345', '123456', '123456'}),
                Account.Service_Type__c => ValueProviderBuilder.provideList(new List<String> {
                    AccountHelper.SERVICE_TYPE_OFFICE,
                    AccountHelper.SERVICE_TYPE_RCCC,
                    AccountHelper.SERVICE_TYPE_ENGAGE_VOICE,
                    AccountHelper.SERVICE_TYPE_ENGAGE_DIGITAL

                })
            })
            .quantity(4)
            .create();
    }

    @isTest static void testAccountNotFound() {
        setup();
        SyncAccountWsBilling.BillingAcctInfo inboundTestData=new SyncAccountWsBilling.BillingAcctInfo();
        inboundTestData.billingID='123';
        inboundTestData.rcUserID='123';

        Test.startTest();
            SyncAccountWsBilling.SyncResult result=SyncAccountWsBilling.applyBillingIdAndPackages(inboundTestData);
            System.assertEquals(result.errorMsg,'Matching Account not found');
        Test.stopTest();
    }

    @isTest static void testTooManyAccountsFoundByBillingId() {
        setup();
        SyncAccountWsBilling.BillingAcctInfo inboundTestData=new SyncAccountWsBilling.BillingAcctInfo();
        inboundTestData.billingID='123456';
        inboundTestData.rcUserID='1234';

        Test.startTest();
            SyncAccountWsBilling.SyncResult result=SyncAccountWsBilling.applyBillingIdAndPackages(inboundTestData);
            System.assertEquals(result.errorMsg,'More than 1 Account with matching Billing Id found');
        Test.stopTest();
    }

    @isTest static void testNoBillingIdSent() {
        setup();
        SyncAccountWsBilling.BillingAcctInfo inboundTestData=new SyncAccountWsBilling.BillingAcctInfo();
        inboundTestData.rcUserID='1234';

        Test.startTest();
            SyncAccountWsBilling.SyncResult result=SyncAccountWsBilling.applyBillingIdAndPackages(inboundTestData);
            System.assertEquals(result.errorMsg,'Billing Id and Enterprise Account Id are required');
        Test.stopTest();
    }

    @isTest static void testBillingIdUpdateFoundByRcUserId() {
        setup();
        SyncAccountWsBilling.BillingAcctInfo inboundTestData=new SyncAccountWsBilling.BillingAcctInfo();
        inboundTestData.billingID='1234567';
        inboundTestData.rcUserID='1234';

        Test.startTest();
            SyncAccountWsBilling.SyncResult result=SyncAccountWsBilling.applyBillingIdAndPackages(inboundTestData);
            System.assertEquals(result.warnings.size(),1);
            System.assertEquals(result.warnings[0].code,1);
        Test.stopTest();
    }

    @isTest
    static void testNoPackagesForMigrationAccount() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'Existing RC customer',
                    Account.Service_Type__c => AccountHelper.SERVICE_TYPE_OFFICE,
                    Account.RC_User_ID__c => '1234',
                    Account.AccMigrationFlag__c => AccountHelper.ACCOUNT_MIGRATION_TYPE_SCHEDULED_BLOCKED
                }
            )
            .create()
            .getRecord();

        SyncAccountWsBilling.BillingAcctInfo inboundTestData = new SyncAccountWsBilling.BillingAcctInfo();
        inboundTestData.rcUserID = '1234';
        Test.startTest();
        SyncAccountWsBilling.SyncResult result = SyncAccountWsBilling.applyBillingIdAndPackages(inboundTestData);
        List<Package__c> packages = (List<Package__c>) new PackageSelector()
            .selectPackagesByAccountId(acc.Id)
            .executeQuery();
        System.assertEquals(packages.size(), 0, 'Account with migration flag does not contain service Accounts');
        Test.stopTest();
    }

    @isTest static void testNewSignUpNoLicences() {
        setup();
        SyncAccountWsBilling.BillingAcctInfo inboundTestData=new SyncAccountWsBilling.BillingAcctInfo();
        inboundTestData.billingID='12345';
        inboundTestData.rcUserID='123';
        inboundTestData.serviceAccounts.add(new SyncAccountWsBilling.PackageWrapper());
        inboundTestData.serviceAccounts[0].isActive=true;
        inboundTestData.serviceAccounts[0].accountPackageId='1234';
        inboundTestData.serviceAccounts[0].serviceAccountId='test package';

        Test.startTest();
            SyncAccountWsBilling.SyncResult result=SyncAccountWsBilling.applyBillingIdAndPackages(inboundTestData);
            Package__c[] packages=[select id,Account__c,Account__r.RC_User_ID__c,Account__r.Billing_ID__c,Licenses_Purchased__c from Package__c];
            System.assertEquals(packages.size(),1);
            System.assertEquals(packages[0].Account__c,result.accountID);
            System.assertEquals(packages[0].Account__r.Billing_ID__c,inboundTestData.billingID);
            System.assertEquals(packages[0].Account__r.RC_User_ID__c,inboundTestData.rcUserID);
            System.assertEquals(packages[0].Licenses_Purchased__c,0);
        Test.stopTest();
    }

    @IsTest
    static void testNewSignUpWithLicencesAndMultiplePackages() {
        setup();
        Integer numberOfPackages = 2;
        SyncAccountWsBilling.BillingAcctInfo inboundTestData = new SyncAccountWsBilling.BillingAcctInfo();
        inboundTestData.billingID = '12345';
        inboundTestData.rcUserID = '123';

        for (Integer i = 0; i < numberOfPackages; i++) {
            inboundTestData.serviceAccounts.add(new SyncAccountWsBilling.PackageWrapper());
            inboundTestData.serviceAccounts[i].isActive = true;
            inboundTestData.serviceAccounts[i].accountPackageId = '1234' + string.valueOf(i);
            inboundTestData.serviceAccounts[i].serviceAccountId = 'test package';
            inboundTestData.serviceAccounts[i].licenses.add(
                new SyncAccountWsBilling.License_Item('test_license_id_1', 10, 1)
            );
            inboundTestData.serviceAccounts[i].licenses.add(
                new SyncAccountWsBilling.License_Item('test_license_id_2', 20, 2)
            );
        }

        Test.startTest();
        Triggers.switchOff();
        SyncAccountWsBilling.SyncResult result = SyncAccountWsBilling.applyBillingIdAndPackages(inboundTestData);
        Triggers.switchOn();
        Package__c[] packages = [select id, Licenses_Purchased__c from Package__c];
        System.assertEquals(packages.size(), numberOfPackages);
        for (Integer i = 0; i < numberOfPackages; i++) {
            System.assertEquals(30, packages[0].Licenses_Purchased__c);
        }
        Test.stopTest();
    }

    @isTest static void testExistingCustomerUpdate() {
        setup();
        SyncAccountWsBilling.BillingAcctInfo inboundTestData=new SyncAccountWsBilling.BillingAcctInfo();
        inboundTestData.billingID='12345';
        inboundTestData.rcUserID='123';
        Account existingCustomerAccount=[select id from Account where Billing_ID__c='12345'];
        insert new Package__c(
            Name='test package before update',
            Account_Package_Id__c='1234',
            Licenses_Purchased__c=10,
            Account__c=existingCustomerAccount.id,
            Enterprise_Account_ID__c = existingCustomerAccount.Id
        );

        inboundTestData.serviceAccounts.add(new SyncAccountWsBilling.PackageWrapper());
        inboundTestData.serviceAccounts[0].isActive=true;
        inboundTestData.serviceAccounts[0].accountPackageId='1234';
        inboundTestData.serviceAccounts[0].serviceAccountId='test package after update';
        inboundTestData.serviceAccounts[0].licenses.add(
            new SyncAccountWsBilling.License_Item('test_license_id_1',10,1)
        );
        inboundTestData.serviceAccounts[0].licenses.add(
            new SyncAccountWsBilling.License_Item('test_license_id_2',20,2)
        );

        Test.startTest();
            SyncAccountWsBilling.SyncResult result=SyncAccountWsBilling.applyBillingIdAndPackages(inboundTestData);
            Package__c[] packages=[select id,Licenses_Purchased__c,Name from Package__c];
            System.assertEquals(packages.size(),1);
            System.assertEquals(packages[0].Licenses_Purchased__c,30);
            System.assertEquals(packages[0].Name,'test package after update');
        Test.stopTest();
    }

    @isTest static void testExistingCustomerDelete() {
        setup();
        SyncAccountWsBilling.BillingAcctInfo inboundTestData=new SyncAccountWsBilling.BillingAcctInfo();
        inboundTestData.billingID='12345';
        inboundTestData.rcUserID='123';
        Account existingCustomerAccount=[select id from Account where Billing_ID__c='12345'];
        insert new Package__c(
            Name='test package to delete',
            Account_Package_Id__c='1234',
            Licenses_Purchased__c=10,
            Account__c=existingCustomerAccount.id,
            Enterprise_Account_ID__c = existingCustomerAccount.Id
        );

        inboundTestData.serviceAccounts.add(new SyncAccountWsBilling.PackageWrapper());
        inboundTestData.serviceAccounts[0].isActive=false;
        inboundTestData.serviceAccounts[0].accountPackageId='1234';
        inboundTestData.serviceAccounts[0].serviceAccountId='test package to delete';

        Test.startTest();
            SyncAccountWsBilling.SyncResult result=SyncAccountWsBilling.applyBillingIdAndPackages(inboundTestData);
            Package__c[] packages=[select id,Licenses_Purchased__c,Name from Package__c];
            System.assertEquals(packages.size(),0);
        Test.stopTest();
    }

    @isTest
    static void testAccountUpdateError() {
        setup();
        SyncAccountWsBilling.BillingAcctInfo inboundTestData=new SyncAccountWsBilling.BillingAcctInfo();
        inboundTestData.billingID='12345';
        inboundTestData.rcUserID='';
        for(integer i=0;i<260;i++) {
            inboundTestData.rcUserID+='1';
        }
        inboundTestData.serviceAccounts.add(new SyncAccountWsBilling.PackageWrapper());
        inboundTestData.serviceAccounts[0].isActive=true;
        inboundTestData.serviceAccounts[0].accountPackageId='1234';
        inboundTestData.serviceAccounts[0].serviceAccountId='test package after update';

        Test.startTest();
            SyncAccountWsBilling.SyncResult result=SyncAccountWsBilling.applyBillingIdAndPackages(inboundTestData);
            Package__c[] packages=[select id,Licenses_Purchased__c,Name from Package__c];
            System.assertEquals(packages.size(),0);
            System.assert(result.errorMsg.contains(SyncAccountWsBilling.ACCOUNT_ERROR_PREFIX));
        Test.stopTest();
    }

    @isTest
    static void testPackageUpdateError() {
        setup();
        SyncAccountWsBilling.BillingAcctInfo inboundTestData=new SyncAccountWsBilling.BillingAcctInfo();
        inboundTestData.billingID='12345';
        inboundTestData.rcUserID='123';
        Account existingCustomerAccount=[select id from Account where Billing_ID__c='12345'];

        inboundTestData.serviceAccounts.add(new SyncAccountWsBilling.PackageWrapper());
        inboundTestData.serviceAccounts[0].isActive=true;
        inboundTestData.serviceAccounts[0].accountPackageId='1234';
        inboundTestData.serviceAccounts[0].serviceAccountId='';
        for(integer i=0;i<260;i++) {
            inboundTestData.serviceAccounts[0].serviceAccountId+='1';
        }
        Test.startTest();
            SyncAccountWsBilling.SyncResult result=SyncAccountWsBilling.applyBillingIdAndPackages(inboundTestData);
            Package__c[] packages=[select id,Licenses_Purchased__c,Name from Package__c];
            System.assertEquals(packages.size(),0);
            System.assert(result.errorMsg.contains(SyncAccountWsBilling.PACKAGE_ERROR_PREFIX));
        Test.stopTest();
    }

    @isTest
    private static void testSignUpSyncForFaxAccount() {

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Account',
                Account.RecordTypeId => AccountHelper.RT_ID_CUSTOMER_ACCOUNT
            })
            .create()
            .getRecord();

        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.AccountId => acc.Id,
                    Contact.LastName => ValueProviderBuilder.provideUniqueString('testContactLastName'),
                    Contact.Email => ValueProviderBuilder.provideUniqueEmail('testemail')
                }
            )
            .create()
            .getRecord();

        SyncAccountWsBilling.syncAcctInputParamBilling params = new SyncAccountWsBilling.syncAcctInputParamBilling();
        params.In_TIERNAME = 'Fax';
        params.In_Company = acc.Name;
        params.In_BillingID = '111111';
        params.In_RCUserID = '222222';
        params.In_ContactEmail = testContact.Email;
        params.proc_debugmsg = '';

        SyncAccountWsBilling.syncAcctInputParamBilling result;

        Test.startTest();
            result = SyncAccountWsBilling.synAccountNew(params);
        Test.stopTest();

        System.assert(
            result.proc_debugmsg.contains('IN searchContactByMail::'),
            'Field proc_debugmsg populated incorrectly'
        );
        System.assert(
            result.proc_debugmsg.contains('IN handleUpdateAccount::'),
            'Field proc_debugmsg populated incorrectly'
        );
        System.assert(
            result.proc_debugmsg.contains('IN handleReturn::'),
            'Field proc_debugmsg populated incorrectly'
        );

        System.assertEquals(
            acc.Id,
            result.Out_AccountID,
            'Field Out_AccountID is not equal to Id of updated Account'
        );

        Account reselectedAcc = (Account) new AccountSelector()
            .selectAccounts()
            .selectFields(new List<Schema.SObjectField>{
                Account.Billing_ID__c,
                Account.RC_User_ID__c
            })
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{ acc.Id })
            .executeQuery()
            .get(0);

        System.assertEquals(
            params.In_BillingID,
            reselectedAcc.Billing_ID__c,
            'Account.Billing_ID__c should be populated with value from In_BillingID parameter'
        );

        System.assertEquals(
            params.In_RCUserID,
            reselectedAcc.RC_User_ID__c,
            'Account.RC_User_ID__c should be populated with value from In_RCUserID parameter'
        );
    }

    @isTest
    private static void testSearchContactByEmailExceptions() {

        Boolean isExpectedExceptionThrown = false;
        try {
            SyncAccountWsBilling.searchContactByEmail(null);
        } catch (Exception ex) {
            System.assert(
                ex.getMessage().contains('Email is blank'),
                'Exception should contain specific message'
            );
            isExpectedExceptionThrown = true;
        }
        System.assert(isExpectedExceptionThrown, 'Expected exception should be thrown');

        isExpectedExceptionThrown = false;

        String email = 'notexistemail@someemailvendor.com';
        try {
            SyncAccountWsBilling.searchContactByEmail(email);
        } catch (Exception ex) {
            System.assert(
                ex.getMessage().contains('Contact with Email "' + email + '" not found'),
                'Exception should contain specific message'
            );
            isExpectedExceptionThrown = true;
        }
        System.assert(isExpectedExceptionThrown, 'Expected exception should be thrown');
    }

    @isTest
    private static void testSignUpSyncForFaxAccountWithMultipleContacts() {

        List<Account> accs = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ValueProviderBuilder.provideUniqueString('Test Account'),
                Account.RecordTypeId => AccountHelper.RT_ID_CUSTOMER_ACCOUNT
            })
            .quantity(2)
            .create()
            .getRecords();

        Id firstAccId = accs.get(0).Id;

        String testEmail = 'testemail@vendor.com';

        List<Contact> testContact = (List<Contact>) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.AccountId => ValueProviderBuilder.provideParents(accs),
                    Contact.LastName => ValueProviderBuilder.provideUniqueString('testContactLastName'),
                    Contact.Email => testEmail
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => 'Test Opportunity',
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Opportunity.AccountId => firstAccId
            })
            .create()
            .getRecord();

        SyncAccountWsBilling.syncAcctInputParamBilling params = new SyncAccountWsBilling.syncAcctInputParamBilling();
        params.In_TIERNAME = 'Fax';
        params.In_Company = accs.get(0).Name;
        params.In_BillingID = '111111';
        params.In_RCUserID = '222222';
        params.In_ContactEmail = testEmail;
        params.proc_debugmsg = '';

        SyncAccountWsBilling.syncAcctInputParamBilling result;

        Test.startTest();
            result = SyncAccountWsBilling.synAccountNew(params);
        Test.stopTest();

        Account reselectedAcc = (Account) new AccountSelector()
            .selectAccounts()
            .selectFields(new List<Schema.SObjectField>{
                Account.Billing_ID__c,
                Account.RC_User_ID__c
            })
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{ firstAccId })
            .executeQuery()
            .get(0);

        System.assertEquals(
            params.In_BillingID,
            reselectedAcc.Billing_ID__c,
            'Account.Billing_ID__c should be populated with value from In_BillingID parameter'
        );

        System.assertEquals(
            params.In_RCUserID,
            reselectedAcc.RC_User_ID__c,
            'Account.RC_User_ID__c should be populated with value from In_RCUserID parameter'
        );
    }

    @isTest
    private static void testFedRampAccountUpdate() {

        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ValueProviderBuilder.provideUniqueString('Test Account'),
                Account.RecordTypeId => AccountHelper.RT_ID_CUSTOMER_ACCOUNT,
                Account.isFedRamp__c => false
            })
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => 'Test Opportunity',
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Opportunity.AccountId => testAcc.Id,
                Opportunity.isFedRamp__c => true
            })
            .create()
            .getRecord();

        SyncAccountWsBilling.syncAcctInputParamBilling params = new SyncAccountWsBilling.syncAcctInputParamBilling();
        params.In_OpportunityID = testOpp.Id;
        params.In_AccountID = testAcc.Id;

        Test.startTest();

            SyncAccountWsBilling.synAccountNew(params);
            Account updatedAccount = (Account) new AccountSelector()
                .selectAccountById(testAcc.Id)
                .executeQuery()
                .get(0);

        Test.stopTest();

        System.assertEquals(true,
            updatedAccount.isFedRamp__c,
            'If Opportunity FedRamp checkbox => true, Account FedRamp checkbox also must be true'
        );
    }

    @isTest
    static void testUpsertServiceAccountsForMultiproduct() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Account',
                Account.RC_User_Id__c => '21331231'
            })
            .create()
            .getRecord();

        Package__c pack = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Name => 'serviceAccId',
                Package__c.Account__c => acc.Id,
                Package__c.Account_Package_Id__c => '21331231',
                Package__c.Enterprise_Account_ID__c => acc.Id
            })
            .create()
            .getRecord();

        SyncAccountWsBilling.syncAcctInputParamBilling params = new SyncAccountWsBilling.syncAcctInputParamBilling();
        params.proc_debugmsg = '';
        params.serviceAccounts = new List<Package__c>{pack};
        params.proc_AccountId = acc.Id;

        Boolean result;

        Test.startTest();
            result = SyncAccountWsBilling.upsertServiceAccounts(params);
        Test.stopTest();

        List<Package__c> packageList = (List<Package__c>) new PackageSelector()
            .selectPackagesByIdForSyncAccountWsTest(new List<Id> {pack.Id})
            .executeQuery();

        System.assert(result, 'Method should return true');
        System.assertEquals('IN upsertServiceAccounts::', params.proc_debugmsg, 'Field proc_debugmsg populated incorrectly');
        System.assertEquals(acc.Id, packageList.get(0).Account__c, 'Account__c field should be populated with parent Account Id');
        System.assertEquals(acc.Id, packageList.get(0).Enterprise_Account_ID__c, 'Enterprise_Account_ID__c field should be populated with parent Account Id');
    }

    @isTest
    static void testShouldCreateOpportunityForLegacyCCMigration() {
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.AccMigrationFlag__c => AccountHelper.ACCOUNT_MIGRATION_TYPE_IN_PROGRESS_BLOCKED,
                Account.Service_Type__c => AccountHelper.SERVICE_TYPE_RCCC
            })
            .build()
            .getRecord();
        Test.startTest();
            Boolean trueResult = SyncAccountWsBilling.shouldCreateOpportunityForLegacyCCMigration(testAcc, true);
            Boolean resultWithBillingIsNotChanged = SyncAccountWsBilling.shouldCreateOpportunityForLegacyCCMigration(testAcc, false);
            Boolean resultWithnullAccount = SyncAccountWsBilling.shouldCreateOpportunityForLegacyCCMigration(null, true);

            testAcc.AccMigrationFlag__c = 'Not in progress';
            Boolean resultWithAccountWithMigrationNotInProgress = SyncAccountWsBilling.shouldCreateOpportunityForLegacyCCMigration(testAcc, true);

            testAcc.AccMigrationFlag__c = AccountHelper.ACCOUNT_MIGRATION_TYPE_IN_PROGRESS_BLOCKED;
            testAcc.Service_Type__c = AccountHelper.SERVICE_TYPE_FAX;
            Boolean resultWithServiceTypeNotRCCC = SyncAccountWsBilling.shouldCreateOpportunityForLegacyCCMigration(testAcc, true);
        Test.stopTest();

        System.assertEquals(true, trueResult, 'Must return true');
        System.assertEquals(false, resultWithBillingIsNotChanged, 'If billing id was not changed, should have returned false');
        System.assertEquals(false, resultWithnullAccount, 'Must return false, when no account is provided');
        System.assertEquals(false, resultWithAccountWithMigrationNotInProgress, 'If migration status is not in progress, then should return false');
        System.assertEquals(false, resultWithServiceTypeNotRCCC, 'Expected false, when provided account with service type not being Contact Center');
    }

    @isTest
    static void testUpdateAccountForLegacyCCMigration() {
        new SObjectBuilder(NGBS_Settings__c.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    NGBS_Settings__c.BaseEndpoint__c => 'https://testapi',
                    NGBS_Settings__c.CatalogPath__c => '/restapi/v1.0/catalog',
                    NGBS_Settings__c.AccountManagerPath__c => '/restapi/account-manager/v1.0',
                    NGBS_Settings__c.Login__c => '123',
                    NGBS_Settings__c.Password__c => '456'
                })
            .create();
        Test.setMock(HttpCalloutMock.class, new CCMigrationNGBSAPIMock());

        String accountName = 'Test Account Name';

        SyncAccountWsBilling.syncAcctInputParamBilling params = new SyncAccountWsBilling.syncAcctInputParamBilling();
        params.In_FirstName = 'FirstName';
        params.In_LastName = 'LastName';
        params.In_ContactEmail = 'mail12345@ringcentral.com';
        params.In_Company = '[TEST]_MIGRATION';
        params.In_Contactphone = '+16175550143';
        params.In_RCUserID = '21331231';
        params.In_BillingID = '55525013';

        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => accountName,
                Account.AccMigrationFlag__c => AccountHelper.ACCOUNT_MIGRATION_TYPE_IN_PROGRESS_BLOCKED,
                Account.Service_Type__c => AccountHelper.SERVICE_TYPE_RCCC,
                Account.RC_Brand__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Account.RC_User_Id__c => '21331231'
            })
            .create()
            .getRecord();

        Test.startTest();
            SyncAccountWsBilling.syncAcctInputParamBilling result = SyncAccountWsBilling.synAccountNew(params);

            System.assertNotEquals(null, result, 'The result should not be null');
            Assert.isTrue(
                SyncAccountWsBilling.IS_ACCOUNT_FOR_LEGACY_CC_MIGRATION_PROCESSING,
                'The static variable must be set to true, if the Migration CCMigrationQueueable was called'
            );
        Test.stopTest();

        String expectedNameForCreatedOppForCCMigration = String.format(
            CCMigrationQueueable.CC_LEGACY_BASE_LINE_OPPORTUNITY_NAME_FORMAT,
            new List<String> {CCMigrationQueueable.CC_LEGACY_BASE_LINE_OPPORTUNITY_NAME, params.In_Company}
        );

        Set<Schema.SObjectField> fieldsToRetrieve = new Set<Schema.SObjectField> {
            Opportunity.Downgrade_Reason_Opp__c,
            Opportunity.IsMultiProductTechnicalOpportunity__c,
            Opportunity.MasterOpportunity__c,
            Opportunity.StageName,
            Opportunity.Type,
            Opportunity.Tier_Name__c,
            Opportunity.AccountId,
            Opportunity.Name,
            Opportunity.Brand_Name__c
        };
        Opportunity createdTechnicalOppForCCMigration = (Opportunity) new ListOptional(
            new OpportunitySelector()
                .selectOpportunityByName(expectedNameForCreatedOppForCCMigration)
                .withoutSelectorFieldsIncluded()
                .selectFields(fieldsToRetrieve)
                .executeQuery()
            )
            .getFirst();

        System.assertNotEquals(null, createdTechnicalOppForCCMigration, 'Technical opportunity must be created');
        System.assertEquals(
            OpportunityHelper.STAGE_NAME_DOWNGRADED,
            createdTechnicalOppForCCMigration.StageName,
            'A technical base-line Opportunity for CC Migration has to be downgraded'
        );
        System.assertEquals(
            OpportunityHelper.DOWNGRADE_REASON_CC_MIGRATION,
            createdTechnicalOppForCCMigration.Downgrade_Reason_Opp__c,
            'Downgrade reason for a technical base-line Opportunity for CC Migration has to be set to "Migration"'
        );
        System.assert(
            createdTechnicalOppForCCMigration.IsMultiProductTechnicalOpportunity__c,
            'A technical base-line Opportunity for CC Migration must be technical'
        );
        System.assertEquals(
            null,
            createdTechnicalOppForCCMigration.MasterOpportunity__c,
            'A technical base-line Opportunity for CC Migration should not have Master Opportunity'
        );
        System.assertEquals(
            OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
            createdTechnicalOppForCCMigration.Type,
            'A technical base-line Opportunity for CC Migration should be for New Business'
        );
        System.assertEquals(
            OpportunityHelper.TIER_RC_CONTACT_CENTER,
            createdTechnicalOppForCCMigration.Tier_Name__c,
            'A technical base-line Opportunity for CC Migration should only be for Contact Center'
        );
        System.assertEquals(
            testAccount.Id,
            createdTechnicalOppForCCMigration.AccountId,
            'A technical base-line Opportunity for CC Migration should be connected to a technical account'
        );
        System.assertEquals(
            testAccount.RC_Brand__c,
            createdTechnicalOppForCCMigration.Brand_Name__c,
            'A technical base-line Opportunity for CC Migration should the same brand as technical account'
        );
    }

    @isTest
    static void testIsLegacyCCMigrationProcess() {
        SyncAccountWsBilling.IS_ACCOUNT_FOR_LEGACY_CC_MIGRATION_PROCESSING = false;
        Assert.isFalse(SyncAccountWsBilling.isLegacyCCMigrationProcess(), 'When there is no Legacy Migration, should return false');

        SyncAccountWsBilling.IS_ACCOUNT_FOR_LEGACY_CC_MIGRATION_PROCESSING = true;
        Assert.isTrue(SyncAccountWsBilling.isLegacyCCMigrationProcess(), 'When there is Legacy Migration, should return true');
    }
}