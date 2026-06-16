public with sharing class CheckCCEntlsScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        BatchJob_CheckCCEntls batch = new BatchJob_CheckCCEntls();
        Database.executebatch(batch);
    }
}