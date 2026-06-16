@isTest
private class Test_Batch_CreateTasksRelationshipSurvey {
	public static Account testAccount;
    public static Contact testContact;
    public static AccountContactRole testACR;
    public static Segment_Master__c testSM;
    public static String RS_SERVICE_NAME = 'sfdc_create_relationship_survey';
    public static Medallia_xm__Invitation__c med_inv;
    
    public static void createTestData(Boolean withCSM, Boolean isPrimary){

        testSM = new Segment_Master__c();
        testSM.Name = 'Small Business';
       	testSM.Min__c = 20;
        testSM.Max__c = 100;
        testSM.Country__c = 'United States';
        testSM.Start_Date__c = Date.today();
        insert testSM;
          
        testAccount = new Account();
		testAccount.Name = 'Test123';
		testAccount.RC_Account_Status__c = 'Paid';
		testAccount.SignupPlatform__c = 'WEB';
		testAccount.RC_Service_name__c = 'office123';
        testAccount.Segment_Name__c = testSM.Id;
		testAccount.RC_Activation_Date__c = null;
        testAccount.RC_Upgrade_Date__c = Date.today().addMonths(-10);
		testAccount.Partner_ID__c = '9852';
        testAccount.wave__c = 'Wave 1';
        if(withCSM) {
            testAccount.CSM__c = UserInfo.getUserId();
        }
        
		insert testAccount;

		testContact = new Contact();
		testContact.AccountId =  testAccount.id;
		testContact.Email = 'fake@email.com';
		testContact.LastName = 'TestLast';
		testContact.Phone='9910106804';
		insert testContact;
        
        testACR = new AccountContactRole();
        testACR.AccountId = testAccount.Id;
        testACR.ContactId = testContact.Id;
        testACR.Role = 'Signatory';
        testACR.IsPrimary = isPrimary;
        insert testACR;

        
        med_inv = new Medallia_xm__Invitation__c();
        med_inv.medallia_xm__Account__c = testAccount.Id;
        med_inv.medallia_xm__Contact__c = testContact.Id;
        med_inv.medallia_xm__Status__c = 'Invited';
        med_inv.medallia_xm__Medallia_Service__c = RS_SERVICE_NAME;
        med_inv.medallia_xm__ParentId__c = testContact.Id;
        med_inv.medallia_xm__Date_To_Send__c = Date.today();
        insert med_inv;
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest 
    static void testMedalliaRelationshipSurveyTask_withCSM() {
        Triggers.switchOff();
        createTestData(true,true);
        Batch_CreateTasksForRelationshipSurvey bcrt = new Batch_CreateTasksForRelationshipSurvey();
		database.executeBatch(bcrt);
    } 
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest 
    static void testMedalliaRelationshipSurveyTask_withCSM_NoPrimContact() {
        Triggers.switchOff();
        createTestData(true,false);
        Batch_CreateTasksForRelationshipSurvey bcrt = new Batch_CreateTasksForRelationshipSurvey();
		database.executeBatch(bcrt);
    } 
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest 
    static void testMedalliaRelationshipSurveyTask_withoutCSM() {
        Triggers.switchOff();
        createTestData(false,false);
        Batch_CreateTasksForRelationshipSurvey bcrt = new Batch_CreateTasksForRelationshipSurvey();
		database.executeBatch(bcrt);
    }  

}