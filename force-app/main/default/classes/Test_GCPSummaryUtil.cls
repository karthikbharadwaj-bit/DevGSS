/* Covers the FLS helpers shared by the Opportunity and Account Summary callouts. */
@IsTest
private class Test_GCPSummaryUtil {
  private static final String ACCOUNT_NAME = 'Summary Util Account';

  // ── stripReadable ───
  @IsTest
  static void shouldReturnEmptyListWhenRecordsAreNullOrEmpty() {
    Test.startTest();
    List<SObject> fromNull = GCPSummaryUtil.stripReadable(null);
    List<SObject> fromEmpty = GCPSummaryUtil.stripReadable(new List<SObject>());
    Test.stopTest();

    String nullMessage = 'A null list must give an empty list, not null.';
    String emptyMessage = 'An empty list must stay empty.';
    Assert.isTrue(fromNull.isEmpty(), nullMessage);
    Assert.isTrue(fromEmpty.isEmpty(), emptyMessage);
  }

  @IsTest
  static void shouldKeepReadableFieldsWhenStrippingRecords() {
    List<SObject> records = new List<SObject>{
      new Account(Name = ACCOUNT_NAME)
    };

    Test.startTest();
    List<SObject> stripped = GCPSummaryUtil.stripReadable(records);
    Test.stopTest();

    String sizeMessage = 'Stripping must keep every record.';
    String nameMessage = 'The admin running the test can read Account.Name.';
    Assert.areEqual(1, stripped.size(), sizeMessage);
    Assert.areEqual(ACCOUNT_NAME, stripped[0].get(Account.Name), nameMessage);
  }

  // ── readableField ───
  @IsTest
  static void shouldReturnPopulatedValueWhenFieldIsPresent() {
    Account record = new Account(Name = ACCOUNT_NAME);

    Test.startTest();
    Object byName = GCPSummaryUtil.readableField(record, 'Name');
    Object byToken = GCPSummaryUtil.readableField(record, Account.Name);
    Test.stopTest();

    String nameMessage = 'A populated field must be returned by API name.';
    String tokenMessage = 'A populated field must be returned by field token.';
    Assert.areEqual(ACCOUNT_NAME, byName, nameMessage);
    Assert.areEqual(ACCOUNT_NAME, byToken, tokenMessage);
  }

  @IsTest
  static void shouldReturnNullWhenFieldIsMissingOrInputsAreBlank() {
    Account record = new Account(Name = ACCOUNT_NAME);
    Schema.SObjectField missingToken;

    Test.startTest();
    Object unpopulated = GCPSummaryUtil.readableField(record, Account.Industry);
    Object nullRecord = GCPSummaryUtil.readableField(null, 'Name');
    Object blankName = GCPSummaryUtil.readableField(record, '');
    Object nullToken = GCPSummaryUtil.readableField(record, missingToken);
    Test.stopTest();

    String unpopulatedMessage = 'A field that was not queried must read as null.';
    String nullRecordMessage = 'A null record must read as null.';
    String blankNameMessage = 'A blank field name must read as null.';
    String nullTokenMessage = 'A null field token must read as null.';
    Assert.isNull(unpopulated, unpopulatedMessage);
    Assert.isNull(nullRecord, nullRecordMessage);
    Assert.isNull(blankName, blankNameMessage);
    Assert.isNull(nullToken, nullTokenMessage);
  }
}
