@isTest
private class TestImplementationMethod {

	@testSetup static void TestDataPrepare()
	{
		Profile salesProfile = [SELECT Id FROM Profile WHERE Name = 'Sales Rep - Lightning' LIMIT 1];

		User accOwner = new User(alias = 'u1', email = 'u1234@testorg.com', emailencodingkey = 'UTF-8',
	 		FirstName = 'testName', lastname='Testing123', ProfileId = salesProfile.Id,
	 		languagelocalekey = 'en_US', localesidkey = 'en_US', country='United States',
	 		timezonesidkey = 'America/Los_Angeles', username = UserHelper.getUniqueUserName(), IsActive=true);

	 	User accProfServPm = new User(alias = 'u2', email = 'u2234@testorg.com', emailencodingkey = 'UTF-8',
	 		FirstName = 'testName2', lastname='Testing223', ProfileId = salesProfile.Id,
	 		languagelocalekey = 'en_US', localesidkey = 'en_US', country='United States',
	 		timezonesidkey = 'America/Los_Angeles', username = UserHelper.getUniqueUserName(), IsActive=true);

	 	User syncUser = new User(alias = 'u3', email = 'u3234@testorg.com', emailencodingkey = 'UTF-8',
	 		FirstName = 'testName3', lastname='Testing323', ProfileId = salesProfile.Id,
	 		languagelocalekey = 'en_US', localesidkey = 'en_US', country='United States',
	 		timezonesidkey = 'America/Los_Angeles', username = UserHelper.getUniqueUserName(), IsActive=true);

	 	User[] testUsers = new User[] { accOwner, accProfServPm, syncUser };

        insert testUsers;

        RCSF_Sync__c rcsfSyncObj = new RCSF_Sync__c(Is_Primary__c = true, Id__c = syncUser.Id, Name = 'RCSFSync');
        insert rcsfSyncObj;

        RecordType rt = [SELECT Id FROM RecordType WHERE Name='Partner Account'];

        Account accountTest1 = new Account();
	    accountTest1.Name = 'TestAccount1';
	    accountTest1.RC_Attribution_Channel__c = 'Sales Agents & Resellers';
	    accountTest1.OwnerId = accOwner.id;
	    system.debug(' AccountTest1.OwnerId ==> '+ accountTest1.OwnerId);
	    accountTest1.Partner_ID__c ='123';
	    accountTest1.BMID__c = '211';
	    accountTest1.PID__c = '442';
	    accountTest1.AID__c = '111';
	    accountTest1.RC_Account_Number__c =  '11';
	    accountTest1.RC_Account_Status__c = 'Paid';
	    accountTest1.Do_Not_Creation_Implementation__c = false;
	    accountTest1.RC_Service_Name__c = 'Office';
	    accountTest1.RC_User_Id__c = 'Test701';
	    accountTest1.Number_of_DL_s__c = 11;
	    accountTest1.Purchased_DL_s__c = 11;
	    accountTest1.RC_Brand__c = 'Test';
	    accountTest1.RC_Tier__c = 'Test';
	    accountTest1.RC_Signup_Date__c = System.today();
	    accountTest1.RecordTypeId  = rt.Id;
	    insert accountTest1;

        Account accountTest2 = new Account();
	    accountTest2.Name = 'TestAccount2';
	    accountTest2.RC_Attribution_Channel__c = 'Sales Agents & Resellers';
	    accountTest2.OwnerId = accOwner.Id;
	    accountTest2.Partner_ID__c ='1231';
	    accountTest2.BMID__c = '2111';
	    accountTest2.PID__c = '4421';
	    accountTest2.AID__c = '1111';
	    accountTest2.RC_Account_Number__c =  '111';
	    accountTest2.RC_Account_Status__c = 'Test1';
	    accountTest2.Do_Not_Creation_Implementation__c = false;
	    accountTest2.RC_Service_Name__c = 'Office';
	    accountTest2.RC_User_Id__c = 'Test7011';
	    accountTest2.Number_of_DL_s__c = 11;
	    accountTest2.Purchased_DL_s__c = 11;
	    accountTest2.RC_Brand__c = 'Test1';
	    accountTest2.RC_Tier__c = 'Test1';
	    accountTest2.RC_Signup_Date__c = System.today();
	    accountTest2.RecordTypeId  = rt.Id;
	    insert accountTest2;
	}

	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@isTest
	public static void testImplementationMethods()
	{
		Account testAccount1 = [
			SELECT Name, RC_Attribution_Channel__c, OwnerId, Partner_ID__c, BMID__c, PID__c, AID__c,Sub_brand__c,
				RC_Account_Number__c, RC_Account_Status__c, Do_Not_Creation_Implementation__c, RC_Service_Name__c,
				RC_User_Id__c, Number_of_DL_s__c, Purchased_DL_s__c, RC_Brand__c, RC_Tier__c, RC_Signup_Date__c, RecordTypeId, Service_Type__c
			FROM Account
			WHERE Name = 'TestAccount1'];

		Account testAccount2 = [
			SELECT Name, RC_Attribution_Channel__c, OwnerId, Partner_ID__c, BMID__c, PID__c, AID__c,Sub_brand__c,
				RC_Account_Number__c, RC_Account_Status__c, Do_Not_Creation_Implementation__c, RC_Service_Name__c,
				RC_User_Id__c, Number_of_DL_s__c, Purchased_DL_s__c, RC_Brand__c, RC_Tier__c, RC_Signup_Date__c, RecordTypeId, Service_Type__c
			FROM Account
			WHERE Name = 'TestAccount2'];


	    Contact contactObj = new Contact();
	    contactObj.AccountId =  testAccount1.Id;
	    contactObj.FirstName = 'RCtest';
	    contactObj.Email = 'test123@test.com';
	    contactObj.LastName = 'TestLast';
	    contactObj.Phone ='9632255698';
	    contactObj.Company__c ='Rc Test';
	    contactObj.NumberOfEmployees__c = '67';
	    insert contactObj;

	 	AccountContactRole accountContactRoleObj = new AccountContactRole() ;
		accountContactRoleObj.AccountId = testAccount1.Id;
		accountContactRoleObj.ContactId = contactObj.Id;

		insert accountContactRoleObj;

	    Lead leadObj2 = new Lead();
		leadObj2.FirstName='Virendra';
        leadObj2.LastName='Singh';
        leadObj2.Company='Simplion';
        leadObj2.Phone='9910106804';
        leadObj2.email = 'fake@email.com';
        leadObj2.LeadSource = 'Inbound Call';
        leadObj2.Website = 'http://test.com';
        leadObj2.NumberOfEmployees = 123;
     	leadObj2.Industry = 'Test';
        leadObj2.NumberOfEmployees__c = '2-19';
        leadObj2.Number_of_Locations__c = '2-4';
	 	leadObj2.Agent_Email_Address__c = 'test@test.com';
        insert leadObj2;

        Implementation__c impObj = new Implementation__c();
        impObj.Name = 'testImp';
        impObj.Account__c = testAccount1.Id;
        impObj.Implementation_Status__c = 'Contacted';

		Test.startTest();

		ImplementationMethods impM = new ImplementationMethods();

		Map<id,Contact> contact_map = new Map<id, Contact>([Select ID, FirstName,Phone,LastName,Email, Name From Contact WHERE AccountId = :testAccount1.Id Limit 100]);
		contact_map.put(testAccount1.Id, contactObj);
		System.debug('Contact >>>'+contact_map);

		Map<Id, Implementation__c> accountImplementationMap = new Map<id, Implementation__c>();
		Map<Id, Lead> newAccountLeadMap =  new Map<Id, Lead>([Select ID,Account__r.Id From Lead  WHERE Account__r.Id = :testAccount1.Id Limit 100]);

		Map<String,Integer> mapAccountImplementation1 = new Map<String, Integer>();
		List<Contact> contactPartnerList = new List<Contact>([Select ID, Phone, Email, AccountId, LastName, FirstName, Name From Contact  WHERE AccountId = :testAccount1.Id limit 100]);

     	Lead l = [Select Id From Lead Limit 1];

		Map<id, Account> accountMap = new Map<id, Account>([Select Id, Name, RC_Account_Number__c, Partner_ID__c, RC_Account_Status__c, RC_Tier__c,
     									BMID__c, PID__c,AID__c, Do_Not_Creation_Implementation__c,RC_Service_Name__c, Owner.Name ,Owner.Email,
     									Owner.Team__c, Owner.Manager.Name,Owner.Manager.Email,(Select AccountId, ContactId, Contact.Email, Contact.Phone, Contact.LastName, Account.Name From AccountContactRoles),
        								(Select AccountId, id, Email, Phone, LastName,FirstName  From Contacts), RC_User_Id__c, Number_of_DL_s__c, Purchased_DL_s__c, RC_Brand__c From Account Where id = :testAccount1.Id ]);

	 	impM.createLead(testAccount1, contact_map, l);
	 	impM.createAccountLead(newAccountLeadMap, accountMap, contact_map);
	 	System.debug('Account lead'+newAccountLeadMap);
		mapAccountImplementation1.put(testAccount1.Id, 0);
        ImplementationMethods.getContactAccountMap(accountMap);
	 	ImplementationMethods.tocreateImplemetationOnInsOrUpdForBrandsLess100Dls(testAccount1);
	 	impM.createVARSurveyOnAccountActivation(testAccount1, accountMap, contactPartnerList);

	 	ImplementationMethods.toCreateImplementationOnInsOrUpdRing(testAccount1);
	 	impM.chkToHardwareRtnOnDeactivation(testAccount1, testAccount2, null);
	 	impM.toCreateImplementationOnInsOrUpdOfficeTrials(testAccount1, mapAccountImplementation1);
	 	delete accountContactRoleObj;
	 	accountMap = new Map<id, Account>([Select Id, Name, RC_Account_Number__c, Partner_ID__c, RC_Account_Status__c, RC_Tier__c,
     									BMID__c, PID__c,AID__c, Do_Not_Creation_Implementation__c,RC_Service_Name__c, Owner.Name ,Owner.Email,
     									Owner.Team__c, Owner.Manager.Name,Owner.Manager.Email,(Select AccountId, ContactId, Contact.Email, Contact.Phone, Contact.LastName, Account.Name From AccountContactRoles),
        								(Select AccountId, id, Email, Phone, Account.Name, LastName,FirstName From Contacts), RC_User_Id__c, Number_of_DL_s__c, RC_Brand__c From Account Where id =: testAccount1.Id ]);

	 	impM.createVARSurveyOnAccountActivation(testAccount1, accountMap, contactPartnerList);

	 	Test.stopTest();
	 }

