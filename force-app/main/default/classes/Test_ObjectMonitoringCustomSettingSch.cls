@IsTest
private class Test_ObjectMonitoringCustomSettingSch {

    @IsTest
    private static void testObjectMonitoringScheduler() {
        Test.startTest();
        ObjectMonitoringCustomSettingScheduler scheduler = new ObjectMonitoringCustomSettingScheduler();
        String jobId = System.schedule('Test run schedule', '0 59 * * * ?', scheduler);
        Test.stopTest();
        List<CronTrigger> lt = [SELECT Id FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(1, lt.size(), 'Job is scheduled');
    }
}