@isTest
private class Test_SObjectCPUMonitorBatchScheduler {

	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@isTest
	private static void testSObjectCPUMonitorBatchScheduler() {
		Test.startTest();
        SObjectCPUMonitorBatchScheduler sch = new SObjectCPUMonitorBatchScheduler();
        System.schedule('Schedule SObjectCPUMonitorBatchScheduler 1',  '0 00 * * * ?', sch);
		Test.stopTest();
	}
}