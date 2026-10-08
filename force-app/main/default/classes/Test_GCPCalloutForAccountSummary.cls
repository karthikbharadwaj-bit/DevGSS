/*
 * Covers GCPCalloutForAccountSummary: the request payload built from one Account, the callout
 * contract with the Account Summary service, and every response status the LWC must handle.
 */
@IsTest
private class Test_GCPCalloutForAccountSummary {
  private static final String SERVICE_HOST = 'https://service.example.invalid';
  private static final String EXPECTED_ENDPOINT =
    SERVICE_HOST + '/api/v1/account_summary';
  private static final String TEST_USERNAME = 'account-summary-test@example.com';
  private static final String TEST_TOKEN = 'test-token';
  private static final String ACCOUNT_WEBSITE = 'https://example.com';
  private static final Integer ACTIVITY_CAP = 5;

  private static final String SUCCESS_RESPONSE = JSON.serialize(
    new Map<String, Object>{
      'statusCode' => 200,
      'body' => new Map<String, Object>{
        'as_of_date' => '2026-06-29',
        'account_summary' => new Map<String, Object>{
          'account_flag' => new Map<String, Object>{
            'score' => 72,
            'band' => 'Amber'
          }
        },
        'derived_metrics' => new Map<String, Object>{ 'open_case_count' => 1 },
        'account_enrichment' => new Map<String, Object>{ 'status' => 'ok' }
      }
    }
  );

  @TestSetup
  static void testData() {
    new SObjectBuilder(ByPassTrigger__c.SObjectType)
      .setField(ByPassTrigger__c.SetupOwnerId, UserInfo.getOrganizationId())
      .setField(ByPassTrigger__c.Bypass_Account_Trigger__c, true)
      .setField(ByPassTrigger__c.Bypass_Opportunity_Trigger__c, true)
      .setField(ByPassTrigger__c.Bypass_Contact_Trigger__c, true)
      .setField(ByPassTrigger__c.Bypass_Case_Trigger__c, true)
      .create();
    new SObjectBuilder(GCP_Feature_Toggle__c.SObjectType)
      .setField(
        GCP_Feature_Toggle__c.SetupOwnerId,
        UserInfo.getOrganizationId()
      )
      .setField(GCP_Feature_Toggle__c.Enable_Account_Summary__c, true)
      .setField(
        GCP_Feature_Toggle__c.Enable_Account_Summary_Enrichment__c,
        true
      )
      .create();

    Account summaryAccount = (Account) new SObjectBuilder(Account.SObjectType)
      .setField(
        Account.Name,
        ValueProviderBuilder.provideUniqueString('Summary account')
      )
      .setField(Account.Website, ACCOUNT_WEBSITE)
      .create()
      .getRecord();
    new SObjectBuilder(Opportunity.SObjectType)
      .setField(Opportunity.AccountId, summaryAccount.Id)
      .setField(Opportunity.CloseDate, Date.today().addDays(30))
      .create();
    new SObjectBuilder(Contact.SObjectType)
      .setField(Contact.AccountId, summaryAccount.Id)
      .setField(
        Contact.LastName,
        ValueProviderBuilder.provideUniqueString('Summary contact')
      )
      .create();
    new SObjectBuilder(Task.SObjectType)
      .setField(Task.WhatId, summaryAccount.Id)
      .setField(
        Task.Subject,
        ValueProviderBuilder.provideUniqueString('Summary task')
      )
      .setField(Task.Status, 'Completed')
      .setField(Task.ActivityDate, Date.today().addDays(-1))
      .quantity(ACTIVITY_CAP + 1)
      .create();
  }

  private static Account testAccount() {
    return [SELECT Id FROM Account WHERE Website = :ACCOUNT_WEBSITE LIMIT 1];
  }

