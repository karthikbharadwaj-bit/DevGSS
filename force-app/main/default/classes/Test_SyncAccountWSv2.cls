@isTest
private class Test_SyncAccountWSv2 {
    public static final string TEST_TIME_ZONE_NAME = '(GMT-12:00) International Date Line West';

    public Account createAccount() {
        Account accountobj1 = new Account();
        accountobj1.Name = 'Test Customer Account'+String.valueOf(System.currentTimeMillis());
        accountobj1.Partner_ID__c = 'PARTNER002';
        accountobj1.Phone = '9910101111';
        accountobj1.AccountNumber = '991010';
        accountobj1.RC_User_ID__c = '2133123188';
        accountobj1.RecordTypeId = AccountHelper.RT_ID_CUSTOMER_ACCOUNT;
        insert accountobj1;

        return accountobj1;
    }

    public EntitlementEnable__c createEntitlementEnable() {
        EntitlementEnable__c mycs = EntitlementEnable__c.getValues('IsEntitlementsEnabled__c');
        if(mycs == null) {
            mycs = new EntitlementEnable__c();
            mycs.IsEntitlementsEnabled__c = true;
            mycs.Name = 'IsEntitlementsEnabled';
            insert mycs;
        }

        return mycs;
    }

    public Contact createContact(Account accountobj1) {
        Contact contObj = new Contact();
        contObj.AccountId =  accountobj1.Id;
        contObj.Email = 'abc2@test.com';
        contObj.LastName = 'Test Last2'+String.valueOf(System.currentTimeMillis());
        contObj.FirstName = 'Test First2'+String.valueOf(System.currentTimeMillis());
        contObj.PartnerDeal_Registration_ID__c = 111222333;
        insert contObj;

        Contact contObj2 = new Contact();
        contObj2.AccountId =  accountobj1.Id;
        contObj2.Email = 'abc2@test.com';
        contObj2.LastName = 'Test Last4'+String.valueOf(System.currentTimeMillis());
        contObj2.FirstName = 'Test First4'+String.valueOf(System.currentTimeMillis());
        insert contObj2;

        return contObj;
    }

