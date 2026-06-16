/**
 * @description Test class for ReportExportUsageTriggerHandler
 *              Provides comprehensive test coverage following Salesforce testing best practices
 * 
 */
@IsTest
private class ReportExportUsageTriggerHandlerTest {
    
    /**
     * @description Test data setup method
     */
    @TestSetup
    static void setupTestData() {
        // Create test user if needed (assuming User__c is a lookup to User)
        // This would depend on your specific field configuration
        
        // Create existing usage record for update scenarios
        ReportExportUsage__c existingUsage = new ReportExportUsage__c(
            User__c = UserInfo.getUserId(),
            ExportDate__c = Date.today(),
            ExportedRows__c = 100
        );
        insert existingUsage;
    }
    
    /**
     * @description Test successful processing of single platform event
     */
    @IsTest
    static void testSingleEventProcessing() {
        // Arrange
        ReportExportUsage_PE__e testEvent = new ReportExportUsage_PE__e(
            UserId__c = UserInfo.getUserId(),
            ExportDate__c = Date.today().addDays(1), // Different date to create new record
            RowsProcessed__c = 50
        );
        
        // Act
        Test.startTest();
        Database.SaveResult result = EventBus.publish(testEvent);
        Test.getEventBus().deliver(); // Deliver platform events in test context
        Test.stopTest();
        
        // Assert
        System.assert(result.isSuccess(), 'Platform event should be published successfully');
        
        List<ReportExportUsage__c> usageRecords = [
            SELECT User__c, ExportDate__c, ExportedRows__c
            FROM ReportExportUsage__c
            WHERE User__c = :UserInfo.getUserId()
            AND ExportDate__c = :Date.today().addDays(1)
        ];
        
        System.assertEquals(1, usageRecords.size(), 'Should create one usage record');
        System.assertEquals(50, usageRecords[0].ExportedRows__c, 'Should have correct row count');
    }
    
    /**
     * @description Test bulk processing of multiple platform events
     */
    @IsTest
    static void testBulkEventProcessing() {
        // Arrange
        List<ReportExportUsage_PE__e> testEvents = new List<ReportExportUsage_PE__e>();
        Date testDate = Date.today().addDays(2);
        
        // Create multiple events for same user/date (should aggregate)
        for (Integer i = 0; i < 5; i++) {
            testEvents.add(new ReportExportUsage_PE__e(
                UserId__c = UserInfo.getUserId(),
                ExportDate__c = testDate,
                RowsProcessed__c = 10
            ));
        }
        
        // Create events for different dates
        testEvents.add(new ReportExportUsage_PE__e(
            UserId__c = UserInfo.getUserId(),
            ExportDate__c = testDate.addDays(1),
            RowsProcessed__c = 25
        ));
        
        // Act
        Test.startTest();
        List<Database.SaveResult> results = EventBus.publish(testEvents);
        Test.getEventBus().deliver();
        Test.stopTest();
        
        // Assert
        for (Database.SaveResult result : results) {
            System.assert(result.isSuccess(), 'All platform events should be published successfully');
        }
        
        // Verify aggregation for same date
        List<ReportExportUsage__c> sameDate = [
            SELECT ExportedRows__c
            FROM ReportExportUsage__c
            WHERE User__c = :UserInfo.getUserId()
            AND ExportDate__c = :testDate
        ];
        System.assertEquals(1, sameDate.size(), 'Should have one record for same date');
        System.assertEquals(50, sameDate[0].ExportedRows__c, 'Should aggregate all rows (5 * 10)');
        
        // Verify separate record for different date
        List<ReportExportUsage__c> differentDate = [
            SELECT ExportedRows__c
            FROM ReportExportUsage__c
            WHERE User__c = :UserInfo.getUserId()
            AND ExportDate__c = :testDate.addDays(1)
        ];
        System.assertEquals(1, differentDate.size(), 'Should have one record for different date');
        System.assertEquals(25, differentDate[0].ExportedRows__c, 'Should have correct row count');
    }
    
    /**
     * @description Test updating existing usage records
     */
    @IsTest
    static void testExistingRecordUpdate() {
        // Arrange
        ReportExportUsage_PE__e testEvent = new ReportExportUsage_PE__e(
            UserId__c = UserInfo.getUserId(),
            ExportDate__c = Date.today(), // Same date as setup data
            RowsProcessed__c = 75
        );
        
        // Act
        Test.startTest();
        Database.SaveResult result = EventBus.publish(testEvent);
        Test.getEventBus().deliver();
        Test.stopTest();
        
        // Assert
        System.assert(result.isSuccess(), 'Platform event should be published successfully');
        
        List<ReportExportUsage__c> usageRecords = [
            SELECT ExportedRows__c
            FROM ReportExportUsage__c
            WHERE User__c = :UserInfo.getUserId()
            AND ExportDate__c = :Date.today()
        ];
        
        System.assertEquals(1, usageRecords.size(), 'Should have one usage record');
        System.assertEquals(175, usageRecords[0].ExportedRows__c, 'Should add to existing count (100 + 75)');
    }
    
