@isTest
private class Test_AccountContactRoleHelper {

    @isTest
    private static void testGetPrimaryContactRoleByAccountId() {

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'test@test.com'
                }
            )
            .create()
            .getRecord();

        System.assertEquals(
            null,
            AccountContactRoleHelper.getPrimaryContactRoleByAccountId(acc.Id),
            'A Role-less account returned a role'
        );

        AccountContactRole accountContactRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => acc.Id,
                    AccountContactRole.ContactId => contact.Id,
                    AccountContactRole.IsPrimary => true,
                    AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_SIGNATORY
                }
            )
            .create()
            .getRecord();

        System.assertEquals(
            accountContactRole.Id,
            AccountContactRoleHelper.getPrimaryContactRoleByAccountId(acc.Id)?.Id,
            'Failed to find a primary contact role'
        );

    }
}