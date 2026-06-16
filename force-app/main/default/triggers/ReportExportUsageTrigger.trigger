/**
 * @description Trigger for ReportExportUsage_PE__e platform events.
 *              Delegates processing to ReportExportUsageTriggerHandler to maintain
 *              separation of concerns and follow Salesforce best practices.
 * @changelog
 * - v1.0: Refactored to use trigger handler pattern with proper bulkification
 */
trigger ReportExportUsageTrigger on ReportExportUsage_PE__e (after insert) {
    
    // Delegate to handler class following Salesforce best practices
    new ReportExportUsageTriggerHandler().handleAfterInsert(Trigger.new);
}