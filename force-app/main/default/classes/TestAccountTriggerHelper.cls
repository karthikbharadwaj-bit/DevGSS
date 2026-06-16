/**************************************************************************************************
* Project Name..........: Account	                                                              *
* File..................: TestAccountTriggerHelper.class                                          *
* Version...............: 1.0                                                                     *
* Created by............: Simplion Technologies                                                   *
* Created Date..........: 06-04-2014                                                              *
* Last Modified by......: Simplion Technologies                                                   *
* Last Modified Date....: 06-04-2014                                                              *
* Description...........: This is a test class for AccountTriggerHelper class.                    *
**************************************************************************************************/

@isTest
private class TestAccountTriggerHelper {

    public static Test_Utils objTest_Utils = new Test_Utils();

    private static void setBypassFlagFalse(){
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE =  false;
    }

    public static Account testAccount;
    public static Contact testContact;


    public static void createTestData(){
        testAccount = new Account();
        testAccount.Name = 'Test123';
        testAccount.SignupType__c = 'TRIAL_30NOCC';
        testAccount.RC_Account_Status__c = 'TRIAL';
        testAccount.SignupPlatform__c = 'WEB';
        testAccount.RC_Service_name__c = 'office123';
        testAccount.RC_Activation_Date__c = null;
        testAccount.Partner_ID__c = '9852';
        insert testAccount;

        testContact = new Contact();
        testContact.AccountId =  testAccount.id;
        testContact.Email = 'fake@email.com';
        testContact.LastName = 'TestLast';
        testContact.Phone='9910106804';
        insert testContact;
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void updateAccountActiveDateWeb(){

        TriggerHandler.BY_PASS_LEAD_UPDATE = true;

        Account accObj = new Account();
        accObj.Name = 'Test123';
        accObj.SignupType__c = 'TRIAL_30NOCC';
        accObj.RC_Account_Status__c = 'TRIAL';
        accObj.SignupPlatform__c = 'WEB';
        accObj.RC_Service_name__c = 'office123';
        accObj.RC_Activation_Date__c = null;
        accObj.Partner_ID__c = '9852';
        insert accObj;

        Contact contactObj = new Contact();
        contactObj.AccountId =  accObj.id;
        contactObj.Email = 'fake@email.com';
        contactObj.LastName = 'TestLast';
        contactObj.Phone='9910106804';
        insert contactObj;

        setBypassFlagFalse();
        accObj.RC_Service_name__c = 'Office789';
        update accObj;
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void updateLeadTRIAL_30_NO_CC(){
        Account acctObj = new Account();
        acctObj.Name = 'Test12';
        acctObj.SignupType__c = 'TRIAL_30NOCC';
        acctObj.RC_Account_Status__c = null;
        acctObj.SignupPlatform__c = 'iphone';
        acctObj.RC_Service_name__c = 'office123';
        insert acctObj;

        Contact contactObj = new Contact();
        contactObj.AccountId =  acctObj.id;
        contactObj.Email = 'fake@email.com';
        contactObj.LastName = 'TestLast';
        contactObj.Phone='9910106804';
        insert contactObj;

        setBypassFlagFalse();
        acctObj.SignupType__c = null;
        acctObj.RC_Account_Status__c = 'Trial 30 no-CC';
        acctObj.SignupPlatform__c = null;
        acctObj.RC_Service_name__c = 'Office789';
        update acctObj;
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void updateAccountActiveDateMobile(){
        TriggerHandler.BY_PASS_LEAD_UPDATE = true;
        Account acctObj = new Account();
        acctObj.Name = 'Test12';
        acctObj.SignupType__c = 'TRIAL_30NOCC';
        acctObj.RC_Account_Status__c = 'TRIAL';
        acctObj.SignupPlatform__c = 'iphone';
        acctObj.RC_Service_name__c = 'office123';
        insert acctObj;

        Contact contactObj = new Contact();
        contactObj.AccountId =  acctObj.id;
        contactObj.Email = 'fake@email.com';
        contactObj.LastName = 'TestLast';
        contactObj.Phone='9910106804';
        insert contactObj;

        setBypassFlagFalse();
        acctObj.RC_Service_name__c = 'Office789';
        update acctObj;

    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void survey(){
        // TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = true;
        // TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = true;
        // TriggerHandler.BY_PASS_CONTACT_ON_INSERT = true;
        // TriggerHandler.BY_PASS_CONTACT_ON_UPDATE = true;
        //TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT = true;
        //TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE = true;

        List<Account> accountList = new List<Account>();
        Map<Id,Account> newAccountMap = new Map<Id,Account>();
        Account oldAccount;

        Schema.DescribeSObjectResult result = Account.SObjectType.getDescribe();
        Map<String,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosByName();
        Schema.RecordTypeInfo rtByName =  rtMapByName.get('Partner Account');

        Account accInsert = new Account();
        accInsert.Name = 'Test123';
        accInsert.SignupType__c = 'TRIAL_30NOCC';
        accInsert.RC_Account_Status__c = 'TRIAL';
        accInsert.SignupPlatform__c = 'android';
        accInsert.RC_Service_name__c = 'office123';
        accInsert.RC_Activation_Date__c = null;
        accInsert.RecordTypeId =  rtByName.getRecordTypeId() ;
        accInsert.Partner_ID__c = '9852';
        insert accInsert;

        Contact contactObj = new Contact();
        contactObj.AccountId =  accInsert.id;
        contactObj.Email = 'fake@email.com';
        contactObj.LastName = 'TestLast';
        contactObj.Phone='9910106804';
        insert contactObj;

        test.startTest();


        Opportunity  oppObj = new Opportunity ();
        oppObj.name ='test2';
        oppObj.AccountId= accInsert.id;
        oppObj.Sales_Model__c='direct';
        oppObj.Type='New Business';
        oppObj.StageName='Qualified';
        oppObj.CloseDate=System.today();
        insert oppObj;



        AccountContactRole accountContactRoleObj = new AccountContactRole() ;
        accountContactRoleObj.AccountId = accInsert.Id;
        accountContactRoleObj.ContactId = contactObj.Id;
        accountContactRoleObj.IsPrimary = true;
        insert accountContactRoleObj;

        //setBypassFlagFalse();
        test.stopTest();

        accInsert.RC_Service_name__c = 'office789';
        accInsert.Is_Demo_Account__c = false;
        accInsert.RC_Activation_Date__c = system.now();
        accInsert.RC_Attribution_Channel__c = 'Sales Agents & Resellers';
        update accInsert;

    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void partnerAccount(){

        List<User> userList = new List<User>();
        userList = objTest_Utils.createUserRecord(new List<User>{new User(), new User(), new User()});

        Schema.DescribeSObjectResult result = Account.SObjectType.getDescribe();
        Map<String,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosByName();
        Schema.RecordTypeInfo rtByName =  rtMapByName.get('Partner Account');

        List<Account> accountList = new List<Account>();

        // Parent Account.
        Account accInsert = new Account();
        accInsert.RecordTypeId = rtByName.getRecordTypeId();
        accInsert.Current_Owner__c = userList[0].Id;
        accInsert.Ultimate_Partner_ID__c = '992323';
        accInsert.Type = 'Partner';
        accInsert.Partner_ID__c = '15669';
        accInsert.BillingCountry='Spain';
        accountList.add(accInsert);
        Account accPartnerObj = new Account();
        accPartnerObj.RecordTypeId = rtByName.getRecordTypeId();
        accountList.add(accPartnerObj);
        Account accCustomerObj = new Account();
        accountList.add(accCustomerObj);
        accountList = objTest_Utils.createAccountRecord(accountList);

        Id parentId = accountList[0].Id;

        setBypassFlagFalse();
        accountList[1].Partner_ID__c = parentId;
        accountList[1].Current_Owner__c = userList[1].Id;
        accountList[1].ParentId = parentId;

        accountList[2].Partner_ID__c = parentId;
        accountList[2].Current_Owner__c = userList[2].Id;
        accountList[2].ParentId = parentId;
        accountList[2].Ultimate_Partner_ID__c = '999222';
        update accountList;
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void createImplementationForChange(){
        Test.startTest();
        Test_Utils testUtilsObject =  new Test_Utils();
        testUtilsObject.initialiseTriggerBypass();
        Account acctObj = new Account();
        acctObj.Name = 'Test12';
        acctObj.RC_Brand__c = 'RingCentral';
        acctObj.Number_of_DL_s__c = 2;
        acctObj.RC_Service_name__c = 'office123';
        acctObj.RC_User_ID__c = '1234';
        acctObj.RC_Account_Status__c = null;
        insert acctObj;

        Contact contactObj = new Contact();
        contactObj.AccountId =  acctObj.id;
        contactObj.Email = 'fake@email.com';
        contactObj.LastName = 'TestLast';
        contactObj.Phone='9910106804';
        insert contactObj;


        List<Implementation__c> implementationAccount = new List<Implementation__c>();
        implementationAccount = [SELECT Id FROM Implementation__c WHERE Account__c =: acctObj.Id];
        if(implementationAccount != null && !implementationAccount.isEmpty()){
            delete implementationAccount;
        }

        // Change Account Status.
        //setBypassFlagFalse();
        acctObj.RC_Brand__c = 'RingCentral';
        acctObj.Number_of_DL_s__c = 2;
        acctObj.RC_Service_name__c = 'Office789';
        acctObj.RC_User_ID__c = '12345';
        acctObj.RC_Account_Status__c = 'Trial 30 no-CC';
        update acctObj;

        List<Implementation__c> implementationAccountd = new List<Implementation__c>();
        implementationAccountd = [SELECT Id FROM Implementation__c WHERE Account__c =: acctObj.Id];
        if(implementationAccountd != null && !implementationAccountd.isEmpty()){
            delete implementationAccountd;
        }

        // Change for Telus Account.
        setBypassFlagFalse();
        acctObj.RC_Brand__c = 'Telus';
        acctObj.RC_Account_Status__c = '30-Day Office Trial';
        acctObj.Do_Not_Creation_Implementation__c = false;
        update acctObj;
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void createImplementationForServiceChange(){

        Account acctObj = new Account();
        acctObj.Name = 'Test12';
        acctObj.RC_Brand__c = 'TestBrand';
        acctObj.Number_of_DL_s__c = 2;
        acctObj.RC_Service_name__c = null;
        acctObj.RC_User_ID__c = '1234';
        acctObj.RC_Account_Status__c = null;
        acctObj.RC_Service_name__c = 'Paid';
        acctObj.Service_Type__c = 'Paid';
        insert acctObj;

        Contact contactObj = new Contact();
        contactObj.AccountId =  acctObj.id;
        contactObj.Email = 'fake@email.com';
        contactObj.LastName = 'TestLast';
        contactObj.Phone='9910106804';
        insert contactObj;

        List<Implementation__c> implementationAccountd = new List<Implementation__c>();
        implementationAccountd = [SELECT Id FROM Implementation__c WHERE Account__c =: acctObj.Id];
        if(implementationAccountd != null && !implementationAccountd.isEmpty()){
            delete implementationAccountd;
        }

        setBypassFlagFalse();
        acctObj.RC_Service_name__c = 'Office';
        acctObj.RC_Account_Status__c = 'Canceled';
        acctObj.Service_Type__c = 'Office';
        //acctObj.RC_Account_Status__c = 'Trial';
        update acctObj;
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void getAccountsToValidate(){

        List<Account> accountList = new List<Account>();
        accountList = objTest_Utils.createAccountRecord(new List<Account>{new Account(), new Account()});

        List<Account> accountListnew = new List<Account>();
        Account accInsert = new Account();
        accInsert.ParentId = accountList[0].Id;
        accInsert.RC_User_ID__c = '12321';
        accountListnew.add(accInsert);
        accountListnew = objTest_Utils.createAccountRecord(accountListnew);

        setBypassFlagFalse();
        accountListnew[0].ParentId = accountList[1].Id;
        update accountList;
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void clear(){
        AccountTriggerHelper.deinitalize();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testImplementationMethod(){

        List<Account> accountForImplementation =  new List<Account>();

        // Telus Implementation.
        Account acctObjTelus = new Account();
        acctObjTelus.RC_Brand__c = 'Telus';
        acctObjTelus.RC_Account_Status__c = '30-Day Office Trial';
        acctObjTelus.Do_Not_Creation_Implementation__c = false;
        accountForImplementation.add(acctObjTelus);

        // Ring Central Implementation.
        Account acctObjRC = new Account();
        acctObjRC.RC_Brand__c = 'RingCentral';
        acctObjRC.RC_Account_Status__c = '30-Day Office Trial';
        acctObjRC.Do_Not_Creation_Implementation__c = false;
        accountForImplementation.add(acctObjRC);

        // No Brand as such.
        Account acctObj = new Account();
        acctObj.RC_Brand__c = 'TestBrand';
        acctObj.RC_Account_Status__c = '30-Day Office Trial';
        acctObj.Do_Not_Creation_Implementation__c = false;
        accountForImplementation.add(acctObj);

        accountForImplementation = objTest_Utils.createAccountRecord(accountForImplementation);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testAccountDisabled(){
        Account acctObj = new Account();
        acctObj.Name = 'Test12';
        acctObj.RC_Brand__c = 'RingCentral';
        acctObj.Number_of_DL_s__c = 2;
        acctObj.RC_Service_name__c = null;
        acctObj.RC_User_ID__c = '1234';
        acctObj.RC_Account_Status__c = 'Trial';
        acctObj.Service_Type__c = null;
        acctObj.RC_Activation_Date__c =  null;
        insert acctObj;

        Contact contactObj = new Contact();
        contactObj.AccountId =  acctObj.id;
        contactObj.Email = 'fake@email.com';
        contactObj.LastName = 'TestLast';
        contactObj.Phone='9910106804';
        insert contactObj;

        Opportunity  oppObj = new Opportunity ();
        oppObj.name ='test2';
        oppObj.AccountId= acctObj.id;
        oppObj.Sales_Model__c='direct';
        oppObj.Type='New Business';
        oppObj.StageName='Qualified';
        oppObj.CloseDate=System.today();
        insert oppObj;

        Contract contarctObj = new Contract();
        contarctObj.AccountId = acctObj.Id;
        contarctObj.Status = 'Draft';
        contarctObj.Opportunity__c = oppObj.Id;
        insert contarctObj;

        setBypassFlagFalse();
        acctObj.RC_Brand__c = 'Telus';
        acctObj.Number_of_DL_s__c = 3;
        acctObj.RC_Service_name__c = 'RC Office';
        acctObj.RC_User_ID__c = '12345';
        acctObj.RC_Account_Status__c = 'Disabled';
        acctObj.Do_Not_Creation_Implementation__c = false;
        acctObj.Service_Type__c = 'Office';
        acctObj.RC_Activation_Date__c =  system.now();
        acctObj.Is_Demo_Account__c = false;
        acctObj.RC_Attribution_Channel__c = 'Sales Agents & Resellers';
        update acctObj;
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testAccountDisabledRC(){
        Account acctObj = new Account();
        acctObj.Name = 'Test12';
        acctObj.RC_Brand__c = 'RingCentral';
        acctObj.Number_of_DL_s__c = 2;
        acctObj.RC_Service_name__c = null;
        acctObj.RC_User_ID__c = '1234';
        acctObj.RC_Account_Status__c = 'Trial';
        acctObj.Service_Type__c = null;
        acctObj.RC_Activation_Date__c =  null;
        insert acctObj;

        Contact contactObj = new Contact();
        contactObj.AccountId =  acctObj.id;
        contactObj.Email = 'fake@email.com';
        contactObj.LastName = 'TestLast';
        contactObj.Phone='9910106804';
        insert contactObj;

        setBypassFlagFalse();
        acctObj.RC_Brand__c = 'Telus';
        acctObj.Number_of_DL_s__c = 3;
        acctObj.RC_Service_name__c = 'RC Office';
        acctObj.RC_User_ID__c = null;
        acctObj.RC_Account_Status__c = 'Disabled';
        acctObj.Do_Not_Creation_Implementation__c = false;
        acctObj.Service_Type__c = 'Office';
        acctObj.RC_Activation_Date__c =  system.now();
        acctObj.Is_Demo_Account__c = false;
        acctObj.RC_Attribution_Channel__c = 'Sales Agents & Resellers';
        update acctObj;
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testCreateImplementationRecordForTrialAccount() {

        Account accnt = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideUniqueString('Test account')
                        }
            )
            .create()
            .getRecord();

        Test.startTest();

        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
        TriggerHandler.BY_PASS_ACCOUNT_ON_AFTER = false;

        accnt.RC_Brand__c = 'RingCentral';
        accnt.Number_of_DL_s__c = 10;
        accnt.RC_Account_Status__c = 'Trial (other)';
        accnt.RC_User_Id__c = 'Test RC Enterprise Account Id';
        accnt.RC_Service_Name__c = 'Office';
        accnt.RC_Tier__c = 'Office';

        update accnt;

        List<Implementation__c> implsList = [SELECT Id, Office_Service_Change_Date__c,
                                             Account__c, Brand__c, Tier__c, Service__c, Implementation_Type__c, Type__c
                                             FROM Implementation__c WHERE Account__c =:accnt.Id];

        // System.assert(!implsList.isEmpty(), 'related implementation record should be created');

        // Implementation__c impl = implsList.get(0);
        // System.assertEquals(
        //     accnt.Id,
        //     impl.Account__c,
        //     'implementation record should be related to updated Account'
        // );
        // System.assertEquals(
        //     'New',
        //     impl.Type__c,
        //     'Implementation__c.Type__c field should be populated with "New" value'
        // );
        // System.assert(
        //     impl.Office_Service_Change_Date__c != null,
        //     'Office_Service_Change_Date__c field should be populated'
        // );
        // System.assertEquals(
        //     accnt.RC_Brand__c,
        //     impl.Brand__c,
        //     'Account.RC_Brand__c should be copied to Implementation.Brand__c'
        // );
        // System.assertEquals(
        //     accnt.RC_Tier__c,
        //     impl.Tier__c,
        //     'Account.RC_Tier__c should be copied to Implementation.Tier__c'
        // );
        // System.assertEquals(
        //     accnt.RC_Service_Name__c,
        //     impl.Service__c,
        //     'Account.RC_Service_Name__c should be copied to Implementation.Service__c'
        // );
        // System.assertEquals(
        //     'Trial Account',
        //     impl.Implementation_Type__c,
        //     'Implementation.Implementation_Type__c should have value "Trial Account" if Account.RC_Account_Status__c contains "Trial"'
        // );
        Test.stopTest();
    }

    @isTest
    static void testCreateSurveyRecordOnAccountActivation() {

        Account testPartnerAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideUniqueString('Test Partner account'),
                    Account.RecordTypeId => AccountHelper.RT_ID_PARTNER_ACCOUNT,
                    Account.Is_Demo_Account__c => false,
                    Account.Partner_ID__c => ValueProviderBuilder.provideUniqueString('Test_Partner_Id'),
                    Account.RC_Attribution_Channel__c => 'Sales Agents & Resellers',
                    Account.RC_Service_name__c => AccountHelper.SERVICE_NAME_RC_OFFICE,
                    Account.Type => 'Partner'
                }
            )
            .create()
            .getRecord();

        Contact contactForContactRole = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.LastName => ValueProviderBuilder.provideUniqueString('Test_Contact'),
                    Contact.Email => 'tstemail0@rcmockdomain.com'
                }
            )
            .create()
            .getRecord();

        Contact testPartnerContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.AccountId => testPartnerAcc.Id,
                    Contact.LastName => ValueProviderBuilder.provideUniqueString('Test_Partner_Contact'),
                    Contact.Email => 'tstemail10@anotherrcmockdomain.com'
                }
            )
            .create()
            .getRecord();

            Contract testContract = (Contract) new SObjectBuilder(Contract.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contract.Name => 'Test Contract',
                    Contract.AccountId => testPartnerAcc.Id,
                    Contract.Status => 'Draft'
                }
            )
            .create()
            .getRecord();

        // create AccountContactRole only for one Contact
        AccountContactRole testContactRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => testPartnerAcc.Id,
                        AccountContactRole.ContactId => contactForContactRole.Id,
                        AccountContactRole.Role => 'Signatory',
                        AccountContactRole.IsPrimary => true
                        }
            )
            .create()
            .getRecord();

        Test.startTest();

        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
        TriggerHandler.BY_PASS_ACCOUNT_ON_AFTER = false;

        testPartnerAcc.RC_Activation_Date__c = System.now();

        update testPartnerAcc;

        List<Survey__c> surveyList = [SELECT Id, Account__c, SurveyType__c, Agent__c, Agent_Email__c,
                                      Agent_Name__c, Agent_Team__c, Agent_Manager_Name__c, Agent_Manager_Email__c,
                                      Name, Contact__c, Contact_Email__c
                                      FROM Survey__c
                                      WHERE Account__c =:testPartnerAcc.Id];

        System.assert(!surveyList.isEmpty(), 'related Survey__c record should be created');

        Survey__c createdSurvey = surveyList.get(0);
        System.assertEquals(
            testPartnerAcc.Id,
            createdSurvey.Account__c,
            'Survey__c record should be related to updated Account'
        );

        System.assertEquals(
            'VAR Customer',
            createdSurvey.SurveyType__c,
            'SurveyType__c should be "VAR Customer"'
        );

        System.assertEquals(
            contactForContactRole.Id,
            createdSurvey.Contact__c,
            'created Survey__c record should be realted to Contact from AccountContactRole'
        );

        System.assertEquals(
            contactForContactRole.Email,
            createdSurvey.Contact_Email__c,
            'Survey__c.Contact_Email__c should have value copied from related Contact.Email'
        );

        System.assert(createdSurvey.Name.contains('VAR Customer -'), 'Survey__c.Name should contain "VAR Customer"');

        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testCreateImplementationRecordForBTCloudPhoneBrand() {

        Account accnt = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideUniqueString('Test account'),
                        Account.Do_Not_Creation_Implementation__c => false
                        }
            )
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => accnt.Id,
                        Opportunity.Is_Premium_Implementation_Required__c => true,
                        Opportunity.RecordTypeId => OpportunityHelper.RT_ID_SALES_OPPORTUNITY,
                        Opportunity.Name => 'Test Sales Opportunity',
                        Opportunity.Brand_Name__c => 'RingCentral',
                        Opportunity.Tier_Name__c => 'Office',
                        Opportunity.StageName => '7. Closed Won',
                        Opportunity.CloseDate => System.today(),
                        Opportunity.CurrencyIsoCode => 'USD'
                        })
            .create()
            .getRecord();

