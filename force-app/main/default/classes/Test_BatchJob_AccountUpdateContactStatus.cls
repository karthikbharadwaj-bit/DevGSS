@IsTest
private class Test_BatchJob_AccountUpdateContactStatus {
    @TestSetup
    private static void createAccountsWithLastModifiedDateField() {
        List<Account> accounts = new List<Account>();
        List<Contact> contacts = new List<Contact>();

        for (Integer i = 0; i < 10; i++) {
            Account account = new Account(Name = 'testAcc' + i, Changes__c = 'ContactStatusNeedsToUpdate');
            accounts.add(account);
        }

        insert accounts;

        List<Account> insertedAccounts = [SELECT Name FROM Account WHERE Name LIKE 'testAcc%'];

        for (Integer i = 0; i < insertedAccounts.size(); i++) {
            Contact contact = new Contact(
                FirstName = 'Test' + i,
                LastName = 'Test' + i,
                AccountId = insertedAccounts.get(i).Id,
                Contact_Status__c = '0. Downgraded'
            );
            contacts.add(contact);
        }

        insert contacts;

        List<Account> accountsToUpdate = new List<Account>();

        for (Integer i = 0; i < insertedAccounts.size(); i++) {
            insertedAccounts.get(i).Name = 'updatedAccount' + i;
            accountsToUpdate.add(insertedAccounts.get(i));
        }

        update accountsToUpdate;
    }

    @IsTest
    private static void testBatchJobAccountUpdateContactStatusWhenChangesNeedsToUpdate() {
        BatchJob_AccountUpdateContactStatus batchToTest = new BatchJob_AccountUpdateContactStatus(0);

        Test.startTest();
        Id batchId = Database.executeBatch(batchToTest);
        Test.stopTest();

        System.assertEquals(true, batchId != null, 'Batch should be executed successfully');
    }

    @IsTest
    private static void testBatchJobAccountUpdateContactStatusWhenChangesContainCurrentOwner() {

        List<Account> insertedAccounts = [SELECT Name FROM Account WHERE Name LIKE 'testAcc%'];
        List<Account> accountsToUpdate = new List<Account>();

        for (Integer i = 0; i < insertedAccounts.size(); i++) {
            insertedAccounts.get(i).Changes__c = 'Current_Owner__c';
            accountsToUpdate.add(insertedAccounts.get(i));
        }

        update accountsToUpdate;

        BatchJob_AccountUpdateContactStatus batchToTest = new BatchJob_AccountUpdateContactStatus(0);

        Test.startTest();
        Id batchId = Database.executeBatch(batchToTest);
        Test.stopTest();

        System.assertEquals(true, batchId != null, 'Batch should be executed successfully');
    }

    @IsTest
    private static void testScheduleBatchJobAccountUpdateContactStatus(){
        String cronExp = '0 0 12 1/1 * ? *';
        BatchJob_AccountUpdateContactStatus batchToRun = new BatchJob_AccountUpdateContactStatus();

        Test.startTest();
        String jobId = System.schedule('BatchJob_AccountUpdateContactStatus' + System.now(), cronExp, batchToRun);
        Test.stopTest();

        System.assert(jobId != null, 'The Scheduler should have returned a jobId successfully');
    }
}