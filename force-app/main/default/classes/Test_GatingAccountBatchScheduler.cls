@isTest
private class Test_GatingAccountBatchScheduler {

	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@isTest
	private static void testGatingAccountBatchScheduler() {
		Test.startTest();
        GatingAccountBatchScheduler sch = new GatingAccountBatchScheduler();
        System.schedule('Schedule AccountGatingUpdate 1',  '0 00 * * * ?', sch);
		Test.stopTest();
	}
}