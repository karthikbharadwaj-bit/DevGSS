global class BatchJob_AccountFirstAppointmentSource extends BatchJobSvc {
    Integer nDays = 1;
    private static Map<Id, Account> accountMap = new Map<Id, Account>();
    private static Map<Id, Account> accountMapToUpdate = new Map<Id, Account>();

    public BatchJob_AccountFirstAppointmentSource() {
    }

    public BatchJob_AccountFirstAppointmentSource(Integer nDays) {
        this.nDays = nDays;
    }

    global override String getBatchJobClassName() {
        return 'BatchJob_AccountFirstAppointmentSource';
    }

    global override void bypassTriggers(Boolean bypass) {
        TriggerHandler.BY_PASS_ACCOUNT_ON_AFTER = bypass;
        TriggerHandler.BY_PASS_ACCOUNT_ON_BEFORE = bypass;
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = bypass;
        TriggerHandler.BY_PASS_PARTNER_ACCOUNT_ON_AFTER = bypass;
        TriggerHandler.BY_PASS_PARTNER_ACCOUNT_ON_BEFORE = bypass;
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = bypass;
        if (bypass) {
            Triggers.switchOff();
        } else {
            Triggers.switchOn();
        }
    }

    global override void performChunkExecution(List<SObject> scope) {
        List<Account> accounts = (List<Account>) scope;
        accountMap = new Map<Id, Account>(accounts);

        updateAccounts(AccountTriggerHelperExt.populateFirstAppointmentSource(accountMap));

        if (accountMap.size() > 0) {
            update accountMapToUpdate.values();
        }
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator('SELECT Id, Name,Changes__c, CreatedBy.Name, Number_of_DL_s__c, ' +
            'SignupPlatform__c, AH_Name__c, SignupType__c, First_Appointment_Source__c, ' +
            'Industry,current_owner__c, Type, Most_Recent_Opportunity_Owner_Email__c, ' +
            'Most_Recent_Opportunity_Owner__c, Service_Type__c,RC_Account_Status__c, RC_Upgrade_Date__c, ' +
            'Most_Recent_Implementation_Contact__c ' +
            'FROM Account ' +
            'WHERE First_Appointment_Source__c = null AND LastModifiedDate >= LAST_N_DAYS:' + nDays + ' ' +
            'LIMIT 20000');
    }

    public void execute(SchedulableContext context) {
        bypassTriggers(true);
        BatchJob_AccountFirstAppointmentSource batchToSchedule = new BatchJob_AccountFirstAppointmentSource();
        Database.executeBatch(batchToSchedule, chunkSizeLimit);
    }

    private void updateAccounts(Map<Id, Account> currentAccountMap) {
        if (currentAccountMap != null && currentAccountMap.size() > 0) {
            accountMapToUpdate.putAll(currentAccountMap);
        }
    }
}