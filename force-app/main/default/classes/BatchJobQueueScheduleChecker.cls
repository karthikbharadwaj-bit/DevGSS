public with sharing class BatchJobQueueScheduleChecker implements Schedulable {
    public void execute(SchedulableContext sc) {
        if (!AsyncApexJobSvc.isJobScheduled(BatchJobQueueScheduler.BATCH_JOB_QUEUE_SCHEDULER)) {
            BatchJobQueueScheduler scheduler = new BatchJobQueueScheduler();
            Integer minuteToRun = System.now().minute() + 1;
            System.schedule(
                BatchJobQueueScheduler.BATCH_JOB_QUEUE_SCHEDULER + ' ' + System.now(),
                '0 ' + minuteToRun + ' * * * ?',
                scheduler
            );
        }
    }
}