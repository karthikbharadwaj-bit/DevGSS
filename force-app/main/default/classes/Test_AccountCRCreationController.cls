@isTest
private class Test_AccountCRCreationController {

    @TestSetup
    static void prepare() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .create()
            .getRecord();

        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.AccountId => testAccount.Id,
                Contact.LastName => 'John',
                Contact.FirstName => 'Doe',
                Contact.Email => 'contact1@ringcentral.tld'
            })
            .create()
            .getRecord();
    }

    static Account selectTestAccount() {
        List<Account> listAccounts = new AccountSelector()
            .selectAccounts()
            .selectFields(new List<SObjectField>{
                Account.Id, Account.Name
            })
            .subselect(
                new ContactSelector()
                    .selectContacts()
                    .selectFields(new List<SObjectField>{
                        Contact.Id, Contact.FirstName, Contact.LastName, Contact.Email
                    })
            )
            .setCondition('Name = :bind0')
            .setQueryBindings(new List<Object>{
                'My Account'
            })
            .setLimit(1)
            .executeQuery();

        return listAccounts.size() == 0 ? null : listAccounts.get(0);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@isTest
	private static void testSaveSuccess() {

        Account testAcc = selectTestAccount();
        Contact testCont = testAcc.Contacts[0];

		Test.StartTest();
			PageReference pageRef = Page.AccountContactRoleCreation;
			pageRef.getParameters().put('accId', String.valueOf(testAcc.Id));
			Test.setCurrentPage(pageRef);

			AccountContactRoleCreationController accountContactRoleCreationPage = new AccountContactRoleCreationController(new ApexPages.StandardController(testAcc));

			accountContactRoleCreationPage.contactRole.ContactId = testCont.Id;
			accountContactRoleCreationPage.contactRole.Role = 'TestOne';

			// Test save button on "success"
			PageReference testSaveOnSuccess = accountContactRoleCreationPage.save();
			// Test cancel button
			PageReference testCancel = accountContactRoleCreationPage.cancel();
		Test.StopTest();
	}

	@isTest
	private static void testSaveAndNewSuccess() {

        Account testAcc = selectTestAccount();
        Contact testCont = testAcc.Contacts[0];

		Test.StartTest();
			PageReference pageRef = Page.AccountContactRoleCreation;
			pageRef.getParameters().put('accId', String.valueOf(testAcc.Id));
			Test.setCurrentPage(pageRef);

			AccountContactRoleCreationController accountContactRoleCreationPage = new AccountContactRoleCreationController(new ApexPages.StandardController(testAcc));
			// Emulate fields population
			accountContactRoleCreationPage.contactRole.ContactId = testCont.Id;
			accountContactRoleCreationPage.contactRole.Role = 'TestOne';

			// Test save button on "success"
			PageReference testSaveOnSuccess = accountContactRoleCreationPage.saveAndNew();
		Test.StopTest();

		Map<String,String> paramsMap = testSaveOnSuccess.getParameters();
		System.assertEquals(testAcc.Id, paramsMap.get('accId'));
	}

	@isTest
	private static void testSaveFailureDuplicate() {

        Account testAcc = selectTestAccount();
        Contact testCont = testAcc.Contacts[0];

		AccountContactRole acContRole = new AccountContactRole (
			ContactId = testCont.Id,
			AccountId = testAcc.Id,
			Role = 'testOne');
		insert acContRole;

		Test.StartTest();
			PageReference pageRef = Page.AccountContactRoleCreation;
			pageRef.getParameters().put('accId', String.valueOf(testAcc.Id));
			Test.setCurrentPage(pageRef);

			AccountContactRoleCreationController accountContactRoleCreationPage = new AccountContactRoleCreationController(new ApexPages.StandardController(testAcc));
			// Emulate fields population
			accountContactRoleCreationPage.contactRole.ContactId = testCont.Id;
			accountContactRoleCreationPage.contactRole.Role = 'TestOne';

			// Test save button on "fail"
			PageReference testSaveOnError = accountContactRoleCreationPage.save();

		Test.StopTest();

		System.assertEquals(null, testSaveOnError);
	}

	@isTest
	private static void testSaveFailureNotSinglePrimary() {

        Account testAcc = selectTestAccount();
        Contact testCont1 = testAcc.Contacts[0];

		Contact testCont2 = new Contact (
			LastName = 'Test',
			FirstName = 'Test',
			accountid = testAcc.id);
		insert testCont2;

		AccountContactRole acContRole = new AccountContactRole (
			ContactId = testCont2.Id,
			AccountId = testAcc.Id,
			Role = 'testOne',
			IsPrimary = true);
		insert acContRole;

		Test.StartTest();
			PageReference pageRef = Page.AccountContactRoleCreation;
			pageRef.getParameters().put('accId', String.valueOf(testAcc.Id));
			Test.setCurrentPage(pageRef);

			AccountContactRoleCreationController accountContactRoleCreationPage = new AccountContactRoleCreationController(new ApexPages.StandardController(testAcc));
			// Emulate fields population
			accountContactRoleCreationPage.contactRole.ContactId = testCont1.Id;
			accountContactRoleCreationPage.contactRole.Role = 'TestOne';
			accountContactRoleCreationPage.contactRole.IsPrimary = true;

			// Test save button on "fail"
			PageReference testSaveOnError = accountContactRoleCreationPage.save();

		Test.StopTest();

		System.assertEquals(null, testSaveOnError);
	}

	@isTest
	private static void testSaveFailureSignatoryLimit() {
		Account testAcc = new Account(Name = 'testAcc');
		insert testAcc;

		Contact testCont1 = new Contact (
			LastName = 'Test',
			FirstName = 'Test',
			accountid = testAcc.id);
		Contact testCont2 = new Contact (
			LastName = 'Test',
			FirstName = 'Test',
			accountid = testAcc.id);
		Contact testCont3 = new Contact (
			LastName = 'Test',
			FirstName = 'Test',
			accountid = testAcc.id);

		insert (new List<Contact>{testCont1, testCont2, testCont3});
		// Create 2 signatoty contact roles
		AccountContactRole acContRole1 = new AccountContactRole (
			ContactId = testCont2.Id,
			AccountId = testAcc.Id,
			Role = 'Signatory');
		AccountContactRole acContRole2 = new AccountContactRole (
			ContactId = testCont3.Id,
			AccountId = testAcc.Id,
			Role = 'Signatory');
		insert (new List<AccountContactRole>{acContRole1, acContRole2});

		Test.StartTest();
			PageReference pageRef = Page.AccountContactRoleCreation;
			pageRef.getParameters().put('accId', String.valueOf(testAcc.Id));
			Test.setCurrentPage(pageRef);

			AccountContactRoleCreationController accountContactRoleCreationPage = new AccountContactRoleCreationController(new ApexPages.StandardController(testAcc));
			// Emulate fields population, try to create the third signatory contact role
			accountContactRoleCreationPage.contactRole.ContactId = testCont1.Id;
			accountContactRoleCreationPage.contactRole.Role = 'Signatory';

			// Test save button on "fail"
			PageReference testSaveOnError = accountContactRoleCreationPage.save();

		Test.StopTest();

		System.assertEquals(null, testSaveOnError);
	}
	/*
	@isTest
	public static void TestSaveFailureOnSignatoryRoleEditWithoutPermission() {
		String name = 'Test';
		String alias = name;
		if (name.length() > 8 ) {
			alias = name.left(8);
		}
		User testUser = new User(
				Username = name+'!user@gmail.com',
				LastName = 'Test'+name,
				Email = name+'_user@gmail.com',
				Alias = alias,
				TimeZoneSidKey = 'America/Los_Angeles',
				ManagerId = UserInfo.getUserId(),
				LocaleSidKey = 'en_US',
				EmailEncodingKey = 'UTF-8',
				ProfileId = [SELECT Id, Name FROM Profile WHERE Name = 'Standard User'].Id,
				LanguageLocaleKey = 'en_US',
				Hierarchy_Role__c = 'Sales Rep'
		);
		insert testUser;

        System.runAs(testUser) {

            Account testAcc = new Account(Name = 'testAcc');
            insert testAcc;

            Contact testCont1 = new Contact (
                LastName = 'Test',
                FirstName = 'Test',
                accountid = testAcc.id);

            insert testCont1;

            AccountContactRole acContRole1 = new AccountContactRole (
                ContactId = testCont1.Id,
                AccountId = testAcc.Id,
                Role = 'Signatory',
                IsPrimary = false);
            insert acContRole1;

            Test.StartTest();
                PageReference pageRef = Page.AccountContactRoleCreation;
                pageRef.getParameters().put('accId', String.valueOf(testAcc.Id));
                pageRef.getParameters().put('crId', String.valueOf(acContRole1.Id));
                pageRef.getParameters().put('isPrimary', String.valueOf(acContRole1.IsPrimary));
                pageRef.getParameters().put('role', acContRole1.Role);
                Test.setCurrentPage(pageRef);

                AccountContactRoleCreationController accountContactRoleCreationPage = new AccountContactRoleCreationController(new ApexPages.StandardController(testAcc));

                accountContactRoleCreationPage.contactRole.ContactId = testCont1.Id;
                accountContactRoleCreationPage.contactRole.Role = 'Other';

                PageReference testSaveOnError = accountContactRoleCreationPage.save();
                System.assertEquals(null, testSaveOnError);
            Test.StopTest();
        }
    }

	@isTest
	public static void TestSaveFailureOnPrimaryEditWithoutPermission() {
		String name = 'Test';
		String alias = name;
		if (name.length() > 8 ) {
			alias = name.left(8);
		}
		User testUser = new User(
				Username = name+'!user@gmail.com',
				LastName = 'Test'+name,
				Email = name+'_user@gmail.com',
				Alias = alias,
				TimeZoneSidKey = 'America/Los_Angeles',
				ManagerId = UserInfo.getUserId(),
				LocaleSidKey = 'en_US',
				EmailEncodingKey = 'UTF-8',
				ProfileId = [SELECT Id, Name FROM Profile WHERE Name = 'Standard User'].Id,
				LanguageLocaleKey = 'en_US',
				Hierarchy_Role__c = 'Sales Rep'
		);
		insert testUser;

        System.runAs(testUser) {

            Account testAcc = new Account(Name = 'testAcc');
            insert testAcc;

            Contact testCont1 = new Contact (
                LastName = 'Test',
                FirstName = 'Test',
                accountid = testAcc.id);

            insert testCont1;

            AccountContactRole acContRole1 = new AccountContactRole (
                ContactId = testCont1.Id,
                AccountId = testAcc.Id,
                Role = 'Other',
                IsPrimary = true);
            insert acContRole1;

            Test.StartTest();
                PageReference pageRef = Page.AccountContactRoleCreation;
                pageRef.getParameters().put('accId', String.valueOf(testAcc.Id));
                pageRef.getParameters().put('crId', String.valueOf(acContRole1.Id));
                pageRef.getParameters().put('isPrimary', String.valueOf(acContRole1.IsPrimary));
                pageRef.getParameters().put('role', acContRole1.Role);
                Test.setCurrentPage(pageRef);

                AccountContactRoleCreationController accountContactRoleCreationPage = new AccountContactRoleCreationController(new ApexPages.StandardController(testAcc));

                accountContactRoleCreationPage.contactRole.ContactId = testCont1.Id;
                accountContactRoleCreationPage.contactRole.IsPrimary = false;

                PageReference testSaveOnError = accountContactRoleCreationPage.save();

                System.assertEquals(null, testSaveOnError);
            Test.StopTest();
        }
    }
    */
	@isTest
	private static void testSaveFailureAccountsPayble() {

        Account testAcc1 = selectTestAccount();
        Contact testCont = testAcc1.Contacts[0];

        Account testAcc2 = new Account(Name = 'testAcc2');
        insert testAcc2;

        Test.StartTest();
            PageReference pageRef = Page.AccountContactRoleCreation;
            pageRef.getParameters().put('accId', String.valueOf(testAcc2.Id));
            Test.setCurrentPage(pageRef);

            AccountContactRoleCreationController accountContactRoleCreationPage = new AccountContactRoleCreationController(new ApexPages.StandardController(testAcc2));

            accountContactRoleCreationPage.contactRole.ContactId = testCont.Id;
            accountContactRoleCreationPage.contactRole.Role = AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE;

            PageReference testSaveOnError = accountContactRoleCreationPage.save();

        Test.StopTest();

        System.assertEquals(null, testSaveOnError, 'Account Payable ACR validation is failed.');
    }

    @isTest
    private static void testSaveFailureHasApprovals() {

        Account testAcc = selectTestAccount();
        Contact testCont = testAcc.Contacts[0];

        AccountContactRole acContRole = new AccountContactRole (
            ContactId = testCont.Id,
            AccountId = testAcc.Id,
            Role = AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE,
            IsPrimary = true
        );
        insert acContRole;

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL_EU,
                    Opportunity.AccountId => testAcc.Id})
            .create()
            .getRecord();

        Approval__c testApproval = new Approval__c (
            Status__c = 'PendingL1Approval',
            RecordTypeId = ApprovalHelper.RT_ID_INVOICING_REQUEST,
            Account__c = testAcc.Id,
            AccountPayableContact__c = testCont.Id,
            Opportunity__c = testOpp.Id,
            Potential_Users__c = 1,
            Reason_Customer_is_Requesting_Invoicing__c = 'test'
        );

        Test.StartTest();

            insert testApproval;

            PageReference pageRef = Page.AccountContactRoleCreation;
            pageRef.getParameters().put('accId', String.valueOf(testAcc.Id));
            pageRef.getParameters().put('crId', String.valueOf(acContRole.Id));
            pageRef.getParameters().put('isPrimary', String.valueOf(acContRole.IsPrimary));
            pageRef.getParameters().put('role', acContRole.Role);
            pageRef.getParameters().put('contactId', String.valueOf(testCont.Id));
            Test.setCurrentPage(pageRef);

            AccountContactRoleCreationController accountContactRoleCreationPage = new AccountContactRoleCreationController(new ApexPages.StandardController(testAcc));

            accountContactRoleCreationPage.contactRole.Role = AccountContactRoleHelper.CONTACT_ROLE_SIGNATORY;

            PageReference testSaveOnError = accountContactRoleCreationPage.save();

        Test.StopTest();

        System.assertEquals(null, testSaveOnError, 'IsHasApprovals ACR validation is failed.');
    }

    @isTest
    private static void testShowValidationForExistingCustomer() {
		String name = 'Test';
		String alias = name;
		if (name.length() > 8 ) {
			alias = name.left(8);
		}
		User testUser = new User(
				Username = name+'!user@gmail.com',
				LastName = 'Test'+name,
				Email = name+'_user@gmail.com',
				Alias = alias,
				TimeZoneSidKey = 'America/Los_Angeles',
				ManagerId = UserInfo.getUserId(),
				LocaleSidKey = 'en_US',
				EmailEncodingKey = 'UTF-8',
				ProfileId = [SELECT Id, Name FROM Profile WHERE Name = 'Standard User'].Id,
				LanguageLocaleKey = 'en_US',
				Hierarchy_Role__c = 'Sales Rep'
		);
		insert testUser;

        System.runAs(testUser) {

            Account testAcc = new Account(Name = 'testAcc', RC_Account_Status__c = 'Paid');
            insert testAcc;

            Contact testCont1 = new Contact (
                LastName = 'Test',
                FirstName = 'Test',
                accountid = testAcc.id);

            insert testCont1;

            AccountContactRole acContRole1 = new AccountContactRole (
                ContactId = testCont1.Id,
                AccountId = testAcc.Id,
                Role = 'Signatory',
                IsPrimary = false);
            insert acContRole1;

            Test.StartTest();
                PageReference pageRef = Page.AccountContactRoleCreation;
                pageRef.getParameters().put('accId', String.valueOf(testAcc.Id));
                pageRef.getParameters().put('crId', String.valueOf(acContRole1.Id));
                pageRef.getParameters().put('isPrimary', String.valueOf(acContRole1.IsPrimary));
                pageRef.getParameters().put('role', acContRole1.Role);
                Test.setCurrentPage(pageRef);

                AccountContactRoleCreationController accountContactRoleCreationPage = new AccountContactRoleCreationController(new ApexPages.StandardController(testAcc));

                accountContactRoleCreationPage.contactRole.ContactId = testCont1.Id;
                accountContactRoleCreationPage.contactRole.Role = 'Other';

                PageReference testSaveOnError = accountContactRoleCreationPage.save();
                System.assertEquals(null, testSaveOnError);
            Test.StopTest();
        }
    }

    @isTest
    private static void testIsContactPhoneInRange() {

        Account testAcc1 = selectTestAccount();
        Contact testCont = testAcc1.Contacts[0];
        testCont.Phone = '12345';

        Triggers.switchOff();
        update testCont;
        Triggers.switchOn();

        Test.StartTest();
        PageReference pageRef = Page.AccountContactRoleCreation;
        pageRef.getParameters().put('accId', String.valueOf(testAcc1.Id));
        Test.setCurrentPage(pageRef);

        AccountContactRoleCreationController accountContactRoleCreationPage = new AccountContactRoleCreationController(
            new ApexPages.StandardController(testAcc1)
        );

        accountContactRoleCreationPage.contactRole.ContactId = testCont.Id;
        accountContactRoleCreationPage.contactRole.Role = AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE;

        Boolean isInRange = accountContactRoleCreationPage.isContactPhoneInRange();

        Test.StopTest();

        System.assertEquals(false, isInRange, 'Account Payable ACR Contact Phone validation is failed.');
    }
}