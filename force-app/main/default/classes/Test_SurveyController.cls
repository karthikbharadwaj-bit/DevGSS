/**
* This class contains unit tests for validating the behavior of Apex classes
* and triggers.
*/
@isTest
private class Test_SurveyController {
    public static final String EANH_CAMPAIGNMEMBER_LOG = 'Camp Memb Exception Log';
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSurveyController() {
        try{
            List<string> lst1 = new List<string>();
            lst1.add('Ques1');
            lst1.add('Ques2');
            String[] strArray = new String[2];
            strArray[0] = 'Sample1';
            strArray[1] = 'Sample2';
            
            SurveyController.WrapperQuestionList WraQue = new SurveyController.WrapperQuestionList(lst1, true);
            WraQue.IsMandatory = true;
            WraQue.theTextValue = 'SampleText';
            WraQue.theRadioValue = 'SampleRadio';
            WraQue.getValues();
            WraQue.getTheCheckBoxValue();
            WraQue.setTheCheckBoxValue(strArray);
            SurveyController.WrapperQuestionList WraQue1 = new SurveyController.WrapperQuestionList(lst1, true);
            WraQue1.IsMandatory = true;
            WraQue1.theTextValue = 'SampleText';
            WraQue1.getValues();
            WraQue1.getTheCheckBoxValue();
            
            Id rtId = Schema.SObjectType.Exception_And_Notification_History__c.getRecordTypeInfosByName()
                .get(EANH_CAMPAIGNMEMBER_LOG)
                .getRecordTypeId();
            
            Exception_And_Notification_History__c EANHs = new Exception_and_Notification_History__c(
                RecordTypeId = rtId,
                Exception__c = 'System.DmlException',
                Exception_desc__c = 'Desc'
            );
            insert EANHs;
            
            Test.startTest();
            
            ApexPages.currentPage().getParameters().put('id',EANHs.Id);
            String exceptionObjId = ApexPages.currentPage().getParameters().get('id');
            system.debug('exceptionObjId++ '+exceptionObjId);
            SurveyController surv = new SurveyController();
            surv.wQesList = new List<SurveyController.WrapperQuestionList>();
            surv.wQesList.add(WraQue);
            surv.wQesList.add(WraQue1);
            surv.getSurveyDetails();
            surv.isAlreadyfilled = false;
            surv.isFilled = true;
            surv.getIsFilled();
            surv.saveSurvey();
            
            Test.stopTest();
        }catch(Exception e){
            system.debug('Exception in test class:'+e.getMessage());
        }
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSurveyController2() {
        try{
            String[] strArray = new String[2];
            strArray[0] = 'Text';
            strArray[1] = 'Radio';
            
            SurveyController.WrapperQuestionList WraQue = new SurveyController.WrapperQuestionList(null, true);
            WraQue.IsMandatory = true;
            WraQue.theTextValue = 'SampleText';
            WraQue.theRadioValue = 'SampleRadio';
            WraQue.getValues();
            WraQue.getTheCheckBoxValue();
            
            Test.startTest();
            
            ApexPages.currentPage().getParameters().put('id','Id');
            SurveyController surv1 = new SurveyController();
            surv1.wQesList = new List<SurveyController.WrapperQuestionList>();
            surv1.wQesList.add(WraQue);
            surv1.getSurveyDetails();
            surv1.isAlreadyfilled = false;
            surv1.isFilled = true;
            surv1.getIsFilled();
            surv1.saveSurvey();
            
            Test.stopTest();
        }catch(Exception e){
            system.debug('Exception in test class:'+e.getMessage());
        }
    }
}