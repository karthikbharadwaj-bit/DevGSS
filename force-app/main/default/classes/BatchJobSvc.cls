global abstract class BatchJobSvc implements Database.Batchable<sObject>, Schedulable {
    @TestVisible protected Database.SaveResult[] databaseResults = new Database.SaveResult[]{};
    private Integer batchSizeLimit = null;
    protected Integer chunkSizeLimit = null;
    protected String errorEmailDistributionList = null;

    global abstract String getBatchJobClassName();
    global abstract void bypassTriggers(Boolean bypass);
    global abstract void performChunkExecution(List<sObject> scope);

    protected String getLimitToApply(){
        String limitToApply = '';
        if(batchSizeLimit != null){
            limitToApply = ' LIMIT ' + batchSizeLimit;
        }
        return limitToApply;
    }

    protected BatchJobSvc(){
        BatchJobsConfiguration__c configForBatchJob = BatchJobsConfiguration__c.getValues(getBatchJobClassName());
        chunkSizeLimit = 200;
        if(configForBatchJob != null){
            batchSizeLimit = (Integer) configForBatchJob.BatchSizeLimit__c;
            if(configForBatchJob.ChunkSizeLimit__c != null){
                chunkSizeLimit = (Integer) configForBatchJob.ChunkSizeLimit__c;
            }
            errorEmailDistributionList = configForBatchJob.ErrorEmailDistributionList__c;
        }
    }

    global void finish(Database.BatchableContext BC) {
        List<PlatformLog__c> logs = new List<PlatformLog__c>();
        Integer countErrors = 0;
        for(Database.SaveResult result : databaseResults) {
            if(countErrors > 200){
                break;
            }

            if(!result.isSuccess()) {
                for(Database.Error err : result.getErrors()) {
                    PlatformLog__c log = new PlatformLog__c();
                    log.Source__c = getBatchJobClassName();
                    log.Error__c = 'Failed record: ' + err.getStatusCode() + ': ' + err.getMessage();
                    logs.add(log);
                    countErrors++;
                }
            }
        }

        if(logs.size() > 0){
            PlatformLog.logResults(logs);
        }
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        try{
            bypassTriggers(true);
            performChunkExecution(scope);
            bypassTriggers(false);
        } catch(Exception e) {
            PlatformLog.logException(getBatchJobClassName(), e);
        }
    }

}