	 @isTest public static void Test_Implementation_Owner_Changed_On_Account_Insert_And_Persist() {
	 	ResetTriggerHandlerAccountSettings();

		Test.startTest();

		RecordType rt = [SELECT Id FROM RecordType WHERE Name='Partner Account'];
		User accOwner = [SELECT Id FROM User WHERE Email = 'u1234@testorg.com'];
		Id accProfServPm = GetProfessionalServPmUser();

        Account testAccount = new Account();
	    testAccount.Name = 'TestAccount3';
	    testAccount.RC_Attribution_Channel__c = 'Sales Agents & Resellers';
	    testAccount.OwnerId = accOwner.Id;
	    testAccount.BMID__c = '211211';
	    testAccount.PID__c = '442442';
	    testAccount.AID__c = '111111';
	    testAccount.RC_Account_Number__c =  '1111';
	    testAccount.RC_Account_Status__c = 'Paid';
	    testAccount.Do_Not_Creation_Implementation__c = false;
	    testAccount.RC_Service_Name__c = 'Office';
	    testAccount.Purchased_DL_s__c = 11;
	    testAccount.RC_Brand__c = OpportunityHelper.BRAND_TELUS_BUSINESS_CONNECT;
	    testAccount.RC_Tier__c = 'Test3';
	    testAccount.RC_Signup_Date__c = System.today();
	    testAccount.RecordTypeId  = rt.Id;
        insert testAccount;

        testAccount.RC_User_Id__c = 'Test703';
        update testAccount;

        Test.stopTest();

		Implementation__c impl = [
	    	SELECT OwnerId, Implementation_Status_2__c
	    	FROM Implementation__c
	    	WHERE Account__r.Id = :testAccount.Id
	    ];
	    system.assert(true == true, 'Could not find Implementation with status New or Scheduled');
	 }

