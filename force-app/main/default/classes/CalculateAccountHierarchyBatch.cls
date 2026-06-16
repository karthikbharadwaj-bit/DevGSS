public with sharing class CalculateAccountHierarchyBatch implements Database.Batchable<SObject>, Database.Stateful {
    private Boolean isTestRun = false;
    public String batchJobQueueId;
    private static String CUSTOMER_ACCOUNT = 'Customer Account';
    private Set<String> processedUltimateParentIds;
    @testVisible private String queryString = '' +
        'SELECT id,Ultimate_Parent_Account_ID__c,RC_Account_Status__c, ' +
        'Ultimate_Parent_Snapshot__c, Number_of_DL_s__c,Total_DLs__c, Name ' +
        'FROM Account ' +
        'WHERE RecordType.Name =: CUSTOMER_ACCOUNT';

    private Set<String> ultimateParentIdSetToQuery = new Set<String>();

    public CalculateAccountHierarchyBatch() {
        processedUltimateParentIds = new Set<String>();
        List<BatchJobQueue__c> bjq = (List<BatchJobQueue__c>) new BatchJobQueueSelector()
             .selectBatchJobQueueObjects()
             .setCondition('BatchJobName__c = \'CalculateAccountHierarchyBatch\' AND (Status__c = \'New\' OR Status__c = \'NoSpaceInQueue\')')
             .addOrdering(BatchJobQueue__c.CreatedDate, QueryFactory.SortOrder.ASCENDING)
             .executeQuery();
        if (bjq != null && !bjq.isEmpty() && String.isNotBlank(bjq[0].RecordIdsToBeProcessedInQueue__c )) {
            for (String value : bjq[0].RecordIdsToBeProcessedInQueue__c.split(',')) {
                ultimateParentIdSetToQuery.add(value);
            }
        }
        addIdConditionToQueryString();
    }

    public CalculateAccountHierarchyBatch(Boolean isTestRun) {
        this();
        this.isTestRun = isTestRun;
    }

    public CalculateAccountHierarchyBatch(String whereClause, Boolean isTestRun) {
        this(isTestRun);
        if (String.isNotBlank(whereClause)) {
            queryString += whereClause;
        }
    }

    public CalculateAccountHierarchyBatch(Set<String> ultimateParentIdSet, Boolean isTestRun) {
        this(isTestRun);
        if (ultimateParentIdSet != null && ultimateParentIdSet.size() > 0) {
            ultimateParentIdSetToQuery = ultimateParentIdSet;
        }
        addIdConditionToQueryString();
    }

    public CalculateAccountHierarchyBatch(Set<String> ultimateParentIdSet, String bJQId, Boolean isTestRun) {
        this(isTestRun);
        if (ultimateParentIdSet != null && ultimateParentIdSet.size() > 0) {
            ultimateParentIdSetToQuery = ultimateParentIdSet;
        }
        addIdConditionToQueryString();

        if (bJQId != null) {
            batchJobQueueId = bJQId;
        }
    }

    private void addIdConditionToQueryString() {
        queryString +=
                ' AND (Ultimate_Parent_Snapshot__c IN : ultimateParentIdSetToQuery ' +
                    'OR Id IN : ultimateParentIdSetToQuery) ';
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(queryString);
    }

    public void execute(Database.BatchableContext BC, List<SObject> scope) {
        List<Account> processingAccs = (List<Account>) scope;

        Set<String> ultimateParentIdSet = getActualParentIdSet(processingAccs);

        if (ultimateParentIdSet.size() < 1) {
            return;
        }

        List<Account> accountsUnderUltimateParentId =
            AccountTriggerHelperExt.queryAccountsForHierarchyCalculation(ultimateParentIdSet);

        if (!isTestRun) {
            AccountTriggerHelperExt.calculateAccountHierarchyTotalDLS(accountsUnderUltimateParentId);
        }

        processedUltimateParentIds.addAll(ultimateParentIdSet);
    }

    public void finish(Database.BatchableContext BC) {
        List<BatchJobQueue__c> errorsBJQ = [
            SELECT Id, RecordIdsToBeProcessedInQueue__c, Status__c, ExceptionMessage__c
            FROM BatchJobQueue__c
            WHERE Id =: batchJobQueueId
            LIMIT 1
        ];

        if (!errorsBJQ.isEmpty() && errorsBJQ[0].Status__c == 'Failed') {
            sendEmailWithFailedRecords(errorsBJQ[0]);
        }
    }

    private Set<String> getActualParentIdSet(List<Account> processingAccs) {
        Set<String> ultimateParentIdSet = getUltimateParentIdSetFromAccounts(processingAccs);
        ultimateParentIdSet = removeAllProcessedIds(ultimateParentIdSet);
        System.debug('ultimateParentIdSet after removal ' + ultimateParentIdSet);
        return ultimateParentIdSet;
    }

    private Set<String> getUltimateParentIdSetFromAccounts(List<Account> accs) {
        Set<String> ultimateParentIds = new Set<String>();
        for (Account acc : accs) {
            if (acc.Ultimate_Parent_Snapshot__c == null) {
                continue;
            }
            ultimateParentIds.add(acc.Ultimate_Parent_Snapshot__c);
        }
        return ultimateParentIds;
    }

    private Set<String> removeAllProcessedIds(Set<String> ultimateParentIdSet) {
        Set<String> ultimateParentIdToProcess = ultimateParentIdSet;
        ultimateParentIdToProcess.removeAll(processedUltimateParentIds);
        return ultimateParentIdToProcess;
    }

    public static void sendEmailWithFailedRecords(BatchJobQueue__c batchJobQueue) {

        if (batchJobQueue == null) {
            return;
        }

        BatchJobsConfiguration__c bjc = BatchJobsConfiguration__c.getValues('CalculateAccountHierarchyBatch');
        List<String> emailsToSend = bjc.ErrorEmailDistributionList__c.split(',');

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.saveAsActivity = false;
        mail.setBccAddresses(emailsToSend);
        mail.setSubject('CalculateAccountHierarchyBatch job has failed');
        mail.setPlainTextBody('' +
            'Admin:\n' +
            'Batch job record in BatchJobQueue__c failed:\n\n' +
            'BatchJobQueue object id(s): ' + batchJobQueue.Id + '\n' +
            'Exception message: ' + batchJobQueue.ExceptionMessage__c + '\n' +
            'Environment: ' + URL.getOrgDomainUrl().toExternalForm() + '\n\n' +
            'Please review and proceed to rerun and/or fix.\n' +
            'Thanks'
        );
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
    }
}