  private static Map<String, Object> coverageFor(
    Map<String, Object> payload,
    String listKey
  ) {
    Map<String, Object> coverage = (Map<String, Object>) payload.get(
      'dataCoverage'
    );
    return (Map<String, Object>) coverage.get(listKey);
  }

  @IsTest
  static void shouldSendEveryListWhenBuildingPayload() {
    Account summaryAccount = testAccount();

    Test.startTest();
    Map<String, Object> payload = GCPCalloutForAccountSummary.buildPayload(
      TEST_USERNAME,
      summaryAccount.Id,
      true
    );
    Test.stopTest();

    Map<String, Object> accountMap = (Map<String, Object>) payload.get(
      'account'
    );
    String recordIdMessage = 'recordId must equal account.id exactly.';
    String enrichmentMessage = 'The enrichment flag must be sent as a boolean.';
    String opportunityMessage = 'The open opportunity must be sent.';
    String emptyListMessage = 'A list whose query ran with no rows must be sent as [], not omitted.';
    String websiteMessage = 'Account fields must be mapped to camelCase keys.';
    Assert.areEqual(
      String.valueOf(summaryAccount.Id),
      payload.get('recordId'),
      recordIdMessage
    );
    Assert.areEqual(
      payload.get('recordId'),
      accountMap.get('id'),
      recordIdMessage
    );
    Assert.areEqual(
      true,
      payload.get('enableAccountSummaryEnrichment'),
      enrichmentMessage
    );
    Assert.areEqual(ACCOUNT_WEBSITE, accountMap.get('website'), websiteMessage);
    Assert.areEqual(
      1,
      ((List<Object>) payload.get('openOpportunities')).size(),
      opportunityMessage
    );
    for (
      String listKey : new List<String>{
        'closedOpportunities',
        'openCases',
        'recentlyClosedCases',
        'escalations',
        'entitlements',
        'accountTeamMembers',
        'contacts',
        'tasks',
        'events',
        'retentionTasks',
        'orders',
        'contracts',
        'accountHistory'
      }
    ) {
      String listMessage = emptyListMessage + ' ' + listKey;
      String coverageMessage = 'dataCoverage must include ' + listKey;
      Assert.isTrue(payload.get(listKey) instanceof List<Object>, listMessage);
      Assert.isNotNull(coverageFor(payload, listKey), coverageMessage);
    }
  }

  @IsTest
  static void shouldKeepOnlyNamedStatusAndOwnerChangesWhenQueryingAccountHistory() {
    Account summaryAccount = testAccount();
    GCPCalloutForAccountSummary.ListSpec historySpec;
    for (
      GCPCalloutForAccountSummary.ListSpec spec : GCPCalloutForAccountSummary.listSpecs()
    ) {
      if (spec.key == 'accountHistory') {
        historySpec = spec;
      }
    }

    Test.startTest();
    String condition = GCPCalloutForAccountSummary.buildListQuery(
        historySpec,
        summaryAccount.Id
      )
      .getCondition();
    Test.stopTest();

    String fieldMessage = 'History must be limited to Account Status and Owner.';
    String dataTypeMessage = 'Owner rows holding user Ids must be left out.';
    String windowMessage = 'History must cover the last 90 days.';
    Assert.isTrue(
      condition.contains('Field IN (\'RC_Account_Status__c\', \'Owner\')'),
      fieldMessage
    );
    Assert.isTrue(condition.contains('DataType = \'Text\''), dataTypeMessage);
    Assert.isTrue(condition.contains('LAST_N_DAYS:90'), windowMessage);
  }

