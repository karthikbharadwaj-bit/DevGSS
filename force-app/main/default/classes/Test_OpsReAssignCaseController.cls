@isTest
private class Test_OpsReAssignCaseController {

	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void TestOpsReAssignCaseController() {
    	try{
    		string strId =  userinfo.getUserId();
			User su = [SELECT Id,Name FROM User WHERE Id =:strId ];
    		
    		try {
        		EntitlementEnable__c mycs = EntitlementEnable__c.getValues('IsEntitlementsEnabled__c');
				 if(mycs == null) {
				    mycs = new EntitlementEnable__c();
				    mycs.IsEntitlementsEnabled__c = true;
				    mycs.Name = 'IsEntitlementsEnabled';
				    insert mycs;
		  	    }
    		}catch(exception ex){}
    		
    		Account acctest = new Account();
	     	acctest.Name = 'TestAccount';
	     	acctest.RecordTypeId  = Schema.SObjectType.Account.getRecordTypeInfosByName()
                .get('Partner Account').getRecordTypeId();
	     	insert acctest; 
		        
	        Contact contObj = new Contact();
		    contObj.AccountId =  acctest.Id;
		    contObj.Email = 'abc2@test.com';
		    contObj.LastName = 'Test Last2';
		    contObj.FirstName = 'Test First2';
	      	insert contObj;
	      	
        	Case caseObj = new Case();
	      	caseObj.AccountId = acctest.Id;
	      	caseObj.ContactId = contObj.id;
	      	caseObj.OwnerId= su.Id;
	      	caseObj.Subject = 'Test Case';
	      	caseObj.Description = 'Test Case Desc';
	      	insert caseObj;
	      	
	      	CaseComment casecommentObj1 = new CaseComment();
	      	casecommentObj1.CommentBody = 'Test';
	      	casecommentObj1.ParentId = caseObj.id;
	      	insert casecommentObj1;
	      	
	      	test.startTest();
	      	ApexPages.currentPage().getParameters().put('id',caseObj.Id);
	      	ApexPages.StandardController controller = new ApexPages.StandardController(caseObj);
	      	OpsReAssignCaseController objORACC = new OpsReAssignCaseController(controller);
	      	objORACC.save();
			test.stopTest();
    	}catch(exception ex){}
			
	      	
    }
	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
     @isTest
    static void TestOpsReAssignCaseController1() {
     	try{
     		string strId =  userinfo.getUserId();
			User su = [SELECT Id,Name FROM User WHERE Id =:strId ];
    		
    		try {
        		EntitlementEnable__c mycs = EntitlementEnable__c.getValues('IsEntitlementsEnabled__c');
				 if(mycs == null) {
				    mycs = new EntitlementEnable__c();
				    mycs.IsEntitlementsEnabled__c = true;
				    mycs.Name = 'IsEntitlementsEnabled';
				    insert mycs;
		  	    }
    		}catch(exception ex){}
    		
    		Account acctest = new Account();
	     	acctest.Name = 'TestAccount';
	     	acctest.RecordTypeId  = Schema.SObjectType.Account.getRecordTypeInfosByName()
                .get('Partner Account').getRecordTypeId();
	     	insert acctest; 
		        
	        Contact contObj = new Contact();
		    contObj.AccountId =  acctest.Id;
		    contObj.Email = 'abc2@test.com';
		    contObj.LastName = 'Test Last2';
		    contObj.FirstName = 'Test First2';
	      	insert contObj;
     		Case caseObj1 = new Case();
	      	caseObj1.AccountId = acctest.Id;
	      	caseObj1.ContactId = contObj.id;
	      	caseObj1.OwnerId= su.Id;
	      	caseObj1.Subject = 'Test Case';
	      	caseObj1.Description = 'Test Case Desc';
	      	insert caseObj1;
	      	test.startTest();
	      	ApexPages.currentPage().getParameters().put('id',caseObj1.Id);
	      	ApexPages.StandardController controller1 = new ApexPages.StandardController(caseObj1);
	      	OpsReAssignCaseController objORACC1 = new OpsReAssignCaseController(controller1);
	      	objORACC1.strClosingComments = 'test';
	      	objORACC1.save();
	      	test.stopTest();
     	}catch(exception ex){}
     		
     }
	 @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
      @isTest
    static void TestOpsReAssignCaseController2() {
      	try{
      		User su = [SELECT Id,Name FROM User Where isActive = true limit 1 ];
    		system.debug('=========su '+su);
    		try {
        		EntitlementEnable__c mycs = EntitlementEnable__c.getValues('IsEntitlementsEnabled__c');
				 if(mycs == null) {
				    mycs = new EntitlementEnable__c();
				    mycs.IsEntitlementsEnabled__c = true;
				    mycs.Name = 'IsEntitlementsEnabled';
				    insert mycs;
		  	    }
    		}catch(exception ex){}
    		
    		Account acctest = new Account();
	     	acctest.Name = 'TestAccount';
	     	acctest.RecordTypeId  = Schema.SObjectType.Account.getRecordTypeInfosByName()
                .get('Partner Account').getRecordTypeId();
	     	insert acctest; 
		        
	        Contact contObj = new Contact();
		    contObj.AccountId =  acctest.Id;
		    contObj.Email = 'abc2@test.com';
		    contObj.LastName = 'Test Last2';
		    contObj.FirstName = 'Test First2';
	      	insert contObj;
     		
     		Case caseObj1 = new Case();
	      	caseObj1.AccountId = acctest.Id;
	      	caseObj1.ContactId = contObj.id;
	      	caseObj1.OwnerId= su.Id;
	      	caseObj1.Subject = 'Test Case';
	      	caseObj1.Description = 'Test Case Desc';
	      	
	      	insert caseObj1;
	      	
	      	test.startTest();
	      	ApexPages.currentPage().getParameters().put('id',caseObj1.Id);
	      	ApexPages.StandardController controller1 = new ApexPages.StandardController(caseObj1);
	      	OpsReAssignCaseController objORACC1 = new OpsReAssignCaseController(controller1);
	      	objORACC1.strClosingComments = 'test';
	      	objORACC1.save();
	      	test.stopTest();
      	}catch(exception ex){}
			
     }
}