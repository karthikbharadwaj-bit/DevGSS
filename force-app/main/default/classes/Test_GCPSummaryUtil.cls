/* Covers the helpers shared by the Opportunity and Account Summary callouts. */
@IsTest
private class Test_GCPSummaryUtil {
  private static final String ACCOUNT_NAME = 'Summary Util Account';
  private static final String ACCOUNT_DESCRIPTION = 'Notes only an Account reader may see';

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

  @IsTest
  static void shouldRemoveFieldWhenRunningUserCannotReadIt() {
    Id minimumAccessProfileId = [
      SELECT Id
      FROM Profile
      WHERE Name = :ProfileHelper.PROFILE_NAME_MINIMUM_ACCESS_SALESFORCE
      LIMIT 1
    ]
    .Id;
    User restrictedUser = (User) new SObjectBuilder(User.SObjectType)
      .setFields(
        new Map<SObjectField, Object>{
          User.ProfileId => minimumAccessProfileId,
          User.Email => new ValueProvider.UniqueStringProvider(
            'summary-util@example.com'
          ),
          User.Username => new ValueProvider.UniqueStringProvider(
            'summary-util@example.com'
          ),
          User.CommunityNickname => new ValueProvider.UniqueStringProvider(
            'summaryUtil'
          )
        }
      )
      .create()
      .getRecord();
    List<SObject> records = new List<SObject>{
      new Account(Name = ACCOUNT_NAME, Description = ACCOUNT_DESCRIPTION)
    };

    Boolean canReadDescription;
    List<SObject> stripped;
    Test.startTest();
    System.runAs(restrictedUser) {
      canReadDescription = Schema.SObjectType.Account.fields.Description.isAccessible();
      stripped = GCPSummaryUtil.stripReadable(records);
    }
    Test.stopTest();

    String precondition = 'A Minimum Access user must not be able to read Account.Description.';
    String sizeMessage = 'Stripping must keep the record even when fields are removed.';
    String strippedMessage = 'A field the running user cannot read must not reach the payload.';
    Assert.isFalse(canReadDescription, precondition);
    Assert.areEqual(1, stripped.size(), sizeMessage);
    Assert.isNull(
      GCPSummaryUtil.readableField(stripped[0], Account.Description),
      strippedMessage
    );
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

  // ── buildServiceEndpoint ───
  @IsTest
  static void shouldReplaceConfiguredPathWhenBuildingEndpoint() {
    String host = 'https://service.example.invalid';
    String path = '/api/v1/account_summary';

    Test.startTest();
    String fromPath = GCPSummaryUtil.buildServiceEndpoint(
      host + '/api/v1/other_route',
      path
    );
    String fromSlashes = GCPSummaryUtil.buildServiceEndpoint(
      ' ' + host + '// ',
      path
    );
    String fromBlank = GCPSummaryUtil.buildServiceEndpoint(null, path);
    Test.stopTest();

    String pathMessage = 'The summary path must replace any configured path.';
    String slashMessage = 'Every trailing slash and surrounding space must be removed.';
    String blankMessage = 'A blank endpoint must stay blank.';
    Assert.areEqual(host + path, fromPath, pathMessage);
    Assert.areEqual(host + path, fromSlashes, slashMessage);
    Assert.isNull(fromBlank, blankMessage);
  }

  // ── errorReply ───
  @IsTest
  static void shouldPrefixMessageWhenBuildingErrorReply() {
    Test.startTest();
    String reply = GCPSummaryUtil.errorReply('Try again later.');
    Test.stopTest();

    String replyMessage = 'An error reply must be the Error: prefix followed by the message.';
    Assert.areEqual('Error: Try again later.', reply, replyMessage);
  }

  // ── trimListsToFit ───
  @IsTest
  static void shouldDropRowsFromLongestListWhenPayloadIsOverLimit() {
    List<Map<String, Object>> longRows = textRows(5);
    List<Map<String, Object>> shortRows = textRows(2);
    Map<String, Object> payload = new Map<String, Object>{
      'long' => longRows,
      'short' => shortRows
    };

    Test.startTest();
    Set<String> trimmedKeys = GCPSummaryUtil.trimListsToFit(
      payload,
      new Map<String, List<Object>>{ 'long' => longRows, 'short' => shortRows },
      600
    );
    Test.stopTest();

    Assert.isTrue(
      Blob.valueOf(JSON.serialize(payload)).size() < 600,
      'The trimmed payload must be under the limit.'
    );
    Assert.areEqual(
      new Set<String>{ 'long' },
      trimmedKeys,
      'Only the longest list should lose rows.'
    );
    Assert.areEqual(3, longRows.size(), 'Rows must come off the longest list.');
    Assert.areEqual(
      2,
      shortRows.size(),
      'The shorter list must keep its rows.'
    );
  }

  @IsTest
  static void shouldLeaveListsWhenPayloadFits() {
    List<Map<String, Object>> rows = textRows(3);
    Map<String, Object> payload = new Map<String, Object>{ 'rows' => rows };

    Test.startTest();
    Set<String> trimmedKeys = GCPSummaryUtil.trimListsToFit(
      payload,
      new Map<String, List<Object>>{ 'rows' => rows },
      2 * 1024 * 1024
    );
    Test.stopTest();

    Assert.isTrue(
      trimmedKeys.isEmpty(),
      'A payload under the limit must not be trimmed.'
    );
    Assert.areEqual(
      3,
      rows.size(),
      'Every row must be kept when the payload fits.'
    );
  }

  private static List<Map<String, Object>> textRows(Integer rowCount) {
    List<Map<String, Object>> rows = new List<Map<String, Object>>();
    for (Integer index = 0; index < rowCount; index++) {
      rows.add(new Map<String, Object>{ 'text' => 'a'.repeat(100) });
    }
    return rows;
  }
}
