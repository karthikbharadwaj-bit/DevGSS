@isTest
public class Test_PlatformEventExceptionLogger {
    /*
     * Platform events manager uses SOSL to identify the apex classes needed to be execute.
     * https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_testing_SOSL.htm. 
    */  
    public static void setProcessor() {
        ApexClass logger = [SELECT Id  
                            FROM ApexClass 
                            WHERE NAME = 'PlatformEventExceptionLogger' 
                            LIMIT 1];
        Test.setFixedSearchResults(new List<Id>{logger.Id});
    }

    /*
     * Verify that when platform event Exception__e is occured the exception logger logs an exception.
    */
    @isTest static void testPlatformEventExceptionCreateLogs() {
        setProcessor();
        System.NullPointerException testEx = new System.NullPointerException();

        Test.startTest();
            try {
                String s;
                // Since s is null, this call causes a NullPointerException
                s.toLowerCase(); 
            } catch(NullPointerException e) {
                testEx = e;
                //Publish test events
                PlatformEvents.publishPlatformEventException(Test_PlatformEventExceptionLogger.class.getName(), testEx, null, null); 
            }
        Test.stopTest();
            
        PlatformLog__c errorLog = PlatformLog.getMostRecent();
        System.assertEquals(errorLog.Error__c, testEx.getMessage(), PlatformEventsUtil.PE_TEST_ERROR_NOT_EQUALS);
        System.assertEquals(errorLog.Source__c, Test_PlatformEventExceptionLogger.class.getName(), PlatformEventsUtil.PE_TEST_SOURCE_NOT_EQUALS);
        System.assertEquals(errorLog.StackTrace__c, testEx.getStackTraceString(), PlatformEventsUtil.PE_TEST_STACK_NOT_EQUALS);
        System.assertEquals(errorLog.InboundMessage__c, null, PlatformEventsUtil.PE_TEST_INBOUND_NOT_EQUALS);
        System.assertEquals(errorLog.OutboundMessage__c, null, PlatformEventsUtil.PE_TEST_OUTBOUND_NOT_EQUALS);
    }

    /*
     * Verify that platform event exception logging could not raise DML limits issue.
    */
    @isTest static void testPlatformEventExceptionCreationDoesntThrowDMLLimits() {
        setProcessor();
        System.NullPointerException testEx = new System.NullPointerException();
        
        Test.startTest();
            // exhaust the Governor Limits for DMLs
            while (Limits.getPublishImmediateDML() < Limits.getLimitPublishImmediateDML()) {
                PlatformEvents.publishPlatformEventException(Test_PlatformEventExceptionLogger.class.getName(), testEx, null, null); 
            }
            // this should not throw any exceptions
            PlatformEvents.publishPlatformEventException(Test_PlatformEventExceptionLogger.class.getName(), testEx, null, null); 
        Test.stopTest();

        System.assert([SELECT COUNT() FROM PlatformLog__c] > 0, 'No PlatformLog__c records created.');
    }
}