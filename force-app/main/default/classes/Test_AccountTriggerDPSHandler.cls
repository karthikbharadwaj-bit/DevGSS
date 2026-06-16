@isTest
private class Test_AccountTriggerDPSHandler {
    private final static String TEST_STRING = 'TestString';

    public static Account testAccount;
    public static Account testAccount2;
    public static Contact testContact;
    public static Contact testContact2;

    private static Account getAccountById(Id accountId){
        return [SELECT Id, AHSearchCriteriaFieldsHaveBeenModified__c, Bill_As_Of_Date__c, InContact_Service__c,
                Number_of_POC_Users__c, SignupType__c, Current_Owner__c, Product_Survey__c, Service_Type__c,
                Current_Owner_Email__c, Current_Owner_Email_Previous__c, Current_Owner_Previous__c,
                Current_Owner_Previous__r.Email,
                RC_Brand__c, CSM_Email__c, CSM_Phone__c, CSM_Name__c, CSM__c
                FROM Account
                WHERE Id =: accountId
                LIMIT 1];
    }

    private static User createUser(String name) {
        return createUser(name, ProfileHelper.SYSTEM_ADMIN, true);
    }

    private static User createUser(String name, String profileName, Boolean isNeedInsert) {
        User user = new User(
            Username = name+'!user@gmail.com',
            LastName = 'Test'+name,
            Email = name+'_user@gmail.com',
            Alias = 'test' + name.left(4),
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id, Name FROM Profile WHERE Name = :profileName].Id,
            LanguageLocaleKey = 'en_US',
            isActive = true
        );
        if(isNeedInsert) {
            insert user;
        }
        return user;
    }

    public static void createTestData(){
        testAccount = new Account();
        testAccount.Name = 'Test123';
        testAccount.SignupType__c = 'TRIAL_30NOCC';
        testAccount.RC_Account_Status__c = 'TRIAL';
        testAccount.SignupPlatform__c = 'WEB';
        testAccount.RC_Service_name__c = 'office123';
        testAccount.RC_Activation_Date__c = null;
        testAccount.Partner_ID__c = '9852';
        testAccount.Permitted_Brands__c = 'RingCentral';
        insert testAccount;

        testContact = new Contact();
        testContact.AccountId =  testAccount.id;
        testContact.Email = 'fake@email.com';
        testContact.LastName = 'TestLast';
        testContact.Phone='9910106804';
        insert testContact;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            Type = 'Syndicated - New',
            StageName = OpportunityHelper.STAGE_NAME_CLOSED_WON,
            CloseDate = System.today(),
            Brand_Name__c = 'RingCentral',
            Tier_Name__c = '999',
            AccountId = testAccount.Id
        );
        insert opp;
 }
    public static void createCustomSettingData(){
    List<descartesdps__DPSAppSettings__c>lstDPSAPP=new List<descartesdps__DPSAppSettings__c>();
        descartesdps__DPSAppSettings__c setting =new descartesdps__DPSAppSettings__c();
        setting.descartesdps__AllowScreeningCustRecords__c = true;
        setting.descartesdps__AllowScreeningStdRecords__c=true;
        setting.descartesdps__AlwaysIncludeUnknownCountry__c=true;
        setting.descartesdps__ApplicationErrorEmail__c='rubby@email.com';
        setting.descartesdps__ComplianceOfficerEmail__c='baby@email.com';
        setting.descartesdps__CustInsertTriggersEnabled__c=true;
        setting.descartesdps__CustUpdateTriggersEnabled__c=true;
        setting.descartesdps__ExcludeCommonWords__c=true;
        setting.descartesdps__ExcludeWeakAliases__c=true;
        setting.descartesdps__IncludeDelistedParties__c=true;
        setting.descartesdps__IncludeSalesforceUUID__c=true;
        setting.descartesdps__RequireNotesForScreenActions__c=true;
        setting.descartesdps__StdInsertTriggersEnabled__c=true;
        setting.descartesdps__StdUpdateTriggersEnabled__c=true;
        setting.Name='DPSDefaultAppSettings';
        insert setting;


  }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void accountUpdateTestDPS1() {
        createTestData();
        User testUser = createUser('TestUser1');
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
        TriggerHandler.BY_PASS_ACCOUNT_ON_BEFORE = false;

        Test.startTest();
        testAccount.BillingCountry = 'United States';
        testAccount.OwnerId = testUser.Id;
        update testAccount;
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void accountUpdateTestDPS2() {
        createTestData();
        User testUser = createUser('TestUser2');
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
        TriggerHandler.BY_PASS_ACCOUNT_ON_BEFORE = false;

        testAccount.BillingCountry = 'North Korea';
        testAccount.OwnerId = testUser.Id;
        update testAccount;

        Test.startTest();
        testAccount.descartesdps__HasBeenFlaggedByDPS__c = true;
        try {
            update testAccount;
        } catch (Exception e) {}
        Test.stopTest();

        // List<descartesdps__DescartesDPSScreen__c> listScreenRecs = [SELECT Id, descartesdps__EntityID__c, Name, descartesdps__Status__c
        //                                                             FROM descartesdps__DescartesDPSScreen__c WHERE descartesdps__EntityID__c =:testAccount.Id];

        // system.debug('Screening Records+++'+listScreenRecs);
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void parterleadDPS3() {
        createTestData();
        createCustomSettingData();
        User testUser = createUser('TestUser2');
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
        TriggerHandler.BY_PASS_ACCOUNT_ON_BEFORE = false;
        update testAccount;

        Test.startTest();
        AccountTriggerHandler.isPartnerLeadConversion=true;
        testAccount.descartesdps__HasBeenFlaggedByDPS__c = true;

        try {
            update testAccount;
        } catch (Exception e) {}

        Test.stopTest();
        system.debug('isPartnerLeadConversion+++'+ AccountTriggerHandler.isPartnerLeadConversion);
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void parterleadDPS4() {
        createCustomSettingData();
        User testUser = createUser('TestUser2');
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
        TriggerHandler.BY_PASS_ACCOUNT_ON_BEFORE = false;

        Test.startTest();

        AccountTriggerHandler.isPartnerLeadConversion=true;
        testAccount = new Account();
        testAccount.Name = 'Test123';
        testAccount.SignupType__c = 'TRIAL_30NOCC';
        testAccount.RC_Account_Status__c = 'TRIAL';
        testAccount.SignupPlatform__c = 'WEB';
        testAccount.RC_Service_name__c = 'office123';
        testAccount.RC_Activation_Date__c = null;
        testAccount.Partner_ID__c = '9852';
        testAccount.Permitted_Brands__c = 'RingCentral';
        testAccount.descartesdps__HasBeenFlaggedByDPS__c=true;
        insert testAccount;
        Test.stopTest();

    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void parterleadDPS5() {
        createTestData();
        createCustomSettingData();
        User testUser = createUser('TestUser2');
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
        TriggerHandler.BY_PASS_ACCOUNT_ON_BEFORE = false;
        testAccount.descartesdps__HasBeenFlaggedByDPS__c = true;

        try {
            update testAccount;
        } catch (Exception e) {}

        Test.startTest();

        testAccount.descartesdps__HasBeenFlaggedByDPS__c = false;

        update testAccount;

        Test.stopTest();
        system.debug('isPartnerLeadConversion+++'+ AccountTriggerHandler.isPartnerLeadConversion);
    }
}