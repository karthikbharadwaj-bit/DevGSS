@IsTest
private class Test_BatchJob_AccountDatePopulation {
    @TestSetup
    private static void createAccountsWithLastModifiedDateField() {
        List<Account> accounts = new List<Account>();
        List<Contact> contacts = new List<Contact>();
        List<Opportunity> opportunities = new List<Opportunity>();

        for (Integer i = 0; i < 10; i++) {
            Account account = new Account(Name = 'testAcc' + i);
            accounts.add(account);
        }

        insert accounts;

        List<Account> insertedAccounts = [SELECT Name FROM Account WHERE Name LIKE 'testAcc%'];

        for (Integer i = 0; i < insertedAccounts.size(); i++) {
            Contact contact = new Contact(
                FirstName = 'Test' + i,
                LastName = 'Test' + i,
                AccountId = insertedAccounts.get(i).Id
            );
            contacts.add(contact);
        }

        insert contacts;

        List<Contact> insertedContacts = [SELECT Id, LastName, AccountId FROM Contact WHERE LastName LIKE 'Test%'];

        for (Integer i = 0; i < insertedContacts.size(); i++) {
            Opportunity opportunity = new Opportunity(
                Name = 'Test Opportunity' + i,
                Type = 'Syndicated - New',
                StageName = 'Planning',
                CloseDate = System.today().addMonths(1),
                AccountId = insertedContacts.get(i).AccountId,
                Primary_Opportunity_Contact__c = insertedContacts.get(i).Id
            );
            opportunities.add(opportunity);
        }

        insert opportunities;

        List<Account> accountsToUpdate = new List<Account>();

        for (Integer i = 0; i < insertedAccounts.size(); i++) {
            insertedAccounts.get(i).Name = 'updatedAccount' + i;
            accountsToUpdate.add(insertedAccounts.get(i));
        }

        update accountsToUpdate;
    }

    @IsTest
    private static void testBatchJobAccountDatePopulation() {
        BatchJob_AccountDatePopulation batchToTest = new BatchJob_AccountDatePopulation(0);

        Test.startTest();
        Id batchId = Database.executeBatch(batchToTest);
        Test.stopTest();

        System.assertEquals(true, batchId != null, 'Batch should be executed successfully');
    }

    @IsTest
    private static void testScheduleBatchJobAccountDatePopulation(){
        String cronExp = '0 0 12 1/1 * ? *';
        BatchJob_AccountDatePopulation batchToRun = new BatchJob_AccountDatePopulation();

        Test.startTest();
        String jobId = System.schedule('BatchJob_AccountDatePopulation' + System.now(), cronExp, batchToRun);
        Test.stopTest();

        System.assert(jobId != null, 'The Scheduler should have returned a jobId successfully');
    }
}