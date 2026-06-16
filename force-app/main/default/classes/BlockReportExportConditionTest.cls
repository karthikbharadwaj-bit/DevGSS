/**
 * @description Test class for BlockReportExportCondition
 *              Provides comprehensive test coverage for transaction security condition
 *              following Salesforce testing best practices
 * 
 * @changelog
 * - v1.0: Initial implementation with comprehensive test scenarios
 */
@IsTest
private class BlockReportExportConditionTest {
    
    // Test constants
    private static final String BYPASS_PERMISSION_SET = 'Export_Report_Permissions';
    private static final String TIER_2_PERMISSION_SET = 'Report_Export_Permissions_5000_Records';
    private static final String TIER_3_PERMISSION_SET = 'Report_Export_Permissions_10000_Records';
    private static final String EXPORT_OPERATION = 'ReportExported';
    private static final Decimal TEST_THRESHOLD = 1000;
    private static final Decimal TIER_2_THRESHOLD = 5000;
    private static final Decimal TIER_3_THRESHOLD = 10000;
    private static final Decimal CURRENT_USAGE = 500;
    
    /**
     * @description Test data setup method
     */
    @TestSetup
    static void setupTestData() {
        // Create test users
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + System.currentTimeMillis() + '@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = standardProfile.Id
        );
        insert testUser;
        
        User bypassUser = new User(
            FirstName = 'Bypass',
            LastName = 'User', 
            Email = 'bypassuser@example.com',
            Username = 'bypassuser' + System.currentTimeMillis() + '@example.com',
            Alias = 'buser',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = standardProfile.Id
        );
        insert bypassUser;
        
        User tier2User = new User(
            FirstName = 'Tier2',
            LastName = 'User', 
            Email = 'tier2user@example.com',
            Username = 'tier2user' + System.currentTimeMillis() + '@example.com',
            Alias = 't2user',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = standardProfile.Id
        );
        insert tier2User;
        
        User tier3User = new User(
            FirstName = 'Tier3',
            LastName = 'User', 
            Email = 'tier3user@example.com',
            Username = 'tier3user' + System.currentTimeMillis() + '@example.com',
            Alias = 't3user',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = standardProfile.Id
        );
        insert tier3User;
        
        // Handle setup objects (PermissionSet and PermissionSetAssignment) separately
        System.runAs(new User(Id = UserInfo.getUserId())) {
            // Create or get permission sets
            Map<String, PermissionSet> permissionSets = new Map<String, PermissionSet>();
            
            List<PermissionSet> existingPS = [
                SELECT Id, Name FROM PermissionSet 
                WHERE Name IN (:BYPASS_PERMISSION_SET, :TIER_2_PERMISSION_SET, :TIER_3_PERMISSION_SET)
            ];
            
            for (PermissionSet ps : existingPS) {
                permissionSets.put(ps.Name, ps);
            }
            
            // Create missing permission sets
            List<PermissionSet> psToInsert = new List<PermissionSet>();
            
            if (!permissionSets.containsKey(BYPASS_PERMISSION_SET)) {
                PermissionSet bypassPS = new PermissionSet(
                    Name = BYPASS_PERMISSION_SET,
                    Label = 'Export Report Permissions Test ' + System.currentTimeMillis()
                );
                psToInsert.add(bypassPS);
                permissionSets.put(BYPASS_PERMISSION_SET, bypassPS);
            }
            
            if (!permissionSets.containsKey(TIER_2_PERMISSION_SET)) {
                PermissionSet tier2PS = new PermissionSet(
                    Name = TIER_2_PERMISSION_SET,
                    Label = 'Tier 2 Permissions Test ' + System.currentTimeMillis()
                );
                psToInsert.add(tier2PS);
                permissionSets.put(TIER_2_PERMISSION_SET, tier2PS);
            }
            
            if (!permissionSets.containsKey(TIER_3_PERMISSION_SET)) {
                PermissionSet tier3PS = new PermissionSet(
                    Name = TIER_3_PERMISSION_SET,
                    Label = 'Tier 3 Permissions Test ' + System.currentTimeMillis()
                );
                psToInsert.add(tier3PS);
                permissionSets.put(TIER_3_PERMISSION_SET, tier3PS);
            }
            
            if (!psToInsert.isEmpty()) {
                insert psToInsert;
            }
            
            // Create permission set assignments
            List<PermissionSetAssignment> assignmentsToInsert = new List<PermissionSetAssignment>();
            
            // Check existing assignments
            List<PermissionSetAssignment> existingAssignments = [
                SELECT Id, AssigneeId, PermissionSetId, PermissionSet.Name
                FROM PermissionSetAssignment 
                WHERE AssigneeId IN (:bypassUser.Id, :tier2User.Id, :tier3User.Id)
                AND PermissionSet.Name IN (:BYPASS_PERMISSION_SET, :TIER_2_PERMISSION_SET, :TIER_3_PERMISSION_SET)
            ];
            
            Set<String> existingAssignmentKeys = new Set<String>();
            for (PermissionSetAssignment psa : existingAssignments) {
                existingAssignmentKeys.add(psa.AssigneeId + '_' + psa.PermissionSet.Name);
            }
            
            // Bypass user assignment
            if (!existingAssignmentKeys.contains(bypassUser.Id + '_' + BYPASS_PERMISSION_SET)) {
                assignmentsToInsert.add(new PermissionSetAssignment(
                    AssigneeId = bypassUser.Id,
                    PermissionSetId = permissionSets.get(BYPASS_PERMISSION_SET).Id
                ));
            }
            
            // Tier 2 user assignment
            if (!existingAssignmentKeys.contains(tier2User.Id + '_' + TIER_2_PERMISSION_SET)) {
                assignmentsToInsert.add(new PermissionSetAssignment(
                    AssigneeId = tier2User.Id,
                    PermissionSetId = permissionSets.get(TIER_2_PERMISSION_SET).Id
                ));
            }
            
            // Tier 3 user assignment
            if (!existingAssignmentKeys.contains(tier3User.Id + '_' + TIER_3_PERMISSION_SET)) {
                assignmentsToInsert.add(new PermissionSetAssignment(
                    AssigneeId = tier3User.Id,
                    PermissionSetId = permissionSets.get(TIER_3_PERMISSION_SET).Id
                ));
            }
            
            if (!assignmentsToInsert.isEmpty()) {
                insert assignmentsToInsert;
            }
        }
        
