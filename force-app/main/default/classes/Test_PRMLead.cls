/*
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 *
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class Test_PRMLead {

    @isTest
    static void myUnitTestPartnerAccountUpdateSharingRule() {
        Test.startTest();
        syncPartnerAccountUpdateSharingRule syncAccountObj = new syncPartnerAccountUpdateSharingRule();
        ID batchprocessid = Database.executeBatch(syncAccountObj);
        System.abortJob(batchprocessid);
        Test.stopTest();

        System.assertNotEquals(batchprocessid, null);
    }

    @isTest
    static void myUnitTestCaseTOPartnerLead() {

    //Create portal account owner
        User admin = [SELECT Id, UserRoleId FROM User WHERE profileId IN (SELECT id FROM Profile WHERE Name = 'System Administrator') AND isActive = true LIMIT 1];
        if(UserInfo.getUserRoleId() == null){
            Id currentUserId = UserInfo.getUserId();
            System.runAs(admin){
                UserRole role = new UserRole(name = 'TEST ROLE');
                insert role;
                User currentUser = new User(Id = currentUserId, UserRoleId = role.Id);
                update currentUser;
            }
        }
        Account acctest = new Account();
        acctest.Name='TestAccount';
        acctest.RC_Attribution_Channel__c = 'Sales Agents & Resellers';
        acctest.Partner_ID__c ='5896745876';
        acctest.RecordTypeId  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner Account').getRecordTypeId();
        acctest.Number_of_DL_s__c = 1;
        acctest.MRR__c = 100;
        acctest.Monthly_CRF__c = 10;
        acctest.OwnerId = admin.Id;
        accTest.Current_Owner__c = admin.Id;
        insert acctest;

        Contact contactObj = new Contact();
        contactObj.AccountId =  acctest.id;
        contactObj.Email = 'fake@email.com';
        contactObj.LastName = 'TestLast';
        contactObj.Phone='9910106804';
        contactObj.Relayware_Portal_User__c = 'Approved';
        insert contactObj;

        //Create user
        UserRole r = [SELECT Id FROM UserRole WHERE PortalType ='Partner' limit 1];
        Profile portalProfile = [SELECT Id FROM Profile WHERE Name LIKE '%Portal User%' Limit 1];
        User user1;
        /*System.runAs(admin){
                user1 = new User(
                Username = System.now().millisecond() + 'test12345@test.com',
                ContactId = contactObj.Id,
                ProfileId = portalProfile.Id,
                //userroleid  = r.Id,
                Alias = 'test123',
                Email = 'test12345@test.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'McTesty',
                CommunityNickname = 'test12345',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US'
            );
            Database.insert(user1);
        }*/
        Case caseObj = new Case();
        caseObj.AccountId = acctest.id;
        caseObj.ContactId = contactObj.id;
        caseObj.Subject = 'Test';
        caseObj.Description = 'Test Desc';
        caseObj.Lead_Partner_ID__c= '5896745876';
        //caseObj.Partner_Lead_Owner__c = user1.id;
        caseObj.Partner_Lead_Email__c = 'testashish@email.com';
        caseObj.Partner_Lead_Company__c = 'Test Comp';
        caseObj.Partner_Lead_LastName__c = 'Test LNMae';
        caseObj.Partner_Contact__c  = contactObj.id;
        insert caseObj;

        Test.startTest();
        CaseTOPartnerLead casetoPartnerLeadObj = new CaseTOPartnerLead(new ApexPages.Standardcontroller(caseObj));
        ApexPages.currentPage().getParameters().put('id', caseObj.id);
        CaseTOPartnerLead casetoPartnerLeadObj1 = new CaseTOPartnerLead(new ApexPages.Standardcontroller(caseObj));
        PageReference testLeadPage = casetoPartnerLeadObj1.createPartnerLead();
        Group testLeadGroup = casetoPartnerLeadObj1.getPartnerQueue();

        Test.stopTest();

        System.assertEquals(testLeadPage, null);
        System.assertEquals(testLeadGroup.Name, 'Partner Lead Reviewer');
    }

    @isTest
    static void myUnitTestConvertPartnerLead() {
        Test_Utils testUtilsObj = new Test_Utils();
        testUtilsObj.initialiseTriggerBypass();

        Profile p = [SELECT Id FROM Profile WHERE Name='RC Partner User'];
        if(UserInfo.getUserRoleId() == null){
            Id currentUserId = UserInfo.getUserId();
            User admin = [SELECT Id, UserRoleId FROM User WHERE profileId IN (SELECT id FROM Profile WHERE Name = 'System Administrator') AND isActive = true LIMIT 1];
            System.runAs(admin){
                UserRole role = new UserRole(name = 'TEST ROLE');
                insert role;
                User currentUser = new User(Id = currentUserId, UserRoleId = role.Id);
                update currentUser;
            }
        }

        Account accountObj = new Account();
        accountObj.Name = 'TestAcc';
        insert accountObj;

        Contact conObj = new Contact();
        conObj.FirstName = 'TestFName11';
        conObj.LastName = 'TestLName11';
        conObj.Email = 'Testname11@test.com';
        conObj.AccountId = accountObj.Id;
        insert  conObj;

        User objUser = new User(Alias = 'standt', Email='standarduser@testorg.com',
                            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                            LocaleSidKey='en_US', ProfileId = p.Id,ContactId = conObj.id,
                            TimeZoneSidKey='America/Los_Angeles', UserName='test@2.com'+system.now().getTime());
        insert objUser ;
        Lead leadObj = new Lead();
        leadObj.FirstName='Virendra';
        leadObj.LastName='Singh';
        leadObj.Company='Simplion';
        leadObj.Email='virendra.singh1@simplion.com';
        leadObj.Phone='9910106804';
        leadObj.LeadSource = 'Inbound Call';
        leadObj.Notes__c = 'Test Notes';
        leadObj.Website = 'http://test.com';
        leadObj.NumberOfEmployees = 123;
        leadObj.Industry = 'Test';
        leadObj.NumberOfEmployees__c = '2-19';
        leadObj.Number_of_Locations__c = '2-4';
        leadObj.Agent_Email_Address__c = 'test@test.com';
        leadObj.Partner_Lead_Owner__c=objUser.id;
        insert leadObj;

        Account acctest = new Account();
       // acctest.parentId=acctest1.id;
        acctest.Name='TestAccount';
        acctest.RC_Attribution_Channel__c = 'Sales Agents & Resellers';
        acctest.Partner_ID__c ='123';
        acctest.RecordTypeId  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account').getRecordTypeId();
        insert acctest;

        Contact contactObj = new Contact();
        contactObj.AccountId =  acctest.id;
        contactObj.Email = 'virendra.singh@simplion.com';
        contactObj.Phone = '9910106804';
        contactObj.LastName = 'TestLast';
        insert contactObj;

        Opportunity Oppval = new Opportunity();
        Oppval.Name = 'Test Opp';
        Oppval.AccountId = acctest.Id;
        Oppval.Type = 'Existing Business';
        Oppval.StageName = '3. ActivePipe';
        Oppval.Sales_Model__c = 'Direct';
        Oppval.CloseDate = System.Today() + 10;
        Oppval.CurrencyIsoCode = 'USD';
        Oppval.Brand_Name__c= 'RingCentral';
        Oppval.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
        Oppval.Proposal_Expiration_Date__c = System.today() + 100;
        insert Oppval;

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.standardController(leadObj);
        ApexPages.currentPage().getParameters().put('id', leadObj.id);
        ConvertPartnerLead convertLeadOptObj = new ConvertPartnerLead(sc);

        convertLeadOptObj.getListInitialCategoryItems();
        convertLeadOptObj.updateLeadCategory();
        ApexPages.currentPage().getParameters().put('retURL','http://test.com');
        convertLeadOptObj.GoBack();
        convertLeadOptObj.convertAndMerge();
        //convertLeadOptObj.leadObj.Account__c  =   acctest.Id;
        convertLeadOptObj.createNew = true;
        convertLeadOptObj.convertAndMerge();
        List<ConvertPartnerLead.cAccount> testLeadAccs = convertLeadOptObj.getAccounts();
        ConvertPartnerLead.cOpportunity wrOppObj = new  ConvertPartnerLead.cOpportunity(Oppval,'Test','Test','Test','Test',System.now(),System.now());
        ConvertPartnerLead.cAccount   wrACCObj = new  ConvertPartnerLead.cAccount(acctest,'test','test','test',contactObj);
        Lead testLead = convertLeadOptObj.getl();
        Test.stopTest();

        System.assertEquals(testLead.InContract__c, false);
        System.assertEquals(testLeadAccs.size(), 0);
    }

    @isTest
    static void myUnitTestConvertPartnerLead1() {
        Test_Utils testUtilsObj = new Test_Utils();
        testUtilsObj.initialiseTriggerBypass();

        Profile p = [SELECT Id FROM Profile WHERE Name ='RC Partner User'];
        if(UserInfo.getUserRoleId() == null){
            Id currentUserId = UserInfo.getUserId();
            User admin = [SELECT Id, UserRoleId FROM User WHERE profileId IN (SELECT id FROM Profile WHERE Name = 'System Administrator') AND isActive = true LIMIT 1];
            System.runAs(admin){
                UserRole role = new UserRole(name = 'TEST ROLE');
                insert role;
                User currentUser = new User(Id = currentUserId, UserRoleId = role.Id);
                update currentUser;
            }
        }

        Account accountObj = new Account();
        accountObj.Name = 'TestAcc';
        insert accountObj;
        Contact conObj = new Contact();
        conObj.FirstName = 'TestFName12';
        conObj.LastName = 'TestLName12';
        conObj.Email = 'Testname12@test.com';
        conObj.AccountId = accountObj.Id;
        insert  conObj;
        User objUser = new User(Alias = 'standt', Email='partneruser@testorg.com',
                            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                            LocaleSidKey='en_US', ProfileId = p.Id, ContactId = conObj.id,
                            TimeZoneSidKey='America/Los_Angeles', UserName='test@2.com'+system.now().getTime());
        insert objUser ;

        Account acctest = new Account();
       // acctest.parentId=acctest1.id;
        acctest.Name='TestAccount';
        acctest.RC_Attribution_Channel__c = 'Sales Agents & Resellers';
        acctest.Partner_ID__c ='123';
        acctest.RecordTypeId  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account').getRecordTypeId();
        insert acctest;

        Lead leadObj1= new Lead();
        leadObj1.FirstName='Kanishk';
        leadObj1.LastName='Singh';
        leadObj1.Company='Simplion';
        leadObj1.Email='kanishk.singh1@simplion.com';
        leadObj1.Phone='9910106804';
        leadObj1.LeadSource = 'Inbound Call';
        leadObj1.Notes__c = 'Test Notes';
        leadObj1.Website = 'http://test1.com';
        leadObj1.NumberOfEmployees = 1231;
        leadObj1.Industry = 'Test';
        leadObj1.NumberOfEmployees__c = '2-19';
        leadObj1.Number_of_Locations__c = '2-4';
        leadObj1.Agent_Email_Address__c = 'test@test1.com';
        leadObj1.Account__c   =acctest.id;
        leadObj1.Partner_Lead_Owner__c=objUser.id;
        insert leadObj1;

        Note noteObj = new Note();
        noteObj.ParentId = leadObj1.id;
        noteObj.Body = 'test';
        noteObj.Title= 'Original note from lead';
        insert noteObj;

        Contact contactObj = new Contact();
        contactObj.AccountId =  acctest.id;
        contactObj.Email = 'virendra.singh@simplion.com';
        contactObj.Phone = '9910106804';
        contactObj.LastName = 'TestLast';
        insert contactObj;

        Test.startTest();

        Opportunity Oppval = new Opportunity();
        Oppval.Name = 'Test Opp';
        Oppval.AccountId = acctest.Id;
        Oppval.Type = 'Existing Business';
        Oppval.StageName = '3. ActivePipe';
        Oppval.Sales_Model__c = 'Direct';
        Oppval.CloseDate = System.Today() + 10;
        Oppval.CurrencyIsoCode = 'USD';
        Oppval.Brand_Name__c= 'RingCentral';
        Oppval.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
        Oppval.Proposal_Expiration_Date__c = System.today() + 100;
        insert Oppval;

        list<note> noteList = new list<note>();
        noteList.add(noteObj);
        id parentId = noteObj.ParentId ;

        ApexPages.StandardController sc1 = new ApexPages.standardController(leadObj1);
        ApexPages.currentPage().getParameters().put('id', leadObj1.id);
        ConvertPartnerLead convertLeadOptObj1 = new ConvertPartnerLead(sc1);
        //convertLeadOptObj1.leadObj.Account__c  =   acctest.Id;
        convertLeadOptObj1.convertAndMerge();
        convertLeadOptObj1.getListInitialCategoryItems();
        convertLeadOptObj1.updateLeadCategory();
        ApexPages.currentPage().getParameters().put('retURL','http://test1.com');
        convertLeadOptObj1.GoBack();
        List<ConvertPartnerLead.cOpportunity> opptys = convertLeadOptObj1.getOpportunities();
        convertLeadOptObj1.getCreateNew();
        convertLeadOptObj1.getInitial_CategoryFlag();
        convertLeadOptObj1.setL(leadObj1);
        convertLeadOptObj1.setCreateNew(true);
        convertLeadOptObj1.getMultipleSelected();
        convertLeadOptObj1.getMatchFound();
        Boolean isAnswered = convertLeadOptObj1.getnotAnswered();
        convertLeadOptObj1.getstrDebug ();
        Boolean isMatchedLead = convertLeadOptObj1.getMatchNotFound();
      //  convertLeadOptObj1.prepareNoteList(noteList, parentId);
        Test.stopTest();

        System.assertEquals(isMatchedLead, true);
        System.assertEquals(isAnswered, false);
        System.assertEquals(opptys.size(), 0);

    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void myUnitTestLeadCreationPartner() {
        Test_Utils testUtilsObj = new Test_Utils();
        testUtilsObj.initialiseTriggerBypass();

        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
                            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                            LocaleSidKey='en_US', ProfileId = p.Id,
                            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg.com');

        Account acctest1 = new Account();
        acctest1.Name='TestAccount';
        insert acctest1;

        Account acct = new Account(name='TestingReal account');
        acct.parentId=acctest1.id;
        insert acct;

        ShareUtil.getParentAccountDetail(acct.id);

        Contact objcon = new Contact(FirstName='test',LastName ='testl',AccountId = acct.id);
        insert objcon;

        Emails__c email = new Emails__c(
            Name = 'fake',
            Email_Address__c = 'fake@email.com');
        insert email;

        Test.startTest();
        ApexPages.StandardController controller1 = new ApexPages.StandardController(new Lead());
        LeadCreationPartner objLCP1 = new LeadCreationPartner(controller1);
        objLCP1.createNew();
        
        Lead leadObj = new Lead();
        setLeadDetail(leadObj );
        objLCP1.rcUsers='Number of RC Users';
        leadObj.FirstName='First Name';
        leadObj.LastName='Last Name';
        leadObj.Title='Business Title';
        leadObj.Company='Company Name';
        leadObj.Email='Email Address';
        leadObj.Website='Website';
        leadObj.Phone='phone';
        objLCP1.newLead=leadObj ;
        objLCP1.resetFieldValue();
        objLCP1.createNew();
        objLCP1.isFakeEmail('fake@email.com');
        leadObj.FirstName='Virendra';
        leadObj.LastName='Singh';
        leadObj.Company='Simplion';
        leadObj.Email='virendra.singh@simplion.com';
        leadObj.Phone='9910106804';
        leadObj.LeadSource = 'Inbound Call';
        leadObj.Notes__c = 'Test Notes';
        leadObj.Website = 'http://test.com';
        leadObj.NumberOfEmployees = 123;
        leadObj.Industry = 'Test';
        leadObj.NumberOfEmployees__c = '2-19';
        leadObj.Number_of_Locations__c = '2-4';
        leadObj.Agent_Email_Address__c = 'test@test.com';
        leadObj.Description ='testing this ';
        leadObj.Number_of_Users__c  =4;
        objLCP1.rcUsers='4';
        leadObj.Email='hagehd';
        leadObj.Phone='12345';
        leadObj.Partner_Lead_Source__c = 'Partner';
        objLCP1.newLead=leadObj ;
        objLCP1.createNew();

        leadObj.Email='virendra.singh@simplion.com';
        leadObj.Phone='9910106804';
        leadObj.Country__c = 'UNITED STATES';
        leadObj.State__c = 'California';
        leadObj.City = 'Test';
        leadObj.How_did_you_acquire_this_Lead__c = 'Test';
        leadObj.Estimated_Close_Date__c = System.today();
        leadObj.Lead_Brand_Name__c = 'Ringcentral';
        leadObj.Lead_Tier_Name__c = 'FAX';
        leadObj.Description = 'Test';
        leadObj.Industry = 'Test';
        leadObj.Number_of_Locations__c = '12';
        leadObj.NumberOfEmployees__c = '12';
        leadObj.PostalCode = '92089';
        objLCP1.rcUsers = '22';
        objLCP1.newLead=leadObj ;

        objLCP1.createNew();
        leadObj.Phone='9910106804';
        objLCP1.newLead=leadObj;
        objLCP1.createNew();
        objLCP1.newLead=leadObj;
        PageReference testCreatedPage = objLCP1.createNew();
        PageReference testCanceledPage = objLCP1.cancelLead();
        Test.stopTest();
        
        objLCP1.createLeadApprovalRecord('Lead Found', u);
        objLCP1.checkLeadEmailAlreadyExists();
        objLCP1.isValidEmail('tests');
    }

    public static void setLeadDetail(Lead objLead){
        objLead.FirstName ='First Name';
        objLead.LastName ='Last Name';
        objLead.Title ='Title';
        objLead.Company ='Company Name';
        objLead.Email ='Email Address';
        objLead.Website ='Website';
        objLead.Phone='tyityiyi';
    }
}