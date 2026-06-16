public class ScheduleJob_PermSetCngsFileGenerator implements Schedulable {
    public void execute(SchedulableContext sc) {
        BatchJob_PermSetChangesFileGenerator batch = new BatchJob_PermSetChangesFileGenerator();
        Database.executeBatch(batch, 200);
    }
}