  @IsTest
  static void shouldMarkListTruncatedWhenQueryHitsItsCap() {
    Account summaryAccount = testAccount();

    Test.startTest();
    Map<String, Object> payload = GCPCalloutForAccountSummary.buildPayload(
      TEST_USERNAME,
      summaryAccount.Id,
      false
    );
    Test.stopTest();

    Map<String, Object> taskCoverage = coverageFor(payload, 'tasks');
    String capMessage = 'Tasks must be trimmed to the cap.';
    String truncatedMessage = 'A list past its cap must be marked truncated.';
    String notTruncatedMessage = 'A list under its cap must not be marked truncated.';
    Assert.areEqual(
      ACTIVITY_CAP,
      ((List<Object>) payload.get('tasks')).size(),
      capMessage
    );
    Assert.areEqual(
      ACTIVITY_CAP,
      taskCoverage.get('returnedCount'),
      capMessage
    );
    Assert.areEqual(true, taskCoverage.get('isTruncated'), truncatedMessage);
    Assert.areEqual(
      false,
      coverageFor(payload, 'contacts').get('isTruncated'),
      notTruncatedMessage
    );
  }

  @IsTest
  static void shouldReturnSummaryWhenServiceCalloutSucceeds() {
    Account summaryAccount = testAccount();
    GCPCalloutForAccountSummary.labelSuffixToValue.put('TimeoutSeconds', '45');
    Test.setMock(
      HttpCalloutMock.class,
      new AccountSummaryCalloutMock(200, SUCCESS_RESPONSE, summaryAccount.Id)
    );

    Test.startTest();
    String rawResult = GCPCalloutForAccountSummary.callCloudRun(
      TEST_USERNAME,
      summaryAccount.Id,
      TEST_TOKEN,
      SERVICE_HOST + '/api/v1/opportunity_summary'
    );
    Test.stopTest();

    Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(
      rawResult
    );
    String successMessage = 'A 200 object body with account_summary must be returned as success.';
    String passthroughMessage = 'Derived metrics and enrichment must be passed through unchanged.';
    Assert.areEqual(true, result.get('success'), successMessage);
    Assert.isTrue(
      result.get('account_summary') instanceof Map<String, Object>,
      successMessage
    );
    Assert.areEqual('2026-06-29', result.get('as_of_date'), successMessage);
    Assert.isTrue(result.containsKey('derived_metrics'), passthroughMessage);
    Assert.isTrue(result.containsKey('account_enrichment'), passthroughMessage);
  }

  @IsTest
  static void shouldThrowCalloutExceptionWhenHttpStatusIsNotOk() {
    Account summaryAccount = testAccount();
    Test.setMock(
      HttpCalloutMock.class,
      new AccountSummaryCalloutMock(503, '', summaryAccount.Id)
    );
    Boolean isThrown = false;

    Test.startTest();
    try {
      GCPCalloutForAccountSummary.callCloudRun(
        TEST_USERNAME,
        summaryAccount.Id,
        TEST_TOKEN,
        SERVICE_HOST
      );
    } catch (CalloutException e) {
      isThrown = true;
    }
    Test.stopTest();

    String exceptionMessage = 'A non-200 HTTP status must raise a CalloutException.';
    Assert.isTrue(isThrown, exceptionMessage);
  }

  @IsTest
  static void shouldReturnRateLimitMessageWhenServiceStatusIs429() {
    String response = JSON.serialize(
      new Map<String, Object>{ 'statusCode' => 429, 'body' => 'Too many' }
    );

    Test.startTest();
    Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(
      GCPCalloutForAccountSummary.buildResult(response)
    );
    Test.stopTest();

    String messageText = 'A 429 must show the rate-limit label.';
    Assert.areEqual(false, result.get('success'), messageText);
    Assert.areEqual(
      System.Label.AccountSummaryRateLimitError,
      result.get('message'),
      messageText
    );
  }

  @IsTest
  static void shouldReturnUnavailableMessageWhenServiceStatusIs422() {
    String response = JSON.serialize(
      new Map<String, Object>{ 'statusCode' => 422, 'body' => 'Bad output' }
    );

    Test.startTest();
    Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(
      GCPCalloutForAccountSummary.buildResult(response)
    );
    Test.stopTest();

    String messageText = 'A 422 must show the unavailable label.';
    Assert.areEqual(
      System.Label.AccountSummaryUnavailableError,
      result.get('message'),
      messageText
    );
  }

