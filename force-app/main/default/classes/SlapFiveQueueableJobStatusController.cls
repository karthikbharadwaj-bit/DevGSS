public without sharing class SlapFiveQueueableJobStatusController {
    @AuraEnabled(cacheable=false)
    public static String getAsyncApexJobStatus(Id jobId) {
        if (jobId == null) {
            return 'MissingJobId';
        } 

        AsyncApexJob job = [
            SELECT Id, Status, ExtendedStatus, NumberOfErrors
            FROM AsyncApexJob
            WHERE Id = :jobId
            LIMIT 1
        ];

        return job.Status;
    }
}