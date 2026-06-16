/**
 * Created by Makhmud.Shafeev on 10/12/2021.
 */
@IsTest
private class Test_ObjectMonitoringScheduler {

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    private static void testObjectMonitoringScheduler() {
        Test.startTest();
        ObjectMonitoringScheduler testObjectMonitoringScheduler = new ObjectMonitoringScheduler();
        String sch = '0 0 23 * * ?';
        System.schedule('Test run schedule delete Object Monitoring object', sch, testObjectMonitoringScheduler);
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    private static void testObjectMonitoringSchedulerWithSOQL() {
        Test.startTest();
        ObjectMonitoringScheduler testObjectMonitoringScheduler = new ObjectMonitoringScheduler(ObjectMonitoringHelper.soqlOlder2Weeks);
        String sch = '0 0 23 * * ?';
        System.schedule('Test run schedule delete Object Monitoring object', sch, testObjectMonitoringScheduler);
        Test.stopTest();
    }

}