  @IsTest
  static void shouldReturnServerErrorWhenOkStatusCarriesStringBody() {
    String response = JSON.serialize(
      new Map<String, Object>{
        'statusCode' => 200,
        'body' => 'We are currently handling a high volume of requests.'
      }
    );

    Test.startTest();
    Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(
      GCPCalloutForAccountSummary.buildResult(response)
    );
    Test.stopTest();

    String messageText = 'A 200 with a string body is a platform error, not a summary.';
    Assert.areEqual(false, result.get('success'), messageText);
    Assert.areEqual(
      System.Label.AccountSummaryServerError,
      result.get('message'),
      messageText
    );
  }

  @IsTest
  static void shouldReturnServerErrorWhenResponseIsNotJson() {
    Test.startTest();
    Map<String, Object> invalid = (Map<String, Object>) JSON.deserializeUntyped(
      GCPCalloutForAccountSummary.buildResult('<html>gateway</html>')
    );
    Map<String, Object> blank = (Map<String, Object>) JSON.deserializeUntyped(
      GCPCalloutForAccountSummary.buildResult('')
    );
    Test.stopTest();

    String messageText = 'Unreadable responses must return the generic server error.';
    Assert.areEqual(
      System.Label.AccountSummaryServerError,
      invalid.get('message'),
      messageText
    );
    Assert.areEqual(
      System.Label.AccountSummaryServerError,
      blank.get('message'),
      messageText
    );
  }

  @IsTest
  static void shouldReturnErrorWhenRecordIsNotAnAccount() {
    Id opportunityId = [SELECT Id FROM Opportunity LIMIT 1].Id;

    Test.startTest();
    Map<String, Object> wrongType = (Map<String, Object>) JSON.deserializeUntyped(
      GCPCalloutForAccountSummary.makeGCPCallout(opportunityId)
    );
    Map<String, Object> blankId = (Map<String, Object>) JSON.deserializeUntyped(
      GCPCalloutForAccountSummary.makeGCPCallout(null)
    );
    Test.stopTest();

    String messageText = 'Only Account record Ids may generate a summary.';
    Assert.areEqual(false, wrongType.get('success'), messageText);
    Assert.areEqual(
      System.Label.AccountSummaryServerError,
      wrongType.get('message'),
      messageText
    );
    Assert.areEqual(false, blankId.get('success'), messageText);
  }

  @IsTest
  static void shouldSendActivationDateWhenOrgStoresDatetime() {
    Account summaryAccount = new Account(
      RC_Activation_Date__c = Datetime.newInstance(2018, 3, 12, 10, 0, 0)
    );

    Test.startTest();
    Map<String, Object> row = GCPCalloutForAccountSummary.mapRow(
      summaryAccount,
      new Map<Schema.SObjectField, String>{
        Account.RC_Activation_Date__c => 'rcActivationDate'
      },
      new Map<String, String>{ 'Owner.Name' => 'ownerName' }
    );
    Test.stopTest();

    String dateMessage = 'rcActivationDate must be sent as a date.';
    String relationshipMessage = 'A relationship that was not queried must be sent as null.';
    Assert.areEqual(
      Date.newInstance(2018, 3, 12),
      row.get('rcActivationDate'),
      dateMessage
    );
    Assert.isTrue(row.containsKey('ownerName'), relationshipMessage);
    Assert.isNull(row.get('ownerName'), relationshipMessage);
  }

