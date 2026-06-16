global class GatingSegmentationBatchScheduler implements Schedulable{
    global void execute(SchedulableContext sc){
        BatchJob_GatingSegmentationUpdate gatingSegmentationBatch = new BatchJob_GatingSegmentationUpdate();        
        String batchID = Database.executeBatch(gatingSegmentationBatch,200);
        System.debug('batchID for BatchJob_GatingSegmentationUpdate '+batchID);
    }
}