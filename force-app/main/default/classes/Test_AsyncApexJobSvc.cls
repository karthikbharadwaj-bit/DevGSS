@IsTest
private class Test_AsyncApexJobSvc {

    @IsTest
    private static void testIsAllowedToBeLaunched() {
        System.assert(!AsyncApexJobSvc.isAllowedToBeLaunched(null));
        System.assert(!AsyncApexJobSvc.isAllowedToBeLaunched(''));
        System.assert(!AsyncApexJobSvc.isAllowedToBeLaunched('TestBatchJob'));
    }

    @IsTest
    private static void testIsJobRunning() {
        System.assert(!AsyncApexJobSvc.isJobRunning(null));
        System.assert(!AsyncApexJobSvc.isJobRunning('TestBatchJob'));
    }

    @IsTest
    private static void testIsJobScheduled() {
        System.assert(!AsyncApexJobSvc.isJobScheduled(null));
        System.assert(!AsyncApexJobSvc.isJobScheduled('TestBatchJob'));
    }

    @IsTest
    private static void testHasSpaceInQueue() {
        System.assert(!AsyncApexJobSvc.hasSpaceInQueue());
    }
}