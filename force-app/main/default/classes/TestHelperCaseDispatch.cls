/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 */
@isTest
private class TestHelperCaseDispatch {

    static void insertCS(String tier, String operator, Boolean vip)
    {
        insert new Case_Dispatch__c (
            Name = 'CS1', Product_Assistance__c = 'Company Settings', Brand__c = 'RingCentral',
            Total_Account_DL_s__c = 20, Queue__c = 'General Support Queue', VIP_Queue__c = 'General Support Queue',
            Tier__c = tier, Operator__c = operator, VIP__c = vip);

        insert new Case_Dispatch__c (
            Name = 'Manila Contact Center Queue', Queue__c = 'Manila Contact Center Queue', VIP_Queue__c = 'General Support Queue');


        /*List<Case_Dispatch__c> settingList = new List<Case_Dispatch__c>();
        settingList.add(new Case_Dispatch__c(Name='CS1',Product_Assistance__c='Company Settings',Tier__c='Fax,Pro',Operator__c='<=',Total_Account_DL_s__c=20,Queue__c='General Support Queue', VIP_Queue__c='General Support Queue', VIP__c = true));
        settingList.add(new Case_Dispatch__c(Name='CS2',Product_Assistance__c='Company Settings',Tier__c='Office',Operator__c='<=',Total_Account_DL_s__c=20,Queue__c='General Support Queue', VIP_Queue__c='General Support Queue', VIP__c = false));
        settingList.add(new Case_Dispatch__c(Name='CS3',Product_Assistance__c='Company Settings',Tier__c='Office',Operator__c='<',Total_Account_DL_s__c=20,Queue__c='General Support Queue', VIP_Queue__c='General Support Queue', VIP__c = true));
        settingList.add(new Case_Dispatch__c(Name='CS4',Product_Assistance__c='Company Settings',Tier__c='Office',Operator__c='==',Total_Account_DL_s__c=20,Queue__c='General Support Queue', VIP_Queue__c='General Support Queue', VIP__c = false));
        settingList.add(new Case_Dispatch__c(Name='CS5',Product_Assistance__c='Company Settings',Tier__c='Office',Operator__c='!=',Total_Account_DL_s__c=20,Queue__c='General Support Queue', VIP_Queue__c='General Support Queue', VIP__c = true));
        settingList.add(new Case_Dispatch__c(Name='CS6',Product_Assistance__c='Company Settings',Tier__c='Office',Operator__c='>',Total_Account_DL_s__c=20,Queue__c='General Support Queue', VIP_Queue__c='General Support Queue', VIP__c = true));

        settingList.add(new Case_Dispatch__c(Name='CS7',Product_Assistance__c='Company Settings',Tier__c='Office',Operator__c='>=',Total_Account_DL_s__c=20,Queue__c='General Support Queue', VIP_Queue__c='General Support Queue', VIP__c = true));
        insert settingList;
        */

    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void myUnitTest() {
        Group mnlQ = new Group(Name='Manila Contact Center Queue', DeveloperName='Manila_Contact_Center_Queue');
        insert mnlQ;

        Group evQ = new Group(Name='RC Engage Voice Support', DeveloperName='RC_Engage_Voice_Support');
        insert evQ;

        Group gdprQ = new Group(Name='GDPR_Request', DeveloperName='GDPR_Request');
        insert gdprQ;

        // TO DO: implement unit test
        Test.startTest();
        insertCS('Fax,Pro', '<=', true);
        Account acctest = new Account();
        acctest.Name = 'TestAccount';
        acctest.Number_of_DL_s__c = 21;
        acctest.RC_Tier__c = 'Fax';
        acctest.RC_Brand__c = 'RingCentral';

        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        insert acctest;
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
        accTest = ReReadAccountFromDb(accTest.Id);

        Contact contObj = new Contact();
        contObj.AccountId =  acctest.Id;
        contObj.Email = 'abc2@test.com';
        contObj.LastName = 'Test Last2';
        contObj.FirstName = 'Test First2';
        TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
        insert contObj;
        TriggerHandler.BY_PASS_CONTACT_ON_INSERT = false;
        Case caseObj = new Case();
        caseObj.Account = acctest;
        caseObj.Product_Assistance__c = 'Company Settings';
        caseObj.Subject = 'Test Case';
        caseObj.Description = 'Test Case Desc';
        insert caseObj;

        ID ProfileID = [Select id from Profile where name = 'Customer Portal User'].id;
        User loginUser = new User( email='test-user@fakeemail.com', contactid = contObj.id, profileid = profileid,
                UserName='test-user@fakeemail.com', alias='tuser1', CommunityNickName='tuser1',
        TimeZoneSidKey='America/New_York', LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',
        LanguageLocaleKey='en_US', FirstName = 'Test', LastName = 'User' );
        insert loginUser;
        HelperCaseDispatch.assignQueue(caseObj, loginUser);
        Test.stopTest();

    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void myUnitTest1() {
        Group mnlQ = new Group(Name='Manila Contact Center Queue', DeveloperName='Manila_Contact_Center_Queue');
        insert mnlQ;

        Group evQ = new Group(Name='RC Engage Voice Support', DeveloperName='RC_Engage_Voice_Support');
        insert evQ;

        Group gdprQ = new Group(Name='GDPR_Request', DeveloperName='GDPR_Request');
        insert gdprQ;

        // TO DO: implement unit test
        Test.startTest();
        insertCS('Office', '<=', false);
        Account acctest = new Account();
        acctest.Name = 'TestAccount';
        acctest.Number_of_DL_s__c = 20;
        acctest.RC_Tier__c = 'office';
        acctest.RC_Brand__c = 'RingCentral';

        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        insert acctest;
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
        accTest = ReReadAccountFromDb(accTest.Id);

        Contact contObj = new Contact();
        contObj.AccountId =  acctest.Id;
        contObj.Email = 'abc2@test.com';
        contObj.LastName = 'Test Last2';
        contObj.FirstName = 'Test First2';

        TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
        insert contObj;
        TriggerHandler.BY_PASS_CONTACT_ON_INSERT = false;

        Case caseObj = new Case();
        caseObj.Account = acctest;
        caseObj.Product_Assistance__c = 'Company Settings';
        caseObj.Subject = 'Test Case';
        caseObj.Description = 'Test Case Desc';
        insert caseObj;

        ID ProfileID = [ Select id from Profile where name = 'Customer Portal User'].id;
        User loginUser = new User( email='test-user@fakeemail.com', contactid = contObj.id, profileid = profileid,
                UserName='test-user@fakeemail.com', alias='tuser1', CommunityNickName='tuser1',
        TimeZoneSidKey='America/New_York', LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',
        LanguageLocaleKey='en_US', FirstName = 'Test', LastName = 'User' );
        insert loginUser;

        HelperCaseDispatch.assignQueue(caseObj, loginUser);
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void myUnitTest2() {
        Group mnlQ = new Group(Name='Manila Contact Center Queue', DeveloperName='Manila_Contact_Center_Queue');
        insert mnlQ;

        Group evQ = new Group(Name='RC Engage Voice Support', DeveloperName='RC_Engage_Voice_Support');
        insert evQ;

        Group gdprQ = new Group(Name='GDPR_Request', DeveloperName='GDPR_Request');
        insert gdprQ;

        // TO DO: implement unit test
        Test.startTest();
        insertCS('Office', '<', true);
        Account acctest = new Account();
        acctest.Name = 'TestAccount';
        acctest.Number_of_DL_s__c = 19;
        acctest.RC_Tier__c = 'office';
        acctest.RC_Brand__c = 'RingCentral';

        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        insert acctest;
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
        accTest = ReReadAccountFromDb(accTest.Id);

        Contact contObj = new Contact();
        contObj.AccountId =  acctest.Id;
        contObj.Email = 'abc2@test.com';
        contObj.LastName = 'Test Last2';
        contObj.FirstName = 'Test First2';

        TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
        insert contObj;
        TriggerHandler.BY_PASS_CONTACT_ON_INSERT = false;

        Case caseObj = new Case();
        caseObj.Account = acctest;
        caseObj.Product_Assistance__c = 'Company Settings';
        caseObj.Subject = 'Test Case';
        caseObj.Description = 'Test Case Desc';

        insert caseObj;
        ID ProfileID = [ Select id from Profile where name = 'Customer Portal User'].id;
        User loginUser = new User( email='test-user@fakeemail.com', contactid = contObj.id, profileid = profileid,
                UserName='test-user@fakeemail.com', alias='tuser1', CommunityNickName='tuser1',
        TimeZoneSidKey='America/New_York', LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',
        LanguageLocaleKey='en_US', FirstName = 'Test', LastName = 'User' );

        insert loginUser;
        HelperCaseDispatch.assignQueue(caseObj, loginUser);
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void myUnitTest3() {
        Group mnlQ = new Group(Name='Manila Contact Center Queue', DeveloperName='Manila_Contact_Center_Queue');
        insert mnlQ;

        Group evQ = new Group(Name='RC Engage Voice Support', DeveloperName='RC_Engage_Voice_Support');
        insert evQ;

        Group gdprQ = new Group(Name='GDPR_Request', DeveloperName='GDPR_Request');
        insert gdprQ;

        // TO DO: implement unit test
        Test.startTest();
        insertCS('Office', '==', false);
        Account acctest = new Account();
        acctest.Name = 'TestAccount';
        acctest.Number_of_DL_s__c = 20;
        acctest.RC_Tier__c = 'office';
        acctest.RC_Brand__c = 'RingCentral';

        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        insert acctest;
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
        accTest = ReReadAccountFromDb(accTest.Id);

        Contact contObj = new Contact();
        contObj.AccountId =  acctest.Id;
        contObj.Email = 'abc2@test.com';
        contObj.LastName = 'Test Last2';
        contObj.FirstName = 'Test First2';

        TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
        insert contObj;
        TriggerHandler.BY_PASS_CONTACT_ON_INSERT = false;

        Case caseObj = new Case();
        caseObj.Account = acctest;
        caseObj.Product_Assistance__c = 'Company Settings';
        caseObj.Subject = 'Test Case';
        caseObj.Description = 'Test Case Desc';
        insert caseObj;

        ID ProfileID = [Select id from Profile where name = 'Customer Portal User'].id;
        User loginUser = new User( email='test-user@fakeemail.com', contactid = contObj.id, profileid = profileid,
                UserName='test-user@fakeemail.com', alias='tuser1', CommunityNickName='tuser1',
        TimeZoneSidKey='America/New_York', LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',
        LanguageLocaleKey='en_US', FirstName = 'Test', LastName = 'User' );
        insert loginUser;

        HelperCaseDispatch.assignQueue(caseObj, loginUser);
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void myUnitTest4() {
        Group mnlQ = new Group(Name='Manila Contact Center Queue', DeveloperName='Manila_Contact_Center_Queue');
        insert mnlQ;

        Group evQ = new Group(Name='RC Engage Voice Support', DeveloperName='RC_Engage_Voice_Support');
        insert evQ;

        Group gdprQ = new Group(Name='GDPR_Request', DeveloperName='GDPR_Request');
        insert gdprQ;

        // TO DO: implement unit test
        Test.startTest();
        insertCS('Office', '!=', true);
        Account acctest = new Account();
        acctest.Name = 'TestAccount';
        acctest.RC_Tier__c = 'Office';
        acctest.RC_Brand__c = 'RingCentral';

        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        insert acctest;
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
        accTest = ReReadAccountFromDb(accTest.Id);

        Contact contObj = new Contact();
        contObj.AccountId =  acctest.Id;
        contObj.Email = 'abc2@test.com';
        contObj.LastName = 'Test Last2';
        contObj.FirstName = 'Test First2';
        TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
        insert contObj;

        TriggerHandler.BY_PASS_CONTACT_ON_INSERT = false;
        Case caseObj = new Case();
        caseObj.Account = acctest;
        caseObj.Product_Assistance__c = 'Company Settings';
        caseObj.Subject = 'Test Case';
        caseObj.Description = 'Test Case Desc';
        insert caseObj;

        ID ProfileID = [ Select id from Profile where name = 'Customer Portal User'].id;
        User loginUser = new User( email='test-user@fakeemail.com', contactid = contObj.id, profileid = profileid,
                UserName='test-user@fakeemail.com', alias='tuser1', CommunityNickName='tuser1',
        TimeZoneSidKey='America/New_York', LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',
        LanguageLocaleKey='en_US', FirstName = 'Test', LastName = 'User' );
        insert loginUser;

        HelperCaseDispatch.assignQueue(caseObj, loginUser);
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void myUnitTest5() {
        Group mnlQ = new Group(Name='Manila Contact Center Queue', DeveloperName='Manila_Contact_Center_Queue');
        insert mnlQ;

        Group evQ = new Group(Name='RC Engage Voice Support', DeveloperName='RC_Engage_Voice_Support');
        insert evQ;

        Group gdprQ = new Group(Name='GDPR_Request', DeveloperName='GDPR_Request');
        insert gdprQ;

        // TO DO: implement unit test
        Test.startTest();
        insertCS('Office', '>', true);
        Account acctest = new Account();
        acctest.Name = 'TestAccount';
        acctest.Number_of_DL_s__c = 22;
        acctest.RC_Tier__c = 'Office';
        acctest.RC_Brand__c = 'RingCentral';

        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        insert acctest;
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
        accTest = ReReadAccountFromDb(accTest.Id);

        Contact contObj = new Contact();
        contObj.AccountId =  acctest.Id;
        contObj.Email = 'abc2@test.com';
        contObj.LastName = 'Test Last2';
        contObj.FirstName = 'Test First2';
        TriggerHandler.BY_PASS_CONTACT_ON_INSERT();

        insert contObj;
        TriggerHandler.BY_PASS_CONTACT_ON_INSERT = false;
        Case caseObj = new Case();
        caseObj.Account = acctest;
        caseObj.Product_Assistance__c = 'Company Settings';
        caseObj.Subject = 'Test Case';
        caseObj.Description = 'Test Case Desc';

        insert caseObj;
        ID ProfileID = [ Select id from Profile where name = 'Customer Portal User'].id;
        User loginUser = new User( email='test-user@fakeemail.com', contactid = contObj.id, profileid = profileid,
                UserName='test-user@fakeemail.com', alias='tuser1', CommunityNickName='tuser1',
        TimeZoneSidKey='America/New_York', LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',
        LanguageLocaleKey='en_US', FirstName = 'Test', LastName = 'User' );

        insert loginUser;
        HelperCaseDispatch.assignQueue(caseObj, loginUser);
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void myUnitTest6() {
        Group mnlQ = new Group(Name='Manila Contact Center Queue', DeveloperName='Manila_Contact_Center_Queue');
        insert mnlQ;

        Group evQ = new Group(Name='RC Engage Voice Support', DeveloperName='RC_Engage_Voice_Support');
        insert evQ;

        Group gdprQ = new Group(Name='GDPR_Request', DeveloperName='GDPR_Request');
        insert gdprQ;

        // TO DO: implement unit test
        Test.startTest();
        insertCS('Office', '>=', true);
        Account acctest = new Account();
        acctest.Name = 'TestAccount';
        acctest.Number_of_DL_s__c = 21;
        acctest.RC_Tier__c = 'Office';
        acctest.RC_Brand__c = 'RingCentral';

        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        insert acctest;
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
        accTest = ReReadAccountFromDb(accTest.Id);

        Contact contObj = new Contact();
        contObj.AccountId =  acctest.Id;
        contObj.Email = 'abc2@test.com';
        contObj.LastName = 'Test Last2';
        contObj.FirstName = 'Test First2';
        TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
        insert contObj;
        TriggerHandler.BY_PASS_CONTACT_ON_INSERT = false;

        Case caseObj = new Case();
        caseObj.Account = acctest;
        caseObj.Product_Assistance__c = 'Company Settings';
        caseObj.Subject = 'Test Case';
        caseObj.Description = 'Test Case Desc';
        insert caseObj;

        ID ProfileID = [ Select id from Profile where name = 'Customer Portal User'].id;
        User loginUser = new User( email='test-user@fakeemail.com', contactid = contObj.id, profileid = profileid,
                UserName='test-user@fakeemail.com', alias='tuser1', CommunityNickName='tuser1',
        TimeZoneSidKey='America/New_York', LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',
        LanguageLocaleKey='en_US', FirstName = 'Test', LastName = 'User' );
        insert loginUser;

        caseObj.OwnerId = userInfo.getUserId();
        update caseObj;

        HelperCaseDispatch.assignQueue(caseObj, loginUser);
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void myUnitTest7() {
        Group mnlQ = new Group(Name='Manila Contact Center Queue', DeveloperName='Manila_Contact_Center_Queue');
        insert mnlQ;

        Group evQ = new Group(Name='RC Engage Voice Support', DeveloperName='RC_Engage_Voice_Support');
        insert evQ;

        Group gdprQ = new Group(Name='GDPR_Request', DeveloperName='GDPR_Request');
        insert gdprQ;

        // TO DO: implement unit test
        Test.startTest();
        insertCS('Fax,Pro', '>=', true);
        Account acctest = new Account();
        acctest.Name = 'TestAccount';
        acctest.Number_of_DL_s__c = 21;
        acctest.RC_Tier__c = 'fax';
        acctest.RC_Brand__c = 'RingCentral';
        acctest.VIP_Account_Indicator__c = 'Sales';

        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        insert acctest;
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
        accTest = ReReadAccountFromDb(accTest.Id);

        Contact contObj = new Contact();
        contObj.AccountId =  acctest.Id;
        contObj.Email = 'abc2@test.com';
        contObj.LastName = 'Test Last2';
        contObj.FirstName = 'Test First2';

        TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
        insert contObj;
        TriggerHandler.BY_PASS_CONTACT_ON_INSERT = false;

        Case caseObj = new Case();
        caseObj.Account = acctest;
        caseObj.Product_Assistance__c = 'Company Settings';
        caseObj.Subject = 'Test Case';
        caseObj.Description = 'Test Case Desc';
        insert caseObj;

        ID ProfileID = [ Select id from Profile where name = 'Customer Portal User'].id;
        User loginUser = new User( email='test-user@fakeemail.com', contactid = contObj.id, profileid = profileid,
                UserName='test-user@fakeemail.com', alias='tuser1', CommunityNickName='tuser1',
        TimeZoneSidKey='America/New_York', LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',
        LanguageLocaleKey='en_US', FirstName = 'Test', LastName = 'User' );
        insert loginUser;

        caseObj.OwnerId = userInfo.getUserId();
        update caseObj;

        HelperCaseDispatch.assignQueue(caseObj, loginUser);
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void TestGdprSpecialCasePositive(){
        Group mnlQ = new Group(Name='Manila Contact Center Queue', DeveloperName='Manila_Contact_Center_Queue');
        insert mnlQ;

        Group evQ = new Group(Name='RC Engage Voice Support', DeveloperName='RC_Engage_Voice_Support');
        insert evQ;

        Group gdprQ = new Group(Name='GDPR_Request', DeveloperName='GDPR_Request');
        insert gdprQ;

        Account acctest = new Account();
        acctest.Name = 'TestAccount';
        acctest.Number_of_DL_s__c = 21;
        acctest.RC_Tier__c = 'Office';
        acctest.RC_Brand__c = 'RingCentral';
        acctest.VIP_Account_Indicator__c = 'Sales';

        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        insert acctest;
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
        accTest = ReReadAccountFromDb(accTest.Id);

        Contact contObj = new Contact();
        contObj.AccountId =  acctest.Id;
        contObj.Email = 'abc2@test.com';
        contObj.LastName = 'Test Last2';
        contObj.FirstName = 'Test First2';

        TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
        insert contObj;
        TriggerHandler.BY_PASS_CONTACT_ON_INSERT = false;

        ID profileId = [ Select id from Profile where name = 'Customer Portal User'].id;
        User loginUser = new User( email='test-user@fakeemail.com', contactid = contObj.id, ProfileId = profileId,
            UserName='test-user@fakeemail.com', alias='tuser1', CommunityNickName='tuser1',
            TimeZoneSidKey='America/New_York', LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',
            LanguageLocaleKey='en_US', FirstName = 'Test', LastName = 'User' );
        insert loginUser;

        Group[] gdprGroup =
        [
            SELECT Id
            FROM Group
            WHERE Name = :HelperCaseDispatch.GDPR_QUEUE_NAME
        ];

        if (gdprGroup.size() == 0)
        {
            System.Debug('TestHelperCaseDispatch.TestGdprSpecialCasePositive >> GDPR queue was not found. Its not an error');
            return;
        }

        Case caseObj = new Case();
        caseObj.Account = acctest;
        caseObj.Product_Assistance__c = HelperCaseDispatch.PRODUCT_ASSISTANCE_GDPR;
        caseObj.Subject = 'Test Case';
        caseObj.Description = 'Test Case Desc';
        insert caseObj;

        Test.StartTest();
        caseObj = HelperCaseDispatch.assignQueue(caseObj, loginUser);
        Test.StopTest();

        //System.Assert(caseObj.OwnerId == gdprGroup[0].Id, 'Case owner was not changed after dispatch: not equal to GDPR queue Id');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testManilaQueueAssigment() {
        Group mnlQ = new Group(Name='Manila Contact Center Queue', DeveloperName='Manila_Contact_Center_Queue');
        insert mnlQ;

        Group evQ = new Group(Name='RC Engage Voice Support', DeveloperName='RC_Engage_Voice_Support');
        insert evQ;

        Group gdprQ = new Group(Name='GDPR_Request', DeveloperName='GDPR_Request');
        insert gdprQ;

        Boolean manilaQueueFound = false;
        User us = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestTest',
                    User.Username => 'Test!user@gmail.com',
                    User.Email => 'Test_user@gmail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep'
                }
            )
            .create()
            .getRecord();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'Test account',
                    Account.Number_of_DL_s__c => 50,
                    Account.Service_Status__c => 'Pre-Sale'
                }
            )
            .create()
            .getRecord();


        Case c = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.Status => 'New',
                    Case.OwnerId => us.Id,
                    Case.RecordTypeId => CaseHelper.RT_ID_IT_HELPDESK
                }
            )
            .create()
            .getRecord();

        Case_Dispatch__c cd = new Case_Dispatch__c (
            Name = 'Manila Contact Center Queue',
            Product_Assistance__c = '',
            Brand__c = 'RingCentral',
            Total_Account_DL_s__c = 99,
            Queue__c = 'Manila Contact Center Queue',
            VIP_Queue__c = '',
            Service_Status__c = 'Pre-Sale, Contract Complete, Pre-Implementation, CC Internal Account, inContact Direct CC');
        insert cd;

        Id initialCaseOwnerId = c.OwnerId;

        List<Group> manilaQueue = [SELECT Id
                                    FROM Group
                                    WHERE Name =: HelperCaseDispatch.MANILA_QUEUE_NAME
                                    ];

        if(manilaQueue.size() != 0) {
            manilaQueueFound = true;
        }

        Test.startTest();
        Case updatedCase = HelperCaseDispatch.assignQueue(c, us);
        Test.stopTest();

        /*
        if(manilaQueueFound) {
            System.assertNotEquals(initialCaseOwnerId, updatedCase.OwnerId,
            'Case owner was not changed after dispatch: not equal to Manila Contact Center Queue queue Id');
        } else {
            System.assertEquals(initialCaseOwnerId, updatedCase.OwnerId,
            'Case owner should not change');
        }
        */

    }

    static Account ReReadAccountFromDb(Id accountId)
    {
        Account[] result =
        [
            SELECT RC_Tier__c, Total_Account_DL_s__c, RC_Brand__c, VIP_Account_Indicator__c, Number_of_DL_s__c, Service_Status__c, Extended_Enterprise_Support_Customer__c
            FROM Account
            WHERE Id = :accountId
        ];

        system.assert(result.size() == 1, 'Error in query to obtain test Account');
        return result[0];
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void myUnitTest8() {
        Group mnlQ = new Group(Name='Manila Contact Center Queue', DeveloperName='Manila_Contact_Center_Queue');
        insert mnlQ;

        Group evQ = new Group(Name='RC Engage Voice Support', DeveloperName='RC_Engage_Voice_Support');
        insert evQ;

        Group gdprQ = new Group(Name='GDPR_Request', DeveloperName='GDPR_Request');
        insert gdprQ;

        // TO DO: implement unit test
        Test.startTest();
        insertCS('Fax,Pro', '>=', true);
        Account acctest = new Account();
        acctest.Name = 'TestAccount';
        acctest.Number_of_DL_s__c = 21;
        acctest.RC_Tier__c = 'fax';
        acctest.RC_Brand__c = 'RingCentral';
        acctest.VIP_Account_Indicator__c = 'Sales';

        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        insert acctest;
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
        accTest = ReReadAccountFromDb(accTest.Id);

        Contact contObj = new Contact();
        contObj.AccountId =  acctest.Id;
        contObj.Email = 'abc2@test.com';
        contObj.LastName = 'Test Last2';
        contObj.FirstName = 'Test First2';

        TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
        insert contObj;
        TriggerHandler.BY_PASS_CONTACT_ON_INSERT = false;

        Case caseObj = new Case();
        caseObj.Product_Assistance__c = HelperCaseDispatch.PRODUCT_ASSISTANCE_GDPR;
        caseObj.Subject = 'Test Case';
        caseObj.Description = 'Test Case Desc';
        insert caseObj;

        ID ProfileID = [ Select id from Profile where name = 'Customer Portal User'].id;
        User loginUser = new User( email='test-user@fakeemail.com', contactid = contObj.id, profileid = profileid,
                UserName='test-user@fakeemail.com', alias='tuser1', CommunityNickName='tuser1',
        TimeZoneSidKey='America/New_York', LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',
        LanguageLocaleKey='en_US', FirstName = 'Test', LastName = 'User' );
        insert loginUser;

        caseObj.OwnerId = userInfo.getUserId();
        update caseObj;

        HelperCaseDispatch.assignQueue(caseObj, loginUser);

        HelperCaseDispatch hp = new HelperCaseDispatch();
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void myUnitTest9() {
        Group mnlQ = new Group(Name='Manila Contact Center Queue', DeveloperName='Manila_Contact_Center_Queue');
        insert mnlQ;

        Group evQ = new Group(Name='RC Engage Voice Support', DeveloperName='RC_Engage_Voice_Support');
        insert evQ;

        Group gdprQ = new Group(Name='GDPR_Request', DeveloperName='GDPR_Request');
        insert gdprQ;

        // TO DO: implement unit test
        Test.startTest();
        insertCS('Fax,Pro', '>=', true);
        Account acctest = new Account();
        acctest.Name = 'TestAccount';
        acctest.Number_of_DL_s__c = 21;
        acctest.RC_Tier__c = 'fax';
        acctest.RC_Brand__c = 'RingCentral';
        acctest.VIP_Account_Indicator__c = 'Sales';

        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        insert acctest;
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
        accTest = ReReadAccountFromDb(accTest.Id);

        Contact contObj = new Contact();
        contObj.AccountId =  acctest.Id;
        contObj.Email = 'abc2@test.com';
        contObj.LastName = 'Test Last2';
        contObj.FirstName = 'Test First2';

        TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
        insert contObj;
        TriggerHandler.BY_PASS_CONTACT_ON_INSERT = false;

        Case caseObj = new Case();
        caseObj.Product_Assistance__c = HelperCaseDispatch.ENGAGE_VOICE_PROD_ASSISTANCE;
        caseObj.Subject = 'Test Case';
        caseObj.Description = 'Test Case Desc';
        caseObj.Account = acctest;
        insert caseObj;

        ID ProfileID = [ Select id from Profile where name = 'Customer Portal User'].id;
        User loginUser = new User( email='test-user@fakeemail.com', contactid = contObj.id, profileid = profileid,
                UserName='test-user@fakeemail.com', alias='tuser1', CommunityNickName='tuser1',
        TimeZoneSidKey='America/New_York', LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',
        LanguageLocaleKey='en_US', FirstName = 'Test', LastName = 'User' );
        insert loginUser;

        caseObj.OwnerId = userInfo.getUserId();
        update caseObj;

        HelperCaseDispatch.assignQueue(caseObj, loginUser);

        HelperCaseDispatch hp = new HelperCaseDispatch();
        Test.stopTest();
    }

    @isTest
    static void testAssignQueueUnifyOffice() {
        new SObjectBuilder(Case_Dispatch__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Case_Dispatch__c.Name => 'Unify Office Support',
                    Case_Dispatch__c.Brand__c => 'Unify Office',
                    Case_Dispatch__c.Queue__c => 'Mitel Support Queue'
                }
            )
            .create();

        /* TODO: HelperCaseDispatch.getAllGroups Group query should be rewritten in order to retrieve sorted results */
        Group mittelQueue = (Group) new ListOptional(new GroupSelector()
            .selectGroupBasedOnDeveloperNames(
                new List<Object>{
                    new Set<String>{
                        'Mitel_Support_Queue'
                    }
                }
            )
            .executeQuery()
        ).getFirst();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'Test account',
                    Account.RC_Brand__c => OpportunityHelper.BRAND_ATOS,
                    Account.RC_User_ID__c => '12345678'
                }
            )
            .build()
            .getRecord();

        Case testCase = new Case();
        testCase.Account = acc;

        User loginUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
            .create()
            .getRecord();

        Test.startTest();
            Case caseToCheck = HelperCaseDispatch.assignQueue(testCase, loginUser);
        Test.stopTest();
        System.assertEquals(mittelQueue.Id, caseToCheck.OwnerId, 'Case owner for for Unify Office Case should be Mitel Support Queue');
    }
}