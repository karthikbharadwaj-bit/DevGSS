@isTest
private class Test_AccountContactRoleSelector {
    //Account fields defined
	private static final String ACCOUNT_NAME = 'Test';

    //Contact fields defined
    private static final String CONTACT_EMAIL = 'test@test.com';
    private static final String CONTACT_FIRST_NAME = 'Test';
    private static final String CONTACT_LAST_NAME = 'Test';

    //Assert message
    private static final String ASSERT_MESSAGE = 'Wrong number of account contact roles was selected';
    private static final String ASSERT_EQUALS_MESSAGE = 'Wrong account contact role selected';

    @testSetup
    private static void testData() {
         Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Account.Name => ACCOUNT_NAME
                }
            )
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setFields(
                new Map<SObjectField, Object> {
                    Contact.AccountId => acc.Id,
                    Contact.Email => CONTACT_EMAIL,
                    Contact.FirstName => CONTACT_FIRST_NAME,
                    Contact.LastName => CONTACT_LAST_NAME
                }
            )
            .create()
            .getRecord();

        AccountContactRole role1 = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    AccountContactRole.AccountId => acc.Id,
                    AccountContactRole.ContactId => contact.Id,
                    AccountContactRole.Role => OpportunityHelper.CONTACT_ROLE_SIGNATORY,
                    AccountContactRole.IsPrimary => true
                }
            )
            .build()
            .getRecord();

        AccountContactRole role2 = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                AccountContactRole.AccountId => acc.Id,
                AccountContactRole.ContactId => contact.Id,
                AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE
            })
            .build()
            .getRecord();

        insert new List<AccountContactRole> {role1, role2};
    }

	@isTest
    private static void testSelectAccountContactRoles() {
		List<AccountContactRole> accountContactRoles = (List<AccountContactRole>) new AccountContactRoleSelector(true, true)
            .selectAccountContactRoles()
            .executeQuery();

        System.assert(accountContactRoles.size() == 2, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectAccountContactRolesByAccountIds() {
        List<AccountContactRole> accountContactRoles = (List<AccountContactRole>) new AccountContactRoleSelector(true, true)
            .selectAccountContactRoles()
            .executeQuery();

		List<AccountContactRole> accountContactRolesByAccountIds = (List<AccountContactRole>) new AccountContactRoleSelector()
            .selectAccountContactRolesByAccountIds(new Set<Id> {accountContactRoles[0].AccountId})
            .executeQuery();

        System.assert(accountContactRolesByAccountIds.size() == 2, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectPrimaryOrSignatoryContactRoles() {
        List<AccountContactRole> accountContactRoles = (List<AccountContactRole>) new AccountContactRoleSelector(true, true)
            .selectAccountContactRoles()
            .executeQuery();

		List<AccountContactRole> accountContactRolesByAccountIds = (List<AccountContactRole>) new AccountContactRoleSelector()
            .selectPrimaryOrSignatoryContactRoles(new List<Id> {accountContactRoles[0].AccountId})
            .executeQuery();

        System.assert(accountContactRolesByAccountIds.size() == 1, ASSERT_MESSAGE);
    }
    
    @isTest
    private static void testSelectPrimaryAccountContactRolesByAccountIds() {
        List<AccountContactRole> accountContactRoles = (List<AccountContactRole>) new AccountContactRoleSelector(true, true)
            .selectAccountContactRoles()
            .executeQuery();

		List<AccountContactRole> primaryAccountContactRolesByAccountIds = (List<AccountContactRole>) new AccountContactRoleSelector()
            .selectPrimaryAccountContactRolesByAccountIds(new List<Object> {new Set<Id> {accountContactRoles[0].AccountId}})
            .executeQuery();

        System.assert(primaryAccountContactRolesByAccountIds.size() == 1, ASSERT_MESSAGE);
        System.assertEquals(accountContactRoles[0].Id, primaryAccountContactRolesByAccountIds[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectAccountContactRolesWithNonEmptyRoleByAccountIds() {
        List<AccountContactRole> accountContactRoles = (List<AccountContactRole>) new AccountContactRoleSelector(true, true)
            .selectAccountContactRoles()
            .executeQuery();

        List<AccountContactRole> accountContactRolesByAccountIds = (List<AccountContactRole>) new AccountContactRoleSelector()
            .selectAccountContactRolesWithNonEmptyRoleByAccountIds(new List<Id> {accountContactRoles[0].AccountId})
            .executeQuery();

        System.assert(accountContactRolesByAccountIds.size() == 2, ASSERT_MESSAGE);
        System.assertEquals(accountContactRoles[0].Id, accountContactRolesByAccountIds[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectSignatoryContactRolesByForAccount() {
        List<AccountContactRole> accountContactRoles = (List<AccountContactRole>) new AccountContactRoleSelector(true, true)
            .selectAccountContactRoles()
            .executeQuery();

		List<AccountContactRole> signatoryContactRolesByForAccount = (List<AccountContactRole>) new AccountContactRoleSelector()
            .selectSignatoryContactRolesByForAccount(new List<Object> {new Set<Id> {accountContactRoles[0].AccountId}})
            .executeQuery();

        System.assert(signatoryContactRolesByForAccount.size() == 1, ASSERT_MESSAGE);
        System.assertEquals(accountContactRoles[0].Id, signatoryContactRolesByForAccount[0].Id, ASSERT_EQUALS_MESSAGE);
    }


    @isTest
    private static void testSelectPrimaryOrSignatoryContactRolesForLookup() {
        List<AccountContactRole> accountContactRoles = (List<AccountContactRole>) new AccountContactRoleSelector(true, true)
            .selectAccountContactRoles()
            .executeQuery();

		List<AccountContactRole> primaryOrSignatoryContactRolesForLookup = (List<AccountContactRole>) new AccountContactRoleSelector()
            .selectPrimaryOrSignatoryContactRolesForLookup(new List<Object> {new Set<Id> {accountContactRoles[0].AccountId}})
            .executeQuery();

        System.assert(primaryOrSignatoryContactRolesForLookup.size() == 1, ASSERT_MESSAGE);
        System.assertEquals(accountContactRoles[0].Id, primaryOrSignatoryContactRolesForLookup[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectAccountPayableContactRolesByAccount() {
		List<AccountContactRole> accountContactRoles = (List<AccountContactRole>) new AccountContactRoleSelector(true, true)
            .selectAccountContactRoles()
            .executeQuery();

        List<AccountContactRole> accountPayableContactRolesByAccount = (List<AccountContactRole>) new AccountContactRoleSelector()
            .selectAccountPayableContactRolesByAccount(new List<Object> {
                new Set<Id> {accountContactRoles[1].AccountId},
                new Set<Id> {accountContactRoles[1].AccountId}
            })
            .executeQuery();

        System.assert(accountPayableContactRolesByAccount.size() == 1, ASSERT_MESSAGE);
        System.assertEquals(accountContactRoles[1].Id, accountPayableContactRolesByAccount[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectAccountContactRolesForOpportunityClose() {
		List<AccountContactRole> accountContactRolesForOpportunityClose = (List<AccountContactRole>) new AccountContactRoleSelector()
            .selectAccountContactRolesForOpportunityClose()
            .executeQuery();

        System.assert(accountContactRolesForOpportunityClose.size() == 2, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectAccountContactRolesByContactIds() {
		List<AccountContactRole> accountContactRoles = (List<AccountContactRole>) new AccountContactRoleSelector(true, true)
            .selectAccountContactRoles()
            .executeQuery();

        List<AccountContactRole> accountContactRolesByContactIds = (List<AccountContactRole>) new AccountContactRoleSelector()
            .selectAccountContactRolesByContactIds(new List<Object> {new Set<Id> {accountContactRoles[0].ContactId}})
            .executeQuery();

        System.assert(accountContactRolesByContactIds.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(accountContactRoles[0].Id, accountContactRolesByContactIds[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectAccountContactRolesByIds() {
        List<AccountContactRole> accountContactRoles = (List<AccountContactRole>) new AccountContactRoleSelector(true, true)
            .selectAccountContactRoles()
            .executeQuery();

		List<AccountContactRole> accountContactRolesByIds = (List<AccountContactRole>) new AccountContactRoleSelector()
            .selectAccountContactRolesByIds(new List<Object> {accountContactRoles})
            .executeQuery();

        System.assert(accountContactRolesByIds.size() == 2, ASSERT_MESSAGE);
        System.assertEquals(accountContactRoles[0].Id, accountContactRolesByIds[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectAccountContactRolesByAccountAndContactIds() {
		List<AccountContactRole> accountContactRoles = (List<AccountContactRole>) new AccountContactRoleSelector(true, true)
            .selectAccountContactRoles()
            .executeQuery();

        List<AccountContactRole> accountContactRolesByAccountAndContactIds = (List<AccountContactRole>) new AccountContactRoleSelector()
            .selectAccountContactRolesByAccountAndContactIds(new List<Object> {
                new Set<Id> {accountContactRoles[0].AccountId},
                new Set<Id> {accountContactRoles[0].ContactId}
            })
            .executeQuery();

        System.assert(accountContactRolesByAccountAndContactIds.size() == 2, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectAccountContactRolesForAccountOrderedByCreatedDate() {
     	List<AccountContactRole> accountContactRoles = (List<AccountContactRole>) new AccountContactRoleSelector(true, true)
            .selectAccountContactRoles()
            .executeQuery();

        List<AccountContactRole> accountContactRolesForAccountOrderedByCreatedDate = (List<AccountContactRole>) new AccountContactRoleSelector()
            .selectAccountContactRolesForAccountOrderedByCreatedDate(new List<Object> {new Set<Id> {accountContactRoles[0].AccountId}})
            .executeQuery();

        System.assert(accountContactRolesForAccountOrderedByCreatedDate.size() == 2, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectPrimaryAccountContactRoles() {
		List<AccountContactRole> primaryAccountContactRoles = (List<AccountContactRole>) new AccountContactRoleSelector()
            .selectPrimaryAccountContactRoles()
            .executeQuery();

        System.assert(primaryAccountContactRoles.size() == 1, ASSERT_MESSAGE);
    }

    @isTest
    static void testSelectAccountContactRolesByRoleAndAccountId() {
        Id dummyAccId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();

        Test.startTest();
            QueryFactory selectPrimaryAccountPayableContactRoleByAccountIdFactory = new AccountContactRoleSelector()
                .selectAccountContactRolesByRoleAndAccountId(dummyAccId, AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE)
                .setQuery();
        Test.stopTest();

        String resultedQuery = selectPrimaryAccountPayableContactRoleByAccountIdFactory.getQuery();
        Assert.isTrue(
            ((Set<Id>) selectPrimaryAccountPayableContactRoleByAccountIdFactory.bindings[0]).contains(dummyAccId),
            'The input accountId should be preserved'
        );
        Assert.isTrue(
            resultedQuery.contains('AccountId IN :bind0'),
            'The selector must filter results by AccountId'
        );
        Assert.isTrue(
            resultedQuery.contains('Role IN :bind1'),
            'The selector must filter results by Role'
        );
    }

    @isTest
    static void testSelectPrimaryAccountContactRolesByAccountIdsWithSetInput() {
        Id dummyAccId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();

        Test.startTest();
            QueryFactory selectPrimaryAccountPayableContactRoleByAccountIdFactory = new AccountContactRoleSelector()
                .selectPrimaryAccountContactRolesByAccountIds(new Set<Id> {dummyAccId})
                .setQuery();
        Test.stopTest();

        String resultedQuery = selectPrimaryAccountPayableContactRoleByAccountIdFactory.getQuery();
        Assert.isTrue(
            ((Set<Id>) selectPrimaryAccountPayableContactRoleByAccountIdFactory.bindings[0]).contains(dummyAccId),
            'The input accountId should be preserved'
        );
        Assert.isTrue(
            resultedQuery.contains('AccountId IN :bind0'),
            'The selector must filter results by AccountId'
        );
        Assert.isTrue(
            resultedQuery.contains('IsPrimary = true'),
            'The selector must return only primary AccountContactRoles'
        );
    }

    @isTest
    static void testSelectPrimarySignatoryAccountContactRolesByAccountIds() {
        Id dummyAccId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();

        Test.startTest();
            QueryFactory factory = new AccountContactRoleSelector()
                .selectPrimarySignatoryAccountContactRolesByAccountIds(new List<Object> {dummyAccId})
                .setQuery();
            QueryFactory factoryWithoutInput = new AccountContactRoleSelector()
                .selectPrimarySignatoryAccountContactRolesByAccountIds(new List<Object>())
                .setQuery();
        Test.stopTest();

        String resultedQuery = factory.getQuery();
        String resultedQueryWithNoInput = factoryWithoutInput.getQuery();
        Assert.areEqual(
            dummyAccId,
            factory.bindings[0],
            'The input accountId should be preserved'
        );
        Assert.isTrue(
            resultedQuery.contains('AccountId = :bind0'),
            'The selector must filter results by a single AccountId'
        );
        Assert.isTrue(
            resultedQuery.contains('isPrimary = true'),
            'The selector must return only primary AccountContactRoles'
        );
        Assert.isTrue(
            resultedQuery.contains('Role = \'' + AccountContactRoleHelper.CONTACT_ROLE_SIGNATORY + '\''),
            'The selector must return only ' + AccountContactRoleHelper.CONTACT_ROLE_SIGNATORY + ' roles'
        );
        Assert.isFalse(
            resultedQueryWithNoInput.contains('AccountId = :bind0'),
            'If the selector was not provided with an Account.Id, then it must not filter results by AccountId'
        );
    }

    @isTest
    static void testSelectDeletedAccountContactRolesById() {
        Id dummyAcrId = (Id) new ValueProvider.DummyIdProvider(AccountContactRole.sObjectType).getValue();

        Test.startTest();
            QueryFactory factory = new AccountContactRoleSelector()
                .selectDeletedAccountContactRolesById(new Set<Id> {dummyAcrId})
                .setQuery();
        Test.stopTest();

        String resultedQuery = factory.getQuery();
        Assert.isTrue(
            ((List<Id>) factory.bindings[0]).contains(dummyAcrId),
            'The input Id should be preserved'
        );
        Assert.isTrue(
            resultedQuery.contains('Id IN :bind0'),
            'The selector must filter results by Id'
        );
        Assert.isTrue(
            resultedQuery.contains('IsDeleted = true'),
            'The selector must return only deleted AccountContactRoles'
        );
    }

    @isTest
    static void testSelectAccountContactRolesById() {
        Id dummyAcrId = (Id) new ValueProvider.DummyIdProvider(AccountContactRole.sObjectType).getValue();

        Test.startTest();
            QueryFactory factory = new AccountContactRoleSelector()
                .selectAccountContactRolesById(new Set<Id> {dummyAcrId})
                .setQuery();
        Test.stopTest();

        String resultedQuery = factory.getQuery();
        Assert.isTrue(
            ((Set<Id>) factory.bindings[0]).contains(dummyAcrId),
            'The input Id should be preserved'
        );
        Assert.isTrue(
            resultedQuery.contains('Id IN :bind0'),
            'The selector must filter results by Id'
        );
        Assert.isTrue(
            resultedQuery.contains('Role != \'[None]\' AND Role != \'\' AND Role != NULL'),
            'The selector must return AccountContactRoles that have any Role'
        );
    }

    @isTest
    static void testSelectAccountContactRolesByContactIds2() {
        Id dummyContactId = (Id) new ValueProvider.DummyIdProvider(Contact.sObjectType).getValue();

        Test.startTest();
            QueryFactory factory = new AccountContactRoleSelector()
                .selectAccountContactRolesByContactIds2(new Set<Id> {dummyContactId})
                .setQuery();
        Test.stopTest();

        String resultedQuery = factory.getQuery();
        Assert.isTrue(
            ((Set<Id>) factory.bindings[0]).contains(dummyContactId),
            'The input ContactId should be preserved'
        );
        Assert.isTrue(
            resultedQuery.contains('Id IN :bind0'),
            'The selector must filter results by ContactId'
        );
        Assert.isTrue(
            resultedQuery.contains('Role != \'[None]\' AND Role != \'\' AND Role != NULL'),
            'The selector must return AccountContactRoles that have any Role'
        );
    }
}