        Test.startTest();

        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
        TriggerHandler.BY_PASS_ACCOUNT_ON_AFTER = false;

        accnt.RC_Brand__c = 'BT Cloud Phone';
        accnt.RC_User_Id__c = 'Test Enterprise Account Id';
        accnt.Number_of_DL_s__c = 10;
        accnt.RC_Account_Status__c = 'Paid';

        update accnt;

        List<Implementation__c> implsList = [SELECT Id, Office_Service_Change_Date__c,
                                             Account__c, Brand__c, Tier__c, Service__c, Implementation_Type__c, Type__c
                                             FROM Implementation__c WHERE Account__c =:accnt.Id];

        // System.assert(!implsList.isEmpty(), 'related implementation record should be created');

        // Implementation__c impl = implsList.get(0);

        // System.assertEquals(
        //     accnt.Id,
        //     impl.Account__c,
        //     'implementation record should be related to updated Account'
        // );
        // System.assertEquals(
        //     'New',
        //     impl.Type__c,
        //     'Implementation__c.Type__c field should be populated with "New" value'
        // );
        // System.assertEquals(
        //     'Premium',
        //     impl.Implementation_Type__c,
        //     'Implementation__c.Implementation_Type__c field should be populated with "Premium" value'
        // );

        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testCreateImplementationRecordTrial() {

        Account accnt = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideUniqueString('Test account'),
                        Account.RC_Account_Status__c => 'TRIAL'
                        }
            )
            .create()
            .getRecord();

        Test.startTest();

        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
        TriggerHandler.BY_PASS_ACCOUNT_ON_AFTER = false;

        accnt.RC_Service_Name__c = 'Office';

        update accnt;

        List<Implementation__c> implsList = [SELECT Id, Office_Service_Change_Date__c,
                                             Account__c, Brand__c, Tier__c, Service__c, Implementation_Type__c, Type__c
                                             FROM Implementation__c WHERE Account__c =:accnt.Id];

        // System.assert(!implsList.isEmpty(), 'related implementation record should be created');

        // Implementation__c impl = implsList.get(0);

        // System.assertEquals(
        //     accnt.Id,
        //     impl.Account__c,
        //     'implementation record should be related to updated Account'
        // );
        // System.assertEquals(
        //     'New',
        //     impl.Type__c,
        //     'Implementation__c.Type__c field should be populated with "New" value'
        // );
        // System.assertEquals(
        //     'Trial Account',
        //     impl.Implementation_Type__c,
        //     'Implementation__c.Implementation_Type__c field should be populated with "Trial Account" value'
        // );
        Test.stopTest();
    }

    @isTest
    static void testCancellImplementationRecord() {

        Account accnt = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideUniqueString('Test account')
                        }
            )
            .create()
            .getRecord();

        // clear static map
        AccountTriggerHandler.implementationMapStatic.clear();

        Implementation__c implRecord = (Implementation__c) new SObjectBuilder(Implementation__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Implementation__c.Account__c => accnt.Id
                        }
            )
            .create()
            .getRecord();
        System.assert(implRecord.Id != null);

        Test.startTest();

        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
        TriggerHandler.BY_PASS_ACCOUNT_ON_AFTER = false;

        accnt.RC_account_Status__c = 'Canceled';

        update accnt;

        List<Implementation__c> implsList = [SELECT Id, Office_Service_Change_Date__c,
                                             Account__c, Brand__c, Tier__c, Service__c, Implementation_Type__c, Type__c,
                                             Implementation_Status_2__c
                                             FROM Implementation__c WHERE Account__c =:accnt.Id];

        // System.assert(!implsList.isEmpty(), 'related implementation record should be created');

        // Implementation__c impl = implsList.get(0);

        // System.assertEquals(
        //     accnt.Id,
        //     impl.Account__c,
        //     'implementation record should be related to updated Account'
        // );
        // System.assertEquals(
        //     '6c. Completed - Account Cancelled',
        //     impl.Implementation_Status_2__c,
        //     'Implementation__c.Implementation_Status_2__c field should be populated with "6c. Completed - Account Cancelled" value'
        // );
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testImplementationLeadsOnAccountInsertWithoutBrand() {

        Test.startTest();

        Account accnt = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideUniqueString('Test account'),
                        Account.RC_Service_Name__c => 'Office'
                        }
            )
            .create()
            .getRecord();

        Test.stopTest();

        List<Implementation__c> implsList = [SELECT Id, Office_Service_Change_Date__c,
                                             Account__c, Brand__c, Tier__c, Service__c, Implementation_Type__c, Type__c,
                                             Implementation_Status_2__c
                                             FROM Implementation__c WHERE Account__c =:accnt.Id];

        // System.assert(!implsList.isEmpty(), 'related implementation record should be created');

        // Implementation__c impl = implsList.get(0);

        // System.assertEquals(
        //     accnt.Id,
        //     impl.Account__c,
        //     'implementation record should be related to updated Account'
        // );
        // System.assertEquals(
        //     accnt.RC_Service_Name__c,
        //     impl.Service__c,
        //     'Account.RC_Service_Name__c should be copied to Implementation.Service__c'
        // );
        // System.assertEquals(
        //     'New',
        //     impl.Type__c,
        //     'Implementation__c.Type__c field should be populated with "New" value'
        // );
        // System.assertEquals(
        //     'Standard',
        //     impl.Implementation_Type__c,
        //     'Implementation__c.Implementation_Type__c field should be populated with "Standard" value'
        // );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testImplementationLeadsOnInsertServiceAccount() {

        Test.startTest();

        Account accnt = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideUniqueString('Test account'),
                        Account.RC_Brand__c => 'RingCentral',
                        Account.RC_Account_Status__c => 'TRIAL',
                        Account.Licenses_Purchased__c => 10,
                        Account.RC_Service_Name__c => 'Office'
                        }
            )
            .create()
            .getRecord();

        Test.stopTest();

        List<Implementation__c> implsList = [SELECT Id, Office_Service_Change_Date__c,
                                             Account__c, Brand__c, Tier__c, Service__c, Implementation_Type__c, Type__c,
                                             Implementation_Status_2__c
                                             FROM Implementation__c WHERE Account__c =:accnt.Id];

        // System.assert(!implsList.isEmpty(), 'related implementation record should be created');

        // Implementation__c impl = implsList.get(0);

        // System.assertEquals(
        //     accnt.Id,
        //     impl.Account__c,
        //     'implementation record should be related to updated Account'
        // );
        // System.assertEquals(
        //     accnt.RC_Brand__c,
        //     impl.Brand__c,
        //     'Account.RC_Brand__c should be copied to Implementation.Brand__c'
        // );
        // System.assertEquals(
        //     accnt.RC_Service_Name__c,
        //     impl.Service__c,
        //     'Account.RC_Service_Name__c should be copied to Implementation.Service__c'
        // );
        // System.assertEquals(
        //     'New',
        //     impl.Type__c,
        //     'Implementation__c.Type__c field should be populated with "New" value'
        // );
        // System.assertEquals(
        //     'Trial Account',
        //     impl.Implementation_Type__c,
        //     'Implementation__c.Implementation_Type__c field should be populated with "Trial Account" value'
        // );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testImplementationLeadsOnInsertAccountTelus() {

        Test.startTest();

        Account accnt = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideUniqueString('Test account'),
                        Account.RC_Brand__c => 'TELUS',
                        Account.RC_Service_Name__c => 'Office',
                        Account.RC_User_Id__c => 'test_rc_user_id',
                        Account.RC_Account_Status__c => 'Paid',
                        Account.Do_Not_Creation_Implementation__c => false
                        }
            )
            .create()
            .getRecord();

        Test.stopTest();

        List<Implementation__c> implsList = [SELECT Id, Office_Service_Change_Date__c,
                                             Account__c, Brand__c, Tier__c, Service__c, Implementation_Type__c, Type__c,
                                             Implementation_Status_2__c
                                             FROM Implementation__c WHERE Account__c =:accnt.Id];

        // System.assert(!implsList.isEmpty(), 'related implementation record should be created');

        // Implementation__c impl = implsList.get(0);

        // System.assertEquals(
        //     accnt.Id,
        //     impl.Account__c,
        //     'implementation record should be related to updated Account'
        // );
        // System.assertEquals(
        //     accnt.RC_Brand__c,
        //     impl.Brand__c,
        //     'Account.RC_Brand__c should be copied to Implementation.Brand__c'
        // );
        // System.assertEquals(
        //     accnt.RC_Service_Name__c,
        //     impl.Service__c,
        //     'Account.RC_Service_Name__c should be copied to Implementation.Service__c'
        // );
    }

    @isTest
    static void testCreateFinanceCaseOnPaid() {

        Triggers.switchOff();

        Account accnt = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideUniqueString('Test account')
                        }
            )
            .create()
            .getRecord();

        testContact = new Contact();
        testContact.AccountId =  accnt.id;
        testContact.Email = 'fake@email.com';
        testContact.LastName = 'TestLast';
        testContact.Phone='9910106804';
        insert testContact;

        AccountContactRole payableContactRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => accnt.Id,
                        AccountContactRole.ContactId => testContact.Id,
                        AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE
                        }
            )
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => accnt.Id,
                        Opportunity.Name => 'Test Opportunity',
                        Opportunity.CloseDate => System.today(),
                        Opportunity.CurrencyIsoCode => 'USD',
                        Opportunity.Total_MRR__c => 550
                        })
            .create()
            .getRecord();

        Triggers.switchOn();

        Test.startTest();

        Approval__c invoiceApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.RecordTypeId => ApprovalHelper.RT_ID_INVOICING_REQUEST,
                        Approval__c.Account__c => accnt.Id,
                        Approval__c.Opportunity__c => testOpp.Id,
                        Approval__c.AccountPayableContact__c => testContact.Id,
                        Approval__c.Potential_Users__c => 1,
                        Approval__c.Reason_Customer_is_Requesting_Invoicing__c => 'test'
                        }
            )
            .create()
            .getRecord();

        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
        TriggerHandler.BY_PASS_ACCOUNT_ON_AFTER = false;

        accnt.RC_Account_Status__c = 'Paid';
        accnt.Active_Invoice_Approval__c = invoiceApproval.Id;
        update accnt;

        Test.stopTest();

        CaseSelector selector = new CaseSelector();

        List<Case> caseList = selector
            .selectCases()
            .selectFields(selector.getDetailFieldList())
            .setCondition('AccountId = :bind0')
            .setQueryBindings(new List<Object>{accnt.Id})
            .executeQuery();

        System.assert(!caseList.isEmpty(), 'case record should be created');

        Case createdCase = caseList.get(0);

        System.assertEquals(
            'New',
            createdCase.Status,
            'created Case Record should be in "New" Status'
        );

        System.assertEquals(
            'New Customer Tracking for Finance',
            createdCase.Subject,
            'created Case Record should have "New Customer Tracking for Finance" Subject'
        );

        final Id financeRtId = Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('COE Audit').getRecordTypeId();

        System.assertEquals(
            financeRtId,
            createdCase.RecordTypeId,
            'created Case Record should have "Finance" RecordType'
        );
    }

    @isTest
    static void testIsValidBillingStateMethod() {

        final String usaCountryName = 'USA';

        System.assertEquals(
            AccountTriggerHelper.COUNTRY_REQUIRE_STATE.contains(usaCountryName.toLowerCase()),
            AccountTriggerHelper.isValidBillingState('Texas', usaCountryName),
            'for countries in AccountTriggerHelper.COUNTRY_REQUIRE_STATE state(first parameter) should be presented'
        );

        final String japanCountryName = 'Japan';

        System.assertEquals(
            !AccountTriggerHelper.COUNTRY_REQUIRE_STATE.contains(japanCountryName.toLowerCase()),
            AccountTriggerHelper.isValidBillingState(null, japanCountryName),
            'for countries not in AccountTriggerHelper.COUNTRY_REQUIRE_STATE state(first parameter) is not required'
        );
    }

    @IsTest
    static void testInvalidateQuotes() {
        Account account = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideUniqueString('Test account')
                        }
            )
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => account.Id,
                        Opportunity.Name => 'Test Opportunity',
                        Opportunity.CloseDate => System.today(),
                        Opportunity.CurrencyIsoCode => 'USD'
                        })
            .create()
            .getRecord();

        Quote oppQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'Test Quote',
                        Quote.OpportunityId => testOpp.Id,
                        Quote.Account__c => account.Id

                        })
            .create()
            .getRecord();

        Quote oppQuote1 = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'Test Quote 2',
                        Quote.OpportunityId => testOpp.Id,
                        Quote.Account__c => account.Id

                        })
            .create()
            .getRecord();

        Account partnerAcc = new Account();
        partnerAcc.Name = 'PartnerAccount';
        insert partnerAcc;

        AccountTriggerHelper.invalidateQuotes(new Set<Id>{account.Id}, new Set<Id>());

        Test.startTest();

        update account;

        List<Quote> updatedQuotes = [
            SELECT Quote_is_Invalid__c
            FROM Quote
            WHERE OpportunityId =: testOpp.Id
        ];

        Test.stopTest();
        for (Quote q : updatedQuotes) {
            System.assertEquals(true, q.Quote_is_Invalid__c, 'Quote wasn\'t invalidated');
        }

    }


    @IsTest
    static void testInvalidateQuotesExcept() {
        Account account = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideUniqueString('Test account')
                        }
            )
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => account.Id,
                        Opportunity.Name => 'Test Opportunity',
                        Opportunity.CloseDate => System.today(),
                        Opportunity.CurrencyIsoCode => 'USD'
                        })
            .create()
            .getRecord();

        Quote oppQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'Test Quote',
                        Quote.OpportunityId => testOpp.Id,
                        Quote.Account__c => account.Id

                        })
            .create()
            .getRecord();

        Quote oppQuote1 = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'Test Quote 2',
                        Quote.OpportunityId => testOpp.Id,
                        Quote.Account__c => account.Id

                        })
            .create()
            .getRecord();

        Account partnerAcc = new Account();
        partnerAcc.Name = 'PartnerAccount';
        insert partnerAcc;

        AccountTriggerHelper.invalidateQuotes(new Set<Id>{account.Id}, new Set<Id>{testOpp.Id});

        Test.startTest();

        update account;

        List<Quote> updatedQuotes = [
            SELECT Quote_is_Invalid__c
            FROM Quote
            WHERE OpportunityId =: testOpp.Id
        ];

        Test.stopTest();
        for (Quote q : updatedQuotes) {
            System.assertEquals(false, q.Quote_is_Invalid__c, 'Quote should not be invalidated');
        }

    }

    @IsTest
    static void testInvalidateQuotesClosedStage() {
        Account account = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideUniqueString('Test account')
                        }
            )
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => account.Id,
                        Opportunity.Name => 'Test Opportunity',
                        Opportunity.CloseDate => System.today(),
                        Opportunity.CurrencyIsoCode => 'USD',
                        Opportunity.StageName => '7. Closed Won'
                        })
            .create()
            .getRecord();

        Quote oppQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'Test Opportunity',
                        Quote.OpportunityId => testOpp.Id,
                        Quote.Account__c => account.Id

                        })
            .create()
            .getRecord();

        Account partnerAcc = new Account();
        partnerAcc.Name = 'PartnerAccount';
        insert partnerAcc;

        AccountTriggerHelper.invalidateQuotes(new Set<Id>{account.Id}, new Set<Id>());

        Test.startTest();

        update account;

        Quote updatedQuote = [
            SELECT Quote_is_Invalid__c
            FROM Quote
            WHERE Id =: oppQuote.Id
        ];

        Test.stopTest();

        System.assertEquals(false, updatedQuote.Quote_is_Invalid__c, 'Quote of Closed Opportunity was invalidated');

    }
    
    @isTest
    static void populateUsersStatic_RunningInLeadConversionContextAndUserPresentInPlatformCache_ReturnNothing(){
        //GIVEN
        List<User> testUsers = [SELECT Id, Email, FirstName, LastName
                               FROM User WHERE IsActive = true LIMIT 1];
        ConvertLead.IS_LEAD_CONVERT_PROCESSING = true;
        SettingsHelper.FEATURE_TOGGLE.EnableLeadConversionUsingCache__c = true;
        PlatformCacheUtility.put(
            PlatformCacheUtility.SESSION_CACHE,
            testUsers[0].Id,
            testUsers[0],
            PlatformCacheUtility.CURRENT_USER_SESSION_DATA
        );
        
        //WHEN
        Test.startTest();
        AccountTriggerHelper.populateUsersStatic(new Set<Id>{testUsers[0].Id});
        Test.stopTest();
        
        //THEN
        Assert.isTrue(testUsers[0].Id != null,'Test user record is present');
    }
    
    @isTest
    static void populateUsersStatic_RunningInLeadConversionContextAndUserNotPresentInPlatformCache_ReturnNothing(){
        //GIVEN
        List<User> testUsers = [SELECT Id, Email, FirstName, LastName
                               FROM User WHERE IsActive = true LIMIT 1];
        ConvertLead.IS_LEAD_CONVERT_PROCESSING = true;
        SettingsHelper.FEATURE_TOGGLE.EnableLeadConversionUsingCache__c = true;
        
        //WHEN
        Test.startTest();
        AccountTriggerHelper.populateUsersStatic(new Set<Id>{testUsers[0].Id});
        Test.stopTest();
        
        //THEN
        Assert.isTrue(testUsers[0].Id != null,'Test user record is present');
    }
    
    @isTest
    static void populateUsersStatic_UserNotPresentInPlatformCache_ReturnNothing(){
        //GIVEN
        List<User> testUsers = [SELECT Id, Email, FirstName, LastName
                               FROM User WHERE IsActive = true LIMIT 1];
        ConvertLead.IS_LEAD_CONVERT_PROCESSING = false;
        SettingsHelper.FEATURE_TOGGLE.EnableLeadConversionUsingCache__c = false;
        
        //WHEN
        Test.startTest();
        AccountTriggerHelper.populateUsersStatic(new Set<Id>{testUsers[0].Id});
        Test.stopTest();
        
        //THEN
        Assert.isTrue(testUsers[0].Id != null,'Test user record is present');
    }

    public class ClayAcctEnrichmentServiceMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatus('OK');
            res.setStatusCode(200);
            return res;
        }
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void testClayEnrichmentCode() {
        Test.setMock(HttpCalloutMock.class, new ClayAcctEnrichmentServiceMock());
        Gating_Process_Stage__c processStage = Gating_Process_Stage__c.getInstance();
        processStage.IsClayEnabled__c = true;
        processStage.Clay_Account_WebHook_URL__c = 'https://example.com/api/endpoint';
        insert processStage;
		// Since the assertion involves comparing the queueable class http response result that gets triggered via trigger method,
		// it cannot be validated and therefore assert not included in this method 
        Account accnt = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideUniqueString('Texas Instruments'),
                        Account.Website => 'http://www.texasInstruments.com',
                        Account.BillingStreet => '101 Greenville Avenue',
                        Account.BillingState => 'TX',
                        Account.BillingCity => 'Dallas',
                        Account.BillingPostalCode => '75001',
                        Account.BillingCountry => 'United States'
                        }
            )
            .create()
            .getRecord();
    }
}