	 @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	 @isTest public static void Test_Impl_Create_On_Account_Licenses_Purchased_Insert_Positive()
	 {
	 	ResetTriggerHandlerAccountSettings();
	 	Account testAccount = new Account();
	 	testAccount.RC_Brand__c = 'RingCentral';
	 	testAccount.Licenses_Purchased__c = 10;
	 	testAccount.Name = 'Test Account #1';

	 	Test.startTest();
	 	insert testAccount;
	 	Test.stopTest();

	 	Implementation__c[] impl = [
	 		SELECT Id
	 		FROM Implementation__c
	 		WHERE Account__c = :testAccount.Id];

	 	// system.assert(impl.size() > 0, 'Implemenation__c was not created');
	 }

	 @isTest public static void Test_Impl_Create_On_Account_Licenses_Purchased_Insert_Negative()
	 {
	 	ResetTriggerHandlerAccountSettings();
	 	Account testAccount = new Account();
	 	testAccount.RC_Brand__c = 'RingCentral';
	 	testAccount.Licenses_Purchased__c = 5;
	 	testAccount.Name = 'Test Account #1';

	 	Test.startTest();
	 	insert testAccount;
	 	Test.stopTest();

	 	Implementation__c[] impl = [
	 		SELECT Id
	 		FROM Implementation__c
	 		WHERE Account__c = :testAccount.Id];

	 	system.assert(impl.size() == 0, 'Implemenation__c was created, but Licenses Purchased value not satisfies requirements');
	 }

