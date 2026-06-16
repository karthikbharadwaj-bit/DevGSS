public class ScheduleJob_DeltaFilesUploadToGCS implements Schedulable {
    public void execute(SchedulableContext sc) {
        BatchJob_DeltaFilesUploadToGCS batch = new BatchJob_DeltaFilesUploadToGCS();
        Database.executeBatch(batch, 20);
    }
}