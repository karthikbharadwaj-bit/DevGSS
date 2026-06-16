@isTest
private class Test_BatchJob_MaintenanceCasesCloseSched {
    @isTest
    private static void testBatchJob_MaintenanceCasesCloseScheduler() {
        Test.startTest();
        System.schedule(BatchJob_MaintenanceCasesCloseScheduler.BATCH_JOB_SCHEDULER_NAME,
            '0 0 0 * * ? *',
            new BatchJob_MaintenanceCasesCloseScheduler()
        );
        Test.stopTest();

        System.assert(
            AsyncApexJobSvc.isJobScheduled(BatchJob_MaintenanceCasesCloseScheduler.BATCH_JOB_SCHEDULER_NAME),
            BatchJob_MaintenanceCasesCloseScheduler.BATCH_JOB_SCHEDULER_NAME + ' is not scheduled'
        );
    }
}