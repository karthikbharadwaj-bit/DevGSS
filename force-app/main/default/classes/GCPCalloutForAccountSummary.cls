/*
 * Collects one Account and its related records, sends them to the Account Summary service on
 * GCP Cloud Run, and hands the service's structured sections back to the aiAccountSummary LWC.
 * The service computes every count, total, score and band, so this class only gathers records
 * and never derives metrics of its own.
 */
public with sharing class GCPCalloutForAccountSummary {
  /* Resolves GCP_Endpoint_Settings__c.Account_Summary_Endpoint__c through GCPAuthUtil. */
  private static final String AUTH_CONFIG_NAME = GCPAuthUtil.ACCOUNT_SUMMARY;
  private static final String ENDPOINT_PATH = '/api/v1/account_summary';
  private static final String API_PATH_MARKER = '/api/v1/';
  private static final String PATH_SEPARATOR = '/';
  private static final String HTTP_METHOD_POST = 'POST';
  private static final String HEADER_CONTENT_TYPE = 'Content-Type';
  private static final String HEADER_AUTHORIZATION = 'Authorization';
  private static final String CONTENT_TYPE_JSON = 'application/json';
  private static final String BEARER_PREFIX = 'Bearer ';
  private static final String LABEL_NAMESPACE = '';
  private static final String LABEL_PREFIX = 'AccountSummary';
  private static final String LABEL_BASE_LANGUAGE = 'en_US';
  private static final String TIMEOUT_LABEL_SUFFIX = 'TimeoutSeconds';
  private static final String LOG_SOURCE = 'GCPCalloutForAccountSummary';
  private static final String DIGITS_PATTERN = '[0-9]+';
  private static final String RELATIONSHIP_SEPARATOR = '.';
  private static final String NOT_AN_ACCOUNT_MESSAGE = 'Account Summary was called with a record that is not an Account.';
  private static final String ACCOUNT_NOT_FOUND_MESSAGE = 'Account Summary could not read the requested Account.';
  private static final String PAYLOAD_TOO_LARGE_MESSAGE = 'Account Summary request exceeds the service size limit.';
  private static final String HTTP_FAILURE_MESSAGE = 'Account Summary callout failed. HTTP status: ';
  private static final String SERVICE_FAILURE_MESSAGE = 'Account Summary service returned status: ';
  private static final String SERVICE_MESSAGE_SEPARATOR = ' - ';

  private static final Integer DEFAULT_TIMEOUT_SECONDS = 120;
  private static final Integer MAX_TIMEOUT_SECONDS = 120;
  private static final Integer MILLISECONDS_PER_SECOND = 1000;
  private static final Integer MAX_REQUEST_BYTES = 2 * 1024 * 1024;
  private static final Integer MAX_LOGGED_MESSAGE_LENGTH = 255;
  private static final Integer HTTP_OK = 200;
  private static final Integer STATUS_UNPROCESSABLE = 422;
  private static final Integer STATUS_RATE_LIMITED = 429;

  private static final Integer OPEN_OPPORTUNITY_LIMIT = 200;
  private static final Integer CLOSED_OPPORTUNITY_LIMIT = 15;
  private static final Integer OPEN_CASE_LIMIT = 200;
  private static final Integer RECENTLY_CLOSED_CASE_LIMIT = 15;
  private static final Integer ESCALATION_LIMIT = 200;
  private static final Integer ENTITLEMENT_LIMIT = 100;
  private static final Integer ACCOUNT_TEAM_LIMIT = 50;
  private static final Integer CONTACT_LIMIT = 20;
  private static final Integer ACTIVITY_LIMIT = 5;
  private static final Integer RETENTION_TASK_LIMIT = 5;
  private static final Integer ORDER_LIMIT = 5;
  private static final Integer CONTRACT_LIMIT = 5;
  private static final Integer ACCOUNT_HISTORY_LIMIT = 20;

  private static final String KEY_USERNAME = 'username';
  private static final String KEY_RECORD_ID = 'recordId';
  private static final String KEY_ENRICHMENT = 'enableAccountSummaryEnrichment';
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
  private static final String LIST_RETENTION_TASKS = 'retentionTasks';
  private static final String LIST_ORDERS = 'orders';
  private static final String LIST_CONTRACTS = 'contracts';
  private static final String LIST_ACCOUNT_HISTORY = 'accountHistory';

  private static final String RESPONSE_STATUS_CODE = 'statusCode';
  private static final String RESPONSE_BODY = 'body';
  private static final String RESPONSE_SUMMARY = 'account_summary';
  private static final String RESPONSE_AS_OF_DATE = 'as_of_date';
  private static final String RESPONSE_DERIVED_METRICS = 'derived_metrics';
  private static final String RESPONSE_ENRICHMENT = 'account_enrichment';
  private static final String RESULT_SUCCESS = 'success';
  private static final String RESULT_MESSAGE = 'message';

  private static final String CONDITION_ACCOUNT = 'Id = :bind0';
  private static final String CONDITION_OPEN_OPPORTUNITIES = 'AccountId = :bind0 AND IsClosed = false';
  private static final String CONDITION_CLOSED_OPPORTUNITIES = 'AccountId = :bind0 AND IsClosed = true';
  private static final String CONDITION_OPEN_CASES = 'AccountId = :bind0 AND IsClosed = false';
  private static final String CONDITION_RECENTLY_CLOSED_CASES = 'AccountId = :bind0 AND IsClosed = true AND ClosedDate = LAST_N_DAYS:183';
  private static final String CONDITION_ESCALATIONS = 'EscalatedAccount__c = :bind0';
  private static final String CONDITION_ENTITLEMENTS = 'Account__c = :bind0 AND Active__c = true';
  private static final String CONDITION_ACCOUNT_CHILD = 'AccountId = :bind0';
  private static final String CONDITION_RETENTION_TASKS = 'Account__c = :bind0';
  /* A future ActivityDate is a due date, not activity, and would push real activity out of the cap. */
  private static final String CONDITION_TASKS = 'WhatId = :bind0 AND TaskSubtype != \'ListEmail\' AND ActivityDate <= TODAY';
  private static final String CONDITION_EVENTS = 'WhatId = :bind0 AND ActivityDate <= TODAY';
  /*
   * Status and Owner are the only tracked Account fields that change in production. An Owner
   * change writes one row of user Ids and one of names; DataType = 'Text' keeps only the names.
   */
  private static final String CONDITION_ACCOUNT_HISTORY = 'AccountId = :bind0 AND Field IN (\'RC_Account_Status__c\', \'Owner\') AND DataType = \'Text\' AND CreatedDate = LAST_N_DAYS:90';

  /* Keys the service reads as dates even though the org stores a datetime. */
  private static final Set<String> DATE_ONLY_KEYS = new Set<String>{
    'rcActivationDate'
  };

  private static final Map<Schema.SObjectField, String> ACCOUNT_FIELD_TO_KEY = new Map<Schema.SObjectField, String>{
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
    Account.AccountSource => 'accountSource'
  };

  private static final Map<String, String> ACCOUNT_RELATED_FIELD_TO_KEY = new Map<String, String>{
    'Owner.Name' => 'ownerName'
  };

  private static final Map<Schema.SObjectField, String> OPEN_OPPORTUNITY_FIELD_TO_KEY = new Map<Schema.SObjectField, String>{
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
    Opportunity.IsClosed => 'isClosed'
  };

  private static final Map<String, String> OPEN_OPPORTUNITY_RELATED_FIELD_TO_KEY = new Map<String, String>{
    'Owner.Name' => 'ownerName'
  };

  private static final Map<Schema.SObjectField, String> CLOSED_OPPORTUNITY_FIELD_TO_KEY = new Map<Schema.SObjectField, String>{
    Opportunity.Id => 'id',
    Opportunity.Name => 'name',
    Opportunity.StageName => 'stageName',
    Opportunity.Type => 'type',
    Opportunity.Amount => 'amount',
    Opportunity.CurrencyIsoCode => 'currencyIsoCode',
    Opportunity.CloseDate => 'closeDate',
    Opportunity.IsClosed => 'isClosed',
    Opportunity.IsWon => 'isWon'
  };

  private static final Map<String, String> CLOSED_OPPORTUNITY_RELATED_FIELD_TO_KEY = new Map<String, String>{
    'Owner.Name' => 'ownerName'
  };

  private static final Map<Schema.SObjectField, String> OPEN_CASE_FIELD_TO_KEY = new Map<Schema.SObjectField, String>{
    Case.Id => 'id',
    Case.CaseNumber => 'caseNumber',
    Case.Subject => 'subject',
    Case.Status => 'status',
    Case.Priority => 'priority',
    Case.IsEscalated => 'isEscalated',
    Case.CreatedDate => 'createdDate',
    Case.Reason => 'reason',
    Case.Type => 'type',
    Case.IsClosed => 'isClosed'
  };

  private static final Map<String, String> OPEN_CASE_RELATED_FIELD_TO_KEY = new Map<String, String>{
    'Owner.Name' => 'ownerName'
  };

  private static final Map<Schema.SObjectField, String> CLOSED_CASE_FIELD_TO_KEY = new Map<Schema.SObjectField, String>{
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
    Case.IsClosed => 'isClosed'
  };

  private static final Map<String, String> CLOSED_CASE_RELATED_FIELD_TO_KEY = new Map<String, String>{
    'Owner.Name' => 'ownerName'
  };

  private static final Map<Schema.SObjectField, String> ESCALATION_FIELD_TO_KEY = new Map<Schema.SObjectField, String>{
    Red_Account__c.Status__c => 'status',
    Red_Account__c.Risk_Type__c => 'riskType',
    Red_Account__c.Risk_Reason__c => 'riskReason',
    Red_Account__c.Revenue_at_Risk__c => 'revenueAtRisk',
    Red_Account__c.CurrencyIsoCode => 'currencyIsoCode',
    Red_Account__c.Escalation_Category__c => 'escalationCategory',
    Red_Account__c.Escalation_Trend__c => 'escalationTrend',
    Red_Account__c.Red_Start_Date__c => 'redStartDate',
    Red_Account__c.Red_End_Date__c => 'redEndDate',
    Red_Account__c.Yellow_Start_Date__c => 'yellowStartDate'
  };

  private static final Map<Schema.SObjectField, String> ENTITLEMENT_FIELD_TO_KEY = new Map<Schema.SObjectField, String>{
    Entitlement__c.Display_Name__c => 'displayName',
    Entitlement__c.DisplayQuantity__c => 'displayQuantity',
    Entitlement__c.Total_Monthly_Price__c => 'totalMonthlyPrice',
    Entitlement__c.CurrencyIsoCode => 'currencyIsoCode',
    Entitlement__c.Start_Date__c => 'startDate',
    Entitlement__c.End_Date__c => 'endDate',
    Entitlement__c.Active__c => 'active'
  };

  private static final Map<Schema.SObjectField, String> ACCOUNT_TEAM_FIELD_TO_KEY = new Map<Schema.SObjectField, String>{
    AccountTeamMember.TeamMemberRole => 'teamMemberRole'
  };

  private static final Map<String, String> ACCOUNT_TEAM_RELATED_FIELD_TO_KEY = new Map<String, String>{
    'User.Name' => 'userName'
  };

  private static final Map<Schema.SObjectField, String> CONTACT_FIELD_TO_KEY = new Map<Schema.SObjectField, String>{
    Contact.Id => 'id',
    Contact.Name => 'name',
    Contact.Title => 'title',
    Contact.Customer_Contact_Role__c => 'customerContactRole',
    Contact.LastActivityDate => 'lastActivityDate'
  };

  private static final Map<Schema.SObjectField, String> TASK_FIELD_TO_KEY = new Map<Schema.SObjectField, String>{
    Task.ActivityDate => 'activityDate',
    Task.TaskSubtype => 'taskSubtype'
  };

  private static final Map<Schema.SObjectField, String> EVENT_FIELD_TO_KEY = new Map<Schema.SObjectField, String>{
    Event.ActivityDate => 'activityDate'
  };

  private static final Map<Schema.SObjectField, String> RETENTION_TASK_FIELD_TO_KEY = new Map<Schema.SObjectField, String>{
    Retention_Task__c.Status__c => 'status',
    Retention_Task__c.Dunning_Status__c => 'dunningStatus'
  };

  private static final Map<Schema.SObjectField, String> ORDER_FIELD_TO_KEY = new Map<Schema.SObjectField, String>{
    Order.Status => 'status',
    Order.EffectiveDate => 'effectiveDate'
  };

  private static final Map<Schema.SObjectField, String> CONTRACT_FIELD_TO_KEY = new Map<Schema.SObjectField, String>{
    Contract.Status => 'status',
    Contract.EndDate => 'endDate'
  };

  private static final Map<Schema.SObjectField, String> ACCOUNT_HISTORY_FIELD_TO_KEY = new Map<Schema.SObjectField, String>{
    AccountHistory.Field => 'field',
    AccountHistory.OldValue => 'oldValue',
    AccountHistory.NewValue => 'newValue',
    AccountHistory.CreatedDate => 'createdDate'
  };

  @TestVisible
  private static Map<String, String> labelSuffixToValue = new Map<String, String>();

  /*
   * Generates the summary for one Account. Technical failures are logged to PlatformLog and the
   * user only sees a label-backed message, so endpoints and status details never reach the UI.
   */
  @AuraEnabled(cacheable=false)
  public static String makeGCPCallout(String recordId) {
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
      return errorJson(System.Label.AccountSummaryServerError);
    }
  }

  @AuraEnabled(cacheable=true)
  public static Boolean isAccountSummaryEnabled() {
    GCP_Feature_Toggle__c setting = GCP_Feature_Toggle__c.getInstance();
    return setting != null && setting.IsAccountSummaryEnabled__c == true;
  }

  @TestVisible
  private static Boolean isAccountSummaryEnrichmentEnabled() {
    GCP_Feature_Toggle__c setting = GCP_Feature_Toggle__c.getInstance();
    return setting != null &&
      setting.IsAccountSummaryEnrichmentEnabled__c == true;
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
    String requestBody = JSON.serialize(payload);
    if (Blob.valueOf(requestBody).size() > MAX_REQUEST_BYTES) {
      throw new AccountSummaryException(PAYLOAD_TOO_LARGE_MESSAGE);
    }

    HttpRequest request = new HttpRequest();
    request.setEndpoint(buildServiceEndpoint(endpoint));
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
    Account summaryAccount = queryAccount(accountId);
    Map<String, Object> payload = new Map<String, Object>{
      KEY_USERNAME => username,
      KEY_RECORD_ID => String.valueOf(summaryAccount.Id),
      KEY_ENRICHMENT => isEnrichmentEnabled == true,
      KEY_ACCOUNT => mapRow(
        summaryAccount,
        ACCOUNT_FIELD_TO_KEY,
        ACCOUNT_RELATED_FIELD_TO_KEY
      )
    };

    /* Every list is always sent: [] tells the service the query ran and found nothing. */
    Map<String, Object> listKeyToCoverage = new Map<String, Object>();
    for (ListSpec spec : listSpecs()) {
      List<SObject> rows = queryList(spec, accountId);
      Boolean isTruncated = rows.size() > spec.maxRows;
      List<SObject> keptRows = isTruncated ? trimTo(rows, spec.maxRows) : rows;
      payload.put(
        spec.key,
        mapRows(keptRows, spec.fieldToKey, spec.relatedFieldToKey)
      );
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

  @TestVisible
  private static List<ListSpec> listSpecs() {
    return new List<ListSpec>{
      new ListSpec(
          LIST_OPEN_OPPORTUNITIES,
          new OpportunitySelector(),
          CONDITION_OPEN_OPPORTUNITIES,
          OPEN_OPPORTUNITY_LIMIT
        )
        .withFields(
          OPEN_OPPORTUNITY_FIELD_TO_KEY,
          OPEN_OPPORTUNITY_RELATED_FIELD_TO_KEY
        )
        .orderBy(
          Opportunity.CloseDate,
          QueryFactory.SortOrder.ASCENDING,
          false
        ),
      new ListSpec(
          LIST_CLOSED_OPPORTUNITIES,
          new OpportunitySelector(),
          CONDITION_CLOSED_OPPORTUNITIES,
          CLOSED_OPPORTUNITY_LIMIT
        )
        .withFields(
          CLOSED_OPPORTUNITY_FIELD_TO_KEY,
          CLOSED_OPPORTUNITY_RELATED_FIELD_TO_KEY
        )
        .orderBy(
          Opportunity.CloseDate,
          QueryFactory.SortOrder.DESCENDING,
          true
        ),
      new ListSpec(
          LIST_OPEN_CASES,
          new CaseSelector(),
          CONDITION_OPEN_CASES,
          OPEN_CASE_LIMIT
        )
        .withFields(OPEN_CASE_FIELD_TO_KEY, OPEN_CASE_RELATED_FIELD_TO_KEY)
        .orderBy(Case.CreatedDate, QueryFactory.SortOrder.ASCENDING, false),
      new ListSpec(
          LIST_RECENTLY_CLOSED_CASES,
          new CaseSelector(),
          CONDITION_RECENTLY_CLOSED_CASES,
          RECENTLY_CLOSED_CASE_LIMIT
        )
        .withFields(CLOSED_CASE_FIELD_TO_KEY, CLOSED_CASE_RELATED_FIELD_TO_KEY)
        .orderBy(Case.ClosedDate, QueryFactory.SortOrder.DESCENDING, true),
      /* All escalations, open or not: lifetime count and days in Red need the full history. */
      new ListSpec(
          LIST_ESCALATIONS,
          new RedAccountSelector(),
          CONDITION_ESCALATIONS,
          ESCALATION_LIMIT
        )
        .withFields(ESCALATION_FIELD_TO_KEY, null)
        .orderBy(
          Red_Account__c.Red_Start_Date__c,
          QueryFactory.SortOrder.DESCENDING,
          true
        ),
      new ListSpec(
          LIST_ENTITLEMENTS,
          new EntitlementSelector(),
          CONDITION_ENTITLEMENTS,
          ENTITLEMENT_LIMIT
        )
        .withFields(ENTITLEMENT_FIELD_TO_KEY, null),
      new ListSpec(
          LIST_ACCOUNT_TEAM,
          new AccountTeamMemberSelector(),
          CONDITION_ACCOUNT_CHILD,
          ACCOUNT_TEAM_LIMIT
        )
        .withFields(
          ACCOUNT_TEAM_FIELD_TO_KEY,
          ACCOUNT_TEAM_RELATED_FIELD_TO_KEY
        ),
      new ListSpec(
          LIST_CONTACTS,
          new ContactSelector(),
          CONDITION_ACCOUNT_CHILD,
          CONTACT_LIMIT
        )
        .withFields(CONTACT_FIELD_TO_KEY, null)
        .orderBy(
          Contact.LastActivityDate,
          QueryFactory.SortOrder.DESCENDING,
          true
        ),
      new ListSpec(
          LIST_TASKS,
          new TaskSelector(),
          CONDITION_TASKS,
          ACTIVITY_LIMIT
        )
        .withFields(TASK_FIELD_TO_KEY, null)
        .orderBy(Task.ActivityDate, QueryFactory.SortOrder.DESCENDING, true),
      new ListSpec(
          LIST_EVENTS,
          new EventSelector(),
          CONDITION_EVENTS,
          ACTIVITY_LIMIT
        )
        .withFields(EVENT_FIELD_TO_KEY, null)
        .orderBy(Event.ActivityDate, QueryFactory.SortOrder.DESCENDING, true),
      new ListSpec(
          LIST_RETENTION_TASKS,
          new RetentionTaskSelector(),
          CONDITION_RETENTION_TASKS,
          RETENTION_TASK_LIMIT
        )
        .withFields(RETENTION_TASK_FIELD_TO_KEY, null)
        .orderBy(
          Retention_Task__c.CreatedDate,
          QueryFactory.SortOrder.DESCENDING,
          true
        ),
      new ListSpec(
          LIST_ORDERS,
          new OrderSelector(),
          CONDITION_ACCOUNT_CHILD,
          ORDER_LIMIT
        )
        .withFields(ORDER_FIELD_TO_KEY, null)
        .orderBy(Order.EffectiveDate, QueryFactory.SortOrder.DESCENDING, true),
      new ListSpec(
          LIST_CONTRACTS,
          new ContractSelector(),
          CONDITION_ACCOUNT_CHILD,
          CONTRACT_LIMIT
        )
        .withFields(CONTRACT_FIELD_TO_KEY, null)
        .orderBy(Contract.EndDate, QueryFactory.SortOrder.DESCENDING, true),
      new ListSpec(
          LIST_ACCOUNT_HISTORY,
          new AccountHistorySelector(),
          CONDITION_ACCOUNT_HISTORY,
          ACCOUNT_HISTORY_LIMIT
        )
        .withFields(ACCOUNT_HISTORY_FIELD_TO_KEY, null)
        .orderBy(
          AccountHistory.CreatedDate,
          QueryFactory.SortOrder.DESCENDING,
          true
        )
    };
  }

  private static Account queryAccount(Id accountId) {
    List<SObject> accounts = stripReadable(
      new AccountSelector()
        .newQueryFactory()
        .withoutSelectorFieldsIncluded()
        .withoutSelectorOrderByIncluded()
        .selectFields(
          new List<Schema.SObjectField>(ACCOUNT_FIELD_TO_KEY.keySet())
        )
        .selectFields(new List<String>(ACCOUNT_RELATED_FIELD_TO_KEY.keySet()))
        .setCondition(CONDITION_ACCOUNT)
        .setQueryBindings(new List<Object>{ accountId })
        .setLimit(1)
        .executeQuery()
    );
    if (accounts.isEmpty()) {
      throw new AccountSummaryException(ACCOUNT_NOT_FOUND_MESSAGE);
    }
    return (Account) accounts[0];
  }

  /* Queries one row past the cap so a full page can be told apart from a truncated one. */
  @TestVisible
  private static QueryFactory buildListQuery(ListSpec spec, Id accountId) {
    QueryFactory query = spec.selector.newQueryFactory()
      .withoutSelectorFieldsIncluded()
      .withoutSelectorOrderByIncluded()
      .selectFields(new List<Schema.SObjectField>(spec.fieldToKey.keySet()))
      .setCondition(spec.condition)
      .setQueryBindings(new List<Object>{ accountId })
      .setLimit(spec.maxRows + 1);
    if (!spec.relatedFieldToKey.isEmpty()) {
      query.selectFields(new List<String>(spec.relatedFieldToKey.keySet()));
    }
    if (spec.orderField != null) {
      query.addOrdering(spec.orderField, spec.direction, spec.isNullsLast);
    }
    return query;
  }

  private static List<SObject> queryList(ListSpec spec, Id accountId) {
    return stripReadable(buildListQuery(spec, accountId).executeQuery());
  }

  @TestVisible
  private static List<Map<String, Object>> mapRows(
    List<SObject> records,
    Map<Schema.SObjectField, String> fieldToKey,
    Map<String, String> relatedFieldToKey
  ) {
    List<Map<String, Object>> rows = new List<Map<String, Object>>();
    for (SObject record : records) {
      rows.add(mapRow(record, fieldToKey, relatedFieldToKey));
    }
    return rows;
  }

  /* A field the user cannot read is sent as null, which the service reports as not recorded. */
  @TestVisible
  private static Map<String, Object> mapRow(
    SObject record,
    Map<Schema.SObjectField, String> fieldToKey,
    Map<String, String> relatedFieldToKey
  ) {
    Map<String, Object> row = new Map<String, Object>();
    for (Schema.SObjectField field : fieldToKey.keySet()) {
      String key = fieldToKey.get(field);
      Object value = readableField(record, String.valueOf(field));
      if (value instanceof Datetime && DATE_ONLY_KEYS.contains(key)) {
        value = ((Datetime) value).date();
      }
      row.put(key, value);
    }
    if (relatedFieldToKey != null) {
      for (String fieldPath : relatedFieldToKey.keySet()) {
        row.put(
          relatedFieldToKey.get(fieldPath),
          readableRelatedField(record, fieldPath)
        );
      }
    }
    return row;
  }

  private static Object readableRelatedField(SObject record, String fieldPath) {
    Object related = readableField(
      record,
      fieldPath.substringBefore(RELATIONSHIP_SEPARATOR)
    );
    return related instanceof SObject
      ? readableField(
          (SObject) related,
          fieldPath.substringAfter(RELATIONSHIP_SEPARATOR)
        )
      : null;
  }

  /*
   * QueryFactory runs in system mode and `with sharing` only covers row access, so fields the
   * user cannot read are stripped. A stripped field is removed rather than nulled, which is why
   * values are read through getPopulatedFieldsAsMap instead of a direct getter.
   */
  private static List<SObject> stripReadable(List<SObject> records) {
    if (records == null || records.isEmpty()) {
      return new List<SObject>();
    }
    return Security.stripInaccessible(AccessType.READABLE, records, false)
      .getRecords();
  }

  private static Object readableField(SObject record, String fieldApiName) {
    return record == null
      ? null
      : record.getPopulatedFieldsAsMap().get(fieldApiName);
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

  @TestVisible
  private static String buildServiceEndpoint(String configuredEndpoint) {
    if (String.isBlank(configuredEndpoint)) {
      return configuredEndpoint;
    }
    String endpoint = configuredEndpoint.trim();
    Integer apiPathIndex = endpoint.toLowerCase().indexOf(API_PATH_MARKER);
    if (apiPathIndex >= 0) {
      endpoint = endpoint.substring(0, apiPathIndex);
    }
    endpoint = endpoint.removeEnd(PATH_SEPARATOR);
    return endpoint + ENDPOINT_PATH;
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
      return errorJson(System.Label.AccountSummaryServerError);
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
        putIfObject(result, bodyMap, RESPONSE_DERIVED_METRICS);
        putIfObject(result, bodyMap, RESPONSE_ENRICHMENT);
        return JSON.serialize(result);
      }
    }

    logServiceFailure(statusCode, body);
    if (statusCode == STATUS_RATE_LIMITED) {
      return errorJson(System.Label.AccountSummaryRateLimitError);
    }
    if (statusCode == STATUS_UNPROCESSABLE) {
      return errorJson(System.Label.AccountSummaryUnavailableError);
    }
    return errorJson(System.Label.AccountSummaryServerError);
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

  private static String errorJson(String message) {
    return JSON.serialize(
      new Map<String, Object>{
        RESULT_SUCCESS => false,
        RESULT_MESSAGE => message
      }
    );
  }

  // ---------------- Configuration ----------------

  /* Technical labels are read in the base language so a translation can never change behavior. */
  @TestVisible
  private static Integer timeoutSeconds() {
    String raw;
    if (
      Test.isRunningTest() &&
      labelSuffixToValue.containsKey(TIMEOUT_LABEL_SUFFIX)
    ) {
      raw = labelSuffixToValue.get(TIMEOUT_LABEL_SUFFIX);
    } else {
      raw = System.Label.get(
        LABEL_NAMESPACE,
        LABEL_PREFIX + TIMEOUT_LABEL_SUFFIX,
        LABEL_BASE_LANGUAGE
      );
    }
    if (String.isBlank(raw) || !Pattern.matches(DIGITS_PATTERN, raw.trim())) {
      return DEFAULT_TIMEOUT_SECONDS;
    }
    Integer value = Integer.valueOf(raw.trim());
    return value > 0 &&
      value <= MAX_TIMEOUT_SECONDS
      ? value
      : DEFAULT_TIMEOUT_SECONDS;
  }

  // ---------------- Types ----------------

  @TestVisible
  private class ListSpec {
    public String key;
    public SObjectSelector selector;
    public String condition;
    public Integer maxRows;
    public Map<Schema.SObjectField, String> fieldToKey = new Map<Schema.SObjectField, String>();
    public Map<String, String> relatedFieldToKey = new Map<String, String>();
    public Schema.SObjectField orderField;
    public QueryFactory.SortOrder direction;
    public Boolean isNullsLast;

    public ListSpec(
      String key,
      SObjectSelector selector,
      String condition,
      Integer maxRows
    ) {
      this.key = key;
      this.selector = selector;
      this.condition = condition;
      this.maxRows = maxRows;
    }

    public ListSpec withFields(
      Map<Schema.SObjectField, String> fieldToKey,
      Map<String, String> relatedFieldToKey
    ) {
      this.fieldToKey = fieldToKey;
      if (relatedFieldToKey != null) {
        this.relatedFieldToKey = relatedFieldToKey;
      }
      return this;
    }

    public ListSpec orderBy(
      Schema.SObjectField orderField,
      QueryFactory.SortOrder direction,
      Boolean isNullsLast
    ) {
      this.orderField = orderField;
      this.direction = direction;
      this.isNullsLast = isNullsLast;
      return this;
    }
  }

  @TestVisible
  private class AccountSummaryException extends Exception {
  }
}
