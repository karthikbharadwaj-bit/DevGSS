@isTest
private class TestAccountContactRoleData {

    @isTest
    private static void testGetAccountContactRolesForCompanyMatchingByAccountIdsShouldReturnResultSuccessfully(){
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
        .setFields(
            new Map<SObjectField, Object>{
                Account.Name => 'Test account'
            }
        )
        .create()
        .getRecord();

    Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
        .setFields(
            new Map<SObjectField, Object>{
                Contact.FirstName => 'Test1',
                Contact.LastName => 'Test1',
                Contact.AccountId => testAccount.Id,
                Contact.Email => 'test@test.com',
                Contact.Phone => '1234567890',
                Contact.Preferred_Language__c => 'en_US'
            }
        )
        .create()
        .getRecord();
        
        AccountContactRoleData.IAccountContactRoleData accountContactRoleData = new AccountContactRoleData();
        
        AccountContactRole testAccountContactRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
        .setFields(
            new Map<SObjectField, Object>{
                AccountContactRole.AccountId => testAccount.Id,
                AccountContactRole.ContactId => testContact.Id,
                AccountContactRole.IsPrimary => true,
                AccountContactRole.Role => 'RC Admin User'
            }
        )
        .create()
        .getRecord();
        
        Test.startTest();
            List<AccountContactRole> accountContactRolesReturned = 
                accountContactRoleData.getAccountContactRolesForCompanyMatchingByAccountIds(new Set<Id>{testAccount.Id});
        Test.stopTest();

        System.assertEquals(1, accountContactRolesReturned.size(), 
            'Only one Account_Hierarchy__c should be returned');
    }

    @isTest
    private static void testMocksShouldReturnExpectedResults() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'Test account'
                }
            )
            .create()
            .getRecord();
        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => testAccount.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
        AccountContactRole accountContactRoleToReturn = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => testAccount.Id,
                    AccountContactRole.ContactId => testContact.Id,
                    AccountContactRole.IsPrimary => true,
                    AccountContactRole.Role => 'RC Admin User'
                }
            )
            .create()
            .getRecord();
        
        AccountContactRoleData.AccountContactRoleDataMock accountContactRoleDataMock = 
            new AccountContactRoleData.AccountContactRoleDataMock();
        accountContactRoleDataMock.accountContactRolesToReturn = new List<AccountContactRole>{accountContactRoleToReturn};

        List<AccountContactRole> acrReturnedByGetAccountContactRolesForCompanyMatchingByAccountIds;
                
        Test.startTest();
            acrReturnedByGetAccountContactRolesForCompanyMatchingByAccountIds = 
                accountContactRoleDataMock.getAccountContactRolesForCompanyMatchingByAccountIds(new Set<Id>{accountContactRoleToReturn.Id});
            
        Test.stopTest();

        System.assertEquals(1, acrReturnedByGetAccountContactRolesForCompanyMatchingByAccountIds.size(), 
            'AccountContactRole should be returned successfully');
    }

}