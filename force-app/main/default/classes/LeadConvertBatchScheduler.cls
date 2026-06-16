global class LeadConvertBatchScheduler implements Schedulable{
    global void execute(SchedulableContext sc){
        LeadConvertBatch leadConvertBatch = new LeadConvertBatch();        
        String batchID = database.executeBatch(leadConvertBatch,1);
        System.debug('batchID for LeadConvertBatch '+batchID);
    }
}