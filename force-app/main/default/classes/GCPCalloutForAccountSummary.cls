/*
 * aiAccountSummary LWC entry point. AccountSummaryHelper gathers the records, calls the
 * Account Summary service and shapes its reply.
 */
public with sharing class GCPCalloutForAccountSummary {
  /**
   * Generates the summary for one Account. Returns the summary JSON, or an 'Error: ' string
   * carrying a label-backed message the user can read.
   */
  @AuraEnabled(cacheable=false)
  public static String makeGCPCallout(String recordId) {
    return AccountSummaryHelper.generateSummary(recordId);
  }

  @AuraEnabled(cacheable=true)
  public static Boolean isAccountSummaryEnabled() {
    return AccountSummaryHelper.isAccountSummaryEnabled();
  }

  /**
   * Browser-cache and list-row settings for the aiAccountSummary LWC, keyed by field name without
   * __c.
   */
  @AuraEnabled(cacheable=true)
  public static Map<String, String> getClientSettings() {
    return AccountSummaryHelper.getClientSettings();
  }
}
