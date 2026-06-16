@isTest
private class Test_ImplementationSurveyController {

  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void myUnitTest() {


   Survey__c surveyObj = new Survey__c();
   surveyObj.SurveyType__c = 'Implementation';
   insert surveyObj;

   ApexPages.currentPage().getParameters().put('id', surveyObj.id);

        ImplementationSurveyController sur = new ImplementationSurveyController();
        //  sur.setQ1Value(3);
        //  sur.setQ2Value(2);
        //  sur.setQ3Value(4);
        //  sur.setQ4Value(5);
        //  sur.setQ6Value(5);
        //  sur.setQ71Value(4);
        //  sur.setQ72Value(3);
        //  sur.setQ73Value(4);
        //  sur.setQ74Value(2);
        //
        //  sur.setComments('these are my comments');
        //
        //  System.assertEquals(3, sur.getQ1Value());
        //  System.assertEquals(2, sur.getQ2Value());
        //  System.assertEquals(4, sur.getQ3Value());
        //  System.assertEquals(5, sur.getQ4Value());
        //  System.assertEquals(5, sur.getQ6Value());
        //  System.assertEquals(4, sur.getQ71Value());
        //  System.assertEquals(3, sur.getQ72Value());
        //  System.assertEquals(4, sur.getQ73Value());
        //  System.assertEquals(2, sur.getQ74Value());
        //  System.assertEquals('these are my comments', sur.getComments());

        //  sur.getImplementationSurvey();
        //  sur.setResponseValue();
          sur.getRogersFooter();
          sur.getRogersHeader();
          sur.getThanksMsg();
          sur.getLogo();
          sur.getFooter();
          sur.getHeader();
          sur.getUserMsg();
          sur.getQ7();
          sur.getQ74();
        //  sur.radio6Select();
         List<SelectOption> l1 = sur.getValues3();
        // List<SelectOption> l2 = sur.getValues2();
         //List<SelectOption> l2 = sur.getValues();


        //  sur.save();

        Survey__c surveyObj1 = new Survey__c();
        surveyObj1.SurveyType__c = 'ATT Implementation';
        surveyObj1.Responded__c = 1;
        insert surveyObj1;

        ApexPages.currentPage().getParameters().put('id', surveyObj1.id);
        ImplementationSurveyController sur1 = new ImplementationSurveyController();
        sur1.getAlradyFilled();
        sur1.getLogo();
        sur1.getHeader();
        sur1.getFooter();
        // sur1.getQ1();

        Survey__c surveyObj2 = new Survey__c();
        surveyObj2.SurveyType__c = 'Implementation';
        insert surveyObj2;

        ApexPages.currentPage().getParameters().put('id', surveyObj2.id);
        ImplementationSurveyController sur2 = new ImplementationSurveyController();
        // sur2.getImplementationSurvey();
        sur2.getLogo();

        Survey__c surveyObj3 = new Survey__c();
        surveyObj3.SurveyType__c = 'Rogers Implementation';
        insert surveyObj3;

        ApexPages.currentPage().getParameters().put('id', surveyObj3.id);
        ImplementationSurveyController sur3 = new ImplementationSurveyController();
        // sur3.getImplementationSurvey();
        sur3.getLogo();
        sur3.getAlradyFilled();
        // sur3.getQ1();


        //TriggerHandler.BY_PASS_IMPLEMENTATION_ON_BEFORE  = true;
        //TriggerHandler.BY_PASS_IMPLEMENTATION_ON_AFTER = true;
        //Testing for Completed Implementation(s)
        Implementation__c testImpl = new Implementation__c();
        testImpl.Name = 'testImpl';
        testImpl.Most_Recent_follow_up_Date__c = date.today();
        testImpl.Porting_Required__c = 'Yes';
        //testImpl.Account__c = objAccount.Id;
        // testImpl.Implementation_Status_2__c = 'Completed';
        testImpl.Brand__c = 'BTBrand';
        testImpl.Status_Change_Comment__c ='comment';
        insert testImpl;
        //TriggerHandler.BY_PASS_IMPLEMENTATION_ON_BEFORE  = false;
        //TriggerHandler.BY_PASS_IMPLEMENTATION_ON_AFTER = false;

        Survey__c surveyObj4 = new Survey__c();
        surveyObj4.SurveyType__c = 'Implementation';
        surveyObj4.Implementation__c = testImpl.Id;
        surveyObj4.Implementation_Advisor_s_ability__c = 10;
        surveyObj4.Implementation_Materials_provided__c = 9;
        surveyObj4.Implementation_Advisor_Communication__c =8;
        surveyObj4.Implementation_Advisor_Satisfaction__c=7;
        surveyObj4.Responded__c=1;
        insert surveyObj4;

        ApexPages.currentPage().getParameters().put('id', surveyObj4.id);
        ImplementationSurveyController sur4 = new ImplementationSurveyController();
        sur4.getLogo();
        sur4.isBTBrand();
        sur4.getHeader();
		sur4.getFooter();
        sur4.getUserMsg();
        sur4.getQ7();
        sur4.getQ74();
        List<SelectOption> l3 = sur4.getValues3();
        sur4.setResponseValue();
		sur4.save();
        
        ApexPages.currentPage().getParameters().put('id', '0000000');
        ImplementationSurveyController sur5 = new ImplementationSurveyController();

        Survey__c surveyObj5 = new Survey__c();
        surveyObj5.SurveyType__c = '';
        insert surveyObj5;
        
        ApexPages.currentPage().getParameters().put('id', surveyObj5.id);
        ImplementationSurveyController sur6 = new ImplementationSurveyController();
        delete surveyObj5;
        //sur6.save();
        
        Survey__c surveyObj6 = new Survey__c();
        surveyObj6.SurveyType__c = 'Implementation';
        surveyObj6.Implementation__c = testImpl.id;
        surveyObj6.Responded__c=null;
        insert surveyObj6; 
        Test.setCreatedDate(surveyObj6.id, date.today().addDays(-31));
        ApexPages.currentPage().getParameters().put('id', surveyObj6.id);
        ImplementationSurveyController sur9 = new ImplementationSurveyController();
        sur9.isSurveyExpired();

        Implementation__c testImpl1 = new Implementation__c();
        testImpl1.Name = 'testImpl1';
        testImpl1.Most_Recent_follow_up_Date__c = date.today();
        testImpl1.ProfessionalServices__c=false;
        testImpl1.PlanningAndDesign__c = false;
        testImpl1.OnsiteDeployment__c = false;
        testImpl1.Brand__c = 'Vodafone Business with RingCentral';
        insert testImpl1;
        
        Survey__c surveyObj7 = new Survey__c();
        surveyObj7.SurveyType__c = 'Implementation';
        surveyObj7.Implementation__c = testImpl1.id;
        surveyObj7.Responded__c=null;
        insert surveyObj7; 
        Test.setCreatedDate(surveyObj7.id, date.today().addDays(-31));
        
        ApexPages.currentPage().getParameters().put('id', surveyObj7.id);
        ImplementationSurveyController sur7 = new ImplementationSurveyController();
         sur7.getLogo();
        sur7.isVodafoneBusinessWithRingCentralBrand();
        sur7.isSurveyExpired();
        sur7.getHeader();
        sur7.getFooter();
        sur7.checkSurveyAlreadyFilled();
        sur7.getUserMsg();
        
        
        Survey__c surveyObj8 = new Survey__c();
        surveyObj8.SurveyType__c = 'Implementation';
        surveyObj8.Implementation__c = testImpl1.id;
        surveyObj8.Responded__c=1;
        surveyObj8.Implementation_Advisor_s_ability__c = 10;
        surveyObj8.Implementation_Materials_provided__c = 9;
        surveyObj8.Implementation_Advisor_Communication__c =8;
        surveyObj8.Implementation_Advisor_Satisfaction__c=7;
        insert surveyObj8;
        ApexPages.currentPage().getParameters().put('id', surveyObj8.id);
        ImplementationSurveyController sur8 = new ImplementationSurveyController();
        sur8.isVodafoneBusinessWithRingCentralBrand();
        sur8.checkSurveyAlreadyFilled();
       	List<SelectOption> l2 = sur8.getValues3();
        sur8.setResponseValue();
		sur8.save();
    }

