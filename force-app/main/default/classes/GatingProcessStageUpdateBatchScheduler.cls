global class GatingProcessStageUpdateBatchScheduler implements Schedulable{
    global void execute(SchedulableContext sc){
        BatchJob_GatingProcessStageUpdate gatingProcessStageBatch = new BatchJob_GatingProcessStageUpdate();        
        String batchID = Database.executeBatch(gatingProcessStageBatch,200);
        System.debug('batchID for BatchJob_GatingProcessStageUpdate '+batchID);
    }
}