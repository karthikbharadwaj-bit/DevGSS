@IsTest
private class TestBatchJobSvc {

    @IsTest
    private static void testBatchJobSvcShouldExecuteSuccessfullyAnyImplementingBatchWhenNoConfigurationIsSetup(){

        BatchJob_PartnerAccount batchToTest = new BatchJob_PartnerAccount();

        Test.startTest();
            Id batchId = Database.executeBatch(batchToTest);
        Test.stopTest();

        System.assertEquals(true, batchId != null,
            'Batch should be executed successfully');
    }

    @IsTest
    private static void testBatchJobSvcShouldExecuteSuccessfullyAnyImplementingBatchWhenConfigurationsAreSetup(){

        BatchJob_PartnerAccount batchToTest = new BatchJob_PartnerAccount();

        Test.startTest();
            Id batchId = Database.executeBatch(batchToTest);
        Test.stopTest();

        System.assertEquals(true, batchId != null,
            'Batch should be executed successfully');
    }

    @IsTest
    private static void
        testBatchJobSvcShouldExecuteSuccessfullyAnyImplementingBatchWhenConfigurationsAreSetupExceptChunkSize(){

        BatchJob_PartnerAccount batchToTest = new BatchJob_PartnerAccount();

        Test.startTest();
            Id batchId = Database.executeBatch(batchToTest);
        Test.stopTest();

        System.assertEquals(true, batchId != null,
            'Batch should be executed successfully');
    }

    @IsTest
    private static void testSchedulerShouldReturnAJobIdSuccessfully(){
        String randomText = String.valueOf(Math.random()).substringAfter('.').right(7);
        String everyDayAt12Am = '0 0 12 1/1 * ? *';
        BatchJob_PartnerAccount batchToRun = new BatchJob_PartnerAccount();

        Test.startTest();
            String jobId = System.schedule('BatchJob_PartnerAccount' + randomText, everyDayAt12Am, batchToRun);
        Test.stopTest();

        System.assert(jobId != null, 'The Scheduler should have returned a jobId successfully');
    }

    @IsTest
    private static void testBatchJobSvcShouldExecuteSuccessfullyWhenExecutingDirectly(){

        BatchJob_PartnerAccount batchToTest = new BatchJob_PartnerAccount();

        Test.startTest();
            batchToTest.execute(null, new List<Account>());
        Test.stopTest();

        System.assertEquals(0, batchToTest.databaseResults.size(),
            'No records should be updated for zero accounts');
    }

    @IsTest
    static void testBatchJobSvcShouldLogPlatformExceptionWhenCannotUpdateRecord() {

        List<Database.SaveResult> saveResults = new List<Database.SaveResult>();
        Database.SaveResult saveResultOk = (Database.SaveResult)JSON.deserialize(
            '{"success":true,"id":"0013000000abcde"}',
            Database.SaveResult.class
        );
        saveResults.add(saveResultOk);
        Database.SaveResult saveResultError = (Database.SaveResult)JSON.deserialize(
            '{"success":false,"errors":[{"message":"You cannot do this...","statusCode":"FIELD_CUSTOM_VALIDATION_EXCEPTION"}]}', 
            Database.SaveResult.class
        );
        saveResults.add(saveResultError);

        BatchJob_PartnerAccount batchJob = new BatchJob_PartnerAccount();
        batchJob.databaseResults = saveResults;

        Test.startTest();
            batchJob.finish(null);
        Test.stopTest();

        List<PlatformLog__c> platformLogs = [SELECT Id, Source__c FROM PlatformLog__c];
        
        System.assertEquals(1, platformLogs.size(),
            'LogSize must be 1 because one row was not updated'); 
    }
}