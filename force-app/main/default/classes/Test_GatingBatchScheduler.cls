@isTest
private class Test_GatingBatchScheduler {

	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@isTest
	private static void testGatingBatchScheduler() {
		Test.startTest();
        GatingProcessStageUpdateBatchScheduler sch = new GatingProcessStageUpdateBatchScheduler();
        System.schedule('Schedule GatingProcessStage 1',  '0 00 * * * ?', sch);
		Test.stopTest();
	}
}