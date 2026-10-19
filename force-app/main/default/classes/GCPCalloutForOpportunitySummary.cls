/*
 * opportunitySummary LWC entry point. OpportunitySummaryHelper gathers the records, calls the
 * Opportunity Summary service and shapes its reply.
 */
public with sharing class GCPCalloutForOpportunitySummary {
  /**
   * Generates the summary for one Opportunity. Returns the summary JSON, or an 'Error: ' string
   * carrying a label-backed message the user can read.
   */
  @AuraEnabled(cacheable=false)
  public static String makeGCPCallout(String userId, String recordId) {
    return OpportunitySummaryHelper.generateSummary(userId, recordId);
  }

  @AuraEnabled(cacheable=true)
  public static Boolean isOpportunitySummaryEnabled() {
    return OpportunitySummaryHelper.isOpportunitySummaryEnabled();
  }

  /**
   * Browser-cache settings for the opportunitySummary LWC, keyed CacheHours and CacheMaxKB.
   */
  @AuraEnabled(cacheable=true)
  public static Map<String, String> getClientSettings() {
    return OpportunitySummaryHelper.getClientSettings();
  }
}
