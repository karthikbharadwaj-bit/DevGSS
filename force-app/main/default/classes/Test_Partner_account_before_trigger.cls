@isTest 
private class Test_Partner_account_before_trigger {

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@isTest
	private static void testName() {
        Schema.DescribeSObjectResult result = Account.SObjectType.getDescribe();
        Map<String, Schema.RecordTypeInfo> rtMapByRecName = result.getRecordTypeInfosByName();
        Id objRecordType = rtMapByRecName.get(AccountTriggerHelperExt.CUSTOMER_ACCOUNT).getRecordTypeId();

        Account newAcc = new Account (
            Name = 'New Test Acc',
            Partner_ID__c = '12345612',
            RecordTypeId = objRecordType
        );
        insert newAcc;

        newAcc.Partner_ID__c = '111111111111';
        update newAcc;
	}

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@isTest
	private static void testName2() {
        Schema.DescribeSObjectResult result = Account.SObjectType.getDescribe();
        Map<String, Schema.RecordTypeInfo> rtMapByRecName = result.getRecordTypeInfosByName();
        Id objRecordType = rtMapByRecName.get(AccountTriggerHelperExt.CUSTOMER_ACCOUNT).getRecordTypeId();
        Id partnerAccountRecordType = rtMapByRecName.get(AccountTriggerHelperExt.PARTNER_ACCOUNT).getRecordTypeId();

        Account newAcc = new Account (
            Name = 'New Test Acc',
            Partner_ID__c = '12345612',
            RecordTypeId = partnerAccountRecordType
        );
        insert newAcc;

        newAcc.IsPartner = true;
        update newAcc;

        Contact testCont = new Contact (
            LastName = 'Test1',
            AccountId = newAcc.Id
        );
        insert testCont;

        System.runAs(new user(ID = UserInfo.getUserID())) {
            User testUser = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'RC Partner Modify'].Id,
                LastName = 'TestUser1214',
                Email = 'puser11121234@amamama.com',
                Username = 'puser11121234@amamama.com' + System.currentTimeMillis(),
                CompanyName = 'TEST',
                Title = 'title',
                Alias = 'r1112123',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ContactId = testCont.Id
            );
            insert testUser;
            try{
            UserRole reselectedExecutiveUserRole = [select Id, Name, PortalRole from UserRole where PortalAccountId = :newAcc.Id and PortalRole = 'Executive' limit 1];
             testUser.UserRoleId = reselectedExecutiveUserRole.Id;	
            update testUser;
            }
            catch(System.QueryException e)
            {
                
            }
            
            AccountShare objAccountShare  = new AccountShare();
            objAccountShare.AccountId = newAcc.Id;
            objAccountShare.UserOrGroupId = testUser.Id;
            objAccountShare.AccountAccessLevel = 'Edit';
            objAccountShare.RowCause = Schema.AccountShare.RowCause.Manual;
            Database.SaveResult sr = Database.insert(objAccountShare,false);

            newAcc.Partner_ID__c = '111111111111';
            update newAcc;
            
        }
	}

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
	private static void testName3() {
        Schema.DescribeSObjectResult result = Account.SObjectType.getDescribe();
        Map<String, Schema.RecordTypeInfo> rtMapByRecName = result.getRecordTypeInfosByName();
        Id objRecordType = rtMapByRecName.get(AccountTriggerHelperExt.CUSTOMER_ACCOUNT).getRecordTypeId();
        Id partnerAccountRecordType = rtMapByRecName.get(AccountTriggerHelperExt.PARTNER_ACCOUNT).getRecordTypeId();

        Account newAcc = new Account (
            Name = 'New Test Acc',
            Partner_ID__c = '12345612',
            RecordTypeId = partnerAccountRecordType
        );
        insert newAcc;

        newAcc.IsPartner = true;
        update newAcc;

        Contact testCont = new Contact (
            LastName = 'Test1',
            AccountId = newAcc.Id
        );
        insert testCont;

        System.runAs(new user(ID = UserInfo.getUserID())) {
            User testUser = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'RC Partner Modify'].Id,
                LastName = 'TestUser1214',
                Email = 'puser11121234@amamama.com',
                Username = 'puser11121234@amamama.com' + System.currentTimeMillis(),
                CompanyName = 'TEST',
                Title = 'title',
                Alias = 'r1112123',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ContactId = testCont.Id
            );
            insert testUser;
            try{
            UserRole reselectedExecutiveUserRole = [select Id, Name, PortalRole from UserRole where PortalAccountId = :newAcc.Id and PortalRole = 'Executive' limit 1];
           	testUser.UserRoleId = reselectedExecutiveUserRole.Id;
            update testUser; }
            catch(System.QueryException e){
                
			}
            

            newAcc.Partner_ID__c = '111111111111';
            update newAcc;

            AccountUpdateSharingRule.deleteOldSharingRuleForAccount(newAcc.Id, newAcc.Partner_ID__c, partnerAccountRecordType);
        }
	}
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testPartnerIDNullUserCheck(){
        
        
        List<User> rcEsbUser = [Select Id from User where name = 'RCESB' limit 1];
        
        if(!rcEsbUser.isEmpty()){
            
            System.runAs(rcEsbUser.get(0)){
                Account testAccount = new Account();
        testAccount.Name = 'Test123';
        testAccount.SignupType__c = 'TRIAL_30NOCC';
        testAccount.RC_Account_Status__c = 'TRIAL';
        testAccount.SignupPlatform__c = 'WEB';
        testAccount.RC_Service_name__c = 'office123';
        testAccount.RC_Activation_Date__c = null;
        testAccount.Partner_ID__c = '9852';
        insert testAccount;
                
                testAccount.Partner_Id__c = null;
        		update testAccount;
            }
        }
    }

}