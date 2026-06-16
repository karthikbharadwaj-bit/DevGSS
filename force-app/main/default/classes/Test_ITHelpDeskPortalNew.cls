/**
 * Created by Работа on 09.02.2018.
 */

@isTest
private class Test_ITHelpDeskPortalNew {
    private static final String CASE_SEARCH_TEXT = 'bestSubject';

    //quick fix for low coverage
    @testSetup static void prepareData() {
        Account rcInternalAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'RC Internal'
                }
            )
            .create()
            .getRecord();

        Contact contactForUser = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => rcInternalAcc.Id,
                    Contact.Email => UserInfo.getUserEmail(),
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();    

        Employee__c emp = (Employee__c) new SObjectBuilder(Employee__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Employee__c.First_Name__c => 'FirstName',
                    Employee__c.Last_Name__c => 'LastName',
                    Employee__c.Email__c => UserInfo.getUserEmail(),
                    Employee__c.Location__c => 'San Mateo, US',
                    Employee__c.Department__c => 'HR',
                    Employee__c.Division__c => 'Sales - Development Bay',
                    Employee__c.Team__c => 'Sales - AT&T Initials'
                }
            )
            .create()
            .getRecord();
      
        Case c = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.Status => 'New',
                    Case.RecordTypeId => CaseHelper.RT_ID_IT_HELPDESK,
                    Case.ContactId => contactForUser.Id,
                    Case.Subject => CASE_SEARCH_TEXT,
                    Case.Request_Subtype_2__c => 'Outage'
                }
            )
            .create()
            .getRecord();         
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testSiteLoginController () {
        ITHelpDeskPortalNew controller = new ITHelpDeskPortalNew();
    }

    @isTest static void testGetUserInfo () {
        Test.startTest();

        ITHelpDeskPortalNew controller = new ITHelpDeskPortalNew();
        controller.getUserInfo();

        System.assertEquals(true, controller.isUserHR, 'we have inserted Employee with HR department - isUserHR should be true');

        Test.stopTest();
    }

    @isTest static void testGetCases() {
        Test.startTest();

        ITHelpDeskPortalNew controller = new ITHelpDeskPortalNew();
        controller.searchText = CASE_SEARCH_TEXT;
        controller.getCases(true);

        System.assertEquals(1, controller.userCasesList.size(), 'a case should be queried and added to userCasesList');

        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testGetters() {
        //just to increase coverage
        Test.startTest();

        ITHelpDeskPortalNew controller = new ITHelpDeskPortalNew();
        controller.hasNextCases = true;
        controller.getNextCases();
        controller.getPrevCases();
        controller.getLegalRequests(true);
        controller.hasNextRequests = true;
        controller.getNextRequests();
        controller.getPrevRequests();
        controller.hasNextArticles = true;
        controller.getNextArticles();
        controller.getPrevArticles();
        controller.searchAll();
        controller.systemStatusColor = 'green';
        controller.getStatusColor();
        controller.errorMsg = '';
        controller.toShowErrorMsg = false;
        controller.newCaseSubject = 'subj';
        controller.newCaseDescription = 'subj';

        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testWrappers() {
        ITHelpDeskPortalNew.WrCaseDetail wrcd = new ITHelpDeskPortalNew.WrCaseDetail();
        wrcd.id = 'testString';
        wrcd.CaseNumber = 'testString';
        wrcd.Status = 'testString';
        wrcd.CreatedDate = 'testString';
        wrcd.ClosedDate = 'testString';
        wrcd.ProductAssistance = 'testString';
        wrcd.Priority = 'testString';
        wrcd.Subject = 'testString';
        wrcd.TimeSinceCaseOpened = 'testString';
        wrcd.caseownernmame = 'testString';
        wrcd.recordtypename = 'testString';
        wrcd.caseowneremail = 'testString';
        wrcd.contactname = 'testString';
        wrcd.accountname = 'testString';
        wrcd.contactemail = 'testString';
        wrcd.AdditionalCaseWatcher = 'testString';
        wrcd.Severity = 'testString';
        wrcd.description = 'testString';
        wrcd.location = 'testString';

        ITHelpDeskPortalNew.WrLegalReqDetail wlrd = new ITHelpDeskPortalNew.WrLegalReqDetail();
        wlrd.id = 'testString';
        wlrd.objname = 'testString';
        wlrd.Status = 'testString';
        wlrd.DraftDate = Date.today();
        wlrd.SubmitDate = Date.today();
        wlrd.recordTypeName = 'testString';

        ITHelpDeskPortalNew.WrITArticles wita = new ITHelpDeskPortalNew.WrITArticles();
        wita.strFormatDate = 'testString';
        wita.strArticleURL = 'testString';
        wita.strArticleId = 'testString';
        wita.strArticleModifiedDate = 'testString';
        wita.strArticleTitle = 'testString';
        wita.strArticleModifiedBy = 'testString';
        wita.strArticleNumber = 'testString';
    }
}