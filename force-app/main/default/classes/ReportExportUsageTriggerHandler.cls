/**
 * @description Handler class for ReportExportUsage_PE__e platform event trigger.
 *              Aggregates report export usage data from platform events into custom objects
 *              following Salesforce best practices for bulkification and governor limits.
 * 
 * @changelog
 * - v1.0: Initial implementation with proper bulkification and error handling
 */
public class ReportExportUsageTriggerHandler {
    
    private static Boolean hasRun = false;
    
    private static final String CLASS_NAME = 'ReportExportUsageTriggerHandler';
    private static final String SEPARATOR = '_';
    
    /**
     * @description Main entry point for trigger execution
     * @param newRecords List of new platform event records from Trigger.new
     */
    public void handleAfterInsert(List<ReportExportUsage_PE__e> newRecords) {
        final String METHOD_NAME = 'handleAfterInsert';
        
        // Prevent recursive execution
        if (hasRun) {
            System.debug(LoggingLevel.DEBUG, CLASS_NAME + '.' + METHOD_NAME + ': Preventing recursive execution');
            return;
        }
        hasRun = true;
        
        try {
            System.debug(LoggingLevel.INFO, CLASS_NAME + '.' + METHOD_NAME + ': Processing ' + newRecords.size() + ' platform events');
            
            // Input validation
            if (newRecords == null || newRecords.isEmpty()) {
                System.debug(LoggingLevel.WARN, CLASS_NAME + '.' + METHOD_NAME + ': No records to process');
                return;
            }
            
            // Process the platform events
            processUsageEvents(newRecords);
            
        } catch (Exception e) {
            // Log the error with full context
            String errorMsg = CLASS_NAME + '.' + METHOD_NAME + ': Unexpected error - ' + e.getMessage() + 
                            '\nStack Trace: ' + e.getStackTraceString();
            System.debug(LoggingLevel.ERROR, errorMsg);
            
            // Re-throw to ensure the platform event processing fails visibly
            throw new TriggerHandlerException('Error processing ReportExportUsage platform events: ' + e.getMessage(), e);
        }
    }
    
    /**
     * @description Processes platform events and aggregates usage data
     * @param events List of ReportExportUsage_PE__e platform events
     */
    private void processUsageEvents(List<ReportExportUsage_PE__e> events) {
        final String METHOD_NAME = 'processUsageEvents';
        
        // Step 1: Collect and validate event data
        Map<String, EventAggregation> eventAggregations = aggregateEventData(events);
        
        if (eventAggregations.isEmpty()) {
            System.debug(LoggingLevel.INFO, CLASS_NAME + '.' + METHOD_NAME + ': No valid events to process');
            return;
        }
        
        // Step 2: Query existing usage records in bulk (single SOQL query)
        Map<String, ReportExportUsage__c> existingUsageMap = queryExistingUsage(eventAggregations.keySet());
        
        // Step 3: Prepare records for upsert
        List<ReportExportUsage__c> recordsToUpsert = prepareUsageRecords(eventAggregations, existingUsageMap);
        
        // Step 4: Perform bulk upsert
        if (!recordsToUpsert.isEmpty()) {
            performBulkUpsert(recordsToUpsert);
        }
    }
    
    /**
     * @description Aggregates platform event data by user and date
     * @param events List of platform events to aggregate
     * @return Map<String, EventAggregation> Aggregated event data keyed by user_date
     */
    private Map<String, EventAggregation> aggregateEventData(List<ReportExportUsage_PE__e> events) {
        final String METHOD_NAME = 'aggregateEventData';
        Map<String, EventAggregation> aggregations = new Map<String, EventAggregation>();
        Integer skippedEvents = 0;
        
        for (ReportExportUsage_PE__e event : events) {
            // Skip invalid events
            if (String.isBlank(event.UserId__c) || event.ExportDate__c == null) {
                skippedEvents++;
                continue;
            }
            
            String key = generateKey(event.UserId__c, event.ExportDate__c);
            Decimal rowsToAdd = event.RowsProcessed__c != null ? event.RowsProcessed__c : 0;
            
            EventAggregation existing = aggregations.get(key);
            if (existing != null) {
                // Aggregate with existing data
                existing.totalRows += rowsToAdd;
            } else {
                // Create new aggregation
                aggregations.put(key, new EventAggregation(event.UserId__c, event.ExportDate__c, rowsToAdd));
            }
        }
        
        if (skippedEvents > 0) {
            System.debug(LoggingLevel.WARN, CLASS_NAME + '.' + METHOD_NAME + ': Skipped ' + skippedEvents + ' invalid events');
        }
        
        System.debug(LoggingLevel.DEBUG, CLASS_NAME + '.' + METHOD_NAME + ': Aggregated ' + aggregations.size() + ' unique user/date combinations');
        return aggregations;
    }
    
