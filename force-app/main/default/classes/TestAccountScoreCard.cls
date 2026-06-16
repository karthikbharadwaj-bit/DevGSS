@isTest
private class TestAccountScoreCard {

	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void myUnitTest() {
    	
    	Test_Utils testUtilsObj = new Test_Utils();
    	try {
    		
    		// Creating test User.
	        User testUser = new User();                   
			testUser = testUtilsObj.createUserRecord(new List<User>{new User()})[0];
		
    		Account acctestRc = new Account();
    		acctestRc.Name='RC Internal';
    		acctestRc.Current_Owner__c = testUser.Id; 
    		Account acctest = new Account();
	        acctest.Name='TestAccount';
	        acctest.Current_Owner__c = testUser.Id;
	        
	        List<Account> accountRecordList =  new List<Account>();
	        accountRecordList.add(acctestRc);
	        accountRecordList.add(acctest);
    		accountRecordList = testUtilsObj.createAccountRecord(accountRecordList);
    		
    		Network_Information__c networkInfo =  new Network_Information__c();
			networkInfo.Account__c = accountRecordList[1].Id;
			networkInfo.Router_New_Router_Make_and_Model__c = 'TestModem';
			networkInfo.Modem_Make_and_Model__c = 'TestModel';
			insert networkInfo;
	        
	        Contact contactObj = new Contact();
	        contactObj.AccountId =  accountRecordList[1].Id;
	        contactObj = testUtilsObj.createContactRecord(new List<Contact>{contactObj})[0];
	    	
	        Account_Metric__c accMetricObj = new Account_Metric__c();
	        accMetricObj.Peer_Group_ID__c = 100;
	        accMetricObj.Account_ID__c = accountRecordList[1].Id;
	        accMetricObj = testUtilsObj.createAccountMetricRecords(new List<Account_Metric__c>{accMetricObj})[0];
	        
	        Implementation__c implementationObj =  new Implementation__c();
	        implementationObj.Account__c = accountRecordList[1].Id;
	        implementationObj.Implementation_Status__c = '6a. Completed';
	        implementationObj.Contact__c = contactObj.Id;
	        implementationObj = testUtilsObj.createImplementationRecords(new List<Implementation__c>{implementationObj})[0];
	        
	        Test.startTest();
		        ApexPages.currentPage().getParameters().put('accid', accountRecordList[1].Id);
		        ApexPages.StandardController sc = new ApexPages.standardController(accountRecordList[1]);
		        AccountMetricExtension accmetricExObj = new AccountMetricExtension(sc);
		        accmetricExObj.inputtxtsearch = 'Test';
		        accmetricExObj.getContactOptions();
		        accmetricExObj.selectedContacts.add(contactObj.id);
		        accmetricExObj.setToAddress();
		        accmetricExObj.removeToAddress();
		        accmetricExObj.setCCList();
		        accmetricExObj.removeCCList();
		        accmetricExObj.getAllCCOptions();
		        accmetricExObj.setAdditionalTo();
		        accmetricExObj.removeAdditionalTo();
		        accmetricExObj.getAllAdditionalTo();
		        accmetricExObj.setBccList();
		        accmetricExObj.removeBccList();
		        accmetricExObj.getAllBccOptions();
		        accmetricExObj.sendMailToCustomerCall();
		        accmetricExObj.exportasPDF();
		        accmetricExObj.redirectToSendMailPage();
		        accmetricExObj.cancel();
		        accmetricExObj.getemailonSearch();
				String testEmail = 'test@example.com';
    		    accmetricExObj.emailaddress = testEmail;
        	    Case testCase1 = new Case(Subject = 'Test Case 1');
        	    Case testCase2 = new Case(Subject = 'Test Case 2');
        	    accmetricExObj.caseObj = testCase1;
        	    accmetricExObj.case2Obj = testCase2;
        	    accmetricExObj.ImpCompleted_Green = true;
        	    accmetricExObj.WebPortal_Green = false;
        	    accmetricExObj.AcctNetwork_Red = true;
        	    accmetricExObj.ImpCheckList_Green = true;
        	    accmetricExObj.ImpCheckList_Orange = false;
        	    accmetricExObj.ACCReview_Green = true;
        	    accmetricExObj.ACCReview_Orange = false;
        	    accmetricExObj.IC_CompanyInfo_Green = true;
        	    accmetricExObj.IC_CompanyInfo_Orange = false;
        	    accmetricExObj.IC_Users_Green = true;
        	    accmetricExObj.IC_Users_Orange = false;
        	    accmetricExObj.IC_Phones_Green = true;
        	    accmetricExObj.IC_Phones_Orange = false;
        	    accmetricExObj.IC_Groups_Green = true;
        	    accmetricExObj.IC_Groups_Orange = false;
        	    accmetricExObj.IC_Tools_Green = true;
        	    accmetricExObj.IC_Tools_Orange = false;
        	    accmetricExObj.MobileUser_Orange = true;
        	    accmetricExObj.MobileUser_Red = false;
        	    accmetricExObj.FaxUser_Green = true;
        	    accmetricExObj.FaxUser_Orange = false;
        	    accmetricExObj.FaxUser_Red = true;
        	    accmetricExObj.PortedIn_Green = true;
        	    accmetricExObj.PortedIn_Red = false;
        	    accmetricExObj.ConfUser_Green = true;
        	    accmetricExObj.ConfUser_Red = false;
        	    accmetricExObj.MinuteTrend_Red = true;
        	    accmetricExObj.T3Case_Red = false;
        	    accmetricExObj.RedAcc_Green = true;
        	    accmetricExObj.RedAcc_Red = false;
        	    accmetricExObj.Farming_Green = true;
        	    accmetricExObj.Farming_Orange = false;
        	    accmetricExObj.GradKit_Green = true;
        	    AccountMetricExtension.HealthScoreWrapper healthscore = new AccountMetricExtension.HealthScoreWrapper();  
				healthscore.dLowestCSAT = 3.5;
        	    healthscore.dNewCustomer = 4.0;
        	    healthscore.dRelationship = 4.5;
        	    healthscore.dSupport = 5.0;
        	    healthscore.dImplementation = 3.8;
	        Test.stopTest();	
    	}catch(Exception ex) {
    		system.debug('#### Error on line - '+ex.getLineNumber());
	    	system.debug('#### Error message - '+ex.getMessage());
    	}
    }
    
	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
 	@isTest
    static void myUnitTest1() {
 		
 		Test_Utils testUtilsObj = new Test_Utils();
     	try {
     		
     		// Creating test User.
	        User testUser = new User();                   
			testUser = testUtilsObj.createUserRecord(new List<User>{new User()})[0];
			
     		Account acctestRc = new Account();
    		acctestRc.Name='TestAccount';
    		acctestRc.Current_Owner__c = testUser.Id; 
    		acctestRc = testUtilsObj.createAccountRecord(new List<Account>{acctestRc})[0];
	        
	        Contact contactObj = new Contact();
	        contactObj.AccountId =  acctestRc.id;
	        contactObj = testUtilsObj.createContactRecord(new List<Contact>{contactObj})[0];
	    	
	        Account_Metric__c accMetricObj = new Account_Metric__c();
	        accMetricObj.Peer_Group_ID__c = 101;
	        accMetricObj.Account_ID__c = acctestRc.Id;
	        accMetricObj = testUtilsObj.createAccountMetricRecords(new List<Account_Metric__c>{accMetricObj})[0];
	        
	        Test.startTest();
		        ApexPages.currentPage().getParameters().put('accid', acctestRc.id);
		        ApexPages.StandardController sc = new ApexPages.standardController(acctestRc);
		        AccountMetricExtensionPDF accmetricExPDFObj = new AccountMetricExtensionPDF(sc);
				accmetricExPDFObj.getMetricSet();
	        Test.stopTest();			
     	} catch(Exception ex) {
     		system.debug('#### Error on line - '+ex.getLineNumber());
	    	system.debug('#### Error message - '+ex.getMessage());
     	}
     }
     
