global class BatchJob_AccountUpdateContactStatus extends BatchJobSvc {
    Integer nDays = 1;
    private static Map<Id, Account> accountMap = new Map<Id, Account>();
    private static Map<Id, Account> accountMapToUpdate = new Map<Id, Account>();

    public BatchJob_AccountUpdateContactStatus() {
    }

    public BatchJob_AccountUpdateContactStatus(Integer nDays) {
        this.nDays = nDays;
    }

    global override String getBatchJobClassName() {
        return 'BatchJob_AccountUpdateContactStatus';
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

        updateAccounts(updateContactStatus(accountMap));

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
        BatchJob_AccountUpdateContactStatus batchToSchedule = new BatchJob_AccountUpdateContactStatus();
        Database.executeBatch(batchToSchedule, chunkSizeLimit);
    }

    private void updateAccounts(Map<Id, Account> currentAccountMap) {
        if (currentAccountMap != null && currentAccountMap.size() > 0) {
            accountMapToUpdate.putAll(currentAccountMap);
        }
    }

    private static Map<Id, Account> updateContactStatus(Map<Id, Account> accMap) {
        Map<Id, Account> accsToUpdate = new Map<Id, Account>();
        Set<Id> accIds = new Set<Id>();
        Map<String, String> accStatus = new Map<String, String>();
        List<Contact> contactsToUpdate = new List<Contact>();
        Map<Id, Id> accCurrentOwnerMap = new Map<Id, Id>();
        try {
            for (Account acc : accMap.values()) {
                if (acc.Changes__c != null && acc.Changes__c.contains('ContactStatusNeedsToUpdate')) {
                    accIds.add(acc.Id);
                    accStatus.put(acc.Id, acc.RC_Account_Status__c);
                    acc.Changes__c = acc.Changes__c.remove(';ContactStatusNeedsToUpdate');
                    accsToUpdate.put(acc.Id, acc);
                }
                if (acc.Changes__c != null && acc.Changes__c.contains('Current_Owner__c')) {
                    accIds.add(acc.Id);
                    accCurrentOwnerMap.put(acc.Id, acc.Current_Owner__c);
                    acc.Changes__c = acc.Changes__c.remove(';Current_Owner__c');
                    accsToUpdate.put(acc.Id, acc);
                }
            }
            if (accIds.size() > 0 && accStatus.size() > 0) {
                for (Contact conObj : [
                    SELECT Id,AccountId, isCustomer__c, Contact_Status__c, People_Segment__c,
                        RCService_ContactStatus__c, Account.Current_Owner__c,
                        Contact_Funnel_Type__c, Account.Current_Owner__r.IsActive, OwnerId
                    FROM Contact
                    WHERE AccountId IN :accIds
                ]) {
                    if (conObj.Contact_Status__c == '0. Downgraded' || conObj.Contact_Status__c == null) {
                        String upcomingStatus = accStatus.get(conObj.AccountId);
                        Boolean paIdBool = false;
                        Boolean canceledBool = false;
                        if ('PaId'.equalsIgnoreCase(upcomingStatus)) {
                            paIdBool = true;
                        } else if (('Cancelled'.equalsIgnoreCase(upcomingStatus) ||
                            'Canceled'.equalsIgnoreCase(upcomingStatus))) {
                            canceledBool = true;
                        }
                        conObj.Contact_Funnel_Type__c =
                            (paIdBool ? 'Customer' : (canceledBool ? 'Winback' : conObj.Contact_Funnel_Type__c));
                        conObj.isCustomer__c = (paIdBool ? true : (canceledBool ? false : conObj.isCustomer__c));
                        conObj.People_Segment__c =
                            (paIdBool ? 'Customer' : (canceledBool ? 'Former Customer' : conObj.People_Segment__c));
                        conObj.Contact_Status__c = '4. Customer';

                        if (accCurrentOwnerMap != null && accCurrentOwnerMap.get(conObj.AccountId) != null) {
                            conObj.OwnerId = accCurrentOwnerMap.get(conObj.AccountId);
                        }
                        contactsToUpdate.add(conObj);
                    } else {
                        if (accCurrentOwnerMap != null && accCurrentOwnerMap.get(conObj.AccountId) != null) {
                            if (conObj.OwnerId != accCurrentOwnerMap.get(conObj.AccountId)) {
                                conObj.OwnerId = accCurrentOwnerMap.get(conObj.AccountId);
                            }
                        }
                        contactsToUpdate.add(conObj);
                    }
                }

                if (contactsToUpdate.size() > 0) {
                    update contactsToUpdate;
                }
            }
        } catch (Exception ex) {
            System.debug('Exception===========' + ex.getStackTraceString());
        }
        return accsToUpdate;
    }
}