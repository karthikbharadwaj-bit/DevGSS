/*
 * Reads the Summary_Setting__mdt record of each AI summary. A record is queried once per transaction;
 * callers read typed fields and own their ranges and fallbacks.
 */
public inherited sharing class SummarySettingHelper {
  private static final String CUSTOM_FIELD_SUFFIX = '__c';

  private static Map<String, Summary_Setting__mdt> settingNameToRecordMap = new Map<String, Summary_Setting__mdt>();

  @TestVisible
  private static Map<String, Summary_Setting__mdt> settingNameToOverrideMap = new Map<String, Summary_Setting__mdt>();

  /**
   * Returns the settings record named developerName, such as OpportunitySummary. A missing record
   * comes back as an empty one, so every field reads as null and callers use their defaults.
   */
  public static Summary_Setting__mdt getSetting(String developerName) {
    if (String.isBlank(developerName)) {
      return new Summary_Setting__mdt();
    }
    if (
      Test.isRunningTest() &&
      settingNameToOverrideMap.containsKey(developerName)
    ) {
      return settingNameToOverrideMap.get(developerName);
    }
    if (!settingNameToRecordMap.containsKey(developerName)) {
      List<Summary_Setting__mdt> settings = (List<Summary_Setting__mdt>) new SummarySettingSelector()
        .selectSettingByDeveloperName(developerName)
        .executeQuery();
      settingNameToRecordMap.put(
        developerName,
        settings.isEmpty() ? new Summary_Setting__mdt() : settings[0]
      );
    }
    return settingNameToRecordMap.get(developerName);
  }

  /**
   * Returns value as an Integer when it is a whole number from 1 to maximum, and fallback otherwise.
   */
  public static Integer positiveInteger(
    Decimal value,
    Integer fallback,
    Integer maximum
  ) {
    if (
      value == null ||
      value <= 0 ||
      value > maximum ||
      value != value.round(System.RoundingMode.DOWN)
    ) {
      return fallback;
    }
    return value.intValue();
  }

  /**
   * Numeric settings for an LWC, keyed by field name without __c (CacheHours__c becomes CacheHours)
   * and written without trailing zeros. A blank field maps to null; the LWC validates each value.
   */
  public static Map<String, String> toClientSettings(
    Summary_Setting__mdt setting,
    List<Schema.SObjectField> fields
  ) {
    Map<String, String> settingNameToValueMap = new Map<String, String>();
    for (Schema.SObjectField field : fields) {
      Decimal value = setting == null ? null : (Decimal) setting.get(field);
      settingNameToValueMap.put(
        field.getDescribe().getName().removeEnd(CUSTOM_FIELD_SUFFIX),
        value == null ? null : value.stripTrailingZeros().toPlainString()
      );
    }
    return settingNameToValueMap;
  }
}
