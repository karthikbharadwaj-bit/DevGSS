public class BatchJob_DeleteMainDataSched implements Schedulable {
    public void execute(SchedulableContext sc) {
        BatchJob_DeleteMainData batch = new BatchJob_DeleteMainData();
        Database.executeBatch(batch, batch.getScope());
    }
}