  @IsTest
  static void shouldReplaceConfiguredPathWhenBuildingEndpoint() {
    Test.startTest();
    String fromPath = GCPCalloutForAccountSummary.buildServiceEndpoint(
      SERVICE_HOST + '/api/v1/other_endpoint'
    );
    String fromHost = GCPCalloutForAccountSummary.buildServiceEndpoint(
      SERVICE_HOST + '/'
    );
    String fromBlank = GCPCalloutForAccountSummary.buildServiceEndpoint(null);
    Test.stopTest();

    String endpointMessage = 'The Account Summary path must replace any configured path.';
    Assert.areEqual(EXPECTED_ENDPOINT, fromPath, endpointMessage);
    Assert.areEqual(EXPECTED_ENDPOINT, fromHost, endpointMessage);
    String blankMessage = 'A blank endpoint must stay blank.';
    Assert.isNull(fromBlank, blankMessage);
  }

  @IsTest
  static void shouldFallBackToDefaultTimeoutWhenLabelIsInvalid() {
    Test.startTest();
    GCPCalloutForAccountSummary.labelSuffixToValue.put('TimeoutSeconds', '500');
    Integer tooLarge = GCPCalloutForAccountSummary.timeoutSeconds();
    GCPCalloutForAccountSummary.labelSuffixToValue.put(
      'TimeoutSeconds',
      '2 minutes'
    );
    Integer notNumeric = GCPCalloutForAccountSummary.timeoutSeconds();
    GCPCalloutForAccountSummary.labelSuffixToValue.put('TimeoutSeconds', '45');
    Integer configured = GCPCalloutForAccountSummary.timeoutSeconds();
    Test.stopTest();

    String fallbackMessage = 'Out-of-range or non-numeric timeouts must fall back to 120 seconds.';
    Assert.areEqual(120, tooLarge, fallbackMessage);
    Assert.areEqual(120, notNumeric, fallbackMessage);
    String configuredMessage = 'A valid timeout label must be used.';
    Assert.areEqual(45, configured, configuredMessage);
  }

  @IsTest
  static void shouldReportFeatureTogglesWhenOrgDefaultsAreSet() {
    Test.startTest();
    Boolean isEnabled = GCPCalloutForAccountSummary.isAccountSummaryEnabled();
    Boolean isEnrichmentEnabled = GCPCalloutForAccountSummary.isAccountSummaryEnrichmentEnabled();
    Test.stopTest();

    String enabledMessage = 'The feature toggle must read the org default.';
    String enrichmentMessage = 'The enrichment toggle must read the org default.';
    Assert.isTrue(isEnabled, enabledMessage);
    Assert.isTrue(isEnrichmentEnabled, enrichmentMessage);
  }

  private class AccountSummaryCalloutMock implements HttpCalloutMock {
    private Integer statusCode;
    private String body;
    private Id expectedAccountId;

    private AccountSummaryCalloutMock(
      Integer statusCode,
      String body,
      Id expectedAccountId
    ) {
      this.statusCode = statusCode;
      this.body = body;
      this.expectedAccountId = expectedAccountId;
    }

    public HttpResponse respond(HttpRequest request) {
      String endpointMessage = 'The request must go to the Account Summary path.';
      String methodMessage = 'The request must be a POST.';
      String tokenMessage = 'The identity token must be sent.';
      String accountMessage = 'The Account Id must be sent.';
      String usernameMessage = 'The username must be sent.';
      Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(
        request.getBody()
      );
      Assert.areEqual(
        EXPECTED_ENDPOINT,
        request.getEndpoint(),
        endpointMessage
      );
      Assert.areEqual('POST', request.getMethod(), methodMessage);
      Assert.areEqual(
        'Bearer ' + TEST_TOKEN,
        request.getHeader('Authorization'),
        tokenMessage
      );
      Assert.areEqual(
        String.valueOf(expectedAccountId),
        payload.get('recordId'),
        accountMessage
      );
      Assert.areEqual(TEST_USERNAME, payload.get('username'), usernameMessage);

      HttpResponse response = new HttpResponse();
      response.setStatusCode(statusCode);
      response.setBody(body);
      return response;
    }
  }

  // ---------------- Call transcripts switch ----------------

