public class BatchJob_AccountsPaidAndCanceled implements Database.Batchable<SObject>{
    public static Integer numberOfTries;
    public static String processType;
    String condition = '';
    String paidCondition = '(AccountId IN :accountsIds AND Contact_Status__c != \'4. Customer\' AND Contact_Status__c != \'3. Working Opp\')';
    String cancelCondition = '(AccountId IN :accountsIds AND Contact_Status__c != \'0. Downgraded\' AND Contact_Status__c != \'3. Working Opp\')';
    Id recordTypeId = Schema.SObjectType.Exception_And_Notification_History__c
        .getRecordTypeInfosByName()
        .get('Accounts Paid And Cancelled')
        .getRecordTypeId();

    public BatchJob_AccountsPaidAndCanceled(Integer tries, String process) {
        numberOfTries = tries;
        processType = process;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        RingCentralVariousSettings__c settings = RingCentralVariousSettings__c.getOrgDefaults();
        List<String> accountIds = new List<String>();

        for (Exception_And_Notification_History__c eanh : (List<Exception_And_Notification_History__c>) new ExceptionAndNotificationHistorySelector()
        .selectExceptionAndNotificationHistorysByRecordTypeIdAndObject(new List<Object>{new List<String>{recordTypeId}, processType})
        .executeQuery()) {
            accountIds.addAll(eanh.Record_Id__c.split(', '));
        }

        ContactSelector conSelector = new ContactSelector();
        return conSelector
            .selectContactsByAccountIds(new List<Object>{ accountIds })
            .selectFields(conSelector.getContactStatusFieldList())
            .executeQueryLocator();
    }

    public void execute(Database.BatchableContext ctx, List<sObject> contacts) {
        List<Contact> contactsToProcess = new List<Contact>();
        Set<Id> accountsIds = new Set<Id>();
        CustomerContactsPaidAccountsHelper.processBatchJobContacts(contacts, processType);

        for (Contact con : (List<Contact>) contacts) {
            if (!accountsIds.contains(con.AccountId)) {
                accountsIds.add(con.AccountId);
            } 
        }

        if (processType == 'Customer Contacts') {
            condition += paidCondition;
        } else if (processType == 'Cancel Accounts') {
            condition += cancelCondition;
        }

        for (AggregateResult ar : Database.query('SELECT AccountId, COUNT(Id) FROM Contact WHERE ' + condition + ' GROUP BY AccountId')) {
            Id accId = (Id) ar.get('AccountId');
            accountsIds.remove(accId);
        }

        List<Exception_And_Notification_History__c> eanhToRemove = (List<Exception_And_Notification_History__c>) new ExceptionAndNotificationHistorySelector()
        .selectExceptionAndNotificationHistoryByIdRecordIdOrAffectedRecordID(new List<Object>{new List<String>{recordTypeId}, processType, accountsIds})
        .executeQuery();
        if (eanhToRemove != null && !eanhToRemove.isEmpty()) { 
            delete eanhToRemove;
        }
    }

    public void finish(Database.BatchableContext BC) {
        if (numberOfTries >= 2 && numberOfTries < 4 && !Test.isRunningTest()) { 
            numberOfTries = numberOfTries + 1;
            Database.executeBatch(new BatchJob_AccountsPaidAndCanceled(numberOfTries, 'Cancel Accounts'));
        }

        if (numberOfTries == 1 && !Test.isRunningTest()) {
            numberOfTries = numberOfTries + 1;
            Database.executeBatch(new BatchJob_AccountsPaidAndCanceled(numberOfTries, 'Customer Contacts'));
        }
    }
}