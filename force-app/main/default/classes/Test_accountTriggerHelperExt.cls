@isTest
private class Test_accountTriggerHelperExt {
    private static final String PARTNER_ID = '64376821783';
    private static final String CUSTOMER_ACCOUNT_NAME = 'CustomerTestAccountName';
    private static final String CUSTOMER_ACCOUNT_NAME_EMPTY_PARTNER_ID = 'CustomerTestAccountNameEmptyParthnerId';

    private static final String PARTNER_ID_1 = '0001';
    private static final String PARTNER_ID_2 = '0002';

    @testSetup
    private static void setup(){
        User currentOwner = (User) new SObjectBuilder(User.sObjectType)
            .create()
            .getRecord();

        /*
            This accounts must be created in testSetup to provide create/update operations in a separate context.
            Otherwise will be triggered BY_PASS static vars and needed operations on accounts would not be done.
        */
        Id partnerRecordTypeId = Schema.SObjectType.Account
            .getRecordTypeInfosByName()
            .get(AccountTriggerHelperExt.PARTNER_ACCOUNT)
            .getRecordTypeId();

        new SObjectBuilder(Account.sObjectType)
            .setField(Account.Partner_Id__c, PARTNER_ID)
            .setField(Account.Type, 'Partner')
            .setField(Account.RecordTypeId, partnerRecordTypeId)
            .setField(Account.Current_Owner__c, currentOwner.Id)
            .create();

        Id customerRecordTypeId = Schema.SObjectType.Account
            .getRecordTypeInfosByName()
            .get(AccountTriggerHelperExt.CUSTOMER_ACCOUNT)
            .getRecordTypeId();

        new SObjectBuilder(Account.sObjectType)
            .setField(Account.Name, CUSTOMER_ACCOUNT_NAME)
            .setField(Account.Partner_Id__c, PARTNER_ID)
            .setField(Account.Type, AccountHelper.TYPE_CUSTOMER)
            .setField(Account.RecordTypeId, customerRecordTypeId)
            .setField(Account.Current_Owner__c, UserInfo.getUserId())
            .create()
            .getRecord();

        new SObjectBuilder(Account.sObjectType)
            .setField(Account.Name, CUSTOMER_ACCOUNT_NAME_EMPTY_PARTNER_ID)
            .setField(Account.Partner_Id__c, null)
            .setField(Account.Type, AccountHelper.TYPE_CUSTOMER)
            .setField(Account.RecordTypeId, customerRecordTypeId)
            .setField(Account.Current_Owner__c, UserInfo.getUserId())
            .create();

        // Partner Accounts
        Account partnerAcc1 = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner Account').getRecordTypeId(),
            Name = 'Partner One',
            Type = 'Partner',
            Partner_ID__c = PARTNER_ID_1
        );
        insert partnerAcc1;

