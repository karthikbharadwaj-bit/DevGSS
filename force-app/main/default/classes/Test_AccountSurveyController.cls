@isTest
public class Test_AccountSurveyController {
	
    @isTest
    public static void testAccountSurvey(){

        Account testAccount = new Account();
        testAccount.name = 'Test Account';
        insert testAccount;


        Survey__c testSurvey = new Survey__c();
        testSurvey.name = 'Test Survey';
        testSurvey.Account__c=testAccount.id;
        insert testSurvey;
        
        //Survey__c testSurvey = [SELECT Id FROM Survey__c WHERE Account__r.Id = :testAccount.Id];
            
        /*Survey__c testSurvey = new Survey__c();
        testSurvey.name = 'Test Survey';
        insert testSurvey;*/
        
        PageReference surveyPage = Page.AccountSurvey;
        Test.setCurrentPage(surveyPage);
        
        
        ApexPages.CurrentPage().getParameters().put('id',testSurvey.Id );
        
        AccountSurveyController accSurvey = new AccountSurveyController();
        List<SelectOption> options = accSurvey.getOptions();
        accSurvey.getRating();
        accSurvey.useVideoConference = 'Yes';
        accSurvey.rating = '5';
        
        accSurvey.submitSurvey();
        
        Survey__c surveyObj = [SELECT ATT_OH_Recommendation_Rating__c,	ATT_OH_Video_Conference_used__c FROM Survey__c WHERE Id = :testSurvey.Id];
        System.assertEquals(accSurvey.useVideoConference, surveyObj.ATT_OH_Video_Conference_used__c);
        System.assertEquals(accSurvey.rating, surveyObj.ATT_OH_Recommendation_Rating__c);
    }

    @isTest
    public static void testErrorMessage(){
        
        Survey__c testSurvey = new Survey__c();
        testSurvey.name = 'Test Survey';
        insert testSurvey;
        
        PageReference surveyPage = Page.AccountSurvey;
        Test.setCurrentPage(surveyPage);
        
        AccountSurveyController accSurvey = new AccountSurveyController();
        List<SelectOption> options = accSurvey.getOptions();
        accSurvey.getRating();
        accSurvey.useVideoConference = 'Yes';
        accSurvey.rating = '5';
        
        accSurvey.submitSurvey();
        
        Survey__c surveyObj = [SELECT ATT_OH_Recommendation_Rating__c,	ATT_OH_Video_Conference_used__c FROM Survey__c WHERE Id = :testSurvey.Id];
        System.assertEquals(null, surveyObj.ATT_OH_Video_Conference_used__c);
        System.assertEquals(null, surveyObj.ATT_OH_Recommendation_Rating__c);
        
    }
}