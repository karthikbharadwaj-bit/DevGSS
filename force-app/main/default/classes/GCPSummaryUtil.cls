/*
 * Helpers shared by the Opportunity and Account Summary callouts: field-level security, the
 * service endpoint and the error reply. QueryFactory runs in system mode and `with sharing` only
 * covers row access, so every queried record is stripped of fields the running user cannot read
 * before it reaches a GCP payload.
 */
public inherited sharing class GCPSummaryUtil {
  /** Both LWCs check for this prefix before parsing a reply as JSON. */
  public static final String ERROR_PREFIX = 'Error: ';
  private static final String ERROR_REPLY_FORMAT = ERROR_PREFIX + '{0}';
  private static final String API_PATH_MARKER = '/api/v1/';
  private static final String PATH_SEPARATOR = '/';

  /**
   * Removes fields the running user cannot read. A stripped field is removed rather than nulled,
   * which is why values must be read through readableField instead of a direct getter.
   */
  public static List<SObject> stripReadable(List<SObject> records) {
    if (records == null || records.isEmpty()) {
      return new List<SObject>();
    }
    return Security.stripInaccessible(AccessType.READABLE, records, false)
      .getRecords();
  }

  /**
   * Returns the value of a field that survived stripReadable, or null when the field was not
   * queried or the user cannot read it.
   */
  public static Object readableField(SObject record, String fieldApiName) {
    if (record == null || String.isBlank(fieldApiName)) {
      return null;
    }
    return record.getPopulatedFieldsAsMap().get(fieldApiName);
  }

  /**
   * Token overload of readableField, so callers reference fields at compile time.
   */
  public static Object readableField(
    SObject record,
    Schema.SObjectField field
  ) {
    return field == null ? null : readableField(record, String.valueOf(field));
  }

  /**
   * Replaces any /api/v1/ path on the configured endpoint with the summary's own path, so the
   * setting may hold either the service host or a full URL. A blank endpoint stays blank.
   */
  public static String buildServiceEndpoint(
    String configuredEndpoint,
    String endpointPath
  ) {
    if (String.isBlank(configuredEndpoint)) {
      return configuredEndpoint;
    }
    String endpoint = configuredEndpoint.trim();
    Integer apiPathIndex = endpoint.toLowerCase().indexOf(API_PATH_MARKER);
    if (apiPathIndex >= 0) {
      endpoint = endpoint.substring(0, apiPathIndex);
    }
    while (endpoint.endsWith(PATH_SEPARATOR)) {
      endpoint = endpoint.removeEnd(PATH_SEPARATOR);
    }
    return endpoint + endpointPath;
  }

  /**
   * The reply an @AuraEnabled summary callout returns for a failure the user should see.
   */
  public static String errorReply(String message) {
    return String.format(ERROR_REPLY_FORMAT, new List<Object>{ message });
  }

  /**
   * Drops rows from the end of the longest list until the serialized payload is under limitBytes
   * or every list is empty, so each list keeps as many of its first rows as possible. The lists
   * are changed in place and must be the ones the payload holds.
   * @return keys of the lists that lost rows
   */
  public static Set<String> trimListsToFit(
    Map<String, Object> payload,
    Map<String, List<Object>> keyToRows,
    Integer limitBytes
  ) {
    Set<String> trimmedKeys = new Set<String>();
    Integer overflowBytes = bytesOverLimit(payload, limitBytes);
    while (
      overflowBytes > 0 &&
      dropLongestRows(keyToRows, overflowBytes, trimmedKeys)
    ) {
      overflowBytes = bytesOverLimit(payload, limitBytes);
    }
    return trimmedKeys;
  }

  private static Integer bytesOverLimit(
    Map<String, Object> payload,
    Integer limitBytes
  ) {
    return Blob.valueOf(JSON.serialize(payload)).size() - limitBytes + 1;
  }

  /* Each dropped row is measured on its own so the payload is serialized again only once per pass. */
  private static Boolean dropLongestRows(
    Map<String, List<Object>> keyToRows,
    Integer overflowBytes,
    Set<String> trimmedKeys
  ) {
    Integer droppedBytes = 0;
    Boolean hasDropped = false;
    while (droppedBytes < overflowBytes) {
      String longestKey = longestListKey(keyToRows);
      if (longestKey == null) {
        return hasDropped;
      }
      List<Object> rows = keyToRows.get(longestKey);
      Object row = rows.remove(rows.size() - 1);
      droppedBytes += Blob.valueOf(JSON.serialize(row)).size() + 1;
      trimmedKeys.add(longestKey);
      hasDropped = true;
    }
    return hasDropped;
  }

  private static String longestListKey(Map<String, List<Object>> keyToRows) {
    String longestKey;
    Integer longestSize = 0;
    for (String listKey : keyToRows.keySet()) {
      List<Object> rows = keyToRows.get(listKey);
      if (rows != null && rows.size() > longestSize) {
        longestKey = listKey;
        longestSize = rows.size();
      }
    }
    return longestKey;
  }
}
