/**************************************************************************************************
* Project Name..........: RingCentral -                                                           *
* File..................: Test_SyncAccountWS.cls                                                  *
* Version...............: 1.0                                                                     *
* Created by............: Simplion Technologies                                                   *
* Created Date..........: 31 December 2013                                                        *
* Last Modified by......: Simplion Technologies                                                   *
* Last Modified Date....:                                                                         *
* Description...........: This is a test class for SyncAccountWS class.                           *
**************************************************************************************************/

@isTest
private class Test_SyncAccountWS {

    public static final string TEST_TIME_ZONE_NAME = '(GMT-12:00) International Date Line West';

    public Account createAccount(){
        Account accountobj1 = new Account();
        accountobj1.Name = 'Test Customer Account'+String.valueOf(System.currentTimeMillis());
        accountobj1.Partner_ID__c = 'PARTNER002';
        accountobj1.Phone = '9910101111';
        accountobj1.AccountNumber = '991010';
        accountobj1.RC_User_ID__c = '21331231';
        insert accountobj1;

        return accountobj1;
    }

    public EntitlementEnable__c createEntitlementEnable(){
        EntitlementEnable__c mycs = EntitlementEnable__c.getValues('IsEntitlementsEnabled__c');
        if(mycs == null) {
            mycs = new EntitlementEnable__c();
            mycs.IsEntitlementsEnabled__c = true;
            mycs.Name = 'IsEntitlementsEnabled';
            insert mycs;
        }

        return mycs;
    }

    public Contact createContact(Account accountobj1){

        Contact contObj = new Contact();
        contObj.AccountId =  accountobj1.Id;
        contObj.Email = 'abc2@test.com';
        contObj.LastName = 'Test Last2'+String.valueOf(System.currentTimeMillis());
        contObj.FirstName = 'Test First2'+String.valueOf(System.currentTimeMillis());
        insert contObj;

        return contObj;
    }

    public User createUser(Contact contObj){

        // Creating User record.
        User testUser = new User(
                        Alias = 'u1',
                        Email = 'u1234@testorg.com',
                        EmailEncodingKey = 'UTF-8',
                        LastName = 'Testing' + String.valueOf(System.currentTimeMillis()),
                        ProfileId = SyncAccountWS.PROFILE_ID_FOR_NEW_PORTAL_USERS,
                        ContactId = contObj.Id,
                        LanguageLocaleKey='en_US',
                        LocaleSIDKey='en_US',
                        Country='United States',
                        TimeZoneSIDKey='America/Los_Angeles',
                        Username='u11234@testorg.com',
                        IsActive=true
        );
        insert testUser;

        return testUser;
    }

    public Opportunity createOpportunity(Account accountobj1){
        //Inserting opportunity record.
        Opportunity Oppval = new Opportunity();
        Oppval.Name = 'Test Opp'+String.valueOf(System.currentTimeMillis());
        Oppval.AccountId = accountobj1.Id;
        Oppval.Type = 'Existing Business';
        Oppval.StageName = '3. Qualified';
        Oppval.Sales_Model__c = 'Direct';
        Oppval.CloseDate = System.Today() + 10;
        Oppval.CurrencyIsoCode = 'USD';
        Oppval.Brand_Name__c= 'RingCentral';
        Oppval.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity')
            .getRecordTypeId();
        Oppval.Proposal_Expiration_Date__c = System.today() + 100;
        insert Oppval;

        return Oppval;
    }

    public Lead createLead(){
        //Inserting Lead record.
        Lead leadObj = new Lead();
        leadObj.FirstName = 'FName';
        leadObj.Email= 'abc2@test.com';
        leadObj.LastName = 'LastName';
        leadObj.Company  ='TestCompany';
        leadObj.phone = '21331231';
        leadObj.Downgrade_Reason__c  = 'Not Enough Info';
        leadObj.User_ID__c ='12345';
        leadObj.Website = 'test.com';
        leadObj.NumberOfEmployees = 5;
        leadObj.Industry = 'Consulting: IT';
        leadObj.NumberOfEmployees__c='2-19';
        leadObj.Number_of_Locations__c ='2-4';
        leadObj.LeadSource = 'Data.com';
        leadObj.Status ='2. Contacted';
        leadObj.Isconverted = false;
        //leadObj.Account__c
        insert leadObj;

        return leadObj;
    }

    public static SyncAccountWS.syncAcctInputParam getInputParam() {
        SyncAccountWS.syncAcctInputParam syncparam = new SyncAccountWS.syncAcctInputParam();
        syncparam.In_RCUserID = '21331231';
        syncparam.In_RCPrimaryNumber = '21331231';
        syncparam.In_FirstName = '21331231';
        syncparam.In_LastName = 'LastName';
        syncparam.In_ContactEmail = 'abc2@test.com';
        syncparam.In_Company = 'test';
        syncparam.In_Contactphone = '21331231';
        syncparam.In_RCBRAND = '21331231';
        syncparam.In_SUBBRAND = '21331231';
        syncparam.In_SERVICENAME = '21331231';
        syncparam.In_TIERNAME = '21331231';
        syncparam.In_SignupPlatform = 'test';
        syncparam.In_RCPrimaryNumber = '991010';
        syncparam.In_Attribute_Value_01 = '21331231';
        syncparam.In_Attribute_Key_02 = '21331231';
        syncparam.In_Attribute_Value_02 = '21331231';
        syncparam.In_Attribute_Key_03 = '21331231';
        syncparam.In_Attribute_Value_03 = '21331231';
        syncparam.In_Attribute_Key_04 = '21331231';
        syncparam.In_Attribute_Value_04 = '21331231';
        syncparam.In_Attribute_Key_05 = '21331231';
        syncparam.In_Attribute_Value_05 = '21331231';
        syncparam.In_CugNumber = '123456';
        syncparam.In_Industry = 'Insurance';

        return syncparam;
    }