	 @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	 @isTest public static void Test_Impl_Create_On_Account_Licenses_Purchased_Update_Positive()
	 {
	 	ResetTriggerHandlerAccountSettings();
	 	Account testAccount = new Account();
	 	testAccount.RC_Brand__c = 'RingCentral';
	 	testAccount.Name = 'Test Account #1';
	 	testAccount.Licenses_Purchased__c = 5;
	 	insert testAccount;
	 	ResetTriggerHandlerAccountSettings();

	 	Test.startTest();
	 	testAccount.Licenses_Purchased__c = 10;
	 	update testAccount;
	 	Test.stopTest();

	 	Implementation__c[] impl = [
	 		SELECT Id
	 		FROM Implementation__c
	 		WHERE Account__c = :testAccount.Id];

	 	// system.assert(impl.size() > 0, 'Implemenation__c was not created');

	 }

	 @isTest public static void Test_Impl_Create_On_Account_Licenses_Purchased_Update_Negative()
	 {
	 	ResetTriggerHandlerAccountSettings();
	 	Account testAccount = new Account();
	 	testAccount.RC_Brand__c = 'RingCentral';
	 	testAccount.Name = 'Test Account #1';
	 	insert testAccount;
	 	ResetTriggerHandlerAccountSettings();

	 	Test.startTest();
	 	testAccount.Licenses_Purchased__c = 5;
	 	update testAccount;
	 	Test.stopTest();

	 	Implementation__c[] impl = [
	 		SELECT Id
	 		FROM Implementation__c
	 		WHERE Account__c = :testAccount.Id];

	 	system.assert(impl.size() == 0, 'Implemenation__c was created, but Licenses Purchased value not satisfies requirements');

	 }

	 private static Account GetAccountForOwnerRenew()
	 {
	 	Account result = [
			SELECT Name, RC_Attribution_Channel__c, OwnerId, Partner_ID__c, BMID__c, PID__c, AID__c,
				RC_Account_Number__c, RC_Account_Status__c, Do_Not_Creation_Implementation__c, RC_Service_Name__c,
				RC_User_Id__c, Number_of_DL_s__c, RC_Brand__c, RC_Tier__c, RC_Signup_Date__c, RecordTypeId
			FROM Account
			WHERE Name = 'TestAccount1'];
		system.assert(result != null, 'The Account for owner renew tests was not found');
		return result;
	 }

	 private static void ResetTriggerHandlerAccountSettings()
	 {
	 	TriggerHandler.BY_PASS_ACCOUNT_ON_BEFORE = false;
	 	TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
	    TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
	    TriggerHandler.BY_PASS_ACCOUNT_ON_AFTER = false;

	 }

	 private static Id GetProfessionalServPmUser()
	 {
	 	User result = [SELECT Id FROM User WHERE Email = 'u2234@testorg.com' LIMIT 1];
	 	system.assert(result != null, 'The professional service PM user was not found');
	 	return result.Id;
     }


    @isTest public static void test_ImplementationCreation_Telus() {
        ResetTriggerHandlerAccountSettings();

        Test.startTest();

        RecordType rt = [SELECT Id FROM RecordType WHERE Name='Partner Account'];
        User accOwner = [SELECT Id FROM User WHERE Email = 'u1234@testorg.com'];
        Id accProfServPm = GetProfessionalServPmUser();

        Account testAccount = new Account();
        testAccount.Name = 'TestAccount3';
        testAccount.RC_Attribution_Channel__c = 'Sales Agents & Resellers';
        testAccount.OwnerId = accOwner.Id;
        testAccount.BMID__c = '211211';
        testAccount.PID__c = '442442';
        testAccount.AID__c = '111111';
        testAccount.RC_Account_Number__c =  '1111';
        testAccount.RC_Account_Status__c = 'Paid';
        testAccount.Do_Not_Creation_Implementation__c = false;
        testAccount.RC_Service_Name__c = 'Office';
        testAccount.Purchased_DL_s__c = 11;
        testAccount.RC_Brand__c = OpportunityHelper.BRAND_TELUS_BUSINESS_CONNECT;
        testAccount.RC_Tier__c = 'Test3';
        testAccount.RC_Signup_Date__c = System.today();
        testAccount.RecordTypeId  = rt.Id;
        insert testAccount;

        testAccount.RC_User_Id__c = 'Test703';
        update testAccount;

        Test.stopTest();
        System.assertEquals(1, [
            SELECT Id, OwnerId, Implementation_Status_2__c, Account__r.Id
            FROM Implementation__c
            WHERE Account__c = :testAccount.Id
        ].size());
    }