    public User createUser(Contact contObj) {
        // Creating User record.
        User testUser = new User(
                        Alias = 'u1',
                        Email = 'u1234@testorg.com',
                        EmailEncodingKey = 'UTF-8',
                        LastName = 'Testing' + String.valueOf(System.currentTimeMillis()),
                        ProfileId = SyncBizAccountWS.PROFILE_ID_FOR_NEW_PORTAL_USERS,
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

    public Opportunity createOpportunity(Account accountobj1) {
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

    public Lead createLead() {
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
        leadObj.PartnerDeal_Registration_ID__c = 111222444;
        //leadObj.Account__c
        insert leadObj;

        return leadObj;
    }

    public static SyncAccountWSv2.syncAcctInputParam getInputParam() {
        Test_SyncAccountWSv2 testClassObject = new Test_SyncAccountWSv2();
        SyncAccountWSv2.syncAcctInputParam syncparam = new SyncAccountWSv2.syncAcctInputParam();
        syncparam.accountparams = testClassObject.createAccount();
        syncparam.contactparams = testClassObject.createContact(syncparam.accountparams);
        syncparam.searchlead = new List<Lead> {testClassObject.createLead()};
        syncparam.searchParams = new Map<String, String>{ 'email' => 'abc2@test.com' };

        syncparam.packages = new List<Package__c>();
        Package__c pack1 = new Package__c(
            Package_Name__c = 'PACKAGE_NAME',
			Service_Account_Status__c = 'Status',
			Service_Type__c = 'SERVICEGROUPNAME',
			Account_Package_Id__c = '1112123',
			Package_Status__c = 'New Status',
            RC_User_ID__c = '2133123188'
        );
        syncparam.packages.add(pack1);

        syncparam.searchParams.put('enterpriseAccountId', '2133123188');
        syncparam.searchParams.put('dealRegId', '111222333');

        return syncparam;
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void Test_SyncAccountWSv2_positive() {
        Test_SyncAccountWSv2 testClassObject = new Test_SyncAccountWSv2();

        SyncAccountWSv2 syncAcc = new SyncAccountWSv2();
        SyncAccountWSv2.syncAcctInputParam syncparam = getInputParam();

        Opportunity opp = testClassObject.createOpportunity(syncparam.accountparams);
        syncparam.searchParams.put('opportunityId', opp.Id);

        Test.startTest();
            SyncAccountWSv2.syncAccountNew(syncparam, false);
            SyncAccountWSv2.accountMatchingContactEmail(syncparam);
            SyncAccountWSv2.accountMatchingContactEmail(syncparam);
            SyncAccountWSv2.handleCreateContact(syncparam);
            SyncAccountWSv2.searchLeadByEmail(syncparam);
            SyncAccountWSv2.searchContactByMailAndBrand(syncparam);
            SyncAccountWSv2.searchOpportunityById(syncparam);
            SyncAccountWSv2.searchAccountByEnterpriseAccountID(syncparam, false);
            SyncAccountWSv2.searchContactandLeadByDealId(syncparam);
            syncparam.searchParams.put('dealRegId', '111222444');
            SyncAccountWSv2.searchContactandLeadByDealId(syncparam);
            SyncAccountWSv2.getOfferTypeForAccount(syncparam);
            SyncAccountWSv2.getPurchasedLicensesNumber(syncparam);
            SyncAccountWSv2.checkFedRampOpportunity(opp.Id);
            syncparam.searchParams.put('enterpriseAccountId', '21331231');
            SyncAccountWSv2.handleCreateAccount(syncparam);
            SyncAccountWSv2.handleUpdateAccount(syncparam);
            SyncAccountWSv2.handleUpdateAccountAndContact(syncparam);
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void Test_SyncAccountWSv2_negative() {
        Test_SyncAccountWSv2 testClassObject = new Test_SyncAccountWSv2();
        //Setting up records database.
        EntitlementEnable__c mycs = EntitlementEnable__c.getValues('IsEntitlementsEnabled__c');
        mycs = testClassObject.createEntitlementEnable();

        SyncAccountWSv2 syncAcc = new SyncAccountWSv2();
        SyncAccountWSv2.syncAcctInputParam syncparam = getInputParam();

        Opportunity opp = testClassObject.createOpportunity(syncparam.accountparams);

        syncparam.searchParams.put('enterpriseAccountId', null);
        syncparam.searchParams.put('dealRegId', null);
        syncparam.searchParams.put('opportunityId', opp.Id);
        syncparam.contactparams = null;

        Account currentAcc = [select Id, RC_User_Id__c from Account where Id = :syncparam.accountparams.Id];
        currentAcc.RC_User_Id__c = null;
        currentAcc.RecordTypeId = AccountHelper.RT_ID_CUSTOMER_ACCOUNT;
        currentAcc.Service_Type__c = AccountHelper.SERVICE_TYPE_RCCC;
        currentAcc.AccMigrationFlag__c = AccountHelper.ACCOUNT_MIGRATION_TYPE_IN_PROGRESS;
        update currentAcc;

        syncparam.accountparams = currentAcc;
        syncparam.searchParams.put('billingId', '111222333444');

        Test.startTest();
            SyncAccountWSv2.searchContactByMailAndBrand(syncparam);
            SyncAccountWSv2.syncAccountNew(syncparam, false);
            syncparam.accountparams.Id = null;
            SyncAccountWSv2.handleUpdateAccount(syncparam);
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void Test_SyncAccountWSv2_negative_withDealRegIdAndContact() {
        Test_SyncAccountWSv2 testClassObject = new Test_SyncAccountWSv2();
        // Setting up records database.
        EntitlementEnable__c mycs = EntitlementEnable__c.getValues('IsEntitlementsEnabled__c');
        mycs = testClassObject.createEntitlementEnable();

        SyncAccountWSv2 syncAcc = new SyncAccountWSv2();
        SyncAccountWSv2.syncAcctInputParam syncparam = getInputParam();

        Opportunity opp = testClassObject.createOpportunity(syncparam.accountparams);

        syncparam.searchParams.put('enterpriseAccountId', null);
        syncparam.searchParams.put('dealRegId', '111222333'); // Set non-empty dealRegId
        syncparam.searchParams.put('opportunityID', opp.Id);
        syncparam.contactparams = null;

        Account currentAcc = [select Id, RC_User_Id__c from Account where Id = :syncparam.accountparams.Id];
        currentAcc.RC_User_Id__c = null;
        currentAcc.RecordTypeId = AccountHelper.RT_ID_CUSTOMER_ACCOUNT;
        currentAcc.Service_Type__c = AccountHelper.SERVICE_TYPE_RCCC;
        currentAcc.AccMigrationFlag__c = AccountHelper.ACCOUNT_MIGRATION_TYPE_IN_PROGRESS;
        update currentAcc;

        syncparam.accountparams = currentAcc;
        syncparam.searchParams.put('billingId', '111222333444');

        Test.startTest();
            SyncAccountWSv2.searchContactByMailAndBrand(syncparam);
            SyncAccountWSv2.syncAccountNew(syncparam, false);
            syncparam.accountparams.Id = null;
            SyncAccountWSv2.handleUpdateAccount(syncparam);
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void Test_SyncAccountWSv2_emptyAccount() {
        Test_SyncAccountWSv2 testClassObject = new Test_SyncAccountWSv2();
        //Setting up records database.
        EntitlementEnable__c mycs = EntitlementEnable__c.getValues('IsEntitlementsEnabled__c');
        mycs = testClassObject.createEntitlementEnable();

        SyncAccountWSv2 syncAcc = new SyncAccountWSv2();
        SyncAccountWSv2.syncAcctInputParam syncparam = getInputParam();

        syncparam.searchParams.put('dealRegId', null);
        syncparam.searchParams.put('opportunityId', null);
        syncparam.searchParams.put('email', 'abc2@test.com');
        syncparam.searchParams.put('billingId', '111222333444');

        syncparam.contactparams = null;

        Account currentAcc = [select Id, RC_User_Id__c, Name from Account where Id = :syncparam.accountparams.Id];
        currentAcc.RC_User_ID__c = null;
        currentAcc.RecordTypeId = AccountHelper.RT_ID_CUSTOMER_ACCOUNT;
        currentAcc.RC_Brand__c = 'RingCentral';
        update currentAcc;

        syncparam.accountparams = currentAcc;
        syncparam.accountparams.Id = null;
        syncparam.accountparams.RC_User_ID__c = '2133123188';

        Test.startTest();
            SyncAccountWSv2.syncAccountNew(syncparam, false);
        Test.stopTest();

        // Asserts
        List<Account> result = [SELECT Id, RC_User_ID__c FROM Account WHERE Name = :currentAcc.Name];
        Assert.areEqual(1, result.size(), 'There should be exactly one account after upserting by an email');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void Test_searchContactByEmail() {
        Test_SyncAccountWSv2 testClassObject = new Test_SyncAccountWSv2();
        //Setting up records database.
        EntitlementEnable__c mycs = EntitlementEnable__c.getValues('IsEntitlementsEnabled__c');
        mycs = testClassObject.createEntitlementEnable();

        SyncAccountWSv2 syncAcc = new SyncAccountWSv2();
        SyncAccountWSv2.syncAcctInputParam syncparam = getInputParam();

        Opportunity opp = testClassObject.createOpportunity(syncparam.accountparams);

        syncparam.searchParams.put('enterpriseAccountId', null);
        syncparam.searchParams.put('dealRegId', null);
        syncparam.searchParams.put('opportunityId', opp.Id);

        Account currentAcc = [select Id, RC_User_Id__c from Account where Id = :syncparam.accountparams.Id];
        currentAcc.RC_User_Id__c = null;
        currentAcc.RecordTypeId = AccountHelper.RT_ID_CUSTOMER_ACCOUNT;
        update currentAcc;

        syncparam.accountparams = currentAcc;
        syncparam.accountparams.Service_Type__c = AccountHelper.SERVICE_TYPE_RCCC;
        syncparam.searchParams.put('billingId', '111222333444');

        Test.startTest();
            SyncAccountWSv2.searchContactByMailAndBrand(syncparam);

            delete [select Id from Contact where Email = 'abc2@test.com' and PartnerDeal_Registration_ID__c = 111222333 limit 1];

            SyncAccountWSv2.searchContactByMailAndBrand(syncparam);
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void Test_searchContactByEmailWithoutOpp() {
        Test_SyncAccountWSv2 testClassObject = new Test_SyncAccountWSv2();
        //Setting up records database.
        EntitlementEnable__c mycs = EntitlementEnable__c.getValues('IsEntitlementsEnabled__c');
        mycs = testClassObject.createEntitlementEnable();

        Feature_Toggle__c toggle = Feature_Toggle__c.getOrgDefaults();
        toggle.Disable_CUG_Account_Sync__c = false;
        insert toggle;

        SyncAccountWSv2 syncAcc = new SyncAccountWSv2();
        SyncAccountWSv2.syncAcctInputParam syncparam = getInputParam();

        syncparam.searchParams.put('enterpriseAccountId', '2133123188');
        syncparam.searchParams.put('dealRegId', null);

        Account currentAcc = [select Id, Name, RC_User_Id__c from Account where Id = :syncparam.accountparams.Id];
        currentAcc.RC_User_Id__c = null;
        currentAcc.RecordTypeId = AccountHelper.RT_ID_CUSTOMER_ACCOUNT;
        update currentAcc;

        syncparam.accountparams = currentAcc;
        syncparam.accountparams.Service_Type__c = AccountHelper.SERVICE_TYPE_RCCC;
        syncparam.searchParams.put('billingId', '111222333444');
        syncparam.accountparams.Bt_Cug_Number__c = '111';

        Test.startTest();
            SyncAccountWSv2.searchContactByMailAndBrand(syncparam);
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void Test_searchContactByDealRegId() {
        Test_SyncAccountWSv2 testClassObject = new Test_SyncAccountWSv2();
        SyncAccountWSv2 syncAcc = new SyncAccountWSv2();
        SyncAccountWSv2.syncAcctInputParam syncparam = getInputParam();

        syncparam.contactparams.Id = null;
        syncparam.searchParams.put('enterpriseAccountId', null);

        Test.startTest();
            SyncAccountWSv2.handleUpdateAccount(syncparam);
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void Test_handleCreateAccount() {
        Test_SyncAccountWSv2 testClassObject = new Test_SyncAccountWSv2();

        SyncAccountWSv2 syncAcc = new SyncAccountWSv2();
        SyncAccountWSv2.syncAcctInputParam syncparam = getInputParam();
        syncparam.accountparams = new Account(
            Name = 'Acc For Inserting 121212'
        );

        Test.startTest();
            SyncAccountWSv2.handleCreateAccount(syncparam);
        Test.stopTest();
    }

}