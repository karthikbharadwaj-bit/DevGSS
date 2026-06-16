@isTest
private class Test_BatchJob_ContactMostFrequentEmail {
    
    @TestSetup 
    static void createData() {
        List<Account> testAccounts = new List<Account>();
        
        Account account1 = TestDataFactory.createAccount(false);
        account1.Name = 'LS test account 1';
        account1.RunContactMostFrequentEmail__c = true;
        testAccounts.add(account1);

        Account account2 = TestDataFactory.createAccount(false);
        account2.Name = 'LS test account 2';
        account2.RunContactMostFrequentEmail__c = true;
        testAccounts.add(account2);

        Account account3 = TestDataFactory.createAccount(false);
        account3.Name = 'LS test account 3';
        account3.RunContactMostFrequentEmail__c = true;
        testAccounts.add(account3);

        insert testAccounts;
    }

    private static Account getAccountByName(String accountName){
        return [SELECT Id, Name, RunContactMostFrequentEmail__c, ContactMostFrequentEmail__c 
            FROM Account 
            WHERE Name =: accountName];
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testContactMostFrequentEmailShouldBeCalculatedCorrectlyForAccounts() {

        CompanyMatchingIgnoredDomains__c blacklist = TestDataFactory.createCompanyMatchingIgnoredDomain(false);
        blacklist.name = 'blacklisted.fake';
        insert blacklist;

        Account testAccount1 = getAccountByName('LS test account 1');
        Account testAccount2 = getAccountByName('LS test account 2');
        Account testAccount3 = getAccountByName('LS test account 3');

        Contact account1Contact1 = TestDataFactory.createContact(testAccount1, false);
        account1Contact1.email = 'something@mostcommon.fake';
        Contact account1Contact2 = TestDataFactory.createContact(testAccount1, false);
        account1Contact2.email = 'something@mostcommon.fake';
        Contact account1Contact3 = TestDataFactory.createContact(testAccount1, false);
        account1Contact3.email = 'something@leastcommon.fake';
        Contact account1Contact4 = TestDataFactory.createContact(testAccount1, false);
        account1Contact4.email = 'something@blacklisted.fake';
        Contact account1Contact5 = TestDataFactory.createContact(testAccount1, false);
        account1Contact5.email = 'something@blacklisted.fake';
        Contact account1Contact6 = TestDataFactory.createContact(testAccount1, false);
        account1Contact6.email = 'something@blacklisted.fake';

        Contact account2Contact1 = TestDataFactory.createContact(testAccount2, false);
        account2Contact1.email = 'something@lucho.com';
        Contact account2Contact2 = TestDataFactory.createContact(testAccount2, false);
        account2Contact2.email = 'something@lucho.com';
        Contact account2Contact3 = TestDataFactory.createContact(testAccount2, false);
        account2Contact3.email = 'something@lucho.com';
        Contact account2Contact4 = TestDataFactory.createContact(testAccount2, false);
        account2Contact4.email = 'something@blacklisted.fake';
        Contact account2Contact5 = TestDataFactory.createContact(testAccount2, false);
        account2Contact5.email = 'something@lesscommon.com';
        Contact account2Contact6 = TestDataFactory.createContact(testAccount2, false); 
        account2Contact6.email = 'something@lesscommon.com';

        Contact account3Contact1 = TestDataFactory.createContact(testAccount3, false);
        account3Contact1.email = 'something@blacklisted.fake';
        Contact account3Contact2 = TestDataFactory.createContact(testAccount3, false);
        account3Contact2.email = 'something@bocajuniors.com';
        Contact account3Contact3 = TestDataFactory.createContact(testAccount3, false);
        account3Contact3.email = 'something@bocajuniors.com';
        Contact account3Contact4 = TestDataFactory.createContact(testAccount3, false);
        account3Contact4.email = 'something@bocajuniors.com';
        Contact account3Contact5 = TestDataFactory.createContact(testAccount3, false);
        account3Contact5.email = 'something@lesscommon.com';
        Contact account3Contact6 = TestDataFactory.createContact(testAccount3, false); 
        account3Contact6.email = 'something@lesscommon.com';

        ContactData.ContactDataMock contactDataMock = new ContactData.ContactDataMock();
        contactDataMock.setContactsToReturn(
            new List<Contact>{
                account1Contact1, account1Contact2, account1Contact3, account1Contact4, account1Contact5, account1Contact6, 
                account2Contact1, account2Contact2, account2Contact3, account2Contact4, account2Contact5, account2Contact6, 
                account3Contact1, account3Contact2, account3Contact3, account3Contact4, account3Contact5, account3Contact6});

        BatchJob_ContactMostFrequentEmail job = new BatchJob_ContactMostFrequentEmail();
        job.contactDataInstance = contactDataMock;

        Test.startTest();
            Database.executeBatch(job);
        Test.stopTest();

        Account account1AfterProcess = getAccountByName('LS test account 1');
        Account account2AfterProcess = getAccountByName('LS test account 2');
        Account account3AfterProcess = getAccountByName('LS test account 3');

        /*System.assertEquals(false, account1AfterProcess.RunContactMostFrequentEmail__c,
            'RunContactMostFrequentEmail__c should be false');
        System.assertEquals('john.doe@mostcommon.fake', account1AfterProcess.ContactMostFrequentEmail__c,
            'ContactMostFrequentEmail__c should be equal to john.doe@mostcommon.fake');
        
        System.assertEquals(false, account2AfterProcess.RunContactMostFrequentEmail__c,
            'RunContactMostFrequentEmail__c should be false');
        System.assertEquals('john.doe@lucho.com', account2AfterProcess.ContactMostFrequentEmail__c,
            'ContactMostFrequentEmail__c should be equal to john.doe@lucho.com');
        
        System.assertEquals(false, account3AfterProcess.RunContactMostFrequentEmail__c,
            'RunContactMostFrequentEmail__c should be false');
        System.assertEquals('john.doe@bocajuniors.com', account3AfterProcess.ContactMostFrequentEmail__c,
            'ContactMostFrequentEmail__c should be equal to john.doe@bocajuniors.com');*/
    }

    @isTest
    static void testContactMostFrequentEmailShouldLogPlatformExceptionWhenCannotUpdateRecord() {
        BatchJob_ContactMostFrequentEmail batchJob = new BatchJob_ContactMostFrequentEmail();
        List<Database.SaveResult> saveResults = new List<Database.SaveResult>();
        Database.SaveResult saveResultOk = (Database.SaveResult)JSON.deserialize('{"success":true,"id":"0013000000abcde"}', 
            Database.SaveResult.class);
        saveResults.add(saveResultOk);
        Database.SaveResult saveResultError = (Database.SaveResult)JSON.deserialize(
            '{"success":false,"errors":[{"message":"You cannot do this...","statusCode":"FIELD_CUSTOM_VALIDATION_EXCEPTION"}]}', 
            Database.SaveResult.class);
        saveResults.add(saveResultError);

        List<SaveResultWrapper> resultsWrapper = new List<SaveResultWrapper>();
        for (Database.SaveResult res : saveResults) {
            SaveResultWrapper wrap = new saveResultWrapper(res.isSuccess(), res.getId(), res.getErrors());
            resultsWrapper.add(wrap);
        }
        batchJob.saveResults = resultsWrapper;

        Test.startTest();
            batchJob.finish(null);
        Test.stopTest();

        List<PlatformLog__c> platformLogs = [SELECT Id, Source__c FROM PlatformLog__c];
        
        System.assertEquals(1, platformLogs.size(),
            'LogSize must be 1 because one row was not updated');
    }

    @isTest
    private static void testSchedulerShouldReturnAJobIdSuccessfully(){
        RingCentralVariousSettings__c rcVariousSettings = TestDataFactory.createRingCentralVariousSettings(false);
        rcVariousSettings.LSMostFrequentEmailChunkSize__c = 5;
        insert rcVariousSettings;
        String everyDayAt12Am = '0 0 12 1/1 * ? *';
        BatchJob_ContactMostFrequentEmail batchToRun = new BatchJob_ContactMostFrequentEmail();
        
        test.startTest();
            String jobId = System.schedule('Batch Job Most Frequent Email Scheduler', everyDayAt12Am, batchToRun);
        test.stopTest();

        System.assert(jobId != null, 'The Scheduler should have returned a jobId successfully');
    }
}