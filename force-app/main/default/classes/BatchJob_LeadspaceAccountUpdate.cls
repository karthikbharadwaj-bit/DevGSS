global class BatchJob_LeadspaceAccountUpdate implements Database.Batchable<sObject>, Schedulable, Database.Stateful {
    global ContactData.IContactData contactDataInstance = new ContactData();
    @TestVisible List<SaveResultWrapper> saveResults = new List<SaveResultWrapper>();
    String query = 'SELECT Id ' +
                    'FROM Account ' +
                    'WHERE RunContactMostFrequentEmail__c = true ';

    global Database.QueryLocator start(Database.BatchableContext BC) {
        String limitToApply = '';
        if(RingCentralVariousSettings__c.getInstance().LSMostFrequentEmailMaxNumberRecords__c != null){
            limitToApply = 'LIMIT ' + RingCentralVariousSettings__c.getInstance().LSMostFrequentEmailMaxNumberRecords__c.intValue();
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
            performMostFrequentEmailCalculationProcess(scope);
            bypassAccountTriggers(false);
        } catch(Exception e) {
            PlatformLog.logException('BatchJob_LeadspaceAccountUpdate', e);
        }
    }

    private void performMostFrequentEmailCalculationProcess(List<sObject> scope){
        List<Contact> contacts = new List<Contact>();
        Set<Id> accIds = new Set<Id>();
        Map<Id, List<String>> accIdToEmails = new Map<Id, List<String>>();
        List<Account> accsToUpdate = new List<Account>();
        DomainManagerSvc domainManager = new DomainManagerSvc();
        Integer highestFrequency = 0;
        
        Map<Id, Account> allAccountsMap = new Map<Id, Account>((List<Account>)scope);

        for(Account acc : allAccountsMap.values()) {
            accIds.add(acc.Id);
            acc.RunContactMostFrequentEmail__c = false;
            acc.ContactMostFrequentEmailExecutionDate__c = Datetime.now();
        }

        contacts = contactDataInstance.getContactsByAccountIds(accIds);

        for(Contact con : contacts) {
            if(!String.isEmpty(con.Email)){
                String domain = domainManager.getDomainPartFromEmailAddress(con.Email);
                if(!String.isEmpty(domain) && !domainManager.domainIsInIgnoredDomainList(domain)) {
                    if(accIdToEmails.get(con.AccountId) == null) {
                        List<String> emails = new List<String>();
                        emails.add(domain);
                        accIdToEmails.put(con.AccountId, emails);
                    } else {
                        List<String> emails = accIdToEmails.get(con.AccountId);
                        emails.add(domain);
                        accIdToEmails.put(con.AccountId, emails);
                    }
                }
            }
        }
        
        for(Id accId : accIdToEmails.keySet()) {
            Account acc = allAccountsMap.get(accId);

            if(accIdToEmails.get(accId) != null) {
                Map<String, Integer> emailFrequency = new Map<String, Integer>();

                for(String email : accIdToEmails.get(accId)) {
                    if(emailFrequency.get(email) == null) {
                        emailFrequency.put(email, 1);
                    } else {
                        Integer frequency = emailFrequency.get(email); 
                        emailFrequency.put(email, ++frequency);
                    }
                }
                highestFrequency = 0;
                for(String email : emailFrequency.keySet()) {
                    if(emailFrequency.get(email) > highestFrequency) {
                        acc.ContactMostFrequentEmail__c = 'john.doe@' + email;
                        //CMR-221423 : Add logic to populate Website value with most frequent email domain for non-Partner Accounts (Since triggers are bypassed)
                        if(acc.RecordTypeId != AccountHelper.RT_ID_PARTNER_ACCOUNT){
                            acc.Website = email;
                        }
                        highestFrequency = emailFrequency.get(email);
                    }
                }
            }
        }
        
        for (Account acc : allAccountsMap.values()) {
            if (!hasRequiredInputFields(acc)) {
                //acc.LS_Status__c = LeadSpaceEnrichmentSvc.NOT_ENRICHED;
                acc.LS_Enrichment_Date__c = Date.today();
                //acc.LS_APIEnrichmentResult__c = LeadSpaceEnrichmentSvc.FIELD_REQUIRED_ERROR;
            }
        }
        Database.SaveResult[] updateResults = Database.update(allAccountsMap.values(), false);
        for (Database.SaveResult updateRes : updateResults) {
            SaveResultWrapper wrap = new SaveResultWrapper(updateRes.isSuccess(), updateRes.getId(), updateRes.getErrors());
            saveResults.add(wrap);
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        List<PlatformLog__c> logs = new List<PlatformLog__c>();
        for (SaveResultWrapper result : saveResults) {
            if (!result.isSuccess) {
                for (SaveResultWrapper.ErrorWrapper err : result.errorResults) {
                    PlatformLog__c log = new PlatformLog__c();
                    log.Source__c = 'BatchJob_LeadspaceAccountUpdate';
                    log.Error__c = 'Failed to update Account! ' + err.statusCode + ': ' + err.message;
                    logs.add(log);
                }
            }
        }
        if(logs.size() > 0){
            PlatformLog.logResults(logs);
        }
    }

    public Void execute(SchedulableContext context) {
        Integer chunkSize = (Integer)RingCentralVariousSettings__c.getInstance().LSMostFrequentEmailChunkSize__c;
        BatchJob_LeadspaceAccountUpdate batchToSchedule = new BatchJob_LeadspaceAccountUpdate();
        Database.executeBatch(batchToSchedule, chunkSize);
    }
    
    public Boolean hasRequiredInputFields(Account acc) {
        Boolean hasRequired = true;
        DomainManagerSvc domainManager = new DomainManagerSvc();
        String websiteDomain = domainManager.getDomainPartFromUrl(acc.Website);
        if ((String.isEmpty(acc.Website)
              || domainManager.domainIsInIgnoredDomainList(websiteDomain))
            && String.isEmpty(acc.ContactMostFrequentEmail__c)) {
            hasRequired = false;
        }
        return hasRequired;
        
    }
    
}