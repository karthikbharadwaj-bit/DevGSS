/**
Class to handle the events and execute the Helper for each type of error or for each job from which the error can arrive.
The coverage is achieved with the test classes of the helpers.
*/

public with sharing class BatchApexErrorEventHandler { 
    
    public static void HandleBatchApexErrorEvent(List<BatchApexErrorEvent> evts) {
        Set<Id> asyncApexJobIds = new Set<Id>();
        for(BatchApexErrorEvent evt: evts){
            asyncApexJobIds.add(evt.AsyncApexJobId);
        }
        
        Map<Id,AsyncApexJob> jobs = new Map<Id,AsyncApexJob>(
            [SELECT id, ApexClass.Name FROM AsyncApexJob WHERE Id IN :asyncApexJobIds]
        );
        
        for(BatchApexErrorEvent evt: evts){
            //only handle events for the job(s) we care about
            if(jobs.get(evt.AsyncApexJobId).ApexClass.Name == DFRUpdateFieldsHelper.BATCHJOB_DFRUPDATEFIELDS) {
                DFRUpdateFieldsHelper.handleBatchError(evt);
            }
        }
    }
}