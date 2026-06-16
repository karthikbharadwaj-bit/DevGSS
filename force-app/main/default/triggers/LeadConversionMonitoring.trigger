trigger LeadConversionMonitoring on Lead_Conversion_Monitoring__e (after insert) {
    LeadConversionMonitoringHelper.processTrigger(Trigger.new);
}