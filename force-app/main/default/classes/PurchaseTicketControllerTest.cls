@isTest
private class PurchaseTicketControllerTest {
    final static String ACCOUNT_NAME = 'RC Internal';
    final static String TEST_USER_NAME = 'Test Purchase Ticket Controller';
    final static String TEST_ADMIN_NAME = 'RC Support Agent';

    class TestStateData {
        public Account testAccount;
        public Contact testContact;
        public User testUser;
        public User adminUser;

        public TestStateData(Account testAccount, Contact testContact, List<User> testUsers) {
            this.testAccount = testAccount;
            this.testContact = testContact;
            for (User u : testUsers) {
                if (this.testUser != null && this.adminUser != null) {
                    break;
                }
                if (u.LastName == TEST_USER_NAME) {
                    this.testUser = u;
                    continue;
                }
                if (u.LastName == TEST_ADMIN_NAME) {
                    this.adminUser = u;
                    continue;
                }
            }
        }
    }

    @TestSetup
    static void testSetup() {
        generateTestData();
    }

    @isTest
    static void testPurchaseTicketController() {
        TestStateData testData = selectTestData();

        PurchaseTicketController controller = new PurchaseTicketController();
        controller.newPurchaseSubject = 'Test Purchase Subject';
        controller.newPurchaseDescription = 'Test Purchase Description';
        PageReference pageRef;

        System.runAs(testData.testUser) {
            Test.startTest();
            pageRef = controller.createNewPurchase();
            Test.stopTest();
        }

        Assert.areEqual(pageRef.getUrl(), '/helpdesk/' + controller.caseObj.Id, 'The page reference should be the case detail page.');
        
        Case cs = (Case) new ListOptional(new CaseSelector()
            .selectCasesByIds(new Set<Id> { controller.caseObj.Id })
            .withoutSelectorFieldsIncluded()
            .selectFields(new List<SObjectField> {
                Case.Subject,
                Case.Description,
                Case.AccountId,
                Case.OwnerId,
                Case.ContactId
            })
            .executeQuery()
        ).getFirst();

        Assert.isNotNull(cs, 'The case should be created.');
        Assert.areEqual(controller.newPurchaseSubject, cs.Subject, 'The case subject should match.');
        Assert.areEqual(controller.newPurchaseDescription, cs.Description, 'The case description should match.');
        Assert.areEqual(testData.testAccount.Id, cs.AccountId, 'The case AccountId should match.');
        Assert.areEqual(testData.testContact.Id, cs.ContactId, 'The case ContactId should match.');
    }

    @isTest
    static void testPurchaseTicketControllerException() {
        TestStateData testData = selectTestData();
        Triggers.switchOff();
        update new Account(Id = testData.testAccount.Id, Name = ACCOUNT_NAME + '1');
        Triggers.switchOn();

        PurchaseTicketController controller = new PurchaseTicketController();
        PageReference pageRef;
        System.runAs(testData.testUser) {
            Test.startTest();
            pageRef = controller.createNewPurchase();
            Test.stopTest();
        }

        Assert.isNull(pageRef, 'The page reference should not be defined');
        
        PlatformLog__c pl = PlatformLog.getMostRecent();

        Assert.isNotNull(pl, 'PlatformLog__c should be inserted');
        Assert.isTrue(pl.Source__c.contains('PurchaseTicketController'), 'PlatformLog__c should contain correct source');
        Assert.isTrue(pl.Error__c.contains('Case Contact for IT Support Cases should be Internal'), 'PlatformLog__c should contain correct error message');
    }

    static void generateTestData() {
        Triggers.switchOff();
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, ACCOUNT_NAME)
            .create()
            .getRecord();

        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.LastName => 'Test Contact',
                Contact.AccountId => testAccount.Id
            })
            .create()
            .getRecord();

        List<User> testUsers = (List<User>) new SObjectBuilder(User.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                User.LastName => new ValueProvider.ListProvider(
                    new List<String> {
                        TEST_USER_NAME,
                        TEST_ADMIN_NAME
                    }
                ),
                User.Username => new ValueProvider.ListProvider(
                    new List<String> {
                        'TestUserNameForTest!user@gmail.com',
                        'TestAdminUserOwner!user@gmail.com'
                    }
                ),
                User.Email => new ValueProvider.ListProvider(
                    new List<String> {
                        'TestUserNameForTest!user@gmail.com',
                        'TestAdminUserOwner!user@gmail.com'
                    }
                ),
                User.ContactId => new ValueProvider.ListProvider(
                    new List<String> {
                        testContact.Id,
                        null
                    }
                ),
                User.Alias => new ValueProvider.ListProvider(
                    new List<String> {
                        'Test',
                        'Admi'
                    }
                ),
                User.Hierarchy_Role__c => new ValueProvider.ListProvider(
                    new List<String> {
                        UserHelper.SALES_REP_ROLE,
                        null
                    }
                ),
                User.LocaleSidKey => 'en_US',
                User.EmailEncodingKey => 'UTF-8',
                User.LanguageLocaleKey => 'en_US',
                User.TimeZoneSidKey => 'America/Los_Angeles',
                User.isActive => true,
                User.ProfileId => new ValueProvider.ListProvider(
                    new List<String> {
                        ProfileHelper.PROFILE_ID_CUSTOMER_PORTAL_USER,
                        ProfileHelper.PROFILE_ID_SYSADMIN
                    }
                )
            })
            .quantity(2)
            .create()
            .getRecords();
        Triggers.switchOn();
    }

    static TestStateData selectTestData() {
        Account accountByName = (Account) new ListOptional(new AccountSelector()
            .selectAccountByName(new List<Object> { new Set<String> { ACCOUNT_NAME } })
            .subselect(new ContactSelector().selectContacts())
            .executeQuery()
        ).getFirst();

        List<User> testUsers = (List<User>) new UserSelector()
            .selectUsers()
            .withoutSelectorFieldsIncluded()
            .selectFields(new List<Schema.SObjectField> {
                User.Id,
                User.LastName
            })
            .setQueryBindings(new List<Object> { new Set<String> { TEST_USER_NAME, TEST_ADMIN_NAME }})
            .setCondition('LastName = :bind0 AND isActive = TRUE')
            .executeQuery();

        return new TestStateData(accountByName, accountByName.Contacts[0], testUsers);
    }
}