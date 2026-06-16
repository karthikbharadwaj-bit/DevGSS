global without sharing class BatchJob_AccountCompanyTotals implements Database.Batchable<sObject>, Schedulable {
    Integer nDays = 1;
    private static Map<Id, Account> accountMap = new Map<Id, Account>();
    private static Map<Id, Account> accountMapToUpdate = new Map<Id, Account>();
    private static List<Lead> leadList = new List<Lead>();

    public BatchJob_AccountCompanyTotals() {
    }

    public BatchJob_AccountCompanyTotals(Integer nDays) {
        this.nDays = nDays;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator('SELECT Id, Name, Changes__c, CreatedBy.Name, Number_of_DL_s__c, ' +
                'SignupPlatform__c, AH_Name__c, SignupType__c, First_Appointment_Source__c, ' +
                'Industry, current_owner__c, Type, Most_Recent_Opportunity_Owner_Email__c, ' +
                'Most_Recent_Opportunity_Owner__c, Service_Type__c, RC_Account_Status__c, RC_Upgrade_Date__c, ' +
                'Most_Recent_Implementation_Contact__c ' +
                'FROM Account ' +
                'WHERE Account.LastModifiedDate >= LAST_N_DAYS:' + nDays);
    }

    global void execute(Database.BatchableContext param1, List<sObject> scope) {
        List<Account> accounts = (List<Account>) scope;
        accountMap = new Map<Id, Account>(accounts);
        updateAccounts(updateCompanyTotalsFromAccount(accounts));
        if (accountMap.size() > 0) {
            update accountMapToUpdate.values();
        }
    }

    private Map<Id, Account> updateCompanyTotalsFromAccount(List<Account> accounts) {
        List<Id> idsList = new List<Id>();
        
        //OnInsert
        for (Account account : accounts) {
            if (account.Number_of_DL_s__c != null && account.AH_Name__c != null) {
                idsList.add((Id) account.AH_Name__c);
            }
        }
        //OnUpdate
        Map<Id, Account> accsToUpdate = new Map<Id, Account>();

        for (Account account : accounts) {
            String oldCompanyId = '';
            if (account.Changes__c != null && account.Changes__c.contains('AH_Name__c')) {
                for (String str : account.Changes__c.split(';')) {
                    if (str.contains('AH_Name__c')) {
                        oldCompanyId = str.substringAfter(':');
                        if (String.isNotBlank(oldCompanyId) && !oldCompanyId.equals('null')) {
                            idsList.add(oldCompanyId);
                        }
                        idsList.add(account.AH_Name__c);
                        account.Changes__c = account.Changes__c.remove(';' + str);
                        accsToUpdate.put(account.Id, account);
                    }
                }
            }
        }
        List<Account_Hierarchy__c> companiesList = 
            [SELECT Id, AH_Total_DLs__c, AH_Total_MRR__c, (SELECT Id, Number_of_DL_s__c FROM Accounts__r)
            FROM Account_Hierarchy__c WHERE Id in :idsList];
        for (Account_Hierarchy__c company : companiesList) {
            company.AH_Total_DLs__c = 0;
            company.AH_Total_MRR__c = 0;
            for (Account account : company.Accounts__r) {
                company.AH_Total_DLs__c += (account.Number_of_DL_s__c != null ? account.Number_of_DL_s__c : 0);
            }
        }
        update companiesList;
        return accsToUpdate;
    }

    private void updateAccounts(Map<Id, Account> currentAccountMap) {
        if (currentAccountMap != null && currentAccountMap.size() > 0) {
            accountMapToUpdate.putAll(currentAccountMap);
        }
    }

    global void execute(SchedulableContext schedulableContext) {
        BatchJobsConfiguration__c configForBatchJob = 
            BatchJobsConfiguration__c.getValues('BatchJob_AccountCompanyTotals');
        Integer chunkSizeLimit = 50;
        if(configForBatchJob != null){
            if(configForBatchJob.ChunkSizeLimit__c != null){
                chunkSizeLimit = (Integer)configForBatchJob.ChunkSizeLimit__c;
            }
        }

        BatchJob_AccountCompanyTotals batch = new BatchJob_AccountCompanyTotals(nDays);
        Database.executeBatch(batch, chunkSizeLimit);
    }

    global void finish(Database.BatchableContext context) {
    }
}