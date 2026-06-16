/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 */
@isTest
private class Test_RCSupportAdvCaseCreate {
	
	static{
		List<Portals_List__c> lstPortal = new List<Portals_List__c>();
		lstPortal.add(new Portals_List__c(Name = 'success.ringcentral.com', Brand__c = 'RC US'));
		insert lstPortal;
		
		List<Product_Assistance_List__c> lstProductAss = new List<Product_Assistance_List__c>();
		lstProductAss.add(new Product_Assistance_List__c(Name = 'Company Settings', Portal__c = 'RC US, RC CA, RC UK, BT'));
		insert lstProductAss;
		
		TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = true;
    	TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = true;
    	TriggerHandler.BY_PASS_CONTACT_ON_INSERT = true;
    	TriggerHandler.BY_PASS_CONTACT_ON_UPDATE = true;
    	TriggerHandler.BY_PASS_CASE_ON_INSERT = true;
    	TriggerHandler.BY_PASS_CASE_ON_UPDATE = true;
	}

  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
  @isTest
  static void testNavigationMethods() {
    List<Account> testList = new List<Account>{
        new Account(Name = 'Test Account 1'), 
        new Account(Name = 'Test Account 2'), 
        new Account(Name = 'Test Account 3'), 
        new Account(Name = 'Test Account 4'), 
        new Account(Name = 'Test Account 5')
    };
      
    RCSupportPortalCasePagingHelper helper = new RCSupportPortalCasePagingHelper(testList);
      
    helper.pageNumber = 1;
    helper.nextBtnClick();
      
    helper.pageNumber = 2;
    helper.previousBtnClick();
      
    helper.last();
      
    helper.index = 15;
    helper.listObj1 = new List<Object>();

    helper.pageNumberParam = 3;
    helper.getRecordsByPN();

  }

  @isTest
  static void testSerialize() {
      RCSupportAdvCaseCreate.GdprRequestHolder holder = new RCSupportAdvCaseCreate.GdprRequestHolder();
      holder.FirstName = 'John';
      holder.LastName = 'Doe';
      holder.Email = 'john.doe@example.com';
      holder.RcPhone = '1234567890';
      holder.EuCitizen = true;
      holder.ViewRequest = true;
      holder.ChangeRequest = false;
      holder.DownloadRequest = true;
      holder.DeleteRequest = false;
      holder.RetainAnalytics = false;
      holder.RetainGlip = false;
      holder.Comments = 'Test comments';
        
	  String expectedSubject = 'DSR Request: "John Doe"';
            
    String expectedSerializedData = '\n\n====================\n\n' +
                                    'View: Yes\n' +
                                    'Change: No\n' +
                                    'Download: Yes\n' +
                                    'Delete: No\n' +
                                    'Name of user requiring privacy action: John Doe\n' +
                                    'Email of user requiring privacy action: john.doe@example.com\n' +
                                    'RC Phone Number (if applicable) of the user requiring privacy action: 1234567890\n' +
                                    'Is this user a Citizen or legal resident within the EU (including UK): Yes\n' +
                                    'Comments: Test comments';
    System.assertEquals(expectedSubject, holder.CaseSubject, 'Case subject is incorrect'); 
    System.assertEquals(expectedSerializedData, holder.Serialize(), 'Serialized data is incorrect');
  }

  @isTest
  static void testConstructor() {
    RCSupportAdvCaseCreate instance = new RCSupportAdvCaseCreate();
    List<SelectOption> result2 = instance.selectOptionViews();
        
    System.assertEquals(2, result2.size(), 'Number of options should match');
    System.assertEquals('My Cases', result2[0].getLabel(), 'First option should be "My Cases"');
    System.assertEquals('My Open Cases', result2[1].getLabel(), 'Second option should be "My Open Cases"');
    System.assertEquals(false, instance.flag, 'Flag should be initialized to false');
  }

