@isTest
private class Test_classNew {

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void Test_CampaignBatchToCalculateMRR() {

        Test.StartTest();
        CampaignBatchToCalculateMRR obj=new CampaignBatchToCalculateMRR();
        ID batchprocessid= Database.executeBatch(obj,200);
        Test.StopTest();

    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void Test_ClaimAccount() {

        Account a = new Account();
        a.Name = 'TestbyAA';
        a.RC_User_ID__c = '345';

        Agent_Credit__c AC = new Agent_Credit__c();
        ac.Name = 'Test';
        ApexPages.currentPage().getParameters().put('userid', '111');
        ApexPages.currentPage().getParameters().put('id', '111');

        claimAccountctrl CATest = new claimAccountctrl(new ApexPages.StandardController(a));
        CATest.getAcctID();
        CATest.getNotAcctID();
        CATest.getAccountID();
        CATest.getNotAccountID();
        CATest.actCreateLeadFromContact();
    }
    @isTest
    static void Test_CSATSurveyservice() {


        Survey__c objSur = new Survey__c();
        objSur.Name = 'test Survey';
        objSur.SurveyType__c = 'Support CSAT';
        insert objSur;
        ApexPages.currentPage().getParameters().put('id', objSur.id);
        CSATSurveyservice objCSATSurveyservice = new CSATSurveyservice();



        objCSATSurveyservice.setQ1Value(3);
        objCSATSurveyservice.setQ2Value(2);
        objCSATSurveyservice.setQ3Value(4);
        objCSATSurveyservice.setQ4Value(5);

        objCSATSurveyservice.setComments('these are my comments');

        System.assertEquals(3, objCSATSurveyservice.getQ1Value());
        System.assertEquals(2, objCSATSurveyservice.getQ2Value());
        System.assertEquals(4, objCSATSurveyservice.getQ3Value());
        System.assertEquals(5, objCSATSurveyservice.getQ4Value());
        System.assertEquals('these are my comments', objCSATSurveyservice.getComments());
        objCSATSurveyservice.getCommentLength();
        objCSATSurveyservice.getAnswered();
        objCSATSurveyservice.setQ5Value(4);
        objCSATSurveyservice.getQ5Value();
        objCSATSurveyservice.getValues3() ;

        Boolean a = objCSATSurveyservice.getIsEmpty();
        Boolean b = objCSATSurveyservice.getIsFilled();
        List<SelectOption> l1 = objCSATSurveyservice.getValues();
        List<SelectOption> l2 = objCSATSurveyservice.getValues2();

        objCSATSurveyservice.getSurvey().SurveyType__c='Support CSAT';
        objCSATSurveyservice.save();
        objCSATSurveyservice.getSurvey().SurveyType__c='Implementation';
        objCSATSurveyservice.save();
    }
}