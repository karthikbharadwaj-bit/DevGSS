@IsTest
private class Test_BatchJob_Account {
    @TestSetup
    private static void createAccountsWithLastModifiedDateField() {
        List<Account> accounts = new List<Account>();

        for (Integer i = 0; i < 10; i++) {
            Account account = new Account(Name = 'testAcc' + i);
            accounts.add(account);
        }

        insert accounts;

        List<Account> insertedAccounts = [SELECT Name FROM Account WHERE Name LIKE 'testAcc%'];
        List<Account> accountsToUpdate = new List<Account>();

        for (Integer i = 0; i < insertedAccounts.size(); i++) {
            insertedAccounts.get(i).Name = 'updatedAccount' + i;
            insertedAccounts.get(i).Changes__c = 'RC_User_ID__c';
            insertedAccounts.get(i).Most_Recent_Opportunity_Owner__c = UserInfo.getUserId();
            accountsToUpdate.add(insertedAccounts.get(i));
        }

        update accountsToUpdate;
    }

    @IsTest
    private static void testBatchJobAccount() {
        BatchJob_Account batchToTest = new BatchJob_Account(0);

        Test.startTest();
        Id batchId = Database.executeBatch(batchToTest);
        Test.stopTest();

        System.assertEquals(true, batchId != null, 'Batch should be executed successfully');
    }

    @IsTest
    private static void testScheduleBatchJobAccount(){
        String cronExp = '0 0 12 1/1 * ? *';
        BatchJob_Account batchToRun = new BatchJob_Account();

        Test.startTest();
        String jobId = System.schedule('BatchJob_Account' + System.now(), cronExp, batchToRun);
        Test.stopTest();

        System.assert(jobId != null, 'The Scheduler should have returned a jobId successfully');
    }
}