public class LeadPlatEvents {
    static final String RECORDTYPENAME = 'Lead Exception';
    public static void leadExceptionCreationAsync(List<Exception> exceptions, String source) {
        List<Lead_Exception__e> leadExceptions = new List<Lead_Exception__e>();
        for (Exception e: exceptions) {
            leadExceptions.add(
                new Lead_Exception__e(
                    Error__c = e.getMessage(),
                    Source__c = source,
                    StackTrace__c = e.getStackTraceString(),
                    Type__c= e.getTypeName()
                )
            );
        }
        PlatformEvents.publishPlatformEvent(leadExceptions, 'leadExceptionCreationAsync');
    }
    public static void processLeadCreationEventException(
        List<Lead_Exception__e> events
    ) {
        List<Exception_And_Notification_History__c> exceptions = new List<Exception_And_Notification_History__c>();
        Id rtId = Schema.SObjectType.Exception_And_Notification_History__c.getRecordTypeInfosByName()
            .get(RECORDTYPENAME)
            .getRecordTypeId();
        for (Lead_Exception__e event : events) {
            exceptions.add(
                new Exception_And_Notification_History__c(
                    RecordTypeId = rtId,
                    Object_Type__c = Lead_Exception__e.SObjectType.getDescribe().getName(),
                    Exception__c = event.Type__c,
                    Exception_desc__c = 'Source: ' + event.Source__c + ' - ' + event.Error__c,
                    stackTraceString__c = event.StackTrace__c
                )
            );
        }
        if (exceptions.size() > 0) {
            insert exceptions;
        }
    }
}