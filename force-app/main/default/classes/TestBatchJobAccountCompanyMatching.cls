@isTest
private class TestBatchJobAccountCompanyMatching {

    private static List<PlatformLog__c> getAllPlatformLogs(){
        return [SELECT Id, Source__c, Error__c, StackTrace__c, InboundMessage__c, OutboundMessage__c
                FROM PlatformLog__c];
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testGetQueryLocatorShouldSaveToPlatformLogWhenAnExceptionIsThrown(){
        BatchJobAccountCompanyMatching batchToTest = new BatchJobAccountCompanyMatching();
        
        test.startTest();
            batchToTest.execute(null, new List<Lead>());
        test.stopTest();
    }

    @isTest
    private static void testSchedulerShouldReturnAJobIdSuccessfully(){
        String everyDayAt12Am = '0 0 12 1/1 * ? *';
        BatchJobAccountCompanyMatching batchToRun = new BatchJobAccountCompanyMatching();
        
        test.startTest();
            String jobId = System.schedule('Batch Job Account Company Matching Scheduler', everyDayAt12Am, batchToRun);
        test.stopTest();

        System.assert(jobId != null, 'The Scheduler should have returned a jobId successfully');
    }

    @isTest
    static void testAccountCompanyMatchingJobShouldLogPlatformExceptionWhenCannotUpdateRecord() {
        BatchJobAccountCompanyMatching batchJob = new BatchJobAccountCompanyMatching();
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
}