@isTest
private class Test_ClassAccount {
	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@isTest
    static void Test_Approvaldefaults(){
		Test.startTest();
		Account a = new Account();
		a.Name = 'TestbyAA';
		a.RC_User_ID__c = '345';
		insert a;
		
		Opportunity o = new Opportunity();
		o.Name = 'TestaOpp';
		o.AccountId = a.Id;
		o.Type = 'New Business';
		o.CloseDate = Date.today();
		o.StageName = '3. ActivePipe';
		o.OwnerId = HardcodedIdsMapper.getMatchedObjectId('005800000036sJJ');
		o.RC_User_ID__c = '345';
		insert o;
		Test.stopTest();
		
		Approval__c objApp = new Approval__c();
		string strrecord = [select id from RecordType where SobjectType='Approval__c' AND Name = 'Invoicing Request' limit 1].id;
		objApp.RecordTypeId=strrecord;
		system.debug('objApp.RecordTypeId:'+objApp.RecordTypeId);
		ApexPages.currentPage().getParameters().put('RecordType', strrecord);
		system.debug(ApexPages.currentPage().getParameters().get('RecordType'));
		ApexPages.StandardController stdCont = new ApexPages.StandardController(objApp);
		
		Approvaldefaults app = new Approvaldefaults(stdCont);
		app.actapprovalObject();
		
		//app.actapprovalObject();
	} 
	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@isTest
    static void Test_authUserWS() {

		Account objAccont = new Account();
		//LastName = 'test',RC_User_ID__c = '123456'
		objAccont.Name = 'test';
		objAccont.RC_User_ID__c = '123456';
		insert objAccont;
		Contact c = new Contact();
		c.LastName = 'contactLast';
		c.AccountId = objAccont.Id;//[SELECT id FROM Account WHERE name=: a.Name].id;
		c.email='test@test.com';

		try{
			insert c;	
		}catch (Exception exp){

		} 
		Profile p = [SELECT Id FROM Profile WHERE Name='Customer Portal User']; 
		User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
				EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
				LocaleSidKey='en_US', ProfileId = p.Id,contactId =c.id, 
				TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg.com');
		insert u;


		test.startTest();
		authUserWS syncAcc = new authUserWS();
		authUserWS.authUserInputParam syncparam = new authUserWS.authUserInputParam();
		syncparam.In_RCUserID='123456';
		syncparam.In_RCPrimaryNumber='234567';
		syncparam.In_ContactMail ='test@test.com';
		//syncparam.Out_Status ='test';
		syncparam.Out_UserID ='23456';
		syncparam.Out_Password ='test';
		authUserWS.authUser(syncparam);
		test.stopTest();
	}
}