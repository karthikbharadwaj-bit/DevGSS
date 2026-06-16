global without sharing class BatchJob_Account implements Database.Batchable<SObject>, Schedulable {
    Integer nDays = 1;
    private static Map<Id, Account> accountMap = new Map<Id, Account>();
    private static Map<Id, Account> accountMapToUpdate = new Map<Id, Account>();

    public BatchJob_Account() {
    }

    public BatchJob_Account(Integer nDays) {
        this.nDays = nDays;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(
            'SELECT Id, Name,Changes__c, CreatedBy.Name, Number_of_DL_s__c, ' +
                    'SignupPlatform__c, AH_Name__c, SignupType__c, First_Appointment_Source__c, ' +
                    'Industry,current_owner__c, Type, Most_Recent_Opportunity_Owner_Email__c, ' +
                    'Most_Recent_Opportunity_Owner__c, Service_Type__c,RC_Account_Status__c, RC_Upgrade_Date__c, ' +
                    'Most_Recent_Implementation_Contact__c, Funnel_not_supported__c ' +
            'FROM Account ' +
            'WHERE Account.LastModifiedDate >= LAST_N_DAYS:' + nDays
        );
    }

    global void execute(Database.BatchableContext param1, List<SObject> scope) {
        List<Account> accounts = (List<Account>) scope;
        accountMap = new Map<Id, Account>(accounts);

        updateAccounts(AccountTriggerHelperExt.Update_Account_CountOfOrder (accountMap));
        GraduationScoreCardHelper.calculateGraduationCompletionRate(accounts, accountMap);

        if (accountMap.size() > 0) {
            update accountMapToUpdate.values();
        }
    }

    private void updateAccounts(Map<Id, Account> currentAccountMap) {
        if (currentAccountMap != null && currentAccountMap.size() > 0) {
            accountMapToUpdate.putAll(currentAccountMap);
        }
    }

    global void execute(SchedulableContext schedulableContext) {
        BatchJobsConfiguration__c configForBatchJob = BatchJobsConfiguration__c.getValues('BatchJob_Account');
        Integer chunkSizeLimit = 50;
        if (configForBatchJob != null) {
            if (configForBatchJob.ChunkSizeLimit__c != null) {
                chunkSizeLimit = (Integer) configForBatchJob.ChunkSizeLimit__c;
            }
        }

        BatchJob_Account batch = new BatchJob_Account(nDays);
        Database.executeBatch(batch, chunkSizeLimit);
    }

    global void finish(Database.BatchableContext context) {
    }
}