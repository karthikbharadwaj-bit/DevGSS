public class BatchJob_MaintenanceCasesCloseScheduler implements Schedulable {
    public final static String BATCH_JOB_SCHEDULER_NAME = 'BatchJob_MaintenanceCasesCloseScheduler';
    public final static Integer CHUNK_SIZE = 50;

    public void execute(SchedulableContext sc) {
        if (!AsyncApexJobSvc.isJobScheduled(BATCH_JOB_SCHEDULER_NAME)) {
            Database.executeBatch(new BatchJob_MaintenanceCasesClose(), CHUNK_SIZE);
        }
    }
}