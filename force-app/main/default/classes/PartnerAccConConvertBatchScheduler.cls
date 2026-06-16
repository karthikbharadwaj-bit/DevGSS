global class PartnerAccConConvertBatchScheduler implements Schedulable{
    global void execute(SchedulableContext sc){
        PartnerAccountContactConvertBatch  partnerAccConBatch = new PartnerAccountContactConvertBatch();        
        String batchID = database.executeBatch(partnerAccConBatch,1);
        System.debug('batchID for PartnerAccountContactConvertBatch '+batchID);
    }
}