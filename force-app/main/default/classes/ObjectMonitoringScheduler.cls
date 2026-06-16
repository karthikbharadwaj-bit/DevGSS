/**
 * Created by Makhmud.Shafeev on 8/31/2021.
 */

global class ObjectMonitoringScheduler implements Schedulable {

    private static final Integer BATCH_LIMIT_ROW = 200;
    private static String soql = ObjectMonitoringHelper.soqlOlder2Weeks;

    global ObjectMonitoringScheduler(){
    }

    global ObjectMonitoringScheduler(String soqlQuery) {
        if (soqlQuery != null) {
            soql = soqlQuery;
        }
    }

    global void execute(SchedulableContext ctx) {
        if(!Test.isRunningTest()){
            String jobId = Database.executeBatch(new BatchObjectMonitoring(soql), BATCH_LIMIT_ROW);
            System.debug('ObjectMonitoringScheduler jobId ' + jobId);
        }
    }
}