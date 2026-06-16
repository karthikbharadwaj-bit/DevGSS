global class SObjectCPUMonitorBatchScheduler implements Schedulable{
    global void execute(SchedulableContext sc){
        BatchJob_SObjectCPUMonitor sObjectCPUMonitorBatch = new BatchJob_SObjectCPUMonitor('Case');        
        String batchID = Database.executeBatch(sObjectCPUMonitorBatch,200);
        System.debug('batchID for BatchJob_SObjectCPUMonitor '+batchID);
    }
}