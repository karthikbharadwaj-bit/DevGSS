@isTest
private class Test_BatchJob_LeadspaceAccountUpdate {
    
    @TestSetup 
    static void createData() {
        List<Account> accList = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Account.Name => ValueProviderBuilder.provideList(new List<String> {'LS test account 1', 'LS test account 2', 'LS test account 3'}),
                    Account.RunContactMostFrequentEmail__c => true
                }
            )
            .quantity(3)
            .create()
            .getRecords();    
    }

    private static Account getAccountByName(String accountName){
        return [SELECT Id, Name, RunContactMostFrequentEmail__c, ContactMostFrequentEmail__c 
            FROM Account 
            WHERE Name =: accountName];
    }
    
    @isTest
    static void testContactMostFrequentEmailShouldBeCalculatedCorrectlyForAccounts() {

        CompanyMatchingIgnoredDomains__c blacklist = (CompanyMatchingIgnoredDomains__c) new SObjectBuilder(CompanyMatchingIgnoredDomains__c.SObjectType)
        .setFields(
            new Map<SObjectField, Object>{
                CompanyMatchingIgnoredDomains__c.Name => 'blacklisted.fake'
            }
        )
        .create()
        .getRecord();


        Account testAccount1 = getAccountByName('LS test account 1');
        Account testAccount2 = getAccountByName('LS test account 2');
        Account testAccount3 = getAccountByName('LS test account 3');

        List<Contact> contactList = (List<Contact>) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => ValueProviderBuilder.provideList(
                        new List<Id> {
                            testAccount1.Id, 
                            testAccount1.Id, 
                            testAccount1.Id,
                            testAccount1.Id, 
                            testAccount1.Id, 
                            testAccount1.Id,
                            testAccount2.Id, 
                            testAccount2.Id, 
                            testAccount2.Id,
                            testAccount2.Id, 
                            testAccount2.Id, 
                            testAccount2.Id,
                            testAccount3.Id, 
                            testAccount3.Id, 
                            testAccount3.Id,
                            testAccount3.Id, 
                            testAccount3.Id, 
                            testAccount3.Id
                        }
                    ),
                    Contact.Email => ValueProviderBuilder.provideList(
                        new List<String> {
                            'something@mostcommon.fake', 
                            'something@mostcommon.fake', 
                            'something@leastcommon.fake',
                            'something@blacklisted.fake',
                            'something@blacklisted.fake',
                            'something@blacklisted.fake',
                            'something@lucho.com',
                            'something@lucho.com',
                            'something@lucho.com',
                            'something@blacklisted.fake',
                            'something@lesscommon.com',
                            'something@lesscommon.com',
                            'something@blacklisted.fake',
                            'something@bocajuniors.com',
                            'something@bocajuniors.com',
                            'something@bocajuniors.com',
                            'something@lesscommon.com',
                            'something@lesscommon.com'
                        }
                    ),
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .quantity(18)
            .create()
            .getRecords();

        ContactData.ContactDataMock contactDataMock = new ContactData.ContactDataMock();
        contactDataMock.setContactsToReturn(contactList);

        BatchJob_LeadspaceAccountUpdate job = new BatchJob_LeadspaceAccountUpdate();
        job.contactDataInstance = contactDataMock;

        Test.startTest();
            Database.executeBatch(job);
        Test.stopTest();

        Account account1AfterProcess = getAccountByName('LS test account 1');
        Account account2AfterProcess = getAccountByName('LS test account 2');
        Account account3AfterProcess = getAccountByName('LS test account 3');

        System.assertEquals(false, account1AfterProcess.RunContactMostFrequentEmail__c,
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
            'ContactMostFrequentEmail__c should be equal to john.doe@bocajuniors.com');
    }

    @isTest
    static void testContactMostFrequentEmailShouldLogPlatformExceptionWhenCannotUpdateRecord() {
        BatchJob_LeadspaceAccountUpdate batchJob = new BatchJob_LeadspaceAccountUpdate();
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
        RingCentralVariousSettings__c rcVariousSettings = (RingCentralVariousSettings__c) new SObjectBuilder(RingCentralVariousSettings__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    RingCentralVariousSettings__c.LeadspaceAPIKey__c => 'AnyFakeKey',
                    RingCentralVariousSettings__c.LSBatchRequestMaxNumberRecords__c => 10,
                    RingCentralVariousSettings__c.LSMostFrequentEmailChunkSize__c => 5
                }
            )
            .create()
            .getRecord();
        String everyDayAt12Am = '0 0 12 1/1 * ? *';
        BatchJob_LeadspaceAccountUpdate batchToRun = new BatchJob_LeadspaceAccountUpdate();
        
        test.startTest();
            String jobId = System.schedule('Batch Job Most Frequent Email Scheduler', everyDayAt12Am, batchToRun);
        test.stopTest();

        System.assert(jobId != null, 'The Scheduler should have returned a jobId successfully');
    }
}