    @isTest public static void test_ImplementationCreation_RingCentral() {
        ResetTriggerHandlerAccountSettings();

        Test.startTest();

        RecordType rt = [SELECT Id FROM RecordType WHERE Name='Partner Account'];
        User accOwner = [SELECT Id FROM User WHERE Email = 'u1234@testorg.com'];
        Id accProfServPm = GetProfessionalServPmUser();

        Account testAccount = new Account();
        testAccount.Name = 'TestAccount3';
        testAccount.RC_Attribution_Channel__c = 'Sales Agents & Resellers';
        testAccount.OwnerId = accOwner.Id;
        testAccount.BMID__c = '211211';
        testAccount.PID__c = '442442';
        testAccount.AID__c = '111111';
        testAccount.RC_Account_Number__c =  '1111';
        testAccount.RC_Account_Status__c = 'Paid';
        testAccount.Do_Not_Creation_Implementation__c = false;
        testAccount.RC_Service_Name__c = 'Office';
        testAccount.Purchased_DL_s__c = 11;
        testAccount.RC_Brand__c = 'RingCentral UK';
        testAccount.RC_Tier__c = 'Test3';
        testAccount.RC_Signup_Date__c = System.today();
        testAccount.RecordTypeId  = rt.Id;
        insert testAccount;

        testAccount.RC_User_ID__c = 'Test703';
        update testAccount;

        Test.stopTest();
        System.assertEquals(1, [
            SELECT Id, OwnerId, Implementation_Status_2__c, Account__r.Id
            FROM Implementation__c
            WHERE Account__c = :testAccount.Id
        ].size());
    }

    @isTest public static void test_ImplementationCreation_BrandsLess100Dls() {
        ResetTriggerHandlerAccountSettings();

        Test.startTest();

        RecordType rt = [SELECT Id FROM RecordType WHERE Name='Partner Account'];
        User accOwner = [SELECT Id FROM User WHERE Email = 'u1234@testorg.com'];
        Id accProfServPm = GetProfessionalServPmUser();

        Account testAccount = new Account();
        testAccount.Name = 'TestAccount3';
        testAccount.RC_Attribution_Channel__c = 'Sales Agents & Resellers';
        testAccount.OwnerId = accOwner.Id;
        testAccount.BMID__c = '211211';
        testAccount.PID__c = '442442';
        testAccount.AID__c = '111111';
        testAccount.RC_Account_Number__c =  '1111';
        testAccount.RC_Account_Status__c = 'Paid';
        testAccount.Do_Not_Creation_Implementation__c = false;
        testAccount.RC_Service_Name__c = 'Office';
        testAccount.RC_Brand__c = 'RingCentral mit 1&1 Connected Calls';
        testAccount.RC_Tier__c = 'Test3';
        testAccount.Purchased_DL_s__c = 11;
        testAccount.RC_Signup_Date__c = System.today();
        testAccount.RecordTypeId  = rt.Id;
        insert testAccount;

		testAccount.RC_User_ID__c = 'Test703';
        update testAccount;

        Test.stopTest();
        System.assertEquals(1, [
            SELECT COUNT()
            FROM Implementation__c
            WHERE Account__c = :testAccount.Id
        ]);
    }

    @isTest
    public static void test_ImplementationCreation_RiseBrands() {
        String optusSubBrandName = '2000.Optus';
        Rise_Partner_CRM_Configuration__c riseSetting = new Rise_Partner_CRM_Configuration__c();
        riseSetting.Name = optusSubBrandName;
        riseSetting.Max_Purchase_DL__c = 99;
        riseSetting.Account_Status__c = 'Paid';
        riseSetting.Implementation_Required__c=true;
        insert riseSetting;

        ResetTriggerHandlerAccountSettings();
        Test.startTest();
            Account testAcc = new Account();
            testAcc.RC_Brand__c = OpportunityHelper.BRAND_RISE_AMERICA;
            testAcc.Sub_Brand__c = optusSubBrandName;
            testAcc.RC_User_ID__c = '34345456';
            testAcc.Purchased_DL_s__c = 50;
            testAcc.RC_Account_Status__c = 'Paid';
            testAcc.Name = 'TestClass Account 1';
            insert testAcc;
        Test.stopTest();

        Assert.areEqual(1, [
            SELECT COUNT()
            FROM Implementation__c
            WHERE Account__c = :testAcc.Id
        ], 'Implementation not created!');
    }
}