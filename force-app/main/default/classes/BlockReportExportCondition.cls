/**
 * @description Transaction Security condition to block report exports based on daily row limits.
 *              Evaluates report export events and blocks exports when users exceed their
 *              configured daily threshold, unless they have bypass permissions.
 */
global class BlockReportExportCondition implements TxnSecurity.EventCondition {
    
    private static final String BYPASS_PERMISSION_SET = 'Export_Report_Permissions';
    private static final String EXPORT_OPERATION = 'ReportExported';
    private static final Integer DEFAULT_THRESHOLD = 0;
    /**
     * @description Main entry point for evaluating transaction security events
     * @param event The SObject event to evaluate (typically ReportEvent)
     * @return Boolean true if the event should be blocked, false if allowed
     */
    global Boolean evaluate(SObject event) {
        if (event == null) {
            return false;
        }
        
        switch on event {
            when ReportEvent reportEvent {
                return evaluateReportExport(reportEvent);
            }
            when else {
                return false;
            }
        }
    }

    /**
     * @description Evaluates whether a report export should be blocked based on daily row limits
     * @param reportEvent The ReportEvent to evaluate for export blocking
     * @return Boolean true if export should be blocked, false if allowed
     */
    private Boolean evaluateReportExport(ReportEvent reportEvent) {
        if (reportEvent == null) {
            return false;
        }
        
        // Check if this is actually an export operation
        Boolean isExportOperation = reportEvent.Operation != null 
            && reportEvent.Operation.contains(EXPORT_OPERATION);
        
        if (!isExportOperation) {
            return false;
        }

        // Step 1: Check for bypass permissions
        Boolean hasBypassPermission = checkBypassPermission(reportEvent.UserId);
        if (hasBypassPermission) {
            // Calculate current export size for tracking
            Decimal currentExportRows = reportEvent.RowsProcessed != null ? reportEvent.RowsProcessed : 0;
            
            // Publish tracking event for bypass users to maintain audit trail
            publishUsageEvent(reportEvent.UserId, currentExportRows);
            return false;
        }
        
        // Step 2: Get daily threshold based on user's tier
        Decimal dailyThreshold = getDailyThresholdForUser(reportEvent.UserId);
        
        // Step 3: Get current usage for today
        Decimal totalRowsExportedToday = getTodaysUsage(reportEvent.UserId);
        
        // Step 4: Calculate current export size
        Decimal currentExportRows = reportEvent.RowsProcessed != null ? reportEvent.RowsProcessed : 0;
        
        // Step 5: Determine if export should be blocked
        if (totalRowsExportedToday + currentExportRows > dailyThreshold) {
            return true; // Block the export
        }

        // Step 6: Publish tracking event for allowed exports
        publishUsageEvent(reportEvent.UserId, currentExportRows);
        return false; 
    }
    
    /**
     * @description Checks if the user has bypass permissions for report export limits
     * @param userId The ID of the user to check
     * @return Boolean true if user has bypass permissions, false otherwise
     */
    private Boolean checkBypassPermission(Id userId) {
        if (userId == null) {
            return false;
        }
        
        try {
            return ![
                SELECT Id 
                FROM PermissionSetAssignment 
                WHERE AssigneeId = :userId
                    AND PermissionSet.Name = :BYPASS_PERMISSION_SET
                LIMIT 1
            ].isEmpty();
        } catch (QueryException e) {
            System.debug(LoggingLevel.ERROR, 'Error checking bypass permission: ' + e.getMessage());
            return false; // Fail secure - no bypass if query fails
        }
    }
    
    /**
     * @description Retrieves the daily export threshold based on user's tier
     * @param userId The ID of the user to get threshold for
     * @return Decimal the daily threshold value for the user's tier, or default if not found
     */
    private Decimal getDailyThresholdForUser(Id userId) {
        if (userId == null) {
            return DEFAULT_THRESHOLD;
        }
        
        try {
            // Get all tier policies
            List<ReportExportPolicy__mdt> policies = [
                SELECT PermissionSetName__c, Threshold__c, TierName__c 
                FROM ReportExportPolicy__mdt 
                WHERE PermissionSetName__c != NULL
                ORDER BY Threshold__c DESC
            ];
            
            if (policies.isEmpty()) {
                return DEFAULT_THRESHOLD;
            }
            
            // Check user's permission set assignments to determine tier
            List<PermissionSetAssignment> userAssignments = [
                SELECT PermissionSet.Name 
                FROM PermissionSetAssignment 
                WHERE AssigneeId = :userId
                    AND PermissionSet.Name IN :getPolicyPermissionSetNames(policies)
            ];
            
            // Find the highest tier the user belongs to
            for (ReportExportPolicy__mdt policy : policies) {
                for (PermissionSetAssignment assignment : userAssignments) {
                    if (assignment.PermissionSet.Name == policy.PermissionSetName__c) {
                        return policy.Threshold__c != null ? policy.Threshold__c : DEFAULT_THRESHOLD;
                    }
                }
            }
            
        } catch (QueryException e) {
            System.debug(LoggingLevel.ERROR, 'Error retrieving user tier policy: ' + e.getMessage());
        }
        return DEFAULT_THRESHOLD;
    }
    
    /**
     * @description Helper method to extract permission set names from policies
     * @param policies List of ReportExportPolicy__mdt records
     * @return Set<String> set of permission set names
     */
    private Set<String> getPolicyPermissionSetNames(List<ReportExportPolicy__mdt> policies) {
        Set<String> permissionSetNames = new Set<String>();
        for (ReportExportPolicy__mdt policy : policies) {
            if (policy.PermissionSetName__c != null) {
                permissionSetNames.add(policy.PermissionSetName__c);
            }
        }
        return permissionSetNames;
    }
    
    /**
     * @description Gets the total rows exported by the user today
     * @param userId The ID of the user to check usage for
     * @return Decimal the total rows exported today, or 0 if none found
     */
    private Decimal getTodaysUsage(Id userId) {
        if (userId == null) {
            return 0;
        }
        
        try {
            List<ReportExportUsage__c> usageRecords = [
                SELECT ExportedRows__c 
                FROM ReportExportUsage__c
                WHERE User__c = :userId
                    AND ExportDate__c = :Date.today()
                LIMIT 1
            ];
            
            if (!usageRecords.isEmpty() && usageRecords[0].ExportedRows__c != null) {
                return usageRecords[0].ExportedRows__c;
            }
        } catch (QueryException e) {
            System.debug(LoggingLevel.ERROR, 'Error retrieving usage data: ' + e.getMessage());
        }
        
        return 0; 
    }
    
    /**
     * @description Publishes a platform event to track report export usage
     * @param userId The ID of the user performing the export
     * @param rowsProcessed The number of rows in the current export
     */
    private void publishUsageEvent(Id userId, Decimal rowsProcessed) {
        if (userId == null || rowsProcessed == null) {
            return;
        }
        
        try {
            ReportExportUsage_PE__e usageEvent = new ReportExportUsage_PE__e(
                UserId__c = userId,
                RowsProcessed__c = rowsProcessed,
                ExportDate__c = Date.today()
            );
            
            Database.SaveResult result = EventBus.publish(usageEvent);
            if (!result.isSuccess()) {
                System.debug(LoggingLevel.ERROR, 'Failed to publish usage event: ' + result.getErrors());
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Exception publishing usage event: ' + e.getMessage());
        }
    }
}