    public static SyncAccountWsBilling.syncAcctInputParamBilling getInputParamBilling() {
        SyncAccountWsBilling.syncAcctInputParamBilling syncparam = new SyncAccountWsBilling.syncAcctInputParamBilling();
        syncparam.In_RCUserID = '21331231';
        syncparam.In_BillingID = '21331231';
        syncparam.In_RCPrimaryNumber = '21331231';
        syncparam.In_FirstName = '21331231';
        syncparam.In_LastName = 'LastName';
        syncparam.In_ContactEmail = 'abc2@test.com';
        syncparam.In_Company = 'test';
        syncparam.In_Contactphone = '21331231';
        syncparam.In_RCBRAND = '21331231';
        syncparam.In_SUBBRAND = '21331231';
        syncparam.In_SERVICENAME = '21331231';
        syncparam.In_TIERNAME = '21331231';
        syncparam.In_SignupPlatform = 'test';
        syncparam.In_RCPrimaryNumber = '991010';
        syncparam.In_Attribute_Value_01 = '21331231';
        syncparam.In_Attribute_Key_02 = '21331231';
        syncparam.In_Attribute_Value_02 = '21331231';
        syncparam.In_Attribute_Key_03 = '21331231';
        syncparam.In_Attribute_Value_03 = '21331231';
        syncparam.In_Attribute_Key_04 = '21331231';
        syncparam.In_Attribute_Value_04 = '21331231';
        syncparam.In_Attribute_Key_05 = '21331231';
        syncparam.In_Attribute_Value_05 = '21331231';

        return syncparam;
    }

    public static List<PlatformLog__c> findPlatformLog() {
        return [
            SELECT Id, Source__c, OutboundMessage__c, InboundMessage__c
            FROM PlatformLog__c
            WHERE Source__c LIKE 'SyncAccountWS%'
        ];
    }

