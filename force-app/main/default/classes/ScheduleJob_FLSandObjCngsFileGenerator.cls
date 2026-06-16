public class ScheduleJob_FLSandObjCngsFileGenerator implements Schedulable {
    public void execute(SchedulableContext sc) {
        BatchJob_FLSandObjChangesFileGenerator batch = new BatchJob_FLSandObjChangesFileGenerator();
        Database.executeBatch(batch, 200);
    }
}