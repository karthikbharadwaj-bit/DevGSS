global class BatchJob_AccountDatePopulation extends BatchJobSvc {
    Integer nDays = 1;
    private static Map<Id, Account> accountMap = new Map<Id, Account>();
    private static Map<Id, Account> accountMapToUpdate = new Map<Id, Account>();

    public BatchJob_AccountDatePopulation() {
    }

    public BatchJob_AccountDatePopulation(Integer nDays) {
        this.nDays = nDays;
    }

    global override String getBatchJobClassName() {
        return 'BatchJob_AccountDatePopulation';
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

        updateAccounts(datePopulationForAgreementsandAmendments(accounts));

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
            'WHERE Account.LastModifiedDate >= LAST_N_DAYS:' + nDays);
    }

    public void execute(SchedulableContext context) {
        bypassTriggers(true);
        BatchJob_AccountDatePopulation batchToSchedule = new BatchJob_AccountDatePopulation();
        Database.executeBatch(batchToSchedule, chunkSizeLimit);
    }

    private void updateAccounts(Map<Id, Account> currentAccountMap) {
        if (currentAccountMap != null && currentAccountMap.size() > 0) {
            accountMapToUpdate.putAll(currentAccountMap);
        }
    }

    private Map<Id, Account> datePopulationForAgreementsandAmendments(List<Account> accounts) {
        Map<Id, String> accIdToIndustryMap = new Map<Id, String>();
        List<Opportunity> oppList = new List<Opportunity>();
        Map<Id, Account> accountsToUpdate = new Map<Id, Account>();
        List <Quote> quotesToUpdate = new List <Quote>();
        List <Opportunity> allOppsList = [
            SELECT Id, AccountId, Industry__c, Account.Changes__c,Account.RC_Upgrade_Date__c,
            (SELECT Id, Name, Status, QuoteType__c, Start_Date__c, End_Date__c, Initial_Term_months__c FROM Quotes)
            FROM Opportunity
            WHERE AccountId IN:accounts
        ];

        if (allOppsList.isEmpty()) {
            return accountsToUpdate;
        }

        //Create a Map of AccountId to Opportunities
        Map <Id, List<Opportunity>> accIdToOptyMap = new Map<Id, List<Opportunity> >();
        for (Opportunity opty : allOppsList) {
            if (accIdToOptyMap.containsKey(opty.AccountId)) {
                List <Opportunity> listOfOpps = accIdToOptyMap.get(opty.AccountId);
                listOfOpps.add(opty);
                accIdToOptyMap.put(opty.AccountId, listOfOpps);
            } else {
                accIdToOptyMap.put(opty.AccountId, new List <Opportunity> {
                    opty
                });
            }
        }

        for (Account newAccObj : accounts) {
            if (accIdToOptyMap.get(newAccObj.Id) != null) {
                oppList.addAll(accIdToOptyMap.get(newAccObj.Id));
                accIdToIndustryMap.put(newAccObj.Id, newAccObj.Industry);
                if (newAccObj.Changes__c != null && newAccObj.Changes__c.contains('RC_Upgrade_Date__c')) {
                    //B-2964 Start Date population for Agreements and Amendments
                    for (Opportunity opp : accIdToOptyMap.get(newAccObj.Id)) {
                        for (Quote q : opp.Quotes) {
                            if (q.Status == 'Active' && q.QuoteType__c == 'Agreement') {
                                q.Start_Date__c = newAccObj.RC_Upgrade_Date__c.date();
                                Integer quoteInitialTermMonths = q.Initial_Term_months__c == null ?
                                    0 : Integer.valueOf(q.Initial_Term_months__c);
                                q.End_Date__c = newAccObj.RC_Upgrade_Date__c.date().addMonths(quoteInitialTermMonths);
                                quotesToUpdate.add(q);
                            }
                        }
                    }
                    //Remove RC_Upgrade_Date__c value from picklist
                    newAccObj.Changes__c = newAccObj.Changes__c.remove(';RC_Upgrade_Date__c');
                    accountsToUpdate.put(newAccObj.Id, newAccObj);
                }
            }
        }
        update quotesToUpdate;
        return accountsToUpdate;
    }
}