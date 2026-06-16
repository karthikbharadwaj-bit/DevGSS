@isTest
private class Test_GatingSegmentationBatchScheduler {

	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@isTest
	private static void testGatingSegmentationBatchScheduler() {
		Test.startTest();
        GatingSegmentationBatchScheduler sch = new GatingSegmentationBatchScheduler();
        System.schedule('Schedule GatingSegmentationUpdate 1',  '0 00 * * * ?', sch);
		Test.stopTest();
	}
}