  private static void setCallTranscriptsSetting(Boolean settingValue) {
    GCP_Feature_Toggle__c setting = GCP_Feature_Toggle__c.getOrgDefaults();
    setting.Account_Summary_Call_Transcripts__c = settingValue;
    upsert setting;
  }

  private static Map<String, Object> serializedPayload() {
    Account summaryAccount = testAccount();

    Test.startTest();
    Map<String, Object> payload = GCPCalloutForAccountSummary.buildPayload(
      TEST_USERNAME,
      summaryAccount.Id,
      true
    );
    Test.stopTest();
    return (Map<String, Object>) JSON.deserializeUntyped(
      JSON.serialize(payload)
    );
  }

  @IsTest
  static void shouldSendCallTranscriptsTrueAsJsonBooleanWhenSettingOn() {
    setCallTranscriptsSetting(true);

    Map<String, Object> payload = serializedPayload();

    String messageText = 'The switch must serialize as a JSON boolean that matches the setting.';
    Assert.isTrue(
      payload.get('enableAccountSummaryCallTranscripts') instanceof Boolean,
      messageText
    );
    Assert.areEqual(
      true,
      payload.get('enableAccountSummaryCallTranscripts'),
      messageText
    );
  }

  @IsTest
  static void shouldSendCallTranscriptsFalseAsJsonBooleanWhenSettingOff() {
    setCallTranscriptsSetting(false);

    Map<String, Object> payload = serializedPayload();

    String messageText = 'The switch must serialize as a JSON boolean that matches the setting.';
    Assert.isTrue(
      payload.get('enableAccountSummaryCallTranscripts') instanceof Boolean,
      messageText
    );
    Assert.areEqual(
      false,
      payload.get('enableAccountSummaryCallTranscripts'),
      messageText
    );
  }

  @IsTest
  static void shouldSendCallTranscriptsFalseWhenNoSettingRecordExists() {
    delete [SELECT Id FROM GCP_Feature_Toggle__c];

    Map<String, Object> payload = serializedPayload();

    String messageText = 'With no setting record the field must still be sent, as false.';
    Assert.isTrue(
      payload.containsKey('enableAccountSummaryCallTranscripts'),
      messageText
    );
    Assert.areEqual(
      false,
      payload.get('enableAccountSummaryCallTranscripts'),
      messageText
    );
  }

  @IsTest
  static void shouldRenderTheSameWhenResponseHasCallTranscriptsBlock() {
    String summary = '"account_summary":{"headline":"CRM summary"}';
    String withoutBlock = '{"statusCode":200,"body":{' + summary + '}}';
    String withBlock =
      '{"statusCode":200,"body":{' +
      summary +
      ',"call_transcripts":{"status":"no_calls",' +
      '"counts":{"calls":0,"ace":0,"salesforce":0,"none":0},"calls":[]}}}';

    String resultWithout = GCPCalloutForAccountSummary.buildResult(
      withoutBlock
    );
    String resultWith = GCPCalloutForAccountSummary.buildResult(withBlock);

    String messageText = 'The optional call_transcripts block must not change what the UI receives.';
    Assert.areEqual(
      true,
      ((Map<String, Object>) JSON.deserializeUntyped(resultWith))
        .get('success'),
      messageText
    );
    Assert.areEqual(resultWithout, resultWith, messageText);
  }

  // ---------------- RingSense call links ----------------

  private static final String RINGSENSE_LINK = 'RingSense call details link - https://ringsense.ops.ringcentral.com/calls/00000000-0000-0000-0000-000000000000';

  private static Map<String, Object> rowWithId(List<Object> rows, Id recordId) {
    for (Object row : rows) {
      Map<String, Object> rowMap = (Map<String, Object>) row;
      if (rowMap.get('id') == String.valueOf(recordId)) {
        return rowMap;
      }
    }
    return null;
  }

