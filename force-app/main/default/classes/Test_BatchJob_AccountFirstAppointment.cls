@IsTest
private class Test_BatchJob_AccountFirstAppointment {
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
            accountsToUpdate.add(insertedAccounts.get(i));
        }

        update accountsToUpdate;
    }

    @IsTest
    private static void testBatchJobAccountFirstAppointmentSource() {
        BatchJob_AccountFirstAppointmentSource batchToTest = new BatchJob_AccountFirstAppointmentSource(0);

        Test.startTest();
        Id batchId = Database.executeBatch(batchToTest);
        Test.stopTest();

        System.assertEquals(true, batchId != null, 'Batch should be executed successfully');
    }

    @IsTest
    private static void testScheduleBatchJobAccountFirstAppointmentSource(){
        String cronExp = '0 0 12 1/1 * ? *';
        BatchJob_AccountFirstAppointmentSource batchToRun = new BatchJob_AccountFirstAppointmentSource();

        Test.startTest();
        String jobId = System.schedule('BatchJob_AccountFirstAppointmentSource' + System.now(), cronExp, batchToRun);
        Test.stopTest();

        System.assert(jobId != null, 'The Scheduler should have returned a jobId successfully');
    }
}