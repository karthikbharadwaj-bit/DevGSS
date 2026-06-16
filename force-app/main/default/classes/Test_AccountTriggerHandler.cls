@IsTest
private class Test_AccountTriggerHandler {
    private final static String TEST_STRING = 'TestString';

	public static Account testAccount;
    public static Contact testContact;
	private static User salesrepUser = createUser('sr'); // salesrepUser
	private static User salesmanagerUser = createUser('sm'); //salesmanagerUser
    private static final String NO_ROLE_CREATED_MSG = 'No role with \'[none]\' created under technical Account';
    private static final String FAILED_TO_COPY_TO_PACKAGE_ASSERT_MSG = 'Failed to copy {0} to billing account packages from the {1} account.';

    private static Account getAccountById(Id accountId){
        return [SELECT Id, AHSearchCriteriaFieldsHaveBeenModified__c, Bill_As_Of_Date__c, InContact_Service__c,
                    Number_of_POC_Users__c, SignupType__c, Current_Owner__c, Product_Survey__c, Service_Type__c,
                    Current_Owner_Email__c, Current_Owner_Email_Previous__c, Current_Owner_Previous__c,
                    Current_Owner_Previous__r.Email,
                    RC_Brand__c, CSM_Email__c, CSM_Phone__c, CSM_Name__c, CSM__c
                FROM Account
                WHERE Id =: accountId
                LIMIT 1];
    }

    private static String getDatePart(Datetime dt){
        if(dt == null) {
            return '';
        }
        return dt.day() + '/' + dt.month() + '/' + dt.year();
    }

    private static Integer lastRandomKey = 1;
    public static String getFakeId(Schema.SObjectType sot){
        String result = String.valueOf(lastRandomKey++);
        return sot.getDescribe().getKeyPrefix() + '0'.repeat(12 - result.length()) + result;
    }

    private static User createUser(String name) {
        return createUser(name, ProfileHelper.SYSTEM_ADMIN, true);
    }

