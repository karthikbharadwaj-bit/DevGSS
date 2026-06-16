global class BatchJobAccountCompanyMatching implements Database.Batchable<sObject>, Schedulable, Database.Stateful {
    @testVisible List<SaveResultWrapper> saveResults = new List<SaveResultWrapper>();
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, Company_DUNS__c, SiteDunsNumber__c, Customer_Country__c, LS_Country__c, ' +
                            'Tech_Stack_Categories__c, LS_Primary_NAICS__c, ' +
                            'AH_Name__c, LS_Account_Name__c, Name, ' +
                            'Effective_No_of_Employees_Range__c, ' +
                            'BillingCountry, Website, RC_Account_Status__c, AH_Name__r.Name, ' +
                            'CreatedBy.Name, Service_Type__c, RC_Tier__c, ContactMostFrequentEmail__c' +
                        ' FROM Account ' +
                        'WHERE AHSearchCriteriaFieldsHaveBeenModified__c = true ' +
                        'AND RunContactMostFrequentEmail__c = false ';

        String limitToApply = '';
        if(RingCentralVariousSettings__c.getInstance().AccountCompanyMatchingMaxNumberRecords__c != null){
            limitToApply = 'LIMIT ' + 
                RingCentralVariousSettings__c.getInstance().AccountCompanyMatchingMaxNumberRecords__c.intValue();
        }
        query = query + limitToApply;
        return Database.getQueryLocator(query);
    }

    private void bypassAccountTriggers(Boolean bypass){
        TriggerHandler.BY_PASS_ACCOUNT_ON_AFTER = bypass;
        TriggerHandler.BY_PASS_ACCOUNT_ON_BEFORE = bypass;
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = bypass;  
        TriggerHandler.BY_PASS_PARTNER_ACCOUNT_ON_AFTER = bypass;
        TriggerHandler.BY_PASS_PARTNER_ACCOUNT_ON_BEFORE = bypass;
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = bypass;
        if(bypass){
            Triggers.switchOff();
        } else {
            Triggers.switchOn();
        }
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        try{
            bypassAccountTriggers(true);

            bypassAccountTriggers(false);
        } catch(Exception e) {
            PlatformLog.logException('BatchJobAccountCompanyMatching general exception', e);
        }
    }

    global void execute(SchedulableContext sc) {
        Integer chunkSize = (Integer)RingCentralVariousSettings__c.getInstance().AccountCompanyMatchingChunkSize__c;
        if(chunkSize == null){
            chunkSize = 200;
        }
        BatchJobAccountCompanyMatching batchToSchedule = new BatchJobAccountCompanyMatching();
        Database.executeBatch(batchToSchedule, chunkSize);
    }

    global void finish(Database.BatchableContext BC) {
        List<PlatformLog__c> logs = new List<PlatformLog__c>();
        for (SaveResultWrapper result : saveResults) {
            if (!result.isSuccess) {
                for (SaveResultWrapper.ErrorWrapper err : result.errorResults) {
                    PlatformLog__c log = new PlatformLog__c();
                    log.Source__c = 'BatchJobAccountCompanyMatching error updating record ' + result.recordId;
                    log.Error__c = err.statusCode + ': ' +  err.message;
                    logs.add(log);
                }
            }
        }
        if (logs.size() > 0) {
            PlatformLog.logResults(logs);
        }
    }
}