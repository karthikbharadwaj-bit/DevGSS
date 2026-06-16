@isTest
private class Test_BatchJobQueueScheduleChecker {
    @isTest
    private static void testScheduleBatchQueueScheduler() {
        Test.startTest();
        String jobId = BatchJobQueueScheduler.scheduleBatchJobQueueScheduler();
        Test.stopTest();

        System.assert(jobId != null, 'The Scheduler should have returned a jobId successfully');
    }
}