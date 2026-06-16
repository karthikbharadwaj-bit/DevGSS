@IsTest
private class Test_CaseCreationController {

    @isTest
    private static void testCaseCreationController() {
        CaseLayoutAssignment__c cs = new CaseLayoutAssignment__c (
                Name = 'System Administrator',
                Profile_Name__c = 'System Administrator',
                Layout_Name__c = 'Support T1 Layout (Standard)'
        );
        insert cs;

        Case testCase = new Case(RecordTypeId = CaseHelper.RT_ID_SUPPORT_T1);
        ApexPages.StandardController sc = new ApexPages.StandardController(testCase);
        CaseCreationController CCcontroller = new CaseCreationController(sc);

        System.assertNotEquals(null, CaseCreationController.caseTaggingToolPageName);
        System.assertNotEquals(null, CaseCreationController.caseTaggingToolFields);
        System.assertNotEquals(null, CCcontroller.caseObj);
        System.assertNotEquals(null, CCcontroller.caseCommentObj);
        System.assertNotEquals(null, CCcontroller.layout);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testCheckAccess() {
        //PageReference pageRef = Page.CaseCreation;
        //Test.setCurrentPage(pageRef);
        //System.assertNotEquals(null, CaseCreationController.checkAccess());

        //pageRef.getParameters().put('RecordType', CaseHelper.RT_ID_SUPPORT_T1);
        //System.assertEquals(null, CaseCreationController.checkAccess());
    }

    @isTest
    private static void testSave() {
        Case testCase = new Case(RecordTypeId = CaseHelper.RT_ID_SUPPORT_T1);
        ApexPages.StandardController sc = new ApexPages.StandardController(testCase);
        CaseCreationController CCcontroller = new CaseCreationController(sc);
        CCcontroller.caseCommentObj = new CaseComment();

        System.assertNotEquals(null, CCcontroller.save());
        System.assert([SELECT COUNT() FROM Case] > 0);
        System.assert([SELECT COUNT() FROM Casecomment] > 0);
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void testCaseCreation1(){
        
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
	       
	       User u1 = new User(Alias = 'suppmgr1', Email='supportmanager1@testorg.com', 
	       EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
	       LocaleSidKey='en_US', ProfileId = p.Id, 
	       TimeZoneSidKey='America/Los_Angeles', UserName='supportmanager1@testorg.com'); 
	       
	       insert u1;
        
        Account testAcc = new Account(
            Name = 'testAccount',
            RC_User_ID__c = '62329416005',
            Partner_ID__c = '66163'
        );
        insert testAcc;
        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setField(Contact.AccountId, testAcc.Id)
            .create()
            .getRecord();
        
        CaseLayoutAssignment__c cs = new CaseLayoutAssignment__c (
                Name = 'System Administrator',
                Profile_Name__c = 'System Administrator',
                Layout_Name__c = 'Support T1 Layout (Standard)',
               RecordType_Name__c = 'Support - T1'
        );
        insert cs;
        
        Case testCase = new Case(RecordTypeId = CaseHelper.RT_ID_SUPPORT_T1, AccountId = testAcc.id);
        Case testCase2 = new Case(RecordTypeId = CaseHelper.RT_ID_SYSTEM_OPERATIONS, AccountId = testAcc.id);
        ApexPages.StandardController sc = new ApexPages.StandardController(testCase);
        
        PageReference pageRef = Page.CaseCreation;
        test.setCurrentPageReference(pageRef);
        pageRef.getParameters().put('RecordType', testCase.RecordTypeId);
        pageRef.getParameters().put('def_account_id', testCase.AccountId);
        CaseCreationController CCcontroller = new CaseCreationController(sc);
        CaseCreationController.checkAccess();
        //Creating dummy list of fields to cover addIgnoredFieldsMessage method
        List<String> ignoredDependentFields = new List<String>{'Test1__c', 'Test2__c' , 'Test3__c'};
        CaseCreationController.addIgnoredFieldsMessage(ignoredDependentFields);
        
        //Coverage for lightning component controller
        
         Case_StandardCaseCreate_Comp.fetchRecordDetailsCase(u1.id , testCase2.RecordTypeId, testAcc.id, contact.id );
        Case_StandardCaseCreate_Comp.fetchRecordDetailsCase(u1.id , testCase.RecordTypeId, testAcc.id, contact.id );
        Case_StandardCaseCreate_Comp.fetchRecordDetailsCase(u1.id , testCase2.RecordTypeId, testAcc.id, null );
                Case_StandardCaseCreate_Comp.fetchRecordDetailsCase(u1.id , testCase.RecordTypeId, testAcc.id, null );
        Case_StandardCaseCreate_Comp.fetchCaseCreatedByFields(testCase2.id);
        Case_recordType_selectioncomp.fetchRecordTypeValues();
        Case_recordType_selectioncomp.getRecTypeId('Support-Case');
        
    }
}