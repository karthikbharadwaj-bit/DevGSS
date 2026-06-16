global class ScheduleJob_UpdateDSAAccounts implements Schedulable {
    global void execute(SchedulableContext sc) {
        BatchJob_UpdateDSAAccounts batch = new BatchJob_UpdateDSAAccounts();
        Database.executeBatch(batch, 25);
    }
}