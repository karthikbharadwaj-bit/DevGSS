@isTest
public class TestLeadPlatEvents {
    @isTest
    private static void testLeadExceptionCreationAsync() {
        try {
            Lead l = new Lead();
            insert l;
        } catch(Exception ex) {
            Test.startTest();
            LeadPlatEvents.leadExceptionCreationAsync(new Exception[]{ex},'populateLSEnrichmentDate');
            Test.stopTest();
        }
        List<Exception_and_notification_history__c> lstExceptions = (List<Exception_and_notification_history__c>) new ExceptionAndNotificationHistorySelector()
                .selectExceptionAndNotificationHistorys()
                .selectFields(
                    new List<String>{
                        'object_type__c',
                        'Affected_record_ID__c',
                        'Exception__c',
                        'RecordTypeId',
                        'Exception_desc__c'
                    }
                )
                .executeQuery();
        System.assertEquals(1, lstExceptions.size(), 'Lead Exception was not created');
    }
}