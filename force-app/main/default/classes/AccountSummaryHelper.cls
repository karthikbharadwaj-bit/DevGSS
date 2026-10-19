/*
 * Collects one Account and its related records, sends them to the Account Summary service on
 * GCP Cloud Run, and shapes the service's structured sections for the aiAccountSummary LWC.
 * The service computes every count, total, score and band, so this class only gathers records
 * and never derives metrics of its own. GCPCalloutForAccountSummary is the LWC's entry point.
 */
public with sharing class AccountSummaryHelper {
  /* Resolves GCP_Endpoint_Settings__c.Account_Summary_Endpoint__c through GCPAuthUtil. */
  private static final String AUTH_CONFIG_NAME = GCPAuthUtil.ACCOUNT_SUMMARY;
  private static final String ENDPOINT_PATH = '/api/v1/account_summary';
  private static final String HTTP_METHOD_POST = 'POST';
  private static final String HEADER_CONTENT_TYPE = 'Content-Type';
  private static final String HEADER_AUTHORIZATION = 'Authorization';
  private static final String CONTENT_TYPE_JSON = 'application/json';
  private static final String BEARER_PREFIX = 'Bearer ';
  private static final String SETTING_NAME = 'AccountSummary';
  private static final List<Schema.SObjectField> CLIENT_SETTING_FIELDS = new List<Schema.SObjectField>{
    Summary_Setting__mdt.CacheHours__c,
    Summary_Setting__mdt.CacheMaxKB__c,
    Summary_Setting__mdt.ListRowLimit__c,
    Summary_Setting__mdt.ListRowsInitial__c
  };
  private static final String LIST_VALUE_SEPARATOR = ',';
  private static final String LOG_SOURCE = 'GCPCalloutForAccountSummary';
  private static final String DIGITS_PATTERN = '[0-9]+';
  private static final String RELATIONSHIP_SEPARATOR = '.';
  private static final String NOT_AN_ACCOUNT_MESSAGE = 'Account Summary was called with a record that is not an Account.';
  private static final String ACCOUNT_NOT_FOUND_MESSAGE = 'Account Summary could not read the requested Account.';
  private static final String PAYLOAD_TOO_LARGE_MESSAGE = 'Account Summary request exceeds the service size limit.';
  private static final String HTTP_FAILURE_MESSAGE = 'Account Summary callout failed. HTTP status: ';
  private static final String SERVICE_FAILURE_MESSAGE = 'Account Summary service returned status: ';
  private static final String SERVICE_MESSAGE_SEPARATOR = ' - ';
  private static final String MISSING_PAYLOAD_KEY_MESSAGE = 'Account Summary has no payload key for field: ';

  private static final Integer DEFAULT_TIMEOUT_SECONDS = 120;
  private static final Integer MAX_TIMEOUT_SECONDS = 120;
  private static final Integer DEFAULT_CLOSED_CASE_MONTHS = 6;
  private static final Integer MAX_CLOSED_CASE_MONTHS = 24;
  private static final Integer MILLISECONDS_PER_SECOND = 1000;
  private static final Integer MAX_REQUEST_BYTES = 2 * 1024 * 1024;

  @TestVisible
  private static Integer requestSizeLimitBytes = MAX_REQUEST_BYTES;
  @TestVisible
  private static final Integer MAX_DESCRIPTION_LENGTH = 1000;
  private static final Integer MAX_LOGGED_MESSAGE_LENGTH = 255;
  private static final Integer HTTP_OK = 200;
  private static final Integer STATUS_UNPROCESSABLE = 422;
  private static final Integer STATUS_RATE_LIMITED = 429;

  /* Row caps and windows used when the setting is blank or out of range. */
  private static final Map<Schema.SObjectField, Integer> SETTING_TO_DEFAULT_MAP = new Map<Schema.SObjectField, Integer>{
    Summary_Setting__mdt.MaxOpenOpportunities__c => 200,
    Summary_Setting__mdt.MaxClosedOpportunities__c => 15,
    Summary_Setting__mdt.MaxOpenCases__c => 200,
    Summary_Setting__mdt.MaxClosedCases__c => 15,
    Summary_Setting__mdt.MaxEscalations__c => 200,
    Summary_Setting__mdt.MaxEntitlements__c => 100,
    Summary_Setting__mdt.MaxTeamMembers__c => 50,
    Summary_Setting__mdt.MaxContacts__c => 20,
    Summary_Setting__mdt.MaxTasks__c => 20,
    Summary_Setting__mdt.MaxCaseTasks__c => 10,
    Summary_Setting__mdt.MaxEvents__c => 10,
    Summary_Setting__mdt.MaxUpcomingEvents__c => 5,
    Summary_Setting__mdt.UpcomingEventDays__c => 30,
    Summary_Setting__mdt.MaxRetentionTasks__c => 5,
    Summary_Setting__mdt.MaxOrders__c => 5,
    Summary_Setting__mdt.MaxContracts__c => 5,
    Summary_Setting__mdt.MaxHistoryRows__c => 20,
    Summary_Setting__mdt.HistoryDays__c => 90
  };

  /* Largest value a setting may take; the 2 MB request limit still applies to the whole payload. */
  private static final Map<Schema.SObjectField, Integer> SETTING_TO_MAXIMUM_MAP = new Map<Schema.SObjectField, Integer>{
    Summary_Setting__mdt.MaxOpenOpportunities__c => 500,
    Summary_Setting__mdt.MaxClosedOpportunities__c => 50,
    Summary_Setting__mdt.MaxOpenCases__c => 500,
    Summary_Setting__mdt.MaxClosedCases__c => 50,
    Summary_Setting__mdt.MaxEscalations__c => 500,
    Summary_Setting__mdt.MaxEntitlements__c => 250,
    Summary_Setting__mdt.MaxTeamMembers__c => 100,
    Summary_Setting__mdt.MaxContacts__c => 50,
    Summary_Setting__mdt.MaxTasks__c => 50,
    Summary_Setting__mdt.MaxCaseTasks__c => 25,
    Summary_Setting__mdt.MaxEvents__c => 25,
    Summary_Setting__mdt.MaxUpcomingEvents__c => 25,
    Summary_Setting__mdt.UpcomingEventDays__c => 90,
    Summary_Setting__mdt.MaxRetentionTasks__c => 25,
    Summary_Setting__mdt.MaxOrders__c => 25,
    Summary_Setting__mdt.MaxContracts__c => 25,
    Summary_Setting__mdt.MaxHistoryRows__c => 50,
    Summary_Setting__mdt.HistoryDays__c => 365
  };

  private static final String KEY_USERNAME = 'username';
  private static final String KEY_RECORD_ID = 'recordId';
  private static final String KEY_ENRICHMENT = 'enableAccountSummaryEnrichment';
  private static final String KEY_CALL_TRANSCRIPTS = 'enableAccountSummaryCallTranscripts';
  private static final String KEY_ACCOUNT = 'account';
  private static final String KEY_DATA_COVERAGE = 'dataCoverage';
  private static final String KEY_RETURNED_COUNT = 'returnedCount';
  private static final String KEY_IS_TRUNCATED = 'isTruncated';

  private static final String LIST_OPEN_OPPORTUNITIES = 'openOpportunities';
  private static final String LIST_CLOSED_OPPORTUNITIES = 'closedOpportunities';
  private static final String LIST_OPEN_CASES = 'openCases';
  private static final String LIST_RECENTLY_CLOSED_CASES = 'recentlyClosedCases';
  private static final String LIST_ESCALATIONS = 'escalations';
  private static final String LIST_ENTITLEMENTS = 'entitlements';
  private static final String LIST_ACCOUNT_TEAM = 'accountTeamMembers';
  private static final String LIST_CONTACTS = 'contacts';
  private static final String LIST_TASKS = 'tasks';
  private static final String LIST_EVENTS = 'events';
  private static final String LIST_CASE_TASKS = 'caseTasks';
  private static final String LIST_UPCOMING_EVENTS = 'upcomingEvents';
  private static final String LIST_RETENTION_TASKS = 'retentionTasks';
  private static final String LIST_ORDERS = 'orders';
  private static final String LIST_CONTRACTS = 'contracts';
  private static final String LIST_ACCOUNT_HISTORY = 'accountHistory';

  private static final String RESPONSE_STATUS_CODE = 'statusCode';
  private static final String RESPONSE_BODY = 'body';
  private static final String RESPONSE_SUMMARY = 'account_summary';
  private static final String RESPONSE_AS_OF_DATE = 'as_of_date';
  private static final String RESPONSE_ENRICHMENT = 'account_enrichment';
  private static final String RESULT_SUCCESS = 'success';

  /* Keys the service reads as dates even though the org stores a datetime. */
  private static final Set<String> DATE_ONLY_KEYS = new Set<String>{
    'rcActivationDate'
  };

  /*
   * What is polymorphic, so QueryFactory cannot select What.Type. The record type is read from
   * the WhatId prefix and sent next to the Id instead.
   */
  private static final String KEY_RELATED_TO_ID = 'relatedToId';
  private static final String KEY_RELATED_TO_TYPE = 'relatedToType';

  /* Long text sent only up to MAX_DESCRIPTION_LENGTH; the RingSense link sits near the top. */
  private static final Set<String> TRUNCATED_TEXT_KEYS = new Set<String>{
    'description'
  };

  /*
   * GCP payload key for every field the selectors return for the Account Summary. The selectors
   * decide which fields each list sends; these names are the service contract.
   */
  private static final Map<Schema.SObjectField, String> FIELD_TO_PAYLOAD_KEY = new Map<Schema.SObjectField, String>{
    Account.Id => 'id',
    Account.Name => 'name',
    Account.Type => 'type',
    Account.Industry => 'industry',
    Account.BillingCity => 'billingCity',
    Account.BillingState => 'billingState',
    Account.BillingCountry => 'billingCountry',
    Account.Website => 'website',
    Account.CurrencyIsoCode => 'currencyIsoCode',
    Account.OwnerId => 'ownerId',
    Account.CSM_Name__c => 'csmName',
    Account.RC_Account_Status__c => 'rcAccountStatus',
    Account.RC_Tier__c => 'rcTier',
    Account.RC_Activation_Date__c => 'rcActivationDate',
    Account.MRR__c => 'mrr',
    Account.aMRR__c => 'amrr',
    Account.Total_Net_MRR__c => 'totalNetMrr',
    Account.Total_Won_Opportunities__c => 'totalWonOpportunities',
    Account.Next_Renewal_Date__c => 'nextRenewalDate',
    Account.Licenses_Purchased__c => 'licensesPurchased',
    Account.Number_of_Extensions__c => 'numberOfExtensions',
    Account.Days_Since_Activity__c => 'daysSinceActivity',
    Account.C360_Overall_Risk_Score__c => 'c360OverallRiskScore',
    Account.C360v2_Overall_Adoption_Score__c => 'c360v2OverallAdoptionScore',
    Account.Account_Health__c => 'accountHealth',
    Account.Upsell_Potential__c => 'upsellPotential',
    Account.Rating => 'rating',
    Account.AccountSource => 'accountSource',
    Opportunity.Id => 'id',
    Opportunity.Name => 'name',
    Opportunity.StageName => 'stageName',
    Opportunity.Type => 'type',
    Opportunity.Amount => 'amount',
    Opportunity.CurrencyIsoCode => 'currencyIsoCode',
    Opportunity.CloseDate => 'closeDate',
    Opportunity.NextStep => 'nextStep',
    Opportunity.Probability => 'probability',
    Opportunity.ForecastCategoryName => 'forecastCategoryName',
    Opportunity.IsClosed => 'isClosed',
    Opportunity.IsWon => 'isWon',
    Case.Id => 'id',
    Case.CaseNumber => 'caseNumber',
    Case.Subject => 'subject',
    Case.Status => 'status',
    Case.Priority => 'priority',
    Case.IsEscalated => 'isEscalated',
    Case.CreatedDate => 'createdDate',
    Case.ClosedDate => 'closedDate',
    Case.Reason => 'reason',
    Case.Type => 'type',
    Case.IsClosed => 'isClosed',
    Red_Account__c.Status__c => 'status',
    Red_Account__c.Risk_Type__c => 'riskType',
    Red_Account__c.Risk_Reason__c => 'riskReason',
    Red_Account__c.Revenue_at_Risk__c => 'revenueAtRisk',
    Red_Account__c.CurrencyIsoCode => 'currencyIsoCode',
    Red_Account__c.Escalation_Category__c => 'escalationCategory',
    Red_Account__c.Escalation_Trend__c => 'escalationTrend',
    Red_Account__c.Red_Start_Date__c => 'redStartDate',
    Red_Account__c.Red_End_Date__c => 'redEndDate',
    Red_Account__c.Yellow_Start_Date__c => 'yellowStartDate',
    Entitlement__c.Display_Name__c => 'displayName',
    Entitlement__c.DisplayQuantity__c => 'displayQuantity',
    Entitlement__c.Total_Monthly_Price__c => 'totalMonthlyPrice',
    Entitlement__c.CurrencyIsoCode => 'currencyIsoCode',
    Entitlement__c.Start_Date__c => 'startDate',
    Entitlement__c.End_Date__c => 'endDate',
    Entitlement__c.Active__c => 'active',
    AccountTeamMember.TeamMemberRole => 'teamMemberRole',
    Contact.Id => 'id',
    Contact.Name => 'name',
    Contact.Title => 'title',
    Contact.Customer_Contact_Role__c => 'customerContactRole',
    Contact.LastActivityDate => 'lastActivityDate',
    /* id, subject, createdDate and description let the service find RingSense call links. */
    Task.Id => 'id',
    Task.Subject => 'subject',
    Task.CreatedDate => 'createdDate',
    Task.Description => 'description',
    Task.ActivityDate => 'activityDate',
    Task.TaskSubtype => 'taskSubtype',
    Task.WhatId => KEY_RELATED_TO_ID,
    Task.Type => 'type',
    Task.CallDurationInSeconds => 'callDurationInSeconds',
    Event.Id => 'id',
    Event.Subject => 'subject',
    Event.CreatedDate => 'createdDate',
    Event.Description => 'description',
    Event.ActivityDate => 'activityDate',
    Event.StartDateTime => 'startDateTime',
    Event.DurationInMinutes => 'durationInMinutes',
    Event.Type => 'type',
    Event.WhatId => KEY_RELATED_TO_ID,
    Retention_Task__c.Status__c => 'status',
    Retention_Task__c.Dunning_Status__c => 'dunningStatus',
    Order.Status => 'status',
    Order.EffectiveDate => 'effectiveDate',
    Contract.Status => 'status',
    Contract.EndDate => 'endDate',
    AccountHistory.Field => 'field',
    AccountHistory.OldValue => 'oldValue',
    AccountHistory.NewValue => 'newValue',
    AccountHistory.CreatedDate => 'createdDate'
  };

  /*
   * Which record an activity was logged on, who it was with and who owns it. Event.Owner can be
   * a Calendar, which QueryFactory cannot resolve, so the Event selector sends the creator.
   */
  private static final Map<String, String> RELATED_FIELD_TO_PAYLOAD_KEY = new Map<String, String>{
    'Owner.Name' => 'ownerName',
    'User.Name' => 'userName',
    'What.Name' => 'relatedToName',
    'Who.Name' => 'whoName',
    'CreatedBy.Name' => 'createdByName'
  };

  /**
   * Generates the summary for one Account. Technical failures are logged to PlatformLog and the
   * user only sees a label-backed message, so endpoints and status details never reach the UI.
   */
  public static String generateSummary(String recordId) {
    if (!isAccountSummaryEnabled()) {
      return GCPSummaryUtil.errorReply(
        System.Label.AccountSummaryUnavailableError
      );
    }
    try {
      Id accountId = toAccountId(recordId);
      GCPAuthUtil.GCPConfig config = GCPAuthUtil.loadConfig(AUTH_CONFIG_NAME);
      String jwt = GCPAuthUtil.createSignedJWT(config);
      String idToken = GCPAuthUtil.exchangeJWTForIdentityToken(
        jwt,
        config.identityTokenUrl
      );
      return callCloudRun(
        UserInfo.getUsername(),
        accountId,
        idToken,
        config.cloudRunEndpoint
      );
    } catch (Exception e) {
      PlatformLog.logException(LOG_SOURCE, e);
      return GCPSummaryUtil.errorReply(System.Label.SummaryServerError);
    }
  }

  public static Boolean isAccountSummaryEnabled() {
    GCP_Feature_Toggle__c setting = GCP_Feature_Toggle__c.getInstance();
    return setting != null && setting.Enable_Account_Summary__c == true;
  }

  /**
   * Browser-cache and list-row settings for the aiAccountSummary LWC, keyed by field name without
   * __c. The LWC validates each value and keeps its own default for a missing or invalid one.
   */
  public static Map<String, String> getClientSettings() {
    return SummarySettingHelper.toClientSettings(
      SummarySettingHelper.getSetting(SETTING_NAME),
      CLIENT_SETTING_FIELDS
    );
  }

  @TestVisible
  private static Boolean isAccountSummaryEnrichmentEnabled() {
    GCP_Feature_Toggle__c setting = GCP_Feature_Toggle__c.getInstance();
    return setting != null &&
      setting.Enable_Account_Summary_Enrichment__c == true;
  }

  @TestVisible
  private static Boolean isAccountSummaryCallTranscriptsEnabled() {
    GCP_Feature_Toggle__c setting = GCP_Feature_Toggle__c.getInstance();
    return setting != null &&
      setting.Account_Summary_Call_Transcripts__c == true;
  }

  @TestVisible
  private static Id toAccountId(String recordId) {
    Id accountId = String.isBlank(recordId)
      ? null
      : Id.valueOf(recordId.trim());
    if (
      accountId == null ||
      accountId.getSObjectType() != Account.SObjectType
    ) {
      throw new AccountSummaryException(NOT_AN_ACCOUNT_MESSAGE);
    }
    return accountId;
  }

  @TestVisible
  private static String callCloudRun(
    String username,
    Id accountId,
    String idToken,
    String endpoint
  ) {
    Map<String, Object> payload = buildPayload(
      username,
      accountId,
      isAccountSummaryEnrichmentEnabled()
    );
    String requestBody = serializeWithinLimit(payload);

    HttpRequest request = new HttpRequest();
    request.setEndpoint(
      GCPSummaryUtil.buildServiceEndpoint(endpoint, ENDPOINT_PATH)
    );
    request.setMethod(HTTP_METHOD_POST);
    request.setHeader(HEADER_CONTENT_TYPE, CONTENT_TYPE_JSON);
    request.setHeader(HEADER_AUTHORIZATION, BEARER_PREFIX + idToken);
    request.setBody(requestBody);
    request.setTimeout(timeoutSeconds() * MILLISECONDS_PER_SECOND);

    HttpResponse response = new Http().send(request);
    if (response.getStatusCode() != HTTP_OK) {
      throw new CalloutException(
        HTTP_FAILURE_MESSAGE + response.getStatusCode()
      );
    }
    return buildResult(response.getBody());
  }

  // ---------------- Payload assembly ----------------

  @TestVisible
  private static Map<String, Object> buildPayload(
    String username,
    Id accountId,
    Boolean isEnrichmentEnabled
  ) {
    AccountSelector accountSelector = new AccountSelector();
    Account summaryAccount = queryAccount(accountSelector, accountId);
    Map<String, Object> payload = new Map<String, Object>{
      KEY_USERNAME => username,
      KEY_RECORD_ID => String.valueOf(summaryAccount.Id),
      KEY_ENRICHMENT => isEnrichmentEnabled == true,
      // Always a JSON boolean, never null: GCP treats any non-boolean as OFF.
      KEY_CALL_TRANSCRIPTS => isAccountSummaryCallTranscriptsEnabled(),
      KEY_ACCOUNT => mapRow(
        summaryAccount,
        accountSelector.getAccountSummaryFieldList(),
        accountSelector.getAccountSummaryRelatedFieldList()
      )
    };

    /* Every list is always sent: [] tells the service the query ran and found nothing. */
    Map<String, Object> listKeyToCoverage = new Map<String, Object>();
    for (ListSpec spec : listSpecs(accountId)) {
      List<SObject> rows = queryList(spec);
      Boolean isTruncated = rows.size() > spec.maxRows;
      List<SObject> keptRows = isTruncated ? trimTo(rows, spec.maxRows) : rows;
      payload.put(spec.key, mapRows(keptRows, spec.fields, spec.relatedFields));
      listKeyToCoverage.put(
        spec.key,
        new Map<String, Object>{
          KEY_RETURNED_COUNT => keptRows.size(),
          KEY_IS_TRUNCATED => isTruncated
        }
      );
    }
    payload.put(KEY_DATA_COVERAGE, listKeyToCoverage);
    return payload;
  }

  /**
   * Serializes the payload, dropping rows from the end of the longest lists when it is over the
   * service limit. A trimmed list is marked truncated in its coverage entry.
   */
  @TestVisible
  private static String serializeWithinLimit(Map<String, Object> payload) {
    Map<String, Object> listKeyToCoverage = (Map<String, Object>) payload.get(
      KEY_DATA_COVERAGE
    );
    Map<String, List<Object>> keyToRows = new Map<String, List<Object>>();
    for (String listKey : listKeyToCoverage.keySet()) {
      keyToRows.put(listKey, (List<Object>) payload.get(listKey));
    }
    for (
      String listKey : GCPSummaryUtil.trimListsToFit(
        payload,
        keyToRows,
        requestSizeLimitBytes
      )
    ) {
      Map<String, Object> coverage = (Map<String, Object>) listKeyToCoverage.get(
        listKey
      );
      coverage.put(KEY_RETURNED_COUNT, keyToRows.get(listKey).size());
      coverage.put(KEY_IS_TRUNCATED, true);
    }
    String requestBody = JSON.serialize(payload);
    if (Blob.valueOf(requestBody).size() >= requestSizeLimitBytes) {
      throw new AccountSummaryException(PAYLOAD_TOO_LARGE_MESSAGE);
    }
    return requestBody;
  }

  @TestVisible
  private static List<ListSpec> listSpecs(Id accountId) {
    List<String> excludedCreators = excludedActivityCreators();
    Datetime asOf = Datetime.now();
    OpportunitySelector opportunities = new OpportunitySelector();
    CaseSelector cases = new CaseSelector();
    RedAccountSelector escalations = new RedAccountSelector();
    EntitlementSelector entitlements = new EntitlementSelector();
    AccountTeamMemberSelector teamMembers = new AccountTeamMemberSelector();
    ContactSelector contacts = new ContactSelector();
    TaskSelector tasks = new TaskSelector();
    EventSelector events = new EventSelector();
    RetentionTaskSelector retentionTasks = new RetentionTaskSelector();
    OrderSelector orders = new OrderSelector();
    ContractSelector contracts = new ContractSelector();
    AccountHistorySelector history = new AccountHistorySelector();
    return new List<ListSpec>{
      new ListSpec(
          LIST_OPEN_OPPORTUNITIES,
          opportunities.selectOpenOpportunitiesForAccountSummary(accountId),
          configuredInteger(Summary_Setting__mdt.MaxOpenOpportunities__c)
        )
        .withFields(
          opportunities.getOpenOpportunityAccountSummaryFieldList(),
          opportunities.getAccountSummaryRelatedFieldList()
        ),
      new ListSpec(
          LIST_CLOSED_OPPORTUNITIES,
          opportunities.selectClosedOpportunitiesForAccountSummary(accountId),
          configuredInteger(Summary_Setting__mdt.MaxClosedOpportunities__c)
        )
        .withFields(
          opportunities.getClosedOpportunityAccountSummaryFieldList(),
          opportunities.getAccountSummaryRelatedFieldList()
        ),
      new ListSpec(
          LIST_OPEN_CASES,
          cases.selectOpenCasesForAccountSummary(accountId),
          configuredInteger(Summary_Setting__mdt.MaxOpenCases__c)
        )
        .withFields(
          cases.getOpenCaseAccountSummaryFieldList(),
          cases.getAccountSummaryRelatedFieldList()
        ),
      new ListSpec(
          LIST_RECENTLY_CLOSED_CASES,
          cases.selectRecentlyClosedCasesForAccountSummary(
            accountId,
            asOf.addMonths(-closedCaseMonths())
          ),
          configuredInteger(Summary_Setting__mdt.MaxClosedCases__c)
        )
        .withFields(
          cases.getClosedCaseAccountSummaryFieldList(),
          cases.getAccountSummaryRelatedFieldList()
        ),
      new ListSpec(
          LIST_ESCALATIONS,
          escalations.selectEscalationsForAccountSummary(accountId),
          configuredInteger(Summary_Setting__mdt.MaxEscalations__c)
        )
        .withFields(escalations.getAccountSummaryFieldList(), null),
      new ListSpec(
          LIST_ENTITLEMENTS,
          entitlements.selectActiveEntitlementsForAccountSummary(accountId),
          configuredInteger(Summary_Setting__mdt.MaxEntitlements__c)
        )
        .withFields(entitlements.getAccountSummaryFieldList(), null),
      new ListSpec(
          LIST_ACCOUNT_TEAM,
          teamMembers.selectTeamMembersForAccountSummary(accountId),
          configuredInteger(Summary_Setting__mdt.MaxTeamMembers__c)
        )
        .withFields(
          teamMembers.getAccountSummaryFieldList(),
          teamMembers.getAccountSummaryRelatedFieldList()
        ),
      new ListSpec(
          LIST_CONTACTS,
          contacts.selectContactsForAccountSummary(accountId),
          configuredInteger(Summary_Setting__mdt.MaxContacts__c)
        )
        .withFields(contacts.getAccountSummaryFieldList(), null),
      new ListSpec(
          LIST_TASKS,
          tasks.selectHumanTasksForAccountSummary(accountId, excludedCreators),
          configuredInteger(Summary_Setting__mdt.MaxTasks__c)
        )
        .withFields(
          tasks.getAccountSummaryFieldList(),
          tasks.getAccountSummaryRelatedFieldList()
        ),
      new ListSpec(
          LIST_CASE_TASKS,
          tasks.selectHumanCaseTasksForAccountSummary(
            accountId,
            excludedCreators
          ),
          configuredInteger(Summary_Setting__mdt.MaxCaseTasks__c)
        )
        .withFields(
          tasks.getAccountSummaryFieldList(),
          tasks.getAccountSummaryRelatedFieldList()
        ),
      new ListSpec(
          LIST_EVENTS,
          events.selectPastEventsForAccountSummary(accountId, asOf),
          configuredInteger(Summary_Setting__mdt.MaxEvents__c)
        )
        .withFields(
          events.getAccountSummaryFieldList(),
          events.getAccountSummaryRelatedFieldList()
        ),
      new ListSpec(
          LIST_UPCOMING_EVENTS,
          events.selectUpcomingEventsForAccountSummary(
            accountId,
            asOf,
            asOf.addDays(
              configuredInteger(Summary_Setting__mdt.UpcomingEventDays__c)
            )
          ),
          configuredInteger(Summary_Setting__mdt.MaxUpcomingEvents__c)
        )
        .withFields(
          events.getAccountSummaryFieldList(),
          events.getAccountSummaryRelatedFieldList()
        ),
      new ListSpec(
          LIST_RETENTION_TASKS,
          retentionTasks.selectRetentionTasksForAccountSummary(accountId),
          configuredInteger(Summary_Setting__mdt.MaxRetentionTasks__c)
        )
        .withFields(retentionTasks.getAccountSummaryFieldList(), null),
      new ListSpec(
          LIST_ORDERS,
          orders.selectOrdersForAccountSummary(accountId),
          configuredInteger(Summary_Setting__mdt.MaxOrders__c)
        )
        .withFields(orders.getAccountSummaryFieldList(), null),
      new ListSpec(
          LIST_CONTRACTS,
          contracts.selectContractsForAccountSummary(accountId),
          configuredInteger(Summary_Setting__mdt.MaxContracts__c)
        )
        .withFields(contracts.getAccountSummaryFieldList(), null),
      new ListSpec(
          LIST_ACCOUNT_HISTORY,
          history.selectStatusAndOwnerChangesForAccountSummary(
            accountId,
            asOf.addDays(
              -configuredInteger(Summary_Setting__mdt.HistoryDays__c)
            )
          ),
          configuredInteger(Summary_Setting__mdt.MaxHistoryRows__c)
        )
        .withFields(history.getAccountSummaryFieldList(), null)
    };
  }

  private static Account queryAccount(
    AccountSelector accountSelector,
    Id accountId
  ) {
    List<SObject> accounts = GCPSummaryUtil.stripReadable(
      accountSelector.selectAccountForSummary(accountId).executeQuery()
    );
    if (accounts.isEmpty()) {
      throw new AccountSummaryException(ACCOUNT_NOT_FOUND_MESSAGE);
    }
    return (Account) accounts[0];
  }

  /* Queries one row past the cap so a full page can be told apart from a truncated one. */
  @TestVisible
  private static QueryFactory buildListQuery(ListSpec spec) {
    return spec.query.setLimit(spec.maxRows + 1);
  }

  private static List<SObject> queryList(ListSpec spec) {
    return GCPSummaryUtil.stripReadable(buildListQuery(spec).executeQuery());
  }

  @TestVisible
  private static List<Map<String, Object>> mapRows(
    List<SObject> records,
    List<Schema.SObjectField> fields,
    List<String> relatedFields
  ) {
    List<Map<String, Object>> rows = new List<Map<String, Object>>();
    for (SObject record : records) {
      rows.add(mapRow(record, fields, relatedFields));
    }
    return rows;
  }

  /* A field the user cannot read is sent as null, which the service reports as not recorded. */
  @TestVisible
  private static Map<String, Object> mapRow(
    SObject record,
    List<Schema.SObjectField> fields,
    List<String> relatedFields
  ) {
    Map<String, Object> row = new Map<String, Object>();
    for (Schema.SObjectField field : fields) {
      String key = payloadKey(FIELD_TO_PAYLOAD_KEY.get(field), field);
      Object value = GCPSummaryUtil.readableField(record, field);
      if (value instanceof Datetime && DATE_ONLY_KEYS.contains(key)) {
        value = ((Datetime) value).date();
      } else if (value instanceof String && TRUNCATED_TEXT_KEYS.contains(key)) {
        value = ((String) value).left(MAX_DESCRIPTION_LENGTH);
      }
      row.put(key, value);
      if (key == KEY_RELATED_TO_ID && value instanceof Id) {
        row.put(
          KEY_RELATED_TO_TYPE,
          String.valueOf(((Id) value).getSObjectType())
        );
      }
    }
    if (relatedFields != null) {
      for (String fieldPath : relatedFields) {
        row.put(
          payloadKey(RELATED_FIELD_TO_PAYLOAD_KEY.get(fieldPath), fieldPath),
          readableRelatedField(record, fieldPath)
        );
      }
    }
    return row;
  }

  /* A selector field without a payload name would silently vanish from the request. */
  private static String payloadKey(String key, Object field) {
    if (key == null) {
      throw new AccountSummaryException(MISSING_PAYLOAD_KEY_MESSAGE + field);
    }
    return key;
  }

  private static Object readableRelatedField(SObject record, String fieldPath) {
    Object related = GCPSummaryUtil.readableField(
      record,
      fieldPath.substringBefore(RELATIONSHIP_SEPARATOR)
    );
    return related instanceof SObject
      ? GCPSummaryUtil.readableField(
          (SObject) related,
          fieldPath.substringAfter(RELATIONSHIP_SEPARATOR)
        )
      : null;
  }

  private static List<SObject> trimTo(List<SObject> records, Integer maxRows) {
    List<SObject> kept = new List<SObject>();
    for (
      Integer index = 0; index < maxRows && index < records.size(); index++
    ) {
      kept.add(records[index]);
    }
    return kept;
  }

  // ---------------- Response handling ----------------

  /*
   * The service always answers HTTP 200 and puts the real status in body.statusCode. On any
   * non-200 status, and on rare platform errors reported as 200, body is a string message, so a
   * summary is only returned when body is an object that contains account_summary.
   */
  @TestVisible
  private static String buildResult(String responseBody) {
    Map<String, Object> envelope;
    try {
      Object raw = String.isBlank(responseBody)
        ? null
        : JSON.deserializeUntyped(responseBody);
      envelope = raw instanceof Map<String, Object>
        ? (Map<String, Object>) raw
        : new Map<String, Object>();
    } catch (JSONException e) {
      PlatformLog.logException(LOG_SOURCE, e);
      return GCPSummaryUtil.errorReply(System.Label.SummaryServerError);
    }

    Integer statusCode = toInteger(envelope.get(RESPONSE_STATUS_CODE));
    Object body = envelope.get(RESPONSE_BODY);
    if (statusCode == HTTP_OK && body instanceof Map<String, Object>) {
      Map<String, Object> bodyMap = (Map<String, Object>) body;
      if (bodyMap.get(RESPONSE_SUMMARY) instanceof Map<String, Object>) {
        Map<String, Object> result = new Map<String, Object>{
          RESULT_SUCCESS => true,
          RESPONSE_AS_OF_DATE => bodyMap.get(RESPONSE_AS_OF_DATE),
          RESPONSE_SUMMARY => bodyMap.get(RESPONSE_SUMMARY)
        };
        putIfObject(result, bodyMap, RESPONSE_ENRICHMENT);
        return JSON.serialize(result);
      }
    }

    logServiceFailure(statusCode, body);
    if (statusCode == STATUS_RATE_LIMITED) {
      return GCPSummaryUtil.errorReply(
        System.Label.AccountSummaryRateLimitError
      );
    }
    if (statusCode == STATUS_UNPROCESSABLE) {
      return GCPSummaryUtil.errorReply(
        System.Label.AccountSummaryUnavailableError
      );
    }
    return GCPSummaryUtil.errorReply(System.Label.SummaryServerError);
  }

  /* Service messages name fields, not record values, so they are safe to keep for support. */
  private static void logServiceFailure(Integer statusCode, Object body) {
    String message = SERVICE_FAILURE_MESSAGE + statusCode;
    if (body instanceof String) {
      message += SERVICE_MESSAGE_SEPARATOR + (String) body;
    }
    PlatformLog.logResult(
      LOG_SOURCE,
      message.left(MAX_LOGGED_MESSAGE_LENGTH),
      null,
      null,
      null,
      false
    );
  }

  private static void putIfObject(
    Map<String, Object> target,
    Map<String, Object> source,
    String key
  ) {
    if (source.get(key) instanceof Map<String, Object>) {
      target.put(key, source.get(key));
    }
  }

  private static Integer toInteger(Object value) {
    String text = value == null ? null : String.valueOf(value);
    return String.isNotBlank(text) && Pattern.matches(DIGITS_PATTERN, text)
      ? Integer.valueOf(text)
      : null;
  }

  // ---------------- Configuration ----------------

  /* A missing record or blank field falls back to the coded default. */
  private static Summary_Setting__mdt setting() {
    return SummarySettingHelper.getSetting(SETTING_NAME);
  }

  @TestVisible
  private static Integer timeoutSeconds() {
    return SummarySettingHelper.positiveInteger(
      setting().TimeoutSeconds__c,
      DEFAULT_TIMEOUT_SECONDS,
      MAX_TIMEOUT_SECONDS
    );
  }

  @TestVisible
  private static Integer closedCaseMonths() {
    return SummarySettingHelper.positiveInteger(
      setting().ClosedCaseMonths__c,
      DEFAULT_CLOSED_CASE_MONTHS,
      MAX_CLOSED_CASE_MONTHS
    );
  }

  /* Row cap or window for one list; a blank or out-of-range setting uses the coded default. */
  @TestVisible
  private static Integer configuredInteger(Schema.SObjectField field) {
    return SummarySettingHelper.positiveInteger(
      (Decimal) setting().get(field),
      SETTING_TO_DEFAULT_MAP.get(field),
      SETTING_TO_MAXIMUM_MAP.get(field)
    );
  }

  /* Integration users whose tasks are automated notices rather than customer contact. */
  @TestVisible
  private static List<String> excludedActivityCreators() {
    List<String> names = new List<String>();
    String raw = setting().ExcludedActivityCreators__c;
    if (String.isBlank(raw)) {
      return names;
    }
    for (String name : raw.split(LIST_VALUE_SEPARATOR)) {
      if (String.isNotBlank(name)) {
        names.add(name.trim());
      }
    }
    return names;
  }

  // ---------------- Types ----------------

  @TestVisible
  private class ListSpec {
    public String key;
    public QueryFactory query;
    public Integer maxRows;
    public List<Schema.SObjectField> fields = new List<Schema.SObjectField>();
    public List<String> relatedFields = new List<String>();

    public ListSpec(String key, QueryFactory query, Integer maxRows) {
      this.key = key;
      this.query = query;
      this.maxRows = maxRows;
    }

    public ListSpec withFields(
      List<Schema.SObjectField> fields,
      List<String> relatedFields
    ) {
      this.fields = fields;
      if (relatedFields != null) {
        this.relatedFields = relatedFields;
      }
      return this;
    }
  }

  @TestVisible
  private class AccountSummaryException extends Exception {
  }
}