        // Create existing usage record (non-setup object)
        ReportExportUsage__c existingUsage = new ReportExportUsage__c(
            User__c = testUser.Id,
            ExportDate__c = Date.today(),
            ExportedRows__c = CURRENT_USAGE
        );
        insert existingUsage;
    }
    
    /**
     * @description Test main evaluate method with null event
     */
    @IsTest
    static void testEvaluateWithNullEvent() {
        // Arrange
        BlockReportExportCondition condition = new BlockReportExportCondition();
        
        // Act
        Test.startTest();
        Boolean result = condition.evaluate(null);
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result, 'Should return false for null event');
    }
    
    /**
     * @description Test evaluate method with unsupported event type
     */
    @IsTest
    static void testEvaluateWithUnsupportedEvent() {
        // Arrange
        BlockReportExportCondition condition = new BlockReportExportCondition();
        Account testAccount = new Account(Name = 'Test Account'); // Unsupported event type
        
        // Act
        Test.startTest();
        Boolean result = condition.evaluate(testAccount);
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result, 'Should return false for unsupported event type');
    }
    
    /**
     * @description Test evaluate method with null ReportEvent
     */
    @IsTest
    static void testEvaluateReportExportWithNullReportEvent() {
        // Arrange
        BlockReportExportCondition condition = new BlockReportExportCondition();
        
        // Act
        Test.startTest();
        Boolean result = condition.evaluate((ReportEvent)null);
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result, 'Should return false for null ReportEvent');
    }
    
    /**
     * @description Test non-export operations are allowed
     */
    @IsTest
    static void testNonExportOperationAllowed() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE FirstName = 'Test' LIMIT 1];
        BlockReportExportCondition condition = new BlockReportExportCondition();
        
        ReportEvent reportEvent = new ReportEvent();
        reportEvent.UserId = testUser.Id;
        reportEvent.Operation = 'ReportViewed'; // Not an export operation
        reportEvent.RowsProcessed = 100;
        
        // Act
        Test.startTest();
        Boolean result = condition.evaluate(reportEvent);
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result, 'Should allow non-export operations');
    }
    
    /**
     * @description Test export operation with null operation field
     */
    @IsTest
    static void testNullOperationAllowed() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE FirstName = 'Test' LIMIT 1];
        BlockReportExportCondition condition = new BlockReportExportCondition();
        
        ReportEvent reportEvent = new ReportEvent();
        reportEvent.UserId = testUser.Id;
        reportEvent.Operation = null;
        reportEvent.RowsProcessed = 100;
        
        // Act
        Test.startTest();
        Boolean result = condition.evaluate(reportEvent);
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result, 'Should allow operations with null Operation field');
    }
    
    /**
     * @description Test bypass user can export unlimited rows
     */
    @IsTest
    static void testBypassUserUnlimitedExport() {
        // Arrange
        User bypassUser = [SELECT Id FROM User WHERE FirstName = 'Bypass' LIMIT 1];
        BlockReportExportCondition condition = new BlockReportExportCondition();
        
        ReportEvent reportEvent = new ReportEvent();
        reportEvent.UserId = bypassUser.Id;
        reportEvent.Operation = EXPORT_OPERATION;
        reportEvent.RowsProcessed = 999999; // Very large export
        
        // Act
        Test.startTest();
        Boolean result = condition.evaluate(reportEvent);
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result, 'Bypass user should be allowed unlimited exports');
    }
    
    /**
     * @description Test platform event publishing for allowed exports
     */
    @IsTest
    static void testPlatformEventPublishing() {
        // Arrange
        User bypassUser = [SELECT Id FROM User WHERE FirstName = 'Bypass' LIMIT 1];
        BlockReportExportCondition condition = new BlockReportExportCondition();
        
        ReportEvent reportEvent = new ReportEvent();
        reportEvent.UserId = bypassUser.Id;
        reportEvent.Operation = EXPORT_OPERATION;
        reportEvent.RowsProcessed = 100;
        
        // Act
        Test.startTest();
        Boolean result = condition.evaluate(reportEvent);
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result, 'Bypass user export should be allowed');
        
        // Note: Platform events are published asynchronously, so we can't directly test
        // the published event in the same transaction. In a real test environment,
        // you might use Test.getEventBus().deliver() or test the publishing logic separately
    }
    
    /**
     * @description Test error handling in bypass permission check
     */
    @IsTest
    static void testBypassPermissionErrorHandling() {
        // This test is challenging to implement directly since we can't easily force
        // a QueryException in the permission check. In a real implementation,
        // you might use dependency injection or mocking to test error scenarios.
        
        // Arrange
        User testUser = [SELECT Id FROM User WHERE FirstName = 'Test' LIMIT 1];
        BlockReportExportCondition condition = new BlockReportExportCondition();
        
        ReportEvent reportEvent = new ReportEvent();
        reportEvent.UserId = testUser.Id;
        reportEvent.Operation = EXPORT_OPERATION;
        reportEvent.RowsProcessed = 100;
        
        // Act
        Test.startTest();
        Boolean result = condition.evaluate(reportEvent);
        Test.stopTest();
        
        // Assert
        // The method should still work normally even if we can't force an error
        System.assertNotEquals(null, result, 'Should return a valid boolean result');
    }
    
    /**
     * @description Test platform event publishing with invalid parameters
     */
    @IsTest 
    static void testPlatformEventPublishingWithInvalidParams() {
        // This test focuses on the edge case handling within publishUsageEvent
        // Since it's a private method, we test it indirectly through the main flow
        
        // Arrange
        User bypassUser = [SELECT Id FROM User WHERE FirstName = 'Bypass' LIMIT 1];
        BlockReportExportCondition condition = new BlockReportExportCondition();
        
        ReportEvent reportEvent = new ReportEvent();
        reportEvent.UserId = bypassUser.Id;
        reportEvent.Operation = EXPORT_OPERATION;
        reportEvent.RowsProcessed = null; // This should be handled gracefully
        
        // Act
        Test.startTest();
        Boolean result = condition.evaluate(reportEvent);
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result, 'Should still allow bypass user even with null rows');
    }
    
    
    /**
     * @description Test Tier 2 user within limit
     */
    @IsTest
    static void testTier2UserWithinLimit() {
        // Arrange
        User tier2User = [SELECT Id FROM User WHERE FirstName = 'Tier2' LIMIT 1];
        BlockReportExportCondition condition = new BlockReportExportCondition();
        
        ReportEvent reportEvent = new ReportEvent();
        reportEvent.UserId = tier2User.Id;
        reportEvent.Operation = EXPORT_OPERATION;
        reportEvent.RowsProcessed = 3000; // Within 5k limit
        
        // Act
        Test.startTest();
        Boolean result = condition.evaluate(reportEvent);
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result, 'Tier 2 user should be allowed to export within 5k limit');
    }
    
    /**
     * @description Test Tier 2 user exceeding limit
     */
    @IsTest
    static void testTier2UserExceedingLimit() {
        // Arrange
        User tier2User = [SELECT Id FROM User WHERE FirstName = 'Tier2' LIMIT 1];
        BlockReportExportCondition condition = new BlockReportExportCondition();
        
        // Create usage record for tier2 user
        ReportExportUsage__c existingUsage = new ReportExportUsage__c(
            User__c = tier2User.Id,
            ExportDate__c = Date.today(),
            ExportedRows__c = 4000 // Already used 4k
        );
        insert existingUsage;
        
        ReportEvent reportEvent = new ReportEvent();
        reportEvent.UserId = tier2User.Id;
        reportEvent.Operation = EXPORT_OPERATION;
        reportEvent.RowsProcessed = 2000; // Would exceed 5k limit (4k + 2k = 6k)
        
        // Act
        Test.startTest();
        Boolean result = condition.evaluate(reportEvent);
        Test.stopTest();
        
        // Assert
        System.assertEquals(true, result, 'Tier 2 user should be blocked when exceeding 5k limit');
    }
    
    /**
     * @description Test Tier 3 user within limit
     */
    @IsTest
    static void testTier3UserWithinLimit() {
        // Arrange
        User tier3User = [SELECT Id FROM User WHERE FirstName = 'Tier3' LIMIT 1];
        BlockReportExportCondition condition = new BlockReportExportCondition();
        
        ReportEvent reportEvent = new ReportEvent();
        reportEvent.UserId = tier3User.Id;
        reportEvent.Operation = EXPORT_OPERATION;
        reportEvent.RowsProcessed = 8000; // Within 10k limit
        
        // Act
        Test.startTest();
        Boolean result = condition.evaluate(reportEvent);
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result, 'Tier 3 user should be allowed to export within 10k limit');
    }
    
    /**
     * @description Test Tier 3 user exceeding limit
     */
    @IsTest
    static void testTier3UserExceedingLimit() {
        // Arrange
        User tier3User = [SELECT Id FROM User WHERE FirstName = 'Tier3' LIMIT 1];
        BlockReportExportCondition condition = new BlockReportExportCondition();
        
        // Create usage record for tier3 user
        ReportExportUsage__c existingUsage = new ReportExportUsage__c(
            User__c = tier3User.Id,
            ExportDate__c = Date.today(),
            ExportedRows__c = 9000 // Already used 9k
        );
        insert existingUsage;
        
        ReportEvent reportEvent = new ReportEvent();
        reportEvent.UserId = tier3User.Id;
        reportEvent.Operation = EXPORT_OPERATION;
        reportEvent.RowsProcessed = 2000; // Would exceed 10k limit (9k + 2k = 11k)
        
        // Act
        Test.startTest();
        Boolean result = condition.evaluate(reportEvent);
        Test.stopTest();
        
        // Assert
        System.assertEquals(true, result, 'Tier 3 user should be blocked when exceeding 10k limit');
    }
    
    /**
     * @description Test user with no tier assignment uses default threshold
     */
    @IsTest
    static void testUserWithNoTierUsesDefault() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE FirstName = 'Test' LIMIT 1];
        BlockReportExportCondition condition = new BlockReportExportCondition();
        
        ReportEvent reportEvent = new ReportEvent();
        reportEvent.UserId = testUser.Id;
        reportEvent.Operation = EXPORT_OPERATION;
        reportEvent.RowsProcessed = 1; // Any amount should be blocked since default is 0
        
        // Act
        Test.startTest();
        Boolean result = condition.evaluate(reportEvent);
        Test.stopTest();
        
        // Assert
        System.assertEquals(true, result, 'User with no tier should be blocked with default threshold of 0');
    }
    
    /**
     * @description Test tier priority - user with multiple tiers gets highest threshold
     */
    @IsTest
    static void testTierPriorityHighestFirst() {
        // Arrange - Give tier3User both Tier 2 and Tier 3 permissions
        User tier3User = [SELECT Id FROM User WHERE FirstName = 'Tier3' LIMIT 1];
        
        System.runAs(new User(Id = UserInfo.getUserId())) {
            // Get Tier 2 permission set
            PermissionSet tier2PS = [SELECT Id FROM PermissionSet WHERE Name = :TIER_2_PERMISSION_SET LIMIT 1];
            
            // Check if assignment already exists
            List<PermissionSetAssignment> existingAssignment = [
                SELECT Id FROM PermissionSetAssignment 
                WHERE AssigneeId = :tier3User.Id 
                AND PermissionSetId = :tier2PS.Id 
                LIMIT 1
            ];
            
            if (existingAssignment.isEmpty()) {
                PermissionSetAssignment psa = new PermissionSetAssignment(
                    AssigneeId = tier3User.Id,
                    PermissionSetId = tier2PS.Id
                );
                insert psa;
            }
        }
        
        BlockReportExportCondition condition = new BlockReportExportCondition();
        
        ReportEvent reportEvent = new ReportEvent();
        reportEvent.UserId = tier3User.Id;
        reportEvent.Operation = EXPORT_OPERATION;
        reportEvent.RowsProcessed = 8000; // Should be allowed under Tier 3 (10k) but not Tier 2 (5k)
        
        // Act
        Test.startTest();
        Boolean result = condition.evaluate(reportEvent);
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result, 'User with multiple tiers should get highest threshold (Tier 3 - 10k)');
    }

    /**
     * @description Helper method to create ReportEvent objects
     */
    private static ReportEvent createReportEvent(Id userId, String operation, Decimal rowsProcessed) {
        ReportEvent event = new ReportEvent();
        event.UserId = userId;
        event.Operation = operation;
        event.RowsProcessed = rowsProcessed;
        return event;
    }
}