  @isTest
  static void testWrapperCaseConstructor() {
    RCSupportAdvCaseCreate.WrapperCase wrapper = new RCSupportAdvCaseCreate.WrapperCase();
        
    System.assertNotEquals(null, wrapper.caseObj, 'caseObj should not be null');
    System.assertEquals(null, wrapper.strformatDT, 'strformatDT should be null');
    System.assertEquals(0, wrapper.caseIndex, 'caseIndex should be 0');
  }
	
  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@isTest
    static void myUnitTest1() {
        try {
        	TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = true;
        	TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = true;
        	TriggerHandler.BY_PASS_CONTACT_ON_INSERT = true;
        	TriggerHandler.BY_PASS_CONTACT_ON_UPDATE = true;
        	TriggerHandler.BY_PASS_CASE_ON_INSERT = true;
        	TriggerHandler.BY_PASS_CASE_ON_UPDATE = true;
        	
        	EntitlementEnable__c mycs = EntitlementEnable__c.getValues('IsEntitlementsEnabled__c');
			  if(mycs == null) {
			    mycs = new EntitlementEnable__c();
			    mycs.IsEntitlementsEnabled__c = true;
			    mycs.Name = 'IsEntitlementsEnabled';
			    insert mycs;
		  	}
		  	
		  	Account acctest = new Account();
            acctest.Name = 'TestAccount';
            acctest.RecordTypeId  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account').getRecordTypeId();
            insert acctest; 
            
            List<Contact> lstCont = new List<Contact>();
            Contact contObj = new Contact();
            contObj.AccountId =  acctest.Id;
            contObj.Email = 'abc2@test.com';
            contObj.LastName = 'Test Last2';
            contObj.FirstName = 'Test First2';
            contObj.Phone_Ext__c = Double.valueOf('1234');
            lstCont.add(contObj);
            
            Contact contObj1 = new Contact();
            contObj1.AccountId =  acctest.Id;
            contObj1.FirstName = 'Manish';
            contObj1.LastName = 'Singh';
            contObj1.Email = 'manish@simplon.com';
            contObj1.Phone= '1234567891';
            contObj1.Phone_Ext__c= Double.valueOf('1234');
            lstCont.add(contObj1);
		  	
		  	insert lstCont;
		  	
		  	Case caseObj = new Case();
            caseObj.AccountId = acctest.Id;
            caseObj.ContactId = contObj.id;
            caseObj.Subject = 'Test Case';
            caseObj.Description = 'Test Case Desc';
            insert caseObj;
            
            List<CaseComment> lstcasecomment  = new List<CaseComment>();
            CaseComment casecommentObj1 = new CaseComment();
            casecommentObj1.CommentBody = 'Test';
            casecommentObj1.ParentId = caseObj.id;
            lstcasecomment.add(casecommentObj1);
            
            CaseComment casecommentObj2 = new CaseComment();
            casecommentObj2.CommentBody = 'Test1';
            casecommentObj2.ParentId = caseObj.id;
            lstcasecomment.add(casecommentObj2);
            insert lstcasecomment;
            
            List<Attachment> lstAtt = new List<Attachment>();
            Attachment attachObj = new  Attachment();
            attachObj.ParentId = caseObj.id;
            attachObj.Name = 'testAttachment';  
            attachObj.body = Blob.valueOf('dkjghdksgjdshgdkh');
            //insert attachObj;
            lstAtt.add(attachObj);
            
            Attachment attachObj1 = new  Attachment();
            attachObj1.Name = 'testAttachment';  
            attachObj1.body = Blob.valueOf('dkjghdksgjdshgdkh');
            attachObj1.ParentId = caseObj.id;
            lstAtt.add(attachObj1);
            insert lstAtt;
            
            Portal_Cases_Record_Types__c cs1 = new Portal_Cases_Record_Types__c();
            cs1.Name = 'Support - T1';
            insert cs1;
	  		
	  		Profile p = [SELECT Id FROM Profile WHERE Name='Customer Portal User']; 
		 	
		 	User LoginUser = new User(ContactId = lstCont[0].Id, Alias = 'standt', Email='standarduser@testorg.com',	EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
		 							  LocaleSidKey='en_US', ProfileId = p.Id,TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg.com');
            insert LoginUser;
             System.runAs(LoginUser) {
             	Test.startTest();
	            RCSupportAdvCaseCreate createcaseObj1 = new RCSupportAdvCaseCreate(new ApexPages.StandardController(new Case()));
	            createcaseObj1.loginUser = LoginUser;
	            system.debug('loginUser========='+loginUser);
	            createcaseObj1.ConDetail.FirstName = 'Manish';
			  	createcaseObj1.ConDetail.LastName = 'Singh';
			  	createcaseObj1.ConDetail.Email = 'manish@simplion.com';
			  	createcaseObj1.ConDetail.Phone = '1234567891';
			  	createcaseObj1.ConDetail.Phone_Ext__c = Double.valueOf('1122');
			  	createcaseObj1.selectedViewOptions1 ='All Open Cases';
			  	createcaseObj1.PhoneExt = '1122';
			  	createcaseObj1.actionType ='Previous';
		        createcaseObj1.getcaseSeverityItemsValues();
	            createcaseObj1.getproductAssistanceItemsValues();
	            createcaseObj1.showArticleList();
	            createcaseObj1.attachment = attachObj1;
	            createcaseObj1.fileSize = (1024 * 1024);
	            createcaseObj1.createCase();
	            createcaseObj1.sortCaseList(); 
	            createcaseObj1.selectSortValue = 'Case_Status';
	            createcaseObj1.sortCaseList();
	            createcaseObj1.searchCase();
	            createcaseObj1.getcaseList1();
	            createcaseObj1.selectSearchValue = 'Contact_Name';
	            createcaseObj1.inputSearchValue = 'Test First2 Test Last2';
	            createcaseObj1.searchCase();
	            createcaseObj1.selectSearchValue = 'Case_Number';
	            createcaseObj1.inputSearchValue = 'Test First2 Test Last2';
	            createcaseObj1.searchCase();
	            createcaseObj1.selectSearchValue = 'Subject';
	            createcaseObj1.inputSearchValue = 'Test First2 Test Last2';
	            createcaseObj1.searchCase();
	            createcaseObj1.selectSearchValue = 'Severity_Level';
	            createcaseObj1.inputSearchValue = 'Test First2 Test Last2';
	            createcaseObj1.searchCase();
	            createcaseObj1.getcaseSeverityItemsValues();
	            createcaseObj1.setPortalQuestion();
	            createcaseObj1.assistanceChange();
	            
	           
	            ApexPages.currentPage().getParameters().put('parentId', caseObj.id);
	            RCSupportAdvCaseCreate createcaseObj2 = new RCSupportAdvCaseCreate(new ApexPages.StandardController(new Case()));
	            createcaseObj2.ConDetail.FirstName = 'Manish';
			  	createcaseObj2.ConDetail.LastName = 'Singh';
			  	createcaseObj2.ConDetail.Email = 'manish@simplion.com';
			  	createcaseObj2.ConDetail.Phone = '1234567891';
			  	createcaseObj2.ConDetail.Phone_Ext__c =  Double.valueOf('2211');
	          	createcaseObj2.createCase();
	          	createcaseObj2.SummitCase();
	          	
	          	Test.stopTest();
             	
             }
            
        } catch(Exception ex) {
        	system.Debug('>>ex>>'+ex.getMessage());
        }
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
     @isTest
    static void myUnitTest2() {
     	try {
     		EntitlementEnable__c mycs = EntitlementEnable__c.getValues('IsEntitlementsEnabled__c');
			  if(mycs == null) {
			    mycs = new EntitlementEnable__c();
			    mycs.IsEntitlementsEnabled__c = true;
			    mycs.Name = 'IsEntitlementsEnabled';
			    insert mycs;
		  	}
		  	
            Account acctest = new Account();
            acctest.Name = 'TestAccount';
            acctest.RecordTypeId  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account').getRecordTypeId();
            insert acctest; 
            
            List<Contact>   lstCont = new List<Contact>();  
            Contact contObj = new Contact();
            contObj.AccountId =  acctest.Id;
            contObj.Email = 'abc2@test.com';
            contObj.LastName = 'Test Last2';
            contObj.FirstName = 'Test First2';
            contObj.Phone_Ext__c = Double.valueOf('123');
            //insert contObj;
            lstCont.add(contObj);
            
            Contact contObj1 = new Contact();
            contObj1.AccountId =  acctest.Id;
            contObj1.FirstName = 'Manish';
            contObj1.LastName = 'Singh';
            contObj1.Email = 'manish@simplon.com';
            contObj1.Phone= '1234567891';
            contObj1.Phone_Ext__c = Double.valueOf('1234');
            lstCont.add(contObj1);
            insert lstCont;
            
            Case caseObj = new Case();
            caseObj.AccountId = acctest.Id;
            caseObj.ContactId = contObj.id;
            caseObj.Subject = 'Test Case';
            caseObj.Description = 'Test Case Desc';
            insert caseObj;
            
            Portal_Cases_Record_Types__c cs1 = new Portal_Cases_Record_Types__c();
            cs1.Name = 'Support - T1';
            insert cs1;
            
            List<CaseComment> lstCC = new List<CaseComment>();
            CaseComment casecommentObj1 = new CaseComment();
            casecommentObj1.CommentBody = 'Test';
            casecommentObj1.ParentId = caseObj.id;
            lstCC.add(casecommentObj1);
            
            CaseComment casecommentObj2 = new CaseComment();
            casecommentObj2.CommentBody = 'Test1';
            casecommentObj2.ParentId = caseObj.id;
            lstCC.add(casecommentObj2);
            insert lstCC;
            List<Attachment> lstAtt = new List<Attachment>();
            
            Attachment attachObj = new  Attachment();
            attachObj.ParentId = caseObj.id;
            attachObj.Name = 'testAttachment';  
            attachObj.body = Blob.valueOf('dkjghdksgjdshgdkh');
            lstAtt.add(attachObj);
           
            Attachment attachObj1 = new  Attachment();
            attachObj1.Name = 'testAttachment';  
            attachObj1.body = Blob.valueOf('dkjghdksgjdshgdkh');
            lstAtt.add(attachObj1);
            insert lstAtt;
           
            Test.startTest();
            RCSupportAdvCaseCreate createCaseObjDummy = new RCSupportAdvCaseCreate();
        	
        	RCSupportAdvCaseCreate createcaseObj3 = new RCSupportAdvCaseCreate(new ApexPages.StandardController(new Case())); 
        	createcaseObj3.setPortalQuestion();
        	
            createcaseObj3.selectedProduct = 'Test2';
            createcaseObj3.selectedProduct2 = 'Test3';
            createcaseObj3.selectedProduct3 = 'Test4';
            createcaseObj3.setPortalQuestion();
            createcaseObj3.assistanceChange();   
            Test.stopTest();
     	} catch(Exception ex) {} 
     }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void myUnitTest() {
        	EntitlementEnable__c mycs = EntitlementEnable__c.getValues('IsEntitlementsEnabled__c');
			  if(mycs == null) {
			    mycs = new EntitlementEnable__c();
			    mycs.IsEntitlementsEnabled__c = true;
			    mycs.Name = 'IsEntitlementsEnabled';
			    insert mycs;
		  	}
		  	
		  	Account acctest = new Account(RC_Brand__c = 'test');
            acctest.Name = 'TestAccount';
            acctest.RecordTypeId  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account').getRecordTypeId();
            insert acctest; 
            
            List<Contact> lstCont = new List<Contact>();
            
            Contact contObj = new Contact();
            contObj.AccountId =  acctest.Id;
            contObj.Email = 'abc2@test.com';
            contObj.LastName = 'Test Last2';
            contObj.FirstName = 'Test First2';
            contObj.Phone_Ext__c = Integer.valueOf('1234');
            lstCont.add(contObj);
            
            Contact contObj1 = new Contact();
            contObj1.AccountId =  acctest.Id;
            contObj1.FirstName = 'Manish';
            contObj1.LastName = 'Singh';
            contObj1.Email = 'manish@simplion.com';
            contObj1.Phone= '1234567891';
            contObj1.Phone_Ext__c = Integer.valueOf('1234');
            lstCont.add(contObj1);
		  	
		  	insert lstCont;
		  	
		  	Case caseObj = new Case();
            caseObj.AccountId = acctest.Id;
            caseObj.ContactId = contObj.id;
            caseObj.Subject = 'Test Case';
            caseObj.Description = 'Test Case Desc';
            insert caseObj;
            
            List<CaseComment> lstcasecomment  = new List<CaseComment>();
            CaseComment casecommentObj1 = new CaseComment();
            casecommentObj1.CommentBody = 'Test';
            casecommentObj1.ParentId = caseObj.id;
            lstcasecomment.add(casecommentObj1);
            
            CaseComment casecommentObj2 = new CaseComment();
            casecommentObj2.CommentBody = 'Test1';
            casecommentObj2.ParentId = caseObj.id;
            lstcasecomment.add(casecommentObj2);
            insert lstcasecomment;
            
            Portal_Cases_Record_Types__c cs1 = new Portal_Cases_Record_Types__c();
            cs1.Name = 'Support - T1';
            insert cs1;
            
	  		Profile p = [SELECT Id FROM Profile WHERE Name='Customer Portal User']; 
		 	
		 	User LoginUser = new User( ContactId = lstCont[1].Id ,FirstName = 'Manish',LastName = 'Singh',Alias = 'standt', Email='manish@simplion.com',	
		 							   EmailEncodingKey='UTF-8',  LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId = p.Id,
		 							   TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg.com');
            insert LoginUser;
             System.runAs(LoginUser) {
             	Test.startTest();
	            ApexPages.currentPage().getParameters().put('parentId', caseObj.id);
	            RCSupportAdvCaseCreate createcaseObj1 = new RCSupportAdvCaseCreate(new ApexPages.StandardController(new Case()));
	           
	            system.debug('loginUser========='+loginUser);
	            createcaseObj1.ConDetail.FirstName = 'Manish';
			  	createcaseObj1.ConDetail.LastName = 'Singh';
			  	createcaseObj1.ConDetail.Email = 'manish@simplion.com';
			  	createcaseObj1.ConDetail.Phone = '12345679999';
			  	createcaseObj1.ConDetail.Phone_Ext__c = Double.valueOf('1134');
			  	createcaseObj1.PhoneExt = '1122';
			    createcaseObj1.selectedViewOptions1 = 'All Open Cases';
			  	createcaseObj1.selectedProduct = 'test';
			  	createcaseObj1.selectedProduct2  = 'test';
			  	createcaseObj1.selectedProduct3 = 'test';
			  	createcaseObj1.setPortalQuestion();
			  	createcaseObj1.createCase();
			  	createcaseObj1.SummitCase();
			  	createcaseObj1.assistanceChange();
			  	createcaseObj1.showArticleList();
			  	Test.stopTest();
             	
             }
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
      static void testIfMessageRequired() {
        RCSupportAdvCaseCreate instance = new RCSupportAdvCaseCreate();
        instance.selectedProduct = 'selectedProduct';
        instance.selectedProduct2 = 'selectedProduct2';
        instance.selectedProduct3 = 'selectedProduct3';
        
        Test.startTest();
        instance.ifMessageRequired();
        Test.stopTest();
    }

    @isTest
    static void testWrPgIteratorInitialization() {
        RCSupportAdvCaseCreate.WrPgIterator instance = new RCSupportAdvCaseCreate.WrPgIterator();
        
        System.assertEquals(null, instance.wrfirstElement, 'wrfirstElement should be null');
        System.assertEquals(null, instance.wrlastElement, 'wrlastElement should be null');
        System.assertEquals(null, instance.rtnIntList, 'rtnIntList should be null');
    }

    @isTest
    static void testFlagValue() {
        RCSupportAdvCaseCreate instance = new RCSupportAdvCaseCreate();
        
        Test.startTest();
        PageReference result = instance.flagValue();
        Boolean result2 = instance.getSCPortal();
        Test.stopTest();
        
        System.assertEquals(null, result, 'flagValue should return null');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testGetGdprRequest() {
        RCSupportAdvCaseCreate controller = new RCSupportAdvCaseCreate();
        RCSupportAdvCaseCreate.GdprRequestHolder gdprRequest = controller.GetGdprRequest();
        RCSupportAdvCaseCreate.GdprRequestHolder setgdprRequest = new RCSupportAdvCaseCreate.GdprRequestHolder();
        controller.SetGdprRequest(gdprRequest);
    }
}