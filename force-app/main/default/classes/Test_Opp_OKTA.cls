@isTest
private class Test_Opp_OKTA {	
	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void OpportunitySurveyClassTest() { 
	 	
	  Account accTest = new Account(Name='TestAcc');
	  insert accTest;
	  
	  Contact contTest = new Contact();
	  contTest.AccountID = accTest.id;
	  contTest.LastName ='test Contact';
	  contTest.Email = 'test@test.com';
	  contTest.Phone = '123654789';
	  insert contTest;
	  
	  AccountContactRole acrTest = new AccountContactRole();
	  acrTest.AccountId= accTest.id;
	  acrTest.IsPrimary=true;
	  acrTest.ContactId= contTest.id;
	  acrTest.Role ='Business User'; 
	  insert acrTest;	
	 
	  Opportunity oppTest = new Opportunity();
	  oppTest.Name ='TestOpp';
	  oppTest.AccountID = accTest.id;
	  oppTest.Type = 'New Business';
	  oppTest.Sales_Model__c = 'Direct';
	  oppTest.Brand_Name__c ='RingCentral';
	  oppTest.Tier_Name__c = 'Power';
	  oppTest.StageName = '4. Closed';
	  oppTest.RecordTypeId = [SELECT id FROM RecordType Where Name='Saves Opportunity'].id;	
	  oppTest.CloseDate = System.today();
	  insert oppTest;
	  
	  OpportunityContactRole ocr = new OpportunityContactRole();
	  ocr.OpportunityId= oppTest.id;
	  ocr.IsPrimary=true;
	  ocr.ContactId= contTest.id;
	  ocr.Role ='Business User'; 
	  insert ocr;
	  
	  Set<Id> testOppId = new Set<Id>();
	  testOppId.add(oppTest.id);
	   
	   Test.startTest();
	   
	  	OpportunitySurveyClass opscSales = new OpportunitySurveyClass(testOppId, 'Sales');
	 	OpportunitySurveyClass opscCsat = new OpportunitySurveyClass(testOppId, 'Saves CSAT');
	 	OpportunitySurveyClass  opscCsat_onCreation = new OpportunitySurveyClass(testOppId, 'Saves CSAT', 'ON_INSERT'); 
 		
 	   Test.stopTest();
	 
	 }
	 @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@isTest
    static void OpportunitySurveyClassTest2() {
      
      Account accTest2 = new Account(Name='TestAcc');
	  insert accTest2;
	  
	  Contact contTest2 = new Contact();
	  contTest2.AccountID = accTest2.id;
	  contTest2.LastName ='test Contact';
	  contTest2.Email = 'test@test.com';
	  contTest2.Phone = '123654789';
	  insert contTest2;
	  
	  AccountContactRole acrTest2 = new AccountContactRole();
	  acrTest2.AccountId= accTest2.id;
	  acrTest2.IsPrimary=false;
	  acrTest2.ContactId= contTest2.id;
	  acrTest2.Role ='Business User'; 
	  insert acrTest2;	
	 
      Opportunity oppTest2 = new Opportunity();
	  oppTest2.Name ='TestOpp';
	  oppTest2.AccountID = accTest2.id;
	  oppTest2.Type = 'New Business';
	  oppTest2.Sales_Model__c = 'Direct';
	  oppTest2.Brand_Name__c ='RingCentral';
	  oppTest2.Tier_Name__c = 'Power';
	  oppTest2.StageName = '4. Closed';	
	  oppTest2.CloseDate = System.today();
	  insert oppTest2;
	  
      OpportunityContactRole ocr2 = new OpportunityContactRole();
	  ocr2.OpportunityId= oppTest2.id;
	  ocr2.IsPrimary=false;
	  ocr2.ContactId= contTest2.id;
	  ocr2.Role ='Business User'; 
	  insert ocr2;
	  
	  Set<Id> testOppId2 = new Set<Id>();
	  testOppId2.add(oppTest2.id);
	  
	  Test.startTest();
		  	OpportunitySurveyClass opscSales = new OpportunitySurveyClass(testOppId2, 'Sales');
		 	OpportunitySurveyClass opscCsat = new OpportunitySurveyClass(testOppId2, 'Saves CSAT');
	 		OpportunitySurveyClass  opscCsat_onCreation = new OpportunitySurveyClass(testOppId2, 'Saves CSAT', 'ON_INSERT'); 
	   
	  Test.stopTest();
	 
	  }
	  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	  @isTest
    static void OpportunitySurveyClassTest3() {
		List<AccountContactRole> accContactRoleList = new List<AccountContactRole>();
	      
		Account accTest3 = new Account(Name='TestAcc');
		TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
		insert accTest3;
		Account accTest3_1 = new Account(Name='TestAcc');
		insert accTest3_1;
		Contact contTest3 = new Contact();
		contTest3.AccountID = accTest3.id;
		  contTest3.LastName ='test Contact';
		  contTest3.Email = 'test@test.com';
		  contTest3.Phone = '123654789';
		  TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
		  insert contTest3;
		  
		  Contact contTest3_1 = new Contact();
		  contTest3_1.AccountID = accTest3_1.id;
		  contTest3_1.LastName ='test Contact';
		  contTest3_1.Email = 'test@test.com';
		  contTest3_1.Phone = '123654789';
		  insert contTest3_1;
		  
		  AccountContactRole acrTest3 = new AccountContactRole();
		  acrTest3.AccountId= accTest3.id;
		  acrTest3.IsPrimary=false;
		  acrTest3.ContactId= contTest3.id;
		  acrTest3.Role ='Business User'; 
		  accContactRoleList.add(acrTest3);	
		
		  AccountContactRole acrTest3_1 = new AccountContactRole();
		  acrTest3_1.AccountId= accTest3_1.id;
		  acrTest3_1.IsPrimary=true;
		  acrTest3_1.ContactId= contTest3_1.id;
		  acrTest3_1.Role ='Business User'; 
		  accContactRoleList.add(acrTest3_1);
		  insert accContactRoleList;
		   
	      Opportunity oppTest3 = new Opportunity();
		  oppTest3.Name ='TestOpp';
		  oppTest3.AccountID = accTest3.id;
		  oppTest3.Type = 'New Business';
		  oppTest3.Sales_Model__c = 'Direct';
		  oppTest3.Brand_Name__c ='RingCentral';
		  oppTest3.Tier_Name__c = 'Power';
		  oppTest3.RecordTypeId = [SELECT id FROM RecordType Where Name='Saves Opportunity'].id;	
		  oppTest3.StageName = '4. Closed';	
		  oppTest3.CloseDate = System.today();
		  
		  TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
		  TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();
		  insert oppTest3;
		  
		  Opportunity oppTest3_1 = new Opportunity();
		  oppTest3_1.Name ='TestOpp';
		  oppTest3_1.AccountID = accTest3_1.id;
		  oppTest3_1.Type = 'New Business';
		  oppTest3_1.Sales_Model__c = 'Direct';
		  oppTest3_1.Brand_Name__c ='RingCentral';
		  oppTest3_1.Tier_Name__c = 'Power';
		  oppTest3_1.StageName = '4. Closed';	
		  oppTest3_1.CloseDate = System.today();
		  
		  insert oppTest3_1;
		  TriggerHandler.RESET_VARIABLES();
		  
		  Set<Id> testOppId3 = new Set<Id>();
		  testOppId3.add(oppTest3.id);
		  testOppId3.add(oppTest3_1.id);
		  
		  Test.startTest();
			OpportunitySurveyClass  opscCsat_onCreation = new OpportunitySurveyClass(testOppId3, 'Saves CSAT', 'ON_INSERT');
		  Test.stopTest(); 
	  }
	  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	  @isTest
	public static void TestOpportunityUpload() {
	        // TO DO: implement unit test
	        OpportunityUpload emailServiceObj = new OpportunityUpload();
	    	// Create a new email, envelope object and Attachment
			Messaging.InboundEmail email = new Messaging.InboundEmail();
			Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
			Messaging.InboundEmail.Textattachment inAtt = new Messaging.InboundEmail.Textattachment();
			Messaging.InboundEmail.Binaryattachment inBtt = new Messaging.InboundEmail.Binaryattachment();
			
		   	email.subject = 'test';
			env.fromAddress = 'user@acme.com';
		
			email.binaryAttachments = new Messaging.inboundEmail.Binaryattachment[] {inBtt }; 
		   
		   	///////////////////////////// binary tests
		   
		   	inBtt.body = blob.valueOf('*EOL*');
		   	inBtt.fileName = 'attach.csv';
			
		   	inBtt.body = blob.valueOf('999*EOL*');
			email.binaryAttachments = new Messaging.inboundEmail.Binaryattachment[] {inBtt };
			emailServiceObj.handleInboundEmail(email, env );	   
	}
}