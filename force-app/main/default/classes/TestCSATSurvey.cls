@isTest
private class TestCSATSurvey {

	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void csatSurveyTest() {
    	Account acctest = new Account();
        acctest.Name = 'TestAccount';
        acctest.RecordTypeId  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account').getRecordTypeId();
        insert acctest; 
        
        Contact contObj = new Contact();
	    contObj.AccountId =  acctest.Id;
	    contObj.Email = 'test@test.com';
	    contObj.LastName = 'Test Last1';
	    contObj.FirstName = 'Test First1';
      	insert contObj;
	      	
    	Survey__c surveyObj1 = new Survey__c();
    	surveyObj1.SurveyType__c = 'Implementation';
    	surveyObj1.Name = 'Test Impl';
    	surveyObj1.Contact__c = contObj.Id;
    	surveyObj1.Contact_Email__c = 'test@test.com';
    	insert surveyObj1;
    	
    	Survey__c surveyObj2 = new Survey__c();
    	surveyObj2.SurveyType__c = 'Sales';
    	surveyObj2.Name = 'Test Impl';
    	surveyObj2.Contact__c = contObj.Id;
    	surveyObj2.Contact_Email__c = 'test@test.com';
    	insert surveyObj2;
    	
    	Test.startTest();
    	
    	CSATSurvey csatsurvey2 = new CSATSurvey();
	    ApexPages.currentPage().getParameters().put('id', surveyObj1.id);
        CSATSurvey csatsurvey1 = new CSATSurvey();
        csatsurvey1.getValues1();
        csatsurvey1.getValues1_Porting();
        csatsurvey1.getValues3_Porting();
        csatsurvey1.getValues2();
        csatsurvey1.getValues3();
        csatsurvey1.getValues4();
        csatsurvey1.save();
        csatsurvey1.answer1 = '1.00';
        csatsurvey1.answer2 = '2.00';
        csatsurvey1.answer31 = '2.00';
        csatsurvey1.answer32 = '2.00';
        csatsurvey1.answer33 = '3.00';
        csatsurvey1.answer34 = '3.00';
        csatsurvey1.answer01 = '8';
        csatsurvey1.answer011 = '8';
        csatsurvey1.answer012 = '8';
        csatsurvey1.answer013 = '8';
        csatsurvey1.answer014 = '8';
        csatsurvey1.surveyObj.X4_Survey__c ='3.00';
        csatsurvey1.answer5 = '3.00';
        csatsurvey1.surveyObj.X6_Survey__c = 'Low';
        csatsurvey1.save();
        csatsurvey1.setResponseValue();
        csatsurvey1.checkSurveyAlreadyFilled();
        new CSATSurvey();
        ApexPages.currentPage().getParameters().put('id', surveyObj2.id);
        CSATSurvey csatsurvey3 = new CSATSurvey();
        
        Test.stopTest();
    }
	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void attSurveyTest(){
    Account acctest = new Account();
        acctest.Name = 'RCTestAccount';
        acctest.RecordTypeId  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account').getRecordTypeId();
        acctest.Number_of_DL_s__c = 5;
        acctest.RC_Service_name__c = 'Office12';
        insert acctest; 
        
        Contact contObj = new Contact();
	    contObj.AccountId =  acctest.Id;
	    contObj.Email = 'test@test1.com';
	    contObj.LastName = 'Test Last123';
	    contObj.FirstName = 'Test First145';
      	insert contObj;
	      	
    	Survey__c surveyObj1 = new Survey__c();
    	surveyObj1.SurveyType__c = 'ATT Implementation';
    	surveyObj1.Name = 'Test Imp4l';
    	surveyObj1.Contact__c = contObj.Id;
    	surveyObj1.Contact_Email__c = 'test@test1.com';
    	insert surveyObj1;
    	
    	Test.startTest();
    	
    	CSATSurvey csatsurvey2 = new CSATSurvey();
	    ApexPages.currentPage().getParameters().put('id', surveyObj1.id);
        CSATSurvey csatsurvey1 = new CSATSurvey();
        csatsurvey1.getValues1();
        csatsurvey1.getValues1_Porting();
        csatsurvey1.getValues3_Porting();
        csatsurvey1.getValues2();
        csatsurvey1.getValues3();
        csatsurvey1.getValues4();
        csatsurvey1.save();
        csatsurvey1.answer1 = '1.00';
        csatsurvey1.answer2 = '2.00';
        csatsurvey1.answer31 = '2.00';
        csatsurvey1.answer32 = '2.00';
        csatsurvey1.answer33 = '3.00';
        csatsurvey1.answer34 = '3.00';
        csatsurvey1.answer01 = '8';
        csatsurvey1.answer011 = '8';
        csatsurvey1.answer012 = '8';
        csatsurvey1.answer013 = '8';
        csatsurvey1.answer014 = '8';
        csatsurvey1.surveyObj.X4_Survey__c ='3.00';
        csatsurvey1.answer5 = '3.00';
        csatsurvey1.surveyObj.X6_Survey__c = 'Low';
        csatsurvey1.save();
        csatsurvey1.setResponseValue();
        csatsurvey1.checkSurveyAlreadyFilled();
        new CSATSurvey();
        ApexPages.currentPage().getParameters().put('id', surveyObj1.id);
        CSATSurvey csatsurvey3 = new CSATSurvey();
        
        Test.stopTest();
    }
	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void getIsEmpty(){
    	Account acctest = new Account();
        acctest.Name = 'RCTestAccount';
        acctest.RecordTypeId  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account').getRecordTypeId();
        insert acctest; 
        
        Contact contObj = new Contact();
	    contObj.AccountId =  acctest.Id;
	    contObj.Email = 'test@test1.com';
	    contObj.LastName = 'Test Last123';
	    contObj.FirstName = 'Test First145';
      	insert contObj;
	      	
    	Survey__c surveyObj1 = new Survey__c();
    	surveyObj1.SurveyType__c = 'ATT Implementation';
    	surveyObj1.Name = 'Test Imp4l';
    	surveyObj1.Contact__c = contObj.Id;
    	surveyObj1.Contact_Email__c = 'test@test1.com';
    	insert surveyObj1;
    	
    	Test.startTest();
    	
    	CSATSurvey csatsurvey2 = new CSATSurvey();
	    ApexPages.currentPage().getParameters().put('id', surveyObj1.id);
        CSATSurvey csatsurvey1 = new CSATSurvey();
        csatsurvey1.getValues1();
        csatsurvey1.getValues1_Porting();
        csatsurvey1.getValues3_Porting();
        csatsurvey1.getValues2();
        csatsurvey1.getValues3();
        csatsurvey1.getValues4();
        csatsurvey1.save();
        csatsurvey1.answer1 = '1.00';
        csatsurvey1.answer2 = '2.00';
        csatsurvey1.answer31 = '2.00';
        csatsurvey1.answer32 = '2.00';
        csatsurvey1.answer33 = '3.00';
        csatsurvey1.answer34 = '3.00';
        csatsurvey1.answer01 = '8';
        csatsurvey1.answer011 = '8';
        csatsurvey1.answer012 = null;
        csatsurvey1.answer013 = null;
        csatsurvey1.answer014 = '8';
        csatsurvey1.surveyObj.X4_Survey__c ='3.00';
        csatsurvey1.answer5 = '3.00';
        csatsurvey1.surveyObj.X6_Survey__c = 'Low';
        csatsurvey1.save();
        //csatsurvey1.setResponseValue();
        //csatsurvey1.checkSurveyAlreadyFilled();
        csatsurvey1.getIsEmpty();
        new CSATSurvey();
        ApexPages.currentPage().getParameters().put('id', surveyObj1.id);
        CSATSurvey csatsurvey3 = new CSATSurvey();
        
        Test.stopTest();
    }
    
	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void surveyTestPorting() {
    	Account acctest = new Account();
        acctest.Name = 'TestAccount11';
        acctest.RecordTypeId  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account').getRecordTypeId();
        insert acctest; 
        
        Contact contObj = new Contact();
	    contObj.AccountId =  acctest.Id;
	    contObj.Email = 'test@test11.com';
	    contObj.LastName = 'Test Last1121';
	    contObj.FirstName = 'Test First1';
      	insert contObj;
	      	
    	Survey__c surveyObj1 = new Survey__c();
    	surveyObj1.SurveyType__c = 'Porting Phone Support';
    	surveyObj1.Name = 'Test Impl';
    	surveyObj1.Contact__c = contObj.Id;
    	surveyObj1.Contact_Email__c = 'test@test.com';
    	insert surveyObj1;
    	
    	Survey__c surveyObj2 = new Survey__c();
    	surveyObj2.SurveyType__c = 'Porting Phone Support1';
    	surveyObj2.Name = 'Test Impl';
    	surveyObj2.Contact__c = contObj.Id;
    	surveyObj2.Contact_Email__c = 'test@test.com';
    	insert surveyObj2;
    	
    	Test.startTest();
    	
    	PortingPhoneSupportCSATSurvey csatsurvey2 = new PortingPhoneSupportCSATSurvey();
	    ApexPages.currentPage().getParameters().put('id', surveyObj1.id);
        PortingPhoneSupportCSATSurvey csatsurvey1 = new PortingPhoneSupportCSATSurvey();
        csatsurvey1.getValues1();
        csatsurvey1.getValues2();
        csatsurvey1.getValues3();
        csatsurvey1.getValues4();
        csatsurvey1.save();
        csatsurvey1.answer1 = '1.00';
        csatsurvey1.answer2 = '2.00';
        csatsurvey1.answer31 = '2.00';
        csatsurvey1.answer32 = '2.00';
        csatsurvey1.answer33 = '3.00';
        csatsurvey1.answer34 = '3.00';
      	csatsurvey1.surveyObj.X4_Survey__c = 'Yes';
        csatsurvey1.answer5 = '3.00';
        csatsurvey1.surveyObj.X6_Survey__c = 'Low';
        csatsurvey1.save();
        csatsurvey1.setResponseValue();
        csatsurvey1.checkSurveyAlreadyFilled();
        new PortingPhoneSupportCSATSurvey();
        ApexPages.currentPage().getParameters().put('id', surveyObj2.id);
        PortingPhoneSupportCSATSurvey csatsurvey3 = new PortingPhoneSupportCSATSurvey();
        
        Test.stopTest();
    }
    
	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
     @isTest
    static void surveyTestrogers() {
    	Account acctest = new Account();
        acctest.Name = 'TestAccount11';
        acctest.RecordTypeId  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account').getRecordTypeId();
        insert acctest; 
        
        Contact contObj = new Contact();
	    contObj.AccountId =  acctest.Id;
	    contObj.Email = 'test@test11.com';
	    contObj.LastName = 'Test Last1121';
	    contObj.FirstName = 'Test First1';
      	insert contObj;
	      	
    	Survey__c surveyObj1 = new Survey__c();
    	surveyObj1.SurveyType__c = 'Support Rogers';
    	surveyObj1.Name = 'Test Impl';
    	surveyObj1.Contact__c = contObj.Id;
    	surveyObj1.Contact_Email__c = 'test@test.com';
    	insert surveyObj1;
    	
    	Survey__c surveyObj2 = new Survey__c();
    	surveyObj2.SurveyType__c = 'Support Rogers1';
    	surveyObj2.Name = 'Test Impl';
    	surveyObj2.Contact__c = contObj.Id;
    	surveyObj2.Contact_Email__c = 'test@test.com';
    	insert surveyObj2;
    	
    	CSATSupportRogers csatsurvey2 = new CSATSupportRogers();
	    ApexPages.currentPage().getParameters().put('id', surveyObj1.id);
        CSATSupportRogers csatsurvey1 = new CSATSupportRogers();
        csatsurvey1.getValues1();
        csatsurvey1.getValues2();
        csatsurvey1.getValues3();
        csatsurvey1.getValues4();
        csatsurvey1.save();
        csatsurvey1.answer1 = '1.00';
        csatsurvey1.answer2 = '2.00';
        csatsurvey1.answer31 = '2.00';
        csatsurvey1.answer32 = '2.00';
        csatsurvey1.answer33 = '3.00';
        csatsurvey1.answer34 = '3.00';
        csatsurvey1.surveyObj.X4_Survey__c = 'Yes';
        csatsurvey1.answer5 = '3.00';
        csatsurvey1.surveyObj.X6_Survey__c = 'Low';
        csatsurvey1.save();
        csatsurvey1.setResponseValue();
        csatsurvey1.checkSurveyAlreadyFilled();
        new CSATSupportRogers();
        ApexPages.currentPage().getParameters().put('id', surveyObj2.id);
        CSATSupportRogers csatsurvey3 = new CSATSupportRogers();
    }
}