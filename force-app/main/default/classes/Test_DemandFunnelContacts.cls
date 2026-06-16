@isTest
public with sharing class Test_DemandFunnelContacts {

    @testSetup
    static void createSObjects() {
        Test.startTest();
        new SObjectBuilder(User.SObjectType)
            .setField(User.Username, Test_DemandFunnelHelper.AEUSERNAME)
            .setField(User.Email, Test_DemandFunnelHelper.AELASTNAME + Test_DemandFunnelHelper.LEADEMAIL)
            .setField(User.LastName, Test_DemandFunnelHelper.AELASTNAME)
            .setField(User.CommunityNickname, Test_DemandFunnelHelper.AECOMMUNITYNICKNAME)
            .setField(User.Team__c, Test_DemandFunnelHelper.AETEAM)
            .create();

        new SObjectBuilder(User.SObjectType)
            .setField(User.Username, Test_DemandFunnelHelper.AEUSERNAME + '2')
            .setField(User.Email, Test_DemandFunnelHelper.AELASTNAME + Test_DemandFunnelHelper.LEADEMAIL + '2')
            .setField(User.LastName, Test_DemandFunnelHelper.AELASTNAME + '2')
            .setField(User.CommunityNickname, Test_DemandFunnelHelper.AECOMMUNITYNICKNAME + '2')
            .setField(User.Team__c, Test_DemandFunnelHelper.AETEAM)
            .create();

        new SObjectBuilder(User.SObjectType)
            .setField(User.Username, Test_DemandFunnelHelper.BDRUSERNAME)
            .setField(User.Email, Test_DemandFunnelHelper.BDRLASTNAME + Test_DemandFunnelHelper.LEADEMAIL)
            .setfield(User.LastName, Test_DemandFunnelHelper.BDRLASTNAME)
            .setField(User.CommunityNickname, Test_DemandFunnelHelper.BDRCOMMUNITYNICKNAME)
            .setField(User.Team__c, Test_DemandFunnelHelper.BDRTEAM)
            .create();

        new SObjectBuilder(User.SObjectType)
            .setField(User.Username, Test_DemandFunnelHelper.SDRUSERNAME)
            .setField(User.Email, Test_DemandFunnelHelper.SDRLASTNAME + Test_DemandFunnelHelper.LEADEMAIL)
            .setfield(User.LastName, Test_DemandFunnelHelper.SDRLASTNAME)
            .setField(User.CommunityNickname, Test_DemandFunnelHelper.SDRCOMMUNITYNICKNAME)
            .setField(User.Team__c, Test_DemandFunnelHelper.SDRTEAM)
            .setField(User.SegmentPicklist__c, Test_DemandFunnelHelper.SDRSEGMENT)
            .create();

        new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Opty test account')
            .setField(Account.Partner_ID__c, 'testID')
            .setField(Account.Permitted_Brands__c, 'RingCentral')
            .setField(Account.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .create();

        new SObjectBuilder(DFR_System_Users__c.SObjectType)
            .setField(DFR_System_Users__c.Name, [SELECT Name FROM User WHERE Name = 'LeanData Queue' LIMIT 1].Id)
            .setField(DFR_System_Users__c.Description__c, 'LeanData Queue')
            .create();

        Test.stopTest();
    }

    @isTest
    static void test_ContactCreationWithContactStatusXSuspect_NoDFRCreated() {
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Contact_Status__c, 'X. Suspect')
            .create()
            .getRecord();
        Test.stopTest();

        List<Contact> contactsCreated = (List<Contact>) new ContactSelector()
            .selectContactsByIdsForStatusUpdate(new List<Object>{ new List<id>{ con.id } })
            .executeQuery();
        System.assert(!contactsCreated.isEmpty(), 'Contact creation failed');
        System.assertEquals('X. Suspect', contactsCreated[0].Contact_Status__c, 'Contact created with incorrect data');

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{ 'DET_Current_Funnel_Status__c' }
        );
        System.assert(dfrList.isEmpty(), 'DFR created incorrectly');
    }

    @isTest
    static void testContactStatusX5WorkingSuspect() {
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Contact_Status__c, 'X.5 Working Suspect')
            .create()
            .getRecord();
        Test.stopTest();

        List<Contact> contactsCreated = (List<Contact>) new ContactSelector()
            .selectContactsByIdsForStatusUpdate(new List<Object>{ new List<id>{ con.id } })
            .executeQuery();
        System.assert(!contactsCreated.isEmpty(), 'Contact creation failed');
        System.assertEquals(
            'X.5 Working Suspect',
            contactsCreated[0].Contact_Status__c,
            'Contact created with incorrect data'
        );

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{ 'DET_Current_Funnel_Status__c' }
        );
        System.assert(dfrList.isEmpty(), 'DFR created incorrectly');
    }

    @isTest
    static void test_ContactCreationWithContactStatusXOpen_DFRCreatedInProspect() {
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Contact_Status__c, 'X. Open')
            .create()
            .getRecord();
        Test.stopTest();

        List<Contact> contactsCreated = (List<Contact>) new ContactSelector()
            .selectContactsByIdsForStatusUpdate(new List<Object>{ new List<id>{ con.id } })
            .executeQuery();
        System.assert(!contactsCreated.isEmpty(), 'Contact creation failed');
        System.assertEquals('X. Open', contactsCreated[0].Contact_Status__c, 'Contact created with incorrect data');

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'Contact_Name_on_Creation__c',
                'Contact_Email_on_Creation__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c',
                'Prospect_Entered_From__c',
                'Prospect_Exited_To__c',
                'MQL_Entered_From__c',
                'MQL_Exited_To__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'EOL_Entered_From__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(
            con.FirstName +
            ' ' +
            con.LastName,
            dfrList[0].Contact_Name_on_Creation__c,
            'DFR created with incorrect data'
        );
        System.assertEquals(con.Email, dfrList[0].Contact_Email_on_Creation__c, 'DFR created with incorrect data');
        System.assertEquals(
            Test_DemandFunnelHelper.PROSPECTFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DFR created with incorrect data'
        );
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].Prospect_Entered_From__c, 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].Prospect_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].MQL_Entered_From__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].MQL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].TAL_Entered_From__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].TAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].SAL_Entered_From__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].SAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].EOL_Entered_From__c), 'DFR created with incorrect data');
    }

    @isTest
    static void test_ContactCreationWithContactStatusX5WorkingProspect_DFRCreatedInProspect() {
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Contact_Status__c, 'X.5 Working Prospect')
            .create()
            .getRecord();
        Test.stopTest();

        List<Contact> contactsCreated = (List<Contact>) new ContactSelector()
            .selectContactsByIdsForStatusUpdate(new List<Object>{ new List<id>{ con.id } })
            .executeQuery();
        System.assert(!contactsCreated.isEmpty(), 'Contact creation failed');
        System.assertEquals(
            'X.5 Working Prospect',
            contactsCreated[0].Contact_Status__c,
            'Contact created with incorrect data'
        );

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'Contact_Name_on_Creation__c',
                'Contact_Email_on_Creation__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c',
                'Prospect_Entered_From__c',
                'Prospect_Exited_To__c',
                'MQL_Entered_From__c',
                'MQL_Exited_To__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'EOL_Entered_From__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(
            con.FirstName +
            ' ' +
            con.LastName,
            dfrList[0].Contact_Name_on_Creation__c,
            'DFR created with incorrect data'
        );
        System.assertEquals(con.Email, dfrList[0].Contact_Email_on_Creation__c, 'DFR created with incorrect data');
        System.assertEquals(
            Test_DemandFunnelHelper.PROSPECTFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DFR created with incorrect data'
        );
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].Prospect_Entered_From__c, 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].Prospect_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].MQL_Entered_From__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].MQL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].TAL_Entered_From__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].TAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].SAL_Entered_From__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].SAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].EOL_Entered_From__c), 'DFR created with incorrect data');
    }

    @isTest
    static void test_ContactCreationWithContactStatus5ReNew_DFRCreatedInMQL() {
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Contact_Status__c, '.5 Re-New')
            .create()
            .getRecord();
        Test.stopTest();

        List<Contact> contactsCreated = (List<Contact>) new ContactSelector()
            .selectContactsByIdsForStatusUpdate(new List<Object>{ new List<id>{ con.id } })
            .executeQuery();
        System.assert(!contactsCreated.isEmpty(), 'Contact creation failed');
        System.assertEquals('.5 Re-New', contactsCreated[0].Contact_Status__c, 'Contact created with incorrect data');

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'Contact_Name_on_Creation__c',
                'Contact_Email_on_Creation__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c',
                'Prospect_Entered_From__c',
                'Prospect_Exited_To__c',
                'MQL_Entered_From__c',
                'MQL_Exited_To__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'EOL_Entered_From__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(
            con.FirstName +
            ' ' +
            con.LastName,
            dfrList[0].Contact_Name_on_Creation__c,
            'DFR created with incorrect data'
        );
        System.assertEquals(con.Email, dfrList[0].Contact_Email_on_Creation__c, 'DFR created with incorrect data');
        System.assertEquals(
            Test_DemandFunnelHelper.MQLFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DFR created with incorrect data'
        );
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].MQL_Entered_From__c, 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].MQL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].TAL_Entered_From__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].TAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].SAL_Entered_From__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].SAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].EOL_Entered_From__c), 'DFR created with incorrect data');
    }

    @isTest
    static void test_ContactCreationWithContactStatus1New_DFRCreatedInMQL() {
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Contact_Status__c, '1. New')
            .create()
            .getRecord();
        Test.stopTest();

        List<Contact> contactsCreated = (List<Contact>) new ContactSelector()
            .selectContactsByIdsForStatusUpdate(new List<Object>{ new List<id>{ con.id } })
            .executeQuery();
        System.assert(!contactsCreated.isEmpty(), 'Contact creation failed');
        System.assertEquals('1. New', contactsCreated[0].Contact_Status__c, 'Contact created with incorrect data');

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'Contact_Name_on_Creation__c',
                'Contact_Email_on_Creation__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c',
                'Prospect_Entered_From__c',
                'Prospect_Exited_To__c',
                'MQL_Entered_From__c',
                'MQL_Exited_To__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'EOL_Entered_From__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(
            con.FirstName +
            ' ' +
            con.LastName,
            dfrList[0].Contact_Name_on_Creation__c,
            'DFR created with incorrect data'
        );
        System.assertEquals(con.Email, dfrList[0].Contact_Email_on_Creation__c, 'DFR created with incorrect data');
        System.assertEquals(
            Test_DemandFunnelHelper.MQLFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DFR created with incorrect data'
        );
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].MQL_Entered_From__c, 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].MQL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].TAL_Entered_From__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].TAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].SAL_Entered_From__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].SAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].EOL_Entered_From__c), 'DFR created with incorrect data');
    }

    @isTest
    static void test_ContactCreationWithContactStatus15CallOutAndAEOwner_DFRCreatedInSAL() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Contact_Status__c, '1.5 Call Out')
            .setField(Contact.OwnerId, aeUser.Id)
            .create()
            .getRecord();
        Test.stopTest();

        List<Contact> contactsCreated = (List<Contact>) new ContactSelector()
            .selectContactsByIdsForStatusUpdate(new List<Object>{ new List<id>{ con.id } })
            .executeQuery();
        System.assert(!contactsCreated.isEmpty(), 'Contact creation failed');
        System.assertEquals(
            '1.5 Call Out',
            contactsCreated[0].Contact_Status__c,
            'Contact created with incorrect data'
        );

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'Contact_Name_on_Creation__c',
                'Contact_Email_on_Creation__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c',
                'Prospect_Entered_From__c',
                'Prospect_Exited_To__c',
                'MQL_Entered_From__c',
                'MQL_Exited_To__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'EOL_Entered_From__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(
            con.FirstName +
            ' ' +
            con.LastName,
            dfrList[0].Contact_Name_on_Creation__c,
            'DFR created with incorrect data'
        );
        System.assertEquals(con.Email, dfrList[0].Contact_Email_on_Creation__c, 'DFR created with incorrect data');
        System.assertEquals(
            Test_DemandFunnelHelper.SALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DFR created with incorrect data'
        );
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].SAL_Entered_From__c, 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].TAL_Entered_From__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].TAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].SAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].EOL_Entered_From__c), 'DFR created with incorrect data');
    }

    @isTest
    static void test_ContactCreationWithContactStatus2ContactedAndAEOwner_DFRCreatedInSAL() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Contact_Status__c, '2. Contacted')
            .setField(Contact.OwnerId, aeUser.Id)
            .create()
            .getRecord();
        Test.stopTest();

        List<Contact> contactsCreated = (List<Contact>) new ContactSelector()
            .selectContactsByIdsForStatusUpdate(new List<Object>{ new List<id>{ con.id } })
            .executeQuery();
        System.assert(!contactsCreated.isEmpty(), 'Contact creation failed');
        System.assertEquals(
            '2. Contacted',
            contactsCreated[0].Contact_Status__c,
            'Contact created with incorrect data'
        );

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'Contact_Name_on_Creation__c',
                'Contact_Email_on_Creation__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c',
                'Prospect_Entered_From__c',
                'Prospect_Exited_To__c',
                'MQL_Entered_From__c',
                'MQL_Exited_To__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'EOL_Entered_From__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(
            con.FirstName +
            ' ' +
            con.LastName,
            dfrList[0].Contact_Name_on_Creation__c,
            'DFR created with incorrect data'
        );
        System.assertEquals(con.Email, dfrList[0].Contact_Email_on_Creation__c, 'DFR created with incorrect data');
        System.assertEquals(
            Test_DemandFunnelHelper.SALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DFR created with incorrect data'
        );
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].SAL_Entered_From__c, 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].TAL_Entered_From__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].TAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].SAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].EOL_Entered_From__c), 'DFR created with incorrect data');
    }

    @isTest
    static void test_ContactStatusChangeFromOpenTo5ReNew_DFRChangesFromProspectToMQL() {
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Contact_Status__c, 'X. Open')
            .create()
            .getRecord();

        con.Contact_Status__c = '.5 Re-New';
        update con;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<Contact> contactsCreated = (List<Contact>) new ContactSelector()
            .selectContactsByIdsForStatusUpdate(new List<Object>{ new List<id>{ con.id } })
            .executeQuery();
        System.assert(!contactsCreated.isEmpty(), 'Contact creation failed');
        System.assertEquals('.5 Re-New', contactsCreated[0].Contact_Status__c, 'Contact created with incorrect data');

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'Contact_Name_on_Creation__c',
                'Contact_Email_on_Creation__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c',
                'Prospect_Entered_From__c',
                'Prospect_Exited_To__c',
                'MQL_Entered_From__c',
                'MQL_Exited_To__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'EOL_Entered_From__c',
                'Prospect_Owner_Name__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(
            Test_DemandFunnelHelper.MQLFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DFR created with incorrect data'
        );
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].Prospect_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.MQL, dfrList[0].Prospect_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.PROSPECT, dfrList[0].MQL_Entered_From__c, 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].MQL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].SAL_Entered_From__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].TAL_Entered_From__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].TAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].SAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].EOL_Entered_From__c), 'DFR created with incorrect data');
        System.assert(!String.isEmpty(dfrList[0].Prospect_Owner_Name__c), 'DFR created with incorrect data');
    }

    @isTest
    static void test_ContactStatusChangeFromOpenTo1New_DFRChangesFromProspectToMQL() {
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        
        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Contact_Status__c, 'X. Open')
            .create()
            .getRecord();

        con.Contact_Status__c = '1. New';
        update con;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<Contact> contactsCreated = (List<Contact>) new ContactSelector()
            .selectContactsByIdsForStatusUpdate(new List<Object>{ new List<id>{ con.id } })
            .executeQuery();
        System.assert(!contactsCreated.isEmpty(), 'Contact creation failed');
        System.assertEquals('1. New', contactsCreated[0].Contact_Status__c, 'Contact created with incorrect data');

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'Contact_Name_on_Creation__c',
                'Contact_Email_on_Creation__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c',
                'Prospect_Entered_From__c',
                'Prospect_Exited_To__c',
                'MQL_Entered_From__c',
                'MQL_Exited_To__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'EOL_Entered_From__c',
                'Prospect_Owner_Name__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(
            Test_DemandFunnelHelper.MQLFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DFR created with incorrect data'
        );
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].Prospect_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.MQL, dfrList[0].Prospect_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.PROSPECT, dfrList[0].MQL_Entered_From__c, 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].MQL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].SAL_Entered_From__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].TAL_Entered_From__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].TAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].SAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].EOL_Entered_From__c), 'DFR created with incorrect data');
        System.assert(!String.isEmpty(dfrList[0].Prospect_Owner_Name__c), 'DFR created with incorrect data');
    }

    @isTest
    static void test_ContactStatusChangeFromOpenTo15CallOut_DFRChangesFromProspectToSAL() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        
        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Contact_Status__c, 'X. Open')
            .setField(Contact.OwnerId, aeUser.Id)
            .create()
            .getRecord();

        con.Contact_Status__c = '1.5 Call Out';
        update con;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<Contact> contactsCreated = (List<Contact>) new ContactSelector()
            .selectContactsByIdsForStatusUpdate(new List<Object>{ new List<id>{ con.id } })
            .executeQuery();
        System.assert(!contactsCreated.isEmpty(), 'Contact creation failed');
        System.assertEquals(
            '1.5 Call Out',
            contactsCreated[0].Contact_Status__c,
            'Contact created with incorrect data'
        );

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'Contact_Name_on_Creation__c',
                'Contact_Email_on_Creation__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c',
                'Prospect_Entered_From__c',
                'Prospect_Exited_To__c',
                'MQL_Entered_From__c',
                'MQL_Exited_To__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'EOL_Entered_From__c',
                'MQL_Owner_Name__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(
            Test_DemandFunnelHelper.SALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DFR created with incorrect data'
        );
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].Prospect_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.SAL, dfrList[0].Prospect_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.PROSPECT, dfrList[0].SAL_Entered_From__c, 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].TAL_Entered_From__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].TAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].SAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].EOL_Entered_From__c), 'DFR created with incorrect data');
        System.assert(!String.isEmpty(dfrList[0].MQL_Owner_Name__c), 'DFR created with incorrect data');
    }

    @isTest
    static void test_ContactStatusChangeFromOpenTo12Contacted_DFRChangesFromProspectToSAL() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        
        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Contact_Status__c, 'X. Open')
            .setField(Contact.OwnerId, aeUser.Id)
            .create()
            .getRecord();

        con.Contact_Status__c = '2. Contacted';
        update con;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<Contact> contactsCreated = (List<Contact>) new ContactSelector()
            .selectContactsByIdsForStatusUpdate(new List<Object>{ new List<id>{ con.id } })
            .executeQuery();
        System.assert(!contactsCreated.isEmpty(), 'Contact creation failed');
        System.assertEquals(
            '2. Contacted',
            contactsCreated[0].Contact_Status__c,
            'Contact created with incorrect data'
        );

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'Contact_Name_on_Creation__c',
                'Contact_Email_on_Creation__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c',
                'Prospect_Entered_From__c',
                'Prospect_Exited_To__c',
                'MQL_Entered_From__c',
                'MQL_Exited_To__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'EOL_Entered_From__c',
                'MQL_Owner_Name__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(
            Test_DemandFunnelHelper.SALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DFR created with incorrect data'
        );
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].Prospect_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.SAL, dfrList[0].Prospect_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.PROSPECT, dfrList[0].SAL_Entered_From__c, 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].TAL_Entered_From__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].TAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].SAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].EOL_Entered_From__c), 'DFR created with incorrect data');
        System.assert(!String.isEmpty(dfrList[0].MQL_Owner_Name__c), 'DFR created with incorrect data');
    }

    @isTest
    static void test_ContactStatusChangeFrom5ReNewTo15CallOut_DFRChangesFromMQLToSAL() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        
        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Contact_Status__c, '.5 Re-New')
            .setField(Contact.OwnerId, aeUser.Id)
            .create()
            .getRecord();

        Test.getEventBus().deliver();
        con.Contact_Status__c = '1.5 Call Out';
        update con;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<Contact> contactsCreated = (List<Contact>) new ContactSelector()
            .selectContactsByIdsForStatusUpdate(new List<Object>{ new List<id>{ con.id } })
            .executeQuery();
        System.assert(!contactsCreated.isEmpty(), 'Contact creation failed');
        System.assertEquals(
            '1.5 Call Out',
            contactsCreated[0].Contact_Status__c,
            'Contact created with incorrect data'
        );

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'Contact_Name_on_Creation__c',
                'Contact_Email_on_Creation__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c',
                'Prospect_Entered_From__c',
                'Prospect_Exited_To__c',
                'MQL_Entered_From__c',
                'MQL_Exited_To__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'EOL_Entered_From__c',
                'MQL_Owner_Team__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(
            Test_DemandFunnelHelper.SALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DFR created with incorrect data'
        );
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR created with incorrect data');
        System.assert(!String.isEmpty(dfrList[0].MQL_Owner_Team__c), 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].MQL_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.SAL, dfrList[0].MQL_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.MQL, dfrList[0].SAL_Entered_From__c, 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].TAL_Entered_From__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].TAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].SAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].EOL_Entered_From__c), 'DFR created with incorrect data');
    }

    @isTest
    static void test_ContactStatusChangeFrom5ReNewTo2Contacted_DFRChangesFromMQLToSAL() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        
        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Contact_Status__c, '.5 Re-New')
            .setField(Contact.OwnerId, aeUser.Id)
            .create()
            .getRecord();

        Test.getEventBus().deliver();
        con.Contact_Status__c = '2. Contacted';
        update con;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<Contact> contactsCreated = (List<Contact>) new ContactSelector()
            .selectContactsByIdsForStatusUpdate(new List<Object>{ new List<id>{ con.id } })
            .executeQuery();
        System.assert(!contactsCreated.isEmpty(), 'Contact creation failed');
        System.assertEquals(
            '2. Contacted',
            contactsCreated[0].Contact_Status__c,
            'Contact created with incorrect data'
        );

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'Contact_Name_on_Creation__c',
                'Contact_Email_on_Creation__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c',
                'Prospect_Entered_From__c',
                'Prospect_Exited_To__c',
                'MQL_Entered_From__c',
                'MQL_Exited_To__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'EOL_Entered_From__c',
                'MQL_Owner_Team__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(
            Test_DemandFunnelHelper.SALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DFR created with incorrect data'
        );
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR created with incorrect data');
        System.assert(!String.isEmpty(dfrList[0].MQL_Owner_Team__c), 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].MQL_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.SAL, dfrList[0].MQL_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.MQL, dfrList[0].SAL_Entered_From__c, 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].TAL_Entered_From__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].TAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].SAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].EOL_Entered_From__c), 'DFR created with incorrect data');
    }

    @isTest
    static void test_ContactStatusChangeFrom5ReNewToXOpen_DFRNoChange() {
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        
        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Contact_Status__c, '.5 Re-New')
            .create()
            .getRecord();

        Test.getEventBus().deliver();
        con.Contact_Status__c = 'X. Open';
        update con;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<Contact> contactsCreated = (List<Contact>) new ContactSelector()
            .selectContactsByIdsForStatusUpdate(new List<Object>{ new List<id>{ con.id } })
            .executeQuery();
        System.assert(!contactsCreated.isEmpty(), 'Contact creation failed');
        System.assertEquals('X. Open', contactsCreated[0].Contact_Status__c, 'Contact created with incorrect data');

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{ 'Contact_Name_on_Creation__c', 'LastModifiedDate' }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
    }

    @isTest
    static void test_ContactStatusChangeFrom1NewTo15CallOut_DFRChanngesFromMQLToSAL() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        
        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Contact_Status__c, '1. New')
            .setField(Contact.OwnerId, aeUser.Id)
            .create()
            .getRecord();

        Test.getEventBus().deliver();
        con.Contact_Status__c = '1.5 Call Out';
        update con;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<Contact> contactsCreated = (List<Contact>) new ContactSelector()
            .selectContactsByIdsForStatusUpdate(new List<Object>{ new List<id>{ con.id } })
            .executeQuery();
        System.assert(!contactsCreated.isEmpty(), 'Contact creation failed');
        System.assertEquals(
            '1.5 Call Out',
            contactsCreated[0].Contact_Status__c,
            'Contact created with incorrect data'
        );

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'Contact_Name_on_Creation__c',
                'Contact_Email_on_Creation__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c',
                'Prospect_Entered_From__c',
                'Prospect_Exited_To__c',
                'MQL_Entered_From__c',
                'MQL_Exited_To__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'EOL_Entered_From__c',
                'MQL_Owner_Team__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(
            Test_DemandFunnelHelper.SALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DFR created with incorrect data'
        );
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR created with incorrect data');
        System.assert(!String.isEmpty(dfrList[0].MQL_Owner_Team__c), 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].MQL_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.SAL, dfrList[0].MQL_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.MQL, dfrList[0].SAL_Entered_From__c, 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].TAL_Entered_From__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].TAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].SAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].EOL_Entered_From__c), 'DFR created with incorrect data');
    }

    @isTest
    static void test_ContactStatusChangeFrom1NewTo2Contacted_DFRChanngesFromMQLToSAL() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        
        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Contact_Status__c, '1. New')
            .setField(Contact.OwnerId, aeUser.Id)
            .create()
            .getRecord();

        Test.getEventBus().deliver();
        con.Contact_Status__c = '2. Contacted';
        update con;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<Contact> contactsCreated = (List<Contact>) new ContactSelector()
            .selectContactsByIdsForStatusUpdate(new List<Object>{ new List<id>{ con.id } })
            .executeQuery();
        System.assert(!contactsCreated.isEmpty(), 'Contact creation failed');
        System.assertEquals(
            '2. Contacted',
            contactsCreated[0].Contact_Status__c,
            'Contact created with incorrect data'
        );

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'Contact_Name_on_Creation__c',
                'Contact_Email_on_Creation__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c',
                'Prospect_Entered_From__c',
                'Prospect_Exited_To__c',
                'MQL_Entered_From__c',
                'MQL_Exited_To__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'EOL_Entered_From__c',
                'MQL_Owner_Team__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(
            Test_DemandFunnelHelper.SALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DFR created with incorrect data'
        );
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR created with incorrect data');
        System.assert(!String.isEmpty(dfrList[0].MQL_Owner_Team__c), 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].MQL_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.SAL, dfrList[0].MQL_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.MQL, dfrList[0].SAL_Entered_From__c, 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].TAL_Entered_From__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].TAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].SAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].EOL_Entered_From__c), 'DFR created with incorrect data');
    }

    @isTest
    static void test_ContactStatusChangeFrom1NewToXOpen_DFRNoChange() {
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        
        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Contact_Status__c, '1. New')
            .create()
            .getRecord();

        Test.getEventBus().deliver();
        con.Contact_Status__c = 'X. Open';
        update con;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<Contact> contactsCreated = (List<Contact>) new ContactSelector()
            .selectContactsByIdsForStatusUpdate(new List<Object>{ new List<id>{ con.id } })
            .executeQuery();
        System.assert(!contactsCreated.isEmpty(), 'Contact creation failed');
        System.assertEquals('X. Open', contactsCreated[0].Contact_Status__c, 'Contact created with incorrect data');

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{ 'Contact_Name_on_Creation__c', 'LastModifiedDate' }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
    }

    @isTest
    static void test_ContactStatusChangeFrom15CallOutTo2Contacted_DFRNoChange() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        
        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Contact_Status__c, '1.5 Call Out')
            .setField(Contact.OwnerId, aeUser.Id)
            .create()
            .getRecord();

        Test.getEventBus().deliver();
        con.Contact_Status__c = '2. Contacted';
        update con;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<Contact> contactsCreated = (List<Contact>) new ContactSelector()
            .selectContactsByIdsForStatusUpdate(new List<Object>{ new List<id>{ con.id } })
            .executeQuery();
        System.assert(!contactsCreated.isEmpty(), 'Contact creation failed');
        System.assertEquals(
            '2. Contacted',
            contactsCreated[0].Contact_Status__c,
            'Contact created with incorrect data'
        );

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{ 'Contact_Name_on_Creation__c', 'LastModifiedDate' }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
    }

    @isTest
    static void test_ContactStatusChangeFrom15CallOutToXOpen_DFRNoChange() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        
        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Contact_Status__c, '1.5 Call Out')
            .setField(Contact.OwnerId, aeUser.Id)
            .create()
            .getRecord();

        Test.getEventBus().deliver();
        con.Contact_Status__c = 'X. Open';
        update con;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<Contact> contactsCreated = (List<Contact>) new ContactSelector()
            .selectContactsByIdsForStatusUpdate(new List<Object>{ new List<id>{ con.id } })
            .executeQuery();
        System.assert(!contactsCreated.isEmpty(), 'Contact creation failed');
        System.assertEquals('X. Open', contactsCreated[0].Contact_Status__c, 'Contact created with incorrect data');

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{ 'Contact_Name_on_Creation__c', 'LastModifiedDate' }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
    }

    @isTest
    static void test_ContactStatusChangesFrom0DowngradedTo5ReNew_DFRCreatedInMQL() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        
        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Contact_Status__c, '0. Downgraded')
            .setField(Contact.OwnerId, aeUser.Id)
            .create()
            .getRecord();

        System.assertEquals(aeUser.Id, con.OwnerId, 'Contact created with incorrect Owner');
        System.assertEquals('0. Downgraded', con.Contact_Status__c, 'Contact created with incorrect Status');

        con.Contact_Status__c = '.5 Re-New';
        update con;
        Test.getEventBus().deliver();
        List<Contact> contactsReNew = (List<Contact>) new ContactSelector()
            .selectContactsByIdsForStatusUpdate(new List<Object>{ new List<id>{ con.id } })
            .executeQuery();
        System.assert(!contactsReNew.isEmpty(), 'Contact creation failed');
        System.assertEquals('.5 Re-New', contactsReNew[0].Contact_Status__c, 'Contact created with incorrect data');

        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'DET_Current_Funnel_Status__c',
                'Prospect_Entered_From__c',
                'Prospect_Exited_To__c',
                'Prospect_Owner_Name__c',
                'MQL_Type__c',
                'MQL_Entered_From__c',
                'MQL_Owner_Name__c',
                'SAL_Entered_From__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(
            Test_DemandFunnelHelper.MQLFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DFR created with incorrect data'
        );
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'DFR created with incorrect data');
        System.assert(!String.isEmpty(dfrList[0].Prospect_Owner_Name__c), 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.RENEW, dfrList[0].MQL_Type__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].MQL_Entered_From__c, 'DFR created with incorrect data');
        System.assert(!String.isEmpty(dfrList[0].MQL_Owner_Name__c), 'DFR created with incorrect data');
    }

    @isTest
    static void test_ContactStatusChangeFrom0DowngradedTo5ReNewTo15CallOut_DFRCreatedInMQLChangesToSAL() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        
        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Contact_Status__c, '0. Downgraded')
            .setField(Contact.OwnerId, aeUser.Id)
            .create()
            .getRecord();

        System.assertEquals(aeUser.Id, con.OwnerId, 'Contact created with incorrect Owner');
        System.assertEquals('0. Downgraded', con.Contact_Status__c, 'Contact created with incorrect Status');

        con.Contact_Status__c = '.5 Re-New';
        update con;
        Test.getEventBus().deliver();
        List<Contact> contactsReNew = (List<Contact>) new ContactSelector()
            .selectContactsByIdsForStatusUpdate(new List<Object>{ new List<id>{ con.id } })
            .executeQuery();
        System.assert(!contactsReNew.isEmpty(), 'Contact creation failed');
        System.assertEquals('.5 Re-New', contactsReNew[0].Contact_Status__c, 'Contact created with incorrect data');

        con.Contact_Status__c = '1.5 Call Out';
        update con;
        Test.getEventBus().deliver();
        List<Contact> contacts15CallOut = (List<Contact>) new ContactSelector()
            .selectContactsByIdsForStatusUpdate(new List<Object>{ new List<id>{ con.id } })
            .executeQuery();
        System.assert(!contacts15CallOut.isEmpty(), 'Contact creation failed');
        System.assertEquals(
            '1.5 Call Out',
            contacts15CallOut[0].Contact_Status__c,
            'Contact created with incorrect data'
        );
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'DET_Current_Funnel_Status__c',
                'Prospect_Entered_From__c',
                'Prospect_Exited_To__c',
                'Prospect_Owner_Name__c',
                'MQL_Type__c',
                'MQL_Entered_From__c',
                'MQL_Owner_Name__c',
                'SAL_Entered_From__c',
                'SAL_Owner_Name__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(
            Test_DemandFunnelHelper.SALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DFR created with incorrect data'
        );
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'DFR created with incorrect data');
        System.assert(!String.isEmpty(dfrList[0].Prospect_Owner_Name__c), 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.RENEW, dfrList[0].MQL_Type__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].MQL_Entered_From__c, 'DFR created with incorrect data');
        System.assert(!String.isEmpty(dfrList[0].MQL_Owner_Name__c), 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.MQL, dfrList[0].SAL_Entered_From__c, 'DFR created with incorrect data');
        System.assert(!String.isEmpty(dfrList[0].SAL_Owner_Name__c), 'DFR created with incorrect data');
    }

    @isTest
    static void test_ContactStatusChangeFrom0DowngradedTo5ReNewTo2Contacted_DFRCreatedInMQLChangesToSAL() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        
        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Contact_Status__c, '0. Downgraded')
            .setField(Contact.OwnerId, aeUser.Id)
            .create()
            .getRecord();

        System.assertEquals(aeUser.Id, con.OwnerId, 'Contact created with incorrect Owner');
        System.assertEquals('0. Downgraded', con.Contact_Status__c, 'Contact created with incorrect Status');

        con.Contact_Status__c = '.5 Re-New';
        update con;
        Test.getEventBus().deliver();
        List<Contact> contactsReNew = (List<Contact>) new ContactSelector()
            .selectContactsByIdsForStatusUpdate(new List<Object>{ new List<id>{ con.id } })
            .executeQuery();
        System.assert(!contactsReNew.isEmpty(), 'Contact creation failed');
        System.assertEquals('.5 Re-New', contactsReNew[0].Contact_Status__c, 'Contact created with incorrect data');

        con.Contact_Status__c = '2. Contacted';
        update con;
        Test.getEventBus().deliver();
        List<Contact> contactsContacted = (List<Contact>) new ContactSelector()
            .selectContactsByIdsForStatusUpdate(new List<Object>{ new List<id>{ con.id } })
            .executeQuery();
        System.assert(!contactsContacted.isEmpty(), 'Contact creation failed');
        System.assertEquals(
            '2. Contacted',
            contactsContacted[0].Contact_Status__c,
            'Contact created with incorrect data'
        );
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'DET_Current_Funnel_Status__c',
                'Prospect_Entered_From__c',
                'Prospect_Exited_To__c',
                'Prospect_Owner_Name__c',
                'MQL_Type__c',
                'MQL_Entered_From__c',
                'MQL_Owner_Name__c',
                'SAL_Entered_From__c',
                'SAL_Owner_Name__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(
            Test_DemandFunnelHelper.SALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DFR created with incorrect data'
        );
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'DFR created with incorrect data');
        System.assert(!String.isEmpty(dfrList[0].Prospect_Owner_Name__c), 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.RENEW, dfrList[0].MQL_Type__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].MQL_Entered_From__c, 'DFR created with incorrect data');
        System.assert(!String.isEmpty(dfrList[0].MQL_Owner_Name__c), 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.MQL, dfrList[0].SAL_Entered_From__c, 'DFR created with incorrect data');
        System.assert(!String.isEmpty(dfrList[0].SAL_Owner_Name__c), 'DFR created with incorrect data');
    }

    @isTest
    static void test_ContactStatusChangeDowngradedToContacted_MQLTypeShouldBeReNew() {
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'John')
            .setField(Contact.LastName, 'Doe')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Contact_Status__c, '0. Downgraded')
            .setField(Contact.Contact_Funnel_Type__c, Test_DemandFunnelHelper.PROSPECTFUNNELSTATUS)
            .setField(Contact.AccountId, acc.Id)
            .create()
            .getRecord();

        TriggerHandler.BY_PASS_CONTACT_ON_UPDATE = false;
        TriggerHandler.BY_PASS_CONTACT_ON_AFTER = false;

        Test.startTest();
        con.Contact_Status__c = '2. Contacted';
        update con;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(new List<Contact>{ con }, new List<String>{ 'MQL_Type__c' });

        System.assertEquals(Test_DemandFunnelHelper.RENEW, dfrList[0].MQL_Type__c, 'MQL_Type__c should be Re-New');
    }

    @isTest
    static void test_ContactStatusChangeFrom1NewTo2ContactedSDRUser_DFRChangesFromMQLToTAL() {
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];
        
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        
        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Contact_Status__c, '1. New')
            .setField(Contact.OwnerId, sdrUser.Id)
            .create()
            .getRecord();

        con.Contact_Status__c = '2. Contacted';
        update con;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<Contact> contactsCreated = (List<Contact>) new ContactSelector()
            .selectContactsByIdsForStatusUpdate(new List<Object>{ new List<id>{ con.id } })
            .selectField(Contact.OwnerId)
            .executeQuery();
        System.assert(!contactsCreated.isEmpty(), 'Contact creation failed');
        System.assertEquals(
            '2. Contacted',
            contactsCreated[0].Contact_Status__c,
            'Contact created with incorrect data'
        );

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'Contact_Name_on_Creation__c',
                'Contact_Email_on_Creation__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c',
                'Prospect_Entered_From__c',
                'Prospect_Exited_To__c',
                'MQL_Entered_From__c',
                'MQL_Exited_To__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'EOL_Entered_From__c',
                'MQL_Owner_Name__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(
            Test_DemandFunnelHelper.TALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DFR created with incorrect data'
        );
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].MQL_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.TAL, dfrList[0].MQL_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.MQL, dfrList[0].TAL_Entered_From__c, 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].SAL_Entered_From__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].TAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].SAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].EOL_Entered_From__c), 'DFR created with incorrect data');
        System.assert(!String.isEmpty(dfrList[0].MQL_Owner_Name__c), 'DFR created with incorrect data');
    }

    @isTest
    static void test_ContactCreationWithContactStatus2ContactedAndSDROwner_DFRCreatedInTAL() {
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Contact_Status__c, '2. Contacted')
            .setField(Contact.OwnerId, sdrUser.Id)
            .create()
            .getRecord();
        Test.stopTest();

        List<Contact> contactsCreated = (List<Contact>) new ContactSelector()
            .selectContactsByIdsForStatusUpdate(new List<Object>{ new List<id>{ con.id } })
            .executeQuery();
        System.assert(!contactsCreated.isEmpty(), 'Contact creation failed');
        System.assertEquals(
            '2. Contacted',
            contactsCreated[0].Contact_Status__c,
            'Contact created with incorrect data'
        );

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'Contact_Name_on_Creation__c',
                'Contact_Email_on_Creation__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c',
                'Prospect_Entered_From__c',
                'Prospect_Exited_To__c',
                'MQL_Entered_From__c',
                'MQL_Exited_To__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'EOL_Entered_From__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(
            con.FirstName +
            ' ' +
            con.LastName,
            dfrList[0].Contact_Name_on_Creation__c,
            'DFR created with incorrect data'
        );
        System.assertEquals(con.Email, dfrList[0].Contact_Email_on_Creation__c, 'DFR created with incorrect data');
        System.assertEquals(
            Test_DemandFunnelHelper.TALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DFR created with incorrect data'
        );
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].TAL_Entered_From__c, 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].SAL_Entered_From__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].TAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].SAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].EOL_Entered_From__c), 'DFR created with incorrect data');
    }

    @isTest
    static void test_ContactOwnerChangeWithContactStatus2ContactedFromSDRUserToAEUser_DFRChangesFromTALToSAL() {
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Contact_Status__c, '2. Contacted')
            .setField(Contact.OwnerId, sdrUser.Id)
            .create()
            .getRecord();

        con.OwnerId = aeUser.Id;
        update con;
        Test.stopTest();

        List<Contact> contactsCreated = (List<Contact>) new ContactSelector()
            .selectContactsByIdsForStatusUpdate(new List<Object>{ new List<id>{ con.id } })
            .executeQuery();
        System.assert(!contactsCreated.isEmpty(), 'Contact creation failed');
        System.assertEquals(
            '2. Contacted',
            contactsCreated[0].Contact_Status__c,
            'Contact created with incorrect data'
        );

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'Contact_Name_on_Creation__c',
                'Contact_Email_on_Creation__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c',
                'Prospect_Entered_From__c',
                'Prospect_Exited_To__c',
                'MQL_Entered_From__c',
                'MQL_Exited_To__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'TQL_Entered_From__c',
                'TQL_Exited_To__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'EOL_Entered_From__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(
            con.FirstName +
            ' ' +
            con.LastName,
            dfrList[0].Contact_Name_on_Creation__c,
            'DFR created with incorrect data'
        );
        System.assertEquals(con.Email, dfrList[0].Contact_Email_on_Creation__c, 'DFR created with incorrect data');
        System.assertEquals(
            Test_DemandFunnelHelper.SALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DFR created with incorrect data'
        );
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].TAL_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.TQL, dfrList[0].TAL_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.TAL, dfrList[0].TQL_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.SAL, dfrList[0].TQL_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.TQL, dfrList[0].SAL_Entered_From__c, 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].SAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].EOL_Entered_From__c), 'DFR created with incorrect data');
    }

    @isTest
    static void test_ContactStatusChangeFromOpenTo15CallOutSDROwner_DFRChangesFromProspectToTAL() {
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
            
        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Contact_Status__c, 'X. Open')
            .setField(Contact.OwnerId, sdrUser.Id)
            .create()
            .getRecord();

        con.Contact_Status__c = '1.5 Call Out';
        update con;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<Contact> contactsCreated = (List<Contact>) new ContactSelector()
            .selectContactsByIdsForStatusUpdate(new List<Object>{ new List<id>{ con.id } })
            .executeQuery();
        System.assert(!contactsCreated.isEmpty(), 'Contact creation failed');
        System.assertEquals(
            '1.5 Call Out',
            contactsCreated[0].Contact_Status__c,
            'Contact created with incorrect data'
        );

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'Contact_Name_on_Creation__c',
                'Contact_Email_on_Creation__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c',
                'Prospect_Entered_From__c',
                'Prospect_Exited_To__c',
                'MQL_Entered_From__c',
                'MQL_Exited_To__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'EOL_Entered_From__c',
                'MQL_Owner_Name__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(
            Test_DemandFunnelHelper.TALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DFR created with incorrect data'
        );
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].Prospect_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.TAL, dfrList[0].Prospect_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.PROSPECT, dfrList[0].TAL_Entered_From__c, 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].SAL_Entered_From__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].TAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].SAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].EOL_Entered_From__c), 'DFR created with incorrect data');
        System.assert(!String.isEmpty(dfrList[0].MQL_Owner_Name__c), 'DFR created with incorrect data');
    }

    @isTest
    static void test_ContactStatusChangeFromOpenTo2ContactedSDROwner_DFRChangesFromProspectToTAL() {
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
            
        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Contact_Status__c, 'X. Open')
            .setField(Contact.OwnerId, sdrUser.Id)
            .create()
            .getRecord();

        con.Contact_Status__c = '2. Contacted';
        update con;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<Contact> contactsCreated = (List<Contact>) new ContactSelector()
            .selectContactsByIdsForStatusUpdate(new List<Object>{ new List<id>{ con.id } })
            .executeQuery();
        System.assert(!contactsCreated.isEmpty(), 'Contact creation failed');
        System.assertEquals(
            '2. Contacted',
            contactsCreated[0].Contact_Status__c,
            'Contact created with incorrect data'
        );

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'Contact_Name_on_Creation__c',
                'Contact_Email_on_Creation__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c',
                'Prospect_Entered_From__c',
                'Prospect_Exited_To__c',
                'MQL_Entered_From__c',
                'MQL_Exited_To__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'EOL_Entered_From__c',
                'MQL_Owner_Name__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(
            Test_DemandFunnelHelper.TALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DFR created with incorrect data'
        );
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].Prospect_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.TAL, dfrList[0].Prospect_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.PROSPECT, dfrList[0].TAL_Entered_From__c, 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].SAL_Entered_From__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].TAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].SAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].EOL_Entered_From__c), 'DFR created with incorrect data');
        System.assert(!String.isEmpty(dfrList[0].MQL_Owner_Name__c), 'DFR created with incorrect data');
    }

    @isTest
    static void test_ContactStatusChangeFrom5ReNewTo15CallOutSDROwner_DFRChangesFromMQLToTAL() {
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
            
        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Contact_Status__c, '.5 Re-New')
            .setField(Contact.OwnerId, sdrUser.Id)
            .create()
            .getRecord();

        Test.getEventBus().deliver();

        con.Contact_Status__c = '1.5 Call Out';
        update con;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<Contact> contactsCreated = (List<Contact>) new ContactSelector()
            .selectContactsByIdsForStatusUpdate(new List<Object>{ new List<id>{ con.id } })
            .executeQuery();
        System.assert(!contactsCreated.isEmpty(), 'Contact creation failed');
        System.assertEquals(
            '1.5 Call Out',
            contactsCreated[0].Contact_Status__c,
            'Contact created with incorrect data'
        );

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'Contact_Name_on_Creation__c',
                'Contact_Email_on_Creation__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c',
                'Prospect_Entered_From__c',
                'Prospect_Exited_To__c',
                'MQL_Entered_From__c',
                'MQL_Exited_To__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'EOL_Entered_From__c',
                'MQL_Owner_Team__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(
            Test_DemandFunnelHelper.TALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DFR created with incorrect data'
        );
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR created with incorrect data');
        System.assert(!String.isEmpty(dfrList[0].MQL_Owner_Team__c), 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].MQL_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.TAL, dfrList[0].MQL_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.MQL, dfrList[0].TAL_Entered_From__c, 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].SAL_Entered_From__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].TAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].SAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].EOL_Entered_From__c), 'DFR created with incorrect data');
    }

    @isTest
    static void test_ContactStatusChangeFrom5ReNewTo2ContactedSDROwner_DFRChangesFromMQLToTAL() {
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
            
        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Contact_Status__c, '.5 Re-New')
            .setField(Contact.OwnerId, sdrUser.Id)
            .create()
            .getRecord();

        Test.getEventBus().deliver();
        con.Contact_Status__c = '2. Contacted';
        update con;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<Contact> contactsCreated = (List<Contact>) new ContactSelector()
            .selectContactsByIdsForStatusUpdate(new List<Object>{ new List<id>{ con.id } })
            .executeQuery();
        System.assert(!contactsCreated.isEmpty(), 'Contact creation failed');
        System.assertEquals(
            '2. Contacted',
            contactsCreated[0].Contact_Status__c,
            'Contact created with incorrect data'
        );

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'Contact_Name_on_Creation__c',
                'Contact_Email_on_Creation__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c',
                'Prospect_Entered_From__c',
                'Prospect_Exited_To__c',
                'MQL_Entered_From__c',
                'MQL_Exited_To__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'EOL_Entered_From__c',
                'MQL_Owner_Team__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(
            Test_DemandFunnelHelper.TALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DFR created with incorrect data'
        );
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR created with incorrect data');
        System.assert(!String.isEmpty(dfrList[0].MQL_Owner_Team__c), 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].MQL_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.TAL, dfrList[0].MQL_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.MQL, dfrList[0].TAL_Entered_From__c, 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].SAL_Entered_From__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].TAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].SAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].EOL_Entered_From__c), 'DFR created with incorrect data');
    }

    @isTest
    static void test_ContactStatusChangeFrom1NewTo15CallOutSDROwner_DFRChangesFromMQLToTAL() {
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
            
        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Contact_Status__c, '1. New')
            .setField(Contact.OwnerId, sdrUser.Id)
            .create()
            .getRecord();

        Test.getEventBus().deliver();
        con.Contact_Status__c = '1.5 Call Out';
        update con;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<Contact> contactsCreated = (List<Contact>) new ContactSelector()
            .selectContactsByIdsForStatusUpdate(new List<Object>{ new List<id>{ con.id } })
            .executeQuery();
        System.assert(!contactsCreated.isEmpty(), 'Contact creation failed');
        System.assertEquals(
            '1.5 Call Out',
            contactsCreated[0].Contact_Status__c,
            'Contact created with incorrect data'
        );

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'Contact_Name_on_Creation__c',
                'Contact_Email_on_Creation__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c',
                'Prospect_Entered_From__c',
                'Prospect_Exited_To__c',
                'MQL_Entered_From__c',
                'MQL_Exited_To__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'EOL_Entered_From__c',
                'MQL_Owner_Team__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(
            Test_DemandFunnelHelper.TALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DFR created with incorrect data'
        );
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR created with incorrect data');
        System.assert(!String.isEmpty(dfrList[0].MQL_Owner_Team__c), 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].MQL_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.TAL, dfrList[0].MQL_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.MQL, dfrList[0].TAL_Entered_From__c, 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].SAL_Entered_From__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].TAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].SAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].EOL_Entered_From__c), 'DFR created with incorrect data');
    }

    @isTest
    static void test_ContactStatusChangeFrom1NewTo2ContactedSDROwner_DFRChangesFromMQLToTAL() {
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
            
        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Contact_Status__c, '1. New')
            .setField(Contact.OwnerId, sdrUser.Id)
            .create()
            .getRecord();

        Test.getEventBus().deliver();
        con.Contact_Status__c = '2. Contacted';
        update con;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<Contact> contactsCreated = (List<Contact>) new ContactSelector()
            .selectContactsByIdsForStatusUpdate(new List<Object>{ new List<id>{ con.id } })
            .executeQuery();
        System.assert(!contactsCreated.isEmpty(), 'Contact creation failed');
        System.assertEquals(
            '2. Contacted',
            contactsCreated[0].Contact_Status__c,
            'Contact created with incorrect data'
        );

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'Contact_Name_on_Creation__c',
                'Contact_Email_on_Creation__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c',
                'Prospect_Entered_From__c',
                'Prospect_Exited_To__c',
                'MQL_Entered_From__c',
                'MQL_Exited_To__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'EOL_Entered_From__c',
                'MQL_Owner_Team__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(
            Test_DemandFunnelHelper.TALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DFR created with incorrect data'
        );
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR created with incorrect data');
        System.assert(!String.isEmpty(dfrList[0].MQL_Owner_Team__c), 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].MQL_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.TAL, dfrList[0].MQL_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.MQL, dfrList[0].TAL_Entered_From__c, 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].SAL_Entered_From__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].TAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].SAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].EOL_Entered_From__c), 'DFR created with incorrect data');
    }

    @isTest
    static void test_ContactStatusChangeFrom15CallOutToXOpenSDROwner_DFRNoChange() {
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
            
        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Contact_Status__c, '1.5 Call Out')
            .setField(Contact.OwnerId, sdrUser.Id)
            .create()
            .getRecord();

        Test.getEventBus().deliver();
        con.Contact_Status__c = 'X. Open';
        update con;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<Contact> contactsCreated = (List<Contact>) new ContactSelector()
            .selectContactsByIdsForStatusUpdate(new List<Object>{ new List<id>{ con.id } })
            .executeQuery();
        System.assert(!contactsCreated.isEmpty(), 'Contact creation failed');
        System.assertEquals('X. Open', contactsCreated[0].Contact_Status__c, 'Contact created with incorrect data');

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{ 'Contact_Name_on_Creation__c', 'LastModifiedDate' }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
    }

    @isTest
    static void test_ContactStatusChangeFrom0DowngradedTo5ReNewSDROwner_DFRCreatedInMQL() {
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
            
        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Contact_Status__c, '0. Downgraded')
            .setField(Contact.OwnerId, sdrUser.Id)
            .create()
            .getRecord();

        System.assertEquals(sdrUser.Id, con.OwnerId, 'Contact created with incorrect Owner');
        System.assertEquals('0. Downgraded', con.Contact_Status__c, 'Contact created with incorrect Status');

        con.Contact_Status__c = '.5 Re-New';
        update con;
        Test.getEventBus().deliver();
        List<Contact> contactsReNew = (List<Contact>) new ContactSelector()
            .selectContactsByIdsForStatusUpdate(new List<Object>{ new List<id>{ con.id } })
            .executeQuery();
        System.assert(!contactsReNew.isEmpty(), 'Contact creation failed');
        System.assertEquals('.5 Re-New', contactsReNew[0].Contact_Status__c, 'Contact created with incorrect data');

        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'DET_Current_Funnel_Status__c',
                'Prospect_Entered_From__c',
                'Prospect_Exited_To__c',
                'Prospect_Owner_Name__c',
                'MQL_Type__c',
                'MQL_Entered_From__c',
                'MQL_Owner_Name__c',
                'SAL_Entered_From__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(
            Test_DemandFunnelHelper.MQLFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DFR created with incorrect data'
        );
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'DFR created with incorrect data');
        System.assert(!String.isEmpty(dfrList[0].Prospect_Owner_Name__c), 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.RENEW, dfrList[0].MQL_Type__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].MQL_Entered_From__c, 'DFR created with incorrect data');
        System.assert(!String.isEmpty(dfrList[0].MQL_Owner_Name__c), 'DFR created with incorrect data');
    }

    @isTest
    static void test_ContactStatusChangeFrom0DowngradedTo5ReNewTo15CallOutSDROwner_DFRCreatedInMQLChangesToTAL() {
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
            
        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Contact_Status__c, '0. Downgraded')
            .setField(Contact.OwnerId, sdrUser.Id)
            .create()
            .getRecord();

        System.assertEquals(sdrUser.Id, con.OwnerId, 'Contact created with incorrect Owner');
        System.assertEquals('0. Downgraded', con.Contact_Status__c, 'Contact created with incorrect Status');

        con.Contact_Status__c = '.5 Re-New';
        update con;
        Test.getEventBus().deliver();
        List<Contact> contactsReNew = (List<Contact>) new ContactSelector()
            .selectContactsByIdsForStatusUpdate(new List<Object>{ new List<id>{ con.id } })
            .executeQuery();
        System.assert(!contactsReNew.isEmpty(), 'Contact creation failed');
        System.assertEquals('.5 Re-New', contactsReNew[0].Contact_Status__c, 'Contact created with incorrect data');

        con.Contact_Status__c = '1.5 Call Out';
        update con;
        Test.getEventBus().deliver();
        List<Contact> contacts15CallOut = (List<Contact>) new ContactSelector()
            .selectContactsByIdsForStatusUpdate(new List<Object>{ new List<id>{ con.id } })
            .executeQuery();
        System.assert(!contacts15CallOut.isEmpty(), 'Contact creation failed');
        System.assertEquals(
            '1.5 Call Out',
            contacts15CallOut[0].Contact_Status__c,
            'Contact created with incorrect data'
        );
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'DET_Current_Funnel_Status__c',
                'Prospect_Entered_From__c',
                'Prospect_Exited_To__c',
                'Prospect_Owner_Name__c',
                'MQL_Type__c',
                'MQL_Entered_From__c',
                'MQL_Owner_Name__c',
                'TAL_Entered_From__c',
                'TAL_Owner_Name__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(
            Test_DemandFunnelHelper.TALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DFR created with incorrect data'
        );
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'DFR created with incorrect data');
        System.assert(!String.isEmpty(dfrList[0].Prospect_Owner_Name__c), 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.RENEW, dfrList[0].MQL_Type__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].MQL_Entered_From__c, 'DFR created with incorrect data');
        System.assert(!String.isEmpty(dfrList[0].MQL_Owner_Name__c), 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.MQL, dfrList[0].TAL_Entered_From__c, 'DFR created with incorrect data');
        System.assert(!String.isEmpty(dfrList[0].TAL_Owner_Name__c), 'DFR created with incorrect data');
    }

    @isTest
    static void test_ContactStatusChangeFrom0DowngradedTo5ReNewTo2ContactedSDROwner_DFRCreatedInMQLChangesToTAL() {
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
            
        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Contact_Status__c, '0. Downgraded')
            .setField(Contact.OwnerId, sdrUser.Id)
            .create()
            .getRecord();

        System.assertEquals(sdrUser.Id, con.OwnerId, 'Contact created with incorrect Owner');
        System.assertEquals('0. Downgraded', con.Contact_Status__c, 'Contact created with incorrect Status');

        con.Contact_Status__c = '.5 Re-New';
        update con;
        Test.getEventBus().deliver();
        List<Contact> contactsReNew = (List<Contact>) new ContactSelector()
            .selectContactsByIdsForStatusUpdate(new List<Object>{ new List<id>{ con.id } })
            .executeQuery();
        System.assert(!contactsReNew.isEmpty(), 'Contact creation failed');
        System.assertEquals('.5 Re-New', contactsReNew[0].Contact_Status__c, 'Contact created with incorrect data');

        con.Contact_Status__c = '2. Contacted';
        update con;
        Test.getEventBus().deliver();
        List<Contact> contactsContacted = (List<Contact>) new ContactSelector()
            .selectContactsByIdsForStatusUpdate(new List<Object>{ new List<id>{ con.id } })
            .executeQuery();
        System.assert(!contactsContacted.isEmpty(), 'Contact creation failed');
        System.assertEquals(
            '2. Contacted',
            contactsContacted[0].Contact_Status__c,
            'Contact created with incorrect data'
        );
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'DET_Current_Funnel_Status__c',
                'Prospect_Entered_From__c',
                'Prospect_Exited_To__c',
                'Prospect_Owner_Name__c',
                'MQL_Type__c',
                'MQL_Entered_From__c',
                'MQL_Owner_Name__c',
                'TAL_Entered_From__c',
                'TAL_Owner_Name__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(
            Test_DemandFunnelHelper.TALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DFR created with incorrect data'
        );
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'DFR created with incorrect data');
        System.assert(!String.isEmpty(dfrList[0].Prospect_Owner_Name__c), 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.RENEW, dfrList[0].MQL_Type__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].MQL_Entered_From__c, 'DFR created with incorrect data');
        System.assert(!String.isEmpty(dfrList[0].MQL_Owner_Name__c), 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.MQL, dfrList[0].TAL_Entered_From__c, 'DFR created with incorrect data');
        System.assert(!String.isEmpty(dfrList[0].TAL_Owner_Name__c), 'DFR created with incorrect data');
    }

    @isTest
    static void test_ContactStatusChangeFromXSuspectTo15CallOutSDROwner_DFRCreatedInTAL() {
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];
        Account testAccount = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Test.startTest();
        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Opty test contact',
                    Contact.AccountId => testAccount.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '+18885550505',
                    Contact.CurrencyIsoCode => 'USD',
                    Contact.Contact_Status__c => 'X. Suspect',
                    Contact.OwnerId => sdrUser.Id
                }
            )
            .create()
            .getRecord();

        testContact.Contact_Status__c = '1.5 Call Out';
        update testContact;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ testContact },
            new List<String>{
                'DET_Current_Funnel_Status__c',
                'Prospect_Owner_Name__c',
                'Contact_Name_on_Creation__c',
                'Contact_Email_on_Creation__c',
                'MQL_Owner_Name__c',
                'SAL_Owner_Name__c',
                'Prospect_Entered_From__c',
                'Prospect_Exited_To__c',
                'MQL_Entered_From__c',
                'MQL_Exited_To__c',
                'TAL_Entered_From__c',
                'TAL_Owner_Name__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(
            testContact.FirstName +
            ' ' +
            testContact.LastName,
            dfrList[0].Contact_Name_on_Creation__c,
            'DFR created with incorrect data'
        );
        System.assertEquals(
            testContact.Email,
            dfrList[0].Contact_Email_on_Creation__c,
            'DFR created with incorrect data'
        );
        System.assertEquals(
            Test_DemandFunnelHelper.TALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DFR created with incorrect data'
        );
        System.assert(!String.isEmpty(dfrList[0].Prospect_Owner_Name__c), 'DFR created with incorrect data');
        System.assert(!String.isEmpty(dfrList[0].MQL_Owner_Name__c), 'DFR created with incorrect data');
        System.assert(!String.isEmpty(dfrList[0].TAL_Owner_Name__c), 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].TAL_Entered_From__c, 'DFR created with incorrect data');
    }

    @isTest
    static void test_ContactStatusChangeFromXSuspectTo2ContactedSDROwner_DFRCreatedInTAL() {
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];
        Account testAccount = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Test.startTest();
        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Opty test contact',
                    Contact.AccountId => testAccount.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '+18885550505',
                    Contact.CurrencyIsoCode => 'USD',
                    Contact.Contact_Status__c => 'X. Suspect',
                    Contact.OwnerId => sdrUser.Id
                }
            )
            .create()
            .getRecord();

        testContact.Contact_Status__c = '2. Contacted';
        update testContact;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ testContact },
            new List<String>{
                'DET_Current_Funnel_Status__c',
                'Prospect_Owner_Name__c',
                'Contact_Name_on_Creation__c',
                'Contact_Email_on_Creation__c',
                'MQL_Owner_Name__c',
                'SAL_Owner_Name__c',
                'Prospect_Entered_From__c',
                'Prospect_Exited_To__c',
                'MQL_Entered_From__c',
                'MQL_Exited_To__c',
                'TAL_Entered_From__c',
                'TAL_Owner_Name__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(
            testContact.FirstName +
            ' ' +
            testContact.LastName,
            dfrList[0].Contact_Name_on_Creation__c,
            'DFR created with incorrect data'
        );
        System.assertEquals(
            testContact.Email,
            dfrList[0].Contact_Email_on_Creation__c,
            'DFR created with incorrect data'
        );
        System.assertEquals(
            Test_DemandFunnelHelper.TALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DFR created with incorrect data'
        );
        System.assert(!String.isEmpty(dfrList[0].Prospect_Owner_Name__c), 'DFR created with incorrect data');
        System.assert(!String.isEmpty(dfrList[0].MQL_Owner_Name__c), 'DFR created with incorrect data');
        System.assert(!String.isEmpty(dfrList[0].TAL_Owner_Name__c), 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].TAL_Entered_From__c, 'DFR created with incorrect data');
    }

    @isTest
    static void test_ContactStatusChangeFromXSuspectToXOpen_DFRCreatedInProspect() {
        Account testAccount = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Test.startTest();
        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Opty test contact',
                    Contact.AccountId => testAccount.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '+18885550505',
                    Contact.CurrencyIsoCode => 'USD',
                    Contact.Contact_Status__c => 'X. Suspect'
                }
            )
            .create()
            .getRecord();

        testContact.Contact_Status__c = 'X. Open';
        update testContact;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ testContact },
            new List<String>{
                'DET_Current_Funnel_Status__c',
                'Prospect_Owner_Name__c',
                'Contact_Name_on_Creation__c',
                'Contact_Email_on_Creation__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(
            testContact.FirstName +
            ' ' +
            testContact.LastName,
            dfrList[0].Contact_Name_on_Creation__c,
            'DFR created with incorrect data'
        );
        System.assertEquals(
            testContact.Email,
            dfrList[0].Contact_Email_on_Creation__c,
            'DFR created with incorrect data'
        );
        System.assertEquals(
            Test_DemandFunnelHelper.PROSPECTFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DFR created with incorrect data'
        );
        System.assert(!String.isEmpty(dfrList[0].Prospect_Owner_Name__c), 'DFR created with incorrect data');
    }

    @isTest
    static void test_ContactStatusChangeFromXSuspectTo0Downgraded_DFRNotCreated() {
        Account testAccount = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Test.startTest();
        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Opty test contact',
                    Contact.AccountId => testAccount.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '+18885550505',
                    Contact.CurrencyIsoCode => 'USD',
                    Contact.Contact_Status__c => 'X. Suspect'
                }
            )
            .create()
            .getRecord();

        testContact.Contact_Status__c = '0. Downgraded';
        update testContact;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ testContact },
            new List<String>{
                'DET_Current_Funnel_Status__c',
                'Prospect_Owner_Name__c',
                'Contact_Name_on_Creation__c',
                'Contact_Email_on_Creation__c'
            }
        );
        System.assert(dfrList.isEmpty(), 'DFR should not be created');
    }

    @isTest
    static void test_ContactStatusChangeFromXSuspectTo5ReNew_DFRCreatedInMQL() {
        Account testAccount = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Test.startTest();
        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Opty test contact',
                    Contact.AccountId => testAccount.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '+18885550505',
                    Contact.CurrencyIsoCode => 'USD',
                    Contact.Contact_Status__c => 'X. Suspect'
                }
            )
            .create()
            .getRecord();

        testContact.Contact_Status__c = '.5 Re-New';
        update testContact;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ testContact },
            new List<String>{
                'DET_Current_Funnel_Status__c',
                'Prospect_Owner_Name__c',
                'Contact_Name_on_Creation__c',
                'Contact_Email_on_Creation__c',
                'MQL_Owner_Name__c',
                'Prospect_Entered_From__c',
                'Prospect_Exited_To__c',
                'MQL_Entered_From__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(
            testContact.FirstName +
            ' ' +
            testContact.LastName,
            dfrList[0].Contact_Name_on_Creation__c,
            'DFR created with incorrect data'
        );
        System.assertEquals(
            testContact.Email,
            dfrList[0].Contact_Email_on_Creation__c,
            'DFR created with incorrect data'
        );
        System.assertEquals(
            Test_DemandFunnelHelper.MQLFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DFR created with incorrect data'
        );
        System.assert(!String.isEmpty(dfrList[0].Prospect_Owner_Name__c), 'DFR created with incorrect data');
        System.assert(!String.isEmpty(dfrList[0].MQL_Owner_Name__c), 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].MQL_Entered_From__c, 'DFR created with incorrect data');
    }

    @isTest
    static void test_ContactStatusChangeFromXSuspectTo1New_DFRCretedInMQL() {
        Account testAccount = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Test.startTest();
        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Opty test contact',
                    Contact.AccountId => testAccount.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '+18885550505',
                    Contact.CurrencyIsoCode => 'USD',
                    Contact.Contact_Status__c => 'X. Suspect'
                }
            )
            .create()
            .getRecord();

        testContact.Contact_Status__c = '1. New';
        update testContact;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ testContact },
            new List<String>{
                'DET_Current_Funnel_Status__c',
                'Prospect_Owner_Name__c',
                'Contact_Name_on_Creation__c',
                'Contact_Email_on_Creation__c',
                'MQL_Owner_Name__c',
                'Prospect_Entered_From__c',
                'Prospect_Exited_To__c',
                'MQL_Entered_From__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(
            testContact.FirstName +
            ' ' +
            testContact.LastName,
            dfrList[0].Contact_Name_on_Creation__c,
            'DFR created with incorrect data'
        );
        System.assertEquals(
            testContact.Email,
            dfrList[0].Contact_Email_on_Creation__c,
            'DFR created with incorrect data'
        );
        System.assertEquals(
            Test_DemandFunnelHelper.MQLFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DFR created with incorrect data'
        );
        System.assert(!String.isEmpty(dfrList[0].MQL_Owner_Name__c), 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].MQL_Entered_From__c, 'DFR created with incorrect data');
    }

    @isTest
    static void test_ContactStatusChangeFromXSuspectTo15CallOut_DFRCreatedInSAL() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        Account testAccount = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Test.startTest();
        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Opty test contact',
                    Contact.AccountId => testAccount.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '+18885550505',
                    Contact.CurrencyIsoCode => 'USD',
                    Contact.Contact_Status__c => 'X. Suspect',
                    Contact.OwnerId => aeUser.Id
                }
            )
            .create()
            .getRecord();

        testContact.Contact_Status__c = '1.5 Call Out';
        update testContact;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ testContact },
            new List<String>{
                'DET_Current_Funnel_Status__c',
                'Prospect_Owner_Name__c',
                'Contact_Name_on_Creation__c',
                'Contact_Email_on_Creation__c',
                'MQL_Owner_Name__c',
                'SAL_Owner_Name__c',
                'Prospect_Entered_From__c',
                'Prospect_Exited_To__c',
                'MQL_Entered_From__c',
                'MQL_Exited_To__c',
                'SAL_Entered_From__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(
            testContact.FirstName +
            ' ' +
            testContact.LastName,
            dfrList[0].Contact_Name_on_Creation__c,
            'DFR created with incorrect data'
        );
        System.assertEquals(
            testContact.Email,
            dfrList[0].Contact_Email_on_Creation__c,
            'DFR created with incorrect data'
        );
        System.assertEquals(
            Test_DemandFunnelHelper.SALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DFR created with incorrect data'
        );
        System.assert(!String.isEmpty(dfrList[0].Prospect_Owner_Name__c), 'DFR created with incorrect data');
        System.assert(!String.isEmpty(dfrList[0].MQL_Owner_Name__c), 'DFR created with incorrect data');
        System.assert(!String.isEmpty(dfrList[0].SAL_Owner_Name__c), 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].SAL_Entered_From__c, 'DFR created with incorrect data');
    }

    @isTest
    static void test_ContactStatusChangeFromXSuspectTo2Contacted_DFRCreatedInSAL() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        Account testAccount = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Test.startTest();
        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Opty test contact',
                    Contact.AccountId => testAccount.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '+18885550505',
                    Contact.CurrencyIsoCode => 'USD',
                    Contact.Contact_Status__c => 'X. Suspect',
                    Contact.OwnerId => aeUser.Id
                }
            )
            .create()
            .getRecord();

        testContact.Contact_Status__c = '2. Contacted';
        update testContact;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ testContact },
            new List<String>{
                'DET_Current_Funnel_Status__c',
                'Prospect_Owner_Name__c',
                'Contact_Name_on_Creation__c',
                'Contact_Email_on_Creation__c',
                'MQL_Owner_Name__c',
                'SAL_Owner_Name__c',
                'Prospect_Entered_From__c',
                'Prospect_Exited_To__c',
                'MQL_Entered_From__c',
                'MQL_Exited_To__c',
                'SAL_Entered_From__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(
            testContact.FirstName +
            ' ' +
            testContact.LastName,
            dfrList[0].Contact_Name_on_Creation__c,
            'DFR created with incorrect data'
        );
        System.assertEquals(
            testContact.Email,
            dfrList[0].Contact_Email_on_Creation__c,
            'DFR created with incorrect data'
        );
        System.assertEquals(
            Test_DemandFunnelHelper.SALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DFR created with incorrect data'
        );
        System.assert(!String.isEmpty(dfrList[0].Prospect_Owner_Name__c), 'DFR created with incorrect data');
        System.assert(!String.isEmpty(dfrList[0].MQL_Owner_Name__c), 'DFR created with incorrect data');
        System.assert(!String.isEmpty(dfrList[0].SAL_Owner_Name__c), 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].SAL_Entered_From__c, 'DFR created with incorrect data');
    }

    @isTest
    static void test_ContactCreationWithContactStatus15CallOutSDROwner_DFRCreatedInTAL() {
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
            
        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Contact_Status__c, '1.5 Call Out')
            .setField(Contact.OwnerId, sdrUser.Id)
            .create()
            .getRecord();
        Test.stopTest();

        List<Contact> contactsCreated = (List<Contact>) new ContactSelector()
            .selectContactsByIdsForStatusUpdate(new List<Object>{ new List<id>{ con.id } })
            .executeQuery();
        System.assert(!contactsCreated.isEmpty(), 'Contact creation failed');
        System.assertEquals(
            '1.5 Call Out',
            contactsCreated[0].Contact_Status__c,
            'Contact created with incorrect data'
        );

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'Contact_Name_on_Creation__c',
                'Contact_Email_on_Creation__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c',
                'Prospect_Entered_From__c',
                'Prospect_Exited_To__c',
                'MQL_Entered_From__c',
                'MQL_Exited_To__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'EOL_Entered_From__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(
            con.FirstName +
            ' ' +
            con.LastName,
            dfrList[0].Contact_Name_on_Creation__c,
            'DFR created with incorrect data'
        );
        System.assertEquals(con.Email, dfrList[0].Contact_Email_on_Creation__c, 'DFR created with incorrect data');
        System.assertEquals(
            Test_DemandFunnelHelper.TALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DFR created with incorrect data'
        );
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].TAL_Entered_From__c, 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].SAL_Entered_From__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].TAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].SAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].EOL_Entered_From__c), 'DFR created with incorrect data');
    }

    @isTest
    static void test_ContactCreationWithContactStatus2Contacted_DFRCreatedInTAL() {
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
            
        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Contact_Status__c, '2. Contacted')
            .setField(Contact.OwnerId, sdrUser.Id)
            .create()
            .getRecord();
        Test.stopTest();

        List<Contact> contactsCreated = (List<Contact>) new ContactSelector()
            .selectContactsByIdsForStatusUpdate(new List<Object>{ new List<id>{ con.id } })
            .executeQuery();
        System.assert(!contactsCreated.isEmpty(), 'Contact creation failed');
        System.assertEquals(
            '2. Contacted',
            contactsCreated[0].Contact_Status__c,
            'Contact created with incorrect data'
        );

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'Contact_Name_on_Creation__c',
                'Contact_Email_on_Creation__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c',
                'Prospect_Entered_From__c',
                'Prospect_Exited_To__c',
                'MQL_Entered_From__c',
                'MQL_Exited_To__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'EOL_Entered_From__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(
            con.FirstName +
            ' ' +
            con.LastName,
            dfrList[0].Contact_Name_on_Creation__c,
            'DFR created with incorrect data'
        );
        System.assertEquals(con.Email, dfrList[0].Contact_Email_on_Creation__c, 'DFR created with incorrect data');
        System.assertEquals(
            Test_DemandFunnelHelper.TALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DFR created with incorrect data'
        );
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Entered_From__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Exited_To__c, 'DFR created with incorrect data');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].TAL_Entered_From__c, 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].SAL_Entered_From__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].TAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].SAL_Exited_To__c), 'DFR created with incorrect data');
        System.assert(String.isEmpty(dfrList[0].EOL_Entered_From__c), 'DFR created with incorrect data');
    }

    @isTest
    static void test_ContactStatusChangeFrom2ContactedTo15CallOutSDROwner_DFRNoChange() {
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .create()
            .getRecord();

        Test.startTest();
        con.OwnerId = sdrUser.Id;
        con.Contact_Status__c = '1.5 Call Out';
        update con;
        Test.stopTest();

        List<Contact> contactsCreated = (List<Contact>) new ContactSelector()
            .selectContactsByIdsForStatusUpdate(new List<Object>{ new List<id>{ con.id } })
            .executeQuery();
        System.assert(!contactsCreated.isEmpty(), 'Contact creation failed');
        System.assertEquals(
            '1.5 Call Out',
            contactsCreated[0].Contact_Status__c,
            'Contact created with incorrect data'
        );

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'Pre_Opportunity_Status__c',
                'TAL_Entered_From__c',
                'TAL_Owner_Name__c',
                'TAL_Owner_Id__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(Test_DemandFunnelHelper.TAL, dfrList[0].Pre_Opportunity_Status__c);
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].TAL_Entered_From__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].TAL_Owner_Name__c);
        System.assertEquals(sdrUser.Id, dfrList[0].TAL_Owner_Id__c);
    }

    @isTest
    static void test_ContactStatusChangeFrom2ContactedTo15CallOut_DFRNoChange() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, aeUser.Id)
            .create()
            .getRecord();

        Test.startTest();
        con.Contact_Status__c = '1.5 Call Out';
        update con;
        Test.stopTest();

        List<Contact> contactsCreated = (List<Contact>) new ContactSelector()
            .selectContactsByIdsForStatusUpdate(new List<Object>{ new List<id>{ con.id } })
            .executeQuery();
        System.assert(!contactsCreated.isEmpty(), 'Contact creation failed');
        System.assertEquals(
            '1.5 Call Out',
            contactsCreated[0].Contact_Status__c,
            'Contact created with incorrect data'
        );

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'Pre_Opportunity_Status__c',
                'SAL_Entered_From__c',
                'SAL_Owner_Name__c',
                'SAL_Owner_Id__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(Test_DemandFunnelHelper.SAL, dfrList[0].Pre_Opportunity_Status__c);
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].SAL_Entered_From__c);
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].SAL_Owner_Name__c);
        System.assertEquals(aeUser.Id, dfrList[0].SAL_Owner_Id__c);
    }

    @isTest
    static void test_ContactCreationWithContactStatus15CallOut_DFRCreatedInSAL() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, aeUser.Id)
            .setField(Contact.Contact_Status__c, '1.5 Call Out')
            .create()
            .getRecord();
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'Pre_Opportunity_Status__c',
                'SAL_Entered_From__c',
                'SAL_Owner_Name__c',
                'SAL_Owner_Id__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(Test_DemandFunnelHelper.SAL, dfrList[0].Pre_Opportunity_Status__c);
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].SAL_Entered_From__c);
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].SAL_Owner_Name__c);
        System.assertEquals(aeUser.Id, dfrList[0].SAL_Owner_Id__c);
    }

    //CRM-13123 #1
    @isTest
    static void ContactStatus_2Contacted_ChangeOwner_UserBDR_to_UserSDR() {
        User bdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.BDRLASTNAME })
            .executeQuery()[0];
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, sdrUser.Id)
            .setField(Contact.Contact_Status__c, '2. Contacted')
            .create()
            .getRecord();

        Test.startTest();
        con.OwnerId = bdrUser.Id;
        update con;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'DFR_Active_Status__c',
                'DET_Current_Funnel_Status__c',
                'MQL_Owner_Team__c',
                'SAL_Owner_Id__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(Test_DemandFunnelHelper.TALFUNNELSTATUS, dfrList[0].DET_Current_Funnel_Status__c);
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c);
        System.assert(dfrList[0].MQL_Owner_Team__c.contains('SDR'));
    }

    //CRM-13123 #2
    @isTest
    static void ContactStatus_2Contacted_ChangeOwner_UserSDR_to_UserAE() {
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, sdrUser.Id)
            .setField(Contact.Contact_Status__c, '2. Contacted')
            .create()
            .getRecord();

        Test.startTest();
        con.OwnerId = aeUser.Id;
        update con;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'DFR_Active_Status__c',
                'DET_Current_Funnel_Status__c',
                'MQL_Owner_Team__c',
                'SAL_Owner_Id__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(Test_DemandFunnelHelper.SALFUNNELSTATUS, dfrList[0].DET_Current_Funnel_Status__c);
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c);
        System.assert(dfrList[0].MQL_Owner_Team__c.contains('SDR'));
    }

    //CRM-13123 #3
    @isTest
    static void ContactStatus_15CallOut_ChangeOwner_UserSDR_to_UserBDR() {
        User bdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.BDRLASTNAME })
            .executeQuery()[0];
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, sdrUser.Id)
            .setField(Contact.Contact_Status__c, '1.5 Call Out')
            .create()
            .getRecord();

        Test.startTest();
        con.OwnerId = bdrUser.Id;
        update con;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'DFR_Active_Status__c',
                'DET_Current_Funnel_Status__c',
                'MQL_Owner_Team__c',
                'SAL_Owner_Id__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(Test_DemandFunnelHelper.TALFUNNELSTATUS, dfrList[0].DET_Current_Funnel_Status__c);
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c);
        System.assert(dfrList[0].MQL_Owner_Team__c.contains('SDR'));
    }

    //CRM-13123 #4
    @isTest
    static void ContactStatus_15CallOut_ChangeOwner_UserSDR_to_UserAE() {
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, sdrUser.Id)
            .setField(Contact.Contact_Status__c, '1.5 Call Out')
            .create()
            .getRecord();

        Test.startTest();
        con.OwnerId = aeUser.Id;
        update con;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'DFR_Active_Status__c',
                'DET_Current_Funnel_Status__c',
                'MQL_Owner_Team__c',
                'SAL_Owner_Id__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(Test_DemandFunnelHelper.SALFUNNELSTATUS, dfrList[0].DET_Current_Funnel_Status__c);
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c);
        System.assert(dfrList[0].MQL_Owner_Team__c.contains('SDR'));
    }

    //CRM-13123 #5
    @isTest
    static void ContactStatus_1New_ChangeOwner_UserBDR_to_UserSDR() {
        User bdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.BDRLASTNAME })
            .executeQuery()[0];
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, bdrUser.Id)
            .setField(Contact.Contact_Status__c, '1. New')
            .create()
            .getRecord();

        Test.startTest();
        con.OwnerId = sdrUser.Id;
        update con;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'DFR_Active_Status__c',
                'SAL_AID__c',
                'SAL_BACKFILLED__c',
                'SAL_Behavior_Score__c',
                'SAL_BMID__c',
                'SAL_Campaign__c',
                'SAL_Channel__c',
                'SAL_Created_to_Entry__c',
                'SAL_Created_to_Exit__c',
                'SAL_DateTime_Entered__c',
                'SAL_DateTime_Exited__c',
                'SAL_Demographic_Score__c',
                'SAL_Employee_Size__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'SAL_isContact__c',
                'SAL_Lead_Entry_Source__c',
                'SAL_Lead_Score_Category__c',
                'SAL_Lead_Source__c',
                'SAL_Marketing_Asset__c',
                'SAL_Owner_Division__c',
                'SAL_Owner_Id__c',
                'SAL_Owner_Name__c',
                'SAL_Owner_Role__c',
                'SAL_Owner_Segment__c',
                'SAL_Owner_Team__c',
                'SAL_PID__c',
                'SAL_Purchase_Timeframe__c',
                'SAL_Score__c',
                'SAL_Status_Duration__c',
                'SAL_Status_Duration_Minutes__c',
                'SAL_SubChannel__c',
                'SAL_Vendor__c',
                'SAL_Handoff_Date__c',
                'SAL_Handoff_Owner__c',
                'SAL_Handoff_Owner_Role__c',
                'SAL_Owner_Territory__c',
                'SAL_Type__c',
                'TAL_AID__c',
                'SAL_BACKFILLED__c',
                'TAL_Behavior_Score__c',
                'TAL_BMID__c',
                'TAL_Campaign__c',
                'TAL_Created_to_Entry__c',
                'TAL_Created_to_Exit__c',
                'TAL_DateTime_Entered__c',
                'TAL_DateTime_Exited__c',
                'TAL_Demographic_Score__c',
                'TAL_Employee_Size__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'TAL_Lead_Entry_Source__c',
                'TAL_Lead_Score_Category__c',
                'TAL_Lead_Source__c',
                'TAL_Marketing_Asset__c',
                'TAL_Owner_Division__c',
                'TAL_Owner_Id__c',
                'TAL_Owner_Name__c',
                'TAL_Owner_Role__c',
                'TAL_Owner_Segment__c',
                'TAL_Owner_Team__c',
                'TAL_PID__c',
                'TAL_Purchase_Timeframe__c',
                'TAL_Score__c',
                'TAL_Status_Duration__c',
                'TAL_Status_Duration_Minutes__c',
                'TAL_Owner_Territory__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c);
        System.assertEquals(null, dfrList[0].SAL_AID__c);
        System.assertEquals(false, dfrList[0].SAL_BACKFILLED__c);
        System.assertEquals(null, dfrList[0].SAL_Behavior_Score__c);
        System.assertEquals(null, dfrList[0].SAL_BMID__c);
        System.assertEquals(null, dfrList[0].SAL_Campaign__c);
        System.assertEquals(null, dfrList[0].SAL_Channel__c);
        System.assertEquals(null, dfrList[0].SAL_Created_to_Entry__c);
        System.assertEquals(null, dfrList[0].SAL_Created_to_Exit__c);
        System.assertEquals(null, dfrList[0].SAL_DateTime_Entered__c);
        System.assertEquals(null, dfrList[0].SAL_DateTime_Exited__c);
        System.assertEquals(null, dfrList[0].SAL_Demographic_Score__c);
        System.assertEquals(null, dfrList[0].SAL_Employee_Size__c);
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c);
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c);
        System.assertEquals(false, dfrList[0].SAL_isContact__c);
        System.assertEquals(null, dfrList[0].SAL_Lead_Entry_Source__c);
        System.assertEquals(null, dfrList[0].SAL_Lead_Score_Category__c);
        System.assertEquals(null, dfrList[0].SAL_Lead_Source__c);
        System.assertEquals(null, dfrList[0].SAL_Marketing_Asset__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Division__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Name__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Role__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Segment__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].SAL_PID__c);
        System.assertEquals(null, dfrList[0].SAL_Purchase_Timeframe__c);
        System.assertEquals(null, dfrList[0].SAL_Score__c);
        System.assertEquals(null, dfrList[0].SAL_Status_Duration__c);
        System.assertEquals(null, dfrList[0].SAL_Status_Duration_Minutes__c);
        System.assertEquals(null, dfrList[0].SAL_SubChannel__c);
        System.assertEquals(null, dfrList[0].SAL_Vendor__c);
        System.assertEquals(null, dfrList[0].SAL_Handoff_Date__c);
        System.assertEquals(null, dfrList[0].SAL_Handoff_Owner__c);
        System.assertEquals(null, dfrList[0].SAL_Handoff_Owner_Role__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Territory__c);
        System.assertEquals(null, dfrList[0].SAL_Type__c);
        System.assertEquals(null, dfrList[0].TAL_AID__c);
        System.assertEquals(false, dfrList[0].SAL_BACKFILLED__c);
        System.assertEquals(null, dfrList[0].TAL_Behavior_Score__c);
        System.assertEquals(null, dfrList[0].TAL_BMID__c);
        System.assertEquals(null, dfrList[0].TAL_Campaign__c);
        System.assertEquals(null, dfrList[0].TAL_Created_to_Entry__c);
        System.assertEquals(null, dfrList[0].TAL_Created_to_Exit__c);
        System.assertEquals(null, dfrList[0].TAL_DateTime_Entered__c);
        System.assertEquals(null, dfrList[0].TAL_DateTime_Exited__c);
        System.assertEquals(null, dfrList[0].TAL_Demographic_Score__c);
        System.assertEquals(null, dfrList[0].TAL_Employee_Size__c);
        System.assertEquals(null, dfrList[0].TAL_Entered_From__c);
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c);
        System.assertEquals(null, dfrList[0].TAL_Lead_Entry_Source__c);
        System.assertEquals(null, dfrList[0].TAL_Lead_Score_Category__c);
        System.assertEquals(null, dfrList[0].TAL_Lead_Source__c);
        System.assertEquals(null, dfrList[0].TAL_Marketing_Asset__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Division__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Name__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Role__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Segment__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].TAL_PID__c);
        System.assertEquals(null, dfrList[0].TAL_Purchase_Timeframe__c);
        System.assertEquals(null, dfrList[0].TAL_Score__c);
        System.assertEquals(null, dfrList[0].TAL_Status_Duration__c);
        System.assertEquals(null, dfrList[0].TAL_Status_Duration_Minutes__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Territory__c);
    }

    //CRM-13123 #6
    @isTest
    static void ContactStatus_1New_ChangeOwner_UserSDR_to_UserAE() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, sdrUser.Id)
            .setField(Contact.Contact_Status__c, '1. New')
            .create()
            .getRecord();

        Test.startTest();
        con.OwnerId = aeUser.Id;
        update con;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'DFR_Active_Status__c',
                'SAL_AID__c',
                'SAL_BACKFILLED__c',
                'SAL_Behavior_Score__c',
                'SAL_BMID__c',
                'SAL_Campaign__c',
                'SAL_Channel__c',
                'SAL_Created_to_Entry__c',
                'SAL_Created_to_Exit__c',
                'SAL_DateTime_Entered__c',
                'SAL_DateTime_Exited__c',
                'SAL_Demographic_Score__c',
                'SAL_Employee_Size__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'SAL_isContact__c',
                'SAL_Lead_Entry_Source__c',
                'SAL_Lead_Score_Category__c',
                'SAL_Lead_Source__c',
                'SAL_Marketing_Asset__c',
                'SAL_Owner_Division__c',
                'SAL_Owner_Id__c',
                'SAL_Owner_Name__c',
                'SAL_Owner_Role__c',
                'SAL_Owner_Segment__c',
                'SAL_Owner_Team__c',
                'SAL_PID__c',
                'SAL_Purchase_Timeframe__c',
                'SAL_Score__c',
                'SAL_Status_Duration__c',
                'SAL_Status_Duration_Minutes__c',
                'SAL_SubChannel__c',
                'SAL_Vendor__c',
                'SAL_Handoff_Date__c',
                'SAL_Handoff_Owner__c',
                'SAL_Handoff_Owner_Role__c',
                'SAL_Owner_Territory__c',
                'SAL_Type__c',
                'TAL_AID__c',
                'SAL_BACKFILLED__c',
                'TAL_Behavior_Score__c',
                'TAL_BMID__c',
                'TAL_Campaign__c',
                'TAL_Created_to_Entry__c',
                'TAL_Created_to_Exit__c',
                'TAL_DateTime_Entered__c',
                'TAL_DateTime_Exited__c',
                'TAL_Demographic_Score__c',
                'TAL_Employee_Size__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'TAL_Lead_Entry_Source__c',
                'TAL_Lead_Score_Category__c',
                'TAL_Lead_Source__c',
                'TAL_Marketing_Asset__c',
                'TAL_Owner_Division__c',
                'TAL_Owner_Id__c',
                'TAL_Owner_Name__c',
                'TAL_Owner_Role__c',
                'TAL_Owner_Segment__c',
                'TAL_Owner_Team__c',
                'TAL_PID__c',
                'TAL_Purchase_Timeframe__c',
                'TAL_Score__c',
                'TAL_Status_Duration__c',
                'TAL_Status_Duration_Minutes__c',
                'TAL_Owner_Territory__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c);
        System.assertEquals(null, dfrList[0].SAL_AID__c);
        System.assertEquals(false, dfrList[0].SAL_BACKFILLED__c);
        System.assertEquals(null, dfrList[0].SAL_Behavior_Score__c);
        System.assertEquals(null, dfrList[0].SAL_BMID__c);
        System.assertEquals(null, dfrList[0].SAL_Campaign__c);
        System.assertEquals(null, dfrList[0].SAL_Channel__c);
        System.assertEquals(null, dfrList[0].SAL_Created_to_Entry__c);
        System.assertEquals(null, dfrList[0].SAL_Created_to_Exit__c);
        System.assertEquals(null, dfrList[0].SAL_DateTime_Entered__c);
        System.assertEquals(null, dfrList[0].SAL_DateTime_Exited__c);
        System.assertEquals(null, dfrList[0].SAL_Demographic_Score__c);
        System.assertEquals(null, dfrList[0].SAL_Employee_Size__c);
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c);
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c);
        System.assertEquals(false, dfrList[0].SAL_isContact__c);
        System.assertEquals(null, dfrList[0].SAL_Lead_Entry_Source__c);
        System.assertEquals(null, dfrList[0].SAL_Lead_Score_Category__c);
        System.assertEquals(null, dfrList[0].SAL_Lead_Source__c);
        System.assertEquals(null, dfrList[0].SAL_Marketing_Asset__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Division__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Name__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Role__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Segment__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].SAL_PID__c);
        System.assertEquals(null, dfrList[0].SAL_Purchase_Timeframe__c);
        System.assertEquals(null, dfrList[0].SAL_Score__c);
        System.assertEquals(null, dfrList[0].SAL_Status_Duration__c);
        System.assertEquals(null, dfrList[0].SAL_Status_Duration_Minutes__c);
        System.assertEquals(null, dfrList[0].SAL_SubChannel__c);
        System.assertEquals(null, dfrList[0].SAL_Vendor__c);
        System.assertEquals(null, dfrList[0].SAL_Handoff_Date__c);
        System.assertEquals(null, dfrList[0].SAL_Handoff_Owner__c);
        System.assertEquals(null, dfrList[0].SAL_Handoff_Owner_Role__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Territory__c);
        System.assertEquals(null, dfrList[0].SAL_Type__c);
        System.assertEquals(null, dfrList[0].TAL_AID__c);
        System.assertEquals(false, dfrList[0].SAL_BACKFILLED__c);
        System.assertEquals(null, dfrList[0].TAL_Behavior_Score__c);
        System.assertEquals(null, dfrList[0].TAL_BMID__c);
        System.assertEquals(null, dfrList[0].TAL_Campaign__c);
        System.assertEquals(null, dfrList[0].TAL_Created_to_Entry__c);
        System.assertEquals(null, dfrList[0].TAL_Created_to_Exit__c);
        System.assertEquals(null, dfrList[0].TAL_DateTime_Entered__c);
        System.assertEquals(null, dfrList[0].TAL_DateTime_Exited__c);
        System.assertEquals(null, dfrList[0].TAL_Demographic_Score__c);
        System.assertEquals(null, dfrList[0].TAL_Employee_Size__c);
        System.assertEquals(null, dfrList[0].TAL_Entered_From__c);
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c);
        System.assertEquals(null, dfrList[0].TAL_Lead_Entry_Source__c);
        System.assertEquals(null, dfrList[0].TAL_Lead_Score_Category__c);
        System.assertEquals(null, dfrList[0].TAL_Lead_Source__c);
        System.assertEquals(null, dfrList[0].TAL_Marketing_Asset__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Division__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Name__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Role__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Segment__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].TAL_PID__c);
        System.assertEquals(null, dfrList[0].TAL_Purchase_Timeframe__c);
        System.assertEquals(null, dfrList[0].TAL_Score__c);
        System.assertEquals(null, dfrList[0].TAL_Status_Duration__c);
        System.assertEquals(null, dfrList[0].TAL_Status_Duration_Minutes__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Territory__c);
    }

    //CRM-13123 #7
    @isTest
    static void ContactStatus_5ReNew_ChangeOwner_UserBDR_to_UserSDR() {
        User bdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.BDRLASTNAME })
            .executeQuery()[0];
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, bdrUser.Id)
            .setField(Contact.Contact_Status__c, '.5 Re-New')
            .create()
            .getRecord();

        Test.startTest();
        con.OwnerId = sdrUser.Id;
        update con;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'DFR_Active_Status__c',
                'SAL_AID__c',
                'SAL_BACKFILLED__c',
                'SAL_Behavior_Score__c',
                'SAL_BMID__c',
                'SAL_Campaign__c',
                'SAL_Channel__c',
                'SAL_Created_to_Entry__c',
                'SAL_Created_to_Exit__c',
                'SAL_DateTime_Entered__c',
                'SAL_DateTime_Exited__c',
                'SAL_Demographic_Score__c',
                'SAL_Employee_Size__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'SAL_isContact__c',
                'SAL_Lead_Entry_Source__c',
                'SAL_Lead_Score_Category__c',
                'SAL_Lead_Source__c',
                'SAL_Marketing_Asset__c',
                'SAL_Owner_Division__c',
                'SAL_Owner_Id__c',
                'SAL_Owner_Name__c',
                'SAL_Owner_Role__c',
                'SAL_Owner_Segment__c',
                'SAL_Owner_Team__c',
                'SAL_PID__c',
                'SAL_Purchase_Timeframe__c',
                'SAL_Score__c',
                'SAL_Status_Duration__c',
                'SAL_Status_Duration_Minutes__c',
                'SAL_SubChannel__c',
                'SAL_Vendor__c',
                'SAL_Handoff_Date__c',
                'SAL_Handoff_Owner__c',
                'SAL_Handoff_Owner_Role__c',
                'SAL_Owner_Territory__c',
                'SAL_Type__c',
                'TAL_AID__c',
                'SAL_BACKFILLED__c',
                'TAL_Behavior_Score__c',
                'TAL_BMID__c',
                'TAL_Campaign__c',
                'TAL_Created_to_Entry__c',
                'TAL_Created_to_Exit__c',
                'TAL_DateTime_Entered__c',
                'TAL_DateTime_Exited__c',
                'TAL_Demographic_Score__c',
                'TAL_Employee_Size__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'TAL_Lead_Entry_Source__c',
                'TAL_Lead_Score_Category__c',
                'TAL_Lead_Source__c',
                'TAL_Marketing_Asset__c',
                'TAL_Owner_Division__c',
                'TAL_Owner_Id__c',
                'TAL_Owner_Name__c',
                'TAL_Owner_Role__c',
                'TAL_Owner_Segment__c',
                'TAL_Owner_Team__c',
                'TAL_PID__c',
                'TAL_Purchase_Timeframe__c',
                'TAL_Score__c',
                'TAL_Status_Duration__c',
                'TAL_Status_Duration_Minutes__c',
                'TAL_Owner_Territory__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c);
        System.assertEquals(null, dfrList[0].SAL_AID__c);
        System.assertEquals(false, dfrList[0].SAL_BACKFILLED__c);
        System.assertEquals(null, dfrList[0].SAL_Behavior_Score__c);
        System.assertEquals(null, dfrList[0].SAL_BMID__c);
        System.assertEquals(null, dfrList[0].SAL_Campaign__c);
        System.assertEquals(null, dfrList[0].SAL_Channel__c);
        System.assertEquals(null, dfrList[0].SAL_Created_to_Entry__c);
        System.assertEquals(null, dfrList[0].SAL_Created_to_Exit__c);
        System.assertEquals(null, dfrList[0].SAL_DateTime_Entered__c);
        System.assertEquals(null, dfrList[0].SAL_DateTime_Exited__c);
        System.assertEquals(null, dfrList[0].SAL_Demographic_Score__c);
        System.assertEquals(null, dfrList[0].SAL_Employee_Size__c);
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c);
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c);
        System.assertEquals(false, dfrList[0].SAL_isContact__c);
        System.assertEquals(null, dfrList[0].SAL_Lead_Entry_Source__c);
        System.assertEquals(null, dfrList[0].SAL_Lead_Score_Category__c);
        System.assertEquals(null, dfrList[0].SAL_Lead_Source__c);
        System.assertEquals(null, dfrList[0].SAL_Marketing_Asset__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Division__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Name__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Role__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Segment__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].SAL_PID__c);
        System.assertEquals(null, dfrList[0].SAL_Purchase_Timeframe__c);
        System.assertEquals(null, dfrList[0].SAL_Score__c);
        System.assertEquals(null, dfrList[0].SAL_Status_Duration__c);
        System.assertEquals(null, dfrList[0].SAL_Status_Duration_Minutes__c);
        System.assertEquals(null, dfrList[0].SAL_SubChannel__c);
        System.assertEquals(null, dfrList[0].SAL_Vendor__c);
        System.assertEquals(null, dfrList[0].SAL_Handoff_Date__c);
        System.assertEquals(null, dfrList[0].SAL_Handoff_Owner__c);
        System.assertEquals(null, dfrList[0].SAL_Handoff_Owner_Role__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Territory__c);
        System.assertEquals(null, dfrList[0].SAL_Type__c);
        System.assertEquals(null, dfrList[0].TAL_AID__c);
        System.assertEquals(false, dfrList[0].SAL_BACKFILLED__c);
        System.assertEquals(null, dfrList[0].TAL_Behavior_Score__c);
        System.assertEquals(null, dfrList[0].TAL_BMID__c);
        System.assertEquals(null, dfrList[0].TAL_Campaign__c);
        System.assertEquals(null, dfrList[0].TAL_Created_to_Entry__c);
        System.assertEquals(null, dfrList[0].TAL_Created_to_Exit__c);
        System.assertEquals(null, dfrList[0].TAL_DateTime_Entered__c);
        System.assertEquals(null, dfrList[0].TAL_DateTime_Exited__c);
        System.assertEquals(null, dfrList[0].TAL_Demographic_Score__c);
        System.assertEquals(null, dfrList[0].TAL_Employee_Size__c);
        System.assertEquals(null, dfrList[0].TAL_Entered_From__c);
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c);
        System.assertEquals(null, dfrList[0].TAL_Lead_Entry_Source__c);
        System.assertEquals(null, dfrList[0].TAL_Lead_Score_Category__c);
        System.assertEquals(null, dfrList[0].TAL_Lead_Source__c);
        System.assertEquals(null, dfrList[0].TAL_Marketing_Asset__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Division__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Name__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Role__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Segment__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].TAL_PID__c);
        System.assertEquals(null, dfrList[0].TAL_Purchase_Timeframe__c);
        System.assertEquals(null, dfrList[0].TAL_Score__c);
        System.assertEquals(null, dfrList[0].TAL_Status_Duration__c);
        System.assertEquals(null, dfrList[0].TAL_Status_Duration_Minutes__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Territory__c);
    }

    //CRM-13123 #8
    @isTest
    static void ContactStatus_5ReNew_ChangeOwner_UserSDR_to_UserAE() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, sdrUser.Id)
            .setField(Contact.Contact_Status__c, '.5 Re-New')
            .create()
            .getRecord();

        Test.startTest();
        con.OwnerId = aeUser.Id;
        update con;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'DFR_Active_Status__c',
                'SAL_AID__c',
                'SAL_BACKFILLED__c',
                'SAL_Behavior_Score__c',
                'SAL_BMID__c',
                'SAL_Campaign__c',
                'SAL_Channel__c',
                'SAL_Created_to_Entry__c',
                'SAL_Created_to_Exit__c',
                'SAL_DateTime_Entered__c',
                'SAL_DateTime_Exited__c',
                'SAL_Demographic_Score__c',
                'SAL_Employee_Size__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'SAL_isContact__c',
                'SAL_Lead_Entry_Source__c',
                'SAL_Lead_Score_Category__c',
                'SAL_Lead_Source__c',
                'SAL_Marketing_Asset__c',
                'SAL_Owner_Division__c',
                'SAL_Owner_Id__c',
                'SAL_Owner_Name__c',
                'SAL_Owner_Role__c',
                'SAL_Owner_Segment__c',
                'SAL_Owner_Team__c',
                'SAL_PID__c',
                'SAL_Purchase_Timeframe__c',
                'SAL_Score__c',
                'SAL_Status_Duration__c',
                'SAL_Status_Duration_Minutes__c',
                'SAL_SubChannel__c',
                'SAL_Vendor__c',
                'SAL_Handoff_Date__c',
                'SAL_Handoff_Owner__c',
                'SAL_Handoff_Owner_Role__c',
                'SAL_Owner_Territory__c',
                'SAL_Type__c',
                'TAL_AID__c',
                'SAL_BACKFILLED__c',
                'TAL_Behavior_Score__c',
                'TAL_BMID__c',
                'TAL_Campaign__c',
                'TAL_Created_to_Entry__c',
                'TAL_Created_to_Exit__c',
                'TAL_DateTime_Entered__c',
                'TAL_DateTime_Exited__c',
                'TAL_Demographic_Score__c',
                'TAL_Employee_Size__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'TAL_Lead_Entry_Source__c',
                'TAL_Lead_Score_Category__c',
                'TAL_Lead_Source__c',
                'TAL_Marketing_Asset__c',
                'TAL_Owner_Division__c',
                'TAL_Owner_Id__c',
                'TAL_Owner_Name__c',
                'TAL_Owner_Role__c',
                'TAL_Owner_Segment__c',
                'TAL_Owner_Team__c',
                'TAL_PID__c',
                'TAL_Purchase_Timeframe__c',
                'TAL_Score__c',
                'TAL_Status_Duration__c',
                'TAL_Status_Duration_Minutes__c',
                'TAL_Owner_Territory__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c);
        System.assertEquals(null, dfrList[0].SAL_AID__c);
        System.assertEquals(false, dfrList[0].SAL_BACKFILLED__c);
        System.assertEquals(null, dfrList[0].SAL_Behavior_Score__c);
        System.assertEquals(null, dfrList[0].SAL_BMID__c);
        System.assertEquals(null, dfrList[0].SAL_Campaign__c);
        System.assertEquals(null, dfrList[0].SAL_Channel__c);
        System.assertEquals(null, dfrList[0].SAL_Created_to_Entry__c);
        System.assertEquals(null, dfrList[0].SAL_Created_to_Exit__c);
        System.assertEquals(null, dfrList[0].SAL_DateTime_Entered__c);
        System.assertEquals(null, dfrList[0].SAL_DateTime_Exited__c);
        System.assertEquals(null, dfrList[0].SAL_Demographic_Score__c);
        System.assertEquals(null, dfrList[0].SAL_Employee_Size__c);
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c);
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c);
        System.assertEquals(false, dfrList[0].SAL_isContact__c);
        System.assertEquals(null, dfrList[0].SAL_Lead_Entry_Source__c);
        System.assertEquals(null, dfrList[0].SAL_Lead_Score_Category__c);
        System.assertEquals(null, dfrList[0].SAL_Lead_Source__c);
        System.assertEquals(null, dfrList[0].SAL_Marketing_Asset__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Division__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Name__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Role__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Segment__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].SAL_PID__c);
        System.assertEquals(null, dfrList[0].SAL_Purchase_Timeframe__c);
        System.assertEquals(null, dfrList[0].SAL_Score__c);
        System.assertEquals(null, dfrList[0].SAL_Status_Duration__c);
        System.assertEquals(null, dfrList[0].SAL_Status_Duration_Minutes__c);
        System.assertEquals(null, dfrList[0].SAL_SubChannel__c);
        System.assertEquals(null, dfrList[0].SAL_Vendor__c);
        System.assertEquals(null, dfrList[0].SAL_Handoff_Date__c);
        System.assertEquals(null, dfrList[0].SAL_Handoff_Owner__c);
        System.assertEquals(null, dfrList[0].SAL_Handoff_Owner_Role__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Territory__c);
        System.assertEquals(null, dfrList[0].SAL_Type__c);
        System.assertEquals(null, dfrList[0].TAL_AID__c);
        System.assertEquals(false, dfrList[0].SAL_BACKFILLED__c);
        System.assertEquals(null, dfrList[0].TAL_Behavior_Score__c);
        System.assertEquals(null, dfrList[0].TAL_BMID__c);
        System.assertEquals(null, dfrList[0].TAL_Campaign__c);
        System.assertEquals(null, dfrList[0].TAL_Created_to_Entry__c);
        System.assertEquals(null, dfrList[0].TAL_Created_to_Exit__c);
        System.assertEquals(null, dfrList[0].TAL_DateTime_Entered__c);
        System.assertEquals(null, dfrList[0].TAL_DateTime_Exited__c);
        System.assertEquals(null, dfrList[0].TAL_Demographic_Score__c);
        System.assertEquals(null, dfrList[0].TAL_Employee_Size__c);
        System.assertEquals(null, dfrList[0].TAL_Entered_From__c);
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c);
        System.assertEquals(null, dfrList[0].TAL_Lead_Entry_Source__c);
        System.assertEquals(null, dfrList[0].TAL_Lead_Score_Category__c);
        System.assertEquals(null, dfrList[0].TAL_Lead_Source__c);
        System.assertEquals(null, dfrList[0].TAL_Marketing_Asset__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Division__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Name__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Role__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Segment__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].TAL_PID__c);
        System.assertEquals(null, dfrList[0].TAL_Purchase_Timeframe__c);
        System.assertEquals(null, dfrList[0].TAL_Score__c);
        System.assertEquals(null, dfrList[0].TAL_Status_Duration__c);
        System.assertEquals(null, dfrList[0].TAL_Status_Duration_Minutes__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Territory__c);
    }

    //CRM-13123 #9
    @isTest
    static void ContactStatus_XOpen_ChangeOwner_UserBDR_to_UserSDR() {
        User bdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.BDRLASTNAME })
            .executeQuery()[0];
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, bdrUser.Id)
            .setField(Contact.Contact_Status__c, 'X. Open')
            .create()
            .getRecord();

        Test.startTest();
        con.OwnerId = sdrUser.Id;
        update con;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'DFR_Active_Status__c',
                'SAL_AID__c',
                'SAL_BACKFILLED__c',
                'SAL_Behavior_Score__c',
                'SAL_BMID__c',
                'SAL_Campaign__c',
                'SAL_Channel__c',
                'SAL_Created_to_Entry__c',
                'SAL_Created_to_Exit__c',
                'SAL_DateTime_Entered__c',
                'SAL_DateTime_Exited__c',
                'SAL_Demographic_Score__c',
                'SAL_Employee_Size__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'SAL_isContact__c',
                'SAL_Lead_Entry_Source__c',
                'SAL_Lead_Score_Category__c',
                'SAL_Lead_Source__c',
                'SAL_Marketing_Asset__c',
                'SAL_Owner_Division__c',
                'SAL_Owner_Id__c',
                'SAL_Owner_Name__c',
                'SAL_Owner_Role__c',
                'SAL_Owner_Segment__c',
                'SAL_Owner_Team__c',
                'SAL_PID__c',
                'SAL_Purchase_Timeframe__c',
                'SAL_Score__c',
                'SAL_Status_Duration__c',
                'SAL_Status_Duration_Minutes__c',
                'SAL_SubChannel__c',
                'SAL_Vendor__c',
                'SAL_Handoff_Date__c',
                'SAL_Handoff_Owner__c',
                'SAL_Handoff_Owner_Role__c',
                'SAL_Owner_Territory__c',
                'SAL_Type__c',
                'TAL_AID__c',
                'TAL_BACKFILLED__c',
                'TAL_Behavior_Score__c',
                'TAL_BMID__c',
                'TAL_Campaign__c',
                'TAL_Created_to_Entry__c',
                'TAL_Created_to_Exit__c',
                'TAL_DateTime_Entered__c',
                'TAL_DateTime_Exited__c',
                'TAL_Demographic_Score__c',
                'TAL_Employee_Size__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'TAL_Lead_Entry_Source__c',
                'TAL_Lead_Score_Category__c',
                'TAL_Lead_Source__c',
                'TAL_Marketing_Asset__c',
                'TAL_Owner_Division__c',
                'TAL_Owner_Id__c',
                'TAL_Owner_Name__c',
                'TAL_Owner_Role__c',
                'TAL_Owner_Segment__c',
                'TAL_Owner_Team__c',
                'TAL_PID__c',
                'TAL_Purchase_Timeframe__c',
                'TAL_Score__c',
                'TAL_Status_Duration__c',
                'TAL_Status_Duration_Minutes__c',
                'TAL_Owner_Territory__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c);
        System.assertEquals(null, dfrList[0].SAL_AID__c);
        System.assertEquals(false, dfrList[0].SAL_BACKFILLED__c);
        System.assertEquals(null, dfrList[0].SAL_Behavior_Score__c);
        System.assertEquals(null, dfrList[0].SAL_BMID__c);
        System.assertEquals(null, dfrList[0].SAL_Campaign__c);
        System.assertEquals(null, dfrList[0].SAL_Channel__c);
        System.assertEquals(null, dfrList[0].SAL_Created_to_Entry__c);
        System.assertEquals(null, dfrList[0].SAL_Created_to_Exit__c);
        System.assertEquals(null, dfrList[0].SAL_DateTime_Entered__c);
        System.assertEquals(null, dfrList[0].SAL_DateTime_Exited__c);
        System.assertEquals(null, dfrList[0].SAL_Demographic_Score__c);
        System.assertEquals(null, dfrList[0].SAL_Employee_Size__c);
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c);
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c);
        System.assertEquals(false, dfrList[0].SAL_isContact__c);
        System.assertEquals(null, dfrList[0].SAL_Lead_Entry_Source__c);
        System.assertEquals(null, dfrList[0].SAL_Lead_Score_Category__c);
        System.assertEquals(null, dfrList[0].SAL_Lead_Source__c);
        System.assertEquals(null, dfrList[0].SAL_Marketing_Asset__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Division__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Name__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Role__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Segment__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].SAL_PID__c);
        System.assertEquals(null, dfrList[0].SAL_Purchase_Timeframe__c);
        System.assertEquals(null, dfrList[0].SAL_Score__c);
        System.assertEquals(null, dfrList[0].SAL_Status_Duration__c);
        System.assertEquals(null, dfrList[0].SAL_Status_Duration_Minutes__c);
        System.assertEquals(null, dfrList[0].SAL_SubChannel__c);
        System.assertEquals(null, dfrList[0].SAL_Vendor__c);
        System.assertEquals(null, dfrList[0].SAL_Handoff_Date__c);
        System.assertEquals(null, dfrList[0].SAL_Handoff_Owner__c);
        System.assertEquals(null, dfrList[0].SAL_Handoff_Owner_Role__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Territory__c);
        System.assertEquals(null, dfrList[0].SAL_Type__c);
        System.assertEquals(null, dfrList[0].TAL_AID__c);
        System.assertEquals(false, dfrList[0].SAL_BACKFILLED__c);
        System.assertEquals(null, dfrList[0].TAL_Behavior_Score__c);
        System.assertEquals(null, dfrList[0].TAL_BMID__c);
        System.assertEquals(null, dfrList[0].TAL_Campaign__c);
        System.assertEquals(null, dfrList[0].TAL_Created_to_Entry__c);
        System.assertEquals(null, dfrList[0].TAL_Created_to_Exit__c);
        System.assertEquals(null, dfrList[0].TAL_DateTime_Entered__c);
        System.assertEquals(null, dfrList[0].TAL_DateTime_Exited__c);
        System.assertEquals(null, dfrList[0].TAL_Demographic_Score__c);
        System.assertEquals(null, dfrList[0].TAL_Employee_Size__c);
        System.assertEquals(null, dfrList[0].TAL_Entered_From__c);
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c);
        System.assertEquals(null, dfrList[0].TAL_Lead_Entry_Source__c);
        System.assertEquals(null, dfrList[0].TAL_Lead_Score_Category__c);
        System.assertEquals(null, dfrList[0].TAL_Lead_Source__c);
        System.assertEquals(null, dfrList[0].TAL_Marketing_Asset__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Division__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Name__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Role__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Segment__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].TAL_PID__c);
        System.assertEquals(null, dfrList[0].TAL_Purchase_Timeframe__c);
        System.assertEquals(null, dfrList[0].TAL_Score__c);
        System.assertEquals(null, dfrList[0].TAL_Status_Duration__c);
        System.assertEquals(null, dfrList[0].TAL_Status_Duration_Minutes__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Territory__c);
    }

    //CRM-13123 #10
    @isTest
    static void ContactStatus_XOpen_ChangeOwner_UserSDR_to_UserAE() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, sdrUser.Id)
            .setField(Contact.Contact_Status__c, 'X. Open')
            .create()
            .getRecord();

        Test.startTest();
        con.OwnerId = aeUser.Id;
        update con;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'DFR_Active_Status__c',
                'SAL_AID__c',
                'SAL_BACKFILLED__c',
                'SAL_Behavior_Score__c',
                'SAL_BMID__c',
                'SAL_Campaign__c',
                'SAL_Channel__c',
                'SAL_Created_to_Entry__c',
                'SAL_Created_to_Exit__c',
                'SAL_DateTime_Entered__c',
                'SAL_DateTime_Exited__c',
                'SAL_Demographic_Score__c',
                'SAL_Employee_Size__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'SAL_isContact__c',
                'SAL_Lead_Entry_Source__c',
                'SAL_Lead_Score_Category__c',
                'SAL_Lead_Source__c',
                'SAL_Marketing_Asset__c',
                'SAL_Owner_Division__c',
                'SAL_Owner_Id__c',
                'SAL_Owner_Name__c',
                'SAL_Owner_Role__c',
                'SAL_Owner_Segment__c',
                'SAL_Owner_Team__c',
                'SAL_PID__c',
                'SAL_Purchase_Timeframe__c',
                'SAL_Score__c',
                'SAL_Status_Duration__c',
                'SAL_Status_Duration_Minutes__c',
                'SAL_SubChannel__c',
                'SAL_Vendor__c',
                'SAL_Handoff_Date__c',
                'SAL_Handoff_Owner__c',
                'SAL_Handoff_Owner_Role__c',
                'SAL_Owner_Territory__c',
                'SAL_Type__c',
                'TAL_AID__c',
                'SAL_BACKFILLED__c',
                'TAL_Behavior_Score__c',
                'TAL_BMID__c',
                'TAL_Campaign__c',
                'TAL_Created_to_Entry__c',
                'TAL_Created_to_Exit__c',
                'TAL_DateTime_Entered__c',
                'TAL_DateTime_Exited__c',
                'TAL_Demographic_Score__c',
                'TAL_Employee_Size__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'TAL_Lead_Entry_Source__c',
                'TAL_Lead_Score_Category__c',
                'TAL_Lead_Source__c',
                'TAL_Marketing_Asset__c',
                'TAL_Owner_Division__c',
                'TAL_Owner_Id__c',
                'TAL_Owner_Name__c',
                'TAL_Owner_Role__c',
                'TAL_Owner_Segment__c',
                'TAL_Owner_Team__c',
                'TAL_PID__c',
                'TAL_Purchase_Timeframe__c',
                'TAL_Score__c',
                'TAL_Status_Duration__c',
                'TAL_Status_Duration_Minutes__c',
                'TAL_Owner_Territory__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c);
        System.assertEquals(null, dfrList[0].SAL_AID__c);
        System.assertEquals(false, dfrList[0].SAL_BACKFILLED__c);
        System.assertEquals(null, dfrList[0].SAL_Behavior_Score__c);
        System.assertEquals(null, dfrList[0].SAL_BMID__c);
        System.assertEquals(null, dfrList[0].SAL_Campaign__c);
        System.assertEquals(null, dfrList[0].SAL_Channel__c);
        System.assertEquals(null, dfrList[0].SAL_Created_to_Entry__c);
        System.assertEquals(null, dfrList[0].SAL_Created_to_Exit__c);
        System.assertEquals(null, dfrList[0].SAL_DateTime_Entered__c);
        System.assertEquals(null, dfrList[0].SAL_DateTime_Exited__c);
        System.assertEquals(null, dfrList[0].SAL_Demographic_Score__c);
        System.assertEquals(null, dfrList[0].SAL_Employee_Size__c);
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c);
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c);
        System.assertEquals(false, dfrList[0].SAL_isContact__c);
        System.assertEquals(null, dfrList[0].SAL_Lead_Entry_Source__c);
        System.assertEquals(null, dfrList[0].SAL_Lead_Score_Category__c);
        System.assertEquals(null, dfrList[0].SAL_Lead_Source__c);
        System.assertEquals(null, dfrList[0].SAL_Marketing_Asset__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Division__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Name__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Role__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Segment__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].SAL_PID__c);
        System.assertEquals(null, dfrList[0].SAL_Purchase_Timeframe__c);
        System.assertEquals(null, dfrList[0].SAL_Score__c);
        System.assertEquals(null, dfrList[0].SAL_Status_Duration__c);
        System.assertEquals(null, dfrList[0].SAL_Status_Duration_Minutes__c);
        System.assertEquals(null, dfrList[0].SAL_SubChannel__c);
        System.assertEquals(null, dfrList[0].SAL_Vendor__c);
        System.assertEquals(null, dfrList[0].SAL_Handoff_Date__c);
        System.assertEquals(null, dfrList[0].SAL_Handoff_Owner__c);
        System.assertEquals(null, dfrList[0].SAL_Handoff_Owner_Role__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Territory__c);
        System.assertEquals(null, dfrList[0].SAL_Type__c);
        System.assertEquals(null, dfrList[0].TAL_AID__c);
        System.assertEquals(false, dfrList[0].SAL_BACKFILLED__c);
        System.assertEquals(null, dfrList[0].TAL_Behavior_Score__c);
        System.assertEquals(null, dfrList[0].TAL_BMID__c);
        System.assertEquals(null, dfrList[0].TAL_Campaign__c);
        System.assertEquals(null, dfrList[0].TAL_Created_to_Entry__c);
        System.assertEquals(null, dfrList[0].TAL_Created_to_Exit__c);
        System.assertEquals(null, dfrList[0].TAL_DateTime_Entered__c);
        System.assertEquals(null, dfrList[0].TAL_DateTime_Exited__c);
        System.assertEquals(null, dfrList[0].TAL_Demographic_Score__c);
        System.assertEquals(null, dfrList[0].TAL_Employee_Size__c);
        System.assertEquals(null, dfrList[0].TAL_Entered_From__c);
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c);
        System.assertEquals(null, dfrList[0].TAL_Lead_Entry_Source__c);
        System.assertEquals(null, dfrList[0].TAL_Lead_Score_Category__c);
        System.assertEquals(null, dfrList[0].TAL_Lead_Source__c);
        System.assertEquals(null, dfrList[0].TAL_Marketing_Asset__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Division__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Name__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Role__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Segment__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].TAL_PID__c);
        System.assertEquals(null, dfrList[0].TAL_Purchase_Timeframe__c);
        System.assertEquals(null, dfrList[0].TAL_Score__c);
        System.assertEquals(null, dfrList[0].TAL_Status_Duration__c);
        System.assertEquals(null, dfrList[0].TAL_Status_Duration_Minutes__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Territory__c);
    }

    //CRM-13123 #11
    @isTest
    static void ContactStatus_2Contacted_ChangeOwner_UserAE_to_UserSDR() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, aeUser.Id)
            .setField(Contact.Contact_Status__c, '2. Contacted')
            .create()
            .getRecord();

        Test.startTest();
        con.OwnerId = sdrUser.Id;
        update con;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'DFR_Active_Status__c',
                'DET_Current_Funnel_Status__c',
                'MQL_Owner_Team__c',
                'SAL_Owner_Id__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(Test_DemandFunnelHelper.SALFUNNELSTATUS, dfrList[0].DET_Current_Funnel_Status__c);
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c);
        System.assert(
            Test_DemandFunnelHelper.isAEUser(dfrList[0].MQL_Owner_Team__c),
            'MQL Owner doesn\'t contains AE. Current value: ' + dfrList[0].MQL_Owner_Team__c
        );
    }

    //CRM-13123 #12
    @isTest
    static void ContactStatus_2Contacted_ChangeOwner_UserAE_to_UserAE() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        User aeUser2 = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME + '2' })
            .executeQuery()[0];

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, aeUser.Id)
            .setField(Contact.Contact_Status__c, '2. Contacted')
            .create()
            .getRecord();

        Test.startTest();
        con.OwnerId = aeUser2.Id;
        update con;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'DFR_Active_Status__c',
                'DET_Current_Funnel_Status__c',
                'MQL_Owner_Team__c',
                'SAL_Owner_Id__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(Test_DemandFunnelHelper.SALFUNNELSTATUS, dfrList[0].DET_Current_Funnel_Status__c);
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c);
        System.assert(
            Test_DemandFunnelHelper.isAEUser(dfrList[0].MQL_Owner_Team__c),
            'MQL Owner doesn\'t contains AE. Current value: ' + dfrList[0].MQL_Owner_Team__c
        );
    }

    //CRM-13123 #13
    @isTest
    static void ContactStatus_15CallOut_ChangeOwner_UserAE_to_UserSDR() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, aeUser.Id)
            .setField(Contact.Contact_Status__c, '1.5 Call Out')
            .create()
            .getRecord();

        Test.startTest();
        con.OwnerId = sdrUser.Id;
        update con;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'DFR_Active_Status__c',
                'DET_Current_Funnel_Status__c',
                'MQL_Owner_Team__c',
                'SAL_Owner_Id__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(Test_DemandFunnelHelper.SALFUNNELSTATUS, dfrList[0].DET_Current_Funnel_Status__c);
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c);
        System.assert(
            Test_DemandFunnelHelper.isAEUser(dfrList[0].MQL_Owner_Team__c),
            'MQL Owner doesn\'t contains AE. Current value: ' + dfrList[0].MQL_Owner_Team__c
        );
    }

    //CRM-13123 #14
    @isTest
    static void ContactStatus_15CallOut_ChangeOwner_UserAE_to_UserAE() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        User aeUser2 = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME + '2' })
            .executeQuery()[0];

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, aeUser.Id)
            .setField(Contact.Contact_Status__c, '1.5 Call Out')
            .create()
            .getRecord();

        Test.startTest();
        con.OwnerId = aeUser2.Id;
        update con;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'DFR_Active_Status__c',
                'DET_Current_Funnel_Status__c',
                'MQL_Owner_Team__c',
                'SAL_Owner_Id__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(Test_DemandFunnelHelper.SALFUNNELSTATUS, dfrList[0].DET_Current_Funnel_Status__c);
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c);
        System.assert(
            Test_DemandFunnelHelper.isAEUser(dfrList[0].MQL_Owner_Team__c),
            'MQL Owner doesn\'t contains AE. Current value: ' + dfrList[0].MQL_Owner_Team__c
        );
    }

    //CRM-13123 #15
    @isTest
    static void ContactStatus_1New_ChangeOwner_UserAE_to_UserSDR() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, aeUser.Id)
            .setField(Contact.Contact_Status__c, '1. New')
            .create()
            .getRecord();

        Test.startTest();
        con.OwnerId = sdrUser.Id;
        update con;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'MQL_Owner_Team__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c',
                'SAL_AID__c',
                'SAL_BACKFILLED__c',
                'SAL_Behavior_Score__c',
                'SAL_BMID__c',
                'SAL_Campaign__c',
                'SAL_Channel__c',
                'SAL_Created_to_Entry__c',
                'SAL_Created_to_Exit__c',
                'SAL_DateTime_Entered__c',
                'SAL_DateTime_Exited__c',
                'SAL_Demographic_Score__c',
                'SAL_Employee_Size__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'SAL_isContact__c',
                'SAL_Lead_Entry_Source__c',
                'SAL_Lead_Score_Category__c',
                'SAL_Lead_Source__c',
                'SAL_Marketing_Asset__c',
                'SAL_Owner_Division__c',
                'SAL_Owner_Id__c',
                'SAL_Owner_Name__c',
                'SAL_Owner_Role__c',
                'SAL_Owner_Segment__c',
                'SAL_Owner_Team__c',
                'SAL_PID__c',
                'SAL_Purchase_Timeframe__c',
                'SAL_Score__c',
                'SAL_Status_Duration__c',
                'SAL_Status_Duration_Minutes__c',
                'SAL_SubChannel__c',
                'SAL_Vendor__c',
                'SAL_Handoff_Date__c',
                'SAL_Handoff_Owner__c',
                'SAL_Handoff_Owner_Role__c',
                'SAL_Owner_Territory__c',
                'SAL_Type__c',
                'TAL_AID__c',
                'SAL_BACKFILLED__c',
                'TAL_Behavior_Score__c',
                'TAL_BMID__c',
                'TAL_Campaign__c',
                'TAL_Created_to_Entry__c',
                'TAL_Created_to_Exit__c',
                'TAL_DateTime_Entered__c',
                'TAL_DateTime_Exited__c',
                'TAL_Demographic_Score__c',
                'TAL_Employee_Size__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'TAL_Lead_Entry_Source__c',
                'TAL_Lead_Score_Category__c',
                'TAL_Lead_Source__c',
                'TAL_Marketing_Asset__c',
                'TAL_Owner_Division__c',
                'TAL_Owner_Id__c',
                'TAL_Owner_Name__c',
                'TAL_Owner_Role__c',
                'TAL_Owner_Segment__c',
                'TAL_Owner_Team__c',
                'TAL_PID__c',
                'TAL_Purchase_Timeframe__c',
                'TAL_Score__c',
                'TAL_Status_Duration__c',
                'TAL_Status_Duration_Minutes__c',
                'TAL_Owner_Territory__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(Test_DemandFunnelHelper.MQLFUNNELSTATUS, dfrList[0].DET_Current_Funnel_Status__c);
        System.assert(
            Test_DemandFunnelHelper.isAEUser(dfrList[0].MQL_Owner_Team__c),
            'MQL Owner doesn\'t contains AE. Current value: ' + dfrList[0].MQL_Owner_Team__c
        );
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c);
        System.assertEquals(null, dfrList[0].SAL_AID__c);
        System.assertEquals(false, dfrList[0].SAL_BACKFILLED__c);
        System.assertEquals(null, dfrList[0].SAL_Behavior_Score__c);
        System.assertEquals(null, dfrList[0].SAL_BMID__c);
        System.assertEquals(null, dfrList[0].SAL_Campaign__c);
        System.assertEquals(null, dfrList[0].SAL_Channel__c);
        System.assertEquals(null, dfrList[0].SAL_Created_to_Entry__c);
        System.assertEquals(null, dfrList[0].SAL_Created_to_Exit__c);
        System.assertEquals(null, dfrList[0].SAL_DateTime_Entered__c);
        System.assertEquals(null, dfrList[0].SAL_DateTime_Exited__c);
        System.assertEquals(null, dfrList[0].SAL_Demographic_Score__c);
        System.assertEquals(null, dfrList[0].SAL_Employee_Size__c);
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c);
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c);
        System.assertEquals(false, dfrList[0].SAL_isContact__c);
        System.assertEquals(null, dfrList[0].SAL_Lead_Entry_Source__c);
        System.assertEquals(null, dfrList[0].SAL_Lead_Score_Category__c);
        System.assertEquals(null, dfrList[0].SAL_Lead_Source__c);
        System.assertEquals(null, dfrList[0].SAL_Marketing_Asset__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Division__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Name__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Role__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Segment__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].SAL_PID__c);
        System.assertEquals(null, dfrList[0].SAL_Purchase_Timeframe__c);
        System.assertEquals(null, dfrList[0].SAL_Score__c);
        System.assertEquals(null, dfrList[0].SAL_Status_Duration__c);
        System.assertEquals(null, dfrList[0].SAL_Status_Duration_Minutes__c);
        System.assertEquals(null, dfrList[0].SAL_SubChannel__c);
        System.assertEquals(null, dfrList[0].SAL_Vendor__c);
        System.assertEquals(null, dfrList[0].SAL_Handoff_Date__c);
        System.assertEquals(null, dfrList[0].SAL_Handoff_Owner__c);
        System.assertEquals(null, dfrList[0].SAL_Handoff_Owner_Role__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Territory__c);
        System.assertEquals(null, dfrList[0].SAL_Type__c);
        System.assertEquals(null, dfrList[0].TAL_AID__c);
        System.assertEquals(false, dfrList[0].SAL_BACKFILLED__c);
        System.assertEquals(null, dfrList[0].TAL_Behavior_Score__c);
        System.assertEquals(null, dfrList[0].TAL_BMID__c);
        System.assertEquals(null, dfrList[0].TAL_Campaign__c);
        System.assertEquals(null, dfrList[0].TAL_Created_to_Entry__c);
        System.assertEquals(null, dfrList[0].TAL_Created_to_Exit__c);
        System.assertEquals(null, dfrList[0].TAL_DateTime_Entered__c);
        System.assertEquals(null, dfrList[0].TAL_DateTime_Exited__c);
        System.assertEquals(null, dfrList[0].TAL_Demographic_Score__c);
        System.assertEquals(null, dfrList[0].TAL_Employee_Size__c);
        System.assertEquals(null, dfrList[0].TAL_Entered_From__c);
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c);
        System.assertEquals(null, dfrList[0].TAL_Lead_Entry_Source__c);
        System.assertEquals(null, dfrList[0].TAL_Lead_Score_Category__c);
        System.assertEquals(null, dfrList[0].TAL_Lead_Source__c);
        System.assertEquals(null, dfrList[0].TAL_Marketing_Asset__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Division__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Name__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Role__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Segment__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].TAL_PID__c);
        System.assertEquals(null, dfrList[0].TAL_Purchase_Timeframe__c);
        System.assertEquals(null, dfrList[0].TAL_Score__c);
        System.assertEquals(null, dfrList[0].TAL_Status_Duration__c);
        System.assertEquals(null, dfrList[0].TAL_Status_Duration_Minutes__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Territory__c);
    }

    //CRM-13123 #16
    @isTest
    static void ContactStatus_1New_ChangeOwner_UserAE_to_UserAE() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        User aeUser2 = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME + '2' })
            .executeQuery()[0];

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, aeUser.Id)
            .setField(Contact.Contact_Status__c, '1. New')
            .create()
            .getRecord();

        Test.startTest();
        con.OwnerId = aeUser2.Id;
        update con;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'MQL_Owner_Team__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c',
                'SAL_AID__c',
                'SAL_BACKFILLED__c',
                'SAL_Behavior_Score__c',
                'SAL_BMID__c',
                'SAL_Campaign__c',
                'SAL_Channel__c',
                'SAL_Created_to_Entry__c',
                'SAL_Created_to_Exit__c',
                'SAL_DateTime_Entered__c',
                'SAL_DateTime_Exited__c',
                'SAL_Demographic_Score__c',
                'SAL_Employee_Size__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'SAL_isContact__c',
                'SAL_Lead_Entry_Source__c',
                'SAL_Lead_Score_Category__c',
                'SAL_Lead_Source__c',
                'SAL_Marketing_Asset__c',
                'SAL_Owner_Division__c',
                'SAL_Owner_Id__c',
                'SAL_Owner_Name__c',
                'SAL_Owner_Role__c',
                'SAL_Owner_Segment__c',
                'SAL_Owner_Team__c',
                'SAL_PID__c',
                'SAL_Purchase_Timeframe__c',
                'SAL_Score__c',
                'SAL_Status_Duration__c',
                'SAL_Status_Duration_Minutes__c',
                'SAL_SubChannel__c',
                'SAL_Vendor__c',
                'SAL_Handoff_Date__c',
                'SAL_Handoff_Owner__c',
                'SAL_Handoff_Owner_Role__c',
                'SAL_Owner_Territory__c',
                'SAL_Type__c',
                'TAL_AID__c',
                'SAL_BACKFILLED__c',
                'TAL_Behavior_Score__c',
                'TAL_BMID__c',
                'TAL_Campaign__c',
                'TAL_Created_to_Entry__c',
                'TAL_Created_to_Exit__c',
                'TAL_DateTime_Entered__c',
                'TAL_DateTime_Exited__c',
                'TAL_Demographic_Score__c',
                'TAL_Employee_Size__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'TAL_Lead_Entry_Source__c',
                'TAL_Lead_Score_Category__c',
                'TAL_Lead_Source__c',
                'TAL_Marketing_Asset__c',
                'TAL_Owner_Division__c',
                'TAL_Owner_Id__c',
                'TAL_Owner_Name__c',
                'TAL_Owner_Role__c',
                'TAL_Owner_Segment__c',
                'TAL_Owner_Team__c',
                'TAL_PID__c',
                'TAL_Purchase_Timeframe__c',
                'TAL_Score__c',
                'TAL_Status_Duration__c',
                'TAL_Status_Duration_Minutes__c',
                'TAL_Owner_Territory__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(Test_DemandFunnelHelper.MQLFUNNELSTATUS, dfrList[0].DET_Current_Funnel_Status__c);
        System.assert(
            Test_DemandFunnelHelper.isAEUser(dfrList[0].MQL_Owner_Team__c),
            'MQL Owner doesn\'t contains AE. Current value: ' + dfrList[0].MQL_Owner_Team__c
        );
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c);
        System.assertEquals(null, dfrList[0].SAL_AID__c);
        System.assertEquals(false, dfrList[0].SAL_BACKFILLED__c);
        System.assertEquals(null, dfrList[0].SAL_Behavior_Score__c);
        System.assertEquals(null, dfrList[0].SAL_BMID__c);
        System.assertEquals(null, dfrList[0].SAL_Campaign__c);
        System.assertEquals(null, dfrList[0].SAL_Channel__c);
        System.assertEquals(null, dfrList[0].SAL_Created_to_Entry__c);
        System.assertEquals(null, dfrList[0].SAL_Created_to_Exit__c);
        System.assertEquals(null, dfrList[0].SAL_DateTime_Entered__c);
        System.assertEquals(null, dfrList[0].SAL_DateTime_Exited__c);
        System.assertEquals(null, dfrList[0].SAL_Demographic_Score__c);
        System.assertEquals(null, dfrList[0].SAL_Employee_Size__c);
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c);
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c);
        System.assertEquals(false, dfrList[0].SAL_isContact__c);
        System.assertEquals(null, dfrList[0].SAL_Lead_Entry_Source__c);
        System.assertEquals(null, dfrList[0].SAL_Lead_Score_Category__c);
        System.assertEquals(null, dfrList[0].SAL_Lead_Source__c);
        System.assertEquals(null, dfrList[0].SAL_Marketing_Asset__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Division__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Name__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Role__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Segment__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].SAL_PID__c);
        System.assertEquals(null, dfrList[0].SAL_Purchase_Timeframe__c);
        System.assertEquals(null, dfrList[0].SAL_Score__c);
        System.assertEquals(null, dfrList[0].SAL_Status_Duration__c);
        System.assertEquals(null, dfrList[0].SAL_Status_Duration_Minutes__c);
        System.assertEquals(null, dfrList[0].SAL_SubChannel__c);
        System.assertEquals(null, dfrList[0].SAL_Vendor__c);
        System.assertEquals(null, dfrList[0].SAL_Handoff_Date__c);
        System.assertEquals(null, dfrList[0].SAL_Handoff_Owner__c);
        System.assertEquals(null, dfrList[0].SAL_Handoff_Owner_Role__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Territory__c);
        System.assertEquals(null, dfrList[0].SAL_Type__c);
        System.assertEquals(null, dfrList[0].TAL_AID__c);
        System.assertEquals(false, dfrList[0].SAL_BACKFILLED__c);
        System.assertEquals(null, dfrList[0].TAL_Behavior_Score__c);
        System.assertEquals(null, dfrList[0].TAL_BMID__c);
        System.assertEquals(null, dfrList[0].TAL_Campaign__c);
        System.assertEquals(null, dfrList[0].TAL_Created_to_Entry__c);
        System.assertEquals(null, dfrList[0].TAL_Created_to_Exit__c);
        System.assertEquals(null, dfrList[0].TAL_DateTime_Entered__c);
        System.assertEquals(null, dfrList[0].TAL_DateTime_Exited__c);
        System.assertEquals(null, dfrList[0].TAL_Demographic_Score__c);
        System.assertEquals(null, dfrList[0].TAL_Employee_Size__c);
        System.assertEquals(null, dfrList[0].TAL_Entered_From__c);
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c);
        System.assertEquals(null, dfrList[0].TAL_Lead_Entry_Source__c);
        System.assertEquals(null, dfrList[0].TAL_Lead_Score_Category__c);
        System.assertEquals(null, dfrList[0].TAL_Lead_Source__c);
        System.assertEquals(null, dfrList[0].TAL_Marketing_Asset__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Division__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Name__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Role__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Segment__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].TAL_PID__c);
        System.assertEquals(null, dfrList[0].TAL_Purchase_Timeframe__c);
        System.assertEquals(null, dfrList[0].TAL_Score__c);
        System.assertEquals(null, dfrList[0].TAL_Status_Duration__c);
        System.assertEquals(null, dfrList[0].TAL_Status_Duration_Minutes__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Territory__c);
    }

    //CRM-13123 #17
    @isTest
    static void ContactStatus_5ReNew_ChangeOwner_UserAE_to_UserSDR() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, aeUser.Id)
            .setField(Contact.Contact_Status__c, '.5 Re-New')
            .create()
            .getRecord();

        Test.startTest();
        con.OwnerId = sdrUser.Id;
        update con;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'MQL_Owner_Team__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c',
                'SAL_AID__c',
                'SAL_BACKFILLED__c',
                'SAL_Behavior_Score__c',
                'SAL_BMID__c',
                'SAL_Campaign__c',
                'SAL_Channel__c',
                'SAL_Created_to_Entry__c',
                'SAL_Created_to_Exit__c',
                'SAL_DateTime_Entered__c',
                'SAL_DateTime_Exited__c',
                'SAL_Demographic_Score__c',
                'SAL_Employee_Size__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'SAL_isContact__c',
                'SAL_Lead_Entry_Source__c',
                'SAL_Lead_Score_Category__c',
                'SAL_Lead_Source__c',
                'SAL_Marketing_Asset__c',
                'SAL_Owner_Division__c',
                'SAL_Owner_Id__c',
                'SAL_Owner_Name__c',
                'SAL_Owner_Role__c',
                'SAL_Owner_Segment__c',
                'SAL_Owner_Team__c',
                'SAL_PID__c',
                'SAL_Purchase_Timeframe__c',
                'SAL_Score__c',
                'SAL_Status_Duration__c',
                'SAL_Status_Duration_Minutes__c',
                'SAL_SubChannel__c',
                'SAL_Vendor__c',
                'SAL_Handoff_Date__c',
                'SAL_Handoff_Owner__c',
                'SAL_Handoff_Owner_Role__c',
                'SAL_Owner_Territory__c',
                'SAL_Type__c',
                'TAL_AID__c',
                'SAL_BACKFILLED__c',
                'TAL_Behavior_Score__c',
                'TAL_BMID__c',
                'TAL_Campaign__c',
                'TAL_Created_to_Entry__c',
                'TAL_Created_to_Exit__c',
                'TAL_DateTime_Entered__c',
                'TAL_DateTime_Exited__c',
                'TAL_Demographic_Score__c',
                'TAL_Employee_Size__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'TAL_Lead_Entry_Source__c',
                'TAL_Lead_Score_Category__c',
                'TAL_Lead_Source__c',
                'TAL_Marketing_Asset__c',
                'TAL_Owner_Division__c',
                'TAL_Owner_Id__c',
                'TAL_Owner_Name__c',
                'TAL_Owner_Role__c',
                'TAL_Owner_Segment__c',
                'TAL_Owner_Team__c',
                'TAL_PID__c',
                'TAL_Purchase_Timeframe__c',
                'TAL_Score__c',
                'TAL_Status_Duration__c',
                'TAL_Status_Duration_Minutes__c',
                'TAL_Owner_Territory__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(Test_DemandFunnelHelper.MQLFUNNELSTATUS, dfrList[0].DET_Current_Funnel_Status__c);
        System.assert(
            Test_DemandFunnelHelper.isAEUser(dfrList[0].MQL_Owner_Team__c),
            'MQL Owner doesn\'t contains AE. Current value: ' + dfrList[0].MQL_Owner_Team__c
        );
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c);
        System.assertEquals(null, dfrList[0].SAL_AID__c);
        System.assertEquals(false, dfrList[0].SAL_BACKFILLED__c);
        System.assertEquals(null, dfrList[0].SAL_Behavior_Score__c);
        System.assertEquals(null, dfrList[0].SAL_BMID__c);
        System.assertEquals(null, dfrList[0].SAL_Campaign__c);
        System.assertEquals(null, dfrList[0].SAL_Channel__c);
        System.assertEquals(null, dfrList[0].SAL_Created_to_Entry__c);
        System.assertEquals(null, dfrList[0].SAL_Created_to_Exit__c);
        System.assertEquals(null, dfrList[0].SAL_DateTime_Entered__c);
        System.assertEquals(null, dfrList[0].SAL_DateTime_Exited__c);
        System.assertEquals(null, dfrList[0].SAL_Demographic_Score__c);
        System.assertEquals(null, dfrList[0].SAL_Employee_Size__c);
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c);
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c);
        System.assertEquals(false, dfrList[0].SAL_isContact__c);
        System.assertEquals(null, dfrList[0].SAL_Lead_Entry_Source__c);
        System.assertEquals(null, dfrList[0].SAL_Lead_Score_Category__c);
        System.assertEquals(null, dfrList[0].SAL_Lead_Source__c);
        System.assertEquals(null, dfrList[0].SAL_Marketing_Asset__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Division__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Name__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Role__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Segment__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].SAL_PID__c);
        System.assertEquals(null, dfrList[0].SAL_Purchase_Timeframe__c);
        System.assertEquals(null, dfrList[0].SAL_Score__c);
        System.assertEquals(null, dfrList[0].SAL_Status_Duration__c);
        System.assertEquals(null, dfrList[0].SAL_Status_Duration_Minutes__c);
        System.assertEquals(null, dfrList[0].SAL_SubChannel__c);
        System.assertEquals(null, dfrList[0].SAL_Vendor__c);
        System.assertEquals(null, dfrList[0].SAL_Handoff_Date__c);
        System.assertEquals(null, dfrList[0].SAL_Handoff_Owner__c);
        System.assertEquals(null, dfrList[0].SAL_Handoff_Owner_Role__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Territory__c);
        System.assertEquals(null, dfrList[0].SAL_Type__c);
        System.assertEquals(null, dfrList[0].TAL_AID__c);
        System.assertEquals(false, dfrList[0].SAL_BACKFILLED__c);
        System.assertEquals(null, dfrList[0].TAL_Behavior_Score__c);
        System.assertEquals(null, dfrList[0].TAL_BMID__c);
        System.assertEquals(null, dfrList[0].TAL_Campaign__c);
        System.assertEquals(null, dfrList[0].TAL_Created_to_Entry__c);
        System.assertEquals(null, dfrList[0].TAL_Created_to_Exit__c);
        System.assertEquals(null, dfrList[0].TAL_DateTime_Entered__c);
        System.assertEquals(null, dfrList[0].TAL_DateTime_Exited__c);
        System.assertEquals(null, dfrList[0].TAL_Demographic_Score__c);
        System.assertEquals(null, dfrList[0].TAL_Employee_Size__c);
        System.assertEquals(null, dfrList[0].TAL_Entered_From__c);
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c);
        System.assertEquals(null, dfrList[0].TAL_Lead_Entry_Source__c);
        System.assertEquals(null, dfrList[0].TAL_Lead_Score_Category__c);
        System.assertEquals(null, dfrList[0].TAL_Lead_Source__c);
        System.assertEquals(null, dfrList[0].TAL_Marketing_Asset__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Division__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Name__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Role__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Segment__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].TAL_PID__c);
        System.assertEquals(null, dfrList[0].TAL_Purchase_Timeframe__c);
        System.assertEquals(null, dfrList[0].TAL_Score__c);
        System.assertEquals(null, dfrList[0].TAL_Status_Duration__c);
        System.assertEquals(null, dfrList[0].TAL_Status_Duration_Minutes__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Territory__c);
    }

    //CRM-13123 #18
    @isTest
    static void ContactStatus_5ReNew_ChangeOwner_UserAE_to_UserAE() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        User aeUser2 = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME + '2' })
            .executeQuery()[0];

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, aeUser.Id)
            .setField(Contact.Contact_Status__c, '.5 Re-New')
            .create()
            .getRecord();

        Test.startTest();
        con.OwnerId = aeUser2.Id;
        update con;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'MQL_Owner_Team__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c',
                'SAL_AID__c',
                'SAL_BACKFILLED__c',
                'SAL_Behavior_Score__c',
                'SAL_BMID__c',
                'SAL_Campaign__c',
                'SAL_Channel__c',
                'SAL_Created_to_Entry__c',
                'SAL_Created_to_Exit__c',
                'SAL_DateTime_Entered__c',
                'SAL_DateTime_Exited__c',
                'SAL_Demographic_Score__c',
                'SAL_Employee_Size__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'SAL_isContact__c',
                'SAL_Lead_Entry_Source__c',
                'SAL_Lead_Score_Category__c',
                'SAL_Lead_Source__c',
                'SAL_Marketing_Asset__c',
                'SAL_Owner_Division__c',
                'SAL_Owner_Id__c',
                'SAL_Owner_Name__c',
                'SAL_Owner_Role__c',
                'SAL_Owner_Segment__c',
                'SAL_Owner_Team__c',
                'SAL_PID__c',
                'SAL_Purchase_Timeframe__c',
                'SAL_Score__c',
                'SAL_Status_Duration__c',
                'SAL_Status_Duration_Minutes__c',
                'SAL_SubChannel__c',
                'SAL_Vendor__c',
                'SAL_Handoff_Date__c',
                'SAL_Handoff_Owner__c',
                'SAL_Handoff_Owner_Role__c',
                'SAL_Owner_Territory__c',
                'SAL_Type__c',
                'TAL_AID__c',
                'SAL_BACKFILLED__c',
                'TAL_Behavior_Score__c',
                'TAL_BMID__c',
                'TAL_Campaign__c',
                'TAL_Created_to_Entry__c',
                'TAL_Created_to_Exit__c',
                'TAL_DateTime_Entered__c',
                'TAL_DateTime_Exited__c',
                'TAL_Demographic_Score__c',
                'TAL_Employee_Size__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'TAL_Lead_Entry_Source__c',
                'TAL_Lead_Score_Category__c',
                'TAL_Lead_Source__c',
                'TAL_Marketing_Asset__c',
                'TAL_Owner_Division__c',
                'TAL_Owner_Id__c',
                'TAL_Owner_Name__c',
                'TAL_Owner_Role__c',
                'TAL_Owner_Segment__c',
                'TAL_Owner_Team__c',
                'TAL_PID__c',
                'TAL_Purchase_Timeframe__c',
                'TAL_Score__c',
                'TAL_Status_Duration__c',
                'TAL_Status_Duration_Minutes__c',
                'TAL_Owner_Territory__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(Test_DemandFunnelHelper.MQLFUNNELSTATUS, dfrList[0].DET_Current_Funnel_Status__c);
        System.assert(
            Test_DemandFunnelHelper.isAEUser(dfrList[0].MQL_Owner_Team__c),
            'MQL Owner doesn\'t contains AE. Current value: ' + dfrList[0].MQL_Owner_Team__c
        );
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c);
        System.assertEquals(null, dfrList[0].SAL_AID__c);
        System.assertEquals(false, dfrList[0].SAL_BACKFILLED__c);
        System.assertEquals(null, dfrList[0].SAL_Behavior_Score__c);
        System.assertEquals(null, dfrList[0].SAL_BMID__c);
        System.assertEquals(null, dfrList[0].SAL_Campaign__c);
        System.assertEquals(null, dfrList[0].SAL_Channel__c);
        System.assertEquals(null, dfrList[0].SAL_Created_to_Entry__c);
        System.assertEquals(null, dfrList[0].SAL_Created_to_Exit__c);
        System.assertEquals(null, dfrList[0].SAL_DateTime_Entered__c);
        System.assertEquals(null, dfrList[0].SAL_DateTime_Exited__c);
        System.assertEquals(null, dfrList[0].SAL_Demographic_Score__c);
        System.assertEquals(null, dfrList[0].SAL_Employee_Size__c);
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c);
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c);
        System.assertEquals(false, dfrList[0].SAL_isContact__c);
        System.assertEquals(null, dfrList[0].SAL_Lead_Entry_Source__c);
        System.assertEquals(null, dfrList[0].SAL_Lead_Score_Category__c);
        System.assertEquals(null, dfrList[0].SAL_Lead_Source__c);
        System.assertEquals(null, dfrList[0].SAL_Marketing_Asset__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Division__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Name__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Role__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Segment__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].SAL_PID__c);
        System.assertEquals(null, dfrList[0].SAL_Purchase_Timeframe__c);
        System.assertEquals(null, dfrList[0].SAL_Score__c);
        System.assertEquals(null, dfrList[0].SAL_Status_Duration__c);
        System.assertEquals(null, dfrList[0].SAL_Status_Duration_Minutes__c);
        System.assertEquals(null, dfrList[0].SAL_SubChannel__c);
        System.assertEquals(null, dfrList[0].SAL_Vendor__c);
        System.assertEquals(null, dfrList[0].SAL_Handoff_Date__c);
        System.assertEquals(null, dfrList[0].SAL_Handoff_Owner__c);
        System.assertEquals(null, dfrList[0].SAL_Handoff_Owner_Role__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Territory__c);
        System.assertEquals(null, dfrList[0].SAL_Type__c);
        System.assertEquals(null, dfrList[0].TAL_AID__c);
        System.assertEquals(false, dfrList[0].SAL_BACKFILLED__c);
        System.assertEquals(null, dfrList[0].TAL_Behavior_Score__c);
        System.assertEquals(null, dfrList[0].TAL_BMID__c);
        System.assertEquals(null, dfrList[0].TAL_Campaign__c);
        System.assertEquals(null, dfrList[0].TAL_Created_to_Entry__c);
        System.assertEquals(null, dfrList[0].TAL_Created_to_Exit__c);
        System.assertEquals(null, dfrList[0].TAL_DateTime_Entered__c);
        System.assertEquals(null, dfrList[0].TAL_DateTime_Exited__c);
        System.assertEquals(null, dfrList[0].TAL_Demographic_Score__c);
        System.assertEquals(null, dfrList[0].TAL_Employee_Size__c);
        System.assertEquals(null, dfrList[0].TAL_Entered_From__c);
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c);
        System.assertEquals(null, dfrList[0].TAL_Lead_Entry_Source__c);
        System.assertEquals(null, dfrList[0].TAL_Lead_Score_Category__c);
        System.assertEquals(null, dfrList[0].TAL_Lead_Source__c);
        System.assertEquals(null, dfrList[0].TAL_Marketing_Asset__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Division__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Name__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Role__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Segment__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].TAL_PID__c);
        System.assertEquals(null, dfrList[0].TAL_Purchase_Timeframe__c);
        System.assertEquals(null, dfrList[0].TAL_Score__c);
        System.assertEquals(null, dfrList[0].TAL_Status_Duration__c);
        System.assertEquals(null, dfrList[0].TAL_Status_Duration_Minutes__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Territory__c);
    }

    //CRM-13123 #19
    @isTest
    static void ContactStatus_XOpen_ChangeOwner_UserAE_to_UserSDR() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, aeUser.Id)
            .setField(Contact.Contact_Status__c, 'X. Open')
            .create()
            .getRecord();

        Test.startTest();
        con.OwnerId = sdrUser.Id;
        update con;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c',
                'SAL_AID__c',
                'SAL_BACKFILLED__c',
                'SAL_Behavior_Score__c',
                'SAL_BMID__c',
                'SAL_Campaign__c',
                'SAL_Channel__c',
                'SAL_Created_to_Entry__c',
                'SAL_Created_to_Exit__c',
                'SAL_DateTime_Entered__c',
                'SAL_DateTime_Exited__c',
                'SAL_Demographic_Score__c',
                'SAL_Employee_Size__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'SAL_isContact__c',
                'SAL_Lead_Entry_Source__c',
                'SAL_Lead_Score_Category__c',
                'SAL_Lead_Source__c',
                'SAL_Marketing_Asset__c',
                'SAL_Owner_Division__c',
                'SAL_Owner_Id__c',
                'SAL_Owner_Name__c',
                'SAL_Owner_Role__c',
                'SAL_Owner_Segment__c',
                'SAL_Owner_Team__c',
                'SAL_PID__c',
                'SAL_Purchase_Timeframe__c',
                'SAL_Score__c',
                'SAL_Status_Duration__c',
                'SAL_Status_Duration_Minutes__c',
                'SAL_SubChannel__c',
                'SAL_Vendor__c',
                'SAL_Handoff_Date__c',
                'SAL_Handoff_Owner__c',
                'SAL_Handoff_Owner_Role__c',
                'SAL_Owner_Territory__c',
                'SAL_Type__c',
                'TAL_AID__c',
                'SAL_BACKFILLED__c',
                'TAL_Behavior_Score__c',
                'TAL_BMID__c',
                'TAL_Campaign__c',
                'TAL_Created_to_Entry__c',
                'TAL_Created_to_Exit__c',
                'TAL_DateTime_Entered__c',
                'TAL_DateTime_Exited__c',
                'TAL_Demographic_Score__c',
                'TAL_Employee_Size__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'TAL_Lead_Entry_Source__c',
                'TAL_Lead_Score_Category__c',
                'TAL_Lead_Source__c',
                'TAL_Marketing_Asset__c',
                'TAL_Owner_Division__c',
                'TAL_Owner_Id__c',
                'TAL_Owner_Name__c',
                'TAL_Owner_Role__c',
                'TAL_Owner_Segment__c',
                'TAL_Owner_Team__c',
                'TAL_PID__c',
                'TAL_Purchase_Timeframe__c',
                'TAL_Score__c',
                'TAL_Status_Duration__c',
                'TAL_Status_Duration_Minutes__c',
                'TAL_Owner_Territory__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(Test_DemandFunnelHelper.PROSPECTFUNNELSTATUS, dfrList[0].DET_Current_Funnel_Status__c);
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c);
        System.assertEquals(null, dfrList[0].SAL_AID__c);
        System.assertEquals(false, dfrList[0].SAL_BACKFILLED__c);
        System.assertEquals(null, dfrList[0].SAL_Behavior_Score__c);
        System.assertEquals(null, dfrList[0].SAL_BMID__c);
        System.assertEquals(null, dfrList[0].SAL_Campaign__c);
        System.assertEquals(null, dfrList[0].SAL_Channel__c);
        System.assertEquals(null, dfrList[0].SAL_Created_to_Entry__c);
        System.assertEquals(null, dfrList[0].SAL_Created_to_Exit__c);
        System.assertEquals(null, dfrList[0].SAL_DateTime_Entered__c);
        System.assertEquals(null, dfrList[0].SAL_DateTime_Exited__c);
        System.assertEquals(null, dfrList[0].SAL_Demographic_Score__c);
        System.assertEquals(null, dfrList[0].SAL_Employee_Size__c);
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c);
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c);
        System.assertEquals(false, dfrList[0].SAL_isContact__c);
        System.assertEquals(null, dfrList[0].SAL_Lead_Entry_Source__c);
        System.assertEquals(null, dfrList[0].SAL_Lead_Score_Category__c);
        System.assertEquals(null, dfrList[0].SAL_Lead_Source__c);
        System.assertEquals(null, dfrList[0].SAL_Marketing_Asset__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Division__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Name__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Role__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Segment__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].SAL_PID__c);
        System.assertEquals(null, dfrList[0].SAL_Purchase_Timeframe__c);
        System.assertEquals(null, dfrList[0].SAL_Score__c);
        System.assertEquals(null, dfrList[0].SAL_Status_Duration__c);
        System.assertEquals(null, dfrList[0].SAL_Status_Duration_Minutes__c);
        System.assertEquals(null, dfrList[0].SAL_SubChannel__c);
        System.assertEquals(null, dfrList[0].SAL_Vendor__c);
        System.assertEquals(null, dfrList[0].SAL_Handoff_Date__c);
        System.assertEquals(null, dfrList[0].SAL_Handoff_Owner__c);
        System.assertEquals(null, dfrList[0].SAL_Handoff_Owner_Role__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Territory__c);
        System.assertEquals(null, dfrList[0].SAL_Type__c);
        System.assertEquals(null, dfrList[0].TAL_AID__c);
        System.assertEquals(false, dfrList[0].SAL_BACKFILLED__c);
        System.assertEquals(null, dfrList[0].TAL_Behavior_Score__c);
        System.assertEquals(null, dfrList[0].TAL_BMID__c);
        System.assertEquals(null, dfrList[0].TAL_Campaign__c);
        System.assertEquals(null, dfrList[0].TAL_Created_to_Entry__c);
        System.assertEquals(null, dfrList[0].TAL_Created_to_Exit__c);
        System.assertEquals(null, dfrList[0].TAL_DateTime_Entered__c);
        System.assertEquals(null, dfrList[0].TAL_DateTime_Exited__c);
        System.assertEquals(null, dfrList[0].TAL_Demographic_Score__c);
        System.assertEquals(null, dfrList[0].TAL_Employee_Size__c);
        System.assertEquals(null, dfrList[0].TAL_Entered_From__c);
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c);
        System.assertEquals(null, dfrList[0].TAL_Lead_Entry_Source__c);
        System.assertEquals(null, dfrList[0].TAL_Lead_Score_Category__c);
        System.assertEquals(null, dfrList[0].TAL_Lead_Source__c);
        System.assertEquals(null, dfrList[0].TAL_Marketing_Asset__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Division__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Name__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Role__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Segment__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].TAL_PID__c);
        System.assertEquals(null, dfrList[0].TAL_Purchase_Timeframe__c);
        System.assertEquals(null, dfrList[0].TAL_Score__c);
        System.assertEquals(null, dfrList[0].TAL_Status_Duration__c);
        System.assertEquals(null, dfrList[0].TAL_Status_Duration_Minutes__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Territory__c);
    }

    //CRM-13123 #20
    @isTest
    static void ContactStatus_XOpen_ChangeOwner_UserAE_to_UserAE() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        User aeUser2 = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME + '2' })
            .executeQuery()[0];

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, aeUser.Id)
            .setField(Contact.Contact_Status__c, 'X. Open')
            .create()
            .getRecord();

        Test.startTest();
        con.OwnerId = aeUser2.Id;
        update con;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c',
                'SAL_AID__c',
                'SAL_BACKFILLED__c',
                'SAL_Behavior_Score__c',
                'SAL_BMID__c',
                'SAL_Campaign__c',
                'SAL_Channel__c',
                'SAL_Created_to_Entry__c',
                'SAL_Created_to_Exit__c',
                'SAL_DateTime_Entered__c',
                'SAL_DateTime_Exited__c',
                'SAL_Demographic_Score__c',
                'SAL_Employee_Size__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'SAL_isContact__c',
                'SAL_Lead_Entry_Source__c',
                'SAL_Lead_Score_Category__c',
                'SAL_Lead_Source__c',
                'SAL_Marketing_Asset__c',
                'SAL_Owner_Division__c',
                'SAL_Owner_Id__c',
                'SAL_Owner_Name__c',
                'SAL_Owner_Role__c',
                'SAL_Owner_Segment__c',
                'SAL_Owner_Team__c',
                'SAL_PID__c',
                'SAL_Purchase_Timeframe__c',
                'SAL_Score__c',
                'SAL_Status_Duration__c',
                'SAL_Status_Duration_Minutes__c',
                'SAL_SubChannel__c',
                'SAL_Vendor__c',
                'SAL_Handoff_Date__c',
                'SAL_Handoff_Owner__c',
                'SAL_Handoff_Owner_Role__c',
                'SAL_Owner_Territory__c',
                'SAL_Type__c',
                'TAL_AID__c',
                'SAL_BACKFILLED__c',
                'TAL_Behavior_Score__c',
                'TAL_BMID__c',
                'TAL_Campaign__c',
                'TAL_Created_to_Entry__c',
                'TAL_Created_to_Exit__c',
                'TAL_DateTime_Entered__c',
                'TAL_DateTime_Exited__c',
                'TAL_Demographic_Score__c',
                'TAL_Employee_Size__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'TAL_Lead_Entry_Source__c',
                'TAL_Lead_Score_Category__c',
                'TAL_Lead_Source__c',
                'TAL_Marketing_Asset__c',
                'TAL_Owner_Division__c',
                'TAL_Owner_Id__c',
                'TAL_Owner_Name__c',
                'TAL_Owner_Role__c',
                'TAL_Owner_Segment__c',
                'TAL_Owner_Team__c',
                'TAL_PID__c',
                'TAL_Purchase_Timeframe__c',
                'TAL_Score__c',
                'TAL_Status_Duration__c',
                'TAL_Status_Duration_Minutes__c',
                'TAL_Owner_Territory__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(Test_DemandFunnelHelper.PROSPECTFUNNELSTATUS, dfrList[0].DET_Current_Funnel_Status__c);
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c);
        System.assertEquals(null, dfrList[0].SAL_AID__c);
        System.assertEquals(false, dfrList[0].SAL_BACKFILLED__c);
        System.assertEquals(null, dfrList[0].SAL_Behavior_Score__c);
        System.assertEquals(null, dfrList[0].SAL_BMID__c);
        System.assertEquals(null, dfrList[0].SAL_Campaign__c);
        System.assertEquals(null, dfrList[0].SAL_Channel__c);
        System.assertEquals(null, dfrList[0].SAL_Created_to_Entry__c);
        System.assertEquals(null, dfrList[0].SAL_Created_to_Exit__c);
        System.assertEquals(null, dfrList[0].SAL_DateTime_Entered__c);
        System.assertEquals(null, dfrList[0].SAL_DateTime_Exited__c);
        System.assertEquals(null, dfrList[0].SAL_Demographic_Score__c);
        System.assertEquals(null, dfrList[0].SAL_Employee_Size__c);
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c);
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c);
        System.assertEquals(false, dfrList[0].SAL_isContact__c);
        System.assertEquals(null, dfrList[0].SAL_Lead_Entry_Source__c);
        System.assertEquals(null, dfrList[0].SAL_Lead_Score_Category__c);
        System.assertEquals(null, dfrList[0].SAL_Lead_Source__c);
        System.assertEquals(null, dfrList[0].SAL_Marketing_Asset__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Division__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Name__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Role__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Segment__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].SAL_PID__c);
        System.assertEquals(null, dfrList[0].SAL_Purchase_Timeframe__c);
        System.assertEquals(null, dfrList[0].SAL_Score__c);
        System.assertEquals(null, dfrList[0].SAL_Status_Duration__c);
        System.assertEquals(null, dfrList[0].SAL_Status_Duration_Minutes__c);
        System.assertEquals(null, dfrList[0].SAL_SubChannel__c);
        System.assertEquals(null, dfrList[0].SAL_Vendor__c);
        System.assertEquals(null, dfrList[0].SAL_Handoff_Date__c);
        System.assertEquals(null, dfrList[0].SAL_Handoff_Owner__c);
        System.assertEquals(null, dfrList[0].SAL_Handoff_Owner_Role__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Territory__c);
        System.assertEquals(null, dfrList[0].SAL_Type__c);
        System.assertEquals(null, dfrList[0].TAL_AID__c);
        System.assertEquals(false, dfrList[0].SAL_BACKFILLED__c);
        System.assertEquals(null, dfrList[0].TAL_Behavior_Score__c);
        System.assertEquals(null, dfrList[0].TAL_BMID__c);
        System.assertEquals(null, dfrList[0].TAL_Campaign__c);
        System.assertEquals(null, dfrList[0].TAL_Created_to_Entry__c);
        System.assertEquals(null, dfrList[0].TAL_Created_to_Exit__c);
        System.assertEquals(null, dfrList[0].TAL_DateTime_Entered__c);
        System.assertEquals(null, dfrList[0].TAL_DateTime_Exited__c);
        System.assertEquals(null, dfrList[0].TAL_Demographic_Score__c);
        System.assertEquals(null, dfrList[0].TAL_Employee_Size__c);
        System.assertEquals(null, dfrList[0].TAL_Entered_From__c);
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c);
        System.assertEquals(null, dfrList[0].TAL_Lead_Entry_Source__c);
        System.assertEquals(null, dfrList[0].TAL_Lead_Score_Category__c);
        System.assertEquals(null, dfrList[0].TAL_Lead_Source__c);
        System.assertEquals(null, dfrList[0].TAL_Marketing_Asset__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Division__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Name__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Role__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Segment__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].TAL_PID__c);
        System.assertEquals(null, dfrList[0].TAL_Purchase_Timeframe__c);
        System.assertEquals(null, dfrList[0].TAL_Score__c);
        System.assertEquals(null, dfrList[0].TAL_Status_Duration__c);
        System.assertEquals(null, dfrList[0].TAL_Status_Duration_Minutes__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Territory__c);
    }

    //CRM-13123 #21
    @isTest
    static void ContactStatus_2Contacted_ChangeOwner_SystemUserBDR_to_UserSDR() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.BDRTEAM;
        update sysUser;
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, sysUser.Id)
            .setField(Contact.Contact_Status__c, '2. Contacted')
            .create()
            .getRecord();

        Test.startTest();
        con.OwnerId = sdrUser.Id;
        update con;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'MQL_Owner_Id__c',
                'MQL_Owner_Name__c',
                'MQL_Owner_Team__c',
                'Prospect_Owner_Id__c',
                'Prospect_Owner_Name__c',
                'Prospect_Owner_Team__c',
                'TAL_Owner_Id__c',
                'TAL_Owner_Name__c',
                'TAL_Owner_Team__c',
                'SAL_Owner_Id__c',
                'SAL_Owner_Name__c',
                'SAL_Owner_Team__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(Test_DemandFunnelHelper.TALFUNNELSTATUS, dfrList[0].DET_Current_Funnel_Status__c);
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].TAL_Owner_Team__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].MQL_Owner_Team__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].Prospect_Owner_Team__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].TAL_Owner_Name__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].MQL_Owner_Name__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].Prospect_Owner_Name__c);
        System.assertEquals(sdrUser.Id, dfrList[0].Prospect_Owner_Id__c);
        System.assertEquals(sdrUser.Id, dfrList[0].TAL_Owner_Id__c);
        System.assertEquals(sdrUser.Id, dfrList[0].MQL_Owner_Id__c);
    }

    //CRM-13123 #22
    @isTest
    static void ContactStatus_2Contacted_ChangeOwner_SystemUserBDR_to_UserAE() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.BDRTEAM;
        update sysUser;
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, sysUser.Id)
            .setField(Contact.Contact_Status__c, '2. Contacted')
            .create()
            .getRecord();

        Test.startTest();
        con.OwnerId = aeUser.Id;
        update con;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'MQL_Owner_Id__c',
                'MQL_Owner_Name__c',
                'MQL_Owner_Team__c',
                'Prospect_Owner_Id__c',
                'Prospect_Owner_Name__c',
                'Prospect_Owner_Team__c',
                'TAL_Owner_Id__c',
                'TAL_Owner_Name__c',
                'TAL_Owner_Team__c',
                'SAL_Owner_Id__c',
                'SAL_Owner_Name__c',
                'SAL_Owner_Team__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(Test_DemandFunnelHelper.SALFUNNELSTATUS, dfrList[0].DET_Current_Funnel_Status__c);
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c);
        System.assertEquals(Test_DemandFunnelHelper.AETEAM, dfrList[0].MQL_Owner_Team__c);
        System.assertEquals(Test_DemandFunnelHelper.AETEAM, dfrList[0].Prospect_Owner_Team__c);
        System.assertEquals(Test_DemandFunnelHelper.AETEAM, dfrList[0].SAL_Owner_Team__c);
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].MQL_Owner_Name__c);
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].Prospect_Owner_Name__c);
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].SAL_Owner_Name__c);
        System.assertEquals(aeUser.Id, dfrList[0].Prospect_Owner_Id__c);
        System.assertEquals(aeUser.Id, dfrList[0].MQL_Owner_Id__c);
        System.assertEquals(aeUser.Id, dfrList[0].SAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Name__c);
    }

    //CRM-13123 #23
    @isTest
    static void ContactStatus_15CallOut_ChangeOwner_SystemUserBDR_to_UserSDR() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.BDRTEAM;
        update sysUser;
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, sysUser.Id)
            .setField(Contact.Contact_Status__c, '1.5 Call Out')
            .create()
            .getRecord();

        Test.startTest();
        con.OwnerId = sdrUser.Id;
        update con;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'MQL_Owner_Id__c',
                'MQL_Owner_Name__c',
                'MQL_Owner_Team__c',
                'Prospect_Owner_Id__c',
                'Prospect_Owner_Name__c',
                'Prospect_Owner_Team__c',
                'TAL_Owner_Id__c',
                'TAL_Owner_Name__c',
                'TAL_Owner_Team__c',
                'SAL_Owner_Id__c',
                'SAL_Owner_Name__c',
                'SAL_Owner_Team__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(Test_DemandFunnelHelper.TALFUNNELSTATUS, dfrList[0].DET_Current_Funnel_Status__c);
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].TAL_Owner_Team__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].MQL_Owner_Team__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].Prospect_Owner_Team__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].TAL_Owner_Name__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].MQL_Owner_Name__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].Prospect_Owner_Name__c);
        System.assertEquals(sdrUser.Id, dfrList[0].Prospect_Owner_Id__c);
        System.assertEquals(sdrUser.Id, dfrList[0].TAL_Owner_Id__c);
        System.assertEquals(sdrUser.Id, dfrList[0].MQL_Owner_Id__c);
    }

    //CRM-13123 #24
    @isTest
    static void ContactStatus_15CallOut_ChangeOwner_SystemUserBDR_to_UserAE() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.BDRTEAM;
        update sysUser;
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, sysUser.Id)
            .setField(Contact.Contact_Status__c, '1.5 Call Out')
            .create()
            .getRecord();

        Test.startTest();
        con.OwnerId = aeUser.Id;
        update con;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'MQL_Owner_Id__c',
                'MQL_Owner_Name__c',
                'MQL_Owner_Team__c',
                'Prospect_Owner_Id__c',
                'Prospect_Owner_Name__c',
                'Prospect_Owner_Team__c',
                'TAL_Owner_Id__c',
                'TAL_Owner_Name__c',
                'TAL_Owner_Team__c',
                'SAL_Owner_Id__c',
                'SAL_Owner_Name__c',
                'SAL_Owner_Team__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(Test_DemandFunnelHelper.SALFUNNELSTATUS, dfrList[0].DET_Current_Funnel_Status__c);
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c);
        System.assertEquals(Test_DemandFunnelHelper.AETEAM, dfrList[0].MQL_Owner_Team__c);
        System.assertEquals(Test_DemandFunnelHelper.AETEAM, dfrList[0].Prospect_Owner_Team__c);
        System.assertEquals(Test_DemandFunnelHelper.AETEAM, dfrList[0].SAL_Owner_Team__c);
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].MQL_Owner_Name__c);
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].Prospect_Owner_Name__c);
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].SAL_Owner_Name__c);
        System.assertEquals(aeUser.Id, dfrList[0].Prospect_Owner_Id__c);
        System.assertEquals(aeUser.Id, dfrList[0].MQL_Owner_Id__c);
        System.assertEquals(aeUser.Id, dfrList[0].SAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Name__c);
    }

    //CRM-13123 #25
    @isTest
    static void ContactStatus_1New_ChangeOwner_SystemUserBDR_to_UserSDR() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.BDRTEAM;
        update sysUser;
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, sysUser.Id)
            .setField(Contact.Contact_Status__c, '1. New')
            .create()
            .getRecord();

        Test.startTest();
        con.OwnerId = sdrUser.Id;
        update con;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'MQL_Owner_Id__c',
                'MQL_Owner_Name__c',
                'MQL_Owner_Team__c',
                'Prospect_Owner_Id__c',
                'Prospect_Owner_Name__c',
                'Prospect_Owner_Team__c',
                'TAL_Owner_Id__c',
                'TAL_Owner_Name__c',
                'TAL_Owner_Team__c',
                'SAL_Owner_Id__c',
                'SAL_Owner_Name__c',
                'SAL_Owner_Team__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(Test_DemandFunnelHelper.MQLFUNNELSTATUS, dfrList[0].DET_Current_Funnel_Status__c);
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].MQL_Owner_Team__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].MQL_Owner_Name__c);
        System.assertEquals(sdrUser.Id, dfrList[0].MQL_Owner_Id__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].Prospect_Owner_Team__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].Prospect_Owner_Name__c);
        System.assertEquals(sdrUser.Id, dfrList[0].Prospect_Owner_Id__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Name__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Name__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Id__c);
    }

    //CRM-13123 #26
    @isTest
    static void ContactStatus_1New_ChangeOwner_SystemUserBDR_to_UserAE() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.BDRTEAM;
        update sysUser;
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, sysUser.Id)
            .setField(Contact.Contact_Status__c, '1. New')
            .create()
            .getRecord();

        Test.startTest();
        con.OwnerId = aeUser.Id;
        update con;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'MQL_Owner_Id__c',
                'MQL_Owner_Name__c',
                'MQL_Owner_Team__c',
                'Prospect_Owner_Id__c',
                'Prospect_Owner_Name__c',
                'Prospect_Owner_Team__c',
                'TAL_Owner_Id__c',
                'TAL_Owner_Name__c',
                'TAL_Owner_Team__c',
                'SAL_Owner_Id__c',
                'SAL_Owner_Name__c',
                'SAL_Owner_Team__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(Test_DemandFunnelHelper.MQLFUNNELSTATUS, dfrList[0].DET_Current_Funnel_Status__c);
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c);
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].MQL_Owner_Name__c);
        System.assertEquals(Test_DemandFunnelHelper.AETEAM, dfrList[0].MQL_Owner_Team__c);
        System.assertEquals(aeUser.Id, dfrList[0].MQL_Owner_Id__c);
        System.assertEquals(Test_DemandFunnelHelper.AETEAM, dfrList[0].Prospect_Owner_Team__c);
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].Prospect_Owner_Name__c);
        System.assertEquals(aeUser.Id, dfrList[0].Prospect_Owner_Id__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Name__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Name__c);
    }

    //CRM-13123 #27
    @isTest
    static void ContactStatus_5ReNew_ChangeOwner_SystemUserBDR_to_UserSDR() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.BDRTEAM;
        update sysUser;
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, sysUser.Id)
            .setField(Contact.Contact_Status__c, '.5 Re-New')
            .create()
            .getRecord();

        Test.startTest();
        con.OwnerId = sdrUser.Id;
        update con;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'MQL_Owner_Id__c',
                'MQL_Owner_Name__c',
                'MQL_Owner_Team__c',
                'Prospect_Owner_Id__c',
                'Prospect_Owner_Name__c',
                'Prospect_Owner_Team__c',
                'TAL_Owner_Id__c',
                'TAL_Owner_Name__c',
                'TAL_Owner_Team__c',
                'SAL_Owner_Id__c',
                'SAL_Owner_Name__c',
                'SAL_Owner_Team__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(Test_DemandFunnelHelper.MQLFUNNELSTATUS, dfrList[0].DET_Current_Funnel_Status__c);
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].MQL_Owner_Team__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].MQL_Owner_Name__c);
        System.assertEquals(sdrUser.Id, dfrList[0].MQL_Owner_Id__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].Prospect_Owner_Team__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].Prospect_Owner_Name__c);
        System.assertEquals(sdrUser.Id, dfrList[0].Prospect_Owner_Id__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Name__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Name__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Id__c);
    }

    //CRM-13123 #28
    @isTest
    static void ContactStatus_5ReNew_ChangeOwner_SystemUserBDR_to_UserAE() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.BDRTEAM;
        update sysUser;
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, sysUser.Id)
            .setField(Contact.Contact_Status__c, '.5 Re-New')
            .create()
            .getRecord();

        Test.startTest();
        con.OwnerId = aeUser.Id;
        update con;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'MQL_Owner_Id__c',
                'MQL_Owner_Name__c',
                'MQL_Owner_Team__c',
                'Prospect_Owner_Id__c',
                'Prospect_Owner_Name__c',
                'Prospect_Owner_Team__c',
                'TAL_Owner_Id__c',
                'TAL_Owner_Name__c',
                'TAL_Owner_Team__c',
                'SAL_Owner_Id__c',
                'SAL_Owner_Name__c',
                'SAL_Owner_Team__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(Test_DemandFunnelHelper.MQLFUNNELSTATUS, dfrList[0].DET_Current_Funnel_Status__c);
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c);
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].MQL_Owner_Name__c);
        System.assertEquals(Test_DemandFunnelHelper.AETEAM, dfrList[0].MQL_Owner_Team__c);
        System.assertEquals(aeUser.Id, dfrList[0].MQL_Owner_Id__c);
        System.assertEquals(Test_DemandFunnelHelper.AETEAM, dfrList[0].Prospect_Owner_Team__c);
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].Prospect_Owner_Name__c);
        System.assertEquals(aeUser.Id, dfrList[0].Prospect_Owner_Id__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Name__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Name__c);
    }

    //CRM-13123 #29
    @isTest
    static void ContactStatus_XOpen_ChangeOwner_SystemUserBDR_to_UserSDR() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.BDRTEAM;
        update sysUser;
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, sysUser.Id)
            .setField(Contact.Contact_Status__c, '.5 Re-New')
            .create()
            .getRecord();

        Test.startTest();
        con.OwnerId = sdrUser.Id;
        update con;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'MQL_Owner_Id__c',
                'MQL_Owner_Name__c',
                'MQL_Owner_Team__c',
                'Prospect_Owner_Id__c',
                'Prospect_Owner_Name__c',
                'Prospect_Owner_Team__c',
                'TAL_Owner_Id__c',
                'TAL_Owner_Name__c',
                'TAL_Owner_Team__c',
                'SAL_Owner_Id__c',
                'SAL_Owner_Name__c',
                'SAL_Owner_Team__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(Test_DemandFunnelHelper.MQLFUNNELSTATUS, dfrList[0].DET_Current_Funnel_Status__c);
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].MQL_Owner_Team__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].MQL_Owner_Name__c);
        System.assertEquals(sdrUser.Id, dfrList[0].MQL_Owner_Id__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].Prospect_Owner_Team__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].Prospect_Owner_Name__c);
        System.assertEquals(sdrUser.Id, dfrList[0].Prospect_Owner_Id__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Name__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Name__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Id__c);
    }

    //CRM-13123 #30
    @isTest
    static void ContactStatus_XOpen_ChangeOwner_SystemUserBDR_to_UserAE() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.BDRTEAM;
        update sysUser;
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, sysUser.Id)
            .setField(Contact.Contact_Status__c, '.5 Re-New')
            .create()
            .getRecord();

        Test.startTest();
        con.OwnerId = aeUser.Id;
        update con;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'MQL_Owner_Id__c',
                'MQL_Owner_Name__c',
                'MQL_Owner_Team__c',
                'Prospect_Owner_Id__c',
                'Prospect_Owner_Name__c',
                'Prospect_Owner_Team__c',
                'TAL_Owner_Id__c',
                'TAL_Owner_Name__c',
                'TAL_Owner_Team__c',
                'SAL_Owner_Id__c',
                'SAL_Owner_Name__c',
                'SAL_Owner_Team__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(Test_DemandFunnelHelper.MQLFUNNELSTATUS, dfrList[0].DET_Current_Funnel_Status__c);
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c);
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].MQL_Owner_Name__c);
        System.assertEquals(Test_DemandFunnelHelper.AETEAM, dfrList[0].MQL_Owner_Team__c);
        System.assertEquals(aeUser.Id, dfrList[0].MQL_Owner_Id__c);
        System.assertEquals(Test_DemandFunnelHelper.AETEAM, dfrList[0].Prospect_Owner_Team__c);
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].Prospect_Owner_Name__c);
        System.assertEquals(aeUser.Id, dfrList[0].Prospect_Owner_Id__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Name__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Name__c);
    }

    //CRM-13123 #31
    @isTest
    static void ContactStatus_2Contacted_ChangeOwner_SystemUserAE_to_UserSDR() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.AETEAM;
        update sysUser;
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, sysUser.Id)
            .setField(Contact.Contact_Status__c, '2. Contacted')
            .create()
            .getRecord();

        Test.startTest();
        con.OwnerId = sdrUser.Id;
        update con;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'MQL_Owner_Id__c',
                'MQL_Owner_Name__c',
                'MQL_Owner_Team__c',
                'Prospect_Owner_Id__c',
                'Prospect_Owner_Name__c',
                'Prospect_Owner_Team__c',
                'TAL_Owner_Id__c',
                'TAL_Owner_Name__c',
                'TAL_Owner_Team__c',
                'SAL_Owner_Id__c',
                'SAL_Owner_Name__c',
                'SAL_Owner_Team__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(Test_DemandFunnelHelper.TALFUNNELSTATUS, dfrList[0].DET_Current_Funnel_Status__c);
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].TAL_Owner_Team__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].MQL_Owner_Team__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].Prospect_Owner_Team__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].TAL_Owner_Name__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].MQL_Owner_Name__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].Prospect_Owner_Name__c);
        System.assertEquals(sdrUser.Id, dfrList[0].Prospect_Owner_Id__c);
        System.assertEquals(sdrUser.Id, dfrList[0].TAL_Owner_Id__c);
        System.assertEquals(sdrUser.Id, dfrList[0].MQL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Name__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Id__c);
    }

    //CRM-13123 #32
    @isTest
    static void ContactStatus_2Contacted_ChangeOwner_SystemUserAE_to_UserAE() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.AETEAM;
        update sysUser;
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, sysUser.Id)
            .setField(Contact.Contact_Status__c, '2. Contacted')
            .create()
            .getRecord();

        Test.startTest();
        con.OwnerId = aeUser.Id;
        update con;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'MQL_Owner_Id__c',
                'MQL_Owner_Name__c',
                'MQL_Owner_Team__c',
                'Prospect_Owner_Id__c',
                'Prospect_Owner_Name__c',
                'Prospect_Owner_Team__c',
                'TAL_Owner_Id__c',
                'TAL_Owner_Name__c',
                'TAL_Owner_Team__c',
                'SAL_Owner_Id__c',
                'SAL_Owner_Name__c',
                'SAL_Owner_Team__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(Test_DemandFunnelHelper.SALFUNNELSTATUS, dfrList[0].DET_Current_Funnel_Status__c);
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c);
        System.assertEquals(Test_DemandFunnelHelper.AETEAM, dfrList[0].MQL_Owner_Team__c);
        System.assertEquals(Test_DemandFunnelHelper.AETEAM, dfrList[0].Prospect_Owner_Team__c);
        System.assertEquals(Test_DemandFunnelHelper.AETEAM, dfrList[0].SAL_Owner_Team__c);
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].MQL_Owner_Name__c);
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].Prospect_Owner_Name__c);
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].SAL_Owner_Name__c);
        System.assertEquals(aeUser.Id, dfrList[0].Prospect_Owner_Id__c);
        System.assertEquals(aeUser.Id, dfrList[0].MQL_Owner_Id__c);
        System.assertEquals(aeUser.Id, dfrList[0].SAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Name__c);
    }

    //CRM-13123 #33
    @isTest
    static void ContactStatus_15CallOut_ChangeOwner_SystemUserAE_to_UserSDR() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.AETEAM;
        update sysUser;
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, sysUser.Id)
            .setField(Contact.Contact_Status__c, '1.5 Call Out')
            .create()
            .getRecord();

        Test.startTest();
        con.OwnerId = sdrUser.Id;
        update con;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'MQL_Owner_Id__c',
                'MQL_Owner_Name__c',
                'MQL_Owner_Team__c',
                'Prospect_Owner_Id__c',
                'Prospect_Owner_Name__c',
                'Prospect_Owner_Team__c',
                'TAL_Owner_Id__c',
                'TAL_Owner_Name__c',
                'TAL_Owner_Team__c',
                'SAL_Owner_Id__c',
                'SAL_Owner_Name__c',
                'SAL_Owner_Team__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(Test_DemandFunnelHelper.TALFUNNELSTATUS, dfrList[0].DET_Current_Funnel_Status__c);
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].TAL_Owner_Team__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].MQL_Owner_Team__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].Prospect_Owner_Team__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].TAL_Owner_Name__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].MQL_Owner_Name__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].Prospect_Owner_Name__c);
        System.assertEquals(sdrUser.Id, dfrList[0].Prospect_Owner_Id__c);
        System.assertEquals(sdrUser.Id, dfrList[0].TAL_Owner_Id__c);
        System.assertEquals(sdrUser.Id, dfrList[0].MQL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Name__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Id__c);
    }

    //CRM-13123 #34
    @isTest
    static void ContactStatus_15CallOut_ChangeOwner_SystemUserAE_to_UserAE() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.AETEAM;
        update sysUser;
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, sysUser.Id)
            .setField(Contact.Contact_Status__c, '1.5 Call Out')
            .create()
            .getRecord();

        Test.startTest();
        con.OwnerId = aeUser.Id;
        update con;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'MQL_Owner_Id__c',
                'MQL_Owner_Name__c',
                'MQL_Owner_Team__c',
                'Prospect_Owner_Id__c',
                'Prospect_Owner_Name__c',
                'Prospect_Owner_Team__c',
                'TAL_Owner_Id__c',
                'TAL_Owner_Name__c',
                'TAL_Owner_Team__c',
                'SAL_Owner_Id__c',
                'SAL_Owner_Name__c',
                'SAL_Owner_Team__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(Test_DemandFunnelHelper.SALFUNNELSTATUS, dfrList[0].DET_Current_Funnel_Status__c);
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c);
        System.assertEquals(Test_DemandFunnelHelper.AETEAM, dfrList[0].MQL_Owner_Team__c);
        System.assertEquals(Test_DemandFunnelHelper.AETEAM, dfrList[0].Prospect_Owner_Team__c);
        System.assertEquals(Test_DemandFunnelHelper.AETEAM, dfrList[0].SAL_Owner_Team__c);
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].MQL_Owner_Name__c);
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].Prospect_Owner_Name__c);
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].SAL_Owner_Name__c);
        System.assertEquals(aeUser.Id, dfrList[0].Prospect_Owner_Id__c);
        System.assertEquals(aeUser.Id, dfrList[0].MQL_Owner_Id__c);
        System.assertEquals(aeUser.Id, dfrList[0].SAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Name__c);
    }

    //CRM-13123 #35
    @isTest
    static void ContactStatus_1New_ChangeOwner_SystemUserAE_to_UserSDR() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.AETEAM;
        update sysUser;
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, sysUser.Id)
            .setField(Contact.Contact_Status__c, '1. New')
            .create()
            .getRecord();

        Test.startTest();
        con.OwnerId = sdrUser.Id;
        update con;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'MQL_Owner_Id__c',
                'MQL_Owner_Name__c',
                'MQL_Owner_Team__c',
                'Prospect_Owner_Id__c',
                'Prospect_Owner_Name__c',
                'Prospect_Owner_Team__c',
                'TAL_Owner_Id__c',
                'TAL_Owner_Name__c',
                'TAL_Owner_Team__c',
                'SAL_Owner_Id__c',
                'SAL_Owner_Name__c',
                'SAL_Owner_Team__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(Test_DemandFunnelHelper.MQLFUNNELSTATUS, dfrList[0].DET_Current_Funnel_Status__c);
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].MQL_Owner_Team__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].Prospect_Owner_Team__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].MQL_Owner_Name__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].Prospect_Owner_Name__c);
        System.assertEquals(sdrUser.Id, dfrList[0].Prospect_Owner_Id__c);
        System.assertEquals(sdrUser.Id, dfrList[0].MQL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Name__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Name__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Id__c);
    }

    //CRM-13123 #36
    @isTest
    static void ContactStatus_1New_ChangeOwner_SystemUserAE_to_UserAE() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.AETEAM;
        update sysUser;
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, sysUser.Id)
            .setField(Contact.Contact_Status__c, '1. New')
            .create()
            .getRecord();

        Test.startTest();
        con.OwnerId = aeUser.Id;
        update con;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'MQL_Owner_Id__c',
                'MQL_Owner_Name__c',
                'MQL_Owner_Team__c',
                'Prospect_Owner_Id__c',
                'Prospect_Owner_Name__c',
                'Prospect_Owner_Team__c',
                'TAL_Owner_Id__c',
                'TAL_Owner_Name__c',
                'TAL_Owner_Team__c',
                'SAL_Owner_Id__c',
                'SAL_Owner_Name__c',
                'SAL_Owner_Team__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(Test_DemandFunnelHelper.MQLFUNNELSTATUS, dfrList[0].DET_Current_Funnel_Status__c);
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c);
        System.assertEquals(Test_DemandFunnelHelper.AETEAM, dfrList[0].MQL_Owner_Team__c);
        System.assertEquals(Test_DemandFunnelHelper.AETEAM, dfrList[0].Prospect_Owner_Team__c);
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].MQL_Owner_Name__c);
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].Prospect_Owner_Name__c);
        System.assertEquals(aeUser.Id, dfrList[0].Prospect_Owner_Id__c);
        System.assertEquals(aeUser.Id, dfrList[0].MQL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Name__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Name__c);
    }

    //CRM-13123 #37
    @isTest
    static void ContactStatus_5ReNew_ChangeOwner_SystemUserAE_to_UserSDR() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.AETEAM;
        update sysUser;
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, sysUser.Id)
            .setField(Contact.Contact_Status__c, '.5 Re-New')
            .create()
            .getRecord();

        Test.startTest();
        con.OwnerId = sdrUser.Id;
        update con;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'MQL_Owner_Id__c',
                'MQL_Owner_Name__c',
                'MQL_Owner_Team__c',
                'Prospect_Owner_Id__c',
                'Prospect_Owner_Name__c',
                'Prospect_Owner_Team__c',
                'TAL_Owner_Id__c',
                'TAL_Owner_Name__c',
                'TAL_Owner_Team__c',
                'SAL_Owner_Id__c',
                'SAL_Owner_Name__c',
                'SAL_Owner_Team__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(Test_DemandFunnelHelper.MQLFUNNELSTATUS, dfrList[0].DET_Current_Funnel_Status__c);
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].MQL_Owner_Team__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].Prospect_Owner_Team__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].MQL_Owner_Name__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].Prospect_Owner_Name__c);
        System.assertEquals(sdrUser.Id, dfrList[0].Prospect_Owner_Id__c);
        System.assertEquals(sdrUser.Id, dfrList[0].MQL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Name__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Name__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Id__c);
    }

    //CRM-13123 #38
    @isTest
    static void ContactStatus_5ReNew_ChangeOwner_SystemUserAE_to_UserAE() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.AETEAM;
        update sysUser;
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, sysUser.Id)
            .setField(Contact.Contact_Status__c, '.5 Re-New')
            .create()
            .getRecord();

        Test.startTest();
        con.OwnerId = aeUser.Id;
        update con;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'MQL_Owner_Id__c',
                'MQL_Owner_Name__c',
                'MQL_Owner_Team__c',
                'Prospect_Owner_Id__c',
                'Prospect_Owner_Name__c',
                'Prospect_Owner_Team__c',
                'TAL_Owner_Id__c',
                'TAL_Owner_Name__c',
                'TAL_Owner_Team__c',
                'SAL_Owner_Id__c',
                'SAL_Owner_Name__c',
                'SAL_Owner_Team__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(Test_DemandFunnelHelper.MQLFUNNELSTATUS, dfrList[0].DET_Current_Funnel_Status__c);
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c);
        System.assertEquals(Test_DemandFunnelHelper.AETEAM, dfrList[0].MQL_Owner_Team__c);
        System.assertEquals(Test_DemandFunnelHelper.AETEAM, dfrList[0].Prospect_Owner_Team__c);
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].MQL_Owner_Name__c);
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].Prospect_Owner_Name__c);
        System.assertEquals(aeUser.Id, dfrList[0].Prospect_Owner_Id__c);
        System.assertEquals(aeUser.Id, dfrList[0].MQL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Name__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Name__c);
    }

    //CRM-13123 #39
    @isTest
    static void ContactStatus_XOpen_ChangeOwner_SystemUserAE_to_UserSDR() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.AETEAM;
        update sysUser;
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, sysUser.Id)
            .setField(Contact.Contact_Status__c, 'X. Open')
            .create()
            .getRecord();

        Test.startTest();
        con.OwnerId = sdrUser.Id;
        update con;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'MQL_Owner_Id__c',
                'MQL_Owner_Name__c',
                'MQL_Owner_Team__c',
                'Prospect_Owner_Id__c',
                'Prospect_Owner_Name__c',
                'Prospect_Owner_Team__c',
                'TAL_Owner_Id__c',
                'TAL_Owner_Name__c',
                'TAL_Owner_Team__c',
                'SAL_Owner_Id__c',
                'SAL_Owner_Name__c',
                'SAL_Owner_Team__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(Test_DemandFunnelHelper.PROSPECTFUNNELSTATUS, dfrList[0].DET_Current_Funnel_Status__c);
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].Prospect_Owner_Team__c);
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].Prospect_Owner_Name__c);
        System.assertEquals(sdrUser.Id, dfrList[0].Prospect_Owner_Id__c);
        System.assertEquals(null, dfrList[0].MQL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].MQL_Owner_Name__c);
        System.assertEquals(null, dfrList[0].MQL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Name__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Name__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Id__c);
    }

    //CRM-13123 #40
    @isTest
    static void ContactStatus_XOpen_ChangeOwner_SystemUserAE_to_UserAE() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.AETEAM;
        update sysUser;
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, sysUser.Id)
            .setField(Contact.Contact_Status__c, 'X. Open')
            .create()
            .getRecord();

        Test.startTest();
        con.OwnerId = aeUser.Id;
        update con;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ con },
            new List<String>{
                'MQL_Owner_Id__c',
                'MQL_Owner_Name__c',
                'MQL_Owner_Team__c',
                'Prospect_Owner_Id__c',
                'Prospect_Owner_Name__c',
                'Prospect_Owner_Team__c',
                'TAL_Owner_Id__c',
                'TAL_Owner_Name__c',
                'TAL_Owner_Team__c',
                'SAL_Owner_Id__c',
                'SAL_Owner_Name__c',
                'SAL_Owner_Team__c',
                'DET_Current_Funnel_Status__c',
                'DFR_Active_Status__c'
            }
        );
        System.assert(!dfrList.isEmpty(), 'DFR creation failed');
        System.assertEquals(Test_DemandFunnelHelper.PROSPECTFUNNELSTATUS, dfrList[0].DET_Current_Funnel_Status__c);
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c);
        System.assertEquals(Test_DemandFunnelHelper.AETEAM, dfrList[0].Prospect_Owner_Team__c);
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].Prospect_Owner_Name__c);
        System.assertEquals(aeUser.Id, dfrList[0].Prospect_Owner_Id__c);
        System.assertEquals(null, dfrList[0].MQL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].MQL_Owner_Name__c);
        System.assertEquals(null, dfrList[0].MQL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Name__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].SAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Id__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Team__c);
        System.assertEquals(null, dfrList[0].TAL_Owner_Name__c);
    }

    @isTest
    static void test_ContactCreationInBulkWithContactStatus1New_DFRCreatedEqualAmount() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        
        Test.startTest();
        List<Contact> con = (List<Contact>) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Contact_Status__c, '1. New')
            .setField(Contact.OwnerId, aeUser.Id)
            .quantity(150)
            .create()
            .getRecords();
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(con, new List<String>{ 'DFR_Active_Status__c' });
        System.assertEquals(dfrList.size(), 150, 'DFR creation failed');
    }

    @isTest
    static void test_ContactUpdateInBulkContactStatusChangeFrom1NewTo2Contacted_DFRCreatedEqualAmountInSAL() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        List<Contact> con = (List<Contact>) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Contact_Status__c, '1. New')
            .setField(Contact.OwnerId, aeUser.Id)
            .quantity(150)
            .create()
            .getRecords();
        Test.startTest();
        for (Contact c : con) {
            c.Contact_Status__c = '2. Contacted';
        }
        update con;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(con, new List<String>{ 'DET_Current_Funnel_Status__c' });
        System.assertEquals(150, dfrList.size(), 'DFR creation failed');
        System.assertEquals(Test_DemandFunnelHelper.SALFUNNELSTATUS, dfrList[0].DET_Current_Funnel_Status__c, 'DFR Update failed');
    }
    
    @isTest
    static void testMQLFormUrl() {
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, sdrUser.Id)
            .setField(Contact.Contact_Status__c, LeadTriggerHelper.LEADSTATUSNEW)
            .setField(Contact.Form_URL__c, 'test')
            .create()
            .getRecord();
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(new List<Contact>{ con }, new List<String>{ 'MQL_Form_URL__c', 'Prospect_Form_URL__c' });

        System.assertEquals(
            'test',
            dfrList[0].MQL_Form_URL__c,
            'The MQL_Form_URL__c field was populated incorrectly'
        );
        
        System.assertEquals(
            'test',
            dfrList[0].Prospect_Form_URL__c,
            'The Prospect_Form_URL__c field was populated incorrectly'
        );
    }
    
    @isTest
    static void testProspectFormUrl() {
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, sdrUser.Id)
            .setField(Contact.Contact_Status__c, LeadTriggerHelper.LEADSTATUSNEW)
            .setField(Contact.Form_URL__c, 'test')
            .create()
            .getRecord();
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByContact(new List<Contact>{ con }, new List<String>{ 'Prospect_Form_URL__c' });

        System.assertEquals(
            'test',
            dfrList[0].Prospect_Form_URL__c,
            'The Prospect_Form_URL__c field was populated incorrectly'
        );
    }
}