    /**
     * @description Test handling of invalid platform events
     */
    @IsTest
    static void testInvalidEventHandling() {
        // Arrange
        List<ReportExportUsage_PE__e> testEvents = new List<ReportExportUsage_PE__e>{
            new ReportExportUsage_PE__e(
                UserId__c = null, // Invalid - no user ID
                ExportDate__c = Date.today(),
                RowsProcessed__c = 50
            ),
            new ReportExportUsage_PE__e(
                UserId__c = '',   // Invalid - blank user ID
                ExportDate__c = Date.today(),
                RowsProcessed__c = 50
            ),
            new ReportExportUsage_PE__e(
                UserId__c = UserInfo.getUserId(),
                ExportDate__c = null, // Invalid - no date
                RowsProcessed__c = 50
            ),
            new ReportExportUsage_PE__e(
                UserId__c = UserInfo.getUserId(),
                ExportDate__c = Date.today().addDays(3),
                RowsProcessed__c = null // Valid - should default to 0
            )
        };
        
        // Act
        Test.startTest();
        List<Database.SaveResult> results = EventBus.publish(testEvents);
        Test.getEventBus().deliver();
        Test.stopTest();
        
        // Assert
        for (Database.SaveResult result : results) {
            System.assert(result.isSuccess(), 'Platform events should be published successfully');
        }
        
        // Only the valid event should create a record
        List<ReportExportUsage__c> usageRecords = [
            SELECT ExportedRows__c
            FROM ReportExportUsage__c
            WHERE User__c = :UserInfo.getUserId()
            AND ExportDate__c = :Date.today().addDays(3)
        ];
        
        System.assertEquals(1, usageRecords.size(), 'Should create record for valid event');
        System.assertEquals(0, usageRecords[0].ExportedRows__c, 'Should default null rows to 0');
    }
    
    /**
     * @description Test direct handler method calls for unit testing
     */
    @IsTest
    static void testDirectHandlerCall() {
        // Arrange
        List<ReportExportUsage_PE__e> testEvents = new List<ReportExportUsage_PE__e>{
            new ReportExportUsage_PE__e(
                UserId__c = UserInfo.getUserId(),
                ExportDate__c = Date.today().addDays(4),
                RowsProcessed__c = 100
            )
        };
        
        ReportExportUsageTriggerHandler handler = new ReportExportUsageTriggerHandler();
        
        // Act
        Test.startTest();
        handler.handleAfterInsert(testEvents);
        Test.stopTest();
        
        // Assert
        List<ReportExportUsage__c> usageRecords = [
            SELECT ExportedRows__c
            FROM ReportExportUsage__c
            WHERE User__c = :UserInfo.getUserId()
            AND ExportDate__c = :Date.today().addDays(4)
        ];
        
        System.assertEquals(1, usageRecords.size(), 'Should create usage record');
        System.assertEquals(100, usageRecords[0].ExportedRows__c, 'Should have correct row count');
    }
    
    /**
     * @description Test recursive execution prevention
     */
    @IsTest
    static void testRecursiveExecutionPrevention() {
        // Arrange
        List<ReportExportUsage_PE__e> testEvents = new List<ReportExportUsage_PE__e>{
            new ReportExportUsage_PE__e(
                UserId__c = UserInfo.getUserId(),
                ExportDate__c = Date.today().addDays(5),
                RowsProcessed__c = 50
            )
        };
        
        ReportExportUsageTriggerHandler handler = new ReportExportUsageTriggerHandler();
        
        // Act
        Test.startTest();
        handler.handleAfterInsert(testEvents); // First call
        handler.handleAfterInsert(testEvents); // Second call should be prevented
        Test.stopTest();
        
        // Assert - should still only have one record
        List<ReportExportUsage__c> usageRecords = [
            SELECT ExportedRows__c
            FROM ReportExportUsage__c
            WHERE User__c = :UserInfo.getUserId()
            AND ExportDate__c = :Date.today().addDays(5)
        ];
        
        System.assertEquals(1, usageRecords.size(), 'Should have only one record');
        System.assertEquals(50, usageRecords[0].ExportedRows__c, 'Should not be duplicated');
    }
    
}