  private static void assertRingSenseRow(
    Map<String, Object> row,
    String expectedSubject
  ) {
    String rowMessage = 'The activity row must carry id, subject, createdDate and description.';
    String descriptionMessage = 'The description must be cut to 1000 characters with the link intact.';
    Assert.isNotNull(row, rowMessage);
    Assert.isTrue(row.containsKey('subject'), rowMessage);
    Assert.areEqual(expectedSubject, row.get('subject'), rowMessage);
    Assert.isTrue(row.get('createdDate') instanceof String, rowMessage);
    Assert.isNotNull(
      JSON.deserialize('"' + row.get('createdDate') + '"', Datetime.class),
      'createdDate must be an ISO-8601 datetime.'
    );
    String description = (String) row.get('description');
    Assert.areEqual(
      GCPCalloutForAccountSummary.MAX_DESCRIPTION_LENGTH,
      description.length(),
      descriptionMessage
    );
    Assert.isTrue(description.startsWith(RINGSENSE_LINK), descriptionMessage);
    Assert.isTrue(row.containsKey('activityDate'), rowMessage);
  }

  @IsTest
  static void shouldSendRingSenseFieldsOnTaskAndEventRows() {
    Account summaryAccount = testAccount();
    // Logged on the opportunity, not the account: AccountId still ties them to the account.
    Id opportunityId = [
      SELECT Id
      FROM Opportunity
      WHERE AccountId = :summaryAccount.Id
      LIMIT 1
    ]
    .Id;
    String longDescription = RINGSENSE_LINK + '\n' + 'x'.repeat(1500);
    String taskSubject = 'RingSense call';
    String eventSubject = 'RingSense meeting';
    Task callTask = (Task) new SObjectBuilder(Task.SObjectType)
      .setField(Task.WhatId, opportunityId)
      .setField(Task.Subject, taskSubject)
      .setField(Task.Status, 'Completed')
      .setField(Task.ActivityDate, Date.today())
      .setField(Task.Description, longDescription)
      .create()
      .getRecord();
    Event meeting = (Event) new SObjectBuilder(Event.SObjectType)
      .setField(Event.WhatId, opportunityId)
      .setField(Event.Subject, eventSubject)
      .setField(Event.ActivityDateTime, Datetime.now().addHours(-2))
      .setField(Event.DurationInMinutes, 30)
      .setField(Event.Description, longDescription)
      .create()
      .getRecord();

    Test.startTest();
    Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(
      JSON.serialize(
        GCPCalloutForAccountSummary.buildPayload(
          TEST_USERNAME,
          summaryAccount.Id,
          true
        )
      )
    );
    Test.stopTest();

    assertRingSenseRow(
      rowWithId((List<Object>) payload.get('tasks'), callTask.Id),
      taskSubject
    );
    // The org can rewrite Event.Subject on insert, so compare with the stored value.
    assertRingSenseRow(
      rowWithId((List<Object>) payload.get('events'), meeting.Id),
      [SELECT Subject FROM Event WHERE Id = :meeting.Id].Subject
    );
  }

  @IsTest
  static void shouldSerializeTasksAsEmptyListWhenAccountHasNoTasks() {
    Account summaryAccount = testAccount();
    delete [SELECT Id FROM Task WHERE WhatId = :summaryAccount.Id];

    Test.startTest();
    Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(
      JSON.serialize(
        GCPCalloutForAccountSummary.buildPayload(
          TEST_USERNAME,
          summaryAccount.Id,
          true
        )
      )
    );
    Test.stopTest();

    String messageText = 'With no Tasks the request must still send tasks as [].';
    Assert.isTrue(payload.containsKey('tasks'), messageText);
    Assert.areEqual(
      0,
      ((List<Object>) payload.get('tasks')).size(),
      messageText
    );
    Assert.areEqual(
      0,
      coverageFor(payload, 'tasks').get('returnedCount'),
      messageText
    );
  }
}
