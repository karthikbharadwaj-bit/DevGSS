global class GatingAccountBatchScheduler implements Schedulable{
    global void execute(SchedulableContext sc){
        BatchJob_AccountGatingUpdate gatingSegmentationBatch = new BatchJob_AccountGatingUpdate();        
        String batchID = Database.executeBatch(gatingSegmentationBatch,200);
        System.debug('batchID for BatchJob_AccountGatingUpdate '+batchID);
    }
}