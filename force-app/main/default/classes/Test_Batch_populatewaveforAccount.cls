@isTest
private class Test_Batch_populatewaveforAccount
{
	public static Account testAccount;
   
      public static void createTestData(){
		testAccount = new Account();
		testAccount.Name = 'Test123';
		testAccount.RC_Account_Status__c = 'Paid';
		testAccount.SignupPlatform__c = 'WEB';
		testAccount.RC_Service_name__c = 'office123';
		testAccount.RC_Activation_Date__c = null;
        testAccount.RC_Upgrade_Date__c = Date.today().addMonths(-10);
		testAccount.Partner_ID__c = '9852';
        
		insert testAccount;
          
    }
	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest 
    static void testMedalliaRelationshipSurvey_Free() {
        createTestData();
        Batch_populateWaveforAccount bcrt = new Batch_populateWaveforAccount();
		database.executeBatch(bcrt);
    }  
 

}