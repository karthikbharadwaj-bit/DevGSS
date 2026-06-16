public class BatchJob_DeleteEANHRecords implements Database.Batchable<sObject> {
    private String recordTypeName;
    private Date dateFrom;
    private Date dateTo;
    private String relativeDate;

    public BatchJob_DeleteEANHRecords(String recordTypeName) {
        this.recordTypeName = recordTypeName;
    }

    public BatchJob_DeleteEANHRecords(String recordTypeName, String relativeDate) {
        this.recordTypeName = recordTypeName;
        this.relativeDate = relativeDate;
    }

    public BatchJob_DeleteEANHRecords(String recordTypeName, Date dateFrom, Date dateTo) {
        this.recordTypeName = recordTypeName;
        this.dateFrom = dateFrom;
        this.dateTo = dateTo;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Id recordTypeId = Schema.SObjectType.Exception_And_Notification_History__c.getRecordTypeInfosByName()
            .get(recordTypeName)
            .getRecordTypeId();
        String queryCondition = 'RecordTypeId = :bind0';
        if (dateFrom != null && dateTo != null) {
            queryCondition += ' AND CreatedDate >= :bind1 AND CreatedDate <= :bind2';
        } else if (!String.isBlank(relativeDate)) {
            queryCondition += ' AND CreatedDate = ' + relativeDate;
        }
        return new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistoryForBatchJobDelete(
                new List<Object>{ recordTypeId, dateFrom, dateTo },
                queryCondition
            )
            .executeQueryLocator();
    }

    public void execute(Database.BatchableContext bc, List<Exception_And_Notification_History__c> scope) {
        Database.delete(scope, false);
    }

    public void finish(Database.BatchableContext bc) {
    }
}