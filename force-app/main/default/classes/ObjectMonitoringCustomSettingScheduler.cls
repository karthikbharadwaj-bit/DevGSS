global class ObjectMonitoringCustomSettingScheduler implements Schedulable {

    private static final Integer BATCH_LIMIT_ROW = 5;

    global ObjectMonitoringCustomSettingScheduler() {}

    global void execute(SchedulableContext ctx) {
        if(!Test.isRunningTest()){
            Database.executeBatch(new BatchObjectMonitoringForCustomSettings(), BATCH_LIMIT_ROW);
        }
    }
}