    /**
     * @description Queries existing usage records in bulk
     * @param keys Set of user_date keys to query for
     * @return Map<String, ReportExportUsage__c> Existing usage records keyed by user_date
     */
    private Map<String, ReportExportUsage__c> queryExistingUsage(Set<String> keys) {
        final String METHOD_NAME = 'queryExistingUsage';
        Map<String, ReportExportUsage__c> existingUsageMap = new Map<String, ReportExportUsage__c>();
        
        // Extract user IDs and dates for efficient querying
        Set<String> userIds = new Set<String>();
        Set<Date> exportDates = new Set<Date>();
        
        for (String key : keys) {
            List<String> keyParts = key.split(SEPARATOR);
            if (keyParts.size() >= 2) {
                userIds.add(keyParts[0]);
                exportDates.add(Date.valueOf(keyParts[1]));
            }
        }
        
        try {
            // Single SOQL query to get all existing records
            List<ReportExportUsage__c> existingRecords = [
                SELECT Id, User__c, ExportDate__c, ExportedRows__c
                FROM ReportExportUsage__c
                WHERE User__c IN :userIds
                AND ExportDate__c IN :exportDates
            ];
            
            // Map the results by user_date key
            for (ReportExportUsage__c record : existingRecords) {
                String key = generateKey(record.User__c, record.ExportDate__c);
                existingUsageMap.put(key, record);
            }
            
            System.debug(LoggingLevel.DEBUG, CLASS_NAME + '.' + METHOD_NAME + ': Found ' + existingRecords.size() + ' existing usage records');
            
        } catch (QueryException e) {
            String errorMsg = CLASS_NAME + '.' + METHOD_NAME + ': Error querying existing usage records - ' + e.getMessage();
            System.debug(LoggingLevel.ERROR, errorMsg);
            throw new TriggerHandlerException(errorMsg, e);
        }
        
        return existingUsageMap;
    }
    
    /**
     * @description Prepares usage records for upsert operation
     * @param aggregations Map of aggregated event data
     * @param existingUsage Map of existing usage records
     * @return List<ReportExportUsage__c> Records ready for upsert
     */
    private List<ReportExportUsage__c> prepareUsageRecords(
        Map<String, EventAggregation> aggregations, 
        Map<String, ReportExportUsage__c> existingUsage) {
        
        List<ReportExportUsage__c> recordsToUpsert = new List<ReportExportUsage__c>();
        
        for (String key : aggregations.keySet()) {
            EventAggregation aggregation = aggregations.get(key);
            ReportExportUsage__c usageRecord = existingUsage.get(key);
            
            if (usageRecord != null) {
                // Update existing record
                Decimal currentRows = usageRecord.ExportedRows__c != null ? usageRecord.ExportedRows__c : 0;
                usageRecord.ExportedRows__c = currentRows + aggregation.totalRows;
            } else {
                // Create new record
                usageRecord = new ReportExportUsage__c(
                    User__c = aggregation.userId,
                    ExportDate__c = aggregation.exportDate,
                    ExportedRows__c = aggregation.totalRows
                );
            }
            
            recordsToUpsert.add(usageRecord);
        }
        
        return recordsToUpsert;
    }
    
    /**
     * @description Performs bulk upsert operation with proper error handling
     * @param recordsToUpsert List of records to upsert
     */
    private void performBulkUpsert(List<ReportExportUsage__c> recordsToUpsert) {
        final String METHOD_NAME = 'performBulkUpsert';
        
        try {
            Database.UpsertResult[] results = Database.upsert(recordsToUpsert, false);
            
            // Process results and log any failures
            Integer successCount = 0;
            Integer failureCount = 0;
            
            for (Integer i = 0; i < results.size(); i++) {
                Database.UpsertResult result = results[i];
                
                if (result.isSuccess()) {
                    successCount++;
                } else {
                    failureCount++;
                    ReportExportUsage__c failedRecord = recordsToUpsert[i];
                    String errorMsg = CLASS_NAME + '.' + METHOD_NAME + ': Failed to upsert usage record for User: ' + 
                                    failedRecord.User__c + ', Date: ' + failedRecord.ExportDate__c + '. Errors: ';
                    
                    for (Database.Error error : result.getErrors()) {
                        errorMsg += error.getMessage() + ' ';
                    }
                    
                    System.debug(LoggingLevel.ERROR, errorMsg);
                }
            }
            
            System.debug(LoggingLevel.INFO, CLASS_NAME + '.' + METHOD_NAME + ': Upsert completed - Success: ' + 
                        successCount + ', Failures: ' + failureCount);
            
            // If all records failed, throw an exception
            if (failureCount > 0 && successCount == 0) {
                throw new TriggerHandlerException('All usage record upserts failed');
            }
            
        } catch (DmlException e) {
            String errorMsg = CLASS_NAME + '.' + METHOD_NAME + ': DML error during upsert - ' + e.getMessage();
            System.debug(LoggingLevel.ERROR, errorMsg);
            throw new TriggerHandlerException(errorMsg, e);
        }
    }
    
    /**
     * @description Generates a consistent key for user and date combination
     * @param userId The user ID
     * @param exportDate The export date
     * @return String The generated key
     */
    private String generateKey(String userId, Date exportDate) {
        return userId + SEPARATOR + String.valueOf(exportDate);
    }
    
    /**
     * @description Inner class to hold aggregated event data
     */
    private class EventAggregation {
        public String userId;
        public Date exportDate;
        public Decimal totalRows;
        
        public EventAggregation(String userId, Date exportDate, Decimal totalRows) {
            this.userId = userId;
            this.exportDate = exportDate;
            this.totalRows = totalRows != null ? totalRows : 0;
        }
    }
    
    /**
     * @description Custom exception class for trigger handler errors
     */
    public class TriggerHandlerException extends Exception {}
}