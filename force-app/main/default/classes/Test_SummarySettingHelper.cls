/* Covers the Summary_Setting__mdt reader shared by the Account and Opportunity Summary callouts. */
@IsTest
private class Test_SummarySettingHelper {
  private static final String ACCOUNT_SETTING = 'AccountSummary';
  private static final String OPPORTUNITY_SETTING = 'OpportunitySummary';
  private static final String MISSING_SETTING = 'SummarySettingThatDoesNotExist';
  private static final String GMAIL_DOMAIN = 'gmail.com';

  // ── getSetting ───
  @IsTest
  static void shouldReturnDeployedRecordWhenSettingExists() {
    Test.startTest();
    Summary_Setting__mdt accountSetting = SummarySettingHelper.getSetting(
      ACCOUNT_SETTING
    );
    Summary_Setting__mdt opportunitySetting = SummarySettingHelper.getSetting(
      OPPORTUNITY_SETTING
    );
    Test.stopTest();

    String accountMessage = 'The deployed AccountSummary record is readable without seeAllData.';
    String domainMessage = 'A multi-line value must come back whole, not as its first line.';
    Assert.areEqual(
      ACCOUNT_SETTING,
      accountSetting.DeveloperName,
      accountMessage
    );
    Assert.isNotNull(accountSetting.TimeoutSeconds__c, accountMessage);
    String domains = opportunitySetting.GenericEmailDomains__c;
    Assert.isTrue(domains.contains(GMAIL_DOMAIN), domainMessage);
    Assert.isTrue(domains.split('\n').size() > 1, domainMessage);
  }

  @IsTest
  static void shouldReturnEmptyRecordWhenSettingIsMissingOrNameIsBlank() {
    Test.startTest();
    Summary_Setting__mdt missing = SummarySettingHelper.getSetting(
      MISSING_SETTING
    );
    Summary_Setting__mdt blank = SummarySettingHelper.getSetting(' ');
    Test.stopTest();

    String missingMessage = 'An unknown setting must read as blank fields so callers use their defaults.';
    Assert.isNotNull(missing, missingMessage);
    Assert.isNull(missing.TimeoutSeconds__c, missingMessage);
    Assert.isNotNull(blank, missingMessage);
    Assert.isNull(blank.CacheHours__c, missingMessage);
  }

  @IsTest
  static void shouldReturnOverrideWhenTestSetsOne() {
    SummarySettingHelper.settingNameToOverrideMap.put(
      OPPORTUNITY_SETTING,
      new Summary_Setting__mdt(MaxActivities__c = 4)
    );

    Test.startTest();
    Summary_Setting__mdt setting = SummarySettingHelper.getSetting(
      OPPORTUNITY_SETTING
    );
    Test.stopTest();

    String overrideMessage = 'A test override must replace the deployed record.';
    Assert.areEqual(4, setting.MaxActivities__c.intValue(), overrideMessage);
    Assert.isNull(setting.MaxOpenCases__c, overrideMessage);
  }

  // ── positiveInteger ───
  @IsTest
  static void shouldReturnFallbackWhenValueIsBlankFractionalOrOutOfRange() {
    String fallbackMessage = 'A blank, fractional or out-of-range value must use the default.';
    Test.startTest();
    for (
      Decimal value : new List<Decimal>{ null, 0, -1, 1.5, 51, 999999999999.0 }
    ) {
      Assert.areEqual(
        50,
        SummarySettingHelper.positiveInteger(value, 50, 50),
        fallbackMessage
      );
    }
    Integer lowerBound = SummarySettingHelper.positiveInteger(1, 50, 50);
    Integer upperBound = SummarySettingHelper.positiveInteger(50.00, 50, 50);
    Integer lowerCap = SummarySettingHelper.positiveInteger(15, 50, 50);
    Test.stopTest();

    String boundMessage = 'Whole numbers from 1 to the maximum must be accepted.';
    Assert.areEqual(1, lowerBound, boundMessage);
    Assert.areEqual(50, upperBound, boundMessage);
    Assert.areEqual(15, lowerCap, boundMessage);
  }

  // ── toClientSettings ───
  @IsTest
  static void shouldKeyClientSettingsByFieldNameWithoutTrailingZeros() {
    Summary_Setting__mdt setting = new Summary_Setting__mdt(
      CacheHours__c = 0.2500,
      CacheMaxKB__c = 100
    );
    List<Schema.SObjectField> fields = new List<Schema.SObjectField>{
      Summary_Setting__mdt.CacheHours__c,
      Summary_Setting__mdt.CacheMaxKB__c,
      Summary_Setting__mdt.ListRowLimit__c
    };

    Test.startTest();
    Map<String, String> settings = SummarySettingHelper.toClientSettings(
      setting,
      fields
    );
    Map<String, String> fromNull = SummarySettingHelper.toClientSettings(
      null,
      fields
    );
    Test.stopTest();

    String valueMessage = 'Numbers must be plain text without trailing zeros or exponents.';
    Assert.areEqual('0.25', settings.get('CacheHours'), valueMessage);
    Assert.areEqual('100', settings.get('CacheMaxKB'), valueMessage);
    String blankMessage = 'A blank field must reach the LWC as null so it uses its default.';
    Assert.isTrue(settings.containsKey('ListRowLimit'), blankMessage);
    Assert.isNull(settings.get('ListRowLimit'), blankMessage);
    Assert.isNull(fromNull.get('CacheHours'), blankMessage);
  }
}
