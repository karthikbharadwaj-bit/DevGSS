@isTest
private class Test_FossTicket {

	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void myUnitTest() {
    	try{
	    	Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
	        User u = new User(Alias = 'standt', Email='standardusertestpop@testorg.com', 
	            EmailEncodingKey='UTF-8', LastName='Testingtest@123', LanguageLocaleKey='en_US', 
	            LocaleSidKey='en_US', ProfileId = p.Id, 
	            TimeZoneSidKey='America/Los_Angeles', UserName='standardusertestpop@testorg.com');
	    	insert u;
	    	Legal_Requests__c legalObj = new Legal_Requests__c(); 
	        ApexPages.StandardController sc = new ApexPages.standardController(legalObj);
	        FOSSTicket clsObj = new FOSSTicket(sc);
	        clsObj.cancelButton();  
	        legalObj.FOSS_Name__c = 'Test FOSSTest';
	        clsObj.saveData();
	        clsObj.watcherObj.Advisor_Name__c = u.id;
	        clsObj.saveWatcher();
	        clsObj.editData(); 
	        clsObj.attachObj.Body = blob.valueOf('Test Body');
	        clsObj.attachObj.ParentId = legalObj.Id;
	        clsObj.attachObj.Name = 'Test';
	        clsObj.uploadFile();
	        clsObj.submitCase();
	        ApexPages.currentPage().getParameters().put('id',legalObj.id);
	        clsObj.getIsFossId();
    	}catch(exception e){
    		system.debug('Exception:'+e.getMessage());
    	}
    }
	
	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void myUnitTest1() {  
    	Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'standt', Email='standardusertestpop1@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testingtest@123', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standardusertestpop1@testorg.com'); 
    	insert u;
    	Legal_Requests__c legalObj	= new Legal_Requests__c();
    	legalObj.Name = 'Test';
    	legalObj.FOSS_Name__c = 'TestFOSSTestFOSSTestFOSSTestFOSSTestFOSSTestFOSSTestFOSSTestFOSSTestFOSSTestFOSSTestFOSSTestFOSS';
    	insert legalObj;
        ApexPages.currentPage().getParameters().put('id',legalObj.id);
        ApexPages.currentPage().getParameters().put('action','edit');
        ApexPages.StandardController sc1 = new ApexPages.standardController(legalObj);
        FOSSTicket clsObj = new FOSSTicket(sc1);
        clsObj.watcherObj.Advisor_Name__c = u.id;
        clsObj.saveWatcher();
    }
}