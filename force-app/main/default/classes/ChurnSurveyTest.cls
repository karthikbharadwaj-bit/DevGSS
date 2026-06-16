@isTest
private class ChurnSurveyTest {

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testChurnSurvey() {
        
        Test.startTest();
        
        ApexPages.currentPage().getParameters().put('id', 'abcd');
        ChurnSurveyController churnSurveyController = new ChurnSurveyController();
        churnSurveyController = new ChurnSurveyController();
        ApexPages.currentPage().getParameters().put('id', '');
        churnSurveyController = new ChurnSurveyController();
        
        Account account = new Account(Name='Test',RC_Account_Status__c='disabled',Total_DLs__c=5,RC_Churn_Date__c=system.now().addDays(-7));
        insert account;
        
        Contact con = new Contact(LastName='test', AccountId=account.Id,Email='test@cc.com');
        
        insert con;
        
        Survey__c survey = new Survey__c(SurveyType__c='Churn Feedback Survey', Name='Churn Survey');
        insert survey;
        
        churnSurveyController = new ChurnSurveyController();
        ApexPages.currentPage().getParameters().put('id', survey.Id);
        churnSurveyController = new ChurnSurveyController();
        churnSurveyController.save();
        survey.Responded__c = 1;
        churnSurveyController = new ChurnSurveyController();
        ApexPages.currentPage().getParameters().put('id', '');
        churnSurveyController = new ChurnSurveyController();
        Test.stopTest();
        
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void churnSurveyBatchTest() {
    	Test.startTest();
	    	Account account = new Account(Name='Test',RC_Account_Status__c='disabled',Total_DLs__c=5,RC_Churn_Date__c=system.now().addDays(-7));
	        insert account;
	        Contact con = new Contact(LastName='test', AccountId=account.Id,Email='vineet.srivastava@simplion.com');
	        insert con;
	    	ChurnSurveyBatch c = new ChurnSurveyBatch ();
	    	Database.executeBatch(c, 100); 
    	Test.stopTest();
    }
    
}