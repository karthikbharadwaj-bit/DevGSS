@IsTest
private class SlapFiveQueueableJobStatusControllerTest {

    private class TestQ implements Queueable {

        public void execute(QueueableContext context) {
            // no-op
        }
    }

    @IsTest
    static void testGetAsyncApexJobStatus_returnsAStatus() {

        Test.startTest();
        Id jobId = System.enqueueJob(new TestQ());
        Test.stopTest();

        String status =
            SlapFiveQueueableJobStatusController.getAsyncApexJobStatus(jobId);

        System.assertNotEquals(null, status);
        System.assertNotEquals('MissingJobId', status);
    }

    @IsTest
    static void testGetAsyncApexJobStatus_missingJobId() {

        String status =
            SlapFiveQueueableJobStatusController.getAsyncApexJobStatus(null);

        System.assertEquals('MissingJobId', status);
    }
}