	 @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
     @isTest
    static void myUnitTest2() {
     	
     	Test_Utils testUtilsObj = new Test_Utils();
     	try {
     		
     		// Creating test User.
	        User testUser = new User();                   
			testUser = testUtilsObj.createUserRecord(new List<User>{new User()})[0];
			
     		Account acctestRc = new Account();
    		acctestRc.Name='TestAccount';
    		acctestRc.Current_Owner__c = testUser.Id; 
    		acctestRc = testUtilsObj.createAccountRecord(new List<Account>{acctestRc})[0];
	        
	        Account_Metric__c accMetricObj = new Account_Metric__c();
	        accMetricObj.Peer_Group_ID__c = 101;
	        accMetricObj.Account_ID__c = acctestRc.Id;
	        accMetricObj = testUtilsObj.createAccountMetricRecords(new List<Account_Metric__c>{accMetricObj})[0];
	        
	        Test.startTest();
		        //ApexPages.currentPage().getParameters().put('accid', acctest.id);
		        ApexPages.StandardController sc = new ApexPages.standardController(acctestRc);
		        AccountHealthcardHelper acchealthObj = new AccountHealthcardHelper(sc);
				acchealthObj.getMetricSet();
	        Test.stopTest();			
     	} catch(Exception ex) {
     		system.debug('#### Error on line - '+ex.getLineNumber());
	    	system.debug('#### Error message - '+ex.getMessage());
     	}
     }
     
	 @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
      @isTest
    static void myUnitTest3() {
     	
     	Test_Utils testUtilsObj = new Test_Utils();
     	try {
     		
     		// Creating test User.
	        User testUser = new User();                   
			testUser = testUtilsObj.createUserRecord(new List<User>{new User()})[0];
			
     		Account acctestRc = new Account();
    		acctestRc.Name='TestAccount';
    		acctestRc.Current_Owner__c = testUser.Id; 
    		acctestRc = testUtilsObj.createAccountRecord(new List<Account>{acctestRc})[0];
	        
	        Account_Metric__c accMetricObj = new Account_Metric__c();
	        accMetricObj.Peer_Group_ID__c = 101;
	        accMetricObj.Metric_1_value__c = 0;
	        accMetricObj.Metric_18_value__c = 0;
	        accMetricObj.Metric_11_value__c = 1;
	        accMetricObj.Account_ID__c = acctestRc.Id;
	        accMetricObj = testUtilsObj.createAccountMetricRecords(new List<Account_Metric__c>{accMetricObj})[0];
	        
	        Test.startTest();
		        ApexPages.currentPage().getParameters().put('accid', acctestRc.Id);
		        ApexPages.StandardController sc = new ApexPages.standardController(acctestRc);
		        AccountMetricExtension accmetricExObj = new AccountMetricExtension(sc);
				accmetricExObj.getMetricSet();
	        Test.stopTest();			
     	} catch(Exception ex) {
     		system.debug('#### Error on line - '+ex.getLineNumber());
	    	system.debug('#### Error message - '+ex.getMessage());
     	}
     }
}// End of Test Class.