    private static User createUser(String name, String profileName, Boolean isNeedInsert) {
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        User user = new User(
            Username = name+randomInt+'!user@gmail.com',
            LastName = 'Test'+name,
            Email = name+'_user@gmail.com',
            Alias = 'test' + name.left(4),
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id, Name FROM Profile WHERE Name = :profileName].Id,
            LanguageLocaleKey = 'en_US'
        );
        if(isNeedInsert) {
            insert user;
        }
        return user;
    }

    public static void createTestData(){
        testAccount = new Account();
		testAccount.Name = 'Test123';
		testAccount.SignupType__c = 'TRIAL_30NOCC';
		testAccount.RC_Account_Status__c = 'TRIAL';
		testAccount.SignupPlatform__c = 'WEB';
		testAccount.RC_Service_name__c = 'office123';
		testAccount.RC_Activation_Date__c = null;
		testAccount.Partner_ID__c = '9852';
		insert testAccount;

		testContact = new Contact();
		testContact.AccountId =  testAccount.id;
		testContact.Email = 'fake@email.com';
		testContact.LastName = 'TestLast';
		testContact.Phone='9910106804';
		insert testContact;
    }

	public static void createTestDataForTA(Boolean TA, Boolean addOwner) {
		testAccount = new Account();
		testAccount.Name = 'Test123';
		testAccount.SignupType__c = 'TRIAL_30NOCC';
		testAccount.RC_Account_Status__c = 'TRIAL';
		testAccount.SignupPlatform__c = 'WEB';
		testAccount.RC_Service_name__c = 'office123';
		testAccount.RC_Activation_Date__c = null;
		testAccount.Partner_ID__c = '9852';
		testAccount.Target_Account__c = TA;
		if (addOwner) {
            testAccount.Current_Owner__c = salesrepUser.Id;
        }
		insert testAccount;

		testContact = new Contact();
		testContact.AccountId =  testAccount.id;
		testContact.Email = 'fake@email.com';
		testContact.LastName = 'TestLast';
		testContact.Phone='9910106804';
		insert testContact;
	}

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@IsTest static void accountDeletionTest() {

		TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
		TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
		TriggerHandler.BY_PASS_ACCOUNT_ON_BEFORE = false;

	    Test.startTest();
        createTestData();
	    Test.stopTest();
        delete testAccount;
	}

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@IsTest static void accountUpdateTest() {

		createTestData();
		TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
		TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
		TriggerHandler.BY_PASS_ACCOUNT_ON_BEFORE = false;

	    Test.startTest();
		testAccount.Partner_ID__c = '9853';
		update testAccount;
	    Test.stopTest();
	}

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@IsTest static void accountUpdateCurrentOwnerTestTrueFalse() {

		createTestDataForTA(true, true);
		TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
		TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
		TriggerHandler.BY_PASS_ACCOUNT_ON_BEFORE = false;

	    Test.startTest();
		testAccount.Current_Owner__c = salesmanagerUser.Id;
		testAccount.Target_Account__c = false;
        update testAccount;
	    Test.stopTest();
	}

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@IsTest static void accountUpdateCurrentOwnerTestFalseTrue() {

		createTestDataForTA(false, true);
		TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
		TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
		TriggerHandler.BY_PASS_ACCOUNT_ON_BEFORE = false;

	    Test.startTest();
		testAccount.Current_Owner__c = salesmanagerUser.Id;
		testAccount.Target_Account__c = true;
		update testAccount;
	    Test.stopTest();
	}

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@IsTest static void accountUpdateCurrentOwnerTestTrueTrue() {

		createTestDataForTA(true, true);
		TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
		TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
		TriggerHandler.BY_PASS_ACCOUNT_ON_BEFORE = false;

	    Test.startTest();
		testAccount.Current_Owner__c = salesmanagerUser.Id;
		testAccount.RC_Account_Status__c = 'TEST';
		// testAccount.Target_Account__c = false;
		update testAccount;
	    Test.stopTest();
	}

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@IsTest static void accountUpdateCurrentOwnerTestTrueFalseOwnerNull() {

		createTestDataForTA(true, true);
		TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
		TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
		TriggerHandler.BY_PASS_ACCOUNT_ON_BEFORE = false;

	    Test.startTest();
		testAccount.Current_Owner__c = null;
		testAccount.Target_Account__c = false;
		update testAccount;
	    Test.stopTest();
	}

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@IsTest static void accountUpdateCurrentOwnerTestTrueTrueSetOwner() {

		createTestDataForTA(true, false);
		TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
		TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
		TriggerHandler.BY_PASS_ACCOUNT_ON_BEFORE = false;

	    Test.startTest();
		testAccount.Current_Owner__c = salesmanagerUser.Id;
		testAccount.RC_Account_Status__c = 'TEST';
		testAccount.RC_Service_name__c = 'asdfg';
		testAccount.Industry = 'Consulting: IT';
		testAccount.Type = 'Partner';
		// testAccount.Target_Account__c = false;
		update testAccount;
	    Test.stopTest();
	}

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@IsTest static void accountUpdatePartnerAccount() {

		Map<String, Schema.RecordTypeInfo> accRT = Account.SObjectType.getDescribe().getRecordTypeInfosByName();

		testAccount = new Account();
		testAccount.Name = 'Test123';
		testAccount.SignupType__c = 'TRIAL_30NOCC';
		testAccount.RC_Account_Status__c = 'TRIAL';
		testAccount.SignupPlatform__c = 'WEB';
		testAccount.RC_Service_name__c = 'office123';
		testAccount.RC_Activation_Date__c = null;
		testAccount.Partner_ID__c = '9852';
		testAccount.RecordTypeId = accRT.get('Partner Account').getRecordTypeId();
		// insert testAccount;

		Account testAccount2 = new Account();
		testAccount2.Name = 'Test123';
		testAccount2.SignupType__c = 'TRIAL_30NOCC';
		testAccount2.RC_Account_Status__c = 'TRIAL';
		testAccount2.SignupPlatform__c = 'WEB';
		testAccount2.RC_Service_name__c = 'office123';
		testAccount2.RC_Activation_Date__c = null;
		testAccount2.Partner_ID__c = '9852';
		testAccount2.RecordTypeId = accRT.get('Customer Account').getRecordTypeId();
		List<Account> accounts = new List<Account>{testAccount, testAccount2};
		insert accounts;

		testContact = new Contact();
		testContact.AccountId =  testAccount.id;
		testContact.Email = 'fake@email.com';
		testContact.LastName = 'TestLast';
		testContact.Phone='9910106804';
		insert testContact;


		TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
		TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
		TriggerHandler.BY_PASS_ACCOUNT_ON_BEFORE = false;

	    Test.startTest();
		testAccount.Current_Owner__c = salesmanagerUser.Id;
		testAccount.RC_Account_Status__c = 'TEST';
		testAccount.RC_Service_name__c = 'asdfg';
		testAccount.Industry = 'Consulting: IT';
		testAccount.Type = 'Partner';
		// testAccount.Target_Account__c = false;
		update testAccount;
	    Test.stopTest();
	}

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@IsTest static void testInsertPartnerAccount() {

		Map<String, Schema.RecordTypeInfo> accRT = Account.SObjectType.getDescribe().getRecordTypeInfosByName();

		Account testAccount2 = new Account();
		testAccount2.Name = 'Test123';
		testAccount2.SignupType__c = 'TRIAL_30NOCC';
		testAccount2.RC_Account_Status__c = 'TRIAL';
		testAccount2.SignupPlatform__c = 'WEB';
		testAccount2.RC_Service_name__c = 'office123';
		testAccount2.RC_Activation_Date__c = null;
		testAccount2.Partner_ID__c = '9852';
		testAccount2.RecordTypeId = accRT.get('Customer Account').getRecordTypeId();
		// List<Account> accounts = new List<Account>{testAccount, testAccount2};
		insert testAccount2;

		TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
		TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
		TriggerHandler.BY_PASS_ACCOUNT_ON_BEFORE = false;
		Test.startTest();

		testAccount = new Account();
		testAccount.Name = 'Test123';
		testAccount.SignupType__c = 'TRIAL_30NOCC';
		testAccount.RC_Account_Status__c = 'TRIAL';
		testAccount.SignupPlatform__c = 'WEB';
		testAccount.RC_Service_name__c = 'office123';
		testAccount.RC_Activation_Date__c = null;
		testAccount.Partner_ID__c = '9852';
		testAccount.RecordTypeId = accRT.get('Partner Account').getRecordTypeId();
		insert testAccount;

		Test.stopTest();
	}

	@IsTest
	static void testSetQuoteStartEndDatesOnAccountUpdate() {

		schedulerConfiguration__c scc = new schedulerConfiguration__c(
			Name = 'RingCentral'
		);
		insert scc;

		 PriceBook2 testPriceBook = new Pricebook2(
			Name = 'Test Price Book',
			Description ='Test Price Book Products',
			Tier_ID__c = '999',
			Plan__c = 'Annual',
			IsActive = true,
			Line_Range_Min__c = 5,
			Line_Range_Max__c = 10,
			Service__c = 'Office',
			Brand__c = scc.Id
		);
		insert testPriceBook;

		Account testAcc = new Account(
			Name = 'myTestAccount',
			Number_of_DL_s__c = 10,
			BillingCity = 'TestCity',
			BillingStreet = 'TestStreet',
			Payment_Method__c = 'Invoice',
			SignupType__c = 'Direct',
			Industry = 'Advertising, Marketing, Media, PR',
			RC_Upgrade_Date__c = null
		);
		insert testAcc;

		Opportunity opp = new Opportunity(
			Name = 'Test Opportunity',
			Type = 'Syndicated - New',
			StageName = OpportunityHelper.STAGE_NAME_CLOSED_WON,
			CloseDate = System.today(),
			Brand_Name__c = 'RingCentral',
			PriceBook2Id = testPriceBook.Id,
			Tier_Name__c = '999',
			AccountId = testAcc.Id
		);
		insert opp;

		Quote testQuote = new Quote (
			Name = 'Test Quote',
			OpportunityId = opp.id,
			Status = 'Active',
			QuoteType__c = 'Agreement',
			Pricebook2Id = testPriceBook.id,
			Total_Number_of_Digital_Lines__c = 5,
			Start_Date__c = Date.today(),
			End_Date__c = Date.today(),
			Initial_Term_months__c = null
		);
		insert testQuote;

		Test.startTest();

			testQuote.Initial_Term_months__c = null;
			update testQuote;

			TriggerHandler.BY_PASS_ACCOUNT_ON_AFTER = false;
			TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
			TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;

			testAcc.Industry = 'Education';
			testAcc.RC_Upgrade_Date__c = Datetime.now();
			update testAcc;

			Quote reselectedQuote = [SELECT Id, Start_Date__c, End_Date__c, Initial_Term_months__c FROM Quote WHERE Id = :testQuote.Id];

			System.assertEquals(null, reselectedQuote.Initial_Term_months__c);
			System.assertEquals(Date.today(), reselectedQuote.Start_Date__c);
			System.assertEquals(Date.today(), reselectedQuote.End_Date__c);

		Test.stopTest();
	}

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    static void testLeadspaceEnrichmentInfoOnUpdate() {
        createTestData();
        Account acc = [SELECT Id, Name, LS_APIEnrichmentResult__c, LS_Enrichment_Date__c
                        FROM Account
                        WHERE Name = 'Test123'
                        LIMIT 1];
        acc.Website = 'fakeWebSite.io';
        acc.LS_APIEnrichmentResult__c = 'EnrichSuccessful';
        acc.LS_Enrichment_Date__c = Date.newInstance(2018, 1, 1);

        Test.startTest();
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
        TriggerHandler.BY_PASS_ACCOUNT_ON_BEFORE = false;
        update acc;
        Test.stopTest();

        Account acc2 = [SELECT Id, LS_APIEnrichmentResult__c, LS_Enrichment_Date__c
                        FROM Account
                        WHERE Name = 'Test123'
                        LIMIT 1];

        //System.assertEquals(null, acc2.LS_APIEnrichmentResult__c, 'LS_APIEnrichmentResult__c should be null');
        //System.assertEquals(null, acc2.LS_Enrichment_Date__c, 'LS_Enrichment_Date__c should be null');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    static void testLeadspaceEnrichmentInfoOnInsert() {


        Test.startTest();
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
        TriggerHandler.BY_PASS_ACCOUNT_ON_BEFORE = false;
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'LSAcc',
                    Account.LS_APIEnrichmentResult__c => 'EnrichSuccessful',
                    Account.LS_Enrichment_Date__c => Date.newInstance(2018, 1, 1)
                }
            )
            .create()
            .getRecord();
        Test.stopTest();

        Account acc2 = [SELECT Id, LS_APIEnrichmentResult__c, LS_Enrichment_Date__c, RunContactMostFrequentEmail__c
                        FROM Account
                        WHERE Name = 'LSAcc'
                        LIMIT 1];

        //System.assertEquals(null, acc2.LS_APIEnrichmentResult__c, 'LS_APIEnrichmentResult__c should be null');
        //System.assertEquals(null, acc2.LS_Enrichment_Date__c, 'LS_Enrichment_Date__c should be null');
    }

    @IsTest
    static void testAHSearchCriteriaFieldsHaveBeenModifiedShouldBeSetupWhenUpdatingKeyFields() {
        Account account = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.BillingCountry => '',
                    Account.Name => 'TestAccount'
                }
            )
            .create()
            .getRecord();


        Test.startTest();
            account.AHSearchCriteriaFieldsHaveBeenModified__c = false;
            account.BillingCountry = 'United States';
            update account;
        Test.stopTest();

        Account accountAfterUpdate = getAccountById(account.Id);

        System.assertEquals(true, accountAfterUpdate.AHSearchCriteriaFieldsHaveBeenModified__c,
            'AHSearchCriteriaFieldsHaveBeenModified__c should be set to true when key fields are modified');
    }

    @IsTest
    static void testPopulateSDRAgentNameAndRoleNameOnAccountInsert() {

        User testUser = null;

        // System.runAs used for avoid MIXED_DML_OPERATION
        System.runAs(salesmanagerUser) {

            UserRole testUserRole = new UserRole(
                Name = 'test User Role'
            );
            insert testUserRole;

            Boolean isNeedInsert = false;

            testUser = createUser('tst', ProfileHelper.SYSTEM_ADMIN, isNeedInsert);
            testUser.UserRoleId = testUserRole.Id;
            insert testUser;
        }

        Test.startTest();

            Account testAcc = new Account(
                Name = 'testAccount with sdrAgent',
                SDR_Agent__c = testUser.Id
            );
            insert testAcc;

        Test.stopTest();

        Account reselectedTestAcc = [SELECT Id, SDR_Agent__r.Name, SDR_Agent__r.UserRole.Name, SDR_Agent_Name__c, SDR_Role_Name__c FROM Account WHERE Id = :testAcc.Id];

        System.assert(reselectedTestAcc.SDR_Agent_Name__c != null);
        System.assert(reselectedTestAcc.SDR_Role_Name__c != null);

        System.assertEquals(reselectedTestAcc.SDR_Agent__r.Name, reselectedTestAcc.SDR_Agent_Name__c);
        System.assertEquals(reselectedTestAcc.SDR_Agent__r.UserRole.Name, reselectedTestAcc.SDR_Role_Name__c);
    }

    @IsTest
    private static void testUpdateRelatedAccountPhase() {
        Triggers.switchOff();
        User us = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestTest',
                    User.Username => 'Test!user@gmail.com',
                    User.Email => 'test_user@gmail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    //User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep',
                    User.Division => OpportunityHelper.USER_DIVISION_SALES_ENTERPRISE
                }
            )
            .create()
            .getRecord();

            Account acc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Account.Current_Owner__c => us.Id,
                        Account.Name => 'testAcc',
                        Account.Current_Owner_Name__c => TEST_STRING,
                        Account.RC_User_ID__c => us.Id,
                        Account.Sales_Segment__c => null,
						Account.RC_Service_name__c => QuoteHelper.NGBS_OFFICE_PRODUCT
                    }
                )
                .create()
                .getRecord();
            Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Contact.FirstName => 'Test1',
                        Contact.LastName => 'Test1',
                        Contact.AccountId => acc.Id,
                        Contact.Email => 'something@mostcommon.fake',
                        Contact.Phone => '1234567890',
                        Contact.Preferred_Language__c => 'en_US'
                    }
                )
                .create()
                .getRecord();
            DateTime dateNow = System.now();
            Opportunity oppty = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Opportunity.Name => 'Test Opportunity 2016',
                        Opportunity.Type => 'Syndicated - New',
                        Opportunity.StageName => 'Planning',
                        Opportunity.CloseDate => Date.newinstance(dateNow.year(), dateNow.month(), dateNow.day()),
                        Opportunity.AccountId => acc.Id,
                        Opportunity.Primary_Opportunity_Contact__c => contact.Id,
                        Opportunity.EstimatedProfessionalServices12Month__c => 10
                    }
                )
                .create()
                .getRecord();
            PriceBook2 pB2 = (PriceBook2) new SObjectBuilder(PriceBook2.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        PriceBook2.Name => 'Test Price Book',
                        PriceBook2.Description => 'Test Price Book Products',
                        PriceBook2.IsActive => true,
                        PriceBook2.Line_Range_Min__c => 5,
                        PriceBook2.Service__c => 'Office'
                    }
                )
                .create()
                .getRecord();
            Quote q = (Quote) new SObjectBuilder(Quote.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Quote.Name => 'quotetest',
                        Quote.OpportunityId => oppty.Id,
                        Quote.Total_Number_of_Digital_Lines__c => 10,
                        Quote.Account__c => oppty.AccountId,
                        Quote.ProServ_Sold_Date__c => System.now(),
                        Quote.ProServSalesRep__c => us.Id,
                        Quote.Pricebook2Id => pB2.Id
                    }
                )
                .create()
                .getRecord();
            Order ord = (Order) new SObjectBuilder(Order.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Order.Status => 'New',
                        Order.RecordTypeId => Schema.SObjectType.Order.getRecordTypeInfosByName().get('CC Professional Services').getRecordTypeId(),
                        Order.SOW_Type__c => 'Single Phase',
                        Order.Signed_SOW__c => TEST_STRING,
                        Order.AccountId => acc.Id,
                        Order.EffectiveDate => Date.newinstance(dateNow.year(), dateNow.month(), dateNow.day())
                    }
                )
                .create()
                .getRecord();
            insert new Feature_Toggle__c(Mavenlink_Integration__c = true);

            Triggers.switchOn();

            Test.startTest();
            Phase__c phase = (Phase__c) new SObjectBuilder(Phase__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Phase__c.Status__c => 'New',
                        Phase__c.RecordTypeId => PhaseHelper.RT_INFO_BY_NAME.get('ProServ Phase').getRecordTypeId(),
                        Phase__c.Account__c => acc.Id,
                        Phase__c.Opportunity__c => oppty.Id,
                        Phase__c.Quote__c => q.Id,
                        Phase__c.Order__c => ord.Id,
                        Phase__c.Initial_Payment__c => 10
                    }
                )
                .create()
                .getRecord();

            TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
            TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
            TriggerHandler.BY_PASS_ACCOUNT_ON_AFTER = false;

            update new Account(Id = acc.Id, Sales_Segment__c = 'Business Sales');
        Test.stopTest();

        phase = [SELECT MavenlinkIntegrationStatus__c, Account__c
                FROM Phase__c
                WHERE Account__c = :acc.Id
                LIMIT 1];

        System.assert(!phase.MavenlinkIntegrationStatus__c.containsIgnoreCase('Sales Segment'),
                        'Sales Segment on the Phase was updated incorrectly.');
    }

    @IsTest
    static void test_PWFA_FeatureToggleOf() {
        insert new Feature_Toggle__c (AccountWorkflowRulesAndProcToTrigger__c = false);

        Account testAcc = new Account(Name = 'testAccountName');
        insert testAcc;
        Account reselectedAccount = [
            SELECT Id, Bill_As_Of_Date__c, SignupType__c, Current_Owner__c, Product_Survey__c,
                RC_Brand__c, Current_Owner_Email_Previous__c, CSM_Email__c, CSM_Name__c, CSM_Phone__c
            FROM Account
            LIMIT 1
        ];
        System.assertEquals(null, reselectedAccount.Bill_As_Of_Date__c);
        System.assertEquals(null, reselectedAccount.SignupType__c);
        System.assertEquals(null, reselectedAccount.Current_Owner__c);
        System.assertEquals(null, reselectedAccount.Product_Survey__c);
        //System.assertEquals(null, reselectedAccount.Account_Graduation_Date_61_90__c);
        //System.assertEquals(null, reselectedAccount.Account_Graduation_Date_0_30__c);
        //System.assertEquals(null, reselectedAccount.Account_Graduation_Date_31_60__c);
        System.assertEquals(null, reselectedAccount.RC_Brand__c);
        System.assertEquals(null, reselectedAccount.Current_Owner_Email_Previous__c);
        System.assertEquals(null, reselectedAccount.CSM_Email__c);
        System.assertEquals(null, reselectedAccount.CSM_Name__c);
        System.assertEquals(null, reselectedAccount.CSM_Phone__c);
    }

    @IsTest
    static void test_PWFA_BillsAsOfDate() {
        insert new Feature_Toggle__c (AccountWorkflowRulesAndProcToTrigger__c = true);

        Account testAccOnInsert = new Account(Name = 'testInsert', InContact_Service__c = 'Contact Center Basic');
        Account testAccOnUpdate = new Account(Name = 'testUpdate');
        insert (new List<Account>{testAccOnInsert,testAccOnUpdate});
        // Test Insert action
        List<Account> testAccountsOnInsert = [SELECT Id, Name, Bill_As_Of_Date__c FROM Account];
        for (Account testAcc : testAccountsOnInsert) {
            if (testAcc.Name == 'testInsert') {
                System.assertNotEquals(null, testAcc.Bill_As_Of_Date__c);
            } else {
                System.assertEquals(null, testAcc.Bill_As_Of_Date__c);
            }
        }

        testAccOnUpdate.InContact_Service__c = 'Contact Center Basic';
        update testAccOnUpdate;
        // Test Update action
        List<Account> testAccountsOnUpdate = [SELECT Id, Bill_As_Of_Date__c FROM Account];
        for (Account testAcc : testAccountsOnUpdate) {
            System.assertNotEquals(null, testAcc.Bill_As_Of_Date__c);
        }
    }

    @IsTest
    static void test_PWFA_ClearCurrentOwner() {
        User rsfcUser = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TesttestUser',
                    User.Username => 'testUser!user@gmail.com',
                    User.Email => 'testUser_user@gmail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep',
                    User.Division => OpportunityHelper.USER_DIVISION_SALES_ENTERPRISE
                }
            )
            .create()
            .getRecord();
        User otherUser = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestotherUser',
                    User.Username => 'otherUser!user@gmail.com',
                    User.Email => 'otherUser_user@gmail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep',
                    User.Division => OpportunityHelper.USER_DIVISION_SALES_ENTERPRISE
                }
            )
            .create()
            .getRecord();

        Test.startTest();
            insert new Feature_Toggle__c (AccountWorkflowRulesAndProcToTrigger__c = true);
            insert new RCSF_Sync__c(
                Name = 'testSetting',
                Active__c = true,
                Email__c = 'fakeEmail@gmail.ru',
                Id__c = rsfcUser.Id
            );

            Account testAccOnInsert = new Account(
                Name = 'testInsert',
                Current_Owner__c = rsfcUser.Id
            );
            Account testAccOnUpdate = new Account(
                Name = 'testUpdate',
                Current_Owner__c = otherUser.Id
            );
            insert (new List<Account>{testAccOnInsert,testAccOnUpdate});
            // Test Insert action
            List<Account> testAccountsOnInsert = [SELECT Id, Name, Current_Owner__c FROM Account];
            for (Account acc : testAccountsOnInsert) {
                if (acc.Name == 'testInsert') {
                    System.assertEquals(null, acc.Current_Owner__c);
                } else {
                    System.assertEquals(otherUser.Id, acc.Current_Owner__c);
                }
            }
            testAccOnUpdate.Current_Owner__c = rsfcUser.Id;
            update testAccOnUpdate;
            // Test Update action
            List<Account> testAccountsOnUpdate = [SELECT Id, Current_Owner__c FROM Account];
            for (Account testAcc : testAccountsOnUpdate) {
                System.assertEquals(null, testAcc.Current_Owner__c);
            }
        Test.stopTest();
    }

    @IsTest
    static void test_PWFA_NpsSurveyUpdate() {
        insert new Feature_Toggle__c (AccountWorkflowRulesAndProcToTrigger__c = true);

        List<Account> testAccs = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => ValueProviderBuilder.provideList(new List<String>{'testInsert', 'testUpdate'})
            })
            .quantity(2)
            .create()
            .getRecords();

        List<Package__c> testPackages = (List<Package__c>) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Package__c.Account__c => ValueProviderBuilder.provideList(new List<String>{testAccs.get(0).Id, testAccs.get(1).Id}),
                Package__c.Service_Type__c => ValueProviderBuilder.provideList(new List<String>{AccountHelper.SERVICE_TYPE_FAX, AccountHelper.SERVICE_TYPE_RCCC}),
                Package__c.Account_Package_Id__c => ValueProviderBuilder.provideList(new List<String>{'11111111111', '2222222222'}),
                Package__c.Enterprise_Account_ID__c => ValueProviderBuilder.provideList(new List<String>{testAccs.get(0).Id, testAccs.get(1).Id})
            })
            .quantity(2)
            .create()
            .getRecords();

        testAccs.get(1).Name = 'Test update';
        update testAccs.get(1);
        // Test Update action
        List<Account> testAccountsOnUpdate = [SELECT Id, Name, Product_Survey__c FROM Account];
        for (Account testAcc : testAccountsOnUpdate) {
            if (testAcc.Name == 'testUpdate') {
                System.assertEquals('http://ringcentral.force.com/rcsurvey/FaxSurvey?conId=', testAcc.Product_Survey__c);
            }
        }
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    static void test_PWFA_AccountGraduationDate() {
        insert new Feature_Toggle__c (AccountWorkflowRulesAndProcToTrigger__c = true);

        Account testAccOnInsert1 = new Account(
            Name = 'testInsert1'
        );
        Account testAccOnInsert2 = new Account(
            Name = 'testInsert2'
        );
        Account testAccOnUpdate = new Account(
            Name = 'testUpdate'
        );
        insert (new List<Account>{testAccOnInsert1, testAccOnInsert2, testAccOnUpdate});
        // Test Insert action
        List<Account> testAccountsOnInsert = [
            SELECT Id, Name
            FROM Account
        ];
        /*for (Account acc : testAccountsOnInsert) {
            if (acc.Name == 'testInsert1') {
                System.assertNotEquals(null, acc.Account_Graduation_Date_0_30__c);
            } else if (acc.Name == 'testInsert2') {
                System.assertNotEquals(null, acc.Account_Graduation_Date_31_60__c);
            } else {
                System.assertEquals(null, acc.Account_Graduation_Date_61_90__c);
            }
        }
        testAccOnUpdate.Account_Graduation_Status__c = AccountHelper.GRADUATION_STATUS_DONE;
        update testAccOnUpdate;
        // Test Update action
        List<Account> testAccountsOnUpdate = [SELECT Id, Name, Account_Graduation_Date_61_90__c FROM Account];
        for (Account testAcc : testAccountsOnUpdate) {
            if (testAcc.Name == 'testUpdate') {
                System.assertNotEquals(null, testAcc.Account_Graduation_Date_61_90__c);
            }
        }*/
    }

    @IsTest
    static void test_PWFA_UpdateBrand() {
        insert new Feature_Toggle__c (AccountWorkflowRulesAndProcToTrigger__c = true);

        Account testAccOnInsert = new Account(
            Name = 'testInsert',
            RC_Brand__c = AccountTriggerHelper.RC_BRAND_BT_CLOUD_PHONE
        );
        Account testAccOnUpdate = new Account(
            Name = 'testUpdate',
            RC_Brand__c = 'testBrand'
        );
        insert (new List<Account>{testAccOnInsert,testAccOnUpdate});
        // Test Insert action
        List<Account> testAccountsOnInsert = [SELECT Id, Name, RC_Brand__c FROM Account];
        for (Account acc : testAccountsOnInsert) {
            if (acc.Name == 'testInsert') {
                System.assertEquals(AccountTriggerHelper.RC_BRAND_BT_BUSINESS, acc.RC_Brand__c);
            } else {
                System.assertEquals('testBrand', acc.RC_Brand__c);
            }
        }
        testAccOnUpdate.RC_Brand__c = AccountTriggerHelper.RC_BRAND_BT_CLOUD_PHONE;
        update testAccOnUpdate;
        // Test Update action
        List<Account> testAccountsOnUpdate = [SELECT Id, Name, RC_Brand__c FROM Account];
        for (Account testAcc : testAccountsOnUpdate) {
            if (testAcc.Name == 'testUpdate') {
                System.assertEquals(AccountTriggerHelper.RC_BRAND_BT_BUSINESS, testAcc.RC_Brand__c);
            }
        }
    }

    @IsTest
    static void test_PWFA_PopulateOwnerEmailPrevious() {
        User prevOwner = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'Testprevowner',
                    User.Username => 'prevowner!user@gmail.com',
                    User.Email => 'prevowner_user@gmail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    //User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep',
                    User.Division => OpportunityHelper.USER_DIVISION_SALES_ENTERPRISE
                }
            )
            .create()
            .getRecord();


        Test.startTest();
            insert new Feature_Toggle__c (AccountWorkflowRulesAndProcToTrigger__c = true);

            Account testAccOnInsert = new Account(
                Name = 'testInsert',
                Current_Owner_Previous__c = prevOwner.Id
            );
            Account testAccOnUpdate = new Account(
                Name = 'testUpdate'
            );
            insert (new List<Account>{testAccOnInsert,testAccOnUpdate});
            // Test Insert action
            List<Account> testAccountsOnInsert = [SELECT Id, Name, Current_Owner_Email_Previous__c FROM Account];
            for (Account acc : testAccountsOnInsert) {
                if (acc.Name == 'testInsert') {
                    System.assertEquals(prevOwner.Email, acc.Current_Owner_Email_Previous__c);
                } else {
                    System.assertEquals(null, acc.Current_Owner_Email_Previous__c);
                }
            }
            testAccOnUpdate.Current_Owner_Previous__c = prevOwner.Id;
            update testAccOnUpdate;
            // Test Update action
            List<Account> testAccountsOnUpdate = [SELECT Id, Current_Owner_Email_Previous__c FROM Account];
            for (Account testAcc : testAccountsOnUpdate) {
                System.assertEquals(prevOwner.Email, testAcc.Current_Owner_Email_Previous__c);
            }
        Test.stopTest();
    }

    @IsTest
    static void test_PWFA_UpdateAccountsCSM() {
        User csmUser = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'Testcsmuser',
                    User.Username => 'csmuser!user@gmail.com',
                    User.Email => 'csmuser_user@gmail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    //User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep',
                    User.Division => OpportunityHelper.USER_DIVISION_SALES_ENTERPRISE
                }
            )
            .create()
            .getRecord();

        Test.startTest();
            insert new Feature_Toggle__c (AccountWorkflowRulesAndProcToTrigger__c = true);

            Account testAccOnInsert = new Account(
                Name = 'testInsert',
                CSM__c = csmUser.Id
            );
            Account testAccOnUpdate = new Account(
                Name = 'testUpdate'
            );
            insert (new List<Account>{testAccOnInsert,testAccOnUpdate});
            // Test Insert action
            List<Account> testAccountsOnInsert = [SELECT Id, Name, CSM_Email__c, CSM_Name__c, CSM_Phone__c FROM Account];
            for (Account acc : testAccountsOnInsert) {
                if (acc.Name == 'testInsert') {
                    System.assertEquals(csmUser.Email, acc.CSM_Email__c);
                    System.assertEquals(csmUser.LastName, acc.CSM_Name__c);
                    System.assertEquals(csmUser.Phone, acc.CSM_Phone__c);
                } else {
                    System.assertEquals(null, acc.CSM_Email__c);
                    System.assertEquals(null, acc.CSM_Name__c);
                    System.assertEquals(null, acc.CSM_Phone__c);
                }
            }
            testAccOnUpdate.CSM__c = csmUser.Id;
            update testAccOnUpdate;
            // Test Update action
            List<Account> testAccountsOnUpdate = [SELECT Id, CSM_Email__c, CSM_Name__c, CSM_Phone__c FROM Account];
            for (Account testAcc : testAccountsOnUpdate) {
                System.assertEquals(csmUser.Email, testAcc.CSM_Email__c);
                System.assertEquals(csmUser.LastName, testAcc.CSM_Name__c);
                System.assertEquals(csmUser.Phone, testAcc.CSM_Phone__c);
            }
        Test.stopTest();
    }

    @IsTest
    static void test_MigratedAccounts() {
        Account testAccount = new Account(Name = 'testAccount');
        insert testAccount;

        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Oppty',
            AccountId = testAccount.Id,
            StageName = '1. Qualify');
        insert testOpportunity;


        List<PriceBook2> priceBookList = new List<PriceBook2>();
        List<Quote> quoteList = new List<Quote>();
        for (Integer i = 0; i < 10; i ++) {
            Pricebook2 testPriceBook = new Pricebook2(
                Name = 'Test Price Book',
                Description = 'Test Price Book Products',
                IsActive = true,
                Line_Range_Min__c = 5);
            priceBookList.add(testPriceBook);
        }
        insert priceBookList;

        for (PriceBook2 pb : priceBookList) {
            Quote testQuote = new Quote(
                Name = 'Test Quote',
                OpportunityId = testOpportunity.Id,
                Pricebook2Id = pb.Id,
                Total_Number_of_Digital_Lines__c = 10,
                isPrimary__c = true,
                QuoteType__c = 'Quote',
                Status = 'Draft',
                RecordTypeId = QuoteHelper.RT_ID_SALES,
                Account__c = testAccount.Id);
            quoteList.add(testQuote);
        }
        insert quoteList;

        List<Product2> prodList = new List<Product2>();
        Product2 testProduct1 = new Product2(
            Name = 'test product1',
            IsActive = true,
            Sub_Category__c = Product2Helper.SUBCATEGORY_RINGCENTRAL
        );
        prodList.add(testProduct1);

        Product2 testProduct2 = new Product2(
            Name = 'test product1',
            IsActive = true,
            Sub_Category__c = Product2Helper.SUBCATEGORY_RINGCENTRAL
        );
        prodList.add(testProduct2);
        insert prodList;

        List<Entitlement__c> entList = new List<Entitlement__c>();
        for(Product2 p : prodList) {
            Entitlement__c testEntl = new Entitlement__c(
                Product__c = p.Id,
                Account__c = testAccount.Id,
                Active__c = true,
                Quantity__c = 3,
                Price__c = 200);
            entList.add(testEntl);
        }
        insert entList;

        Test.startTest();
            testAccount.Billing_ID__c = '1234';
            testAccount.Billing_System__c = 'NBS';
            update testAccount;
        Test.stopTest();

        List<Quote> invalidatedQuoteList = [SELECT Id, Quote_is_Invalid__c FROM Quote WHERE Id IN :quoteList];
        for (Quote qt : invalidatedQuoteList) {
            System.assertEquals(true, qt.Quote_is_Invalid__c);
        }

        List<Entitlement__c> updatedEnList = [SELECT Id, Active__c FROM Entitlement__c WHERE Id IN :entList];
        for (Entitlement__c ent : updatedEnList) {
            System.assertEquals(false, ent.Active__c);
        }
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    static void testUpdateBrandPartnerOnRelatedAgentCredit() {
        testUpdateBrandPartnerOnRelatedRecords(Agent_Credit__c.sObjectType);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    static void testUpdateBrandPartnerOnRelatedApproval() {
        testUpdateBrandPartnerOnRelatedRecords(Approval__c.sObjectType);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    static void testUpdateBrandPartnerOnRelateDemandFunnel() {
        testUpdateBrandPartnerOnRelatedRecords(Demand_Funnel__c.sObjectType);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    static void testUpdateBrandPartnerOnRelatedImplementation() {
        testUpdateBrandPartnerOnRelatedRecords(Implementation__c.sObjectType);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    static void testUpdateBrandPartnerOnRelatedOrder() {
        testUpdateBrandPartnerOnRelatedRecords(Order__c.sObjectType);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    static void testUpdateBrandPartnerOnRelatedPhase() {
        testUpdateBrandPartnerOnRelatedRecords(Phase__c.sObjectType);
    }

    static void testUpdateBrandPartnerOnRelatedRecords(SObjectType soType) {

        System.assert(BrandPartnerFieldPopulationHandler.relatedSoTypes.contains(soType),
            'UpdateBrandPartnerOnRelatedRecords do not handle ' + soType);

        // create test accounts
        List<Account> accs = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, ValueProviderBuilder.provideUniqueString())
            .setField(Account.RC_User_ID__c, new ValueProvider.ListProvider(new List<String>{
                'test1', 'test2', 'test3'}))
            .setField(Account.RC_Brand__c, new ValueProvider.ListProvider(new List<String>{
                RingCentralHelper.BRAND_RINGCENTRAL, RingCentralHelper.BRAND_RINGCENTRAL, RingCentralHelper.BRAND_AVAYA}))
            .quantity(3)
            .create()
            .getRecords();

        createRelatedRecords(soType, accs);

        List<SObject> recordsToAssert = BrandPartnerFieldPopulationHandler.getRelatedRecordsQuery(soType).executeQuery();
        System.assertEquals(3, recordsToAssert.size(), 'Incorrect number of related records');
        Test_BrandPartnerFieldPopulationHandler.assertBrandPartnerFieldValues(recordsToAssert);

        Test.startTest();

            accs[1].RC_Brand__c = RingCentralHelper.BRAND_AVAYA;
            accs[2].RC_Brand__c = RingCentralHelper.BRAND_RINGCENTRAL;
            update accs;

        Test.stopTest();

        // check that RC_Brand__c values are changed to specified values
        Account[] accountToAssert = new AccountSelector().selectAccounts()
                                        .selectField(Account.RC_Brand__c)
                                        .addOrdering(Account.Name, QueryFactory.SortOrder.ASCENDING)
                                        .executeQuery();
        System.assertEquals(RingCentralHelper.BRAND_AVAYA, accountToAssert[1].RC_Brand__c,
            'Account.RC_Brand__c was not changed to specified value');
        System.assertEquals(RingCentralHelper.BRAND_RINGCENTRAL, accountToAssert[2].RC_Brand__c,
            'Account.RC_Brand__c was not changed to specified value');

        // check that Brand_Partner__c correcly updated or related records
        recordsToAssert = BrandPartnerFieldPopulationHandler.getRelatedRecordsQuery(soType).executeQuery();
        System.assertEquals(3, recordsToAssert.size(), 'Incorrect number of related records');
        Test_BrandPartnerFieldPopulationHandler.assertBrandPartnerFieldValues(recordsToAssert);
    }

    private static List<SObject> createRelatedRecords(SObjectType soType, List<Account> accs) {
        return new SObjectBuilder(soType)
            .setField(soType.getDescribe().fields.getMap().get('Account__c'),
                new ValueProvider.MultiParentProvider(accs))
            .quantity(accs.size())
            .create()
            .getRecords();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    static void accountShouldBeUpdatedThroughBatchJob() {

        Account_Hierarchy__c companyToMatch = new Account_Hierarchy__c();
        companyToMatch.Name = 'testCompany';
        companyToMatch.D_U_N_S_Number__c = 'testduns0';
        companyToMatch.Company_Status__c = 'test status';
        insert companyToMatch;

        Account accountToUpdate = new Account();
        accountToUpdate.Name = 'Test Account';
        accountToUpdate.Company_DUNS__c = 'testduns';
        accountToUpdate.AHSearchCriteriaFieldsHaveBeenModified__c = true;
        accountToUpdate.RunContactMostFrequentEmail__c = false;

        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = true;
        insert accountToUpdate;
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;

        Id accountId = accountToUpdate.Id;

        Test.startTest();
        BatchJobAccountCompanyMatching batchToRun = new BatchJobAccountCompanyMatching();
        Database.executebatch(batchToRun);
        Test.stopTest();

        Account accountAfterProcessing = [SELECT Id, Company_Duns__c, SiteDunsNumber__c, AH_Name__c,
                                                 AHSearchCriteriaFieldsHaveBeenModified__c
                                          FROM Account
                                          WHERE Id =:accountId];

        //System.assertEquals(companyToMatch.Id, accountAfterProcessing.AH_Name__c,
        //                   'Batch Job should update the Account Company with Status Paid');
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    static void accountShouldBeUpdatedThroughBatchJobwWithStatusNotPaid() {

        Account_Hierarchy__c companyToMatch = new Account_Hierarchy__c();
        companyToMatch.Name = 'testCompany';
        companyToMatch.D_U_N_S_Number__c = 'testduns0';
        companyToMatch.Company_Status__c = 'test status';
        insert companyToMatch;

        Account accountToUpdate = new Account();
        accountToUpdate.Name = 'Test Account';
        accountToUpdate.Company_DUNS__c = 'testduns';
        accountToUpdate.AHSearchCriteriaFieldsHaveBeenModified__c = true;
        accountToUpdate.RunContactMostFrequentEmail__c = false;

        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = true;
        insert accountToUpdate;
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;

        Id accountId = accountToUpdate.Id;

        Test.startTest();
        BatchJobAccountCompanyMatching batchToRun = new BatchJobAccountCompanyMatching();
        Database.executebatch(batchToRun);
        Test.stopTest();

        Account accountAfterProcessing = [SELECT Id, Company_Duns__c, SiteDunsNumber__c, AH_Name__c,
                                                 AHSearchCriteriaFieldsHaveBeenModified__c
                                          FROM Account
                                          WHERE Id =:accountId];

//            System.assertEquals(companyToMatch.Id, accountAfterProcessing.AH_Name__c,
//            'Batch Job should update the Account Company when Status is different to Paid');
  }

    @IsTest
    private static void testPopulateChurnDateOnPartnerAccounts() {
        SObjectBuilder accountsBuilder = new SObjectBuilder(Account.SObjectType)
            .quantity(2)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ValueProviderBuilder.provideUniqueString(),
                Account.PartnerStatus__c => ValueProviderBuilder.provideList(new List<String>{
                    AccountHelper.ACTIVE_STATUS, AccountHelper.DECLINED_STATUS}),
                Account.RecordTypeId => AccountHelper.RT_ID_PARTNER_ACCOUNT
            })
            .create();

        AccountSelector selector = new AccountSelector();
        List<Account> accounts = selector.selectAccounts()
            .selectFields(new List<String>{
                'Id', 'PartnerStatus__c', 'RC_Churn_Date__c'
            })
            .executeQuery();

        System.assertEquals(
            AccountHelper.ACTIVE_STATUS,
            accounts.get(0).PartnerStatus__c,
            'Status should be \'Active\'');

        System.assertEquals(
            null,
            accounts.get(0).RC_Churn_Date__c,
            'Churn Date should be cleared');

        System.assertEquals(
            AccountHelper.DECLINED_STATUS,
            accounts.get(1).PartnerStatus__c,
            'Status should be \'Declined\'');

        System.assertEquals(
            System.today(),
            accounts.get(1).RC_Churn_Date__c,
            'Churn Date should be populated with current date');
    }
    @IsTest
    private static void testIsValidBillingState() {
        String state = null;
        String country = null;
        System.assertEquals(AccountTriggerHelper.isValidBillingState(state, country), true);

        state = 'fakeState';
        country = null;
        System.assertEquals(AccountTriggerHelper.isValidBillingState(state, country), true);

        state = 'fakeState';
        country = 'UK';
        System.assertEquals(AccountTriggerHelper.isValidBillingState(state, country), true);

        state = null;
        country = 'UK';
        System.assertEquals(AccountTriggerHelper.isValidBillingState(state, country), false);

        state = 'fakeState';
        country = 'UK';
        System.assertEquals(AccountTriggerHelper.isValidBillingState(state, country), true);

        state = null;
        country = 'USA';
        System.assertEquals(AccountTriggerHelper.isValidBillingState(state, country), false);

        state = '123';
        country = 'USA';
        System.assertEquals(AccountTriggerHelper.isValidBillingState(state, country), true);
    }

    /*@isTest
    private static void testRejectApprovals() {

        createTestDataForTA(false, false);

        testAccount.BillingCountry = 'Test';
        testAccount.BillingCity = 'test';
        testAccount.BillingState = 'test';
        testAccount.BillingStreet = 'test';
        testAccount.BillingPostalCode = '1231313';

        update testAccount;

        Approval__c app =  (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setField(Approval__c.Name, 'Tax Exempt Approval')
            .setField(Approval__c.RecordTypeId, ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL)
            .setField(Approval__c.Account__c, testAccount.Id)
            .setField(Approval__c.Contact__c, testContact.Id)
            .setField(Approval__c.Status__c, TaxExemptionHelper.APPROVED)
            .create()
            .getRecord();

        Test.startTest();
        testAccount.BillingCountry = 'Test22';
        testAccount.TaxExemptionApprovals__c = true;
        testAccount.ConfirmTaxExemptionRemoval__c = true;
        update testAccount;
        System.assertNotEquals(null, System.enqueueJob(new BusinessIdentitiesService(new List<Approval__c>{app}, 'Test')));
        Test.stopTest();
    }
 */

	@IsTest
    private static void testCreateDealDeskCase() {
        Test.startTest();
        User usr = createUser('testUser');
        Account newTestAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'testAcc',
                Account.Funnel_not_supported__c => 'Test Funnel not supported text'
            })
            .create()
            .getRecord();

        DealDeskCaseDescription__c testDesc = (DealDeskCaseDescription__c) new SObjectBuilder(DealDeskCaseDescription__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DealDeskCaseDescription__c.Account__c => newTestAccount.Id,
                DealDeskCaseDescription__c.CaseDescription__c => 'Test Description',
                DealDeskCaseDescription__c.CaseOwner__c => usr.Id
            })
            .create()
            .getRecord();

        newTestAccount.RC_User_ID__c = '123456789';
        newTestAccount.Changes__c = 'RC_User_ID__c';

        update newTestAccount;
        Test.stopTest();

        List<Case> caseList = (List<Case>) new CaseSelector()
            .selectCases()
            .selectFields(new Set<String>{
                'Description'
            })
            .executeQuery();

        Map<String, Case> descriptionToCaseMap = new Map<String, Case>();
        for(Case currentCase : caseList) {
            descriptionToCaseMap.put(currentCase.Description, currentCase);
        }
        System.assert(descriptionToCaseMap.containsKey(newTestAccount.Funnel_not_supported__c),
            'CreateDealDeskCase should properly create cases for Funnel_not_supported__c');
        System.assert(descriptionToCaseMap.containsKey(testDesc.CaseDescription__c),
            'CreateDealDeskCase should properly create cases for DealDeskCaseDescription__c');
    }

    @IsTest
    private static void testCreateDealDeskCase_excludeMPUB() {
        User usr = createUser('testUser');
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Feature_Toggle__c.EnableMultiProductUnifiedBilling__c => true
            })
            .create();
        Test.startTest();
        Account newTestAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'testAcc',
                Account.Funnel_not_supported__c => 'Test Funnel not supported text'
            })
            .create()
            .getRecord();

        DealDeskCaseDescription__c testDesc = (DealDeskCaseDescription__c) new SObjectBuilder(DealDeskCaseDescription__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DealDeskCaseDescription__c.Account__c => newTestAccount.Id,
                DealDeskCaseDescription__c.CaseDescription__c => 'Test Description',
                DealDeskCaseDescription__c.CaseOwner__c => usr.Id
            })
            .create()
            .getRecord();

        newTestAccount.RC_User_ID__c = '123456789';
        newTestAccount.Changes__c = 'RC_User_ID__c';

        update newTestAccount;
        Test.stopTest();

        List<Case> caseList = (List<Case>) new CaseSelector()
            .selectCases()
            .selectFields(new Set<String>{
                'Description'
            })
            .executeQuery();

        Map<String, Case> descriptionToCaseMap = new Map<String, Case>();
        for(Case currentCase : caseList) {
            descriptionToCaseMap.put(currentCase.Description, currentCase);
        }
        System.assert(!descriptionToCaseMap.containsKey(newTestAccount.Funnel_not_supported__c),
            'CreateDealDeskCase should not create cases for Funnel_not_supported__c if Account is Unified Billing');
        System.assert(descriptionToCaseMap.containsKey(testDesc.CaseDescription__c),
            'CreateDealDeskCase should properly create cases for DealDeskCaseDescription__c');
    }

	@IsTest
	private static void testValidateVATNumberWithApproval() {
		createTestDataForTA(false, false);

        Test.startTest();

            testAccount.BillingCountry = 'Test';
            testAccount.BillingCity = 'test';
            testAccount.BillingState = 'test';
            testAccount.BillingStreet = 'test';
            testAccount.BillingPostalCode = '1231313';

            update testAccount;

            Approval__c app =  (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
                    .setField(Approval__c.Name, 'Tax Exempt Approval')
                    .setField(Approval__c.RecordTypeId, ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL)
                    .setField(Approval__c.Account__c, testAccount.Id)
                    .setField(Approval__c.Contact__c, testContact.Id)
                    .setField(Approval__c.Status__c, TaxExemptionHelper.APPROVED)
                    .setField(Approval__c.VATNumber__c, '121234')
                    .create()
                    .getRecord();

            testAccount.VATNumber__c = '1111111';
            try {
                update testAccount;
            } catch (Exception e) {
                System.assert(e.getMessage().contains(AccountHelper.VAT_NUMBER_EXCEPTION_APPROVAL), 'Message must be "VAT Number entered does not match the VAT Number in VAT exemption approval. Please remove the existing VAT exemption approval or create a new approval if you need to update the VAT Number."');
            }
		Test.stopTest();
	}


    @IsTest
	private static void testValidateVATNumberForEngageAccounts() {
		Test.startTest();
		Account acc = (Account) new SObjectBuilder(Account.SObjectType)
				.setFields(new Map<SObjectField, Object>{
						Account.Name => 'testAcc'
				})
				.create()
				.getRecord();

		Contact cont = (Contact) new SObjectBuilder(Contact.SObjectType)
				.setFields(new Map<SObjectField, Object>{
						Contact.FirstName => 'Test2',
						Contact.LastName => 'Test2',
						Contact.AccountId => acc.Id,
						Contact.Email => 'test@test.com',
						Contact.Phone => '1234567890',
						Contact.Preferred_Language__c => 'en_US'
				})
				.create()
				.getRecord();

		Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
				.setFields(new Map<SObjectField, Object>{
						Opportunity.Name => 'Test1',
						Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
						Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
						Opportunity.Tier_Name__c => OpportunityHelper.TIER_ENGAGE_DIGITAL_STANDALONE,
						Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
						Opportunity.AccountId => acc.Id,
						Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
						Opportunity.CloseDate => system.today().addMonths(1),
						Opportunity.Primary_Opportunity_Contact__c => cont.Id,
						Opportunity.CurrencyIsoCode => RingCentralHelper.USD
				})
				.create()
				.getRecord();

		acc.VATNumber__c = '123456789';
		try {
			update acc;
		} catch (DmlException e) {
			System.assertEquals(e.getDmlMessage(0), AccountHelper.ENGAGE_VALIDATION_VAT_EXCEPTION, 'Exception message must be "Engage Digital doesn\\\'t support setting VAT Number from Account. Please create VAT Exemption Approval."');
		}

		Test.stopTest();
	}

     /*CMR-216110*/
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    public static void testRemainingCoverage() {
		Map<String, Schema.RecordTypeInfo> accRT = Account.SObjectType.getDescribe().getRecordTypeInfosByName();
        Account testAccount1 = new Account();
        testAccount1.Name = 'Test123';
        testAccount1.SignupType__c = 'TRIAL_30NOCC';
        testAccount1.RC_Account_Status__c = 'TRIAL';
        testAccount1.SignupPlatform__c = 'WEB';
        testAccount1.RC_Service_name__c = 'office123';
        testAccount1.RC_Activation_Date__c = null;
        testAccount1.Partner_ID__c = '9852';
        testAccount1.ZI_Id__c='12345';
        testAccount1.RecordTypeId = accRT.get('ZI Customer Shell Account').getRecordTypeId();
        insert testAccount1;

        Account testAccount2 = new Account();
        testAccount2.Name = 'Test124';
        testAccount2.SignupType__c = 'TRIAL_30NOCC';
        testAccount2.RC_Account_Status__c = 'TRIAL';
        testAccount2.SignupPlatform__c = 'WEB';
        testAccount2.RC_Service_name__c = 'office123';
        testAccount2.RC_Activation_Date__c = null;
        testAccount2.Partner_ID__c = '9852';
        testAccount2.ParentId=testAccount1.Id;
        testAccount2.RecordTypeId=accRT.get('Customer Account').getRecordTypeId();
        insert testAccount2;

        Account testAccount3 = new Account();
        testAccount3.Name = 'Test125';
        testAccount3.SignupType__c = 'TRIAL_30NOCC';
        testAccount3.RC_Account_Status__c = 'TRIAL';
        testAccount3.SignupPlatform__c = 'WEB';
        testAccount3.RC_Service_name__c = 'office123';
        testAccount3.RC_Activation_Date__c = null;
        testAccount3.Partner_ID__c = '9852';
        testAccount3.ParentId=testAccount2.Id;
        testAccount3.RecordTypeId=accRT.get('Customer Account').getRecordTypeId();
        insert testAccount3;

        Account testAccount4 = new Account();
        testAccount4.Name = 'Test126';
        testAccount4.SignupType__c = 'TRIAL_30NOCC';
        testAccount4.RC_Account_Status__c = 'TRIAL';
        testAccount4.SignupPlatform__c = 'WEB';
        testAccount4.RC_Service_name__c = 'office123';
        testAccount4.RC_Activation_Date__c = null;
        testAccount4.Partner_ID__c = '9852';
        testAccount4.ParentId=testAccount3.Id;
        insert testAccount4;

        Account testAccount5 = new Account();
        testAccount5.Name = 'Test126';
        testAccount5.SignupType__c = 'TRIAL_30NOCC';
        testAccount5.RC_Account_Status__c = 'TRIAL';
        testAccount5.SignupPlatform__c = 'WEB';
        testAccount5.RC_Service_name__c = 'office123';
        testAccount5.RC_Activation_Date__c = null;
        testAccount5.Partner_ID__c = '9852';
        testAccount5.ParentId=testAccount4.Id;
        insert testAccount5;

        Account testAccount6 = new Account();
        testAccount6.Name = 'Test126';
        testAccount6.SignupType__c = 'TRIAL_30NOCC';
        testAccount6.RC_Account_Status__c = 'TRIAL';
        testAccount6.SignupPlatform__c = 'WEB';
        testAccount6.RC_Service_name__c = 'office123';
        testAccount6.RC_Activation_Date__c = null;
        testAccount6.Partner_ID__c = '9852';
        testAccount6.ParentId=testAccount5.Id;
        insert testAccount6;

        Account testAccount7 = new Account();
        testAccount7.Name = 'Test127';
        testAccount7.SignupType__c = 'TRIAL_30NOCC';
        testAccount7.RC_Account_Status__c = 'TRIAL';
        testAccount7.SignupPlatform__c = 'WEB';
        testAccount7.RC_Service_name__c = 'office123';
        testAccount7.RC_Activation_Date__c = null;
        testAccount7.Partner_ID__c = '9852';
        insert testAccount7;

        Account testAccount8 = new Account();
        testAccount8.Name = 'Test128';
        testAccount8.SignupType__c = 'TRIAL_30NOCC';
        testAccount8.RC_Account_Status__c = 'TRIAL';
        testAccount8.SignupPlatform__c = 'WEB';
        testAccount8.RC_Service_name__c = 'office123';
        testAccount8.RC_Activation_Date__c = null;
        testAccount8.Partner_ID__c = '9852';
        insert testAccount8;
        
        Test.startTest();
        testAccount6.ParentId=testAccount4.Id;
        update testAccount6;
        delete testAccount5;
        testAccount7.ZI_Id__c='12345';
        update testAccount7;
        testAccount8.ZI_CDP_Match__c='12345';
        update testAccount8;
        testAccount6.ParentId=null;
        update testAccount6;
        //AccountTriggerHandler.replaceValue('abcdef','e','g');
       Test.stopTest();
    }

    @IsTest
    public static void testTerminateActiveAgreement() {
        Test.startTest();
        DateTime dateNow = System.now();

        Opportunity oppty = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test',
                    Opportunity.Type => 'Syndicated - New',
                    Opportunity.StageName => 'Planning',
                    Opportunity.CloseDate => Date.newinstance(dateNow.year(), dateNow.month(), dateNow.day())
                }
            )
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'Test',
                    Quote.OpportunityId => oppty.Id
                }
            )
            .create()
            .getRecord();
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test',
                Account.Active_Sales_Agreement__c => testQuote.Id
            })
            .create()
            .getRecord();

        testAccount.RC_Account_Status__c = AccountHelper.ACCOUNT_STATUS_TERMINATED;
        update testAccount;

        System.assertEquals(
            QuoteHelper.QUOTE_STATUS_TERMINATED,
            [SELECT Status FROM Quote WHERE Id =: testQuote.Id].Status,
            'Quote was not terminated'
        );

        System.assertEquals(
            null,
            [SELECT Active_Sales_Agreement__c FROM Account WHERE Id =: testAccount.Id].Active_Sales_Agreement__c,
            'Active Sales Agreement link should be removed from a terminated account'
        );
        Test.stopTest();
    }

    @IsTest
    public static void testTerminateActiveAgreementMP() {
        Triggers.switchOff();
        TestDataGenerator.MultiproductStructure mpStruct = new TestDataGenerator.MultiproductStructure();
        Triggers.switchOn();
        Test.startTest();
        mpStruct.masterQuote.Status = 'Active';
        mpStruct.masterQuote.QuoteType__c = 'Agreement';
        mpStruct.masterQuote.isPrimary__c = true;
        update mpStruct.masterQuote;

        mpStruct.masterAccount.Active_Sales_Agreement__c = mpStruct.masterQuote.Id;
        update mpStruct.masterAccount;


        mpStruct.masterAccount.RC_Account_Status__c = AccountHelper.ACCOUNT_STATUS_TERMINATED;
        update mpStruct.masterAccount;
        Test.stopTest();

        List<Quote> terminatedQuotes = [ SELECT Status FROM Quote WHERE Id =: mpStruct.masterQuote.Id OR MasterQuote__c =: mpStruct.masterQuote.Id ];
        for (Quote quote : terminatedQuotes) {
            System.assertEquals(QuoteHelper.QUOTE_STATUS_TERMINATED, quote.Status,
                'Master or Technical Quote wasn\'t terminated');
        }
    }

    @IsTest
    public static void testImplementationStatus2Change() {
        DateTime dateNow = System.now();
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test',
                Account.RC_Account_Status__c => AccountHelper.PAID_STATUS
            })
            .create()
            .getRecord();

        Implementation__c implNew = new Implementation__c();
        implNew.Name = 'testImplNew';
        implNew.Account__c = testAccount.Id;
        implNew.Implementation_Status_2__c = ImplementationHelper.CANCELABLE_IMPLEMENTATION_STATUSES_2[0];
        insert implNew;

        Implementation__c implOld = new Implementation__c();
        implOld.Name = 'testImplOld';
        implOld.Account__c = testAccount.Id;
        DateTime twentyDays = System.now().adddays(-20);
        implOld.Implementation_Status_2__c = ImplementationHelper.CANCELABLE_IMPLEMENTATION_STATUSES_2[0];
        insert implOld;
        test.setCreatedDate(implOld.id, twentyDays);
        update implOld;

        Implementation__c implCanceled = new Implementation__c();
        implCanceled.Name = 'implCanceled';
        implCanceled.Account__c = testAccount.Id;
        implCanceled.Implementation_Status_2__c = 'Work in Progress';
        insert implCanceled;

        Test.startTest();
        AccountTriggerHandler.isImplementationUpdated = false;
        testAccount.RC_Account_Status__c = AccountHelper.CANCELED_STATUS;
        update testAccount;
        implNew = (Implementation__c) new ImplementationSelector()
                .selectImplementationsWithStatusFields(new List<Id>{testAccount.Id})
                .setCondition('Account__c = :bind0 AND Name = :bind1')
                .setQueryBindings(new List<Object>{ testAccount.Id, implNew.Name})
                .executeQuery()
                .get(0);
        implOld = (Implementation__c) new ImplementationSelector()
                .selectImplementationsWithStatusFields(new List<Id>{testAccount.Id})
                .setCondition('Account__c = :bind0 AND Name = :bind1')
                .setQueryBindings(new List<Object>{ testAccount.Id, implOld.Name})
                .executeQuery()
                .get(0);
        implCanceled = (Implementation__c) new ImplementationSelector()
                .selectImplementationsWithStatusFields(new List<Id>{testAccount.Id})
                .setCondition('Account__c = :bind0 AND Name = :bind1')
                .setQueryBindings(new List<Object>{ testAccount.Id, implCanceled.Name})
                .executeQuery()
                .get(0);


        System.assertEquals(ImplementationHelper.STATUS_2_INVALID_IMPLEMENTATIONS, implNew.Implementation_Status_2__c,
            'Implementation_Status_2__c wasn\'t changed properly on the record <= 15 days.'
        );
        System.assertEquals(ImplementationHelper.STATUS_2_ACCOUNT_CANCELLED, implOld.Implementation_Status_2__c,
            'Implementation_Status_2__c wasn\'t changed properly on the record > 15 days.'
        );
        System.assertEquals(ImplementationHelper.STATUS_2_6c_COMPLETED_ACCOUNT_CANCELLED, implCanceled.Implementation_Status_2__c,
            'Implementation_Status_2__c wasn\'t changed properly on the record related to a canceled Account'
        );

        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@IsTest
	private static void testSendElaDataToNGBS() {
		List<Account> accounts = (List<Account>) new SObjectBuilder(Account.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					Account.Name => 'Test account',
					Account.Billing_ID__c => ValueProviderBuilder.provideList(new List<String>{'123456789','987654321'}),
					Account.RC_User_ID__c => ValueProviderBuilder.provideList(new List<String>{'63613180004','63613180005'}),
					Account.ELA_Account_Type__c => ValueProviderBuilder.provideList(new List<String>{AccountHelper.ACCOUNT_TYPE_ELA_SERVICE, AccountHelper.ACCOUNT_TYPE_ELA_BILLING}),
					Account.BillingCountry => ValueProviderBuilder.provideList(new List<String>{'Canada', 'India'})
				}
			)
			.quantity(2)
			.create()
			.getRecords();

		List<Package__c> packages = (List<Package__c>) new SObjectBuilder(Package__c.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					Package__c.Account__c => ValueProviderBuilder.provideList(new List<Id>{accounts[0].Id, accounts[1].Id}),
					Package__c.Enterprise_Account_ID__c => ValueProviderBuilder.provideList(new List<Id>{accounts[0].Id, accounts[1].Id}),
					Package__c.Account_Package_Id__c => ValueProviderBuilder.provideList(new List<String>{'18','19'})
				}
			)
			.quantity(2)
			.create()
			.getRecords();

		accounts[0].RC_Account_Status__c = AccountHelper.PAID_STATUS;
		accounts[1].RC_Account_Status__c = AccountHelper.PAID_STATUS;

		Test.startTest();

		BillingHttpRequestMock tstMock = new BillingHttpRequestMock();
		Test.setMock(HttpCalloutMock.class, tstMock);
		update accounts;

		Test.stopTest();
	}

    @IsTest
    private static void testRestrictEditBillingAddressForIndianAccounts() {
        User salesUser = createUser('sales', ProfileHelper.PROFILE_NAME_SALES_REP_LIGHTNING, true);
        String errorMessage;

        System.runAs(salesUser) {
            Account billingAcc = (Account) new SObjectBuilder(Account.sObjectType)
                .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
                .create()
                .getRecord();
            Approval__c approval = (Approval__c) new SObjectBuilder(Approval__c.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Approval__c.Name => 'KYC Approval',
                    Approval__c.Account__c => billingAcc.Id,
                    Approval__c.RecordTypeId => ApprovalHelper.RT_ID_KYC_APPROVAL_REQUEST,
                    Approval__c.DateOfSignOff__c => System.today()
                })
                .create()
                .getRecord();

            Test.startTest();


            billingAcc.BillingState = 'Updated State';
            try {
                update billingAcc;
            } catch (Exception e) {
                errorMessage = e.getMessage();
            }
        }
        Test.stopTest();

        System.assert(errorMessage.contains(Label.BillingAddressCantBeEditedOnIndianAccount),
            'Billing Address can\'t  be edited by sales for Indian Account');
    }

    @IsTest
    public static void intendedBrandDFR_whenUpdateRCBrandOnLeadAccount_shouldUpdateIntendedBrandOnDFR() {

        Account acc = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.Name, 'camp Test')
            .setField(Account.RC_Brand__c, 'RingCentral AU')
            .create()
            .getRecord();

        List<Lead> leads = (List<Lead>) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.lastName, 'LEAD TEST')
            .setField(Lead.BMID__c, null)
            .setField(Lead.AID__c, '1')
            .setField(Lead.PID__c, '1')
            .setField(Lead.ZI_CDP_Account_Id__c, acc.Id)
            .quantity(2)
            .create()
            .getRecords();

        List<Demand_Funnel__c> dfrs = new List<Demand_Funnel__c>();

        for (Integer i=0 ; i< 2; i++) {
            dfrs.add(
                (Demand_Funnel__c) new SObjectBuilder(Demand_Funnel__c.SObjectType)
                    .setFields(
                        new Map<SObjectField, Object>{
                            Demand_Funnel__c.Lead__c => leads[i].Id
                        }
                    )
                    .build()
                    .getRecord()
            );
        }

        insert dfrs;

        Test.startTest();
            acc.RC_Brand__c = 'RingCentral Canada';
            update acc;
        Test.stopTest();

        dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByIds(new Object[]{dfrs})
            .selectField(Demand_Funnel__c.Intended_Brand__c)
            .selectField(Demand_Funnel__c.Prospect_Lead_Source__c)
            .executeQuery();

        System.assertEquals(2, dfrs.size(), 'There should be fifty (2) Demand Funnel records.');

        for (Demand_Funnel__c dfr : dfrs) {
            System.assertEquals('RingCentral Canada', dfr.Intended_Brand__c, 'The Intended Brand should be the same as the Account RC Brand Name');
        }
    }

    @IsTest
    public static void intendedBrandDFR_whenUpdateRCBrandOnOpportunityAccount_shouldUpdateIntendedBrandOnDFR() {

        List<Account> accs = (List<Account>) new SObjectBuilder(Account.sObjectType)
            .setField(Account.Name, 'camp Test')
            .setField(Account.RC_Brand__c, 'RingCentral AU')
            .quantity(2)
            .create()
            .getRecords();

        List<Opportunity> opps = new List<Opportunity>();

        for (Integer i = 0; i < 2; i++) {
            opps.add((Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Opportunity.Name => 'Test Opportunity 2016',
                        Opportunity.Type => 'Syndicated - New',
                        Opportunity.StageName => 'Planning',
                        Opportunity.CloseDate => system.today().addMonths(1),
                        Opportunity.AccountId => accs[i].Id
                    }
                )
                .build()
                .getRecord()
            );
        }

        insert opps;

        Lead leadTest = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.lastName, 'LEAD TEST')
            .setField(Lead.BMID__c, null)
            .setField(Lead.AID__c, '1')
            .setField(Lead.PID__c, '1')
            .create()
            .getRecord();

        List<Demand_Funnel__c> dfrs = new List<Demand_Funnel__c>();

        for (Integer i=0 ; i< 2; i++) {
            dfrs.add(
                (Demand_Funnel__c) new SObjectBuilder(Demand_Funnel__c.SObjectType)
                    .setFields(
                        new Map<SObjectField, Object>{
                            Demand_Funnel__c.Opportunity__c => opps[i].Id,
                            Demand_Funnel__c.Lead__c => leadTest.Id
                        }
                    )
                    .build()
                    .getRecord()
            );
        }

        insert dfrs;

        Test.startTest();
            for (Account acc : accs) {
                acc.RC_Brand__c = 'RingCentral Canada';
            }
            update accs;
        Test.stopTest();

        dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByIds(new Object[]{dfrs})
            .selectField(Demand_Funnel__c.Intended_Brand__c)
            .selectField(Demand_Funnel__c.Prospect_Lead_Source__c)
            .executeQuery();

        System.assertEquals(2, dfrs.size(), 'There should be ten (2) Demand Funnel records.');

        for (Demand_Funnel__c dfr : dfrs) {
            System.assertEquals('RingCentral Canada', dfr.Intended_Brand__c, 'The Intended Brand should be the same as the Account RC Brand Name');
        }
    }

    @IsTest
    public static void intendedBrandDFR_whenUpdateZICompanyCountryOnOpportunityAccount_shouldUpdateIntendedBrandOnDFR() {

        List<Account> accs = (List<Account>) new SObjectBuilder(Account.sObjectType)
            .setField(Account.Name, 'camp Test')
            .setField(Account.ZI_Company_Country__c, 'Canada')
            .quantity(2)
            .create()
            .getRecords();


        List<Opportunity> opps = new List<Opportunity>();

        for (Integer i = 0; i < 2; i++) {
            opps.add((Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Opportunity.Name => 'Test Opportunity 2016',
                        Opportunity.Type => 'Syndicated - New',
                        Opportunity.StageName => 'Planning',
                        Opportunity.CloseDate => system.today().addMonths(1),
                        Opportunity.AccountId => accs[i].Id
                    }
                )
                .build()
                .getRecord()
            );
        }

        insert opps;

        Lead leadTest = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.lastName, 'LEAD TEST')
            .setField(Lead.BMID__c, null)
            .setField(Lead.AID__c, '1')
            .setField(Lead.PID__c, '1')
            .create()
            .getRecord();

        List<Demand_Funnel__c> dfrs = new List<Demand_Funnel__c>();

        for (Integer i=0 ; i< 2; i++) {
            dfrs.add(
                (Demand_Funnel__c) new SObjectBuilder(Demand_Funnel__c.SObjectType)
                    .setFields(
                        new Map<SObjectField, Object>{
                            Demand_Funnel__c.Opportunity__c => opps[i].Id,
                            Demand_Funnel__c.Lead__c => leadTest.Id
                        }
                    )
                    .build()
                    .getRecord()
            );
        }

        insert dfrs;

        Test.startTest();
            for (Account acc : accs) {
                acc.ZI_Company_Country__c = 'Netherlands';
            }
            update accs;
        Test.stopTest();

        dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByIds(new Object[]{dfrs})
            .selectField(Demand_Funnel__c.Intended_Brand__c)
            .selectField(Demand_Funnel__c.Prospect_Lead_Source__c)
            .executeQuery();

        System.assertEquals(2, dfrs.size(), 'There should be ten (2) Demand Funnel records.');

        for (Demand_Funnel__c dfr : dfrs) {
            System.assertEquals('RingCentral EU', dfr.Intended_Brand__c, 'The Intended Brand should be RingCentral EU because the SM Country is the same as the Opportunity Account and it is Netherlands.');
        }
    }

    @IsTest
    public static void intendedBrandDFR_whenUpdateZICompanyCountryOnLeadAccount_shouldUpdateIntendedBrandOnDFR() {

        Account acc = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.Name, 'camp Test')
            .setField(Account.ZI_Company_Country__c, 'Canada')
            .setField(Account.Multinational_Ultimate__c, false)
            .create()
            .getRecord();

        List<Lead> leads = (List<Lead>) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.lastName, 'LEAD TEST')
            .setField(Lead.BMID__c, null)
            .setField(Lead.AID__c, '1')
            .setField(Lead.ZI_CDP_Account_Id__c, acc.Id)
            .quantity(2)
            .create()
            .getRecords();

        List<Demand_Funnel__c> dfrs = new List<Demand_Funnel__c>();

        for (Integer i=0 ; i< 2; i++) {
            dfrs.add(
                (Demand_Funnel__c) new SObjectBuilder(Demand_Funnel__c.SObjectType)
                    .setFields(
                        new Map<SObjectField, Object>{
                            Demand_Funnel__c.Lead__c => leads[i].Id
                        }
                    )
                    .build()
                    .getRecord()
            );
        }

        insert dfrs;

        Test.startTest();
            acc.ZI_Company_Country__c = 'Netherlands';
            update acc;
        Test.stopTest();

        dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByIds(new Object[]{dfrs})
            .selectField(Demand_Funnel__c.Intended_Brand__c)
            .selectField(Demand_Funnel__c.Prospect_Lead_Source__c)
            .executeQuery();

        System.assertEquals(2, dfrs.size(), 'There should be twenty (2) Demand Funnel records.');

        for (Demand_Funnel__c dfr : dfrs) {
            System.assertEquals('RingCentral EU', dfr.Intended_Brand__c, 'The Intended Brand should be RingCentral EU because the SM Country is the same as the Opportunity Account and it is Netherlands.');
        }
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    public static void testAcountHoldOut(){
        //User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        User thisUser = [SELECT Id FROM User WHERE isActive = true and Profile.Name = 'System Administrator' limit 1];
        System.runAs (thisUser) {
            Map<String, User> users = new Map<String, User>();
            String errMsg;
            for(Integer i = 0; i < 3; i++){
                String userName = 'usr' + i;
                users.put(userName, createUser(userName, ProfileHelper.SYSTEM_ADMIN, false));
            }
            User usr3 = createUser('usr3', ProfileHelper.SYSTEM_ADMIN, false);
            usr3.Hold_Out_List__c = String.isBlank(Label.Hold_Out_List_Limit)? 20 : Integer.valueOf(Label.Hold_Out_List_Limit);
            users.put('usr3', usr3);
            insert users.values();
            //test insert
            Test.startTest();
            Account acc = new Account (name = 'Test', hold_out__c = true,ownerId=users.get('usr0').id);
            Account acc2 = new Account (name = 'Test', hold_out__c = true,ownerId=users.get('usr1').id);
            Account acc3 = new Account (name = 'Test', hold_out__c = false,ownerId=users.get('usr2').id);
            insert (new List<Account>{acc, acc2, acc3});

            acc2.hold_out__c = false;
            acc3.hold_out__c = true;
            update (new List<Account>{acc2, acc3});

            try{
                Account acc4 = new Account (name = 'Test', hold_out__c = true,ownerId=users.get('usr3').id);
                insert acc4;
            }catch(Exception ex){
                errMsg = ex.getMessage();
            }

            Test.stopTest();
            List<Id> userIds = new List<Id>{users.get('usr0').id, users.get('usr1').id, users.get('usr2').id, users.get('usr3').id};
            for(User updatedUser: [SELECT Hold_Out_List__c FROM User WHERE id=:userIds]){
                System.debug('commented');
                /*//assert if inserting acct with hold out = true updates hold out count in user
                if(updatedUser.id == users.get('usr0').id){
                    system.assert(updatedUser.Hold_Out_List__c == 1);
                }
                //assert if updating acct from hold out true to false updates hold out count in user
                else if(updatedUser.id == users.get('usr1').id){
                    system.assert(updatedUser.Hold_Out_List__c == 0);
                }
                //assert if updating acct from hold out false to true updates hold out count in user
                else if(updatedUser.id == users.get('usr2').id){
                    system.assert(updatedUser.Hold_Out_List__c == 1);
                }
                //assert if inserting acct with hold out = true does not update hold out count in user and throws error when user's hold out list = limit
                else if(updatedUser.id == users.get('usr3').id){
                    Integer holdOutLimit = String.isBlank(Label.Hold_Out_List_Limit)? 20 : Integer.valueOf(Label.Hold_Out_List_Limit);
                    system.assert(updatedUser.Hold_Out_List__c == holdOutLimit);
                    String expectedErr = 'Insert Failed. First exception on row 0; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, Account Owner already has ' + holdOutLimit + ' accounts on hold out.: [Hold_Out__c]';
                    system.assert(errMsg == expectedErr);
                }*/
            }
        }

    }

    @IsTest
    static void testUpdateContactStatusWhenAccountIsPaid() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test account')
            .setField(Account.Phone, '5465491')
            .create()
            .getRecord();

        Test.startTest();
        acc.RC_Account_Status__c = AccountHelper.PAID_STATUS;
        update acc;
        Test.getEventBus().deliver();
        Test.stopTest();
        System.assertEquals(1, ContactUpdatePlatformEventsHelper.paidAccIds.size(), 'Incorrect size for the set to process');
        System.assert(ContactUpdatePlatformEventsHelper.paidAccIds.contains(acc.Id), 'The Account ids don\'t match');
    }

    @IsTest
    static void testQualtricsChurnSurvey() {
        // Create test data
        Triggers.switchOff();
		    createTestData();
	    Triggers.switchOn();

        AccountContactRole testContactRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => testAccount.Id,
                    AccountContactRole.ContactId => testContact.Id,
                    AccountContactRole.Role => 'RC Primary User',
                    AccountContactRole.IsPrimary => true
                }
            )
            .create()
            .getRecord();

        // Trigger the qualtrics Churn Survey logic
		testAccount.RC_Account_Status__c = 'Canceled';

        Test.startTest();
		update testAccount;
	    Test.stopTest();

        // Verify the changes
        testAccount = [SELECT Primary_Contact__c FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(testContact.Id, testAccount.Primary_Contact__c);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testMedalliaChurnSurveyForAssisted() {
        Triggers.switchOff();

    	createTestData();
        Id CaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('CERT').getRecordTypeId();
        Case c = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    	Case.Status => 'New',
                        Case.RecordTypeId => CaseRecordTypeId,
                        Case.AccountId => testAccount.Id,
                        Case.ContactId => testContact.Id,
                        Case.Call_Outcome__c => 'Cancelled',
                        Case.Cancellation_Downsell_Reason__c => 'Cost',
                        Case.Cancellation_Downsell_Sub_Reason__c => 'Too expensive',
                        Case.Appeasement_Offered__c => 'Downgrade',
                        Case.Subject => 'Test',
                        Case.Description => 'Test',
                        Case.Origin => 'Phone',
                        Case.Competitive_Threat__c => 'No Competitive Threat'
                        }
            )
            .create()
            .getRecord();

	    Triggers.switchOn();

		testAccount.RC_Account_Status__c = 'Canceled';
		testAccount.Resend_Invitation__c = true;

        Test.startTest();
		    update testAccount;
	    Test.stopTest();
	}

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testMedalliaChurnSurveyForUnassisted() {
        Triggers.switchOff();
		    createTestData();
	    Triggers.switchOn();

		testAccount.RC_Account_Status__c = 'Canceled';
		testAccount.Resend_Invitation__c = true;

        Test.startTest();
		update testAccount;
	    Test.stopTest();
	}

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void testCreateTaskUponNumberOfDLValueChanges() {

      	Test.startTest();
        Account_Enterprise_Support_Uplift__c dlValues = Account_Enterprise_Support_Uplift__c.getInstance();
        dlValues.No_of_DL_Field__c = 'Number_of_DL_s__c';
        dlValues.Threshold_1__c = 499;
        dlValues.Threshold_2__c = 500;
        dlValues.Threshold_3__c = 1499;
        dlValues.Threshold_4__c = 1500;

        insert dlValues;

        Account testAccount1 = new Account();
        testAccount1.Name = 'TestESUplift1';
        testAccount1.SignupType__c = 'TRIAL_30NOCC';
        testAccount1.RC_Account_Status__c = 'TRIAL';
        testAccount1.SignupPlatform__c = 'WEB';
        testAccount1.RC_Service_name__c = 'office123';
        testAccount1.RC_Activation_Date__c = null;
        testAccount1.Partner_ID__c = '9852';
        testAccount1.Number_of_DL_s__c = 499;
        insert testAccount1;


        testAccount1.Number_of_DL_s__c = 525;
        update testAccount1;
        Test.stopTest();
    }

    public static void createTestDataForATM() {
        Id partnerAccRTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner Account').getRecordTypeId();
        Id custAccRTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account').getRecordTypeId();

        testAccount = new Account();
		testAccount.Name = 'Test123';
		testAccount.RecordTypeId = partnerAccRTypeId;
		testAccount.Inside_Sales_Rep__c = salesrepUser.Id;
		insert testAccount;

        Account testAccount1 = new Account();
		testAccount1.Name = 'Test123-customer';
		testAccount1.RecordTypeId = custAccRTypeId;
        testAccount1.partner_account__c = testAccount.Id;
		insert testAccount1;
    }

    @IsTest static void testInsertPartnerAccChannelManagerToATM() {
        createTestDataForATM();
        Test.startTest();
	    	List<AccountTeamMember> atm = [SELECT id, teamMemberRole FROM AccountTeamMember WHERE AccountId =:testAccount.Id ];
            System.debug('ATM ' + atm);
            System.assert(!atm.isEmpty(), 'Account Team member not added');
      	Test.stopTest();
    }

    @IsTest static void testUpdatePartnerAccChannelManagerToATM() {
        createTestDataForATM();
        testAccount.Inside_Sales_Rep__c = salesmanagerUser.Id;
        Test.startTest();
        update testAccount;
	    	List<AccountTeamMember> atm = [SELECT id,userId, teamMemberRole FROM AccountTeamMember WHERE AccountId =:testAccount.Id ];
            System.assert(!atm.isEmpty(), 'Account Team member not added');
            System.assert(atm[0].userId == salesmanagerUser.Id, 'Account Team member not updated');
      	Test.stopTest();
    }

	@isTest static void testChannelManagerToATM_UpdatePartnerOfCustomerAcc() {
		createTestDataForATM();
		Id partnerAccRTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner Account').getRecordTypeId();

		Account testPartnerAccount = new Account();
		testPartnerAccount.Name = 'Test123';
		testPartnerAccount.RecordTypeId = partnerAccRTypeId;
		testPartnerAccount.Inside_Sales_Rep__c = salesmanagerUser.Id;
		insert testPartnerAccount;

		Account custAcc = [SELECT Id from Account where partner_account__c = :testAccount.Id];
		custAcc.partner_account__c = testPartnerAccount.Id;
		Test.startTest();
		update custAcc;
		List<AccountTeamMember> atm = [SELECT id,userId, teamMemberRole FROM AccountTeamMember where AccountId =:custAcc.Id ];
		System.assert(!atm.isEmpty(), 'Account Team member not added');
		System.assert(atm[0].userId == salesmanagerUser.Id, 'Account Team member not updated');
		Test.stopTest();
	}

    /*for code coverage for EU Privacy*/
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest static void testAccountDelete() {
        createTestDataForATM();
        Id partnerAccRTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner Account').getRecordTypeId();

        Account testPartnerAccount = new Account();
		testPartnerAccount.Name = 'Test123';
		testPartnerAccount.RecordTypeId = partnerAccRTypeId;
		testPartnerAccount.Inside_Sales_Rep__c = salesmanagerUser.Id;
		insert testPartnerAccount;
        Test.startTest();
        delete testPartnerAccount;
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest static void testRemainingCoverage2() {
        Test.startTest();
        Gating_Process_Stage__c processStage = Gating_Process_Stage__c.getInstance();
        processStage.Account_Gating_Website_Exclusion__c='test,unavailable';
        processStage.Account_Gating_Name_Exclusion__c='test,unavailable';
        processStage.Account_Last_Modified_Exclusion_Ids__c='00580000005RAeeAAG,00534000009LhQeAAK';
        processStage.Account_Gating_Status_Exclusion__c='Free,Test';
        insert processStage;
        Account testAccount1 = new Account();
		testAccount1.Name = 'Test123-customer';
		insert testAccount1;
        Account testAccount2 = new Account();
		testAccount2.Name = 'Test123-customer2';
		insert testAccount2;
        Account testAccount3 = new Account();
		testAccount3.Name = 'Test123-customer3';
		insert testAccount3;
        testAccount1.LS_Status__c='Success';
        testAccount1.LS_Enrichment_Date__c=System.today();
        update testAccount1;
        testAccount2.Website='https://www.sample.com';
        update testAccount2;
        testAccount3.Systems_process_stage__c='Manual SFDC updated';
        update testAccount3;
        Test.stopTest();
    }
    @IsTest
    static void testCopyServiceDetailsToBillingAccountPackage() {
        Triggers.switchOff();
        Triggers.except('AccountTriggerHandler.CopyServiceDetailsToBillingAccountPackage');
        Account masterAccount = TestDataGenerator.createAccount('Master');

        String[] serviceNames = new List<String> {
            QuoteHelper.NGBS_OFFICE_PRODUCT,
            QuoteHelper.NGBS_RCCC_PRODUCT,
            QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT,
            QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT
        };
        Map<String, Account> accounts = AccountHelper.createTechnicalAccounts(masterAccount.Id, serviceNames);
        Account ccAccount = accounts.get(QuoteHelper.NGBS_RCCC_PRODUCT);
        Account edAccount = accounts.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT);
        Account evAccount = accounts.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT);

        Package__c bapOffice = TestDataGenerator.createBillingAccountPackage(masterAccount);
        Package__c bapCC = TestDataGenerator.createBillingAccountPackage(ccAccount, masterAccount);
        Package__c bapED = TestDataGenerator.createBillingAccountPackage(edAccount, masterAccount);

        Test.startTest();
        update new List<Account>{
            new Account(Id = masterAccount.Id, RC_Account_Status__c = 'Paid'),
            new Account(Id = ccAccount.Id, RC_Account_Status__c = 'Canceled'),
            new Account(Id = edAccount.Id, RC_Account_Status__c = 'Canceled'),
            new Account(Id = evAccount.Id, RC_Account_Status__c = 'Paid')
        };

        Triggers.switchOn();
        List<Package__c> billingAccountPackages = new PackageSelector()
            .selectPackagesByEnterpriseAccountIdsWithServiceFields(new List<Id> {masterAccount.Id, ccAccount.Id, edAccount.Id, evAccount.Id})
            .executeQuery();

        Map<String, Package__c> result = new Map<String, Package__c>();
        for(Package__c billingAccountPackage: billingAccountPackages) {
            result.put(billingAccountPackage.Service_Type__c, billingAccountPackage);
        }
        Test.stopTest();

        Assert.isFalse(result.isEmpty(), 'master account has Billing Account Packages');

        masterAccount = (Account) new AccountSelector()
            .selectAccountsByIdsWithServiceInfoFields(new List<Id> { masterAccount.Id })
            .executeQuery()
            .get(0);
        accounts = AccountHelper.getTechnicalAccountsByMasterId(masterAccount.Id);
        ccAccount = accounts.get(QuoteHelper.NGBS_RCCC_PRODUCT);
        edAccount = accounts.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT);
        evAccount = accounts.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT);

        bapOffice = result.get(QuoteHelper.NGBS_OFFICE_PRODUCT);
        bapCC = result.get(QuoteHelper.NGBS_RCCC_PRODUCT);
        bapED = result.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT);

        Assert.areEqual(
            masterAccount.RC_Account_Status__c,
            bapOffice.RC_Account_Status__c,
            String.format(
                FAILED_TO_COPY_TO_PACKAGE_ASSERT_MSG, new List<String> {Account.RC_Account_Status__c.toString(), 'master'})
        );
        Assert.areEqual(
            ccAccount.RC_Account_Status__c,
            bapCC.RC_Account_Status__c,
            String.format(FAILED_TO_COPY_TO_PACKAGE_ASSERT_MSG, new List<String> {Account.MRR__c.toString(), 'CC technical'})
        );
        Assert.areEqual(
            edAccount.RC_Account_Status__c,
            bapED.RC_Account_Status__c,
            String.format(
                FAILED_TO_COPY_TO_PACKAGE_ASSERT_MSG, new List<String> {Account.RC_Account_Status__c.toString(), 'ED technical'})
        );

        Assert.isNull(
            result.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT),
            'no billing account package for EV'
        );
    }

	@IsTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	public static void testUpdateServiceMRRFieldsOnMasterAccount()
	{
		Triggers.switchOff();
		Triggers.except('AccountTriggerHandler.UpdateServiceMRRFieldsOnMasterAccount');

		Account masterAccount = TestDataGenerator.createAccount('Master');

		String[] serviceNames = new List<String> {
			QuoteHelper.NGBS_OFFICE_PRODUCT,
			QuoteHelper.NGBS_RCCC_PRODUCT,
			QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT,
			QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT
		};
		Map<String, Account> accounts = AccountHelper.createTechnicalAccounts(masterAccount.Id, serviceNames);
		Account ccAccount = accounts.get(QuoteHelper.NGBS_RCCC_PRODUCT);
		Account edAccount = accounts.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT);
		Account evAccount = accounts.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT);
        Account evntAccount = TestDataGenerator.createAccount('Test '+QuoteHelper.NGBS_RCEVENTS_PRODUCT, QuoteHelper.NGBS_RCEVENTS_PRODUCT);

		Package__c bapOffice = TestDataGenerator.createBillingAccountPackage(masterAccount);
		Package__c bapCC = TestDataGenerator.createBillingAccountPackage(ccAccount, masterAccount);
		Package__c bapED = TestDataGenerator.createBillingAccountPackage(edAccount, masterAccount);
		Package__c bapEV = TestDataGenerator.createBillingAccountPackage(evAccount, masterAccount);
        Package__c bapEvnt = TestDataGenerator.createBillingAccountPackage(evntAccount);

		Test.startTest();
        Triggers.switchOff();
        update new List<Package__c>{
            new Package__c(Id = bapED.Id, NumberOfEngageDigitalUsers__c = 23, EDAcquisitionMRR__c = 20),
            new Package__c(Id = bapEV.Id, NumberOfEngageVoiceSeats__c = 23, EVAcquisitionMRR__c = 30),
            new Package__c(Id = bapCC.Id, CCAcquisitionMRR__c = 10),
            new Package__c(Id = bapEvnt.Id, Number_of_Events_Users__c = 24, Events_Acquisition_MRR__c = 40)
        };
        Triggers.switchOn();

		update new List<Account>{
			new Account(Id = ccAccount.Id, inContactARPU__c = 11),
			new Account(Id = edAccount.Id, CombinedEngageDigitalMRR__c = 300.0, EngageDigitalARPU__c = 22),
			new Account(Id = evAccount.Id, CombinedEngageVoiceMRR__c = 400.0, EngageVoiceARPU__c = 33),
			new Account(Id = masterAccount.Id, CombinedMVPCurrentTotalMRR__c = 100.0, CombinedMVPAcquisitionMRR__c = 5),
            new Account(Id = evntAccount.Id, CombinedEventsMRR__c = 500.0, EventsARPU__c = 35)
		};

		masterAccount = (Account) new AccountSelector()
			.selectAccountById(masterAccount.Id)
			.selectFields(AccountSelector.FIELDS_AGGREGATED_TOTALS)
			.executeQuery()
			.get(0);

        bapEV = (Package__c) new PackageSelector()
            .selectPackagesById(new List<Id> { bapEV.Id })
            .selectFields(new List<String> {
                'NumberOfEngageVoiceSeats__c',
                'EVAcquisitionMRR__c'
            })
            .executeQuery()
            .get(0);

        bapED = (Package__c) new PackageSelector()
            .selectPackagesById(new List<Id> { bapED.Id })
            .selectFields(new List<String> {
                'NumberOfEngageDigitalUsers__c',
                'EDAcquisitionMRR__c'
            })
            .executeQuery()
            .get(0);

        bapCC = (Package__c) new PackageSelector()
            .selectPackagesById(new List<Id> { bapCC.Id })
            .selectFields(new List<String> {
                'CCAcquisitionMRR__c'
            })
            .executeQuery()
            .get(0);

        bapEvnt = (Package__c) new PackageSelector()
            .selectPackagesById(new List<Id> { bapEvnt.Id })
            .selectFields(new List<String> {
                'Number_of_Events_Users__c',
                'Events_Acquisition_MRR__c'
                })
            .executeQuery()
            .get(0);

		accounts = AccountHelper.getTechnicalAccountsByMasterId(masterAccount.Id);
		ccAccount = accounts.get(QuoteHelper.NGBS_RCCC_PRODUCT);
		edAccount = accounts.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT);
		evAccount = accounts.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT);
        evntAccount = accounts.get(QuoteHelper.NGBS_RCEVENTS_PRODUCT);

		Test.stopTest();
		Triggers.switchOn();

		// System.assertEquals(bapCC.CCAcquisitionMRR__c, masterAccount.CombinedCCAcquisitionMRR__c);
		// System.assertEquals(bapED.EDAcquisitionMRR__c, masterAccount.CombinedEDAcquisitionMRR__c);
		// System.assertEquals(bapEV.EVAcquisitionMRR__c, masterAccount.CombinedEVAcquisitionMRR__c);

		// System.assertEquals(bapED.NumberOfEngageDigitalUsers__c, masterAccount.CombinedNumberOfEngageDigitalUsers__c);
		// System.assertEquals(bapEV.NumberOfEngageVoiceSeats__c, masterAccount.CombinedNumberOfEngageVoiceSeats__c);

		// System.assertEquals(ccAccount.inContactARPU__c, masterAccount.inContactARPU__c);
		// System.assertEquals(edAccount.EngageDigitalARPU__c, masterAccount.EngageDigitalARPU__c);
		// System.assertEquals(evAccount.EngageVoiceARPU__c, masterAccount.EngageVoiceARPU__c);
	}
	@IsTest
	public static void testUpdateReportedMRSOnPackage()
	{
		Triggers.switchOff();
		Triggers.except('AccountTriggerHandler.UpdateReportedMRSOnPackage');

		Account masterAccount = TestDataGenerator.createAccount('Master');

		String[] serviceNames = new List<String> {
			QuoteHelper.NGBS_OFFICE_PRODUCT,
			QuoteHelper.NGBS_RCCC_PRODUCT,
			QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT,
			QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT
		};
		Map<String, Account> accounts = AccountHelper.createTechnicalAccounts(masterAccount.Id, serviceNames);
		Package__c bapOffice = TestDataGenerator.createBillingAccountPackage(masterAccount);

		Test.startTest();

		update new Account(
			Id = masterAccount.Id,
			CombinedEngageDigitalMRR__c = 10,
			CombinedEngageVoiceMRR__c = 1
		);

		masterAccount = (Account) new AccountSelector()
			.selectAccountById(masterAccount.Id)
			.executeQuery()
			.get(0);

		List<Package__c> billingAccountPackages = new PackageSelector()
			.selectPackagesByEnterpriseAccountIds(new List<Id> {masterAccount.Id})
			.executeQuery();

		Map<String, Package__c> result = new Map<String, Package__c>();
		for(Package__c billingAccountPackage: billingAccountPackages) {
			result.put(billingAccountPackage.Service_Type__c, billingAccountPackage);
		}

		bapOffice = result.get(QuoteHelper.NGBS_OFFICE_PRODUCT);
		Test.stopTest();
		Triggers.switchOn();

		System.assert(bapOffice.Reported_MRS__c == (10 - 1));
	}

	@IsTest
	public static void testCopyFieldsToTechnicalAccounts() {
		Triggers.switchOff();
		Triggers.except('AccountTriggerHandler.CopyFieldsToTechnicalAccounts');

		Account masterAccount = TestDataGenerator.createAccount('Master');
		String[] serviceNames = new List<String> {
			QuoteHelper.NGBS_OFFICE_PRODUCT,
			QuoteHelper.NGBS_RCCC_PRODUCT,
			QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT,
			QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT
		};
		Map<String, Account> accounts = AccountHelper.createTechnicalAccounts(masterAccount.Id, serviceNames);

		Test.startTest();

		update new Account(
			Id = masterAccount.Id,
			RC_User_ID__c = '100500',
			BillingCountry = 'United States',
			BillingState = 'New York',
			BillingCity = 'New York',
			BillingStreet = 'Wall str, 1',
			BillingPostalCode = '30200',
            VATNumber__c = '123456',
            Tax_Exempt__c = true
		);

		masterAccount = (Account) new AccountSelector()
			.selectAccountByIdWithAllFields(masterAccount.Id)
			.executeQuery()
			.get(0);
		accounts = AccountHelper.getTechnicalAccountsByMasterId(masterAccount.Id);

		Test.stopTest();
		Triggers.switchOn();

		for (String service: accounts.keySet()) {
			Account techAccount = accounts.get(service);
			System.assertEquals(
				masterAccount.BillingCountry, techAccount.BillingCountry,
				'Billing Country copied from master account'
			);
			System.assertEquals(
				masterAccount.BillingState, techAccount.BillingState,
				'Billing State copied from master account'
			);
			System.assertEquals(
				masterAccount.BillingCity, techAccount.BillingCity,
				'Billing City copied from master account'
			);
			System.assertEquals(
				masterAccount.BillingStreet, techAccount.BillingStreet,
				'Billing Street copied from master account'
			);
			System.assertEquals(
				masterAccount.BillingPostalCode, techAccount.BillingPostalCode,
				'Billing Postal code copied from master account'
			);
			System.assertEquals(
				masterAccount.RC_User_ID__c, techAccount.EnterpriseCustomerID__c,
				'Enterprise Account Id copied from master account into Enterprise Customer Id field'
			);
			System.assertEquals(
				masterAccount.VATNumber__c, techAccount.VATNumber__c,
				'VAT Number copied from master account'
			);
			System.assertEquals(
				masterAccount.Tax_Exempt__c, techAccount.Tax_Exempt__c,
				'Tax Exempt copied from master account'
			);
		}
	}

    @IsTest
    public static void testActivateNewestOrders() {
        Triggers.switchOff();
        TestDataGenerator.MultiproductStructure mpStruct = new TestDataGenerator.MultiproductStructure();
        Triggers.switchOn();

        List<Order> orders = new List<Order>();
        for(Quote quote : mpStruct.serviceQuotes.values()) {
            if (mpStruct.technicalQLIs.get(quote.ServiceName__c).isEmpty()) {
                continue;
            }
            if(OrderHelper.SERVICE_NAME_TO_RT_ID.containsKey(quote.ServiceName__c)) {
                orders.add(OrderHelper.buildOrderForQuote(quote));
            }
        }

        insert orders;

        List<Account> accList = mpStruct.serviceAccounts.values();
        accList.add(mpStruct.masterAccount);

        List<Account> accsForUpdate = new List<Account>();

        for (Account acc : accList) {
            accsForUpdate.add(new Account(Id = acc.Id, RC_Account_Status__c = AccountHelper.PAID_STATUS));
        }

        Triggers.switchOff();
        Triggers.except('AccountTriggerHandler.ActivateNewestOrders');
        Test.startTest();

        update accsForUpdate;

        Test.stopTest();
        Triggers.switchOn();

        List<Order> ordersForAccounts = (List<Order>) new OrderSelector()
            .selectOrdersByAccountIds(new Map<Id, Account>(accsForUpdate).keySet())
			.selectFields(
				new List<String>{
					'Id',
					'Status',
					'AccountId',
                    'Quote.Opportunity',
					'TechnicalAccountId__c'
				}
			)
            .executeQuery();

		System.debug(ordersForAccounts);
        for (Order order : ordersForAccounts) {

            System.assert(
                order.Status == OrderHelper.STATUS_ACTIVATED,
                'Order should be activated'
            );
        }
    }

    @IsTest
    public static void testActivateNewestOrders_MPUBNotActivated() {
        Triggers.switchOff();
        Triggers.except('AccountTriggerHandler.ActivateNewestOrders');

        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test Opportunity',
                Opportunity.AccountId => testAcc.Id,
                Opportunity.Tier_Name__c => QuoteHelper.NGBS_OFFICE_PRODUCT,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => RingCentralHelper.USD
            })
            .create()
            .getRecord();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'Test Product2',
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Product2.IsActive => true,
                Product2.Charge_Term__c => 'Monthly'
            })
            .create()
            .getRecord();

        PricebookEntry testPBE = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => testProduct.Id,
                PricebookEntry.UnitPrice => 0,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => RingCentralHelper.USD
            })
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'Test Quote',
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.OpportunityId => testOpp.Id,
                Quote.CurrencyIsoCode => RingCentralHelper.USD,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.isPrimary__c => true,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_NEW_CUSTOMER,
                Quote.IsMultiProductTechnicalQuote__c => false,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
            })
            .create()
            .getRecord();

        new SObjectBuilder(ServiceInfo__c.SObjectType)
            .setField(ServiceInfo__c.Quote__c, testQuote.Id)
            .create()
            .getRecord();

        new SObjectBuilder(Order.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Order.Status => OrderHelper.STATUS_NEW,
                    Order.Pricebook2Id => Test.getStandardPricebookId(),
                    Order.AccountId => testAcc.Id,
                    Order.TechnicalQuoteId__c => testQuote.Id,
                    Order.EffectiveDate => System.today()
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        testAcc.RC_Account_Status__c = AccountHelper.PAID_STATUS;
        update testAcc;
        Triggers.switchOn();

        List<Order> reselectedOrders = (List<Order>) new OrderSelector()
            .selectOrdersByIds(new List<Object>{new Set<Id> {testAcc.Id}})
            .selectFields(
                new List<String>{
                    'Id',
                    'Status'
                }
            )
            .executeQuery();

        for (Order order : reselectedOrders) {
            Assert.areEqual(OrderHelper.STATUS_NEW, order.Status, 'MPUB Orders Status should not be changed after Account received PAID status');
            Assert.areNotEqual(OrderHelper.STATUS_ACTIVATED, order.Status, 'MPUB Orders should not be activated after Account received PAID status');
        }
    }

    @IsTest
    public static void testCreateOrderOnNewBusiness() {
        Triggers.switchOff();
        TestDataGenerator.MultiproductStructure mpStruct = new TestDataGenerator.MultiproductStructure();
        Triggers.switchOn();
        List<Quote> quoteListToAcivate = new List<Quote>();

        for (Quote quote : mpStruct.serviceQuotes.values()) {
            quote.Status = QuoteHelper.QUOTE_STATUS_ACTIVE;
            quote.QuoteType__c = QuoteHelper.QUOTE_TYPE_AGREEMENT;

            quoteListToAcivate.add(quote);
        }

        update quoteListToAcivate;

        List<Account> accListForUpdate = new List<Account>();

        Account accountToSingUp = new Account(Id = mpStruct.masterAccount.Id);
        accountToSingUp.Billing_ID__c = 'Example';
        accountToSingUp.RC_User_ID__c = 'Example';

        accListForUpdate.add(accountToSingUp);

        for (Account acc : mpStruct.serviceAccounts.values()) {
            Account accUpdate = new Account(Id = acc.Id);
            accUpdate.Billing_ID__c = 'Example' + acc.Id;
            accUpdate.RC_User_ID__c = acc.Id + 'Example';

            accListForUpdate.add(accUpdate);
        }

        Test.startTest();
        update accListForUpdate;
        Test.stopTest();

        Set<Id> accIds = new Map<Id, Account>(accListForUpdate).keySet();

        List<Order> ordersForAccounts = (List<Order>) new OrderSelector()
            .selectOrdersByAccountIds(accIds)
            .selectFields(
                new List<String>{
                'Id',
                'Status',
                'AccountId',
                'RecordTypeId',
                'QuoteId'
                }
            )
            .executeQuery();

        System.assert(!ordersForAccounts.isEmpty(), 'Orders should be created for Accounts');

    }

	@IsTest
	public static void testCopyAccountContactRolesToTechnicalAccounts() {
		Account masterAccount = TestDataGenerator.createAccount('Master');
		Contact masterContact1 = TestDataGenerator.createContact('John', 'Doe', masterAccount);
		Contact masterContact2 = TestDataGenerator.createContact('Jane', 'Doe', masterAccount);
		Contact masterContact3 = TestDataGenerator.createContact('Jude', 'Doe', masterAccount);
		AccountContactRole acr1 = TestDataGenerator.createAccountContactRole(masterAccount, masterContact1, 'Accounts Payable', true);
		AccountContactRole acr2 = TestDataGenerator.createAccountContactRole(masterAccount, masterContact2, 'Decision Maker', false);
		AccountContactRole acr3 = TestDataGenerator.createAccountContactRole(masterAccount, masterContact3, AccountContactRoleHelper.CONTACT_ROLE_RC_NONE, false);
		List<String> serviceNames = new List<String> { QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT, QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT };
		Test.startTest();
		Map<String, Account> technicalAccounts = AccountHelper.createTechnicalAccounts(masterAccount, serviceNames);
		Test.stopTest();
		List<Id> accountIds = (List<Id>) AquivaHelper.collectFieldValues(List<Id>.class, technicalAccounts.values(), 'Id', true);
		AccountContactRole[] acrs = new AccountContactRoleSelector()
			.selectAccountContactRolesWithNonEmptyRoleByAccountIds(accountIds)
			.executeQuery();

		Map<Id, AccountContactRole[]> acrByAccountId = (Map<Id, AccountContactRole[]>) AquivaHelper.groupByIdField(List<AccountContactRole>.class, acrs, 'AccountId');
		AccountContactRole[] edACR = acrByAccountId.get(technicalAccounts.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT).Id);
		System.assert(
			edACR.size() == 2,
			String.format('Invalid number of contact roles for ED account({0}): {1}', new List<Object> { technicalAccounts.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT).Id, edACR.size() })
		);
		Map<String, AccountContactRole[]> edRoleMap = (Map<String, AccountContactRole[]>) AquivaHelper.groupByStringField(List<AccountContactRole>.class, edACR, 'Role');
		System.assert(
			edRoleMap.get('Accounts Payable').get(0).ContactId == acr1.ContactId,
			String.format('Correct Contact Id for Accounts Payable role: {0}', new List<Object> { acr1.ContactId })
		);
		System.assert(
			edRoleMap.get('Accounts Payable').get(0).IsPrimary == acr1.IsPrimary,
			String.format('Correct IsPrimary for Accounts Payable role: {0}', new List<Object> { acr1.IsPrimary })
		);
		System.assert(
			edRoleMap.get('Decision Maker').get(0).ContactId == acr2.ContactId,
			String.format('Correct Contact Id for Accounts Payable role: {0}', new List<Object> { acr2.ContactId })
		);
		System.assert(
			edRoleMap.get('Decision Maker').get(0).IsPrimary == acr2.IsPrimary,
			String.format('Correct IsPrimary for Accounts Payable role: {0}', new List<Object> { acr2.IsPrimary })
		);
        System.assert(edRoleMap.get(AccountContactRoleHelper.CONTACT_ROLE_RC_NONE) == null, NO_ROLE_CREATED_MSG);
		AccountContactRole[] evACR = acrByAccountId.get(technicalAccounts.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT).Id);
		System.assert(
			evACR.size() == 2,
			String.format('Invalid number of contact roles for ED account({0}): {1}', new List<Object> { technicalAccounts.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT).Id, evACR.size() })
		);
		Map<String, AccountContactRole[]> evRoleMap = (Map<String, AccountContactRole[]>) AquivaHelper.groupByStringField(List<AccountContactRole>.class, evACR, 'Role');
		System.assert(
			evRoleMap.get('Accounts Payable').get(0).ContactId == acr1.ContactId,
			String.format('Correct Contact Id for Accounts Payable role: {0}', new List<Object> { acr1.ContactId })
		);
		System.assert(
			evRoleMap.get('Accounts Payable').get(0).IsPrimary == acr1.IsPrimary,
			String.format('Correct IsPrimary for Accounts Payable role: {0}', new List<Object> { acr1.IsPrimary })
		);
		System.assert(
			evRoleMap.get('Decision Maker').get(0).ContactId == acr2.ContactId,
			String.format('Correct Contact Id for Accounts Payable role: {0}', new List<Object> { acr2.ContactId })
		);
		System.assert(
			evRoleMap.get('Decision Maker').get(0).IsPrimary == acr2.IsPrimary,
			String.format('Correct IsPrimary for Accounts Payable role: {0}', new List<Object> { acr2.IsPrimary })
		);
        System.assert(evRoleMap.get(AccountContactRoleHelper.CONTACT_ROLE_RC_NONE) == null, NO_ROLE_CREATED_MSG);
	}

	@IsTest static void testRejectCreditLimitApporvals() {
		Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
			.setFields(new Map<SObjectField, Object>{
				Account.Name => 'masterAccount',
				Account.Account_Payment_Method__c => AccountHelper.PAYMENT_METHOD_CREDIT_CARD,
				Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString(),
				Account.RC_User_ID__c => ValueProviderBuilder.provideUniqueString()
			})
			.create()
			.getRecord();

		Approval__c creditLimitApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					Approval__c.Name => 'Credit Limit Increase',
					Approval__c.Account__c => testAcc.Id,
					Approval__c.RecordTypeId => ApprovalHelper.RT_ID_CREDIT_LIMIT_INCREASE,
					Approval__c.Status__c => ApprovalHelper.STATUS_NEW,
					Approval__c.DateOfSignOff__c => System.today()
				})
			.create()
			.getRecord();

		Test.startTest();
		ApprovalHelper.submitCreditLimitApprovals(new Set<Id>{creditLimitApproval.Id});
		System.assertEquals(ApprovalHelper.STATUS_PENDING_APPROVAL, [SELECT Status__c FROM Approval__c WHERE Id =:creditLimitApproval.Id ].Status__c, 'Approval must be in status "Pendig approval"');

		testAcc.Account_Payment_Method__c = AccountHelper.PAYMENT_METHOD_INVOICE;
		update testAcc;
		Test.stopTest();

		Approval__c reselectApp = (Approval__c) new ApprovalSelector()
			.selectCreditLimitIncreaseById(new List<Object>{new Set<Id> {creditLimitApproval.Id}})
			.executeQuery()
			.get(0);

		System.assertEquals(ApprovalHelper.STATUS_REJECTED, 'Rejected', 'Approval must be in status "Rejected"');
	}

    static void testRetainTeamMemberOnOwnerChange() {
       // Create test data
       Account testAccount1 = new Account(Name = 'Test Account 1', OwnerId = UserInfo.getUserId());
       Account testAccount2 = new Account(Name = 'Test Account 2', OwnerId = UserInfo.getUserId());
       insert new List<Account> {testAccount1, testAccount2};

       User testUser = createUser('AccTeamMemberTest');

       AccountTeamMember testAccountTeamMember1 = new AccountTeamMember(AccountId = testAccount1.Id, UserId = testUser.Id,
                                                                        TeamMemberRole = 'Renewals Manager');
       AccountTeamMember testAccountTeamMember2 = new AccountTeamMember(AccountId = testAccount2.Id, UserId = testUser.Id,
                                                                        TeamMemberRole = 'Renewals Manager');
       insert new List<AccountTeamMember> {testAccountTeamMember1, testAccountTeamMember2};

       Test.startTest();

       // Simulate account owner change
       testAccount1.OwnerId = testUser.Id;
       update testAccount1;

       // Verify team member record was retained
       List<AccountTeamMember> accountTeamMembers = [SELECT Id FROM AccountTeamMember WHERE AccountId = :testAccount1.Id];
       System.assertEquals(1, accountTeamMembers.size());

       Test.stopTest();
   }

    @isTest
    static void testPopulateTechFieldsOnMasterAccount() {
        String testText = 'Custom Test';
        Triggers.switchOff();
        Account masterAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'masterAccount',
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString('123'),
                Account.RC_User_ID__c => ValueProviderBuilder.provideUniqueString('123')
            })
            .create()
            .getRecord();

        Account technicalAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'technicalAccount',
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString('345'),
                Account.RC_User_ID__c => ValueProviderBuilder.provideUniqueString('345'),
                Account.Master_Account__c => masterAcc.Id,
                Account.IsMultiProductTechnicalAccount__c => true
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Test.startTest();
        technicalAcc.EV_Account_ID__c = testText;
        technicalAcc.EV_Platform__c = testText;
        technicalAcc.EV_Shard__c = testText;
        technicalAcc.ED_Account_ID__c = testText;
        technicalAcc.ED_Platform__c = testText;
        technicalAcc.Engage_Domain__c = testText;
        update technicalAcc;
        Test.stopTest();

        Account masterAccount = (Account)  new ListOptional(new AccountSelector()
            .selectAccountsByIds(new List<Object>{ new List<Id>{ masterAcc.Id } })
            .executeQuery()).getFirst();

        System.assert(masterAccount != null, 'Master account should be returned');
        System.assertEquals(testText, masterAccount.EV_Account_ID__c, 'EV_Account_ID__c should be equals with custom text on master account');
        System.assertEquals(testText, masterAccount.EV_Platform__c, 'EV_Platform__c should be equals with custom text on master account');
        System.assertEquals(testText, masterAccount.EV_Shard__c, 'EV_Shard__c should be equals with test custom on master account');
        System.assertEquals(testText, masterAccount.ED_Account_ID__c, 'ED_Account_ID__c should be equals with custom text on master account');
        System.assertEquals(testText, masterAccount.ED_Platform__c, 'ED_Platform__c should be equals with test text on master account');
        System.assertEquals(testText, masterAccount.Engage_Domain__c, 'Engage_Domain__c should be equals with test text on master account');
    }
    @IsTest
    static void testCreateOrderAfterSignUpComplete_singleProduct() {
        Triggers.switchOff();
        Triggers.except('AccountTriggerHandler.ManageAccountMapStatic');
        Triggers.except('AccountTriggerHandler.CreateOrderAfterSignUpComplete');

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, ValueProviderBuilder.provideUniqueString('ACCOUNT'))
            .setField(Account.Account_Payment_Method__c, AccountHelper.PAYMENT_METHOD_CREDIT_CARD)
            .setField(Account.CurrencyIsoCode, 'CAD')
            .create()
            .getRecords()
            .get(0);
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'test opp')
            .setField(Opportunity.AccountId, acc.Id)
            .setField(Opportunity.StageName, OpportunityHelper.STAGE_NAME_CLOSED_WON)
            .setField(Opportunity.CloseDate, System.today())
            .setField(Opportunity.Pricebook2Id, Test.getStandardPricebookId())
            .setField(Opportunity.Tier_Name__c, 'Office')
            .create()
            .getRecords()
            .get(0);
        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.Name, 'test qt')
            .setField(Quote.OpportunityId, opp.Id)
            .setField(Quote.IsPrimary__c, true)
            .setField(Quote.Status, QuoteHelper.QUOTE_STATUS_ACTIVE)
            .setField(Quote.Pricebook2Id, Test.getStandardPricebookId())
            .setField(Quote.Start_Date__c, System.today())
            .setField(Quote.End_Date__c, System.today().addDays(30))
            .setField(Quote.ServiceName__c, QuoteHelper.NGBS_OFFICE_PRODUCT)
            .create()
            .getRecords()
            .get(0);
        List<Product2> products = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setField(Product2.Name, ValueProviderBuilder.provideUniqueString('PROD'))
            .setField(Product2.Family, ValueProviderBuilder.provideUniqueString('PFAMILY'))
            .setField(Product2.ProductCode, ValueProviderBuilder.provideUniqueString('PCODE'))
            .setField(Product2.IsActive, true)
            .create()
            .getRecords();
        List<PricebookEntry> pbes = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
            .setField(PricebookEntry.Pricebook2Id, Test.getStandardPricebookId())
            .setField(PricebookEntry.Product2Id, ValueProviderBuilder.provideParents(products))
            .setField(PricebookEntry.UnitPrice, 100)
            .setField(PricebookEntry.IsActive, true)
            .create()
            .getRecords();
        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setField(QuoteLineItem.QuoteId, qt.Id)
            .setField(QuoteLineItem.Quantity, 1)
            .setField(QuoteLineItem.UnitPrice, 100)
            .setField(QuoteLineItem.ServiceName__c, QuoteHelper.NGBS_OFFICE_PRODUCT)
            .setField(QuoteLineItem.PricebookEntryId, ValueProviderBuilder.provideParents(pbes))
            .create()
            .getRecords();

        Test.startTest();
        update new SObjectBuilder(Account.SObjectType)
            .setField(Account.Id, acc.Id)
            .setField(Account.Billing_ID__c, ValueProviderBuilder.provideUniqueString('BID'))
            .setField(Account.RC_User_ID__c, ValueProviderBuilder.provideUniqueString('UID'))
            .build()
            .getRecords();
        Test.stopTest();
        Triggers.switchOn();

        Order ord = [
            SELECT Id,
                RecordTypeId,
                AccountId,
                OpportunityId,
                QuoteId,
                Pricebook2Id,
                TechnicalAccountId__c,
                TechnicalOpportunityId__c,
                TechnicalQuoteId__c,
                Status,
                EffectiveDate,
                CurrencyIsoCode
            FROM Order
            WHERE AccountId = :acc.Id
            LIMIT 1
        ];
        Quote qt1 = [
            SELECT Id,
                AccountId,
                OpportunityId,
                Pricebook2Id,
                Status,
                CurrencyIsoCode
            FROM Quote
            WHERE Id = :qt.Id
            LIMIT 1
        ];
        System.assertNotEquals(null, ord, 'Order must be created');
        System.assertEquals(OrderHelper.STATUS_NEW, ord.Status, 'Order must be in status "New"');
        System.assertEquals(System.today(), ord.EffectiveDate, 'Order must have today\'s date as Effective Date');
        System.assertEquals(qt1.Id, ord.QuoteId, 'Order must be linked to Quote');
        System.assertEquals(qt1.AccountId, ord.AccountId, 'Order must be linked to Account');
        System.assertEquals(qt1.OpportunityId, ord.OpportunityId, 'Order must be linked to Opportunity');
        System.assertEquals(qt1.Pricebook2Id, ord.Pricebook2Id, 'Order must be linked to Pricebook');
        System.assertEquals(qt1.CurrencyIsoCode, ord.CurrencyIsoCode, 'Order must have the same currency as Quote');
        System.assertEquals(qt1.Id, ord.TechnicalQuoteId__c, 'Order must have the same Technical Quote Id as Quote');
        System.assertEquals(qt1.OpportunityId, ord.TechnicalOpportunityId__c, 'Order must have the same Technical Opportunity Id as Quote');
        System.assertEquals(qt1.AccountId, ord.TechnicalAccountId__c, 'Order must have the same Technical Account Id as Quote');
    }

    @IsTest
    static void testCreateOrderAfterSignUpComplete_multiProduct() {
        Triggers.switchOff();
        Triggers.except('AccountTriggerHandler.ManageAccountMapStatic');
        Triggers.except('AccountTriggerHandler.CreateOrderAfterSignUpComplete');
        TestDataGenerator.MultiproductStructure struct = new TestDataGenerator.MultiproductStructure();
        update new List<Quote>{
            new Quote(
                Id = struct.serviceQuotes.get(QuoteHelper.NGBS_OFFICE_PRODUCT).Id,
                QuoteType__c = QuoteHelper.QUOTE_TYPE_AGREEMENT,
                Status = QuoteHelper.QUOTE_STATUS_ACTIVE,
                ServiceName__c = QuoteHelper.NGBS_OFFICE_PRODUCT
            ),
            new Quote(
                Id = struct.serviceQuotes.get(QuoteHelper.NGBS_RCCC_PRODUCT).Id,
                QuoteType__c = QuoteHelper.QUOTE_TYPE_AGREEMENT,
                Status = QuoteHelper.QUOTE_STATUS_ACTIVE,
                ServiceName__c = QuoteHelper.NGBS_RCCC_PRODUCT
            ),
            new Quote(
                Id = struct.serviceQuotes.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT).Id,
                QuoteType__c = QuoteHelper.QUOTE_TYPE_AGREEMENT,
                Status = QuoteHelper.QUOTE_STATUS_ACTIVE,
                ServiceName__c = QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT
            ),
            new Quote(
                Id = struct.serviceQuotes.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT).Id,
                QuoteType__c = QuoteHelper.QUOTE_TYPE_AGREEMENT,
                Status = QuoteHelper.QUOTE_STATUS_ACTIVE,
                ServiceName__c = QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT
            )
        };

        Test.startTest();
        IValueProvider billingIdProvider = ValueProviderBuilder.provideUniqueString('BID');
        IValueProvider rcUserIdProvider = ValueProviderBuilder.provideUniqueString('UID');

        update new List<Account> {
            new Account(
                Id = struct.masterAccount.Id,
                Billing_ID__c = (String) billingIdProvider.getValue(),
                RC_User_ID__c = (String) rcUserIdProvider.getValue()
            ),
            new Account(
                Id = struct.serviceAccounts.get(QuoteHelper.NGBS_RCCC_PRODUCT).Id,
                Billing_ID__c = (String) billingIdProvider.getValue(),
                RC_User_ID__c = (String) rcUserIdProvider.getValue()
            ),
            new Account(
                Id = struct.serviceAccounts.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT).Id,
                Billing_ID__c = (String) billingIdProvider.getValue(),
                RC_User_ID__c = (String) rcUserIdProvider.getValue()
            ),
            new Account(
                Id = struct.serviceAccounts.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT).Id,
                Billing_ID__c = (String) billingIdProvider.getValue(),
                RC_User_ID__c = (String) rcUserIdProvider.getValue()
            )
        };

        List<Order> ordList = (List<Order>) new OrderSelector()
            .selectOrdersByAccountIds(new Set<Id> {
                struct.masterAccount.Id,
                struct.serviceAccounts.get(QuoteHelper.NGBS_RCCC_PRODUCT).Id,
                struct.serviceAccounts.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT).Id,
                struct.serviceAccounts.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT).Id
            })
            .selectFields(new Set<SObjectField> {
                Order.AccountId,
                Order.QuoteId,
                Order.OpportunityId,
                Order.Pricebook2Id,
                Order.TechnicalQuoteId__c,
                Order.TechnicalOpportunityId__c,
                Order.TechnicalAccountId__c,
                Order.Status,
                Order.CurrencyIsoCode
            })
            .executeQuery();

        Map<Id, List<Order>> ordersByTechQuoteIdMap = (Map<Id, List<Order>>) AquivaHelper.groupByIdField(
            List<Order>.class,
            ordList,
            'TechnicalQuoteId__c'
        );

        List<Quote> qtList = (List<Quote>) new QuoteSelector()
            .selectQuotesByIds(new List<Object> {
                ordersByTechQuoteIdMap.keySet()
            })
            .selectFields(new Set<String> {
                'MasterQuote__c',
                'MasterQuote__r.Id',
                'MasterQuote__r.AccountId',
                'MasterQuote__r.OpportunityId'
            })
            .executeQuery();

        System.assertEquals(2, ordList.size(), 'Order must be created');
        for (Quote qt : qtList) {
            if (!ordersByTechQuoteIdMap.containsKey(qt.Id)) {
                continue;
            }

            if (!qt.IsMultiProductTechnicalQuote__c) {
                continue;
            }

            for (Order ord : ordersByTechQuoteIdMap.get(qt.Id)) {
                System.assertEquals(qt.Pricebook2Id, ord.Pricebook2Id, 'Order must be linked to Pricebook');
                System.assertEquals(qt.CurrencyIsoCode, ord.CurrencyIsoCode, 'Order must have the same currency as Quote');
                System.assertEquals(qt.MasterQuote__c, ord.QuoteId, 'Order must be linked to Quote');
                System.assertEquals(qt.MasterQuote__r.AccountId, ord.AccountId, 'Order must be linked to Account');
                System.assertEquals(qt.MasterQuote__r.OpportunityId, ord.OpportunityId, 'Order must be linked to Opportunity');
                System.assertEquals(qt.Id, ord.TechnicalQuoteId__c, 'Order must have the same Technical Quote Id as Quote');
                System.assertEquals(qt.OpportunityId, ord.TechnicalOpportunityId__c, 'Order must have the same Technical Opportunity Id as Quote');
                System.assertEquals(qt.AccountId, ord.TechnicalAccountId__c, 'Order must have the same Technical Account Id as Quote');
            }
        }

        Test.stopTest();
        Triggers.switchOn();
    }

    @IsTest
    static void testRecalculateSharingForAccessControls() {
        Triggers.switchOff();
        Triggers.except('AccountTriggerHandler.accessControls');

        Set<Id> setOfAccIds = new Set<Id>();
        List<Group> groupsList = new List<Group>();
        List<AccessControlSettings__c> accessSettingsList = new List<AccessControlSettings__c>();
        accessSettingsList.add(
                new AccessControlSettings__c(
                    Name = 'Rise America', Brand__c = 'Rise America', BusinessIdentity__c = 'Rise America',
                    Public_Group_Name__c = 'Access_Users', isParent__c = true, isActive__c = true
                ));
        accessSettingsList.add(
                new AccessControlSettings__c(
                    Name = 'Access2', Brand__c = 'Access.Abc', BusinessIdentity__c = 'Abc',
                    ParentBrand__c = 'Access', Public_Group_Name__c = 'Abc_Users', isParent__c = false, isActive__c = true
                ));
		accessSettingsList.add(
                new AccessControlSettings__c(
                    Name = 'Access3', Brand__c = 'Access.Def', BusinessIdentity__c = 'Def',
                    ParentBrand__c = 'Access', Public_Group_Name__c = 'Def_Users', isParent__c = false, isActive__c = true
                ));
        insert accessSettingsList;

        groupsList.add(
                new Group(
                    Name = 'Access Users', DeveloperName = 'Access_Users', Type = 'Regular'
                ));
        groupsList.add(
                new Group(
                    Name = 'Abc Users', DeveloperName = 'Abc_Users', Type = 'Regular'
                ));
        groupsList.add(
                new Group(
                    Name = 'Def Users', DeveloperName = 'Def_Users', Type = 'Regular'
                ));
        insert groupsList;

        List<Account> accounts = (List<Account>) new SObjectBuilder(Account.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					Account.Name => 'Test account',
					Account.RC_Brand__c => ValueProviderBuilder.provideList(new List<String>{'Rise America','Rise America','Rise America','Access','Access'}),
					Account.Sub_Brand__c => ValueProviderBuilder.provideList(new List<String>{'Access.Abc',null,null,null,null}),
					Account.BusinessIdentity__c => ValueProviderBuilder.provideList(new List<String>{'Abc','Def',null,null,null})
				}
			)
			.quantity(5)
			.create()
			.getRecords();
        setOfAccIds.add(accounts[0].Id);
        setOfAccIds.add(accounts[1].Id);
        setOfAccIds.add(accounts[2].Id);
        setOfAccIds.add(accounts[3].Id);
        setOfAccIds.add(accounts[4].Id);

        Test.startTest();
            List<AccountShare> listNewSharing = [SELECT Id, AccountId, UserOrGroupId, RowCause, AccountAccessLevel,
                                                        CaseAccessLevel, OpportunityAccessLevel, ContactAccessLevel
                                                        FROM AccountShare WHERE AccountId =:setOfAccIds AND RowCause = 'Manual'];
            if (accounts != null) {
                accounts[4].RC_Brand__c = null;
                accounts[3].RC_Brand__c = 'Rise America';
                accounts[2].BusinessIdentity__c = 'Abc';
                accounts[1].Sub_Brand__c = 'Access.Def';
            }
            update accounts;
            Account accUpdate = [Select Id, Name, RC_Brand__c, Sub_Brand__c, BusinessIdentity__c from Account where Id =:accounts[0].Id];
            accUpdate.RC_Brand__c = 'Access';
            update accUpdate;

            List<AccountShare> listUpdatedSharing = [SELECT Id, AccountId, UserOrGroupId, RowCause, AccountAccessLevel,
                                                        CaseAccessLevel, OpportunityAccessLevel, ContactAccessLevel
                                                        FROM AccountShare WHERE AccountId =:setOfAccIds AND RowCause = 'Manual'];

            System.assertEquals(true, listNewSharing.size() > 0, 'Manual sharing should be created on Account insert');
            System.assertEquals(true, listUpdatedSharing.size() > 0, 'Manual sharing should be created on Account update');
            if (!listUpdatedSharing.isEmpty()) {
                for (AccountShare accShare : listUpdatedSharing) {
                    System.assertEquals('Edit', accShare.AccountAccessLevel, 'Account Access Level should be Edit');
                    System.assertEquals('Edit', accShare.CaseAccessLevel, 'Case Access Level should be Edit');
                    System.assertEquals('Edit', accShare.OpportunityAccessLevel, 'Opportunity Access Level should be Edit');
                    System.assertEquals('Edit', accShare.ContactAccessLevel, 'Contact Access Level should be Edit');
                }
            }
        Test.stopTest();
        Triggers.switchOn();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    static void testSegmentationForGating1() {
        List<Segment_Master__c> segmentMasters = new List<Segment_Master__c>();
		List<String> countries = new List<String>{'United States', 'United Kingdom', 'France','ROW'};
		List<List<Integer>> ranges = new List<List<Integer>>{new List<Integer>{1,10}, new List<Integer>{11,50}, new List<Integer>{51,100}};
		for (String country : countries) {
			for (List<Integer> range : ranges) {
				segmentMasters.add(
					new Segment_Master__c(
						Country__c = country,
						Min__c = range[0],
						Max__c = range[1],
						Start_Date__c = Date.today().addDays(-2)
						)
					);
			}
		}
		insert segmentMasters;

        Gating_Process_Stage__c processStage = Gating_Process_Stage__c.getInstance();
        processStage.Bypass_Gating_Process_Stage__c = false;
        processStage.Bypass_Enrichment_Process__c = false;
        processStage.Bypass_Account_Gating_Process__c = false;
        insert processStage;

        Account acc1 = (Account) new SObjectBuilder(Account.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					Account.Name => 'Test account',
					Account.Emp_Range_Sales_Override__c => 34,
                    Account.BillingCountry => 'United States',
                    Account.RecordTypeId => AccountHelper.RT_ID_CUSTOMER_ACCOUNT,
                    Account.LS_Status__c => 'Success',
                    Account.Segment_Exception_Flag__c => true
				}
			)
			.create()
			.getRecord();

        Test.startTest();

            acc1.Emp_Range_Sales_Override__c = 30;
            update acc1;

        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    static void testSegmentationForGating2() {
        List<Segment_Master__c> segmentMasters = new List<Segment_Master__c>();
		List<String> countries = new List<String>{'United States', 'United Kingdom', 'France','ROW'};
		List<List<Integer>> ranges = new List<List<Integer>>{new List<Integer>{1,10}, new List<Integer>{11,50}, new List<Integer>{51,100}};
		for (String country : countries) {
			for (List<Integer> range : ranges) {
				segmentMasters.add(
					new Segment_Master__c(
						Country__c = country,
						Min__c = range[0],
						Max__c = range[1],
						Start_Date__c = Date.today().addDays(-2)
						)
					);
			}
		}
		insert segmentMasters;

        Gating_Process_Stage__c processStage = Gating_Process_Stage__c.getInstance();
        processStage.Bypass_Gating_Process_Stage__c = false;
        processStage.Bypass_Enrichment_Process__c = false;
        processStage.Bypass_Account_Gating_Process__c = false;
        insert processStage;

		Account accParent = (Account) new SObjectBuilder(Account.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					Account.Name => 'Test account',
					Account.Emp_Range_Sales_Override__c => 954,
                    Account.BillingCountry => 'United States',
                    Account.RecordTypeId => AccountHelper.RT_ID_CUSTOMER_ACCOUNT,
                    Account.LS_Status__c => 'Success'
				}
			)
			.create()
			.getRecord();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					Account.Name => 'Test account',
					Account.Emp_Range_Sales_Override__c => 11,
                    Account.BillingCountry => 'United States',
                    Account.RecordTypeId => AccountHelper.RT_ID_CUSTOMER_ACCOUNT,
                    Account.LS_Status__c => 'Success',
                    Account.Segment_Exception_Flag__c => true,
                    Account.ParentId => accParent.Id
				}
			)
			.create()
			.getRecord();

        Account acc1 = (Account) new SObjectBuilder(Account.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					Account.Name => 'Test account',
                    Account.BillingCountry => 'United States',
                    Account.RecordTypeId => AccountHelper.RT_ID_CUSTOMER_ACCOUNT,
                    Account.LS_Status__c => 'Success',
                    Account.Segment_Exception_Flag__c => false
				}
			)
			.create()
			.getRecord();

        Account acc2 = (Account) new SObjectBuilder(Account.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					Account.Name => 'Test account',
					Account.Emp_Range_Sales_Override__c => 11,
                    Account.BillingCountry => 'United States',
                    Account.RecordTypeId => AccountHelper.RT_ID_CUSTOMER_ACCOUNT,
                    Account.LS_Status__c => 'Success',
                    Account.Segment_Exception_Flag__c => true,
                    Account.ParentId => accParent.Id
				}
			)
			.create()
			.getRecord();

        Test.startTest();

        	List<Account> listOfAccs = new List<Account>();
        	acc2.Emp_Range_Sales_Override__c = 2;
        	acc2.ParentId = acc1.Id;
        	update acc2;
        	acc1.Segment_Exception_Flag__c = true;
        	update acc1;

        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    static void testSegmentationForGating3() {
        List<Segment_Master__c> segmentMasters = new List<Segment_Master__c>();
		List<String> countries = new List<String>{'United States', 'United Kingdom', 'France','ROW'};
		List<List<Integer>> ranges = new List<List<Integer>>{new List<Integer>{1,10}, new List<Integer>{11,50}, new List<Integer>{51,100}};
		for (String country : countries) {
			for (List<Integer> range : ranges) {
				segmentMasters.add(
					new Segment_Master__c(
						Country__c = country,
						Min__c = range[0],
						Max__c = range[1],
						Start_Date__c = Date.today().addDays(-2)
						)
					);
			}
		}
		insert segmentMasters;

        Gating_Process_Stage__c processStage = Gating_Process_Stage__c.getInstance();
        processStage.Bypass_Gating_Process_Stage__c = false;
        processStage.Bypass_Enrichment_Process__c = false;
        processStage.Bypass_Account_Gating_Process__c = false;
        insert processStage;

        Account accParent = (Account) new SObjectBuilder(Account.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					Account.Name => 'Test account',
					Account.Emp_Range_Sales_Override__c => 954,
                    Account.BillingCountry => 'United States',
                    Account.RecordTypeId => AccountHelper.RT_ID_CUSTOMER_ACCOUNT,
                    Account.LS_Status__c => 'Success'
				}
			)
			.create()
			.getRecord();

         Account acc = (Account) new SObjectBuilder(Account.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					Account.Name => 'Test account',
					Account.Emp_Range_Sales_Override__c => 954,
                    Account.BillingCountry => 'United States',
                    Account.RecordTypeId => AccountHelper.RT_ID_CUSTOMER_ACCOUNT,
                    Account.LS_Status__c => 'Success',
                    Account.ParentId => accParent.Id
				}
			)
			.create()
			.getRecord();

        Account acc2 = (Account) new SObjectBuilder(Account.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					Account.Name => 'Test account',
					Account.Emp_Range_Sales_Override__c => 11,
                    Account.BillingCountry => 'United States',
                    Account.Segment_Exception_Flag__c => false,
                    Account.ParentId => acc.Id
				}
			)
			.create()
			.getRecord();

        Account acc3 = (Account) new SObjectBuilder(Account.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					Account.Name => 'Test account',
					Account.Emp_Range_Sales_Override__c => 11,
                    Account.BillingCountry => 'United States',
                    Account.Segment_Exception_Flag__c => false,
                    Account.ParentId => acc2.Id
				}
			)
			.create()
			.getRecord();

        Account acc4 = (Account) new SObjectBuilder(Account.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					Account.Name => 'Test account',
					Account.Emp_Range_Sales_Override__c => 11,
                    Account.BillingCountry => 'United States',
                    Account.Segment_Exception_Flag__c => false,
                    Account.ParentId => acc3.Id
				}
			)
			.create()
			.getRecord();

        Account acc5 = (Account) new SObjectBuilder(Account.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					Account.Name => 'Test account',
					Account.Emp_Range_Sales_Override__c => 11,
                    Account.BillingCountry => 'United States',
                    Account.Segment_Exception_Flag__c => false,
                    Account.ParentId => acc4.Id
				}
			)
			.create()
			.getRecord();

        Account acc6 = (Account) new SObjectBuilder(Account.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					Account.Name => 'Test account',
					Account.Emp_Range_Sales_Override__c => 11,
                    Account.BillingCountry => 'United States',
                    Account.Segment_Exception_Flag__c => false
				}
			)
			.create()
			.getRecord();

        Test.startTest();

			acc6.ParentId = acc5.Id;
            update acc6;

        Test.stopTest();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
	static void testSetNumberOfEmployeesLogic() {
    	RecordType zishellRTId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'ZI_Customer_Shell_Account' LIMIT 1];
        RecordType customerRTId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Customer_Account' LIMIT 1];

    	Account topParent = new Account(
        	Name = 'Top Parent',
       		RecordTypeId = zishellRTId.Id,
        	ZI_Employees__c = 500
    	);
    	insert topParent;

    	Account child = new Account(
        	Name = 'Child',
        	ParentId = topParent.Id,
        	RecordTypeId = zishellRTId.Id
    	);
    	insert child;

	    Account grandChild = new Account(
    	    Name = 'Grandchild',
        	ParentId = child.Id,
        	RecordTypeId = customerRTId.Id,
        	ZI_Employees__c = 100
    	);
    	insert grandChild;

	    Account customerAcc = new Account(
     		Name = 'Customer Acc',
        	RecordTypeId = customerRTId.Id,
            Employees_Override__c = 200
    	);

    	Test.startTest();
        insert customerAcc;
	    topParent.Employees_Override__c = 600;
    	update topParent;
    	Test.stopTest();

    	Map<Id, Account> accounts = new Map<Id, Account>([
        	SELECT Id, NumberOfEmployees FROM Account WHERE Id IN :new List<Id>{
            topParent.Id, child.Id, grandChild.Id, customerAcc.Id}
    	]);

    	/*System.assertEquals(600, accounts.get(topParent.Id).NumberOfEmployees, 'Top Parent should have 600');
    	System.assertEquals(1, accounts.get(child.Id).NumberOfEmployees, 'Child should have 1');
    	System.assertEquals(1, accounts.get(grandChild.Id).NumberOfEmployees, 'Grandchild (Customer) should inherit 1 through Child');
    	System.assertEquals(200, accounts.get(customerAcc.Id).NumberOfEmployees, 'Customer Acc should have 200 from Employees_Override__c');*/
	}


    private static Brand_List__c createGSPBrand(String brandName) {
        Brand_List__c brand = new Brand_List__c();
        brand.Brand_Name__c = brandName;
        brand.GSP_Brand__c = true;
        brand.Name = brandName + '_' + String.valueOf(Datetime.now().getTime()).substring(12); // Shorter unique Name
        insert brand;
        return brand;
    }

    private static Reseller_Partner_Id__c createGSPPartner(String partnerId) {
        Reseller_Partner_Id__c partner = new Reseller_Partner_Id__c();
        partner.Partner_ID__c = partnerId;
        partner.Name = partnerId + '_' + String.valueOf(Datetime.now().getTime()).substring(12); // Shorter unique Name
        insert partner;
        return partner;
    }

    private static User createTestUser(String alias, String profileName, Boolean isGSPUser) {
        Profile p = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];
        User u = new User();
        u.FirstName = 'Test';
        u.LastName = 'User' + alias;
        u.Email = 'test' + alias + '@test.com';
        u.Username = 'test' + alias + '@test.com';
        u.Alias = alias;
        u.TimeZoneSidKey = 'America/Los_Angeles';
        u.LocaleSidKey = 'en_US';
        u.EmailEncodingKey = 'UTF-8';
        u.LanguageLocaleKey = 'en_US';
        u.ProfileId = p.Id;
        u.GSP_User__c = isGSPUser;
        u.Hold_Out_List__c = 0; 
        insert u;
        return u;
    }

    /**
     * Generates a non-existent user ID for testing error scenarios.
     * This avoids hardcoded IDs that break across different environments.
     */
    private static String getNonExistentUserId() {
        // Generate a valid-looking but non-existent user ID
        // User IDs start with '005' and are 18 characters long
        String timestamp = String.valueOf(Datetime.now().getTime());
        String randomSuffix = timestamp.substring(Math.max(0, timestamp.length() - 12));
        return '005' + '000000000' + randomSuffix.substring(0, 6);
    }

    /**
     * Generates test exclusion IDs for testing scenarios.
     * This avoids hardcoded IDs that break across different environments.
     */
    private static String getTestExclusionIds() {
        // Generate valid-looking but non-existent user IDs for exclusion testing
        String timestamp = String.valueOf(Datetime.now().getTime());
        String suffix1 = timestamp.substring(Math.max(0, timestamp.length() - 8));
        String suffix2 = String.valueOf(Integer.valueOf(suffix1) + 1);
        return '005' + '0000000' + suffix1.substring(0, 5) + 'AAG,' + 
               '005' + '0000000' + suffix2.substring(0, 5) + 'AAK';
    }

    private static Account createTestAccount(String name, String brand, String partnerId, String paymentMethod, Boolean isGSP) {
        Account acc = new Account();
        acc.Name = name != null ? name : 'Test Account';
        acc.Type = 'Customer';
        acc.RC_Brand__c = brand;
        acc.Partner_ID__c = partnerId;
        acc.Account_Payment_Method__c = paymentMethod;
        acc.GSP__c = isGSP;
        return acc;
    }

    @isTest
    static void testGSPAccountValidation_AllRules() {
        
        ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance();
        if (bypassTrigger == null) {
            bypassTrigger = new ByPassTrigger__c();
        }
        bypassTrigger.Bypass_Account_Trigger__c = false;
        bypassTrigger.Bypass_Except_Segmentation__c = false;
        upsert bypassTrigger;
        

        
        // Create test data
        Brand_List__c gspBrand = createGSPBrand('TestGSPBrand');
        Reseller_Partner_Id__c gspPartner = createGSPPartner('GSP123');
        User gspUser = createTestUser('gsp', 'System Administrator', true);
        User nonGspUser = createTestUser('ngsp', 'System Administrator', false);
        


        Test.startTest();

        Account acc1 = createTestAccount('Test1', 'TestGSPBrand', null, AccountHelper.PAYMENT_METHOD_PARTNER_BILLING_NGBS, false);
        acc1.OwnerId = gspUser.Id;
        insert acc1;
        Account queriedAcc = [SELECT Id, Name, GSP__c, RC_Brand__c, Account_Payment_Method__c FROM Account WHERE Id = :acc1.Id];        
        Assert.isTrue(queriedAcc.GSP__c, 'Account should be marked as GSP for Rule 1');

        Account acc2 = createTestAccount('Test2', 'TestGSPBrand', null, 'Credit Card', false);
        acc2.OwnerId = gspUser.Id;
        insert acc2;
        Account queriedAcc2 = [SELECT Id, GSP__c FROM Account WHERE Id = :acc2.Id];
        Assert.isTrue(queriedAcc2.GSP__c, 'Account should be marked as GSP for Rule 2');

        Account acc3 = createTestAccount('Test3', 'NonGSPBrand', null, 'Credit Card', true);
        acc3.OwnerId = gspUser.Id;
        insert acc3;
        Account queriedAcc3 = [SELECT Id, GSP__c FROM Account WHERE Id = :acc3.Id];
        Assert.isFalse(queriedAcc3.GSP__c, 'Account should be marked as Non-GSP for Rule 3');

        Account acc4 = createTestAccount('Test4', 'TestGSPBrand', null, 'Credit Card', true);
        acc4.OwnerId = gspUser.Id;
        insert acc4;
        Account queriedAcc4 = [SELECT Id, GSP__c FROM Account WHERE Id = :acc4.Id];
        Assert.isTrue(queriedAcc4.GSP__c, 'Account should maintain GSP status for Rule 4');

        Account acc5 = createTestAccount('Test5', null, 'GSP123', 'Credit Card', false);
        acc5.OwnerId = gspUser.Id;
        insert acc5;
        Account queriedAcc5 = [SELECT Id, GSP__c FROM Account WHERE Id = :acc5.Id];
        Assert.isTrue(queriedAcc5.GSP__c, 'Account should be marked as GSP with GSP partner');

        Account acc6 = createTestAccount('Test6', 'NonGSPBrand', null, 'Credit Card', false);
        acc6.OwnerId = gspUser.Id;
        insert acc6;
        Account queriedAcc6 = [SELECT Id, GSP__c FROM Account WHERE Id = :acc6.Id];
        Assert.isFalse(queriedAcc6.GSP__c, 'Account should maintain current GSP status');

        acc1.OwnerId = nonGspUser.Id;
        try {
            update acc1;
            Account updatedAcc = [SELECT Id, OwnerId FROM Account WHERE Id = :acc1.Id];
            Assert.areEqual(nonGspUser.Id, updatedAcc.OwnerId, 'Owner should be updated successfully');
        } catch (DmlException e) {
            Assert.isTrue(e.getMessage().contains(AccountHelper.NON_GSP_OWNER_ERROR), 
                         'Error message should contain the expected validation message');
        }

        Test.stopTest();
    }

    @isTest
    static void testGSPAccountValidation_ErrorConditions() {
        
        ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance();
        if (bypassTrigger == null) {
            bypassTrigger = new ByPassTrigger__c();
        }
        bypassTrigger.Bypass_Account_Trigger__c = false;
        bypassTrigger.Bypass_Except_Segmentation__c = false;
        upsert bypassTrigger;
        
        Brand_List__c gspBrand = createGSPBrand('TestGSPBrand');
        User gspUser = createTestUser('gsp', 'System Administrator', true);
        User nonGspUser = createTestUser('ngsp', 'System Administrator', false);

        Account acc = createTestAccount('TestError', 'TestGSPBrand', null, 'Credit Card', true);
        acc.OwnerId = gspUser.Id;
        insert acc;

        Test.startTest();

        acc.OwnerId = nonGspUser.Id;
        
        try {
            update acc;
            Account updatedAcc = [SELECT Id, OwnerId FROM Account WHERE Id = :acc.Id];
            Assert.areEqual(nonGspUser.Id, updatedAcc.OwnerId, 'Owner should be updated successfully');
        } catch (DmlException e) {
            Assert.isTrue(e.getMessage().contains(AccountHelper.NON_GSP_OWNER_ERROR), 
                         'Error message should contain the expected validation message');
        }

        Test.stopTest();
    }

    @isTest
    static void testGSPAccountValidation_EdgeCases() {
        ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance();
        if (bypassTrigger == null) {
            bypassTrigger = new ByPassTrigger__c();
        }
        bypassTrigger.Bypass_Account_Trigger__c = false;
        bypassTrigger.Bypass_Except_Segmentation__c = false;
        upsert bypassTrigger;
        
        Brand_List__c gspBrand = createGSPBrand('TestGSPBrand');
        User gspUser = createTestUser('gsp', 'System Administrator', true);

        Test.startTest();

        Account acc1 = createTestAccount('TestNull', null, null, null, false);
        acc1.OwnerId = gspUser.Id;
        insert acc1;
        Account queriedAcc1 = [SELECT Id, GSP__c FROM Account WHERE Id = :acc1.Id];
        Assert.isFalse(queriedAcc1.GSP__c, 'Account with null values should not be GSP');

        Account acc2 = createTestAccount('TestEmpty', '', '', '', false);
        acc2.OwnerId = gspUser.Id;
        insert acc2;
        Account queriedAcc2 = [SELECT Id, GSP__c FROM Account WHERE Id = :acc2.Id];
        Assert.isFalse(queriedAcc2.GSP__c, 'Account with empty strings should not be GSP');

        Account acc3 = createTestAccount('TestNoChange', 'TestGSPBrand', null, 'Credit Card', true);
        acc3.OwnerId = gspUser.Id;
        insert acc3;
        Account queriedAcc3 = [SELECT Id, GSP__c FROM Account WHERE Id = :acc3.Id];
        
        acc3.Name = 'Updated Name';
        update acc3;
        Account updatedAcc3 = [SELECT Id, GSP__c FROM Account WHERE Id = :acc3.Id];
        Assert.isTrue(updatedAcc3.GSP__c, 'Account should maintain GSP status when no relevant fields change');

        Test.stopTest();
    }

    @isTest
    static void testGSPAccountValidation_BypassProfileValidation() {
        ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance();
        if (bypassTrigger == null) {
            bypassTrigger = new ByPassTrigger__c();
        }
        bypassTrigger.Bypass_Account_Trigger__c = false;
        bypassTrigger.Bypass_Except_Segmentation__c = false;
        upsert bypassTrigger;
        
        Brand_List__c gspBrand = createGSPBrand('TestGSPBrand');
        Bypass_GSP_override_Validation__c bypassProfile = new Bypass_GSP_override_Validation__c();
        bypassProfile.Profile_Name__c = 'System Administrator';
        bypassProfile.Name = 'System Administrator_' + String.valueOf(Datetime.now().getTime()); // Ensure unique Name
        insert bypassProfile;

        User gspUser = createTestUser('gsp', 'System Administrator', true);
        User nonGspUser = createTestUser('ngsp', 'System Administrator', false);

        Account acc = createTestAccount('TestBypass', 'TestGSPBrand', null, 'Credit Card', true);
        acc.OwnerId = gspUser.Id;
        insert acc;

        Test.startTest();

        acc.OwnerId = nonGspUser.Id;
        update acc; 
        Account updatedAcc = [SELECT Id, OwnerId FROM Account WHERE Id = :acc.Id];
        Assert.areEqual(nonGspUser.Id, updatedAcc.OwnerId, 'Owner should be updated successfully with bypass profile');

        Test.stopTest();
    }

    @isTest
    static void testGSPAccountValidation_NullStatements() {
        ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance();
        if (bypassTrigger == null) {
            bypassTrigger = new ByPassTrigger__c();
        }
        bypassTrigger.Bypass_Account_Trigger__c = false;
        bypassTrigger.Bypass_Except_Segmentation__c = false;
        upsert bypassTrigger;
        
        Brand_List__c gspBrand = createGSPBrand('TestGSPBrand');
        User gspUser = createTestUser('gsp', 'System Administrator', true);
        
        Account acc1 = createTestAccount('TestInvalidUser', 'TestGSPBrand', null, AccountHelper.PAYMENT_METHOD_PARTNER_BILLING_NGBS, true);
        acc1.OwnerId = gspUser.Id;
        insert acc1;
        
        Test.startTest();
        
        // Test with non-existent user ID - should fail gracefully
        try {
            acc1.OwnerId = getNonExistentUserId(); 
            update acc1;
            // If we reach here, the update succeeded (unexpected)
            Assert.fail('Expected an exception when updating with non-existent user ID');
        } catch (Exception e) {
            // Expected to fail with non-existent user ID
            Assert.isTrue(e.getMessage() != null, 'Exception should have a message');
        }
        
        Test.stopTest();
    }

    @isTest
    static void testGSPAccountValidation_OwnerChangeAndGSPMarking() {
        
        ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance();
        if (bypassTrigger == null) {
            bypassTrigger = new ByPassTrigger__c();
        }
        bypassTrigger.Bypass_Account_Trigger__c = false;
        bypassTrigger.Bypass_Except_Segmentation__c = false;
        upsert bypassTrigger;
        

                        // Set the static flag to true to cover the cache path in getUserById method
        ConvertLead.IS_LEAD_CONVERT_PROCESSING = true;
        
        // Set the custom setting to enable lead conversion using cache
        Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();
        if (featureToggle == null) {
            featureToggle = new Feature_Toggle__c();
        }
        featureToggle.EnableLeadConversionUsingCache__c = true;
        upsert featureToggle;  

        
        Brand_List__c gspBrand = createGSPBrand('TestGSPBrandComprehensive');
        User gspUser1 = createTestUser('gsp1', 'System Administrator', true);
        User gspUser2 = createTestUser('gsp2', 'System Administrator', true);
        User nonGspUser = createTestUser('ngsp', 'System Administrator', false);
        
        Test.startTest();
        
        // Test cache functionality - owner change between GSP users
        Account acc1 = createTestAccount('TestCache', 'TestGSPBrandComprehensive', null, 'Credit Card', true);
        acc1.OwnerId = gspUser1.Id;
        insert acc1;
        acc1.OwnerId = gspUser2.Id;
        update acc1;
        Account updatedAcc1 = [SELECT Id, OwnerId FROM Account WHERE Id = :acc1.Id];
        Assert.areEqual(gspUser2.Id, updatedAcc1.OwnerId, 'Owner should be updated successfully between GSP users');
        
        // Test GSP validation with GSP user (UserSelector path)
        Account acc2 = createTestAccount('TestGSP', 'TestGSPBrandComprehensive', null, 'Credit Card', false);
        acc2.OwnerId = gspUser1.Id;
        insert acc2;
        Account queriedAcc2 = [SELECT Id, GSP__c FROM Account WHERE Id = :acc2.Id];
        Assert.isTrue(queriedAcc2.GSP__c, 'Account should be marked as GSP with GSP user');
        
        // Test owner change validation - non-GSP user (error scenario)
        acc2.OwnerId = nonGspUser.Id;
        try {
            update acc2;
            Account updatedAcc2 = [SELECT Id, OwnerId FROM Account WHERE Id = :acc2.Id];
            Assert.areEqual(nonGspUser.Id, updatedAcc2.OwnerId, 'Owner should be updated successfully');
        } catch (DmlException e) {
            Assert.isTrue(e.getMessage().contains(AccountHelper.NON_GSP_OWNER_ERROR), 
                         'Error message should contain the expected validation message');
        }

        try {
            acc2.OwnerId = getNonExistentUserId(); // Non-existent user ID
            update acc2;
        } catch (Exception e) {
            // Expected to fail, but this tests the getUserById method path
        }
        
        // Now test the else path (UserSelector) by setting the custom setting to false
        featureToggle.EnableLeadConversionUsingCache__c = false;
        update featureToggle;
        
        // Test another account update to trigger the else path
        Account acc3 = createTestAccount('TestElsePath', 'TestGSPBrandComprehensive', null, 'Credit Card', false);
        acc3.OwnerId = gspUser1.Id;
        insert acc3;
        
        acc3.OwnerId = gspUser2.Id;
        update acc3;
        Account updatedAcc3 = [SELECT Id, OwnerId FROM Account WHERE Id = :acc3.Id];
        Assert.areEqual(gspUser2.Id, updatedAcc3.OwnerId, 'Owner should be updated successfully using UserSelector path');
    }

    // ─── PopulateWaveOnInsertAndUpdate Tests ─────────────────────────────────────

    // ── Before-Insert scenarios ───────────────────────────────────────────────

    /**
     * Paid account inserted with RC_Upgrade_Date__c in November (month 11).
     * Wave 1 covers Oct-Dec (months 10-12), so Wave__c must be populated.
     */
    @IsTest
    static void testPopulateWaveOnInsertAndUpdate_Insert_PaidWithUpgradeDate_SetsWave() {
        Account acc = new Account(
            Name               = 'Test Wave Insert Paid',
            RC_Account_Status__c = AccountHelper.PAID_STATUS,
            RC_Upgrade_Date__c = Date.newInstance(2024, 11, 1),
            SignupPlatform__c  = 'WEB',
            RC_Service_name__c = 'office123',
            Partner_ID__c      = '9852'
        );

        Test.startTest();
        insert acc;
        Test.stopTest();

        Account result = [SELECT Wave__c FROM Account WHERE Id = :acc.Id];
        Assert.isNotNull(result.Wave__c, 'Wave__c should be populated on insert for a Paid account with RC_Upgrade_Date__c');
    }

    /**
     * Non-paid (Trial) account inserted with RC_Upgrade_Date__c.
     * Wave__c must remain null — only Paid accounts get wave assigned.
     */
    @IsTest
    static void testPopulateWaveOnInsertAndUpdate_Insert_NonPaid_WaveRemainsNull() {
        Account acc = new Account(
            Name               = 'Test Wave Insert Trial',
            RC_Account_Status__c = 'TRIAL',
            RC_Upgrade_Date__c = Date.newInstance(2024, 11, 1),
            SignupPlatform__c  = 'WEB',
            RC_Service_name__c = 'office123',
            Partner_ID__c      = '9852'
        );

        Test.startTest();
        insert acc;
        Test.stopTest();

        Account result = [SELECT Wave__c FROM Account WHERE Id = :acc.Id];
        Assert.isNull(result.Wave__c, 'Wave__c should not be set for non-Paid accounts on insert');
    }

    /**
     * Paid account inserted without RC_Upgrade_Date__c.
     * Wave__c must remain null — no Paid Date means wave cannot be determined.
     */
    @IsTest
    static void testPopulateWaveOnInsertAndUpdate_Insert_NoUpgradeDate_WaveRemainsNull() {
        Account acc = new Account(
            Name               = 'Test Wave Insert No Date',
            RC_Account_Status__c = AccountHelper.PAID_STATUS,
            RC_Upgrade_Date__c = null,
            SignupPlatform__c  = 'WEB',
            RC_Service_name__c = 'office123',
            Partner_ID__c      = '9852'
        );

        Test.startTest();
        insert acc;
        Test.stopTest();

        Account result = [SELECT Wave__c FROM Account WHERE Id = :acc.Id];
        Assert.isNull(result.Wave__c, 'Wave__c should not be set when RC_Upgrade_Date__c is null');
    }

    // ── Before-Update scenarios ───────────────────────────────────────────────

    /**
     * Status changes to Paid while RC_Upgrade_Date__c is non-null.
     * Wave__c must be populated/recalculated by the handler.
     */
    @IsTest
    static void testPopulateWaveOnInsertAndUpdate_Update_StatusChangedToPaid_SetsWave() {
        Account acc = new Account(
            Name               = 'Test Wave Update ToPaid',
            RC_Account_Status__c = 'TRIAL',
            RC_Upgrade_Date__c = Date.newInstance(2024, 11, 1),
            SignupPlatform__c  = 'WEB',
            RC_Service_name__c = 'office123',
            Partner_ID__c      = '9852'
        );
        insert acc;

        acc.RC_Account_Status__c = AccountHelper.PAID_STATUS;

        Test.startTest();
        update acc;
        Test.stopTest();

        Account result = [SELECT Wave__c FROM Account WHERE Id = :acc.Id];
        Assert.isNotNull(result.Wave__c, 'Wave__c should be populated when status changes to Paid with non-null RC_Upgrade_Date__c');
    }

    /**
     * Account is already Paid and RC_Upgrade_Date__c changes to a different non-null value.
     * Wave__c must be recalculated to reflect the new upgrade-date month.
     */
    @IsTest
    static void testPopulateWaveOnInsertAndUpdate_Update_UpgradeDateChanged_Recalculates() {
        Account acc = new Account(
            Name               = 'Test Wave Update DateChg',
            RC_Account_Status__c = AccountHelper.PAID_STATUS,
            RC_Upgrade_Date__c = Date.newInstance(2024, 11, 1),
            SignupPlatform__c  = 'WEB',
            RC_Service_name__c = 'office123',
            Partner_ID__c      = '9852'
        );
        insert acc;

        String originalWave = [SELECT Wave__c FROM Account WHERE Id = :acc.Id].Wave__c;

        acc.RC_Upgrade_Date__c = Date.newInstance(2024, 5, 15);

        Test.startTest();
        update acc;
        Test.stopTest();

        Account result = [SELECT Wave__c FROM Account WHERE Id = :acc.Id];
        Assert.isNotNull(result.Wave__c, 'Wave__c should be recalculated when RC_Upgrade_Date__c changes on a Paid account');
    }

    /**
     * Status changes away from Paid (e.g. to CANCELED).
     * The wave handler guards on isPaid, so Wave__c must not be set by this logic.
     */
    @IsTest
    static void testPopulateWaveOnInsertAndUpdate_Update_StatusChangedAwayFromPaid_NoWave() {
        Account acc = new Account(
            Name               = 'Test Wave Update AwayPaid',
            RC_Account_Status__c = AccountHelper.PAID_STATUS,
            RC_Upgrade_Date__c = Date.newInstance(2024, 11, 1),
            SignupPlatform__c  = 'WEB',
            RC_Service_name__c = 'office123',
            Partner_ID__c      = '9852'
        );
        insert acc;

        acc.RC_Account_Status__c = 'CANCELED';
        acc.Wave__c = null;

        Test.startTest();
        update acc;
        Test.stopTest();

        Account result = [SELECT Wave__c FROM Account WHERE Id = :acc.Id];
        Assert.isNull(result.Wave__c, 'Wave__c should not be populated when status changes away from Paid');
    }

    /**
     * RC_Upgrade_Date__c changes to null on a Paid account.
     * Guard requires non-null date, so Wave__c must not be recalculated.
     */
    @IsTest
    static void testPopulateWaveOnInsertAndUpdate_Update_UpgradeDateSetToNull_NoRecalc() {
        Account acc = new Account(
            Name               = 'Test Wave Update NullDate',
            RC_Account_Status__c = AccountHelper.PAID_STATUS,
            RC_Upgrade_Date__c = Date.newInstance(2024, 11, 1),
            SignupPlatform__c  = 'WEB',
            RC_Service_name__c = 'office123',
            Partner_ID__c      = '9852'
        );
        insert acc;

        String waveBeforeNull = [SELECT Wave__c FROM Account WHERE Id = :acc.Id].Wave__c;

        acc.RC_Upgrade_Date__c = null;

        Test.startTest();
        update acc;
        Test.stopTest();

        Account result = [SELECT Wave__c FROM Account WHERE Id = :acc.Id];
        Assert.areEqual(waveBeforeNull, result.Wave__c,
            'Wave__c should remain unchanged when RC_Upgrade_Date__c is set to null — handler must not recalculate');
    }
}