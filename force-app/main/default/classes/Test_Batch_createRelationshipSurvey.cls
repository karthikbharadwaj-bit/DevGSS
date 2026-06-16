@isTest
private class Test_Batch_createRelationshipSurvey {
	public static Account testAccount;
    public static Contact testContact;
    public static AccountContactRole testACR;
    public static Segment_Master__c testSM;
    public static Medallia_Invitation__mdt med_inv;
    
    public static void createTestData(){
 	
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
        testAccount.RC_Brand__c = 'RingCentral';
        
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
        testACR.IsPrimary = true;
        insert testACR;
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest 
    static void testMedalliaRelationshipSurvey_Free() {
        Triggers.switchOff();
        createTestData();
        Batch_createRelationshipSurvey bcrt = new Batch_createRelationshipSurvey();
		database.executeBatch(bcrt);
    }  
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
      @isTest 
    static void testMedalliaRelationshipSurvey_Paid() {
        Triggers.switchOff();
        createTestData();        
        
        testAccount.RC_Service_name__c = 'RC Office EU';
        update testAccount;
        Batch_createRelationshipSurvey bcrt = new Batch_createRelationshipSurvey();
		database.executeBatch(bcrt);
    } 
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest 
    static void testMedalliaRelationshipSurvey_InvalidBrand() {
      Triggers.switchOff();
      createTestData();        

      testAccount.RC_Service_name__c = 'RC Office EU';
      testAccount.RC_Brand__c = 'Unify Office';
      update testAccount;
      Batch_createRelationshipSurvey bcrt = new Batch_createRelationshipSurvey();
      database.executeBatch(bcrt);
  } 

}