        Account partnerAcc2 = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner Account').getRecordTypeId(),
            Name = 'Partner Two',
            Type = 'Partner',
            Partner_ID__c = PARTNER_ID_2
        );
        insert partnerAcc2;

        // Customer Account linked to Partner 1
        Account customerAcc = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account').getRecordTypeId(),
            Name = 'Customer One',
            Type = 'Customer',
            Partner_ID__c = PARTNER_ID_1
        );
        insert customerAcc;
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void accountTriggerHelperExtUpdate() {

        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = true;
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = true;

        List<Account> lstAccount = new List<Account>();

        Profile salesAgentProfile = [SELECT Id FROM Profile WHERE Name = 'Sales Agent SDR w Insidesales' LIMIT 1];

        User testUser = new User(alias = 'u1', email='u1234@testorg.com',
          emailencodingkey='UTF-8', lastname='Testing123', ProfileId=salesAgentProfile.Id,
          languagelocalekey='en_US',localesidkey='en_US', country='United States',
          timezonesidkey='America/Los_Angeles', username=UserHelper.getUniqueUserName(), IsActive=true
        );
        insert testUser;

        Account accObj0 = new Account();
        accObj0.Name = 'RCTest';
        accObj0.Number_of_DL_s__c = 5;

        Account accObj01 = new Account();
        accObj01.Name = 'TestAccount1023';
        accObj01.Number_of_DL_s__c = 5;
        accObj01.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account')
            .getRecordTypeId();
        accObj01.Type ='Customer';

        Account accObj00 = new Account();
        accObj00.Name = 'TestAccount1023';
        accObj00.Number_of_DL_s__c = 5;
        accObj00.ParentId = accObj01.Id;
        accObj00.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account')
            .getRecordTypeId();
        accObj00.Type ='Customer';

        Account accObj02 = new Account();
        accObj02.Name = 'TestAccount1023';
        accObj02.Number_of_DL_s__c = 5;
        accObj02.ParentId = accObj01.Id;
        accObj02.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account')
            .getRecordTypeId();
        accObj02.Type ='Customer';

        List<Account> insertList = new List<Account>{accObj0,accObj01,accObj00,accObj02};
        insert insertList;

        Contact contObj = new Contact();
        contObj.AccountId =  accObj0.Id;
        contObj.Email = 'rc1234@test.com';
        contObj.LastName = 'Test Last232';
        contObj.FirstName = 'Test First333';
        insert contObj;

        Schema.DescribeSObjectResult result = Account.SObjectType.getDescribe();
        Map<ID,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosById();
        AccountTriggerHelperExt objAccountTriggerHelperExt = new AccountTriggerHelperExt();

        Account accObj = new Account();
        accObj.Name = 'TestAccount1023';
        accObj.Number_of_DL_s__c = 5;
        accObj.ParentId = accObj0.Id;
        accObj.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account').getRecordTypeId();
        accObj.Type ='Partner';
        accObj.Partner_ID__c ='1234';
        accObj.RC_Account_Status__c = 'office';
        accObj.OwnerId = testUser.Id;
        accObj.Phone = '9856321475';
        accObj.BillingCountry = 'test';
        insert accObj;
        lstAccount.add(accObj);
        lstAccount.add(accObj01);
        accObj01.Number_of_DL_s__c = 6;
        accObj01.Website = 'gogle.com';
        accObj.RC_Account_Status__c = 'office12';
        accObj.Current_Owner__c = testUser.Id;
        accObj01.Partner_ID__c ='1234';
        system.debug('$$$$$$$$$ here we are $$$$$$$$$$$$$$$ ');
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
        //update lstAccount;
        AccountTriggerHelperExt.accountRecordTypeInformation(lstAccount);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void accountTriggerHelperInsert() {

        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = true;
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = true;
        
        List<Account> accountList = new List<Account>();
        Map<id, User> mapUser = new Map<id, User>();

        Schema.DescribeSObjectResult result = Account.SObjectType.getDescribe();
        Map<ID,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosById();

        Account acctObj = new Account();
        acctObj.Name = 'TestAccount1';
        acctObj.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account').getRecordTypeId();
        acctObj.Type ='Partner';
        acctObj.RC_Account_Status__c = 'office13';
        acctObj.RC_User_ID__c = '6783';
        insert acctObj;
        accountList.add(acctObj);
        acctObj.Partner_ID__c ='1234';
        acctObj.Current_Owner__c = HardcodedIdsMapper.getMatchedObjectId('00580000003SZir');
        //update accountList;

        Account accObj = new Account();
        accObj.Name = 'TestAccount12';
        accObj.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account').getRecordTypeId();
        accObj.Type ='Partner';
        accObj.RC_Account_Status__c = 'office13';
        accObj.RC_User_ID__c = '678';
        insert accObj;
        accountList.add(accObj);
        accObj.Partner_ID__c ='1234';
        acctObj.Current_Owner__c = HardcodedIdsMapper.getMatchedObjectId('00580000003SZir');
        //update accountList;

        Account objAcc = new Account();
        objAcc.Name = 'TestAccount10234';
        objAcc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account')
            .getRecordTypeId();
        objAcc.Type ='Customer';
        objAcc.Partner_ID__c ='1234';
        objAcc.RC_Account_Status__c = 'office13';
        insert objAcc;
        accountList.add(objAcc);
        objAcc.RC_Account_Status__c = 'office14';
        acctObj.Current_Owner__c = HardcodedIdsMapper.getMatchedObjectId('00580000003SZir');
        //update accountList;
        AccountTriggerHelperExt.accountSharingOnInsert(accountList);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void accountSharingOnUpdate0() {
        Schema.DescribeSObjectResult result = Account.SObjectType.getDescribe();
        Map<ID,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosById();
        Map<id, User> mapUser = new Map<id, User>();
        Map<Id,Account>oldAccountMap = new Map<Id,Account>();
        List<Account> accList = new List<Account>();

        Profile salesAgentProfile = [SELECT Id FROM Profile WHERE Name = 'Sales Agent SDR w Insidesales' LIMIT 1];

        User testUser = new User(alias = 'u1', email='u1234@testorg.com',
            emailencodingkey='UTF-8', lastname='Testing12', ProfileId=salesAgentProfile.Id,
            languagelocalekey='en_US',localesidkey='en_US', country='United States',
            timezonesidkey='America/Los_Angeles', username=UserHelper.getUniqueUserName(), IsActive=true);

        insert testUser;
        mapUser.put(testUser.id,testUser);

        Account acctObj = new Account();
        acctObj.Name = 'RCTest';
        acctObj.Website = 'https://www.google.co.in/';
        acctObj.NumberOfEmployees = 2;
        acctObj.Industry = 'Consulting: IT';
        acctObj.Is_the_customer_interested_in_porting__c = 'Yes';
        /* acctObj.Current_Owner__c = HardcodedIdsMapper.getMatchedObjectId('00580000003SZir');
        acctObj.OwnerId = testUser.Id;*/
        acctObj.RC_Account_Number__c = '8377081942';
        acctObj.Service_Type__c = 'office12';
        acctObj.RC_Account_Status__c = 'Trial 7 CC';
        insert acctObj;
        accountTriggerHelperExt.oldAccountMap.put(acctObj.id,acctObj);
        //accList.add(acctObj);
        acctObj.Industry ='Consulting: Other';
        acctObj.Website = 'https://www.gmail.com';
        //update accList;

        update acctObj;
        system.debug('@#@#@#@#@323'+accountTriggerHelperExt.oldAccountMap);
        //accountTriggerHelperExt.accountSharingOnUpdate0(accList, mapUser);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void accountSharingOnUpdate1() {
        Schema.DescribeSObjectResult result = Account.SObjectType.getDescribe();
        Map<ID,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosById();
        Map<Id,Account>oldAccountMap = new Map<Id,Account>();
        Map<id, User> mapUser = new Map<id, User>();
        List<Account> accountList = new List<Account>();
        Set<String>  setPartnerId  = New Set<String>();
        Map<String,Account> MapPartnerId = new Map<String,Account>();

        Profile salesAgentProfile = [SELECT Id FROM Profile WHERE Name = 'Sales Agent SDR w Insidesales' LIMIT 1];

        User testUser = new User(alias = 'u1', email='u1234@testorg.com',
        emailencodingkey='UTF-8', lastname='Testing12', ProfileId=salesAgentProfile.Id,
        languagelocalekey='en_US',localesidkey='en_US', country='United States',
        timezonesidkey='America/Los_Angeles', username=UserHelper.getUniqueUserName(), IsActive=true);

        insert testUser;
        mapUser.put(testUser.id,testUser);

        Account acctObj = new Account();
        acctObj.Name = 'TestAccount98';
        acctObj.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account').getRecordTypeId();
        acctObj.Type ='Partner';
        acctObj.Partner_ID__c ='456';
        acctObj.Current_Owner__c = testUser.id;
        insert acctObj;

        Account accObj = new Account();
        accObj.Name = 'TestAccount12';
        accObj.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account')
            .getRecordTypeId();
        accObj.Type ='Customer';
        accObj.Partner_ID__c ='098';
        insert accObj;
        accObj.Partner_ID__c ='456';
        update accObj;
        accountTriggerHelperExt.accountSharingOnUpdate2(accountList);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void toggleNumberPorting() {

        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = true;
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = true;
        TriggerHandler.BY_PASS_ACCOUNT_ON_AFTER = true;

        Account accObj = new Account();
        accObj.Name = 'RCTest';
        insert accObj;

        Case caseObj = new Case();
        caseObj.Subject = 'Test Subject';
        caseObj.status = 'New';
        caseObj.Priority='P3';
        caseObj.AccountId = accObj.Id;
        insert caseObj;


        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
        TriggerHandler.BY_PASS_ACCOUNT_ON_AFTER = false;

        Test.startTest();
        caseObj.status = 'Closed';
        update caseObj;
        Test.stopTest();
        //accountTriggerHelperExt.toggleNumberPorting(accObj);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void accountSharingOnUpdate2() {
        Schema.DescribeSObjectResult result = Account.SObjectType.getDescribe();
        Map<ID,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosById();
        Map<id, User> mapUser = new Map<id, User>();
        Map<Id,Account>oldAccountMap = new Map<Id,Account>();
        List<Account> accountList = new List<Account>();

        Account accObj = new Account();
        accObj.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account')
            .getRecordTypeId();
        accObj.Name = 'RCIndiaTest';
        accObj.Do_Not_Creation_Implementation__c =  true;
        accObj.Type = 'Customer';
        accObj.Partner_ID__c = '345';
        insert accObj;
        accObj.Do_Not_Creation_Implementation__c =  false;
        update accObj;

        Account acctObj = new Account();
        acctObj.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account').getRecordTypeId();
        acctObj.Name = 'RCIndiaTest1';
        acctObj.Do_Not_Creation_Implementation__c = true;
        acctObj.Type = 'Partner';
        acctObj.Partner_ID__c = '345';
        insert acctObj;
        acctObj.Do_Not_Creation_Implementation__c =  false;
        update acctObj;
        accountTriggerHelperExt.accountSharingOnUpdate2(accountList);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void calculateAccountHierarchyTotalDLS() {
        List<Account> accountList = new List<Account>();
        Set<String> testid= new Set<String>();
        Account accObj0 = new Account();
        accObj0.Name = 'RCTest';
        accObj0.RC_Account_Status__c ='Paid';
        //accObj0.Ultimate_Parent_Account_ID__c = '001Q000000pyRQk';
        insert accObj0;
        accountList.add(accObj0);
        testid.add(accObj0.Id);

        Account accObj = new Account();
        accObj.Name = 'Rctest1';
        accObj.ParentId = accObj0.Id;
        accObj.RC_Account_Status__c ='Paid';
        // accObj.Ultimate_Parent_Account_ID__c = '001Q000000pyRQk';
        insert accObj;
        accountList.add(accObj);
        testid.add(accObj.Id);
        accountTriggerHelperExt.runAccountHierarchyCalculation(testid);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void accountReferralTest() {
        Schema.DescribeSObjectResult result = Account.SObjectType.getDescribe();
        Map<String,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosByName();
        List<Account> accountList = new List<Account>();
        Set<String> testid= new Set<String>();
        Account accObj0 = new Account();
        accObj0.Name = 'RCTest';
        accObj0.recordTypeId =rtMapByName.get('Partner Account').getRecordTypeId();
        accObj0.Partner_Sign_Up_Date__c = System.today();
        accObj0.Partner_ID__c = '1234';
        //accObj0.Ultimate_Parent_Account_ID__c = '001Q000000pyRQk';
        insert accObj0;

        Test.startTest();
            AccountTriggerHelperExt.partnerIdToAccountMap = new Map<String,Account>{String.valueOf(accObj0.Partner_ID__c) => accObj0};
            AccountTriggerHelperExt.eligiblePartnerAccountStaticIdSet = new Set<Id>{accObj0.Id};
            accountList.add(accObj0);
            testid.add(accObj0.Id);

            Account accObj = new Account();
            accObj.Name = 'Rctest1';
            accObj.ParentId = accObj0.Id;
            accObj.RC_Account_Status__c ='Paid';
            accObj.Partner_ID__c = '1234';
            accObj.recordTypeId = rtMapByName.get('Customer Account').getRecordTypeId();
            accObj.RC_Signup_Date__c = System.Now();
            // accObj.Ultimate_Parent_Account_ID__c = '001Q000000pyRQk';
            insert accObj;
            Account_Split__c asp = new Account_Split__c(Account__c = accObj.id,Role__c ='VAR Shared Agent',Agent_Credit_Sub_Type__c = 'Overlay Shared', Begin_Date__c = Date.today(), Commission__c = 10);
            insert asp;
            accObj.RC_Account_Status__c ='test';
            update accObj;
            accObj.RC_Account_Status__c ='Paid';
            update accObj;
            accountTriggerHelperExt.createUpdateAccountSplits(new List<Account>{accObj}, new Set<Id>{accObj0.Id});
        Test.stoptest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void deleteAccntSplitOnPartnerChange() {
        Schema.DescribeSObjectResult result = Account.SObjectType.getDescribe();
        Map<String,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosByName();
        List<Account> accountList = new List<Account>();
        Set<String> testid= new Set<String>();
        Account accObj0 = new Account();
        accObj0.Name = 'RCTest';
        accObj0.recordTypeId =rtMapByName.get('Partner Account').getRecordTypeId();
        system.debug('======= accObj0.recordTypeId ====== '+ accObj0.recordTypeId);
        accObj0.Partner_Sign_Up_Date__c = System.today();
        accObj0.Partner_ID__c = '1234';
        //accObj0.Ultimate_Parent_Account_ID__c = '001Q000000pyRQk';
        insert accObj0;
        system.debug('======= accObj0.recordTypeId ====== '+ accObj0.recordTypeId);
        accountList.add(accObj0);
        testid.add(accObj0.Id);

        Test.startTest();
            Account accObj = new Account();
            accObj.Name = 'Rctest1';
            accObj.ParentId = accObj0.Id;
            accObj.RC_Account_Status__c ='Paid';
            accObj0.Partner_ID__c = '1234';
            accObj.recordTypeId = rtMapByName.get('Customer Account').getRecordTypeId();
            system.debug('======= accObj.recordTypeId ====== '+ accObj.recordTypeId);
            accObj.RC_Signup_Date__c = System.Now();
            // accObj.Ultimate_Parent_Account_ID__c = '001Q000000pyRQk';
            insert accObj;
            AccountTriggerHelperExt.oldAccountMap = new Map<Id,Account>{accObj.Id => accObj};
            Account_Split__c asp = new Account_Split__c(Account__c = accObj.id,Role__c ='VAR Shared Agent',Agent_Credit_Sub_Type__c = 'Overlay Shared', Begin_Date__c = Date.today(), Commission__c = 10);
            insert asp;

            accObj.RC_Account_Status__c ='test';
            accObj0.Partner_ID__c = '4576';
            update accObj;

            accountTriggerHelperExt.deleteAccntSplitOnPartnerChange(new Map<id,Account>{accObj.Id => accObj});
        Test.stoptest();
    }

    @IsTest
    static void testGetSetOfIds() {
        BatchJobQueue__c bjq = new BatchJobQueue__c();
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 100; i++) {
            Account account = new Account();
            account.Name = 'TestChildOfAccHierarchy-' + i;
            testAccounts.add(account);
        }
        insert testAccounts;

        String setIds = '';
        for (Account acc : [SELECT Id FROM Account]) {
            setIds += acc.Id + ', ';
        }
        setIds = setIds.left(setIds.length() - 3);
        bjq.RecordIdsToBeProcessedInQueue__c = setIds;
        insert bjq;

        List<BatchJobQueue__c> bJQObjects = [SELECT Id, RecordIdsToBeProcessedInQueue__c FROM BatchJobQueue__c];
        List<BatchJobQueue__c> emptyList = new List<BatchJobQueue__c>();

        System.assert(!AccountTriggerHelperExt.getSetOfIds(bJQObjects).isEmpty());
        System.assertEquals(null, AccountTriggerHelperExt.getSetOfIds(emptyList));
    }

    @IsTest
    static void testBatchJobWithErorrs() {
        Account testAcc = (Account) new SObjectBuilder(Account.sObjectType)
                                                       .setField(Account.Number_of_DL_s__c, 4)
                                                       .setField(Account.RC_Account_Status__c, 'Paid')
                                                       .create()
                                                       .getRecord();

        BatchJobQueue__c batchQueue = (BatchJobQueue__c) new SObjectBuilder(BatchJobQueue__c.sObjectType)
                                                                            .setField(BatchJobQueue__c.Status__c, 'New')
                                                                            .setField(BatchJobQueue__c.BatchJobName__c, 'CalculateAccountHierarchyBatch')
                                                                            .setField(BatchJobQueue__c.RecordIdsToBeProcessedInQueue__c, testAcc.id)
                                                                            .create()
                                                                            .getRecord();
        testAcc.Name = null;
        Test.startTest();
        AccountTriggerHelperExt.calculateAccountHierarchyTotalDLS(new List<Account>{testAcc});
        Test.stopTest();
        BatchJobQueueSelector batchSelector = new BatchJobQueueSelector();
        batchQueue = (BatchJobQueue__c)batchSelector.selectBatchJobQueueObjects()
                                                    .executeQuery()[0];
        System.assertEquals('Failed', batchQueue.Status__c, 'Status for BatchJobQueue should be failed');
    }

    // Test trigger logic in AccountTrigger BeforeUpdate
    @isTest
    private static void testCurrentOwnerOnChangePartnerId_NullParterIdUpdate() {
        List<Account> customerAccountList = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object>{CUSTOMER_ACCOUNT_NAME_EMPTY_PARTNER_ID})
            .selectFields(new List<String>{'Current_Owner__c'})
            .executeQuery();
        System.assertEquals(1, customerAccountList.size());

        Account customerAccount = customerAccountList[0];
        Id oldCurrentOwnerId = customerAccount.Current_Owner__c;

        Test.startTest();
        customerAccount.Partner_Id__c = PARTNER_ID;
        update customerAccount;
        Test.stopTest();

        customerAccount = [SELECT Id, Current_Owner__c FROM Account WHERE Name = :CUSTOMER_ACCOUNT_NAME_EMPTY_PARTNER_ID];
        System.assertEquals(
            oldCurrentOwnerId,
            customerAccount.Current_Owner__c,
            'Current_Owner_Id should not be changed after update of PartnerId in CustomerAccount'
        );
    }

    // Test trigger logic in AccountTrigger BeforeInsert
    @isTest
    private static void testCurrentOwnerOnChangePartnerId_NonNullParterIdInsert() {
        Id oldCurrentOwnerId = UserInfo.getUserId();
        Id customerRecordTypeId = Schema.SObjectType.Account
            .getRecordTypeInfosByName()
            .get(AccountTriggerHelperExt.CUSTOMER_ACCOUNT)
            .getRecordTypeId();
        String customerAccountName = CUSTOMER_ACCOUNT_NAME + 'InSeparateContext';

        Test.startTest();
        new SObjectBuilder(Account.sObjectType)
            .setField(Account.Name, customerAccountName)
            .setField(Account.Partner_Id__c, PARTNER_ID)
            .setField(Account.Type, AccountHelper.TYPE_CUSTOMER)
            .setField(Account.RecordTypeId, customerRecordTypeId)
            .setField(Account.Current_Owner__c, oldCurrentOwnerId)
            .create();
        Test.stopTest();

        Account customerAccount = [SELECT Id, Current_Owner__c, Partner_Id__c FROM Account WHERE Name = :customerAccountName];
        System.assertEquals(
            oldCurrentOwnerId,
            customerAccount.Current_Owner__c,
            'Current_Owner_Id should not be changed after insert CustomerAccount with not null PartnerId'
        );
    }

    @isTest
    static void testUpdateCreditCounterMethod() {

        List<Account> partnerAccounts = new AccountSelector()
            .selectAccounts()
            .selectFields(
                new Set<SObjectField>{
                    Account.Id,
                    Account.Partner_Sign_Up_Date__c,
                    Account.Referring_DSR__c
                }
            )
            .setCondition('RecordTypeId = :bind0')
            .setQueryBindings(new List<Object>{ AccountHelper.RT_ID_PARTNER_ACCOUNT })
            .executeQuery();

        Account partnerAcc = partnerAccounts.get(0);

        partnerAcc.Partner_Sign_Up_Date__c = System.today();
        partnerAcc.Referring_DSR__c = UserInfo.getUserId();
        update partnerAcc;

        Account testAccnt = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideUniqueString('Test account'),
                    Account.RecordTypeId => AccountHelper.RT_ID_CUSTOMER_ACCOUNT,
                    Account.Partner_ID__c => PARTNER_ID,
                    Account.Is_Demo_Account__c => false,
                    Account.RC_Account_Status__c => 'New',
                    Account.RC_Signup_Date__c => System.today()
                }
            )
            .create()
            .getRecord();

        Test.startTest();

            TriggerHandler.BY_PASS_ACCOUNT_ON_BEFORE = false;
            TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
            TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;

            testAccnt.RC_Account_Status__c = 'Paid';
            update testAccnt;

            List<Account> reselectedAccounts = new AccountSelector()
                .selectAccounts()
                .selectFields(
                    new Set<SObjectField>{
                        Account.Id,
                        Account.Eligible_for_Refferel_Credit__c
                    }
                )
                .setCondition('Id = :bind0')
                .setQueryBindings(new List<Object>{ testAccnt.Id })
                .executeQuery();

            Account acc = reselectedAccounts.get(0);

            System.assert(
                acc.Eligible_for_Refferel_Credit__c,
                'Account.Eligible_for_Refferel_Credit__c should be true'
            );

        Test.stopTest();
    }

    @isTest
    static void testUpdateMostRecentImplementationContact() {

        Account testAccnt = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideUniqueString('Test account')
                }
            )
            .create()
            .getRecord();

        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.AccountId => testAccnt.Id,
                    Contact.LastName => ValueProviderBuilder.provideUniqueString('testContactLastName'),
                    Contact.Email => ValueProviderBuilder.provideUniqueEmail('testemail'),
                    Contact.Phone => '1234567897'
                }
            )
            .create()
            .getRecord();

        AccountContactRole testContactRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => testAccnt.Id,
                    AccountContactRole.ContactId => testContact.Id,
                    AccountContactRole.IsPrimary => true
                }
            )
            .create()
            .getRecord();

        Test.startTest();

            Map<Id, Account> resultMap = AccountTriggerHelperExt.updateMostRecentImplementationContact(
                new Map<Id, Account>{testAccnt.Id => testAccnt}
            );

            System.assert(resultMap.containsKey(testAccnt.Id), 'resultMap should contain processed account id');

            Account processedAcc = resultMap.get(testAccnt.Id);
            System.assertEquals(
                testContact.Id,
                processedAcc.Most_Recent_Implementation_Contact__c,
                'Account.Most_Recent_Implementation_Contact__c should be filled with contactId ' +
                'from Primary AccountContactRole'
            );

        Test.stopTest();
    }

    @isTest
    static void testPopulateFirstAppointmentSourceMethod() {

        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = true;
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = true;
        TriggerHandler.BY_PASS_EVENT_ON_INSERT = true;
        TriggerHandler.BY_PASS_EVENT_ON_UPDATE = true;

        Account testAccnt = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideUniqueString('Test account')
                }
            )
            .create()
            .getRecord();

        Implementation__c implRecord = (Implementation__c) new SObjectBuilder(Implementation__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Implementation__c.Account__c => testAccnt.Id
                }
            )
            .create()
            .getRecord();

        Event eventRecord = (Event) new SObjectBuilder(Event.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Event.WhatId => implRecord.Id,
                    Event.DurationInMinutes => 1,
                    Event.ActivityDateTime => System.now(),
                    Event.Appointment_Source__c => 'Calendar'
                }
            )
            .create()
            .getRecord();

        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
        TriggerHandler.BY_PASS_EVENT_ON_INSERT = false;
        TriggerHandler.BY_PASS_EVENT_ON_UPDATE = false;

        Test.startTest();

            Map<Id, Account> resultMap = AccountTriggerHelperExt.populateFirstAppointmentSource(
                new Map<Id, Account>{testAccnt.Id => testAccnt}
            );

            System.assert(resultMap.containsKey(testAccnt.Id), 'resultMap should contain processed account id');

            Account processedAcc = resultMap.get(testAccnt.Id);
            System.assertEquals(
                eventRecord.Appointment_Source__c,
                processedAcc.First_Appointment_Source__c,
                'Event.Appointment_Source__c should be copied to Account.First_Appointment_Source__c field'
            );
        Test.stopTest();
    }

    @isTest
    static void testUpdateAccountCountOfOrderMethod() {

        Account testAccnt = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideUniqueString('Test account')
                }
            )
            .create()
            .getRecord();

        // create 4 Order__c - 2 with positive MRS_Delta__c and 2 others with negative
        List<Order__c> orderList = (List<Order__c>) new SObjectBuilder(Order__c.SObjectType)
            .quantity(4)
            .setFields(
                new Map<SObjectField, Object>{
                    Order__c.Name => ValueProviderBuilder.provideUniqueString('Test order'),
                    Order__c.Account__c => testAccnt.Id,
                    Order__c.Service_Plan_Change_Amount__c => ValueProviderBuilder.provideList(
                        new List<Integer>{
                            10, 10, 1, 1
                        }
                    ),
                    Order__c.Serivce_Plan_Discount_Change_Amount__c => ValueProviderBuilder.provideList(
                        new List<Integer>{
                            1, 1, 10, 10
                        }
                    ),
                    Order__c.Cost_Recovery_MRR__c => ValueProviderBuilder.provideList(
                        new List<Integer>{
                            5, 5, 1, 1
                        }
                    )
                }
            )
            .create()
            .getRecords();

        Test.startTest();

            Map<Id, Account> resultMap = AccountTriggerHelperExt.Update_Account_CountOfOrder(
                new Map<Id, Account>{
                    testAccnt.Id => testAccnt
                }
            );

            System.assert(resultMap.containsKey(testAccnt.Id), 'resultMap should contain Id of processed Account');
        Test.stopTest();
    }

    @isTest
    static void testSetAccountTeamforCSMOnAccountInsert() {
        User testCsmUser = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'Test' + 'Testcsmm',
                    User.Username => 'csmm!user@gmail.com',
                    User.Email => 'csmm_user@gmail.com',
                    User.Alias => 'csmm',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep',
                    User.CommunityNickname => 'test4'
                }
            )
            .create()
            .getRecord();

        Test.startTest();

            Account testAccnt = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Account.Name => ValueProviderBuilder.provideUniqueString('Test account'),
                        Account.CSM__c => testCsmUser.Id,
                        Account.OwnerId => UserInfo.getUserId()
                    }
                )
                .create()
                .getRecord();

        Test.stopTest();

        List<AccountTeamMember> teamMemberList = [SELECT Id, AccountId,
                UserId, TeamMemberRole
            FROM AccountTeamMember
            WHERE AccountId =:testAccnt.Id];

        System.assert(!teamMemberList.isEmpty(), 'AccountTeamMember record should be created for inserted Account');

        AccountTeamMember teamMember = teamMemberList.get(0);

        System.assertEquals(
            testAccnt.Id,
            teamMember.AccountId,
            'created AccountTeamMember record should be related to inserted Account'
        );
        System.assertEquals(
            testAccnt.CSM__c,
            teamMember.UserId,
            'created AccountTeamMember record should be related to Account.CSM__c user'
        );
        System.assertEquals(
            'Customer Success Manager (CSM)',
            teamMember.TeamMemberRole,
            'created AccountTeamMember record should have "Customer Success Manager (CSM)" TeamMemberRole'
        );
    }

    @isTest
    static void testSetAccountTeamforCSMOnAccountUpdate() {

        User testCsmUser = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'Test' + 'Testcsmmm',
                    User.Username => 'csmmm!user@gmail.com',
                    User.Email => 'csmmm_user@gmail.com',
                    User.Alias => 'csm',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep',
                    User.CommunityNickname => 'test3'
                }
            )
            .create()
            .getRecord();

        Account testAccnt = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideUniqueString('Test account'),
                    Account.OwnerId => UserInfo.getUserId()
                }
            )
            .create()
            .getRecord();

        AccountShare accShare = (AccountShare) new SObjectBuilder(AccountShare.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountShare.AccountId => testAccnt.Id,
                    AccountShare.UserOrGroupId => testCsmUser.Id,
                    AccountShare.AccountAccessLevel => 'Read',
                    AccountShare.CaseAccessLevel => 'Read',
                    AccountShare.ContactAccessLevel => 'Read',
                    AccountShare.OpportunityAccessLevel => 'Read'
                }
            )
            .create()
            .getRecord();

        Test.startTest();

            TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
            TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
            TriggerHandler.BY_PASS_ACCOUNT_ON_AFTER = false;

            testAccnt.CSM__c = testCsmUser.Id;
            update testAccnt;

        Test.stopTest();

        List<AccountTeamMember> teamMemberList = [SELECT Id, AccountId,
                UserId, TeamMemberRole
            FROM AccountTeamMember
            WHERE AccountId =:testAccnt.Id];

        System.assert(!teamMemberList.isEmpty(), 'AccountTeamMember record should be created for updated Account');

        AccountTeamMember teamMember = teamMemberList.get(0);

        System.assertEquals(
            testAccnt.Id,
            teamMember.AccountId,
            'created AccountTeamMember record should be related to updated Account'
        );
        System.assertEquals(
            testAccnt.CSM__c,
            teamMember.UserId,
            'created AccountTeamMember record should be related to Account.CSM__c user'
        );
        System.assertEquals(
            'Customer Success Manager (CSM)',
            teamMember.TeamMemberRole,
            'created AccountTeamMember record should have "Customer Success Manager (CSM)" TeamMemberRole'
        );

        List<AccountShare> sharesList = [SELECT Id, AccountId, AccountAccessLevel, CaseAccessLevel,
                ContactAccessLevel, OpportunityAccessLevel, RowCause
            FROM AccountShare
            WHERE Id =: accShare.Id];

        AccountShare reselectedAccShare = sharesList.get(0);
        System.assertEquals(
            'Edit',
            reselectedAccShare.AccountAccessLevel,
            'AccountShare.AccountAccessLevel should be updated to "Edit"'
        );
        System.assertEquals(
            'Edit',
            reselectedAccShare.CaseAccessLevel,
            'AccountShare.CaseAccessLevel should be updated to "Edit"'
        );
        System.assertEquals(
            'Edit',
            reselectedAccShare.ContactAccessLevel,
            'AccountShare.ContactAccessLevel should be updated to "Edit"'
        );
        System.assertEquals(
            'Edit',
            reselectedAccShare.OpportunityAccessLevel,
            'AccountShare.OpportunityAccessLevel should be updated to "Edit"'
        );
    }

    @isTest
    static void testRemoveAccountTeamMemberOnClearCSM() {

        User testCsmUser = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'Test' + 'Testcsmmmm',
                    User.Username => 'csmmmm!user@gmail.com',
                    User.Email => 'csmmmm_user@gmail.com',
                    User.Alias => 'csm',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep',
                    User.CommunityNickname => 'test4'
                }
            )
            .create()
            .getRecord();

        Account testAccnt = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideUniqueString('Test account'),
                    Account.OwnerId => UserInfo.getUserId(),
                    Account.CSM__c => testCsmUser.Id
                }
            )
            .create()
            .getRecord();

        AccountTeamMember testTeamMember = (AccountTeamMember) new SObjectBuilder(AccountTeamMember.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountTeamMember.AccountId => testAccnt.Id,
                    AccountTeamMember.UserId => testCsmUser.Id,
                    AccountTeamMember.TeamMemberRole => 'Customer Success Manager (CSM)'
                }
            )
            .create()
            .getRecord();

        Test.startTest();

            TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
            TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
            TriggerHandler.BY_PASS_ACCOUNT_ON_AFTER = false;

            testAccnt.CSM__c = null;
            update testAccnt;

        Test.stopTest();

        List<AccountTeamMember> teamMemberList = [SELECT Id, AccountId,
                UserId, TeamMemberRole
            FROM AccountTeamMember
            WHERE Id =:testTeamMember.Id];

        System.assert(
            teamMemberList.isEmpty(),
            'AccountTeamMember record should be deleted after clear Account.CSM__c field'
        );
    }

    @isTest
    static void testUpdateChannelManagerOnPartnerAccountUpdate() {

        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = true;
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = true;
        TriggerHandler.BY_PASS_ACCOUNT_ON_AFTER = true;
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE = true;
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT = true;
        TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = true;
        TriggerHandler.BY_PASS_LEAD_UPDATE = true;

        User testChannelManagerUser = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'Test' + 'Testmngr',
                    User.Username => 'mngr!user@gmail.com',
                    User.Email => 'mngr_user@gmail.com',
                    User.Alias => 'mngr',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep',
                    User.CommunityNickname => 'test5'
                }
            )
            .create()
            .getRecord();

            Account partnerAcc = new Account(
                Name = 'Test Partner',
                RecordTypeId = AccountHelper.RT_ID_PARTNER_ACCOUNT,
                Partner_Id__c = 'P-12345'
            );
            insert partnerAcc;

        Account testAccnt = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideUniqueString('Test account'),
                    Account.RecordTypeId => AccountHelper.RT_ID_CUSTOMER_ACCOUNT,
                    Account.Partner_Id__c => partnerAcc.Partner_Id__c
                }
            )
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => partnerAcc.Id,
                    Opportunity.Name => 'Test Opportunity',
                    Opportunity.CloseDate => System.today(),
                    Opportunity.Partner_Id__c => partnerAcc.Partner_Id__c,
                    Opportunity.CurrencyIsoCode => 'USD'
                }
            )
            .create()
            .getRecord();

        Lead testLead = (Lead) new SobjectBuilder(Lead.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.LeadPartnerID__c => partnerAcc.Partner_Id__c,
                    Lead.Status => LeadHelper.STATUS_NEW
                }
            )
            .create()
            .getRecord();

        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
        TriggerHandler.BY_PASS_ACCOUNT_ON_AFTER = false;
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE = false;
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT = false;
        TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = false;
        TriggerHandler.BY_PASS_LEAD_UPDATE = false;

        Test.startTest();

            partnerAcc.Partner_Hierarchy_Level__c = 'Reseller';
            partnerAcc.Inside_Sales_Rep__c = testChannelManagerUser.Id;
            update partnerAcc;

        Test.stopTest();

        List<Account> accsList = new AccountSelector()
            .selectAccounts()
            .selectFields(
                new Set<SObjectField>{
                    Account.Id,
                    Account.Inside_Sales_Rep__c
                }
            )
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{ testAccnt.Id })
            .executeQuery();

        Account reselectedAcc = accsList.get(0);
        System.assertEquals(
            testChannelManagerUser.Id,
            reselectedAcc.Inside_Sales_Rep__c,
            'Acount.Inside_Sales_Rep__c field should be populated with value from Inside_Sales_Rep__c from ' +
            'partner Account with same Partner_Id__c'
        );

        List<Opportunity> oppList = new OpportunitySelector()
            .selectOpportunities()
            .selectFields(
                new Set<SObjectField>{
                    Opportunity.Id,
                    Opportunity.Inside_Sales_Rep__c
                }
            )
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{ testOpp.Id })
            .executeQuery();

        Opportunity reselectedOpp = oppList.get(0);
        System.assertEquals(
            testChannelManagerUser.Id,
            reselectedOpp.Inside_Sales_Rep__c,
            'Opportunity.Inside_Sales_Rep__c field should be populated with value from Inside_Sales_Rep__c from ' +
            'partner Account with same Partner_Id__c'
        );

        List<Lead> leadList = new LeadSelector()
            .selectLeads()
            .selectFields(
                new Set<SObjectField>{
                    Lead.Id,
                    Lead.Inside_Sales_Rep__c
                }
            )
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{ testLead.Id })
            .executeQuery();

        Lead reselectedLead = leadList.get(0);
        System.assertEquals(
            testChannelManagerUser.Id,
            reselectedLead.Inside_Sales_Rep__c,
            'Lead.Inside_Sales_Rep__c field should be populated with value from Inside_Sales_Rep__c from ' +
            'partner Account with same Partner_Id__c'
        );
    }

    @IsTest
    static void testGetQueryStringForAccountHierarchyCalculation() {
        Test.startTest();
            String query = AccountTriggerHelperExt.getQueryStringForAccountHierarchyCalculation();
        Test.stopTest();
        
        System.assertNotEquals(null, query, 'Should return a valid query string');
        System.assert(query.contains('Ultimate_Parent_Account_ID__c'), 'Query should include Ultimate_Parent_Account_ID__c field');
        System.assert(query.contains('Total_DLs__c'), 'Query should include Total_DLs__c field');
        System.assert(query.contains('ORDER BY'), 'Query should have an ORDER BY clause');
    }
    
    @IsTest
    static void testUpdateSignatureRepPartnershipOptOut_OnInsert() {
        Id partnerRecordTypeId = Schema.SObjectType.Account
            .getRecordTypeInfosByName()
            .get(AccountTriggerHelperExt.PARTNER_ACCOUNT)
            .getRecordTypeId();
            
        Id customerRecordTypeId = Schema.SObjectType.Account
            .getRecordTypeInfosByName()
            .get(AccountTriggerHelperExt.CUSTOMER_ACCOUNT)
            .getRecordTypeId();
        
        // Create test accounts
        Account partnerAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'SignatureTest Partner',
                    Account.Partner_Id__c => 'SIGNATURETEST123',
                    Account.Type => 'Partner',
                    Account.RecordTypeId => partnerRecordTypeId,
                    Account.Signature_Rep_Partnership_Opt_Out__c => true
                }
            )
            .create()
            .getRecord();
            
        Test.startTest();
            // Create a customer account with the same partner ID
            Account customerAccount = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Account.Name => 'SignatureTest Customer',
                        Account.Partner_Id__c => 'SIGNATURETEST123',
                        Account.Type => 'Customer',
                        Account.RecordTypeId => customerRecordTypeId
                    }
                )
                .create()
                .getRecord();
                
            // Test the method directly
            List<Account> accounts = new List<Account>{customerAccount};
            AccountTriggerHelperExt.Update_SignatureRepPartnershipOptOut(
                accounts, 
                new Map<Id, Account>{customerAccount.Id => customerAccount}, 
                null, 
                true
            );
        Test.stopTest();
        
        // Verify the customer account inherited the opt-out value
        customerAccount = [SELECT Id, Signature_Rep_Partnership_Opt_Out__c FROM Account WHERE Id = :customerAccount.Id];
        System.assertEquals(
            partnerAccount.Signature_Rep_Partnership_Opt_Out__c,
            customerAccount.Signature_Rep_Partnership_Opt_Out__c,
            'Customer account should inherit partner account Signature_Rep_Partnership_Opt_Out__c value'
        );
    }
    
    @IsTest
    static void testUpdateSignatureRepPartnershipOptOut_OnUpdate() {
        Id partnerRecordTypeId = Schema.SObjectType.Account
            .getRecordTypeInfosByName()
            .get(AccountTriggerHelperExt.PARTNER_ACCOUNT)
            .getRecordTypeId();
            
        Id customerRecordTypeId = Schema.SObjectType.Account
            .getRecordTypeInfosByName()
            .get(AccountTriggerHelperExt.CUSTOMER_ACCOUNT)
            .getRecordTypeId();
        
        // Create test accounts
        Account partnerAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'SignatureTest Partner',
                    Account.Partner_Id__c => 'SIGNATURETEST456',
                    Account.Type => 'Partner',
                    Account.RecordTypeId => partnerRecordTypeId,
                    Account.Signature_Rep_Partnership_Opt_Out__c => false
                }
            )
            .create()
            .getRecord();
            
        Account customerAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'SignatureTest Customer',
                    Account.Partner_Id__c => 'SIGNATURETEST456',
                    Account.Type => 'Customer',
                    Account.RecordTypeId => customerRecordTypeId,
                    Account.Signature_Rep_Partnership_Opt_Out__c => false
                }
            )
            .create()
            .getRecord();
            
        Test.startTest();
            // Change partner account opt-out value
            Account oldPartnerAccount = partnerAccount.clone(true);
            partnerAccount.Signature_Rep_Partnership_Opt_Out__c = true;
            update partnerAccount;
            
            // Test the method directly
            Map<Id, Account> oldMap = new Map<Id, Account>{partnerAccount.Id => oldPartnerAccount};
            Map<Id, Account> newMap = new Map<Id, Account>{partnerAccount.Id => partnerAccount};
            
            AccountTriggerHelperExt.Update_SignatureRepPartnershipOptOut(
                new List<Account>{partnerAccount}, 
                newMap, 
                oldMap, 
                false
            );
        Test.stopTest();
        
        // Verify customer account was updated to match partner account
        customerAccount = [SELECT Id, Signature_Rep_Partnership_Opt_Out__c FROM Account WHERE Id = :customerAccount.Id];
        System.assertEquals(
            true,
            customerAccount.Signature_Rep_Partnership_Opt_Out__c,
            'Customer account should have updated Signature_Rep_Partnership_Opt_Out__c value'
        );
    }

    @isTest
    static void testCustomerPartnerIdUpdate() {
        Account customerAcc = [SELECT Id, Partner_ID__c, Partner_Account__c, Partner_Account_Name__c 
                               FROM Account 
                               WHERE Name = 'Customer One'];
        
        AccountTriggerHelperExt.oldAccountMap = new Map<Id, Account>{customerAcc.Id => customerAcc.clone(false, true, false, false)};
            
            Test.startTest();
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
        customerAcc.Partner_ID__c = PARTNER_ID_2;
        update customerAcc;
        Test.stopTest();
        
        Account updatedAcc = [SELECT Partner_Account__c, Partner_Account_Name__c 
                              FROM Account 
                              WHERE Id = :customerAcc.Id];
        
        System.assertEquals([SELECT Id FROM Account WHERE Partner_ID__c = :PARTNER_ID_2 LIMIT 1].Id,updatedAcc.Partner_Account__c,'Partner Account lookup should be updated ');
        System.assertEquals('Partner Two',updatedAcc.Partner_Account_Name__c,'Partner Account name should be updated');
    }
}