    static Account findCreatedAccount(SyncAccountWS.syncAcctInputParam params) {
        if(params == null || params.Out_AccountId == null) {
            return null;
        }

        String accountId = params.Out_AccountId;

        return (Account) new AccountSelector()
            .selectAccounts()
            .selectFields(new List<Schema.SObjectField>{
                Account.Id,
                Account.RC_Sync_Status__c,
                Account.Industry
            })
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{ accountId })
            .setLimit(1)
            .executeQuery()
            .get(0);
    }

    static Opportunity createTestOpportunity(Account account) {
        Opportunity opp = new Opportunity();

        opp.Name = 'Test Opp' + String.valueOf(System.currentTimeMillis());
        opp.AccountId = account.Id;
        opp.Type = 'Existing Business';
        opp.StageName = '3. Qualified';
        opp.Sales_Model__c = 'Direct';
        opp.CloseDate = System.Today() + 10;
        opp.CurrencyIsoCode = 'USD';
        opp.Brand_Name__c= 'RingCentral';
        opp.RecordTypeId = Schema.SObjectType.Opportunity
            .getRecordTypeInfosByName()
            .get('Sales Opportunity')
            .getRecordTypeId();
        opp.Proposal_Expiration_Date__c = System.today() + 100;

        insert opp;

        return opp;
    }

    // Test method for positive cases.
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void TestSyncAccountWS() {
        try{

            Test_SyncAccountWS testClassObject = new Test_SyncAccountWS();
            //Setting up records database.
            EntitlementEnable__c mycs = EntitlementEnable__c.getValues('IsEntitlementsEnabled__c');
            mycs = testClassObject.createEntitlementEnable();
            Account accountobj1 = new Account();
            accountobj1 = testClassObject.createAccount();
            Contact contObj = new Contact();
            contObj = testClassObject.createContact(accountobj1);
            User testUser = new User();
            testUser = testClassObject.createUser(contObj);

            SyncAccountWS syncAcc = new SyncAccountWS();
            SyncAccountWS.syncAcctInputParam syncparam = getInputParam();
            SyncAccountWsBilling.syncAcctInputParamBilling syncparamBilling = getInputParamBilling();
            syncparam.proc_AccountId = accountobj1.Id;
            syncparamBilling.proc_AccountId = accountobj1.Id;

            test.startTest();
            SyncAccountWS.synAccountNew(syncparam);
            SyncAccountWS.handleReturn(syncparam);
            SyncAccountWS.handleCreateUser(syncparam);
            SyncAccountWS.contactHavingUserRecord(syncparam);
            SyncAccountWS.accountMatchingContactEmail(syncparam);
            SyncAccountWS.accountMatchingContactEmail(syncparam);
            SyncAccountWS.handleCreateContact(syncparam);
            SyncAccountWS.handleCreateAccount(syncparam);
            SyncAccountWS.handleUpdateAccount(syncparam);
            SyncAccountWS.searchLeadByEmail(syncparam);
            SyncAccountWS.searchContactByMailAndBrand(syncparam);
            SyncAccountWS.searchOppertunityByOID(syncparam);
            SyncAccountWS.synAccountCreateUser(syncparam);
            //billing
            SyncAccountWSBilling.synAccountNew(syncparamBilling);
            SyncAccountWSBilling.handleReturn(syncparamBilling);
            SyncAccountWSBilling.handleCreateUser(syncparamBilling);
            SyncAccountWSBilling.contactHavingUserRecord(syncparamBilling);
            SyncAccountWSBilling.accountMatchingContactEmail(syncparamBilling);
            SyncAccountWSBilling.accountMatchingContactEmail(syncparamBilling);
            SyncAccountWSBilling.handleCreateContact(syncparamBilling);
            SyncAccountWSBilling.handleCreateAccount(syncparamBilling);
            SyncAccountWSBilling.handleConverLead(syncparamBilling);
            SyncAccountWSBilling.handleUpdateAccount(syncparamBilling);
            SyncAccountWSBilling.searchLeadByEmail(syncparamBilling);
            SyncAccountWSBilling.searchContactByMail(syncparamBilling);
            SyncAccountWSBilling.searchOppertunityByOID(syncparamBilling);
            SyncAccountWSBilling.synAccountCreateUser(syncparamBilling);
            Test.stopTest();
        }catch(Exception ex){
            system.debug('#### testError @ - '+ex.getMessage());
        }
    }//End of positive method.

    @isTest
    static void TestSyncAccountWS_AccountCreateLogged() {
        SyncAccountWS.syncAcctInputParam inputParam = new SyncAccountWS.syncAcctInputParam();
        inputParam.In_Company = 'ACME Inc.';
        inputParam.In_ContactPhone = '+1 (234) 5678901';
        inputParam.In_ContactEmail = 'jdoe@acmeinc.com';
        inputParam.In_FirstName = 'John';
        inputParam.In_LastName = 'Doe';
        inputParam.In_RCBrand = 'RingCentral';
        inputParam.In_SUBBrand = 'RingCentral';
        inputParam.In_RCPrimaryNumber = '1234567890';
        inputParam.In_RCUserID = '0987654321';
        inputParam.In_SignUpType = 'Paid';
        inputParam.In_SignUpPlatform = 'SignUpPlatform';
        inputParam.In_TierName = 'Office Premium 2-19 line';
        inputParam.In_ServiceName = 'Office';
        inputParam.In_CugNumber = '100500';
        inputParam.In_Industry = 'Insurance';
        inputParam.In_Bandwidth_Test_Id = '42';
        inputParam.In_Bandwidth_MOS_Score = 9000;
        inputParam.In_Bandwidth_Num_Sim_Calls = 50;
        inputParam.In_OpportunityID = (Id) new ValueProvider.DummyIdProvider(Opportunity.sObjectType).getValue();

        SyncAccountWS.syncAcctInputParam output = SyncAccountWS.synAccountNew(inputParam);
        List<PlatformLog__c> listPlatformLogs = findPlatformLog();

        System.assertEquals(1, listPlatformLogs.size(), listPlatformLogs.size());
        System.assert(
            Pattern.matches('SyncAccountWS: Inserting Account.+', listPlatformLogs[0].Source__c),
            listPlatformLogs[0].Source__c
        );

        Account acc = findCreatedAccount(output);
        System.assertEquals(
            inputParam.In_Industry,
            acc.Industry,
            'In_Industry value not written to Account.Industry'
        );
    }

    @isTest
    static void TestSyncAccountWS_AccountUpdateLogged() {
        SyncAccountWS.syncAcctInputParam inputParam = new SyncAccountWS.syncAcctInputParam();
        inputParam.In_Company = 'ACME Inc.';
        inputParam.In_ContactPhone = '+1 (234) 5678901';
        inputParam.In_ContactEmail = 'jdoe@acmeinc.com';
        inputParam.In_FirstName = 'John';
        inputParam.In_LastName = 'Doe';
        inputParam.In_RCBrand = 'RingCentral';
        inputParam.In_SUBBrand = 'RingCentral';
        inputParam.In_RCPrimaryNumber = '1234567890';
        inputParam.In_SignUpType = 'Paid';
        inputParam.In_SignUpPlatform = 'SignUpPlatform';
        inputParam.In_TierName = 'Office Premium 2-19 line';
        inputParam.In_ServiceName = 'Office';
        inputParam.In_CugNumber = '100500';
        inputParam.In_Bandwidth_Test_Id = '42';
        inputParam.In_Bandwidth_MOS_Score = 9000;
        inputParam.In_Bandwidth_Num_Sim_Calls = 50;

        SyncAccountWS.syncAcctInputParam output = SyncAccountWS.synAccountNew(inputParam);
        Account acc = findCreatedAccount(output);

        Opportunity opp = createTestOpportunity(acc);

        inputParam = new SyncAccountWS.syncAcctInputParam();
        inputParam.In_Company = 'ACME Inc.';
        inputParam.In_ContactPhone = '+1 (234) 5678901';
        inputParam.In_ContactEmail = 'jdoe@acmeinc.com';
        inputParam.In_FirstName = 'John';
        inputParam.In_LastName = 'Doe';
        inputParam.In_RCBrand = 'RingCentral';
        inputParam.In_SUBBrand = 'RingCentral';
        inputParam.In_RCPrimaryNumber = '1234567890';
        inputParam.In_SignUpType = 'Paid';
        inputParam.In_SignUpPlatform = 'SignUpPlatform';
        inputParam.In_TierName = 'Office Premium 2-19 line';
        inputParam.In_ServiceName = 'Office';
        inputParam.In_Industry = 'Insurance';
        inputParam.In_Bandwidth_Test_Id = '42';
        inputParam.In_Bandwidth_MOS_Score = 9000;
        inputParam.In_Bandwidth_Num_Sim_Calls = 50;
        inputParam.In_OpportunityID = String.valueOf(opp.Id);

        output = SyncAccountWS.synAccountNew(inputParam);
        List<PlatformLog__c> listPlatformLogs = findPlatformLog();

        System.assertEquals(2, listPlatformLogs.size(), listPlatformLogs.size());

        System.assert(
            Pattern.matches('SyncAccountWS: Upserting Account.+', listPlatformLogs[1].Source__c),
            listPlatformLogs[1].Source__c
        );

        System.assertEquals(
            inputParam.In_Industry,
            findCreatedAccount(output).Industry,
            'In_Industry value not written to Account.Industry'
        );
    }

    // Test method for positive cases.
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void TestSyncAccountWS1() {
        try{

            Test_SyncAccountWS testClassObject = new Test_SyncAccountWS();
            //Setting up records database.
            EntitlementEnable__c mycs = EntitlementEnable__c.getValues('IsEntitlementsEnabled__c');
            mycs = testClassObject.createEntitlementEnable();
            Account accountobj1 = new Account();
            accountobj1 = testClassObject.createAccount();
            Contact contObj = new Contact();
            contObj = testClassObject.createContact(accountobj1);
            User testUser = new User();
            testUser = testClassObject.createUser(contObj);

            SyncAccountWS syncAcc = new SyncAccountWS();
            SyncAccountWS.syncAcctInputParam syncparam = getInputParam();
            SyncAccountWsBilling.syncAcctInputParamBilling syncparamBilling = getInputParamBilling();
            syncparam.proc_AccountId = accountobj1.Id;
            syncparamBilling.proc_AccountId = accountobj1.Id;

            test.startTest();
            SyncAccountWS.synAccountNew(syncparam);
            SyncAccountWSBilling.synAccountNew(syncparamBilling);
            Test.stopTest();
        }catch(Exception ex){
            system.debug('#### testError @ - '+ex.getMessage());
        }
    }//End of positive method.

    //Test method for searchContactByMail return true;
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void TestSyncAccountWSNegative1() {

        try{

            Test_SyncAccountWS testClassObject = new Test_SyncAccountWS();
            //Inserting Account record.
            Account accountobj1 = new Account();
            accountobj1 = testClassObject.createAccount();
            accountobj1.RC_User_ID__c = null;
            accountobj1.RC_Sync_Status__c = 'Pending';
            update accountobj1;

            Contact contObj = new Contact();
            contObj = testClassObject.createContact(accountobj1);

            Opportunity Oppval = new Opportunity();
            Oppval = testClassObject.createOpportunity(accountobj1);

            SyncAccountWS syncAcc = new SyncAccountWS();
            SyncAccountWS.syncAcctInputParam syncparam = getInputParam();
            SyncAccountWsBilling.syncAcctInputParamBilling syncparamBilling = getInputParamBilling();
            syncparam.In_OpportunityID = Oppval.Id;
            syncparamBilling.In_OpportunityID = Oppval.Id;


            test.startTest();
            SyncAccountWS.synAccountNew(syncparam);
            SyncAccountWS.synAccountCreateUser(syncparam);
            SyncAccountWSBilling.synAccountNew(syncparamBilling);
            SyncAccountWSBilling.synAccountCreateUser(syncparamBilling);
            test.stopTest();
        }catch(Exception ex){
            system.debug('#### testException @ - '+ex.getMessage());
        }
    }// End of negative 1 method.

    //Test method for searchContactByMail return true;
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void TestSyncAccountWSNegative12() {

        try{

            Test_SyncAccountWS testClassObject = new Test_SyncAccountWS();
            //Inserting Account record.
            Account accountobj1 = new Account();
            accountobj1 = testClassObject.createAccount();
            accountobj1.RC_User_ID__c = null;
            accountobj1.RC_Sync_Status__c = 'Pending';
            update accountobj1;

            Contact contObj = new Contact();
            contObj = testClassObject.createContact(accountobj1);

            Opportunity Oppval = new Opportunity();
            Oppval = testClassObject.createOpportunity(accountobj1);

            SyncAccountWS syncAcc = new SyncAccountWS();
            SyncAccountWS.syncAcctInputParam syncparam = getInputParam();
            SyncAccountWsBilling.syncAcctInputParamBilling syncparamBilling = getInputParamBilling();
            syncparam.In_OpportunityID = Oppval.Id;
            syncparamBilling.In_OpportunityID = Oppval.Id;

            test.startTest();
            SyncAccountWS.synAccountNew(syncparam);
            SyncAccountWSBilling.synAccountNew(syncparamBilling);
            test.stopTest();

        }catch(Exception ex){
            system.debug('#### testException @ - '+ex.getMessage());
        }
    }// End of negative 12 method.

    //Test method for searchContactByMailAndBrand return false;
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void TestSyncAccountWSNegative2() {

        try{

            Test_SyncAccountWS testClassObject = new Test_SyncAccountWS();
            //Inserting Account record.
            Account accountobj1 = new Account();
            accountobj1 = testClassObject.createAccount();
            accountobj1.RC_User_ID__c = null;
            accountobj1.RC_Sync_Status__c = null;
            accountobj1.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account')
                .getRecordTypeId();
            update accountobj1;

            Contact contObj = new Contact();
            contObj = testClassObject.createContact(accountobj1);

            Opportunity Oppval = new Opportunity();
            Oppval = testClassObject.createOpportunity(accountobj1);

            SyncAccountWS syncAcc = new SyncAccountWS();
            SyncAccountWS.syncAcctInputParam syncparam = getInputParam();
            SyncAccountWsBilling.syncAcctInputParamBilling syncparamBilling = getInputParamBilling();
            syncparam.In_OpportunityID = Oppval.Id;
            syncparamBilling.In_OpportunityID = Oppval.Id;

            test.startTest();
            SyncAccountWS.synAccountNew(syncparam);
            SyncAccountWSBilling.synAccountNew(syncparamBilling);
            test.stopTest();
        }catch(Exception ex){
            system.debug('#### testException @ - '+ex.getMessage());
        }
    }// End of negative method 2.

    //Test method for searchContactByMail return false;
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void TestSyncAccountWSNegative22() {

        try{

            Test_SyncAccountWS testClassObject = new Test_SyncAccountWS();
            //Inserting Account record.
            Account accountobj1 = new Account();
            accountobj1 = testClassObject.createAccount();
            accountobj1.RC_User_ID__c = null;
            accountobj1.RC_Sync_Status__c = null;
            accountobj1.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account')
                .getRecordTypeId();
            update accountobj1;

            Contact contObj = new Contact();
            contObj = testClassObject.createContact(accountobj1);

            Opportunity Oppval = new Opportunity();
            Oppval = testClassObject.createOpportunity(accountobj1);

            SyncAccountWS syncAcc = new SyncAccountWS();
            SyncAccountWS.syncAcctInputParam syncparam = getInputParam();
            SyncAccountWsBilling.syncAcctInputParamBilling syncparamBilling = getInputParamBilling();
            syncparam.In_OpportunityID = Oppval.Id;
            syncparamBilling.In_OpportunityID = Oppval.Id;

            test.startTest();
            SyncAccountWS.synAccountNew(syncparam);
            SyncAccountWSBilling.synAccountNew(syncparamBilling);
            test.stopTest();
        }catch(Exception ex){
            system.debug('#### testException @ - '+ex.getMessage());
        }
    }// End of negative method 22.

    //Test method for searchLeadByEmail return true;
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void TestSyncAccountWSNegative3() {

        try{

            Test_SyncAccountWS testClassObject = new Test_SyncAccountWS();
            //Inserting Account record.
            Account accountobj1 = new Account();
            accountobj1 = testClassObject.createAccount();
            accountobj1.RC_User_ID__c = null;
            update accountobj1;

            //Inserting opportunity record.
            Opportunity Oppval = new Opportunity();
            Oppval = testClassObject.createOpportunity(accountobj1);

            //Inserting Lead record.
            Lead leadObj = new Lead();
            leadObj = testClassObject.createLead();

            SyncAccountWS syncAcc = new SyncAccountWS();
            SyncAccountWS.syncAcctInputParam syncparam = getInputParam();
            SyncAccountWsBilling.syncAcctInputParamBilling syncparamBilling = getInputParamBilling();
            syncparam.In_OpportunityID = Oppval.Id;
            syncparamBilling.In_OpportunityID = Oppval.Id;

            test.startTest();
            SyncAccountWS.synAccountNew(syncparam);
            SyncAccountWSBilling.synAccountNew(syncparamBilling);
            test.stopTest();
        }catch(Exception ex){
            system.debug('#### testException @ - '+ex.getMessage());
        }
    }// End of negative method 3.

    //Test method for searchLeadByEmail return true;
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void TestSyncAccountWSNegative32() {

        try{

            Test_SyncAccountWS testClassObject = new Test_SyncAccountWS();
            //Inserting Account record.
            Account accountobj1 = new Account();
            accountobj1 = testClassObject.createAccount();
            accountobj1.RC_User_ID__c = null;
            update accountobj1;

            //Inserting opportunity record.
            Opportunity Oppval = new Opportunity();
            Oppval = testClassObject.createOpportunity(accountobj1);

            //Inserting Lead record.
            Lead leadObj = new Lead();
            leadObj = testClassObject.createLead();

            SyncAccountWS syncAcc = new SyncAccountWS();
            SyncAccountWS.syncAcctInputParam syncparam = getInputParam();
            SyncAccountWsBilling.syncAcctInputParamBilling syncparamBilling = getInputParamBilling();
            syncparam.In_OpportunityID = Oppval.Id;
            syncparamBilling.In_OpportunityID = Oppval.Id;

            test.startTest();
            SyncAccountWS.synAccountNew(syncparam);
            SyncAccountWSBilling.synAccountNew(syncparamBilling);
            test.stopTest();
        }catch(Exception ex){
            system.debug('#### testException @ - '+ex.getMessage());
        }
    }// End of negative method 32.

    //Test method for searchAccountByUID return false;
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void TestSyncAccountWSNegative4() {

        try{

            Test_SyncAccountWS testClassObject = new Test_SyncAccountWS();
            //Inserting Account record.
            Account accountobj1 = new Account();
            accountobj1 = testClassObject.createAccount();
            accountobj1.RC_User_ID__c = null;
            accountobj1.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account')
                .getRecordTypeId();
            update accountobj1;

            Contact contObj = new Contact();
            contObj = testClassObject.createContact(accountobj1);

            SyncAccountWS syncAcc = new SyncAccountWS();
            SyncAccountWS.syncAcctInputParam syncparam = getInputParam();
            SyncAccountWsBilling.syncAcctInputParamBilling syncparamBilling = getInputParamBilling();

            test.startTest();
            SyncAccountWS.synAccountNew(syncparam);
            SyncAccountWSBilling.synAccountNew(syncparamBilling);
            test.stopTest();
        }catch(Exception ex){
            system.debug('#### testException @ - '+ex.getMessage());
        }
    }// End of negative method 4.

    //Test method for searchAccountByUID return false;
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void TestSyncAccountWSNegative42() {

        try{

            Test_SyncAccountWS testClassObject = new Test_SyncAccountWS();
            //Inserting Account record.
            Account accountobj1 = new Account();
            accountobj1 = testClassObject.createAccount();
            accountobj1.RC_User_ID__c = null;
            accountobj1.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account')
                .getRecordTypeId();
            update accountobj1;

            Contact contObj = new Contact();
            contObj = testClassObject.createContact(accountobj1);

            SyncAccountWS syncAcc = new SyncAccountWS();
            SyncAccountWS.syncAcctInputParam syncparam = getInputParam();
            SyncAccountWsBilling.syncAcctInputParamBilling syncparamBilling = getInputParamBilling();

            test.startTest();
            SyncAccountWS.synAccountNew(syncparam);
            SyncAccountWSBilling.synAccountNew(syncparamBilling);
            test.stopTest();
        }catch(Exception ex){
            system.debug('#### testException @ - '+ex.getMessage());
        }
    }// End of negative method 42.

    //Test method for searchAccountByUID return false;
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void TestSyncAccountWSNegative5() {

        try{

            Test_SyncAccountWS testClassObject = new Test_SyncAccountWS();
            //Inserting Account record.
            Account accountobj1 = new Account();
            accountobj1 = testClassObject.createAccount();
            accountobj1.RC_User_ID__c = null;
            accountobj1.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account')
                .getRecordTypeId();
            update accountobj1;

            //Inserting Lead record.
            Lead leadObj = new Lead();
            leadObj = testClassObject.createLead();

            SyncAccountWS syncAcc = new SyncAccountWS();
            SyncAccountWS.syncAcctInputParam syncparam = getInputParam();
            SyncAccountWsBilling.syncAcctInputParamBilling syncparamBilling = getInputParamBilling();

            test.startTest();
            SyncAccountWS.synAccountNew(syncparam);
            SyncAccountWSBilling.synAccountNew(syncparamBilling);
            test.stopTest();
        }catch(Exception ex){
            system.debug('#### testException @ - '+ex.getMessage());
        }
    }// End of negative method 5.

    //Test method for searchAccountByUID return false;
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void TestSyncAccountWSNegative52() {

        try{

            Test_SyncAccountWS testClassObject = new Test_SyncAccountWS();
            //Inserting Account record.
            Account accountobj1 = new Account();
            accountobj1 = testClassObject.createAccount();
            accountobj1.RC_User_ID__c = null;
            accountobj1.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account')
                .getRecordTypeId();
            update accountobj1;

            //Inserting Lead record.
            Lead leadObj = new Lead();
            leadObj = testClassObject.createLead();

            SyncAccountWS syncAcc = new SyncAccountWS();
            SyncAccountWS.syncAcctInputParam syncparam = getInputParam();
            SyncAccountWsBilling.syncAcctInputParamBilling syncparamBilling = getInputParamBilling();

            test.startTest();
            SyncAccountWS.synAccountNew(syncparam);
            SyncAccountWSBilling.synAccountNew(syncparamBilling);
            test.stopTest();
        }catch(Exception ex){
            system.debug('#### testException @ - '+ex.getMessage());
        }
    }// End of negative method 52.

    @isTest
    static void testCugNumberisPopulated() {
        insert new Feature_Toggle__c(Disable_CUG_Account_Sync__c = true);
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
        .setFields(
            new Map<SObjectField, Object>{
                Account.Name => 'Test account',
                Account.RC_User_Id__c => '21331231'
            }
        )
        .create()
        .getRecord();

        SyncAccountWS.syncAcctInputParam inputParams = getInputParam();

        Test.startTest();
        SyncAccountWS.synAccountNew(inputParams);
        Test.stopTest();

        Account updatedAcc = [SELECT Bt_Cug_Number__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals('123456', updatedAcc.Bt_Cug_Number__c, 'BT CUG Number should be equal to 123456');
    }

    @isTest
    private static void testGetProfilesForPortalUsersShouldReturnDefaultSet() {
        insert new RingCentralVariousSettings__c(
            Use_Community_Licenses_on_portal__c = true
        );

        Set<Id> result;

        Test.startTest();
        result = SyncAccountWS.getProfilesForPortalUsers();
        Test.stopTest();

        System.assertEquals(
            2,
            result.size(),
            'Method should return default Set of Id with 2 values'
        );
    }

    @isTest
    private static void testGetProfilesForPortalUsersShouldCoverCatch() {
        insert new RingCentralVariousSettings__c(
            Use_Community_Licenses_on_portal__c = true,
            SitesAcceptedProfiles__c = 'invalidProfile'
        );

        Set<Id> result;

        Test.startTest();
        result = SyncAccountWS.getProfilesForPortalUsers();
        Test.stopTest();

        System.assertEquals(
            2,
            result.size(),
            'Method should return Set of Id with 2 values'
        );
    }

    @isTest
    private static void testGetProfileForNewUserShouldCoverCatch() {
        insert new RingCentralVariousSettings__c(
            Use_Community_Licenses_on_portal__c = true,
            ProfileForNewPortalUser__c = 'invalidProfile'
        );

        Id result;

        Test.startTest();
        result = SyncAccountWS.getProfileForNewUser();
        Test.stopTest();

        System.assertEquals(
            ProfileHelper.PROFILE_ID_CUSTOMER_PORTAL_USER,
            result,
            'Method should return correct Id'
        );
    }

    @isTest
    private static void testSubstringStr() {
        String result;

        Test.startTest();
        result = SyncAccountWS.substringStr('1234', 2);
        Test.stopTest();

        System.assertEquals(
            '12',
            result,
            'Method should return correct value'
        );
    }

    @isTest
    private static void testSearchContactandLeadByDealId() {
        SyncAccountWS.syncAcctInputParam syncparam = new SyncAccountWS.syncAcctInputParam();
        syncparam.In_Partner_Deal_Registration_Id = '11';

        Account acc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test acc',
                Account.Payment_Method__c => 'Invoice',
                Account.Tax_Exempt__c => false,
                Account.SignupType__c => 'Free',
                Account.Monthly_Credit_Limit__c => 0,
                Account.Sign_up_Purchase_Limit__c => 0,
                Account.Payment_Terms__c => '12',
                Account.Invoice_Terms__c => '12',
                Account.PID__c => 'test_p_id',
                Account.Timezone__c => TEST_TIME_ZONE_NAME,
                Account.BillingCity => 'TestCity',
                Account.BillingStreet => 'TestStreet',
                Account.BillingState => 'NY',
                Account.BillingPostalCode => '123890',
                Account.BillingCountry => 'US'
            })
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.AccountId => acc.Id,
                Contact.LastName => 'John',
                Contact.FirstName => 'Good',
                Contact.Email => 'jg@rc.test',
                Contact.PartnerDeal_Registration_Id__c => 11
            })
            .create()
            .getRecord();

        Boolean result;

        Test.startTest();
        result = SyncAccountWS.searchContactandLeadByDealId(syncparam);
        Test.stopTest();

        System.assert(
            result,
            'Method should return true'
        );
        System.assertEquals(
            1,
            syncparam.searchContact.size(),
            'Field searchContact populated incorrectly'
        );
    }

    @isTest
    private static void testSearchContactandLeadByDealIdContactsListEmpty() {
        SyncAccountWS.syncAcctInputParam syncparam = new SyncAccountWS.syncAcctInputParam();
        syncparam.In_Partner_Deal_Registration_Id = '11';

        Lead lead = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Lead.LastName => 'TestLead',
                Lead.PartnerDeal_Registration_Id__c => 11,
                Lead.IsConverted => false
            })
            .create()
            .getRecord();

        Boolean result;

        Test.startTest();
        result = SyncAccountWS.searchContactandLeadByDealId(syncparam);
        Test.stopTest();

        System.assert(
            result,
            'Method should return true'
        );
        System.assertEquals(
            1,
            syncparam.searchlead.size(),
            'Field searchlead populated incorrectly'
        );
    }

    @isTest
    private static void testSearchContactandLeadByDealIdContactsAndLeadsListsEmpty() {
        SyncAccountWS.syncAcctInputParam syncparam = new SyncAccountWS.syncAcctInputParam();
        syncparam.In_Partner_Deal_Registration_Id = '11';

        Boolean result;

        Test.startTest();
        result = SyncAccountWS.searchContactandLeadByDealId(syncparam);
        Test.stopTest();

        System.assert(
            !result,
            'Method should return false'
        );
    }

    @isTest
    private static void testSearchContactandLeadByDealIdShouldCoverCatch() {
        SyncAccountWS.syncAcctInputParam syncparam = new SyncAccountWS.syncAcctInputParam();
        syncparam.In_Partner_Deal_Registration_Id = 'invalid';

        Boolean result;

        Test.startTest();
        result = SyncAccountWS.searchContactandLeadByDealId(syncparam);
        Test.stopTest();

        System.assert(
            !result,
            'Method should return false'
        );
        System.assert(
            syncparam.OutErrorMsg.contains('searchContactandLeadByDealId'),
            'Catch block works incorrectly'
        );
    }

    @isTest
    private static void verifyServiceCreatesUsersBulkified() {

        final Integer NUM_OF_NEW_USERS = 10;
        final String EXPECTED_ERRORS_OCCURED = 'Expected errors ouccred during user creation';
        final String EXPECTED_NO_ERRORS_OCCURED = 'Expected no errors ouccred during user creation';
        final String EXPECTED_USER_CREATED = 'Expected user to be created';
        final String EXPECTED_USER_NOT_CREATED = 'Expected user not created';

        List<SyncAccountWS.syncAcctInputParam> syncparams = new List<SyncAccountWS.syncAcctInputParam>();

        Id syncUsersProfileId = new ProfileSelector()
                                  .selectProfileByName(new List<Object>{ 'Customer Community Login User Custom' })
                                  .executeQuery()
                                  .get(0)
                                  .Id;

        new SObjectBuilder(RingCentralVariousSettings__c.sObjectType)
            .setField(RingCentralVariousSettings__c.ProfileForNewPortalUser__c, String.ValueOf(syncUsersProfileId))
            .create();

        List<Contact> contacts = new SObjectBuilder(Contact.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.AccountId => ValueProviderBuilder.provideGenericParent(Account.sObjectType),
                Contact.Email => ValueProviderBuilder.provideUniqueEmail()
            })
            .quantity(NUM_OF_NEW_USERS)
            .create()
            .getRecords();

        for (Integer numUsers = 0; numUsers < NUM_OF_NEW_USERS; numUsers++) {
            SyncAccountWS.syncAcctInputParam syncparam = getInputParam();
            syncparam.In_ContactEmail = contacts[numUsers].Email;
            syncparam.proc_ContactId = contacts[numUsers].Id;
            syncparams.add(syncparam);
        }

        /* For the first conatact we will create a user and expect service to not create a user */
        User alreadyExistedUser = SyncAccountWS.buildUser(syncparams[0]);
        insert alreadyExistedUser;

        /* Sync the users */
        syncparams = SyncAccountWS.synAccountCreateUsers(syncparams);

        /* Check that the first user was skipped */
        System.assertNotEquals(syncparams[0].outErrorMsg, '', EXPECTED_ERRORS_OCCURED);
        System.assertEquals(syncparams[0].Out_UserID, null, EXPECTED_USER_NOT_CREATED);

        /* Check that remainig 9 users were created*/
        for (Integer numUsers = 1; numUsers < syncparams.size(); numUsers++) {
            System.assertEquals(syncparams[numUsers].outErrorMsg, '', EXPECTED_NO_ERRORS_OCCURED);
            System.assertNotEquals(syncparams[numUsers].Out_UserID, null, EXPECTED_USER_CREATED);
        }
    }

    @isTest
    private static void testSearchContactByMailAndBrand() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ValueProviderBuilder.provideUniqueString('Test Account'),
                Account.RecordTypeId => AccountHelper.RT_ID_CUSTOMER_ACCOUNT,
                Account.RC_User_ID__c => null
            })
            .create()
            .getRecord();

        String testEmail = 'testemail@vendor.com';

        List<Contact> testContact = (List<Contact>) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.AccountId => acc.Id,
                    Contact.LastName => ValueProviderBuilder.provideUniqueString(),
                    Contact.Email => testEmail
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        SyncAccountWS.syncAcctInputParam syncparam = new SyncAccountWS.syncAcctInputParam();
        syncparam.In_ContactEmail = testEmail;
        System.assert(SyncAccountWS.searchContactByMailAndBrand(syncparam), 'Should return true');
    }

    @isTest
    private static void testSynAccountNew() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                        Account.Name => ValueProviderBuilder.provideUniqueString('Test Account'),
                        Account.RecordTypeId => AccountHelper.RT_ID_CUSTOMER_ACCOUNT
                })
                .create()
                .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.AccountId => acc.Id,
                Contact.Email => ValueProviderBuilder.provideUniqueEmail(),
                Contact.PartnerDeal_Registration_Id__c => 11
            })
            .create()
            .getRecord();

        SyncAccountWS.syncAcctInputParam syncparam = getInputParam();
        syncparam.In_Partner_Deal_Registration_Id = '11';
        syncparam = SyncAccountWS.synAccountNew(syncparam);
        System.assertEquals(acc.Id, syncparam.proc_AccountId, 'Field proc_AccountId populated incorrectly');
        System.assertEquals(contact.Id, syncparam.proc_ContactId, 'Field proc_ContactId populated incorrectly');
    }

    @isTest
    private static void testSynAccountCreateUsersCatchBlock() {
        List<SyncAccountWS.syncAcctInputParam> syncparams = new List<SyncAccountWS.syncAcctInputParam>();
        SyncAccountWS.syncAcctInputParam syncparam = new SyncAccountWS.syncAcctInputParam();
        syncparam.proc_UserRecCreation = '-1';
        syncparam.In_RCUserID = '-1';
        syncparam.In_ContactEmail = '-1';
        syncparam.proc_ContactId = '`';
        syncparams.add(syncparam);
        syncparams = SyncAccountWS.synAccountCreateUsers(syncparams);
        System.assert(String.isNotBlank(syncparams[0].OutErrorMsg), 'Should be error message');
        System.assert(
            syncparams[0].OutErrorMsg.contains('Error while creating user'),
            'Catch block works incorrectly'
        );
    }

    @isTest
    private static void testHandleUpdateAccountCatchBlock() {
        SyncAccountWS.syncAcctInputParam syncparam = new SyncAccountWS.syncAcctInputParam();
        syncparam.In_RCUserID = '`';
        Boolean result = SyncAccountWS.handleUpdateAccount(syncparam);
        System.assert(
            syncparam.OutErrorMsg.contains('handleUpdateAccount'),
            'Catch block works incorrectly'
        );
        System.assert(!result, 'Should return false');
    }

    @isTest
    private static void testHandleCreateAccountCatchBlock() {
        SyncAccountWS.syncAcctInputParam syncparam = new SyncAccountWS.syncAcctInputParam();
        syncparam.In_RCUserID = '`';
        Boolean result = SyncAccountWS.handleCreateAccount(syncparam);
        System.assert(
                syncparam.OutErrorMsg.contains('handleCreateAccount'),
                'Catch block works incorrectly'
        );
        System.assert(!result, 'Should return false');
    }
}