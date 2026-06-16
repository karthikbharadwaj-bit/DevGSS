public class BatchJob_CheckCompanyPersonType implements Database.Batchable<sObject>, Schedulable, Database.Stateful {

    List<AsyncApexJob> lastBatchRun = [SELECT CompletedDate 
                                        FROM AsyncApexJob 
                                        WHERE ApexClass.Name = 'BatchJob_CheckCompanyPersonType' 
                                        AND CompletedDate != null 
                                        ORDER BY CompletedDate DESC 
                                        LIMIT 1];

    private String query = 'SELECT Id, The_Set__c ' +
                    'FROM Lead ' +
                    'WHERE Id IN (SELECT Lead__c ' +
                                'FROM Company_Persons__c ' +
                                'WHERE Lead__c != null ' +
                                (lastBatchRun.isEmpty() 
                                ? ''
                                : 'AND LastModifiedDate >= ' +
                                lastBatchRun.get(0).CompletedDate.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'')) + ') ' +
                    'AND isConverted = false ' +
                    'AND (NOT (Status = \'0. Downgraded\' ' +
                        'AND Downgrade_Reason__c = null))';
    public Integer maxRecords = (Integer) RingCentralVariousSettings__c.getInstance()
                                                                        .CompanyPersonTypeBatchMaxRecords__c;
    private Integer chunkSize = (Integer) RingCentralVariousSettings__c.getInstance()
                                                                        .CompanyPersonTypeBatchChunkSize__c;

    public BatchJob_CheckCompanyPersonType() {
        if (maxRecords != null && maxRecords > 0) {
            this.query += ' LIMIT ' + maxRecords;
        }
    }

    public BatchJob_CheckCompanyPersonType(Boolean isDesc) {
        if (isDesc) {
            this.query += ' ORDER BY LastModifiedDate DESC';
        } else {
            this.query += ' ORDER BY LastModifiedDate ASC';
        }
        if (maxRecords != null && maxRecords > 0) {
            this.query += ' LIMIT ' + maxRecords;
        }
    }

    public BatchJob_CheckCompanyPersonType(String leadId) {
        this.query = 'SELECT Id, The_Set__c ' +
                    'FROM Lead ' +
                    'WHERE Id = \'' + leadId + '\'';
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Lead> scope) {
        try {
            LeadTriggerHelper.skipLeadTriggerOnUpdateFromCompanyPersonBatch = true;
            turnLeadTrigger(true);
            populateLeadSetField(scope);
            turnLeadTrigger(false);
        } catch(Exception e) {
            PlatformLog.logException('BatchJob_CheckCompanyPersonType: ', e);
        }
    }

    private void turnLeadTrigger(Boolean bypass) {
        TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = bypass;
        TriggerHandler.BY_PASS_LEAD_UPDATE = bypass;
        if (bypass) {
            Triggers.switchOff();
        } else {
            Triggers.switchOn();
        }
    }

    private void populateLeadSetField(List<Lead> scope) {
        Set<Id> leadIds = new Set<Id>();
        Map<Id, String> typeByLeadId = new Map<Id, String>();

        for (Lead ld : scope) {
            if (ld.Id != null) {
                leadIds.add(ld.Id);
            }
        }
        if (!leadIds.isEmpty()) {
            for (Company_Persons__c person : [
                                                SELECT Lead__c, Company_Person_Type__c
                                                FROM Company_Persons__c
                                                WHERE Lead__c IN : leadIds
                                                ORDER BY LastModifiedDate ASC
                                                ]) {
                typeByLeadId.put(person.Lead__c, person.Company_Person_Type__c);
            }
            if (!typeByLeadId.isEmpty()) {
                for (Lead ld : scope) {
                    ld.The_Set__c = (!String.isBlank(typeByLeadId.get(ld.Id))
                                    && typeByLeadId.get(ld.Id).containsIgnoreCase('The Set'))
                                    ? 'Yes'
                                    : 'No';
                }
                update scope;
            }
        }
    }

    public void finish(Database.BatchableContext bc) {}

    public void execute(SchedulableContext context) {
        BatchJob_CheckCompanyPersonType batchJob = new BatchJob_CheckCompanyPersonType(true);
        if (chunkSize != null && chunkSize > 0) {
            Database.executeBatch(batchJob, chunkSize);
        } else {
            Database.executeBatch(batchJob);
        }
    }
}