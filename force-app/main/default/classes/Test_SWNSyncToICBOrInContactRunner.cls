@isTest
class Test_SWNSyncToICBOrInContactRunner {
    @isTest
    static void testSWNSyncToICBOrInContactRunner() {
        SWNSyncToICBOrInContactRunner runner = new SWNSyncToICBOrInContactRunner(null, '');

        Test.startTest();
            runner.run();
        Test.stopTest();

        Assert.isTrue(runner.isSkipFinalize, 'Skip finalize should be true');
    }
}