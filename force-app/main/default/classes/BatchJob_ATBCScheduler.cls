public class BatchJob_ATBCScheduler implements Schedulable {
    private String customQuery;
    private Integer batchScopeSize;

    public BatchJob_ATBCScheduler() {
        this(null, 200);
    }

    public BatchJob_ATBCScheduler(String customQuery, Integer batchScopeSize) {
        this.customQuery = customQuery;
        this.batchScopeSize = batchScopeSize;
    }

    public void execute(SchedulableContext sc) {
        if (String.isBlank(customQuery)) {
            Database.executeBatch(new BatchJob_ATBC(), batchScopeSize);
        } else {
            Database.executeBatch(new BatchJob_ATBC(customQuery), batchScopeSize);
        }
    }
}