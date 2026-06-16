@isTest
private class Test_CaseBeforeTrigger {
    private static final String CASE_OWNER_ASSIGNED_CORRECTLY_MSG = 'Case owner should be assigned correctly';
    private static final String CASE_CATEGORY_OTHER = 'Other';

    @isTest
    static void testConst_RT_COLLECTIONS_DISPUTE() {
        System.assertEquals('Collections Dispute', CaseHelper.RT_COLLECTIONS_DISPUTE);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void DateStartedUpdateOnOwnerChangeForSpecificRT() {
        User caseOwner = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestCaseOwner',
                    User.Username => 'CaseOwner!user@gmail.com',
                    User.Email => 'CaseOwner_user@gmail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep',
                    User.Division => OpportunityHelper.USER_DIVISION_SALES_ENTERPRISE
                }
            )
            .create()
            .getRecord();
        User newCaseOwner = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestNewCaseOwner',
                    User.Username => 'NewCaseOwner!user@gmail.com',
                    User.Email => 'NewCaseOwner_user@gmail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep',
                    User.Division => OpportunityHelper.USER_DIVISION_SALES_ENTERPRISE
                }
            )
            .create()
            .getRecord();
        Case newCase = new Case
        (
            RecordTypeId = CaseHelper.RT_ID_COLLECTIONS_DISPUTE
        );

        Test.startTest();

        newCase.OwnerId = caseOwner.Id;
        insert newCase;
        testCaseCreateDateIsEqualToCurrentDate();

        newCase.OwnerId = newCaseOwner.Id;
        newCase.Date_Started__c = Date.today().addDays(10);
        TriggerHandler.BY_PASS_BEFORE = false;
        update newCase;
        testCaseCreateDateIsEqualToCurrentDate();

        Test.stopTest();
    }

    private static void testCaseCreateDateIsEqualToCurrentDate() {
        Case[] cases  = [SELECT Date_Started__c FROM Case];
        System.assert(cases.size() > 0, 'Case object not found');
        System.assertEquals(cases[0].Date_Started__c, Date.today(), 'Case.Date_Started__c is not equals to current date!');
    }

    @isTest
    static void MedalliaSurveyWillBeSent_Positive() {
        Medallia_Credentials__c credentials = new Medallia_Credentials__c();
        credentials.isMedallia__c = true;
        credentials.Name = 'Medallia';
        insert credentials;

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc',
                    Account.RC_Brand__c => 'RingCentral'
                }
            )
            .create()
            .getRecord();

        Contact cntc = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'something@mostcommon.fake',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
        User caseOwner = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestCaseOwner',
                    User.Username => 'CaseOwner!user@gmail.com',
                    User.Email => 'CaseOwner_user@gmail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep',
                    User.Division => OpportunityHelper.USER_DIVISION_SALES_ENTERPRISE
                }
            )
            .create()
            .getRecord();

        System.runAs(caseOwner) {
            Case testCase1 = createCaseForMedalliaTests(CaseHelper.RT_ID_SUPPORT_T1, cntc.Id);
            testCase1.CloseCustomerSupportLevel1__c = 'some value to pass valiation';
            insert testCase1;

            Case testCase2 = createCaseForMedalliaTests(CaseHelper.RT_ID_SUPPORT_T2, cntc.Id);
            testCase2.Support_Disposition_Level_1__c = 'some value to pass valiation';
            testCase2.CloseCustomerSupportLevel1__c = 'some value to pass valiation';
            insert testCase2;

            Test.startTest();
            TriggerHandler.BY_PASS_BEFORE = false;
            testCase1.Status = CaseHelper.CASE_STATUS_CLOSED;
            testCase2.Status = CaseHelper.CASE_STATUS_CLOSED_NO_RESPONSE;
            update new Case[] { testCase1, testCase2 };
            Test.stopTest();
        }

        Medallia_Survey__c[] surveys = [SELECT Id FROM Medallia_Survey__c];
        System.assertEquals(2, surveys.size(), 'One or more Medallia_Survey__c records were not created. Blame!');
    }

    @isTest
    static void MedalliaSurveyWillBeSent_Negative() {
        Medallia_Credentials__c credentials = new Medallia_Credentials__c();
        credentials.isMedallia__c = true;
        credentials.Name = 'Medallia';
        insert credentials;

        Account accRc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc',
                    Account.RC_Brand__c => 'RingCentral'
                }
            )
            .create()
            .getRecord();
        Contact contactRc = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => accRc.Id,
                    Contact.Email => 'something@mostcommon.fake',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

        Account accTelus = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc',
                    Account.RC_Brand__c => 'Telus'
                }
            )
            .create()
            .getRecord();

        Contact contactTelus = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => accTelus.Id,
                    Contact.Email => 'something@mostcommon.fake',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

        User caseOwner = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestCaseOwner',
                    User.Username => 'CaseOwner!user@gmail.com',
                    User.Email => 'CaseOwner_user@gmail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep',
                    User.Division => OpportunityHelper.USER_DIVISION_SALES_ENTERPRISE
                }
            )
            .create()
            .getRecord();

        Map<Id, Case> casesMap = null;

        System.runAs(caseOwner) {
            List<Case> casesToInsert = new List<Case>();

            Case testCase1 = createCaseForMedalliaTests(CaseHelper.RT_ID_SUPPORT_T1, contactTelus.Id);
            testCase1.AccountId = accTelus.Id;
            testCase1.CloseCustomerSupportLevel1__c = 'some value to pass validation 0';
            casesToInsert.add(testCase1);


            Case testCase2 = createCaseForMedalliaTests(CaseHelper.RT_ID_SUPPORT_T2, contactRc.Id);
            testCase2.AccountId = accRc.Id;
            testCase2.Support_Disposition_Level_1__c = 'Internal Workflow';
            testCase2.CloseCustomerSupportLevel1__c = 'some value to pass validation 0';
            casesToInsert.add(testCase2);

            Case testCase3 = createCaseForMedalliaTests(CaseHelper.RT_ID_SUPPORT_T2, contactRc.Id);
            testCase3.AccountId = accRc.Id;
            testCase3.Support_Disposition_Level_1__c = 'some value to pass validation 2';
            casesToInsert.add(testCase3);

            insert casesToInsert;

            Test.startTest();

            TriggerHandler.RESET_VARIABLES();
            testCase1.Status = CaseHelper.CASE_STATUS_CLOSED;
            testCase2.Status = CaseHelper.CASE_STATUS_CLOSED_NO_RESPONSE;
            testCase3.Status = CaseHelper.CASE_STATUS_COMPLETED;

            casesMap = new Map<Id, Case>(casesToInsert);

            update casesMap.values();

            Test.stopTest();
        }

        Medallia_Survey__c[] surveys = [SELECT Case_SFDC_ID__c FROM Medallia_Survey__c];

        for (Medallia_Survey__c survey : surveys) {
            System.assert(false == true, 'Medallia_Survey__c record was created for following test case: ' + casesMap.get(survey.Case_SFDC_ID__c));
        }
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testContactWithUserNameUpdate() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'RC Internal'
                }
            )
            .create()
            .getRecord();

        User user = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestTest',
                    User.Username => 'Test!user@gmail.com',
                    User.Email => 'fake@mail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep',
                    User.Division => OpportunityHelper.USER_DIVISION_SALES_ENTERPRISE,
                    User.Title => 'testTitle',
                    User.Department => 'testDepartment'
                }
            )
            .create()
            .getRecord();

        Contact oldContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'something@mostcommon.fake',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

        Contact newContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'fake@mail.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

        Case c = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.Status => 'New',
                    Case.RecordTypeId => CaseHelper.RT_ID_IT_HELPDESK,
                    Case.ContactId => oldContact.Id
                }
            )
            .create()
            .getRecord();

        Test.startTest();
        TriggerHandler.BY_PASS_BEFORE = false;
        TriggerHandler.BY_PASS_CASE_ON_UPDATE= false;
        TriggerHandler.BY_PASS_CASE_Trigger = false;
        c.ContactId = newContact.Id;
        update c;
        Test.stopTest();

        Case updatedCase = [SELECT Id, User_Name__c, Title__c, Department__c
                             FROM Case
                             WHERE Id =: c.Id];

        //System.assertEquals('TestTest', updatedCase.User_Name__c, 'Case User Name should be TestTest');
        //System.assertEquals('testTitle', updatedCase.Title__c, 'Case Title should be testTitle');
        //System.assertEquals('testDepartment', updatedCase.Department__c, 'Case Department should be testDepartment');
    }

    @isTest
    static void testContactWithOutUserNameUpdate() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'RC Internal'
                }
            )
            .create()
            .getRecord();

        User user = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestTest',
                    User.Username => 'Test!user@gmail.com',
                    User.Email => 'fake@mail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep',
                    User.Division => OpportunityHelper.USER_DIVISION_SALES_ENTERPRISE,
                    User.Title => 'testTitle',
                    User.Department => 'testDepartment'
                }
            )
            .create()
            .getRecord();

        Contact oldContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'fake@mail.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

        Contact newContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'veryunique@mail.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

        Case c = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.Status => 'New',
                    Case.RecordTypeId => CaseHelper.RT_ID_IT_HELPDESK,
                    Case.ContactId => oldContact.Id
                }
            )
            .create()
            .getRecord();

        Test.startTest();
        TriggerHandler.BY_PASS_BEFORE = false;
        TriggerHandler.BY_PASS_CASE_ON_UPDATE= false;
        TriggerHandler.BY_PASS_CASE_Trigger = false;
        c.ContactId = newContact.Id;
        update c;
        Test.stopTest();

        Case updatedCase = [SELECT Id, User_Name__c, Title__c, Department__c
                            FROM Case
                            WHERE Id =: c.Id];

        System.assertEquals(null, updatedCase.User_Name__c, 'Case User Name should be blank');
        System.assertEquals(null, updatedCase.Title__c, 'Case Title should be blank');
        System.assertEquals(null, updatedCase.Department__c, 'Case Department should be blank');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testContactWithUserNameInsert() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'RC Internal'
                }
            )
            .create()
            .getRecord();

        User user = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestTest',
                    User.Username => 'Test!user@gmail.com',
                    User.Email => 'fake@mail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep',
                    User.Division => OpportunityHelper.USER_DIVISION_SALES_ENTERPRISE,
                    User.Title => 'testTitle',
                    User.Department => 'testDepartment'
                }
            )
            .create()
            .getRecord();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'fake@mail.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();



        Test.startTest();
        TriggerHandler.BY_PASS_BEFORE = false;
        TriggerHandler.BY_PASS_CASE_Trigger = false;
        TriggerHandler.BY_PASS_CASE_ON_INSERT = false;
        Case c = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.Status => 'New',
                    Case.RecordTypeId => CaseHelper.RT_ID_IT_HELPDESK,
                    Case.ContactId => con.Id
                }
            )
            .create()
            .getRecord();
        Test.stopTest();



        //System.assertEquals('TestTest', updatedCase.User_Name__c, 'Case User Name should be TestTest');
        //System.assertEquals('testTitle', updatedCase.Title__c, 'Case Title should be testTitle');
        //System.assertEquals('testDepartment', updatedCase.Department__c, 'Case Department should be testDepartment');
    }

    private static Case createCaseForMedalliaTests(Id recordTypeId, Id contactId) {
        return new Case(
            RecordTypeId = recordTypeId,
            ContactId = contactId,
            Callback_Contact_ID__c = contactId);
    }

    @isTest
    static void testCaseAssignmentToEntitlement() {
        new SObjectBuilder(Entitlement_Case_ReType_Configuration__c.sObjectType)
            .setField(Entitlement_Case_ReType_Configuration__c.Name, CaseHelper.RT_NAME_SYSTEM_OPERATIONS)
            .setField(Entitlement_Case_ReType_Configuration__c.SLAProcessId__c, [SELECT Id, Name FROM SlaProcess WHERE Name = 'Default' LIMIT 1].Id)
            .setField(Entitlement_Case_ReType_Configuration__c.SLAProcessName__c, 'Default')
            .setField(Entitlement_Case_ReType_Configuration__c.Business_Hours_Id__c, [SELECT Id FROM BusinessHours WHERE Name = 'Default' LIMIT 1].Id)
            .setField(Entitlement_Case_ReType_Configuration__c.Business_Hours_Name__c, 'Default')
            .create()
            .getRecord();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .create()
            .getRecord();

        Entitlement originalEnt = (Entitlement) new SObjectBuilder(Entitlement.sObjectType)
            .setField(Entitlement.Name, 'test entitlement')
            .setField(Entitlement.AccountId, acc.Id)
            .setField(Entitlement.Type, 'Phone Support')
            .setField(Entitlement.StartDate, System.today())
            .setField(Entitlement.EndDate, System.today())
            .create()
            .getRecord();

        Test.startTest();
            Case c = (Case) new SObjectBuilder(Case.SObjectType)
                .setField(Case.Type, 'Telecom Ops (US)')
                .setField(Case.AccountId, acc.Id)
                .setField(Case.Status, 'New')
                .setField(Case.Priority, 'Medium')
                .setField(Case.Origin, 'Phone')
                .setField(Case.RecordTypeId, CaseHelper.RT_ID_SYSTEM_OPERATIONS)
                .create()
                .getRecord();
        Test.stopTest();

        List<Entitlement> ents = new SupportEntitlementSelector().selectSupportEntitlements().executeQuery();
        List<Case> updatedCases = (List<Case>) new CaseSelector()
            .selectCasesDefault()
            .selectFields(new List<String>{'EntitlementId'})
            .setCondition('Id = \'' + c.Id + '\'')
            .executeQuery();
        Entitlement createdEnt;

        for (Entitlement e : ents) {
            if (e.Id != originalEnt.Id) {
                createdEnt = e;
            }
        }

        System.assertEquals(2, ents.size(), 'No duplicate support entitlements should be created');
        System.assertEquals(createdEnt.Id, updatedCases.get(0).EntitlementId, 'Case should be assigned to created entitlement');
    }

    @isTest
    static void testCaseAssignmentToEntitlementForBulk() {
        new SObjectBuilder(Entitlement_Case_ReType_Configuration__c.sObjectType)
            .setField(Entitlement_Case_ReType_Configuration__c.Name, CaseHelper.RT_NAME_SYSTEM_OPERATIONS)
            .setField(Entitlement_Case_ReType_Configuration__c.SLAProcessId__c, [SELECT Id, Name FROM SlaProcess WHERE Name = 'Default' LIMIT 1].Id)
            .setField(Entitlement_Case_ReType_Configuration__c.SLAProcessName__c, 'Default')
            .setField(Entitlement_Case_ReType_Configuration__c.Business_Hours_Id__c, [SELECT Id FROM BusinessHours WHERE Name = 'Default' LIMIT 1].Id)
            .setField(Entitlement_Case_ReType_Configuration__c.Business_Hours_Name__c, 'Default')
            .create()
            .getRecord();

        Account firstAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .create()
            .getRecord();

        Entitlement firstAccOriginalEnt = (Entitlement) new SObjectBuilder(Entitlement.sObjectType)
            .setField(Entitlement.Name, 'test entitlement')
            .setField(Entitlement.AccountId, firstAcc.Id)
            .setField(Entitlement.Type, 'Phone Support')
            .setField(Entitlement.StartDate, System.today())
            .setField(Entitlement.EndDate, System.today())
            .create()
            .getRecord();

        Account secondAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .create()
            .getRecord();

        Entitlement secondAccOriginalEnt = (Entitlement) new SObjectBuilder(Entitlement.sObjectType)
            .setField(Entitlement.Name, 'test entitlement')
            .setField(Entitlement.AccountId, secondAcc.Id)
            .setField(Entitlement.Type, 'Phone Support')
            .setField(Entitlement.StartDate, System.today())
            .setField(Entitlement.EndDate, System.today())
            .create()
            .getRecord();

        Test.startTest();
            List<Case> casesToInsert = new List<Case>();
            Case caseForFirstAcc = (Case) new SObjectBuilder(Case.SObjectType)
                .setField(Case.Type, 'Telecom Ops (US)')
                .setField(Case.AccountId, firstAcc.Id)
                .setField(Case.Status, 'New')
                .setField(Case.Priority, 'Medium')
                .setField(Case.Origin, 'Phone')
                .setField(Case.RecordTypeId, CaseHelper.RT_ID_SYSTEM_OPERATIONS)
                .build()
                .getRecord();
            casesToInsert.add(caseForFirstAcc);

            Case caseForSecondAcc = (Case) new SObjectBuilder(Case.SObjectType)
                .setField(Case.Type, 'Telecom Ops (US)')
                .setField(Case.AccountId, secondAcc.Id)
                .setField(Case.Status, 'New')
                .setField(Case.Priority, 'Medium')
                .setField(Case.Origin, 'Phone')
                .setField(Case.RecordTypeId, CaseHelper.RT_ID_SYSTEM_OPERATIONS)
                .build()
                .getRecord();
            casesToInsert.add(caseForSecondAcc);

            insert casesToInsert;
        Test.stopTest();

        List<Entitlement> ents = new SupportEntitlementSelector().selectSupportEntitlements().executeQuery();
        List<Case> updatedCases = (List<Case>) new CaseSelector()
            .selectCasesDefault()
            .selectFields(new List<String>{'EntitlementId'})
            .setCondition('Id IN (\'' + caseForFirstAcc.Id + '\', \'' + caseForSecondAcc.Id + '\')')
            .executeQuery();
        Case updatedCaseForFirstAcc;
        Case updatedCaseForSecondAcc;
        Entitlement createdEntForFirstAcc;
        Entitlement createdEntForSecondAcc;

        for (Case c : updatedCases) {
            if (c.Id == caseForFirstAcc.Id) {
                updatedCaseForFirstAcc = c;
            }
            if (c.Id == caseForSecondAcc.Id) {
                updatedCaseForSecondAcc = c;
            }
        }

        for (Entitlement e : ents) {
            if (e.Id == updatedCaseForFirstAcc.EntitlementId) {
                createdEntForFirstAcc = e;
            }
            if (e.Id == updatedCaseForSecondAcc.EntitlementId) {
                createdEntForSecondAcc = e;
            }
        }

        System.assertEquals(4, ents.size(), 'No duplicate support entitlements should be created');
        System.assertEquals(createdEntForFirstAcc.Id, updatedCaseForFirstAcc.EntitlementId, 'First case should be assigned to first created entitlement');
        System.assertEquals(createdEntForSecondAcc.Id, updatedCaseForSecondAcc.EntitlementId, 'Second case should be assigned to second created entitlement');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
     @isTest
    static void testForBeforetrigger() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'RC Internal'
                }
            )
            .create()
            .getRecord();

        User user = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestTest',
                    User.Username => 'Test!user@gmail.com',
                    User.Email => 'fake@mail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep',
                    User.Division => OpportunityHelper.USER_DIVISION_SALES_ENTERPRISE,
                    User.Title => 'testTitle',
                    User.Department => 'testDepartment'
                }
            )
            .create()
            .getRecord();

        Contact oldContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'testfake@mail.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

        Contact newContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'fake@mail.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
        Date refdate = System.today();
        Case c = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.Status => 'New',
                    Case.RecordTypeId => Schema.SObjectType.Case.getRecordTypeInfosByName().get('Product / Platform Issues').getRecordTypeId(),
                    Case.ContactId => oldContact.Id,
                    Case.inContact_BU_ID__c => 10,
                    Case.Provision_Date__c => refdate,
                    Case.inContact_Cluster__c => 'Test cluster',
                    case.Support_Jira__c => 'Test cluster',
                    Case.inContact_Status__c => 'Information Requested'
                }
            )
            .create()
            .getRecord();
         Case c1= (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.Status => 'New',
                    Case.RecordTypeId => Schema.SObjectType.Case.getRecordTypeInfosByName().get('Product / Platform Issues').getRecordTypeId(),
                    Case.ContactId => oldContact.Id,
                    Case.inContact_BU_ID__c => 10,
                    Case.Provision_Date__c => refdate,
                    Case.inContact_Cluster__c => 'Test cluster',
                    case.Support_Jira__c => 'Test cluster',
                    Case.inContact_Status__c => ''
                }
            )
            .create()
            .getRecord();

        Order ord = new Order(
            AccountId = acc.Id,
            Status = 'New',
            Booked_ProServ_OTP__c = 100,
            EffectiveDate = System.today(),
            Pricebook2Id = Test.getStandardPricebookId(),
            RecordTypeId = OrderHelper.RT_ID_PROSERV
        );
        insert ord;

        Test.startTest();
        TriggerHandler.BY_PASS_BEFORE = false;
        TriggerHandler.BY_PASS_CASE_ON_UPDATE= false;
        TriggerHandler.BY_PASS_CASE_Trigger = false;
        c.ContactId = newContact.Id;
        c.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('inContact Order').getRecordTypeId();
        c.Type = 'Platform Incident';
        c.Order__c = ord.id;
        c.inContact_BU_ID__c = 20;
        c.Provision_Date__c = refdate.addDays(10);
        c.inContact_Cluster__c = 'Test 2 Cluster';
        c.inContact_Status__c = 'Completed';
        c.Support_Jira__c=null;
        update c;
        c1.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('inContact Order').getRecordTypeId();
        c.Type = 'Platform Incident';
		c1.inContact_Status__c = 'Information Requested';
		update c1;
        Test.stopTest();


    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
     @isTest
    static void testForBeforetrigger2() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'RC Internal',
                    Account.RC_User_ID__c => '12345',
                    Account.Number_of_DL_s__c => 10,
                    Account.Current_Owner_Email__c => 'testacc@acc.com'
                }
            )
            .create()
            .getRecord();

        User user = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'RC Support Agent',
                    User.Username => 'Test!user@gmail.com',
                    User.Email => 'fake@mail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep',
                    User.Division => OpportunityHelper.USER_DIVISION_SALES_ENTERPRISE,
                    User.Title => 'testTitle',
                    User.Department => 'testDepartment'
                }
            )
            .create()
            .getRecord();

        Contact oldContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'testfake@mail.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

        Contact newContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'fake@mail.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

        system.runAs(user){
        Date refdate = System.today();
        List<Case> cseList = new List<Case>();
        Case c = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.Status => 'New',
                    Case.RecordTypeId => Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support - T1 (Shipping)').getRecordTypeId(),
                    Case.ContactId => oldContact.Id,
                    Case.inContact_BU_ID__c => 10,
                    Case.Provision_Date__c => refdate,
                    Case.inContact_Cluster__c => 'Test cluster',
                    Case.inContact_Status__c => 'Information Requested',
                    Case.SuppliedEmail => Label.NotForShippingEmail,
                    Case.OwnerId => user.id,
                    Case.Description => 'Test Customer contact email is given as a test Customer Name and also for many Cases. This description should satisfy RMA Comments and also include User_ID'
                }
            )
            .build()
            .getRecord();
        cseList.add(c);

        Case c2 = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.Status => 'New',
                    Case.RecordTypeId => Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support - T1 (Shipping)').getRecordTypeId(),
                    Case.ContactId => oldContact.Id,
                    Case.inContact_BU_ID__c => 10,
                    Case.Provision_Date__c => refdate,
                    Case.inContact_Cluster__c => 'Test cluster',
                    Case.inContact_Status__c => 'Information Requested',
                    Case.SuppliedEmail => Label.NotForShippingEmail,
                    Case.OwnerId => user.id,
                    Case.Description => 'This Customer contact email contact email is given as a test and also for many Cases. This description should satisfy User_ID and also 12345Customer Name'
                }
            )
            .build()
            .getRecord();
        cseList.add(c2);
        Case c3 = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.Status => 'New',
                    Case.RecordTypeId => Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support - T1 (Shipping)').getRecordTypeId(),
                    Case.ContactId => oldContact.Id,
                    Case.inContact_BU_ID__c => 10,
                    Case.Provision_Date__c => refdate,
                    Case.inContact_Cluster__c => 'Test cluster',
                    Case.inContact_Status__c => 'Information Requested',
                    Case.SuppliedEmail => Label.NotForShippingEmail,
                    Case.OwnerId => user.id,
                    Case.Description => 'Test Customer contact email is given as a test Customer Name and also for many Cases. This description should satisfy RMA Comments and also include User_ID'
                }
            )
            .build()
            .getRecord();
        cseList.add(c3);

        insert cseList;
        c3.status = 'Closed';
        update c3;
    }

    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
     @isTest
    static void testForBeforetrigger3() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'RC Internal',
                    Account.RC_User_ID__c => '12345',
                    Account.Number_of_DL_s__c => 10,
                    Account.Current_Owner_Email__c => 'testacc@acc.com',
                    Account.RC_Brand__c => 'Telus'

                }
            )
            .create()
            .getRecord();
        system.debug('acc---->'+acc.id);
        User user1 = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'RC Support Agent',
                    User.Username => 'Test!user@gmail.com',
                    User.Email => 'fake@mail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep',
                    User.Division => OpportunityHelper.USER_DIVISION_SALES_ENTERPRISE,
                    User.Title => 'testTitle',
                    User.Department => 'testDepartment'
                }
            )
            .create()
            .getRecord();


        Contact oldContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'testfake@mail.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
        Contact newContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'fake@mail.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
        Date refdate = System.today();
        system.debug('acc2---->'+acc.id);
        Case c3 = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.Status => 'New',
                    Case.AccountId  => acc.id,
                    Case.ContactId   => oldContact.id,
                    Case.RecordTypeId => Schema.SObjectType.Case.getRecordTypeInfosByName().get('Porting - Out').getRecordTypeId(),
                    Case.inContact_BU_ID__c => 10,
                    Case.Provision_Date__c => refdate,
                    Case.inContact_Cluster__c => 'Test cluster',
                    Case.inContact_Status__c => 'Information Requested',
                    Case.SuppliedEmail => Label.NotForShippingEmail,
                    Case.OwnerId => user1.id,
                    Case.Porting_Estimated_Completion_Date__c => date.parse('9/10/2013'),
                    Case.Description => 'Test Customer contact email is given as a test Customer Name and also for many Cases. This description should satisfy RMA Comments and also include User_ID'
                }
            )
            .create()
            .getRecord();
            Test.startTest();
        system.debug('Case3 id in test class--->' +c3.id+'accid'+c3.AccountId);
        system.debug('Account for c3'+acc.id);
        TriggerHandler.BY_PASS_BEFORE = false;
        TriggerHandler.BY_PASS_CASE_ON_UPDATE= false;
        TriggerHandler.BY_PASS_CASE_Trigger = false;
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
     @isTest
    static void testForBeforetrigger4() {
        Medallia_Credentials__c credentials = new Medallia_Credentials__c();
        credentials.isMedallia__c = false;
        credentials.Name = 'Medallia';
        insert credentials;
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc',
                    Account.RC_Brand__c => 'RingCentral'
                }
            )
            .create()
            .getRecord();

        Contact cntc = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'testfake@mail.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

        User caseOwner = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestCaseOwner',
                    User.Username => 'CaseOwner!user@gmail.com',
                    User.Email => 'CaseOwner_user@gmail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep',
                    User.Division => OpportunityHelper.USER_DIVISION_SALES_ENTERPRISE
                }
            )
            .create()
            .getRecord();

        System.runAs(caseOwner) {
            Case testCase1 = createCaseForMedalliaTests(CaseHelper.RT_ID_SUPPORT_T1, cntc.Id);
            testCase1.CloseCustomerSupportLevel1__c = 'some value to pass valiation';
            insert testCase1;

            Case testCase2 = createCaseForMedalliaTests(CaseHelper.RT_ID_SUPPORT_T2, cntc.Id);
            testCase2.Support_Disposition_Level_1__c = 'some value to pass valiation';
            testCase2.CloseCustomerSupportLevel1__c = 'some value to pass valiation';
            insert testCase2;

            Case testCase3 = createCaseForMedalliaTests(CaseHelper.RT_ID_SUPPORT_T2, cntc.Id);
            testCase3.Support_Disposition_Level_1__c = 'some value to pass valiation';
            testCase3.CloseCustomerSupportLevel1__c = 'some value to pass valiation';
            insert testCase3;

            Test.startTest();
            TriggerHandler.BY_PASS_BEFORE = false;
            testCase1.Status = CaseHelper.CASE_STATUS_CLOSED;
            testCase1.Support_Disposition_Level_1__c = 'Account Federation';
            testCase1.Support_Disposition_Level_2__c = 'Add/Remove';
            testCase1.Support_Disposition_Level_3__c = 'Accessibility';
            testCase1.AccountId = acc.id;
           	testCase1.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support - T1 (VAR & Partners)').getRecordTypeId();
            testCase2.Status = CaseHelper.CASE_STATUS_CLOSED_NO_RESPONSE;
            testCase2.AccountId = acc.id;
            testCase3.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Porting - In (RC UK)').getRecordTypeId();
            testCase3.Porting_Estimated_Completion_Date__c = date.parse('9/10/2013');

            update new Case[] { testCase1, testCase2 , testCase3};
            Test.stopTest();

        }


    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
     @isTest
    static void testForBeforetrigger5() {
        Account acc = new Account();
        acc.Name = 'RC Internal';
        acc.RC_User_ID__c = '12345';
        acc.Number_of_DL_s__c = 10;
        acc.Current_Owner_Email__c = 'testacc@acc.com';
        insert acc;
        system.debug('acc---->'+acc.id);
        User user1 = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'RC Support Agent',
                    User.Username => 'Test!user@gmail.com',
                    User.Email => 'fake@mail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep',
                    User.Division => OpportunityHelper.USER_DIVISION_SALES_ENTERPRISE,
                    User.Title => 'testTitle',
                    User.Department => 'testDepartment'
                }
            )
            .create()
            .getRecord();

        Contact oldContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'testfake@mail.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

        Contact newContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'fake@mail.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
        test.startTest();
         Survey__c surveyObj1 = new Survey__c();
                surveyObj1.SurveyType__c = 'IT Helpdesk CSAT';
                surveyObj1.Name = 'Test Impl';
                surveyObj1.Contact__c = newContact.Id;
                surveyObj1.Contact_Email__c = 'test@test.com';
                insert surveyObj1;

        Date refdate = System.today();
        system.debug('acc2---->'+acc.id);
        Case c3 = new Case();
        c3.AccountId = [select id from Account where id =: acc.id].id;

        c3.SuppliedEmail = Label.NotForShippingEmail;
        c3.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Porting - Out').getRecordTypeId();
        c3.inContact_BU_ID__c = 10;
        c3.Provision_Date__c = refdate;
        c3.inContact_Cluster__c = 'Test cluster';
        c3.inContact_Status__c =  'Information Requested';
        c3.Status = 'New';
        c3.OwnerId = user1.id;
        c3.Porting_Estimated_Completion_Date__c = date.parse('9/10/2013');
        c3.Description = 'Test Customer contact email is given as a test Customer Name and also for many Cases. This description should satisfy RMA Comments and also include User_ID';

        insert c3;
        system.debug('Case3 id in test class--->' +c3.id+'accid'+c3.AccountId);
        system.debug('Account for c3'+acc.id);
        TriggerHandler.BY_PASS_BEFORE = false;
        TriggerHandler.BY_PASS_CASE_ON_UPDATE= false;
        TriggerHandler.BY_PASS_CASE_Trigger = false;
        c3.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Internal Business Services').getRecordTypeId();
        c3.Status = 'Closed';
        c3.ContactId = newContact.Id;
        c3.Request_Type__c = 'EXEC';
        c3.Is_Quickwin__c = 'Support';
        c3.Resolution_Code__c = 'Resolved Successfully';
        update c3;

        test.stopTest();

    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testForBeforetrigger6() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'RC Internal',
                    Account.RC_User_ID__c => '12345',
                    Account.Number_of_DL_s__c => 10,
                    Account.Current_Owner_Email__c => 'testacc@acc.com'
                }
            )
            .create()
            .getRecord();

        Profile p = [SELECT Id FROM Profile WHERE Name='Support T3'];
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name='Permission_Set_for_Exclusion_Users'];
        User user1 = new User(Alias = 'standt2', Email='standarduser@testorg.com',
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                          LocaleSidKey='en_US', ProfileId = p.Id,
                          TimeZoneSidKey='America/Los_Angeles', UserName='standarduser121@testorg.com', Team__c = 'Test Team');
        insert user1;
        PermissionSetAssignment psa = new PermissionSetAssignment
        (PermissionSetId = ps.Id, AssigneeId = user1.id);
        //insert psa;
        test.startTest();

        Contact oldContact = (Contact) new SObjectBuilder(Contact.SObjectType)
        .setFields(
            new Map<SObjectField, Object>{
                Contact.FirstName => 'Test1',
                Contact.LastName => 'Test1',
                Contact.AccountId => acc.Id,
                Contact.Email => 'testfake@mail.com',
                Contact.Phone => '1234567890',
                Contact.Preferred_Language__c => 'en_US'
            }
        )
        .create()
        .getRecord();

        Contact newContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'fake@mail.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

        Date refdate = System.today();
        List<Case> cseList = new List<Case>();

        List<Case> insCase = new List<Case>();
        Case c4 = new Case();
        c4.ContactId = oldContact.Id;
        c4.SuppliedEmail = Label.NotForShippingEmail;
        c4.inContact_BU_ID__c = 10;
        c4.Provision_Date__c = refdate;
        c4.inContact_Cluster__c = 'Test cluster';
        c4.inContact_Status__c =  'Information Requested';
        c4.Status = 'New';
        c4.OwnerId = user1.id;
        c4.IsEscalated = true;
        c4.Priority = 'Medium';

        c4.Description = 'Test Customer contact email is given as a test Customer Name and also for many Cases. This description should satisfy RMA Comments and also include User_ID';


        //insCase.add(c4);
        insert c4;



        TriggerHandler.BY_PASS_BEFORE = false;
        TriggerHandler.BY_PASS_CASE_ON_UPDATE= false;
        TriggerHandler.BY_PASS_CASE_Trigger = false;
        c4.inContact_BU_ID__c  = 40;

        update c4;

        test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
     @isTest
    static void testForBeforetrigger7() {
        List<User> users = new List<User>();
        Profile p = [SELECT Id FROM Profile WHERE Name='Support T3'];
        User manageru = new User(Alias = 'standt', Email='standarduser2@testorg.com',
           EmailEncodingKey='UTF-8', LastName='Testing12345', LanguageLocaleKey='en_US',
           LocaleSidKey='en_US', ProfileId = p.Id,
           TimeZoneSidKey='America/Los_Angeles', UserName='standarduser1222@testorg.com');
        users.add(manageru);

         User manageru2 = new User(Alias = 'standtee', Email='standarwwduser2@testorg.com',
           EmailEncodingKey='UTF-8', LastName='Testing123451', LanguageLocaleKey='en_US',
           LocaleSidKey='en_US', ProfileId = p.Id,
           TimeZoneSidKey='America/Los_Angeles', UserName='standarduser341222@testorg.com');
        users.add(manageru2);

        Date opsleavedate = System.today();
        User u = new User(Alias = 'standt2', Email='standarduser@testorg.com',
           EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
           LocaleSidKey='en_US', ProfileId = p.Id,  Ops_TeamMemName__c = manageru2.Id, Ops_LeaveFromDate__c = opsleavedate, Ops_LeaveToDate__c = opsleavedate.addDays(20),
           TimeZoneSidKey='America/Los_Angeles', UserName='standarduser121@testorg.com', Team__c = 'Test Team', managerId = manageru.Id);
        users.add(u);
        insert users;

        Account acc = new Account();
        acc.Name = 'RC Internal';
        acc.RC_User_ID__c = '12345';
        acc.Number_of_DL_s__c = 10;
        acc.Current_Owner_Email__c = 'testacc@acc.com';
        insert acc;
        system.debug('acc---->'+acc.id);
        User user1 = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'RC Support Agent',
                    User.Username => 'Test!user@gmail.com',
                    User.Email => 'fake@mail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep',
                    User.Division => OpportunityHelper.USER_DIVISION_SALES_ENTERPRISE,
                    User.Title => 'testTitle',
                    User.Department => 'testDepartment'
                }
            )
            .create()
            .getRecord();

            Contact oldContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'testfake@mail.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

            Contact newContact = (Contact) new SObjectBuilder(Contact.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Contact.FirstName => 'Test1',
                        Contact.LastName => 'Test1',
                        Contact.AccountId => acc.Id,
                        Contact.Email => 'fake@mail.com',
                        Contact.Phone => '1234567890',
                        Contact.Preferred_Language__c => 'en_US'
                    }
                )
                .create()
                .getRecord();
        test.startTest();
         Survey__c surveyObj1 = new Survey__c();
                surveyObj1.SurveyType__c = 'IT Helpdesk CSAT';
                surveyObj1.Name = 'Test Impl';
                surveyObj1.Contact__c = newContact.Id;
                surveyObj1.Contact_Email__c = 'test@test.com';
                insert surveyObj1;

        Date refdate = System.today();
        system.debug('acc2---->'+acc.id);
        Case c3 = new Case();
        c3.AccountId = [select id from Account where id =: acc.id].id;

        c3.SuppliedEmail = Label.NotForShippingEmail;
        c3.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('IT Deskside Support').getRecordTypeId();
        c3.inContact_BU_ID__c = 10;
        c3.Provision_Date__c = refdate;
        c3.inContact_Cluster__c = 'Test cluster';
        c3.inContact_Status__c =  'Information Requested';
        c3.Status = 'New';
        c3.OwnerId = u.id;
        c3.Description = 'Test Customer contact email is given as a test Customer Name and also for many Cases. This description should satisfy RMA Comments and also include User_ID';

        insert c3;
        system.debug('Case3 id in test class--->' +c3.id+'accid'+c3.AccountId);
        system.debug('Account for c3'+acc.id);
        TriggerHandler.BY_PASS_BEFORE = false;
        TriggerHandler.BY_PASS_CASE_ON_UPDATE= false;
        TriggerHandler.BY_PASS_CASE_Trigger = false;
        c3.Status = 'Closed';
        c3.ContactId = oldContact.Id;
        c3.Request_Type__c = 'EXEC';
        c3.Is_Quickwin__c = 'Support';
        c3.Resolution_Code__c = 'Resolved Successfully';
        update c3;

        test.stopTest();

    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testForBeforetrigger8() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'RC Internal',
                    Account.RC_User_ID__c => '12345',
                    Account.Number_of_DL_s__c => 10,
                    Account.Current_Owner_Email__c => 'testacc@acc.com'
                }
            )
            .create()
            .getRecord();

        Profile p = [SELECT Id FROM Profile WHERE Name='Support T3'];
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name='Permission_Set_for_Exclusion_Users'];
        User user1 = new User(Alias = 'standt2', Email='standarduser@testorg.com',
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                          LocaleSidKey='en_US', ProfileId = p.Id,
                          TimeZoneSidKey='America/Los_Angeles', UserName='standarduser121@testorg.com', Team__c = 'Test Team');
        insert user1;
        PermissionSetAssignment psa = new PermissionSetAssignment
        (PermissionSetId = ps.Id, AssigneeId = user1.id);

         Employee__c empObj1 = new Employee__c();
                empObj1.User__c = user1.Id;
                empObj1.First_Name__c = 'TestFName';
                empObj1.Last_Name__c = 'TestLName';
                empObj1.Email__c = 'standarduser@testorg.com';
                empObj1.Location__c = 'Denver, US';
                empObj1.Department__c = 'IT';
                empObj1.Team__c = 'Marketing';
                empObj1.Division__c = 'CV';
                empObj1.SPID__c = '12345';

                insert empObj1  ;

           Employee__c empObj2 = new Employee__c();
                empObj2.User__c = user1.Id;
                empObj2.First_Name__c = 'TestFName1';
                empObj2.Last_Name__c = 'TestLName1';
                empObj2.Email__c = 'standarduser11@testorg.com';
                empObj2.Location__c = 'Denver, US';
                empObj2.Department__c = 'IT';
                empObj2.Team__c = 'Marketing';
                empObj2.Division__c = 'CV';
                empObj2.SPID__c = '12346';
                empObj2.Manager_Employee_Number__c = empObj1.id;

                insert empObj2  ;
            Contact oldContact = (Contact) new SObjectBuilder(Contact.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Contact.FirstName => 'Test1',
                        Contact.LastName => 'Test1',
                        Contact.AccountId => acc.Id,
                        Contact.Email => 'testfake@mail.com',
                        Contact.Phone => '1234567890',
                        Contact.Preferred_Language__c => 'en_US'
                    }
                )
                .create()
                .getRecord();

            Contact newContact = (Contact) new SObjectBuilder(Contact.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Contact.FirstName => 'Test1',
                        Contact.LastName => 'Test1',
                        Contact.AccountId => acc.Id,
                        Contact.Email => 'fake@mail.com',
                        Contact.Phone => '1234567890',
                        Contact.Preferred_Language__c => 'en_US'
                    }
                )
                .create()
                .getRecord();

        Date refdate = System.today();
        List<Case> cseList = new List<Case>();

        List<Case> insCase = new List<Case>();
        System.runas(user1){
            try{
        Case c5 = new Case();
        c5.ContactId = oldContact.Id;
            c5.SuppliedEmail = Label.NotForShippingEmail;
            c5.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Internal OPS to OPS').getRecordTypeId();
            c5.inContact_BU_ID__c = 10;
            c5.Provision_Date__c = refdate;
            c5.inContact_Cluster__c = 'Test cluster';
            c5.inContact_Status__c =  'Information Requested';
            c5.Status = 'New';
            c5.OwnerId = user1.id;
            c5.IsEscalated = false;
            c5.Priority = 'Medium';
            c5.Description = 'Test Customer contact email is given as a test Customer Name and also for many Cases. This description should satisfy RMA Comments and also include User_ID';

            insert c5;
            test.startTest();
            TriggerHandler.BY_PASS_BEFORE = false;
            TriggerHandler.BY_PASS_CASE_ON_UPDATE= false;
            TriggerHandler.BY_PASS_CASE_Trigger = false;
            c5.inContact_BU_ID__c = 120;
            c5.inContact_Status__c = 'Information Requested';
            update c5;

        test.stopTest();
            }catch(DmlException ex){}
        }
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testForBeforetrigger9() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'RC Internal',
                    Account.RC_User_ID__c => '12345',
                    Account.Number_of_DL_s__c => 10,
                    Account.Current_Owner_Email__c => 'testacc@acc.com'
                }
            )
            .create()
            .getRecord();

        Profile p = [SELECT Id FROM Profile WHERE Name='Support T3'];
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name='Permission_Set_for_Exclusion_Users'];
        User user1 = new User(Alias = 'standt2', Email='standarduser@testorg.com',
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                          LocaleSidKey='en_US', ProfileId = p.Id,
                          TimeZoneSidKey='America/Los_Angeles', UserName='standarduser121@testorg.com', Team__c = 'Test Team');
        insert user1;
        PermissionSetAssignment psa = new PermissionSetAssignment
        (PermissionSetId = ps.Id, AssigneeId = user1.id);
        test.startTest();

        Contact oldContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'testfake@mail.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

        Contact newContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'fake@mail.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

        Date refdate = System.today();
        List<Case> cseList = new List<Case>();

        List<Case> insCase = new List<Case>();
        System.runAs(user1){
            try{
        Case c6 = new Case();
        c6.ContactId = oldContact.Id;
        c6.SuppliedEmail = Label.NotForShippingEmail;
        c6.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Internal OPS to OPS').getRecordTypeId();
        c6.inContact_BU_ID__c = 10;
        c6.Provision_Date__c = refdate;
        c6.inContact_Cluster__c = 'Test cluster';
        c6.inContact_Status__c =  'Information Requested';
        c6.Status = 'New';
        c6.OwnerId = user1.id;
        c6.IsEscalated = false;
    // c6.OPS_ESCALATED__c = null;
        c6.Priority = 'Medium';
        //insCase.add(c6);

        insert c6;

        TriggerHandler.BY_PASS_BEFORE = false;
        TriggerHandler.BY_PASS_CASE_ON_UPDATE= false;
        TriggerHandler.BY_PASS_CASE_Trigger = false;
        c6.inContact_BU_ID__c  = 80;
        update c6;
        test.stopTest();
        }catch(DmlException ex){}
        }
        //test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testForBeforetrigger10() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'RC Internal',
                    Account.RC_User_ID__c => '12345',
                    Account.Number_of_DL_s__c => 10,
                    Account.Current_Owner_Email__c => 'testacc@acc.com'
                }
            )
            .create()
            .getRecord();

        Profile p = [SELECT Id FROM Profile WHERE Name='Support - TAM'];
        PermissionSet pset = [SELECT Id FROM PermissionSet WHERE Name='Permission_Set_for_Exclusion_Users'];
        User user1 = new User(Alias = 'standt2', Email='standarduser@testorg.com',
                          EmailEncodingKey='UTF-8', LastName='RCESB', LanguageLocaleKey='en_US',
                          LocaleSidKey='en_US', ProfileId = p.Id,
                          TimeZoneSidKey='America/Los_Angeles', UserName='standarduser121@testorg.com', Team__c = 'Test Team');
        insert user1;
        PermissionSetAssignment psa = new PermissionSetAssignment
        (PermissionSetId = pset.Id, AssigneeId = user1.id);
       // insert psa;

        test.startTest();

        Profile p2 = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User user2 = new User(Alias = 'standt23', Email='standarduser3@testorg.com',
                            EmailEncodingKey='UTF-8', LastName='RCESB2', LanguageLocaleKey='en_US',
                            LocaleSidKey='en_US', ProfileId = p2.Id,
                            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser1212@testorg.com', Team__c = 'Test Team');

        System.runAs(user2){
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Support_Agent_Porting_meta'];
            insert new PermissionSetAssignment(AssigneeId = user1.id, PermissionSetId = ps.Id);
        }

        Contact oldContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'testfake@mail.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

        Contact newContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'fake@mail.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

            Date refdate = System.today();
            List<Case> updCase = new List<Case>();

            List<Case> insCase = new List<Case>();

            Case c5 = new Case();
            c5.ContactId = oldContact.Id;
            c5.SuppliedEmail = Label.NotForShippingEmail;
            c5.inContact_BU_ID__c = 10;
            c5.Provision_Date__c = refdate;
            c5.inContact_Cluster__c = 'Test cluster';
            c5.inContact_Status__c =  'Information Requested';
            c5.OwnerId = user1.id;
            c5.IsEscalated = false;
            c5.Priority = 'Medium';
            c5.Description = 'Test Customer contact email is given as a test Customer Name and also for many Cases. This description should satisfy RMA Comments and also include User_ID';
            insCase.add(c5);



        Case c6 = new Case();
            c6.ContactId = oldContact.Id;
            c6.SuppliedEmail = Label.NotForShippingEmail;
            c6.inContact_BU_ID__c = 10;
            c6.Provision_Date__c = refdate;
            c6.inContact_Cluster__c = 'Test cluster';
            c6.inContact_Status__c =  'Information Requested';
            c6.OwnerId = user1.id;
            c6.IsEscalated = false;
            c6.Priority = 'Medium';

            insCase.add(c6);

            Case c7 = new Case();
            c7.ContactId = oldContact.Id;
            c7.SuppliedEmail = Label.NotForShippingEmail;
            c7.inContact_BU_ID__c = 10;
            c7.Provision_Date__c = refdate;
            c7.inContact_Cluster__c = 'Test cluster';
            c7.inContact_Status__c =  'Information Requested';
            c7.OwnerId = user1.id;
            c7.IsEscalated = false;
            c7.Priority = 'Medium';


        insCase.add(c7);

        insert insCase;
            TriggerHandler.BY_PASS_BEFORE = false;
            TriggerHandler.BY_PASS_CASE_ON_UPDATE= false;
            TriggerHandler.BY_PASS_CASE_Trigger = false;
            c5.inContact_BU_ID__c = 120;
            c5.Porting_Admin_Last_Change_Date__c = refdate.addDays(3);
            updcase.add(c5);

        c6.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Porting - In (TELUS)').getRecordTypeId();
        c6.Type = 'Platform Incident';
        c6.Support_Escalate_To__c = 'Platform Incident';
        c6.IsUpdatePermitted__c = true;
        c6.Porting_Estimated_Completion_Date__c = date.parse('9/10/2013');

        updcase.add(c6);

        update updcase;
        test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testForBeforetrigger11() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'RC Internal'
                }
            )
            .create()
            .getRecord();
        Order ord = new Order(
            AccountId = acc.Id,
            Status = 'New',
            Booked_ProServ_OTP__c = 100,
            EffectiveDate = System.today(),
            Pricebook2Id = Test.getStandardPricebookId(),
            RecordTypeId = OrderHelper.RT_ID_PROSERV
        );
        insert ord;
        List<Case> insCase = new List<Case>();
        List<Case> updCase = new List<Case>();
         Case c = new Case();
        c.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('inContact Order').getRecordTypeId();
        c.Type = 'Platform Incident';
        c.Support_Escalate_To__c = 'Platform Incident';
        insCase.add(c);
        Case c2 = new Case();
        c2.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('inContact Order').getRecordTypeId();
        c2.Type = 'Platform Incident';
        c2.Support_Escalate_To__c = 'Platform Incident';
        insCase.add(c2);
        insert insCase;
        c.inContact_BU_ID__c = 20;
        c.inContact_Status__c = 'Information Requested';
        c.Order__c = ord.id;
        c2.inContact_BU_ID__c = 20;
        c2.inContact_Status__c = 'Information Requested';
        c2.Order__c = ord.id;
        c2.Provision_Date__c = System.today();
        c2.inContact_Cluster__c = 'Test cluster';
        updCase.add(c);
        updCase.add(c2);
        update updCase;
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testForBeforetrigger12() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc',
                    Account.RC_Brand__c => 'RingCentral'
                }
            )
            .create()
            .getRecord();

        Contact cntc = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'something@mostcommon.fake',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();


        Emails__c emailSettings = new Emails__c();
        emailSettings.Name = 'RC_EDS_Acknowledgement';
        emailSettings.Description__c = 'test;test';
        emailSettings.Email_Address__c = 'something@mostcommon.fake';
        insert emailSettings;

        Case c2 = new Case();
        c2.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('inContact Order').getRecordTypeId();
        c2.Type = 'Platform Incident';
        c2.Support_Escalate_To__c = 'Platform Incident';
        c2.AccountId = acc.Id;
        c2.SuppliedEmail = 'something@mostcommon.fake';
        c2.ContactId = cntc.Id;

        test.startTest();
        insert c2;

        TriggerHandler.BY_PASS_BEFORE = false;
        TriggerHandler.BY_PASS_AFTER = false;
        TriggerHandler.BY_PASS_CASE_ON_UPDATE= false;
        TriggerHandler.BY_PASS_CASE_Trigger = false;

        List<Case> c = [SELECT Id, Support_Escalate_To__c FROM Case where type = 'Platform Incident' LIMIT 1];
        c[0].Support_Escalate_To__c = 'RC Engage Digital Support';
        c[0].Last_Case_Comment__c = 'test';
        c[0].isLastCaseCommentPublic__c = true;
        c[0].Last_Public_Comment_Timestamp__c = system.now();
        update c;
        test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testForBeforetrigger13() {
        List<Group> engQ = [Select Id, DeveloperName From Group WHERE Type = :GroupHelper.GROUP_TYPE_QUEUE AND DeveloperName ='RC_Engage_Digital_Support' limit 1];

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc',
                    Account.RC_Brand__c => 'RingCentral'
                }
            )
            .create()
            .getRecord();

        Contact cntc = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'something@mostcommon.fake',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

        Emails__c emailSettings = new Emails__c();
        emailSettings.Name = 'RC_EDS_Acknowledgement';
        emailSettings.Description__c = 'test;test';
        emailSettings.Email_Address__c = 'something@mostcommon.fake';
        insert emailSettings;

        Case c2 = new Case();
        c2.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support-Case').getRecordTypeId();
        c2.OwnerId =  engQ[0].Id;
        c2.AccountId = acc.Id;
        c2.ContactId = cntc.Id;
        c2.SuppliedEmail = 'something@mostcommon.fake';
        test.startTest();
        insert c2;
        test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testForBeforetrigger14() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc',
                    Account.RC_Brand__c => 'RingCentral'
                }
            )
            .create()
            .getRecord();

        Contact cntc = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'something@mostcommon.fake',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();


        Emails__c emailSettings = new Emails__c();
        emailSettings.Name = 'RC_EDS_Acknowledgement';
        emailSettings.Description__c = 'test;test';
        emailSettings.Email_Address__c = 'something@mostcommon.fake';
        insert emailSettings;

        InContactConnectionId__c ins = new InContactConnectionId__c();
        ins.Id__c = [SELECT Id FROM PartnerNetworkConnection WHERE ConnectionName = 'inContact, Inc.'].Id;
        ins.SetupOwnerId = userinfo.getuserid();
        insert ins;

        Case c2 = new Case();
        c2.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('inContact Order').getRecordTypeId();
        c2.Type = 'Platform Incident';
        c2.Support_Escalate_To__c = 'Platform Incident';
        c2.AccountId = acc.Id;
        c2.SuppliedEmail = 'something@mostcommon.fake';
        c2.ContactId = cntc.Id;

        test.startTest();
        insert c2;

        TriggerHandler.BY_PASS_BEFORE = false;
        TriggerHandler.BY_PASS_AFTER = false;
        TriggerHandler.BY_PASS_CASE_ON_UPDATE= false;
        TriggerHandler.BY_PASS_CASE_Trigger = false;

        List<Case> c = [SELECT Id, Support_Escalate_To__c FROM Case where type = 'Platform Incident' LIMIT 1];
        c[0].Support_Escalate_To__c = 'inContact Support';
        c[0].Status = 'WIP by Partner';
        c[0].CC_Order_Type__c= 'Change Order';
        update c;
        test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testCaseSendInvitation() {
        Id CaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('CERT').getRecordTypeId();
        Id AccountRecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account').getRecordTypeId();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.recordtypeId => AccountRecordtypeId,
                        Account.Name => 'Test Account',
                        Account.RC_User_ID__c => '12345',
                        Account.Number_of_DL_s__c => 10,
                        Account.RC_Brand__c => 'RingCentral'
                        }
            )
            .create()
            .getRecord();

        Contact newContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                        Contact.LastName => 'Test1',
                        Contact.AccountId => acc.Id,
                        Contact.Email => 'fake@mail.com',
                        Contact.Phone => '1234567890',
                        Contact.Preferred_Language__c => 'en_US'
                        }
            )
            .create()
            .getRecord();

        Case c = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.Status => 'New',
                        Case.RecordTypeId => CaseRecordTypeId,
                        Case.AccountId => acc.Id,
                        Case.ContactId => newContact.Id,
                        Case.Call_Outcome__c => 'Saved',
                        Case.Appeasement_Offered__c => 'Downgrade',
                        Case.Subject => 'Test',
                        Case.Description => 'Test',
                        Case.Origin => 'Phone',
                        Case.Competitive_Threat__c => 'No Competitive Threat'
                        }
            )
            .create()
            .getRecord();

        TriggerHandler.BY_PASS_BEFORE = false;
        TriggerHandler.BY_PASS_CASE_ON_UPDATE= false;
        c.Status = 'Closed';
        c.Case_Reason__c = 'Campaign Request';
        Test.startTest();
        update c;
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
   @isTest
    static void testForBeforetrigger15() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'RC Internal'
                }
            )
            .create()
            .getRecord();

        User user = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestTest',
                    User.Username => 'curtis.peterson@ringcentral.com',
                    User.Email => 'fake@mail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep',
                    User.Division => OpportunityHelper.USER_DIVISION_SALES_ENTERPRISE,
                    User.Title => 'testTitle',
                    User.Department => 'testDepartment'
                }
            )
            .create()
            .getRecord();

        Contact oldContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'testfake@mail.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

        Contact newContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'fake@mail.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
        Date refdate = System.today();

        Order ord = new Order(
            AccountId = acc.Id,
            Status = 'New',
            Booked_ProServ_OTP__c = 100,
            EffectiveDate = System.today(),
            Pricebook2Id = Test.getStandardPricebookId(),
            RecordTypeId = OrderHelper.RT_ID_PROSERV
        );
        insert ord;


        TriggerHandler.BY_PASS_BEFORE = false;
        TriggerHandler.BY_PASS_CASE_ON_UPDATE= false;
        TriggerHandler.BY_PASS_CASE_Trigger = false;
        System.runAs(user){
            try{
         Case c11 = new case();
        c11.ContactId = oldContact.Id;
        c11.SuppliedEmail = Label.NotForShippingEmail;
        c11.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Internal OPS to OPS').getRecordTypeId();
        c11.inContact_BU_ID__c = 10;
        c11.Provision_Date__c = refdate;
        c11.inContact_Cluster__c = 'Test cluster';
        c11.inContact_Status__c =  'Information Requested';
        c11.Status = 'New';
        c11.IsEscalated = false;
        c11.OwnerId = user.id;
        c11.Priority = 'Medium';

        c11.Description = 'Test Customer contact email is given as a test Customer Name and also for many Cases. This description should satisfy RMA Comments and also include User_ID';
		insert c11;
            }catch(DmlException ex){
                system.debug('Exception++ '+ex.getMessage());
            }
        }

    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testForBeforetrigger15v2() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'RC Internal'
                }
            )
            .create()
            .getRecord();

        User user1 = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestTest',
                    User.Username => 'curtis.peterson@ringcentral.com',
                    User.Email => 'fake@mail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'Support T3'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep',
                    User.Division => OpportunityHelper.USER_DIVISION_SALES_ENTERPRISE,
                    User.Title => 'testTitle',
                    User.Department => 'testDepartment'
                }
            )
            .create()
            .getRecord();

        Contact oldContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'testfake@mail.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

        Contact newContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'fake@mail.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
        Date refdate = System.today();

        Order ord = new Order(
            AccountId = acc.Id,
            Status = 'New',
            Booked_ProServ_OTP__c = 100,
            EffectiveDate = System.today(),
            Pricebook2Id = Test.getStandardPricebookId(),
            RecordTypeId = OrderHelper.RT_ID_PROSERV
        );
        insert ord;

        TriggerHandler.BY_PASS_BEFORE = false;
        TriggerHandler.BY_PASS_CASE_ON_UPDATE= false;
        TriggerHandler.BY_PASS_CASE_Trigger = false;
        System.runAs(user1){

        try{
            Case c3 = new Case();
            c3.AccountId = acc.id;
            c3.SuppliedEmail = Label.NotForShippingEmail;
            c3.ContactId = oldContact.Id;
            c3.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Reseller Team').getRecordTypeId();
            c3.inContact_BU_ID__c = 10;
            c3.Provision_Date__c = refdate;
            c3.inContact_Cluster__c = 'Test cluster';
            c3.inContact_Status__c =  'Information Requested';
            c3.Status = 'New';
            c3.OwnerId = user1.id;
            c3.Porting_Estimated_Completion_Date__c = date.parse('9/10/2013');


            c3.Description = 'Test Customer contact email is given as a test Customer Name and also for many Cases. This description should satisfy RMA Comments and also include User_ID';

            Test.startTest();
                insert c3;
            Test.stopTest();
                }catch(DmlException ex){
                    system.debug('Exception++ '+ex.getMessage());
                }
            }

    }

    @isTest
    static void testPopulateCaseFields() {
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'Test Account'
                }
            )
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.Name => 'TestOpportunity',
                    Opportunity.Total_MRR__c => 100
                }
            )
            .create()
            .getRecord();

        Case testCase = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.Status => CaseHelper.CASE_STATUS_NEW,
                    Case.AccountId => testAcc.Id,
                    Case.Opportunity_Reference__c => testOpp.Id
                }
            )
            .create()
            .getRecord();

        Test.startTest();

        testCase.Status = CaseHelper.CASE_STATUS_WIP;
        update testCase;

        Case reselectedCase = (Case) new ListOptional(new CaseSelector()
            .selectCasesByIds(new Set<Id>{testCase.Id})
            .executeQuery()
        ).getFirst();

        System.assertNotEquals(null, reselectedCase.TimeFromCreatedToWIP__c, 'TimeFromCreatedToWIP Field should be populated');

        testCase.Status = CaseHelper.CASE_STATUS_CLOSED;
        testCase.FirstResponseTime__c = '0:1:0';
        update testCase;

        reselectedCase = (Case) new ListOptional(new CaseSelector()
            .selectCasesByIds(new Set<Id>{testCase.Id})
            .executeQuery()
        ).getFirst();

        System.assertNotEquals(null, reselectedCase.TimeFromWIPToClosed__c, ' TimeFromWIPToClosed Field should be populated');
        System.assertNotEquals(null, reselectedCase.TimeFromFirstResponseToClosed__c, ' TimeFromFirstResponseToClosed Field should be populated');

        Test.stopTest();
    }

    @isTest
    static void testChangeCaseOwnerToProServNAEnterpriseQueue() {
        User userObj = createUser('TestSalesManager1', 'SalesManager1!user@gmail.com', UserHelper.SEGMENT_ENTERPRISE);
        Case testCase;
        System.runAs(userObj) {
            Triggers.switchOff();
            Account testAcc = createTestAccount();
            Opportunity testOpp = createTestOpportunity(testAcc);
            Quote proServQuote = createTestProServQuote(testOpp);
            Triggers.switchOn();

            Test.startTest();
                testCase = createTestCaseWithProServRT(testOpp, proServQuote, CaseHelper.SUBJECT_PS_UC_QUOTE_REQUESTED);
            Test.stopTest();
        }

        Case reselectedCase = (Case) new ListOptional(new CaseSelector()
                .selectCasesByIds(new Set<Id> {testCase.Id})
                .withoutSelectorFieldsIncluded()
                .selectField(Case.OwnerId)
                .executeQuery()
            ).getFirst();
        Map<String,Id> psQueuesMap = QueueHelper.getPSQueuesMap();

        Assert.areEqual(psQueuesMap.get(QueueHelper.QUEUE_PS_NA_ENTERPRISE), reselectedCase.OwnerId, CASE_OWNER_ASSIGNED_CORRECTLY_MSG);
    }

    @isTest
    static void testChangeCaseOwnerToProServNAMajorsQueue() {
        User userObj = createUser('TestSalesManager2', 'SalesManager2!user@gmail.com', UserHelper.SEGMENT_MAJORS);
        Case testCase;
        System.runAs(userObj) {
            Triggers.switchOff();
            Account testAcc = createTestAccount();
            Opportunity testOpp = createTestOpportunity(testAcc);
            Quote proServQuote = createTestProServQuote(testOpp);
            Triggers.switchOn();

            Test.startTest();
                testCase = createTestCaseWithProServRT(testOpp, proServQuote, CaseHelper.SUBJECT_PS_UC_QUOTE_REQUESTED);
            Test.stopTest();
        }

        Case reselectedCase = (Case) new ListOptional(new CaseSelector()
                .selectCasesByIds(new Set<Id> {testCase.Id})
                .withoutSelectorFieldsIncluded()
                .selectField(Case.OwnerId)
                .executeQuery()
            ).getFirst();
        Map<String,Id> psQueuesMap = QueueHelper.getPSQueuesMap();

        Assert.areEqual(psQueuesMap.get(QueueHelper.QUEUE_PS_NA_MAJORS), reselectedCase.OwnerId, CASE_OWNER_ASSIGNED_CORRECTLY_MSG);
    }

    @isTest
    static void testChangeCaseOwnerToProServNAMidmarketQueue() {
        User userObj = createUser('TestSalesManager3', 'SalesManager3!user@gmail.com', UserHelper.SEGMENT_MID_MARKET);
        Case testCase;
        System.runAs(userObj) {
            Triggers.switchOff();
            Account testAcc = createTestAccount();
            Opportunity testOpp = createTestOpportunity(testAcc);
            Quote proServQuote = createTestProServQuote(testOpp);
            Triggers.switchOn();

            Test.startTest();
                testCase = createTestCaseWithProServRT(testOpp, proServQuote, CaseHelper.SUBJECT_PS_UC_QUOTE_REQUESTED);
            Test.stopTest();
        }

        Case reselectedCase = (Case) new ListOptional(new CaseSelector()
                .selectCasesByIds(new Set<Id> {testCase.Id})
                .withoutSelectorFieldsIncluded()
                .selectField(Case.OwnerId)
                .executeQuery()
            ).getFirst();
        Map<String,Id> psQueuesMap = QueueHelper.getPSQueuesMap();

        Assert.areEqual(psQueuesMap.get(QueueHelper.QUEUE_PS_NA_MIDMARKET), reselectedCase.OwnerId, CASE_OWNER_ASSIGNED_CORRECTLY_MSG);
    }

    @isTest
    static void testChangeCaseOwnerToProServSMBQueue() {
        User userObj = createUser('TestSalesManager4', 'SalesManager4!user@gmail.com', UserHelper.SEGMENT_SMB);
        Case testCase;
        System.runAs(userObj) {
            Triggers.switchOff();
            Account testAcc = createTestAccount();
            Opportunity testOpp = createTestOpportunity(testAcc);
            Quote proServQuote = createTestProServQuote(testOpp);
            Triggers.switchOn();

            Test.startTest();
                testCase = createTestCaseWithProServRT(testOpp, proServQuote, CaseHelper.SUBJECT_PS_UC_QUOTE_REQUESTED);
            Test.stopTest();
        }

        Case reselectedCase = (Case) new ListOptional(new CaseSelector()
                .selectCasesByIds(new Set<Id> {testCase.Id})
                .withoutSelectorFieldsIncluded()
                .selectField(Case.OwnerId)
                .executeQuery()
            ).getFirst();
        Map<String,Id> psQueuesMap = QueueHelper.getPSQueuesMap();

        Assert.areEqual(psQueuesMap.get(QueueHelper.QUEUE_PS_SMB), reselectedCase.OwnerId, CASE_OWNER_ASSIGNED_CORRECTLY_MSG);
    }

    @isTest
    static void testChangeOwnerForPSWithProServQuote() {
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'Test Account'
                }
            )
            .create()
            .getRecord();

        Test.startTest();

            Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Opportunity.AccountId => testAcc.Id,
                        Opportunity.Name => 'TestOpportunity',
                        Opportunity.Total_MRR__c => 100,
                        Opportunity.CloseDate => System.today()
                    }
                )
                .create()
                .getRecord();

            Quote proServQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Quote.RecordTypeId => QuoteHelper.RT_ID_PROSERV,
                        Quote.OpportunityId => testOpp.Id,
                        Quote.Status => QuoteHelper.QUOTE_STATUS_PRESENTED,
                        Quote.Pricebook2Id => Test.getStandardPricebookId(),
                        Quote.End_Date__c => ValueProviderBuilder.provideUniqueDate(),
                        Quote.Start_Date__c => ValueProviderBuilder.provideUniqueDate()
                    }
                )
                .create()
                .getRecord();

            List<Case> caseList = (List<Case>) new SObjectBuilder(Case.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Case.Status => CaseHelper.CASE_STATUS_NEW,
                        Case.Opportunity_Reference__c => testOpp.Id,
                        Case.Quote_Approval_ID__c => proServQuote.Id,
                        Case.Origin => CaseHelper.CASE_ORIGIN_QUOTING_PAGE,
                        Case.Category__c =>  ValueProviderBuilder.provideList(new List<String> {CaseHelper.CATEGORY_MANAGED_OR_RECURRING_SERVICES, CaseHelper.CATEGORY_VIDEO, CaseHelper.CATEGORY_AFTERMARKET_SUPPORT, 'Other'}),
                        Case.RecordTypeId => CaseHelper.RT_ID_PROFESSIONAL_SERVICES,
                        Case.Subject => CaseHelper.SUBJECT_PS_UC_QUOTE_REQUESTED
                    }
                )
                .quantity(4)
                .create()
                .getRecords();

        Test.stopTest();

        List<Case> reselectedCases = (List<Case>) new CaseSelector()
			.selectCasesDefaultDetailed(new List<Object>{})
			.executeQuery();

        Map<String, Id> caseCategoryToOwnerId = new Map<String, Id>();
        for (Case testCase : reselectedCases) {
            caseCategoryToOwnerId.put(testCase.Category__c, testCase.OwnerId);
        }

        Map<String,Id> psQueuesMap = QueueHelper.getPSQueuesMap();

        Assert.areEqual(psQueuesMap.get(QueueHelper.QUEUE_PS_MRR_SERVICES), caseCategoryToOwnerId.get(CaseHelper.CATEGORY_MANAGED_OR_RECURRING_SERVICES), 'Case owner shuold be assigned correctly');
        Assert.areEqual(psQueuesMap.get(QueueHelper.QUEUE_PS_VIDEO), caseCategoryToOwnerId.get( CaseHelper.CATEGORY_VIDEO), 'Case owner shuold be assigned correctly');
        Assert.areEqual(psQueuesMap.get(QueueHelper.QUEUE_PS_AFTERMARKET), caseCategoryToOwnerId.get(CaseHelper.CATEGORY_AFTERMARKET_SUPPORT), 'Case owner shuold be assigned correctly');
        Assert.areEqual(psQueuesMap.get(QueueHelper.QUEUE_PS_NA_MIDMARKET), caseCategoryToOwnerId.get(CASE_CATEGORY_OTHER), 'Case owner shuold be assigned correctly');
    }

    @isTest
    static void testChangeOwnerForPSWithCCProServQuote() {
        User testUser = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestSalesManager1',
                    User.Username => 'SalesManager1!user@gmail.com',
                    User.Email => 'SalesManager1!user@gmail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep',
                    User.SegmentPicklist__c => UserHelper.SEGMENT_ENTERPRISE
                }
            )
            .create()
            .getRecord();

        System.runAs(testUser) {
                Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
                    .setFields(
                        new Map<SObjectField, Object>{
                            Account.Name => 'Test Account'
                        }
                    )
                    .create()
                    .getRecord();

                Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                    .setFields(
                        new Map<SObjectField, Object>{
                            Opportunity.AccountId => testAcc.Id,
                            Opportunity.Name => 'TestOpportunity',
                            Opportunity.Total_MRR__c => 100,
                            Opportunity.CloseDate => System.today()
                        }
                    )
                    .create()
                    .getRecord();

                Quote ccProServQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
                    .setFields(
                        new Map<SObjectField, Object> {
                            Quote.RecordTypeId => QuoteHelper.RT_ID_CC_PROSERV,
                            Quote.OpportunityId => testOpp.Id,
                            Quote.Status => QuoteHelper.QUOTE_STATUS_PRESENTED,
                            Quote.Pricebook2Id => Test.getStandardPricebookId(),
                            Quote.End_Date__c => ValueProviderBuilder.provideUniqueDate(),
                            Quote.Start_Date__c => ValueProviderBuilder.provideUniqueDate()
                        }
                    )
                    .create()
                    .getRecord();

            Test.startTest();
                new SObjectBuilder(Case.SObjectType)
                    .setFields(
                        new Map<SObjectField, Object>{
                            Case.Status => CaseHelper.CASE_STATUS_NEW,
                            Case.Opportunity_Reference__c => testOpp.Id,
                            Case.Quote_Approval_ID__c => ccProServQuote.Id,
                            Case.Origin => CaseHelper.CASE_ORIGIN_QUOTING_PAGE,
                            Case.Category__c =>  ValueProviderBuilder.provideList(new List<String> {CaseHelper.CATEGORY_IMPLEMENTATION_SERVICES, CaseHelper.CATEGORY_MANAGED_OR_RECURRING_SERVICES, CaseHelper.CATEGORY_AFTERMARKET_SUPPORT, 'Other'}),
                            Case.RecordTypeId => CaseHelper.RT_ID_PROFESSIONAL_SERVICES,
                            Case.Subject => CaseHelper.SUBJECT_PS_CC_QUOTE_REQUESTED
                        }
                    )
                    .quantity(4)
                    .create();
            Test.stopTest();
        }

        List<Case> reselectedCases = (List<Case>) new CaseSelector()
			.selectCasesDefaultDetailed(new List<Object>{})
			.executeQuery();

        Map<String, Id> caseCategoryToOwnerId = new Map<String, Id>();
        for (Case testCase : reselectedCases) {
            caseCategoryToOwnerId.put(testCase.Category__c, testCase.OwnerId);
        }

        Map<String,Id> psQueuesMap = QueueHelper.getPSQueuesMap();

        Assert.areEqual(psQueuesMap.get(QueueHelper.QUEUE_PS_CONTACT_CENTER), caseCategoryToOwnerId.get( CaseHelper.CATEGORY_IMPLEMENTATION_SERVICES), 'Case owner shuold be assigned correctly');
        Assert.areEqual(psQueuesMap.get(QueueHelper.QUEUE_PS_MRR_SERVICES), caseCategoryToOwnerId.get(CaseHelper.CATEGORY_MANAGED_OR_RECURRING_SERVICES), 'Case owner shuold be assigned correctly');
        Assert.areEqual(psQueuesMap.get(QueueHelper.QUEUE_PS_AFTERMARKET), caseCategoryToOwnerId.get(CaseHelper.CATEGORY_AFTERMARKET_SUPPORT), 'Case owner shuold be assigned correctly');
        Assert.areEqual(psQueuesMap.get(QueueHelper.QUEUE_PS_CONTACT_CENTER), caseCategoryToOwnerId.get(CASE_CATEGORY_OTHER), 'Case owner shuold be assigned correctly');
    }

    @isTest
    static void testValidateStatusFieldOnUpdateUserWithoutPermissionSet() {
        User testUser = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestCaseOwner',
                    User.Username => 'CaseOwner!user@gmail.com',
                    User.Email => 'CaseOwner_user@gmail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name =: ProfileHelper.SYSTEM_ADMIN].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep',
                    User.Division => OpportunityHelper.USER_DIVISION_SALES_ENTERPRISE
                }
            )
            .create()
            .getRecord();

        Case testCase = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.Status => CaseHelper.CASE_STATUS_NEW,
                    Case.Case_Category__c => 'Account Updates',
                    Case.Case_Subcategory__c => 'Other',
                    Case.Origin => 'Account'
                }
            )
            .create()
            .getRecord();
        String errorMessage;
        System.runAs(testUser) {
            Test.startTest();
                testCase.Status = CaseHelper.CASE_STATUS_WIP;
                testCase.RecordTypeId = CaseHelper.RT_ID_DEAL_AND_ORDER_SUPPORT;
                try {
                    update testCase;
                } catch (Exception e) {
                    errorMessage = e.getMessage();
                }
            Test.stopTest();
        }
        System.assert(errorMessage.contains(Label.CaseOnlyQueueMemberCanChangeStatus), 'Status of DOS Case should be failed');
    }

    @isTest
    static void testValidateStatusFieldOnUpdateUserWithPermissionSet() {
        User testUser = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestCaseOwner',
                    User.Username => 'CaseOwner!user@gmail.com',
                    User.Email => 'CaseOwner_user@gmail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name =: ProfileHelper.SYSTEM_ADMIN].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep',
                    User.Division => OpportunityHelper.USER_DIVISION_SALES_ENTERPRISE
                }
            )
            .create()
            .getRecord();

        PermissionSet permissionSetRecord = (PermissionSet) new PermissionSetSelector()
            .selectPermissionSetByLabel(new List<Object>{CustomPermissionHelper.PERMISSION_SET_LABEL_ALLOW_DOS_CASE_STATUS_CHANGE})
            .executeQuery()
            .get(0);

        PermissionSetAssignment testPermissionSetAssignment = (PermissionSetAssignment) new SObjectBuilder(PermissionSetAssignment.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PermissionSetAssignment.AssigneeId => testUser.Id,
                PermissionSetAssignment.PermissionSetId => permissionSetRecord.Id
            })
            .create()
            .getRecord();

        Case testCase = new Case();
        String errorMessage;
        System.runAs(testUser) {
            Test.startTest();
                testCase = (Case) new SObjectBuilder(Case.SObjectType)
                    .setFields(
                        new Map<SObjectField, Object>{
                            Case.Status => CaseHelper.CASE_STATUS_NEW,
                            Case.Case_Category__c => 'Account Updates',
                            Case.Case_Subcategory__c => 'Other',
                            Case.Origin => 'Account'
                        }
                    )
                    .create()
                    .getRecord();
                testCase.Status = CaseHelper.CASE_STATUS_WIP;
                testCase.RecordTypeId = CaseHelper.RT_ID_DEAL_AND_ORDER_SUPPORT;
                try {
                    update testCase;
                } catch (Exception e) {
                    errorMessage = e.getMessage();
                }
            Test.stopTest();
        }
        System.assert(String.isBlank(errorMessage), 'Status of DOS Case should be updated succesfully');
    }

    private static User createUser(String lastName, String userName, String segment) {
        return (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    User.LastName => lastName,
                    User.Username => userName,
                    User.Email => userName,
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep',
                    User.SegmentPicklist__c => segment
                }
            )
            .create()
            .getRecord();
    }

    private static Account createTestAccount() {
        return (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .create()
            .getRecord();
    }

    private static Opportunity createTestOpportunity(Account testAcc) {
        return (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.Name => 'TestOpportunity',
                    Opportunity.Total_MRR__c => 100,
                    Opportunity.CloseDate => System.today()
                }
            )
            .create()
            .getRecord();
    }

    private static Quote createTestProServQuote(Opportunity testOpp) {
        return (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Quote.RecordTypeId => QuoteHelper.RT_ID_PROSERV,
                    Quote.OpportunityId => testOpp.Id,
                    Quote.Status => QuoteHelper.QUOTE_STATUS_PRESENTED,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.End_Date__c => ValueProviderBuilder.provideUniqueDate(),
                    Quote.Start_Date__c => ValueProviderBuilder.provideUniqueDate()
                }
            )
            .create()
            .getRecord();
    }

    private static Case createTestCaseWithProServRT(Opportunity testOpp, Quote proServQuote, String subject) {
        return (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Case.Status => CaseHelper.CASE_STATUS_NEW,
                    Case.Opportunity_Reference__c => testOpp.Id,
                    Case.Quote_Approval_ID__c => proServQuote.Id,
                    Case.Origin => CaseHelper.CASE_ORIGIN_QUOTING_PAGE,
                    Case.Category__c => CaseHelper.CATEGORY_IMPLEMENTATION_SERVICES,
                    Case.RecordTypeId => CaseHelper.RT_ID_PROFESSIONAL_SERVICES,
                    Case.Subject => subject
                }
            )
            .create()
            .getRecord();
    }
}