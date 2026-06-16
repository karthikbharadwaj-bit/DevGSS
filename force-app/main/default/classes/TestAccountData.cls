@isTest
private class TestAccountData {

    @TestSetup static void createTestData() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'Test account'
                }
            )
            .create()
            .getRecord();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testRetrieveAccountsShouldRetrieveAccountsSuccessfully(){

        Account testAccount = (Account) new AccountSelector()
            .selectAccountByName(new List<Object>{
                'Test account'
            })
            .executeQuery()
            .get(0);

        Set<Id> accountsToRetrieve = new Set<Id>{testAccount.Id};
        AccountData.IAccountData accountData = new AccountData();
        Test.startTest();
            List<Account> accountsRetrieved = accountData.retrieveAccounts(accountsToRetrieve);
        Test.stopTest();

        //System.assertEquals(1, accountsRetrieved.size(), 
        //    'Only one Account should be retrieved');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testUpdateAccountsShouldUpdateAccountsSuccessfully(){
        Account testAccount = (Account) new AccountSelector()
            .selectAccountByName(new List<Object>{
                'Test account'
            })
            .executeQuery()
            .get(0);
        testAccount.LS_Installed_Base_Technologies__c = 'preUpdateVal';
        upsert testAccount;
        testAccount.LS_Installed_Base_Technologies__c = 'postUpdateVal';
        
        AccountData.IAccountData accountData = new AccountData();
        Test.startTest();
            accountData.updateAccounts(new List<Account>{testAccount}, false);
        Test.stopTest();

        Set<Id> accountsToRetrieve = new Set<Id>{testAccount.Id};
        List<Account> accountsRetrieved = accountData.retrieveAccounts(accountsToRetrieve);

        //System.assertEquals('postUpdateVal', accountsRetrieved.get(0).LS_Installed_Base_Technologies__c, 
        //    'Update accounts should update accounts successfully');
    }

    @isTest
    private static void testMocksShouldReturnExpectedResults() {
        String AnyWebTechnology = 'anyWebTechnology';
        Account accountToReturn = (Account) new AccountSelector()
            .selectAccountByName(new List<Object>{
                'Test account'
            })
            .executeQuery()
            .get(0);
        accountToReturn.LS_Installed_Base_Technologies__c = 'anyWebTechnology';
        
        AccountData.AccountDataMock accountDataMock = new AccountData.AccountDataMock();
        accountDataMock.accountsToReturn = new List<Account>{accountToReturn};

        List<Account> accountsReturnedByUpdateAccounts;
        List<Account> accountsReturnedByRetrieveAccounts;
        
        Test.startTest();
            accountsReturnedByUpdateAccounts = accountDataMock.retrieveAccounts(new Set<Id>{null});
            accountsReturnedByRetrieveAccounts = accountDataMock.updateAccounts(new List<Account>{new Account()}, false);
        Test.stopTest();

        System.assertEquals(AnyWebTechnology, accountsReturnedByUpdateAccounts[0].LS_Installed_Base_Technologies__c, 
            'Account should be returned correctly by the mock');
        System.assertEquals(AnyWebTechnology, accountsReturnedByRetrieveAccounts[0].LS_Installed_Base_Technologies__c, 
            'Account should be returned correctly by the mock');
    }

}