    @isTest
    static void rCLogo2018ShouldBeReturnedForNonBTBrands(){
      ImplementationSurveyController controllerUnderTest = new ImplementationSurveyController();
      controllerUnderTest.surveyType = 'Implementation';
      Component.Apex.Image imageFromController = controllerUnderTest.getLogo();
      System.assertEquals('{!URLFOR($Resource.RcLogo2018)}', imageFromController.expressions.url,
        'The logo returned should be RCLogo2018');
    }
    
    @isTest
    static void testMethodForRisePartners() {
        String optusSubBrandName = '2000.Optus';
        Rise_Partner_CRM_Configuration__c riseSetting = new Rise_Partner_CRM_Configuration__c();
        riseSetting.Name = optusSubBrandName;
        riseSetting.Identifier__c = 'Optus';
        riseSetting.Logo_URL__c = 'test URL';
        riseSetting.Max_Purchase_DL__c = 99;
        riseSetting.Account_Status__c = 'Paid';
        insert riseSetting;

        Implementation__c testImpl = new Implementation__c();
        testImpl.Name = 'Test Implementation for RISE Partner';
        testImpl.Most_Recent_follow_up_Date__c = Date.Today();
        testImpl.Brand__c = OpportunityHelper.BRAND_RISE_AMERICA;
        testImpl.Sub_brand__c = optusSubBrandName;
        insert testImpl;

        Survey__c surveyObj = new Survey__c();
        surveyObj.SurveyType__c = 'Implementation';
        surveyObj.Implementation__c = testImpl.Id;
        insert surveyObj;

        ApexPages.currentPage().getParameters().put('id', surveyObj.id);
        ImplementationSurveyController controllerObject = new ImplementationSurveyController();
        controllerObject.getLogo();
        controllerObject.getFooter();
        controllerObject.getQ7();
        String headerText = controllerObject.getHeader();
        Assert.areEqual(true, headerText.contains('Optus'), 'The header text is incorrect!');
    }
    
    @isTest
    static void testMethodForFrontierwithRingCentral() {
        Implementation__c testImpl = new Implementation__c();
        testImpl.Name = 'Test Implementation for Frontier with RingCentral';
        testImpl.Most_Recent_follow_up_Date__c = Date.Today();
        testImpl.Brand__c = 'Frontier with RingCentral';
        testImpl.ProfessionalServices__c = true;
        insert testImpl;

        Survey__c surveyObj = new Survey__c();
        surveyObj.SurveyType__c = 'Implementation';
        surveyObj.OverallProjectManagerSatisfaction__c = 9;
        surveyObj.Implementation__c = testImpl.Id;
        insert surveyObj;

        ApexPages.currentPage().getParameters().put('id', surveyObj.id);
        ImplementationSurveyController controllerObject = new ImplementationSurveyController();
        controllerObject.getLogo();
        controllerObject.getFooter();
        controllerObject.getQ7();
        controllerObject.getQ74();
        controllerObject.save();
        String headerText = controllerObject.getHeader();
        Assert.areEqual(true, headerText.contains('Frontier'), 'The header text is incorrect!');
    }
}