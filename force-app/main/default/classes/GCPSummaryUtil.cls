/*
 * Field-level security helpers shared by the Opportunity and Account Summary callouts.
 * QueryFactory runs in system mode and `with sharing` only covers row access, so every queried
 * record is stripped of fields the running user cannot read before it reaches a GCP payload.
 */
public inherited sharing class GCPSummaryUtil {
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
}
