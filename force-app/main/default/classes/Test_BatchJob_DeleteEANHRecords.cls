@isTest
public class Test_BatchJob_DeleteEANHRecords {
    public static final String LEAD_EXCEPTION = 'Lead Exception';
    public static final String CONTACT_EXCEPTION = 'Contact Exception';

    @testSetup
    static void setupData() {
        Map<String, Schema.RecordTypeInfo> recordTypeInfos = Schema.SObjectType.Exception_And_Notification_History__c.getRecordTypeInfosByName();
        Id leadRecordTypeId = recordTypeInfos.get(LEAD_EXCEPTION).getRecordTypeId();
        Id contactRecordTypeId = recordTypeInfos.get(CONTACT_EXCEPTION).getRecordTypeId();

        List<Exception_And_Notification_History__c> eanhLeadException = (List<Exception_And_Notification_History__c>) new SObjectBuilder(
                Exception_And_Notification_History__c.sObjectType
            )
            .setField(Exception_And_Notification_History__c.RecordTypeId, leadRecordTypeId)
            .quantity(2)
            .create()
            .getRecords();

        Test.setCreatedDate(eanhLeadException[0].Id, Date.today().addMonths(-1));

        List<Exception_And_Notification_History__c> eanhContactException = (List<Exception_And_Notification_History__c>) new SObjectBuilder(
                Exception_And_Notification_History__c.sObjectType
            )
            .setField(Exception_And_Notification_History__c.RecordTypeId, contactRecordTypeId)
            .quantity(2)
            .create()
            .getRecords();

        Test.setCreatedDate(eanhContactException[0].Id, Date.today().addMonths(-2));
    }

    @isTest
    static void testBatchJobDeleteByRecordType() {
        BatchJob_DeleteEANHRecords batchJob = new BatchJob_DeleteEANHRecords(LEAD_EXCEPTION);
        Test.startTest();
        Database.executeBatch(batchJob);
        Test.stopTest();
        List<Exception_And_Notification_History__c> eanhRecords = (List<Exception_And_Notification_History__c>) new ExceptionAndNotificationHistorySelector()
            .selectAllExceptionAndNotificationHistory()
            .executeQuery();
        System.assertEquals(2, eanhRecords.size(), 'Only 2 EANH records should be present');
    }

    @isTest
    static void testBatchJobDeleteByRecordTypeAndRelativeDate() {
        BatchJob_DeleteEANHRecords batchJob = new BatchJob_DeleteEANHRecords(CONTACT_EXCEPTION, 'THIS_WEEK');
        Test.startTest();
        Database.executeBatch(batchJob);
        Test.stopTest();
        List<Exception_And_Notification_History__c> eanhRecords = (List<Exception_And_Notification_History__c>) new ExceptionAndNotificationHistorySelector()
            .selectAllExceptionAndNotificationHistory()
            .executeQuery();
        System.assertEquals(3, eanhRecords.size(), 'Only 3 EANH record should be present');
    }

    @isTest
    static void testBatchJobDeleteByRecordTypeAndDatesFromAndTo() {
        BatchJob_DeleteEANHRecords batchJob = new BatchJob_DeleteEANHRecords(
            CONTACT_EXCEPTION,
            Date.today().addMonths(-3),
            Date.today().addDays(-1)
        );
        Test.startTest();
        Database.executeBatch(batchJob);
        Test.stopTest();
        List<Exception_And_Notification_History__c> eanhRecords = (List<Exception_And_Notification_History__c>) new ExceptionAndNotificationHistorySelector()
            .selectAllExceptionAndNotificationHistory()
            .executeQuery();
        System.assertEquals(3, eanhRecords.size(), 'Only 3 EANH records should be present');
    }
}