public with sharing class GCPCalloutForOpportunitySummary {
  private static final String AUTH_CONFIG_NAME = 'opportunitySummary';
  private static final String ENDPOINT_PATH = '/api/v1/opportunity_summary';
  private static final String ENRICHMENT_SWITCH_FIELD = 'Enable_Opportunity_Summary_Enrichment__c';
  private static final String ENRICHMENT_REQUEST_FIELD = 'enableOpportunitySummaryEnrichment';
  private static final String CALL_TRANSCRIPTS_REQUEST_FIELD = 'enableOpportunitySummaryCallTranscripts';
  private static final Map<String, Schema.SObjectType> REFERENCE_OBJECT_TYPES = new Map<String, Schema.SObjectType>{
    'Case' => Case.SObjectType,
    'Task' => Task.SObjectType,
    'Event' => Event.SObjectType,
    'Account' => Account.SObjectType,
    'Contact' => Contact.SObjectType,
    'Opportunity' => Opportunity.SObjectType,
    'User' => User.SObjectType,
    'Product2' => Product2.SObjectType
  };
  private static final Integer MIN_NAMED_LABEL_LENGTH = 3;
  // Subjects such as "Call" or "Meeting" are too generic to link reliably.
  private static final Integer MIN_SUBJECT_LABEL_LENGTH = 10;
  private static final Set<String> UNRESOLVED_ACCOUNT_NAMES = new Set<String>{
    'NEW COMPANY',
    'FIRST NAME LAST NAME',
    '[NONE]',
    'NONE',
    'RINGCENTRAL / DINS'
  };
  private static final Set<String> GENERIC_EMAIL_DOMAINS = new Set<String>{
    'aol.com',
    'gmail.com',
    'hotmail.com',
    'icloud.com',
    'live.com',
    'mac.com',
    'me.com',
    'msn.com',
    'outlook.com',
    'privaterelay.appleid.com',
    'proton.me',
    'protonmail.com',
    'yahoo.com'
  };

  // Cases closed within this window are sent to the model for trend context.
  private static Integer closedCaseMonths {
    get {
      return configuredInteger('ClosedCaseMonths', 6, 24);
    }
  }

  // Caps keep heap and callout body size in check on busy accounts.
  private static Integer activityLookbackDays {
    get {
      return configuredInteger('ActivityDays', 180, 365);
    }
  }
  private static Integer maxActivities {
    get {
      return configuredInteger('MaxActivities', 50, 50);
    }
  }
  private static Integer maxHistoryRows {
    get {
      return configuredInteger('MaxHistoryRows', 50, 50);
    }
  }
  private static Integer maxOpenCases {
    get {
      return configuredInteger('MaxOpenCases', 50, 50);
    }
  }
  private static Integer maxClosedCases {
    get {
      return configuredInteger('MaxClosedCases', 50, 50);
    }
  }
  private static Integer maxRelatedOpps {
    get {
      return configuredInteger('MaxRelatedOpps', 25, 25);
    }
  }
  private static Integer maxLineItems {
    get {
      return configuredInteger('MaxLineItems', 50, 50);
    }
  }
  private static Integer maxStakeholders {
    get {
      return configuredInteger('MaxStakeholders', 25, 25);
    }
  }
  private static final Integer MAX_DESCRIPTION_LENGTH = 1000;
  private static final Integer MAX_LOSS_FIELD_LENGTH = 300;
  private static final Integer DEFAULT_RECENT_EVIDENCE_DAYS = 90;
  private static final Integer MAX_RECENT_EVIDENCE_DAYS = 365;
  private static Integer maxConversationItems {
    get {
      return configuredInteger('MaxConversationItems', 10, 10);
    }
  }
  private static final Integer MAX_CONVERSATION_TEXT_LENGTH = 4000;
  private static final Integer MAX_ACTIVITY_RELATIONS = 250;
  private static final Integer MAX_REQUEST_BYTES = 2 * 1024 * 1024;

  @TestVisible
  private static Integer requestSizeLimitBytes = MAX_REQUEST_BYTES;

  @TestVisible
  private static ActivityParticipantProvider activityParticipantProvider = new ActivityParticipantProvider();

  // Technical failures (callout, config, query, parsing) are logged for support and
  // reported to the user with this message only — endpoints, status codes and stack
  // details must never reach the UI.
  private static String userFacingError {
    get {
      return System.Label.OpportunitySummaryServerError;
    }
  }

  @AuraEnabled(cacheable=false)
  public static String makeGCPCallout(String userId, String recordId) {
    try {
      if (String.isBlank(recordId)) {
        System.debug(
          LoggingLevel.ERROR,
          'Opportunity Summary called without a record Id.'
        );
        return errorJson(userFacingError);
      }

      String username = getUsername(userId);

      GCPAuthUtil.GCPConfig config = GCPAuthUtil.loadConfig(AUTH_CONFIG_NAME);
      String jwt = GCPAuthUtil.createSignedJWT(config);
      String idToken = GCPAuthUtil.exchangeJWTForIdentityToken(
        jwt,
        config.identityTokenUrl
      );

      return callCloudRun(
        username,
        (Id) recordId,
        idToken,
        config.cloudRunEndpoint
      );
    } catch (CalloutException ce) {
      return logAndFail('Callout error', ce);
    } catch (QueryException qe) {
      return logAndFail('Database query error', qe);
    } catch (GCPAuthUtil.GCPCalloutException ae) {
      return logAndFail('Configuration error', ae);
    } catch (Exception e) {
      return logAndFail('Unexpected error', e);
    }
  }

  private static String getUsername(String userId) {
    if (String.isBlank(userId)) {
      return null;
    }
    List<User> users = (List<User>) new UserSelector()
      .selectUserById(new List<Object>{ (Id) userId })
      .setLimit(1)
      .executeQuery();
    return users.isEmpty() ? null : users[0].Username;
  }

  @TestVisible
  private static String callCloudRun(
    String username,
    Id recordId,
    String idToken,
    String endpoint
  ) {
    Map<String, Object> payload = buildPayload(username, recordId);
    System.debug(
      'Heap after payload built (queries):: ' +
        Limits.getHeapSize() +
        ' / ' +
        Limits.getLimitHeapSize()
    );

    String requestBody = serializePayloadWithinLimit(payload);

    HttpRequest req = new HttpRequest();
    req.setEndpoint(buildServiceEndpoint(endpoint));
    req.setMethod('POST');
    req.setHeader('Content-Type', 'application/json');
    req.setHeader('Authorization', 'Bearer ' + idToken);
    req.setBody(requestBody);
    req.setTimeout(configuredInteger('TimeoutSeconds', 120, 120) * 1000);

    System.debug(
      'Opportunity Summary request bytes:: ' + Blob.valueOf(requestBody).size()
    );
    System.debug(
      'Opportunity Summary request body:: ' + Json.serialize(requestBody)
    );

    Http h = new Http();
    HttpResponse res = h.send(req);
    System.debug('Opportunity Summary response status::' + res.getStatusCode());
    System.debug(
      'Opportunity Summary response body::' + json.serialize(res.getBody())
    );

    if (res.getStatusCode() != 200) {
      throw new CalloutException(
        'Cloud Run call failed. Status: ' + res.getStatusCode()
      );
    }

    String responseBody = res.getBody();
    if (String.isBlank(responseBody)) {
      return errorJson(userFacingError);
    }

    String result = buildResult(
      JSON.deserializeUntyped(responseBody),
      referenceableRecordIds(payload),
      namedRecordReferences(payload)
    );
    System.debug(
      'Heap after summary generated:: ' +
        Limits.getHeapSize() +
        ' / ' +
        Limits.getLimitHeapSize()
    );
    return result;
  }

  // ---------------- Payload assembly ----------------

  @TestVisible
  private static Map<String, Object> buildPayload(
    String username,
    Id recordId
  ) {
    Opportunity opp = getOpportunity(recordId);
    Boolean enrichmentEnabled = effectiveEnrichmentEnabled(
      isOpportunitySummaryEnrichmentEnabled(),
      opp
    );
    Integer recentEvidenceDays = getRecentEvidenceLookbackDays();
    // AccountId may have been stripped for FLS; fall back to null (no related account context).
    Id accountId = (Id) readableField(opp, 'AccountId');

    Map<String, Object> caseBuckets = getCases(accountId);
    ActivityData activityData = getActivityData(
      recordId,
      enrichmentEnabled,
      recentEvidenceDays
    );
    CollectionData stakeholderData = getStakeholderData(recordId);
    CollectionData lineItemData = getLineItemData(recordId, enrichmentEnabled);

    Map<String, Object> payload = new Map<String, Object>{
      'username' => username,
      'recordId' => recordId,
      'opportunity' => buildOpportunityMap(opp, enrichmentEnabled),
      'stageHistory' => getStageHistory(recordId),
      'fieldHistory' => getFieldHistory(recordId),
      'activities' => new Map<String, Object>{
        'tasks' => activityData.tasks,
        'events' => activityData.events
      },
      'stakeholders' => stakeholderData.rows,
      'cases' => caseBuckets,
      'lineItems' => lineItemData.rows,
      'relatedOpportunities' => getRelatedOpportunities(accountId, recordId)
    };
    addEnrichmentRequestControl(payload, enrichmentEnabled);
    addCallTranscriptsRequestControl(
      payload,
      isOpportunitySummaryCallTranscriptsEnabled()
    );
    addViewerContext(payload);
    // Conversation notes are CRM evidence, not public research, so they are sent
    // whether or not the enrichment toggle is on.
    payload.put(
      'conversationEvidence',
      new Map<String, Object>{ 'items' => activityData.conversations }
    );

    if (enrichmentEnabled) {
      payload.put(
        'dataCoverage',
        buildDataCoverage(activityData, stakeholderData, lineItemData)
      );
    }

    return payload;
  }

  @TestVisible
  private static void addEnrichmentRequestControl(
    Map<String, Object> payload,
    Boolean enrichmentEnabled
  ) {
    payload.put(ENRICHMENT_REQUEST_FIELD, enrichmentEnabled == true);
  }

  // Always a JSON boolean, never null: GCP treats any non-boolean as OFF.
  @TestVisible
  private static void addCallTranscriptsRequestControl(
    Map<String, Object> payload,
    Boolean callTranscriptsEnabled
  ) {
    payload.put(CALL_TRANSCRIPTS_REQUEST_FIELD, callTranscriptsEnabled == true);
  }

  // The callout runs as the viewing user, so UserInfo describes the viewer rather than the
  // opportunity owner or the integration user. GCP formats summary dates with these values.
  @TestVisible
  private static void addViewerContext(Map<String, Object> payload) {
    payload.put('viewerTimeZone', UserInfo.getTimeZone().getID());
    payload.put('viewerLocale', UserInfo.getLocale());
  }

  private static Opportunity getOpportunity(Id recordId) {
    List<Opportunity> opps = (List<Opportunity>) new OpportunitySelector()
      .selectOpportunities()
      .withoutSelectorFieldsIncluded()
      .selectFields(
        new List<String>{
          'Id',
          'Name',
          'Amount',
          'CurrencyIsoCode',
          'Type',
          'LeadSource',
          'StageName',
          'IsClosed',
          'IsWon',
          'Probability',
          'ForecastCategory',
          'CloseDate',
          'CreatedDate',
          'LastModifiedDate',
          'NextStep',
          'Description',
          'Intended_Product__c',
          'Order_Type__c',
          'Downgrade_Reason_Opp__c',
          'Primary_Loss_Reason__c',
          'Primary_Competitor__c',
          'Website__c',
          'OwnerId',
          'Owner.Name',
          'AccountId',
          'Account.Name',
          'Account.Industry',
          'Account.Sector__c',
          'Account.Website',
          'Account.BillingCity',
          'Account.BillingState',
          'Account.BillingCountry'
        }
      )
      .setCondition('Id = :bind0')
      .setLimit(1)
      .setQueryBindings(new List<Object>{ recordId })
      .executeQuery();
    if (opps.isEmpty()) {
      throw new QueryException('Opportunity not found for Id ' + recordId);
    }
    // FLS: QueryFactory runs Database.query (system mode), and `with sharing` only enforces
    // row-level sharing — strip fields the running user cannot read before the GCP payload.
    return (Opportunity) stripReadable(opps)[0];
  }

  @TestVisible
  private static Map<String, Object> buildOpportunityMap(
    Opportunity opp,
    Boolean enrichmentEnabled
  ) {
    SObject owner = readableRelated(opp, 'Owner');
    SObject account = readableRelated(opp, 'Account');
    Map<String, Object> opportunityMap = new Map<String, Object>{
      'id' => readableField(opp, 'Id'),
      'name' => readableField(opp, 'Name'),
      'amount' => readableField(opp, 'Amount'),
      'currencyIsoCode' => readableField(opp, 'CurrencyIsoCode'),
      'type' => readableField(opp, 'Type'),
      'leadSource' => readableField(opp, 'LeadSource'),
      'stageName' => readableField(opp, 'StageName'),
      'probability' => readableField(opp, 'Probability'),
      'forecastCategory' => readableField(opp, 'ForecastCategory'),
      'closeDate' => readableField(opp, 'CloseDate'),
      'createdDate' => readableField(opp, 'CreatedDate'),
      'lastModifiedDate' => readableField(opp, 'LastModifiedDate'),
      'nextStep' => readableField(opp, 'NextStep'),
      'description' => truncateText((String) readableField(opp, 'Description')),
      'ownerId' => readableField(opp, 'OwnerId'),
      'ownerName' => readableField(owner, 'Name'),
      'accountId' => readableField(opp, 'AccountId'),
      'accountIndustry' => readableField(account, 'Industry'),
      'accountCity' => readableField(account, 'BillingCity'),
      'accountCountry' => readableField(account, 'BillingCountry')
    };
    putIfPresent(opportunityMap, 'accountName', resolvedAccountName(opp));
    // GCP rejects non-boolean values, so omit the flags when they are unreadable.
    putIfPresent(opportunityMap, 'isClosed', readableField(opp, 'IsClosed'));
    putIfPresent(opportunityMap, 'isWon', readableField(opp, 'IsWon'));
    // Order_Type__c is the acquisition/upsell/downsell picklist; sent unchanged.
    // Type (New/Existing/Renewal) is not a deal motion and is already sent as `type`.
    putIfPresent(
      opportunityMap,
      'dealMotion',
      normalizedText(readableField(opp, 'Order_Type__c'))
    );
    // Loss context for closed deals; GCP accepts at most 300 characters per key.
    putIfPresent(
      opportunityMap,
      'lossReason',
      lossFieldText(readableField(opp, 'Downgrade_Reason_Opp__c'))
    );
    putIfPresent(
      opportunityMap,
      'lossReasonDetail',
      lossFieldText(readableField(opp, 'Primary_Loss_Reason__c'))
    );
    putIfPresent(
      opportunityMap,
      'lostToCompetitor',
      lossFieldText(readableField(opp, 'Primary_Competitor__c'))
    );
    // Sector exists only on Account (text, not a picklist).
    putIfPresent(
      opportunityMap,
      'sector',
      normalizedText(readableField(account, 'Sector__c'))
    );
    putIfPresent(
      opportunityMap,
      'intendedProduct',
      normalizedText(readableField(opp, 'Intended_Product__c'))
    );

    if (enrichmentEnabled) {
      putIfPresent(
        opportunityMap,
        'accountWebsite',
        resolvedAccountWebsite(opp)
      );
      putIfPresent(
        opportunityMap,
        'accountState',
        readableField(account, 'BillingState')
      );
    }
    return opportunityMap;
  }

  @TestVisible
  private static Boolean effectiveEnrichmentEnabled(
    Boolean configuredValue,
    Opportunity opp
  ) {
    return configuredValue == true && hasUsableCompanyIdentity(opp);
  }

  private static Boolean hasUsableCompanyIdentity(Opportunity opp) {
    String accountName = resolvedAccountName(opp);
    if (String.isBlank(accountName)) {
      return false;
    }
    return !isGenericEmailDomainName(accountName) ||
      String.isNotBlank(resolvedAccountWebsite(opp));
  }

  private static String resolvedAccountName(Opportunity opp) {
    SObject account = readableRelated(opp, 'Account');
    String accountName = normalizedText(readableField(account, 'Name'));
    return String.isBlank(accountName) ||
      configuredList('UnresolvedNames', UNRESOLVED_ACCOUNT_NAMES, false)
        .contains(accountName.toLowerCase())
      ? null
      : accountName;
  }

  private static Boolean isGenericEmailDomainName(String accountName) {
    String normalized = accountName == null
      ? null
      : accountName.trim().toLowerCase();
    if (String.isBlank(normalized)) {
      return false;
    }
    for (
      String domain : configuredList(
        'GenericEmailDomains',
        GENERIC_EMAIL_DOMAINS,
        true
      )
    ) {
      if (
        normalized == domain ||
        normalized == domain.substringBefore('.') ||
        normalized.endsWith('@' + domain)
      ) {
        return true;
      }
    }
    return normalized.contains('apple private relay');
  }

  private static String resolvedAccountWebsite(Opportunity opp) {
    SObject account = readableRelated(opp, 'Account');
    String accountWebsite = normalizedText(readableField(account, 'Website'));
    if (String.isNotBlank(accountWebsite)) {
      return sanitizedPublicWebsite(accountWebsite);
    }
    return sanitizedPublicWebsite(
      normalizedText(readableField(opp, 'Website__c'))
    );
  }

  @TestVisible
  private static String sanitizedPublicWebsite(String rawWebsite) {
    String candidate = normalizedText(rawWebsite);
    if (String.isBlank(candidate)) {
      return null;
    }
    try {
      Url parsed = new Url(candidate);
      String protocol = parsed.getProtocol()?.toLowerCase();
      String authority = parsed.getAuthority();
      String host = parsed.getHost()?.toLowerCase();
      if (
        (protocol != 'http' &&
        protocol != 'https') ||
        String.isBlank(authority) ||
        authority.contains('@') ||
        isInternalWebsiteHost(host)
      ) {
        return null;
      }
      String path = parsed.getPath();
      return protocol +
        '://' +
        authority.toLowerCase() +
        (String.isBlank(path) ? '' : path);
    } catch (Exception ignored) {
      return null;
    }
  }

  private static Boolean isInternalWebsiteHost(String host) {
    return String.isBlank(host) ||
      !host.contains('.') ||
      host == 'localhost' ||
      host.endsWith('.internal') ||
      host.endsWith('.invalid') ||
      host.endsWith('.local') ||
      host.endsWith('.localhost') ||
      host.endsWith('.test') ||
      Pattern.matches('^\\d{1,3}(\\.\\d{1,3}){3}$', host);
  }

  private static String lossFieldText(Object rawValue) {
    String text = normalizedText(rawValue);
    return text == null ? null : text.left(MAX_LOSS_FIELD_LENGTH);
  }

  private static String normalizedText(Object rawValue) {
    if (!(rawValue instanceof String)) {
      return null;
    }
    String normalized = ((String) rawValue).trim();
    return String.isBlank(normalized) ? null : normalized;
  }

  private static List<Map<String, Object>> getStageHistory(Id recordId) {
    List<Map<String, Object>> rows = new List<Map<String, Object>>();
    // Selector returns newest first; reverse so the payload stays chronological.
    List<SObject> histories = stripReadable(
      new OpportunityHistorySelector()
        .selectStageHistoryByOpportunityId(recordId)
        .setLimit(maxHistoryRows)
        .executeQuery()
    );
    for (Integer i = histories.size() - 1; i >= 0; i--) {
      OpportunityHistory h = (OpportunityHistory) histories[i];
      rows.add(
        new Map<String, Object>{
          'stageName' => readableField(h, 'StageName'),
          'amount' => readableField(h, 'Amount'),
          'probability' => readableField(h, 'Probability'),
          'closeDate' => readableField(h, 'CloseDate'),
          'forecastCategory' => readableField(h, 'ForecastCategory'),
          'createdDate' => readableField(h, 'CreatedDate')
        }
      );
    }
    return rows;
  }

  private static List<Map<String, Object>> getFieldHistory(Id recordId) {
    List<Map<String, Object>> rows = new List<Map<String, Object>>();
    Set<String> trackedFields = new Set<String>{
      'CloseDate',
      'Amount',
      'Probability'
    };
    List<SObject> histories = stripReadable(
      new OpportunityFieldHistorySelector()
        .selectFieldHistoryByOpportunityIdAndFields(recordId, trackedFields)
        .setLimit(maxHistoryRows)
        .executeQuery()
    );
    for (Integer i = histories.size() - 1; i >= 0; i--) {
      OpportunityFieldHistory fh = (OpportunityFieldHistory) histories[i];
      rows.add(
        new Map<String, Object>{
          'field' => readableField(fh, 'Field'),
          'oldValue' => readableField(fh, 'OldValue'),
          'newValue' => readableField(fh, 'NewValue'),
          'createdDate' => readableField(fh, 'CreatedDate')
        }
      );
    }
    return rows;
  }

  private static ActivityData getActivityData(
    Id recordId,
    Boolean enrichmentEnabled,
    Integer recentEvidenceDays
  ) {
    Datetime windowEnd = Datetime.now();
    Datetime activitySince = windowEnd.addDays(-activityLookbackDays);
    List<SObject> tasks = stripReadable(
      buildTaskQuery(recordId, activitySince).executeQuery()
    );
    Boolean tasksTruncated = trimOverflow(tasks, maxActivities);
    Map<Id, Datetime> taskCompletionTimesById = loadTaskCompletionTimes(tasks);
    Boolean taskCompletionTimesLoaded = taskCompletionTimesById != null;
    if (!taskCompletionTimesLoaded) {
      taskCompletionTimesById = new Map<Id, Datetime>();
    }

    // QueryFactory cannot validate Owner.Name on Event — Owner is polymorphic
    // (User | Calendar) and Calendar has no Name field. Resolve User names separately.
    List<SObject> events = stripReadable(
      new EventSelector()
        .selectEventsByWhatIds(new Set<Id>{ recordId })
        .selectFields(
          new List<String>{
            'Id',
            'WhoId',
            'Subject',
            'StartDateTime',
            'EndDateTime',
            'CreatedDate',
            'OwnerId',
            'Description'
          }
        )
        .withoutSelectorOrderByIncluded()
        .setCondition('WhatId IN :bind0 AND StartDateTime >= :bind1')
        .setQueryBindings(
          new List<Object>{ new Set<Id>{ recordId }, activitySince }
        )
        .addOrdering(Event.StartDateTime, QueryFactory.SortOrder.DESCENDING)
        .setLimit(maxActivities + 1)
        .executeQuery()
    );
    Boolean eventsTruncated = trimOverflow(events, maxActivities);

    Set<Id> ownerIds = new Set<Id>();
    for (SObject sobj : events) {
      Id ownerId = (Id) readableField(sobj, 'OwnerId');
      if (ownerId != null && String.valueOf(ownerId).startsWith('005')) {
        ownerIds.add(ownerId);
      }
    }

    Map<Id, String> ownerNamesById = new Map<Id, String>();
    if (!ownerIds.isEmpty()) {
      for (
        SObject sobj : stripReadable(
          new UserSelector().selectUsersByIds(ownerIds).executeQuery()
        )
      ) {
        Id userId = (Id) readableField(sobj, 'Id');
        String userName = (String) readableField(sobj, 'Name');
        if (userId != null) {
          ownerNamesById.put(userId, userName);
        }
      }
    }

    ActivityData data = assembleActivityData(
      tasks,
      events,
      ownerNamesById,
      taskCompletionTimesById,
      enrichmentEnabled,
      activitySince,
      windowEnd,
      recentEvidenceDays,
      tasksTruncated,
      eventsTruncated
    );
    if (!taskCompletionTimesLoaded) {
      data.conversationReasonCode = 'task_completion_time_retrieval_error';
      if (data.conversations.isEmpty()) {
        data.conversationStatus = 'error';
      }
    }
    data.tasksAccessible = Task.SObjectType.getDescribe().isAccessible();
    data.eventsAccessible = Event.SObjectType.getDescribe().isAccessible();
    return data;
  }

  @TestVisible
  private static QueryFactory buildTaskQuery(
    Id recordId,
    Datetime activitySince
  ) {
    // QueryFactory validates fields through SObjectDescribeHelper, which is compiled
    // at API 41. CompletedDateTime was added after that version, so selecting it here
    // raises InvalidFieldException even though the current Task API supports it.
    return new TaskSelector()
      .selectTasksByWhatIdForOpportunitySummary(recordId)
      .selectFields(
        new List<String>{ 'Id', 'WhoId', 'IsClosed', 'TaskSubtype' }
      )
      .setCondition('WhatId = :bind0 AND CreatedDate >= :bind1')
      .setQueryBindings(new List<Object>{ recordId, activitySince })
      .setLimit(maxActivities + 1);
  }

  @TestVisible
  private static Map<Id, Datetime> loadTaskCompletionTimes(
    List<SObject> tasks
  ) {
    Set<Id> taskIds = new Set<Id>();
    for (SObject taskRecord : tasks) {
      Id taskId = (Id) readableField(taskRecord, 'Id');
      if (taskId != null) {
        taskIds.add(taskId);
      }
    }
    if (taskIds.isEmpty()) {
      return new Map<Id, Datetime>();
    }

    try {
      // This class is compiled at API 64, where the exact Task completion timestamp
      // is available. Keep this query outside the legacy QueryFactory validation path.
      List<SObject> completionRows = stripReadable(
        [
          SELECT Id, CompletedDateTime
          FROM Task
          WHERE Id IN :taskIds
        ]
      );
      Map<Id, Datetime> completionTimesByTaskId = new Map<Id, Datetime>();
      for (SObject completionRow : completionRows) {
        completionTimesByTaskId.put(
          (Id) readableField(completionRow, 'Id'),
          (Datetime) readableField(completionRow, 'CompletedDateTime')
        );
      }
      return completionTimesByTaskId;
    } catch (QueryException ignored) {
      // Conversation evidence is optional; preserve the established activity payload.
      return null;
    }
  }

  @TestVisible
  private static ActivityData assembleActivityData(
    List<SObject> tasks,
    List<SObject> events,
    Map<Id, String> eventOwnerNamesById,
    Boolean enrichmentEnabled,
    Datetime activityWindowStart,
    Datetime windowEnd,
    Integer recentEvidenceDays,
    Boolean tasksTruncated,
    Boolean eventsTruncated
  ) {
    return assembleActivityData(
      tasks,
      events,
      eventOwnerNamesById,
      new Map<Id, Datetime>(),
      enrichmentEnabled,
      activityWindowStart,
      windowEnd,
      recentEvidenceDays,
      tasksTruncated,
      eventsTruncated
    );
  }

  private static ActivityData assembleActivityData(
    List<SObject> tasks,
    List<SObject> events,
    Map<Id, String> eventOwnerNamesById,
    Map<Id, Datetime> taskCompletionTimesById,
    Boolean enrichmentEnabled,
    Datetime activityWindowStart,
    Datetime windowEnd,
    Integer recentEvidenceDays,
    Boolean tasksTruncated,
    Boolean eventsTruncated
  ) {
    ActivityData data = new ActivityData();
    data.activityWindowStart = activityWindowStart;
    data.activityWindowEnd = windowEnd;
    data.conversationWindowStart = windowEnd.addDays(-recentEvidenceDays);
    data.tasksTruncated = tasksTruncated;
    data.eventsTruncated = eventsTruncated;

    // Participants decide which activities qualify as conversation evidence, so
    // they load on every request; they are added to activity rows only with enrichment.
    ActivityParticipantResult participantResult = new ActivityParticipantResult();
    try {
      participantResult = activityParticipantProvider.load(tasks, events);
    } catch (Exception ignored) {
      participantResult.status = 'error';
      participantResult.reasonCode = 'participant_retrieval_error';
    }
    data.participantStatus = participantResult.status;
    data.participantReasonCode = participantResult.reasonCode;
    data.participantRelationsTruncated = participantResult.isTruncated;

    for (SObject sobj : tasks) {
      Task taskRecord = (Task) sobj;
      SObject owner = readableRelated(taskRecord, 'Owner');
      Map<String, Object> row = new Map<String, Object>{
        'id' => readableField(taskRecord, 'Id'),
        'subject' => readableField(taskRecord, 'Subject'),
        'status' => readableField(taskRecord, 'Status'),
        'type' => readableField(taskRecord, 'Type'),
        'activityDate' => readableField(taskRecord, 'ActivityDate'),
        'createdDate' => readableField(taskRecord, 'CreatedDate'),
        'ownerName' => readableField(owner, 'Name'),
        'description' => truncateText(
          (String) readableField(taskRecord, 'Description')
        )
      };
      // TaskSubtype = 'Call' is how calls are logged; Type is usually blank.
      putIfPresent(
        row,
        'taskSubtype',
        normalizedText(readableField(taskRecord, 'TaskSubtype'))
      );
      if (enrichmentEnabled) {
        Id taskId = (Id) readableField(taskRecord, 'Id');
        row.put('sourceRecordId', taskId);
        row.put('participants', participantsFor(participantResult, taskId));
      }
      data.tasks.add(row);
    }

    for (SObject sobj : events) {
      Event eventRecord = (Event) sobj;
      Id ownerId = (Id) readableField(eventRecord, 'OwnerId');
      Map<String, Object> row = new Map<String, Object>{
        'id' => readableField(eventRecord, 'Id'),
        'subject' => readableField(eventRecord, 'Subject'),
        'startDateTime' => readableField(eventRecord, 'StartDateTime'),
        'endDateTime' => readableField(eventRecord, 'EndDateTime'),
        'createdDate' => readableField(eventRecord, 'CreatedDate'),
        'ownerName' => eventOwnerNamesById.get(ownerId),
        'description' => truncateText(
          (String) readableField(eventRecord, 'Description')
        )
      };
      if (enrichmentEnabled) {
        Id eventId = (Id) readableField(eventRecord, 'Id');
        row.put('sourceRecordId', eventId);
        row.put('participants', participantsFor(participantResult, eventId));
      }
      data.events.add(row);
    }

    if (participantResult.status != 'error') {
      ConversationResult conversationResult = buildConversationEvidence(
        tasks,
        events,
        participantResult.participantsByActivityId,
        taskCompletionTimesById,
        data.conversationWindowStart,
        windowEnd
      );
      data.conversations = conversationResult.items;
      data.conversationsTruncated =
        conversationResult.isTruncated || participantResult.isTruncated;
      data.conversationReasonCode = participantResult.isTruncated
        ? 'participant_relation_limit'
        : conversationResult.reasonCode;
    } else {
      data.conversationStatus = 'error';
      data.conversationReasonCode = 'participant_retrieval_error';
    }

    return data;
  }

  private static CollectionData getStakeholderData(Id recordId) {
    CollectionData data = new CollectionData();
    List<SObject> roles = stripReadable(
      new OpportunityContactRoleSelector()
        .selectOpportunityContactRolesByOppId(new List<Object>{ recordId })
        .selectFields(
          new List<String>{
            'Contact.Name',
            'Contact.Title',
            'Contact.Email',
            'Contact.Phone',
            'Contact.LastActivityDate'
          }
        )
        .addOrdering(
          OpportunityContactRole.IsPrimary,
          QueryFactory.SortOrder.DESCENDING
        )
        .setLimit(maxStakeholders + 1)
        .executeQuery()
    );
    data.isTruncated = trimOverflow(roles, maxStakeholders);
    for (SObject sobj : roles) {
      OpportunityContactRole r = (OpportunityContactRole) sobj;
      SObject contact = readableRelated(r, 'Contact');
      data.rows.add(
        new Map<String, Object>{
          'role' => readableField(r, 'Role'),
          'isPrimary' => readableField(r, 'IsPrimary'),
          'contactId' => readableField(r, 'ContactId'),
          'name' => readableField(contact, 'Name'),
          'title' => readableField(contact, 'Title'),
          'email' => readableField(contact, 'Email'),
          'phone' => readableField(contact, 'Phone'),
          'lastActivityDate' => readableField(contact, 'LastActivityDate')
        }
      );
    }
    data.isAccessible = OpportunityContactRole.SObjectType.getDescribe()
      .isAccessible();
    return data;
  }

  private static Map<String, Object> getCases(Id accountId) {
    List<Map<String, Object>> openCases = new List<Map<String, Object>>();
    List<Map<String, Object>> recentlyClosed = new List<Map<String, Object>>();

    if (accountId == null) {
      return new Map<String, Object>{
        'open' => openCases,
        'recentlyClosed' => recentlyClosed
      };
    }

    Date closedSince = Date.today().addMonths(-closedCaseMonths);
    List<SObject> cases = stripReadable(
      new CaseSelector()
        .selectCases()
        .selectFields(
          new List<String>{
            'Id',
            'CaseNumber',
            'Subject',
            'Status',
            'Priority',
            'IsClosed',
            'IsEscalated',
            'CreatedDate',
            'ClosedDate',
            'Owner.Name',
            'Description'
          }
        )
        .setCondition(
          'AccountId = :bind0 AND (IsClosed = false OR ClosedDate >= :bind1)'
        )
        .addOrdering(Case.CreatedDate, QueryFactory.SortOrder.DESCENDING)
        .setQueryBindings(new List<Object>{ accountId, closedSince })
        .setLimit(maxOpenCases + maxClosedCases)
        .executeQuery()
    );

    for (SObject sobj : cases) {
      Case c = (Case) sobj;
      SObject owner = readableRelated(c, 'Owner');
      Map<String, Object> row = new Map<String, Object>{
        'id' => readableField(c, 'Id'),
        'caseNumber' => readableField(c, 'CaseNumber'),
        'subject' => readableField(c, 'Subject'),
        'status' => readableField(c, 'Status'),
        'priority' => readableField(c, 'Priority'),
        'isEscalated' => readableField(c, 'IsEscalated'),
        'createdDate' => readableField(c, 'CreatedDate'),
        'closedDate' => readableField(c, 'ClosedDate'),
        'ownerName' => readableField(owner, 'Name'),
        'description' => truncateText((String) readableField(c, 'Description'))
      };
      // IsClosed may be stripped; treat missing as open so we do not drop the row.
      Boolean isClosed = (Boolean) readableField(c, 'IsClosed');
      if (isClosed == true) {
        if (recentlyClosed.size() < maxClosedCases) {
          recentlyClosed.add(row);
        }
      } else if (openCases.size() < maxOpenCases) {
        openCases.add(row);
      }
    }

    return new Map<String, Object>{
      'open' => openCases,
      'recentlyClosed' => recentlyClosed
    };
  }

  private static CollectionData getLineItemData(
    Id recordId,
    Boolean enrichmentEnabled
  ) {
    CollectionData data = new CollectionData();
    List<SObject> lineItems = stripReadable(
      new OpportunityLineItemSelector()
        .selectLineItemsByOpportunityIdForSummary(recordId)
        .selectFields(
          new List<String>{
            'Product2.Family',
            'Product2.Sub_Category__c',
            'Product2.Subgroup__c',
            'Product2.Group__c',
            'Product2.Description',
            'Product2.Product_Description__c',
            'Product2.CategoryName__c',
            'Product2.LicenseGroup__c',
            'Product2.ServiceCategory__c'
          }
        )
        .setLimit(maxLineItems + 1)
        .executeQuery()
    );
    data.isTruncated = trimOverflow(lineItems, maxLineItems);
    data.rows = buildLineItemRows(lineItems, enrichmentEnabled);
    data.isAccessible = OpportunityLineItem.SObjectType.getDescribe()
      .isAccessible();
    return data;
  }

  @TestVisible
  private static List<Map<String, Object>> buildLineItemRows(
    List<SObject> lineItems,
    Boolean enrichmentEnabled
  ) {
    List<Map<String, Object>> rows = new List<Map<String, Object>>();
    for (SObject sobj : lineItems) {
      OpportunityLineItem li = (OpportunityLineItem) sobj;
      SObject product = readableRelated(li, 'Product2');
      Map<String, Object> row = new Map<String, Object>{
        'name' => readableField(li, 'Name'),
        'productId' => readableField(li, 'Product2Id'),
        'productName' => readableField(product, 'Name'),
        'quantity' => readableField(li, 'Quantity'),
        'unitPrice' => readableField(li, 'UnitPrice'),
        'totalPrice' => readableField(li, 'TotalPrice'),
        'discount' => readableField(li, 'Discount'),
        'serviceDate' => readableField(li, 'ServiceDate'),
        'description' => truncateText((String) readableField(li, 'Description'))
      };
      if (enrichmentEnabled) {
        putIfPresent(
          row,
          'productFamily',
          activeProductFamily(readableField(product, 'Family'))
        );
        putIfPresent(
          row,
          'productLine',
          normalizedText(readableField(product, 'Sub_Category__c'))
        );
        putIfPresent(
          row,
          'productSubgroup',
          readableField(product, 'Subgroup__c')
        );
        putIfPresent(row, 'productGroup', readableField(product, 'Group__c'));
        putIfPresent(
          row,
          'productDescription',
          truncateText((String) readableField(product, 'Description'))
        );
        putIfPresent(
          row,
          'productCatalogDescription',
          truncateText(
            (String) readableField(product, 'Product_Description__c')
          )
        );
        putIfPresent(
          row,
          'productCategoryName',
          readableField(product, 'CategoryName__c')
        );
        List<String> licenseGroups = splitMultiSelect(
          readableField(product, 'LicenseGroup__c')
        );
        if (!licenseGroups.isEmpty()) {
          row.put('licenseGroups', licenseGroups);
        }
        putIfPresent(
          row,
          'serviceCategory',
          readableField(product, 'ServiceCategory__c')
        );
      }
      rows.add(row);
    }
    return rows;
  }

  private static String activeProductFamily(Object rawValue) {
    String candidate = normalizedText(rawValue);
    if (String.isBlank(candidate)) {
      return null;
    }
    for (
      Schema.PicklistEntry entry : Product2.Family.getDescribe()
        .getPicklistValues()
    ) {
      if (entry.isActive() && entry.getValue().equalsIgnoreCase(candidate)) {
        return entry.getValue();
      }
    }
    return null;
  }

  private static List<String> splitMultiSelect(Object rawValue) {
    List<String> values = new List<String>();
    if (!(rawValue instanceof String) || String.isBlank((String) rawValue)) {
      return values;
    }

    Set<String> seen = new Set<String>();
    for (String candidate : ((String) rawValue).split(';')) {
      String normalized = candidate == null ? null : candidate.trim();
      if (String.isNotBlank(normalized) && seen.add(normalized)) {
        values.add(normalized);
      }
    }
    return values;
  }

  public virtual class ActivityParticipantProvider {
    public virtual ActivityParticipantResult load(
      List<SObject> tasks,
      List<SObject> events
    ) {
      List<SObject> taskRelations = new List<SObject>();
      List<SObject> eventRelations = new List<SObject>();
      Set<Id> taskIds = recordIds(tasks);
      Set<Id> eventIds = recordIds(events);
      List<String> unavailableSources = new List<String>();
      Boolean relationsTruncated = false;

      if (!taskIds.isEmpty()) {
        if (TaskRelation.SObjectType.getDescribe().isAccessible()) {
          try {
            taskRelations = stripReadable(
              new QueryFactory(TaskRelation.SObjectType)
                .selectFields(
                  new List<String>{ 'TaskId', 'RelationId', 'IsWhat' }
                )
                .setCondition('TaskId IN :bind0 AND IsWhat = false')
                .setQueryBindings(new List<Object>{ taskIds })
                .setLimit(MAX_ACTIVITY_RELATIONS + 1)
                .executeQuery()
            );
            if (trimOverflow(taskRelations, MAX_ACTIVITY_RELATIONS)) {
              relationsTruncated = true;
              unavailableSources.add('task_relations_limit');
            }
          } catch (Exception ignored) {
            unavailableSources.add('task_relations_error');
          }
        } else {
          unavailableSources.add('task_relations_not_accessible');
        }
      }

      if (!eventIds.isEmpty()) {
        if (EventRelation.SObjectType.getDescribe().isAccessible()) {
          try {
            eventRelations = stripReadable(
              new QueryFactory(EventRelation.SObjectType)
                .selectFields(
                  new List<String>{ 'EventId', 'RelationId', 'IsInvitee' }
                )
                .setCondition('EventId IN :bind0')
                .setQueryBindings(new List<Object>{ eventIds })
                .setLimit(MAX_ACTIVITY_RELATIONS + 1)
                .executeQuery()
            );
            if (trimOverflow(eventRelations, MAX_ACTIVITY_RELATIONS)) {
              relationsTruncated = true;
              unavailableSources.add('event_relations_limit');
            }
          } catch (Exception ignored) {
            unavailableSources.add('event_relations_error');
          }
        } else {
          unavailableSources.add('event_relations_not_accessible');
        }
      }

      List<ParticipantEvidence> evidence = collectParticipantEvidence(
        tasks,
        events,
        taskRelations,
        eventRelations
      );
      Set<Id> contactIds = new Set<Id>();
      for (ParticipantEvidence item : evidence) {
        contactIds.add(item.contactId);
      }

      ActivityParticipantResult result = new ActivityParticipantResult();
      result.isTruncated = relationsTruncated;
      if (!unavailableSources.isEmpty()) {
        result.reasonCode = unavailableSources.size() == 1
          ? unavailableSources[0]
          : 'participant_sources_partial';
      }
      if (contactIds.isEmpty()) {
        return result;
      }
      if (!Contact.SObjectType.getDescribe().isAccessible()) {
        result.status = 'not_accessible';
        result.reasonCode = 'contacts_not_accessible';
        return result;
      }

      try {
        List<SObject> contacts = stripReadable(
          new QueryFactory(Contact.SObjectType)
            .selectFields(new List<String>{ 'Id', 'Name', 'Title' })
            .setCondition('Id IN :bind0')
            .setQueryBindings(new List<Object>{ contactIds })
            .executeQuery()
        );
        result.participantsByActivityId = materializeParticipants(
          evidence,
          contacts
        );
        return result;
      } catch (Exception ignored) {
        result.status = 'error';
        result.reasonCode = 'contact_retrieval_error';
        return result;
      }
    }
  }

  @TestVisible
  private static List<ParticipantEvidence> collectParticipantEvidence(
    List<SObject> tasks,
    List<SObject> events,
    List<SObject> taskRelations,
    List<SObject> eventRelations
  ) {
    Map<String, ParticipantEvidence> evidenceByKey = new Map<String, ParticipantEvidence>();

    for (SObject record : tasks) {
      addParticipantEvidence(
        evidenceByKey,
        (Id) readableField(record, 'Id'),
        contactId(readableField(record, 'WhoId')),
        'unknown',
        'Task.WhoId contact link'
      );
    }
    for (SObject record : events) {
      addParticipantEvidence(
        evidenceByKey,
        (Id) readableField(record, 'Id'),
        contactId(readableField(record, 'WhoId')),
        'unknown',
        'Event.WhoId contact link'
      );
    }
    for (SObject record : taskRelations) {
      addParticipantEvidence(
        evidenceByKey,
        (Id) readableField(record, 'TaskId'),
        contactId(readableField(record, 'RelationId')),
        'unknown',
        'TaskRelation.RelationId contact link'
      );
    }
    for (SObject record : eventRelations) {
      Boolean isInvitee = (Boolean) readableField(record, 'IsInvitee');
      addParticipantEvidence(
        evidenceByKey,
        (Id) readableField(record, 'EventId'),
        contactId(readableField(record, 'RelationId')),
        isInvitee == true ? 'invited' : 'unknown',
        isInvitee == true
          ? 'EventRelation invitee record'
          : 'EventRelation.RelationId contact link'
      );
    }
    return evidenceByKey.values();
  }

  private static void addParticipantEvidence(
    Map<String, ParticipantEvidence> evidenceByKey,
    Id activityId,
    Id contactRecordId,
    String participationStatus,
    String evidenceSource
  ) {
    if (activityId == null || contactRecordId == null) {
      return;
    }
    String key =
      String.valueOf(activityId) +
      ':' +
      String.valueOf(contactRecordId);
    ParticipantEvidence existing = evidenceByKey.get(key);
    if (existing == null) {
      evidenceByKey.put(
        key,
        new ParticipantEvidence(
          activityId,
          contactRecordId,
          participationStatus,
          evidenceSource
        )
      );
    } else if (
      existing.participationStatus == 'unknown' &&
      participationStatus == 'invited'
    ) {
      existing.participationStatus = participationStatus;
      existing.evidenceSource = evidenceSource;
    }
  }

  @TestVisible
  private static Map<Id, List<Map<String, Object>>> materializeParticipants(
    List<ParticipantEvidence> evidence,
    List<SObject> contacts
  ) {
    Map<Id, SObject> contactsById = new Map<Id, SObject>();
    for (SObject contactRecord : contacts) {
      Id contactRecordId = (Id) readableField(contactRecord, 'Id');
      if (contactRecordId != null) {
        contactsById.put(contactRecordId, contactRecord);
      }
    }

    Map<Id, List<Map<String, Object>>> participantsByActivityId = new Map<Id, List<Map<String, Object>>>();
    for (ParticipantEvidence item : evidence) {
      SObject contactRecord = contactsById.get(item.contactId);
      if (contactRecord == null) {
        continue;
      }
      Map<String, Object> participant = new Map<String, Object>{
        'contactId' => item.contactId,
        'participationStatus' => item.participationStatus,
        'evidenceSource' => item.evidenceSource
      };
      putIfPresent(participant, 'name', readableField(contactRecord, 'Name'));
      putIfPresent(participant, 'title', readableField(contactRecord, 'Title'));
      if (!participantsByActivityId.containsKey(item.activityId)) {
        participantsByActivityId.put(
          item.activityId,
          new List<Map<String, Object>>()
        );
      }
      participantsByActivityId.get(item.activityId).add(participant);
    }
    return participantsByActivityId;
  }

  @TestVisible
  private static ConversationResult buildConversationEvidence(
    List<SObject> tasks,
    List<SObject> events,
    Map<Id, List<Map<String, Object>>> participantsByActivityId,
    Datetime windowStart,
    Datetime windowEnd
  ) {
    return buildConversationEvidence(
      tasks,
      events,
      participantsByActivityId,
      new Map<Id, Datetime>(),
      windowStart,
      windowEnd
    );
  }

  private static ConversationResult buildConversationEvidence(
    List<SObject> tasks,
    List<SObject> events,
    Map<Id, List<Map<String, Object>>> participantsByActivityId,
    Map<Id, Datetime> taskCompletionTimesById,
    Datetime windowStart,
    Datetime windowEnd
  ) {
    List<ConversationCandidate> candidates = new List<ConversationCandidate>();
    Set<Id> seenActivityIds = new Set<Id>();

    for (SObject record : tasks) {
      Id activityId = (Id) readableField(record, 'Id');
      Datetime occurredAt = taskCompletionTimesById.get(activityId);
      if (occurredAt == null) {
        occurredAt = (Datetime) readableField(record, 'CompletedDateTime');
      }
      Boolean isClosed = (Boolean) readableField(record, 'IsClosed');
      addConversationCandidate(
        candidates,
        seenActivityIds,
        activityId,
        occurredAt,
        (String) readableField(record, 'Description'),
        'Task',
        isClosed == true,
        participantsByActivityId,
        windowStart,
        windowEnd
      );
    }
    for (SObject record : events) {
      Id activityId = (Id) readableField(record, 'Id');
      Datetime occurredAt = (Datetime) readableField(record, 'StartDateTime');
      Datetime endedAt = (Datetime) readableField(record, 'EndDateTime');
      addConversationCandidate(
        candidates,
        seenActivityIds,
        activityId,
        occurredAt,
        (String) readableField(record, 'Description'),
        'Event',
        endedAt != null && endedAt <= windowEnd,
        participantsByActivityId,
        windowStart,
        windowEnd
      );
    }

    candidates.sort();
    ConversationResult result = new ConversationResult();
    Boolean textWasTruncated = false;
    for (Integer i = 0; i < candidates.size(); i++) {
      if (i >= maxConversationItems) {
        result.isTruncated = true;
        break;
      }
      result.items.add(candidates[i].item);
      if ((Boolean) candidates[i].item.get('isTruncated') == true) {
        textWasTruncated = true;
      }
    }
    result.isTruncated = result.isTruncated || textWasTruncated;
    if (candidates.size() > maxConversationItems && textWasTruncated) {
      result.reasonCode = 'item_and_text_limits';
    } else if (candidates.size() > maxConversationItems) {
      result.reasonCode = 'item_limit';
    } else if (textWasTruncated) {
      result.reasonCode = 'text_limit';
    } else if (result.items.isEmpty()) {
      result.reasonCode = 'transcripts_not_supported_no_recent_notes';
    } else {
      result.reasonCode = 'activity_notes_only';
    }
    return result;
  }

  private static void addConversationCandidate(
    List<ConversationCandidate> candidates,
    Set<Id> seenActivityIds,
    Id activityId,
    Datetime occurredAt,
    String text,
    String sourceType,
    Boolean activityCompleted,
    Map<Id, List<Map<String, Object>>> participantsByActivityId,
    Datetime windowStart,
    Datetime windowEnd
  ) {
    List<Map<String, Object>> participants = participantsByActivityId.get(
      activityId
    );
    if (
      activityId == null ||
      seenActivityIds.contains(activityId) ||
      occurredAt == null ||
      occurredAt < windowStart ||
      occurredAt > windowEnd ||
      String.isBlank(text) ||
      activityCompleted != true ||
      participants == null ||
      participants.isEmpty()
    ) {
      return;
    }

    seenActivityIds.add(activityId);
    Boolean isTruncated = text.length() > MAX_CONVERSATION_TEXT_LENGTH;
    String boundedText = isTruncated
      ? text.left(MAX_CONVERSATION_TEXT_LENGTH)
      : text;
    Map<String, Object> item = new Map<String, Object>{
      'sourceRecordId' => activityId,
      'relatedActivityId' => activityId,
      'occurredAt' => occurredAt,
      'sourceType' => sourceType,
      'contentType' => 'notes',
      'text' => boundedText,
      'participants' => participants,
      'isTruncated' => isTruncated
    };
    candidates.add(new ConversationCandidate(occurredAt, item));
  }

  @TestVisible
  private static Map<String, Object> buildDataCoverage(
    ActivityData activityData,
    CollectionData stakeholderData,
    CollectionData lineItemData
  ) {
    Integer activityCount =
      activityData.tasks.size() + activityData.events.size();
    Boolean activitiesAccessible =
      activityData.tasksAccessible || activityData.eventsAccessible;
    String activityStatus = !activitiesAccessible
      ? 'not_accessible'
      : activityCount == 0 ? 'not_found' : 'available';
    String activityReason = activityData.participantReasonCode;
    if (String.isBlank(activityReason)) {
      activityReason = activityData.tasksTruncated ||
        activityData.eventsTruncated ||
        activityData.participantRelationsTruncated
        ? 'activity_limit'
        : activityCount == 0 ? 'no_visible_records_in_window' : null;
    }

    String conversationStatus = activityData.conversationStatus;
    if (String.isBlank(conversationStatus)) {
      conversationStatus = !activitiesAccessible ||
        activityData.participantStatus == 'not_accessible'
        ? 'not_accessible'
        : activityData.conversations.isEmpty() ? 'not_found' : 'available';
    }

    return new Map<String, Object>{
      'stakeholders' => coverageEntry(
        collectionStatus(stakeholderData),
        stakeholderData.rows.size(),
        stakeholderData.isTruncated,
        null,
        null,
        collectionReason(stakeholderData)
      ),
      'activities' => coverageEntry(
        activityStatus,
        activityCount,
        activityData.tasksTruncated ||
          activityData.eventsTruncated ||
          activityData.participantRelationsTruncated,
        activityData.activityWindowStart,
        activityData.activityWindowEnd,
        activityReason
      ),
      'conversations' => coverageEntry(
        conversationStatus,
        activityData.conversations.size(),
        activityData.conversationsTruncated,
        activityData.conversationWindowStart,
        activityData.activityWindowEnd,
        activityData.conversationReasonCode
      ),
      'lineItems' => coverageEntry(
        collectionStatus(lineItemData),
        lineItemData.rows.size(),
        lineItemData.isTruncated,
        null,
        null,
        collectionReason(lineItemData)
      )
    };
  }

  private static Map<String, Object> coverageEntry(
    String status,
    Integer returnedCount,
    Boolean isTruncated,
    Datetime windowStart,
    Datetime windowEnd,
    String reasonCode
  ) {
    Map<String, Object> entry = new Map<String, Object>{
      'status' => status,
      'returnedCount' => returnedCount,
      'isTruncated' => isTruncated
    };
    putIfPresent(entry, 'windowStart', windowStart);
    putIfPresent(entry, 'windowEnd', windowEnd);
    putIfPresent(entry, 'reasonCode', reasonCode);
    return entry;
  }

  private static String collectionStatus(CollectionData data) {
    return !data.isAccessible
      ? 'not_accessible'
      : data.rows.isEmpty() ? 'not_found' : 'available';
  }

  private static String collectionReason(CollectionData data) {
    return data.isTruncated
      ? 'record_limit'
      : !data.isAccessible
          ? 'object_not_accessible'
          : data.rows.isEmpty() ? 'no_visible_records' : null;
  }

  @TestVisible
  private static String serializePayloadWithinLimit(
    Map<String, Object> payload
  ) {
    String serialized = JSON.serialize(payload);
    if (Blob.valueOf(serialized).size() < requestSizeLimitBytes) {
      return serialized;
    }

    Map<String, Object> conversationEvidence = mapValue(
      payload.get('conversationEvidence')
    );
    List<Map<String, Object>> conversationItems = conversationEvidence.get(
        'items'
      ) == null
      ? new List<Map<String, Object>>()
      : (List<Map<String, Object>>) conversationEvidence.get('items');
    Map<String, Object> coverage = mapValue(payload.get('dataCoverage'));
    Map<String, Object> conversationCoverage = mapValue(
      coverage.get('conversations')
    );

    while (!conversationItems.isEmpty()) {
      conversationItems.remove(conversationItems.size() - 1);
      conversationEvidence.put('items', conversationItems);
      conversationCoverage.put('returnedCount', conversationItems.size());
      conversationCoverage.put('isTruncated', true);
      conversationCoverage.put('reasonCode', 'request_size_limit');
      serialized = JSON.serialize(payload);
      if (Blob.valueOf(serialized).size() < requestSizeLimitBytes) {
        return serialized;
      }
    }

    Map<String, Object> activities = mapValue(payload.get('activities'));
    List<Map<String, Object>> taskRows = mapListValue(activities.get('tasks'));
    List<Map<String, Object>> eventRows = mapListValue(
      activities.get('events')
    );
    Map<String, Object> activityCoverage = mapValue(coverage.get('activities'));
    while (trimOneParticipant(eventRows) || trimOneParticipant(taskRows)) {
      activityCoverage.put('isTruncated', true);
      activityCoverage.put('reasonCode', 'request_size_limit');
      serialized = JSON.serialize(payload);
      if (Blob.valueOf(serialized).size() < requestSizeLimitBytes) {
        return serialized;
      }
    }

    throw new OpportunitySummaryPayloadException(
      'Opportunity Summary core request exceeds the service size limit.'
    );
  }

  @TestVisible
  private static String buildServiceEndpoint(String configuredEndpoint) {
    if (String.isBlank(configuredEndpoint)) {
      return configuredEndpoint;
    }
    String endpoint = configuredEndpoint.trim();
    Integer apiPathIndex = endpoint.toLowerCase().indexOf('/api/v1/');
    if (apiPathIndex >= 0) {
      endpoint = endpoint.substring(0, apiPathIndex);
    }
    while (endpoint.endsWith('/')) {
      endpoint = endpoint.left(endpoint.length() - 1);
    }
    return endpoint + ENDPOINT_PATH;
  }

  private static Set<Id> recordIds(List<SObject> records) {
    Set<Id> ids = new Set<Id>();
    for (SObject record : records) {
      Id recordId = (Id) readableField(record, 'Id');
      if (recordId != null) {
        ids.add(recordId);
      }
    }
    return ids;
  }

  private static Id contactId(Object possibleId) {
    if (possibleId == null) {
      return null;
    }
    try {
      Id candidate = (Id) possibleId;
      return candidate.getSObjectType() == Contact.SObjectType
        ? candidate
        : null;
    } catch (Exception ignored) {
      return null;
    }
  }

  private static List<Map<String, Object>> participantsFor(
    ActivityParticipantResult result,
    Id activityId
  ) {
    List<Map<String, Object>> participants = result.participantsByActivityId.get(
      activityId
    );
    return participants == null
      ? new List<Map<String, Object>>()
      : participants;
  }

  private static Boolean trimOverflow(
    List<SObject> records,
    Integer maximumSize
  ) {
    Boolean isTruncated = records.size() > maximumSize;
    while (records.size() > maximumSize) {
      records.remove(records.size() - 1);
    }
    return isTruncated;
  }

  private static void putIfPresent(
    Map<String, Object> target,
    String key,
    Object value
  ) {
    if (
      value != null &&
      (!(value instanceof String) || String.isNotBlank((String) value))
    ) {
      target.put(key, value);
    }
  }

  private static Map<String, Object> mapValue(Object value) {
    return value instanceof Map<String, Object>
      ? (Map<String, Object>) value
      : new Map<String, Object>();
  }

  private static List<Map<String, Object>> mapListValue(Object value) {
    return value == null
      ? new List<Map<String, Object>>()
      : (List<Map<String, Object>>) value;
  }

  private static Boolean trimOneParticipant(
    List<Map<String, Object>> activityRows
  ) {
    for (Integer index = activityRows.size() - 1; index >= 0; index--) {
      Object value = activityRows[index].get('participants');
      if (value == null) {
        continue;
      }
      List<Map<String, Object>> participants = (List<Map<String, Object>>) value;
      if (!participants.isEmpty()) {
        participants.remove(participants.size() - 1);
        return true;
      }
    }
    return false;
  }

  public class CollectionData {
    public List<Map<String, Object>> rows = new List<Map<String, Object>>();
    public Boolean isTruncated = false;
    public Boolean isAccessible = true;
  }

  public class ActivityData {
    public List<Map<String, Object>> tasks = new List<Map<String, Object>>();
    public List<Map<String, Object>> events = new List<Map<String, Object>>();
    public List<Map<String, Object>> conversations = new List<Map<String, Object>>();
    public Boolean tasksTruncated = false;
    public Boolean eventsTruncated = false;
    public Boolean conversationsTruncated = false;
    public Boolean participantRelationsTruncated = false;
    public Boolean tasksAccessible = true;
    public Boolean eventsAccessible = true;
    public String participantStatus = 'available';
    public String participantReasonCode;
    public String conversationStatus;
    public String conversationReasonCode;
    public Datetime activityWindowStart;
    public Datetime activityWindowEnd;
    public Datetime conversationWindowStart;
  }

  public class ActivityParticipantResult {
    public Map<Id, List<Map<String, Object>>> participantsByActivityId = new Map<Id, List<Map<String, Object>>>();
    public String status = 'available';
    public String reasonCode;
    public Boolean isTruncated = false;
  }

  public class ParticipantEvidence {
    public Id activityId;
    public Id contactId;
    public String participationStatus;
    public String evidenceSource;

    public ParticipantEvidence(
      Id activityId,
      Id contactId,
      String participationStatus,
      String evidenceSource
    ) {
      this.activityId = activityId;
      this.contactId = contactId;
      this.participationStatus = participationStatus;
      this.evidenceSource = evidenceSource;
    }
  }

  public class ConversationResult {
    public List<Map<String, Object>> items = new List<Map<String, Object>>();
    public Boolean isTruncated = false;
    public String reasonCode;
  }

  private class ConversationCandidate implements Comparable {
    private Datetime occurredAt;
    private Map<String, Object> item;

    private ConversationCandidate(
      Datetime occurredAt,
      Map<String, Object> item
    ) {
      this.occurredAt = occurredAt;
      this.item = item;
    }

    public Integer compareTo(Object other) {
      ConversationCandidate otherCandidate = (ConversationCandidate) other;
      if (occurredAt == otherCandidate.occurredAt) {
        return 0;
      }
      return occurredAt > otherCandidate.occurredAt ? -1 : 1;
    }
  }

  private class OpportunitySummaryPayloadException extends Exception {
  }

  // Sibling opportunities on the same account (excluding the current one) give the model
  // the account's win/downgrade/expansion history, which powers the "account pattern" and
  // stage-journey narrative in the summary.
  private static List<Map<String, Object>> getRelatedOpportunities(
    Id accountId,
    Id currentOppId
  ) {
    List<Map<String, Object>> rows = new List<Map<String, Object>>();
    if (accountId == null) {
      return rows;
    }
    List<SObject> related = stripReadable(
      buildRelatedOpportunitiesQuery(accountId, currentOppId).executeQuery()
    );
    for (SObject sobj : related) {
      Opportunity opp = (Opportunity) sobj;
      rows.add(
        new Map<String, Object>{
          'id' => readableField(opp, 'Id'),
          'name' => readableField(opp, 'Name'),
          'amount' => readableField(opp, 'Amount'),
          'currencyIsoCode' => readableField(opp, 'CurrencyIsoCode'),
          'type' => readableField(opp, 'Type'),
          'stageName' => readableField(opp, 'StageName'),
          'forecastCategory' => readableField(opp, 'ForecastCategory'),
          'probability' => readableField(opp, 'Probability'),
          'isWon' => readableField(opp, 'IsWon'),
          'isClosed' => readableField(opp, 'IsClosed'),
          'closeDate' => readableField(opp, 'CloseDate'),
          'createdDate' => readableField(opp, 'CreatedDate')
        }
      );
    }
    return rows;
  }

  @TestVisible
  private static QueryFactory buildRelatedOpportunitiesQuery(
    Id accountId,
    Id currentOppId
  ) {
    return new OpportunitySelector()
      .selectOpportunities()
      .withoutSelectorFieldsIncluded()
      .selectFields(
        new List<String>{
          'Id',
          'Name',
          'Amount',
          'CurrencyIsoCode',
          'Type',
          'StageName',
          'ForecastCategory',
          'Probability',
          'IsWon',
          'IsClosed',
          'CloseDate',
          'CreatedDate'
        }
      )
      // The selector's default Name ordering would come first and make the limit
      // keep the first opportunities alphabetically instead of the most recent.
      .withoutSelectorOrderByIncluded()
      .setCondition('AccountId = :bind0 AND Id != :bind1')
      .addOrdering(Opportunity.CloseDate, QueryFactory.SortOrder.DESCENDING)
      .setQueryBindings(new List<Object>{ accountId, currentOppId })
      .setLimit(maxRelatedOpps);
  }

  // QueryFactory / selectors run in system mode; `with sharing` only enforces row-level
  // sharing. Strip fields the running user cannot read before they reach the GCP payload.
  // enforceRootObjectCRUD=false so missing object access on related types (Case, Task, …)
  // yields empty field sets instead of NoAccessException aborting the whole summary.
  private static List<SObject> stripReadable(List<SObject> records) {
    if (records == null || records.isEmpty()) {
      return records == null ? new List<SObject>() : records;
    }
    return System.Security.stripInaccessible(
        System.AccessType.READABLE,
        records,
        false
      )
      .getRecords();
  }

  // stripInaccessible REMOVES an inaccessible field from the record — it does NOT null it
  // out. A direct getter on a removed field throws System.SObjectException. Reading via
  // getPopulatedFieldsAsMap() returns null instead, so the payload still builds from what
  // the user CAN read.
  private static Object readableField(SObject record, String fieldApiName) {
    if (record == null || String.isBlank(fieldApiName)) {
      return null;
    }
    return record.getPopulatedFieldsAsMap().get(fieldApiName);
  }

  private static SObject readableRelated(
    SObject record,
    String relationshipName
  ) {
    Object related = readableField(record, relationshipName);
    return related instanceof SObject ? (SObject) related : null;
  }

  private static String truncateText(String value) {
    if (String.isBlank(value) || value.length() <= MAX_DESCRIPTION_LENGTH) {
      return value;
    }
    return value.left(MAX_DESCRIPTION_LENGTH) + '…';
  }

  // ---------------- Response handling ----------------

  // The Cloud Run response wraps the model output in a `body` field. The model is expected to
  // return the summary as an ordered list of section objects (title/badge/badgeVariant/items),
  // which the LWC renders as cards. This method normalises the possible shapes into a `cards`
  // list, or surfaces a plain-string body as an error message.
  @TestVisible
  private static String buildResult(Object raw) {
    return buildResult(raw, new Set<Id>(), new List<Map<String, Object>>());
  }

  @TestVisible
  private static String buildResult(
    Object raw,
    Set<Id> referenceableIds,
    List<Map<String, Object>> namedRecords
  ) {
    List<Object> cards = extractCards(raw);
    if (cards != null) {
      Map<String, Object> result = new Map<String, Object>{
        'success' => true,
        'cards' => cards
      };

      // Keep the established cards contract intact while passing the optional
      // objects through. The LWC owns validation and presentation so a malformed
      // optional object can never invalidate a summary.
      Object body = getBody(raw);
      if (body instanceof Map<String, Object>) {
        Map<String, Object> bodyMap = (Map<String, Object>) body;
        for (
          String key : new List<String>{
            'opportunity_enrichment',
            'deal_state',
            'salesforce_fields'
          }
        ) {
          if (bodyMap.get(key) instanceof Map<String, Object>) {
            result.put(key, bodyMap.get(key));
          }
        }
        List<Object> references = sanitizedRecordReferences(
          bodyMap.get('record_references'),
          referenceableIds
        );
        references.addAll(
          namedReferencesForCards(namedRecords, references, cards)
        );
        if (!references.isEmpty()) {
          result.put('record_references', references);
        }
      }

      return JSON.serializePretty(result);
    }

    Object body = getBody(raw);
    if (body instanceof String) {
      System.debug(
        LoggingLevel.ERROR,
        'Opportunity Summary service returned a non-card message.'
      );
    } else {
      System.debug(
        LoggingLevel.ERROR,
        'Opportunity Summary service returned an unexpected response format.'
      );
    }

    return errorJson(userFacingError);
  }

  private static List<Object> extractCards(Object raw) {
    Object body = getBody(raw);

    if (body instanceof List<Object>) {
      return (List<Object>) body;
    }

    if (body instanceof Map<String, Object>) {
      Map<String, Object> bodyMap = (Map<String, Object>) body;
      for (
        String key : new List<String>{
          'opportunity_summary',
          'sections',
          'cards'
        }
      ) {
        Object val = bodyMap.get(key);
        if (val instanceof List<Object>) {
          return (List<Object>) val;
        }
        // The model may emit the summary as a keyed object
        // (sectionTitle -> list of bullet strings) instead of an
        // ordered list of card objects. Convert that shape here so the
        // LWC always receives a consistent `cards` array.
        if (val instanceof Map<String, Object>) {
          return cardsFromSummaryMap((Map<String, Object>) val);
        }
      }
    }

    return null;
  }

  // Preferred display order for the summary sections. Any section not listed
  // here is appended afterwards in its original order.
  private static final List<String> SECTION_ORDER = new List<String>{
    'Executive Summary',
    'Overall Deal Score',
    'Win Factors',
    'Risk Flags',
    'Next Best Actions',
    'Close Plan',
    'Opportunity History & Stage Journey'
  };

  // Section title (lower-cased) -> badge/card styling hint understood by the LWC.
  private static final Map<String, String> SECTION_VARIANTS = new Map<String, String>{
    'risk flags' => 'risk',
    'win factors' => 'success',
    'next best actions' => 'info',
    'overall deal score' => 'success'
  };

  private static List<Object> cardsFromSummaryMap(
    Map<String, Object> summaryMap
  ) {
    List<Object> cards = new List<Object>();
    Set<String> used = new Set<String>();

    for (String preferred : SECTION_ORDER) {
      for (String key : summaryMap.keySet()) {
        if (
          !used.contains(key) &&
          key != null &&
          key.equalsIgnoreCase(preferred)
        ) {
          cards.add(buildSummaryCard(key, summaryMap.get(key)));
          used.add(key);
        }
      }
    }

    for (String key : summaryMap.keySet()) {
      if (!used.contains(key)) {
        cards.add(buildSummaryCard(key, summaryMap.get(key)));
        used.add(key);
      }
    }

    return cards;
  }

  private static Object buildSummaryCard(String title, Object value) {
    List<Object> items = new List<Object>();
    if (value instanceof List<Object>) {
      items = new List<Object>((List<Object>) value);
    } else if (value != null) {
      items.add(value);
    }

    String lower = title == null ? '' : title.toLowerCase();

    Map<String, Object> card = new Map<String, Object>{
      'title' => title,
      'items' => items
    };

    if (SECTION_VARIANTS.containsKey(lower)) {
      card.put('badgeVariant', SECTION_VARIANTS.get(lower));
    }

    // The score section reads best with the headline score shown as a badge
    // and the remaining bullets kept as body text.
    if (lower == 'overall deal score' && !items.isEmpty()) {
      card.put('cardVariant', 'score');
      card.put('badge', String.valueOf(items[0]));
      List<Object> rest = new List<Object>();
      for (Integer i = 1; i < items.size(); i++) {
        rest.add(items[i]);
      }
      card.put('items', rest);
    }

    return card;
  }

  // Links may only open records this request sent to GCP, so a model-invented or
  // altered Id can never become a link.
  @TestVisible
  private static Set<Id> referenceableRecordIds(Map<String, Object> payload) {
    Set<Id> ids = new Set<Id>();
    for (Map<String, Object> namedRecord : namedRecordReferences(payload)) {
      ids.add((Id) namedRecord.get('id'));
    }
    Map<String, Object> cases = mapValue(payload.get('cases'));
    Map<String, Object> activities = mapValue(payload.get('activities'));
    for (
      Object rows : new List<Object>{
        cases.get('open'),
        cases.get('recentlyClosed'),
        activities.get('tasks'),
        activities.get('events')
      }
    ) {
      for (Map<String, Object> row : mapListValue(rows)) {
        Id rowId = toId(row.get('id'));
        if (rowId != null) {
          ids.add(rowId);
        }
      }
    }
    return ids;
  }

  // Every record this request sent that has an Id and a name the summary can quote:
  // owner, account, related opportunities, contacts, products, cases and activities.
  // Each label is the record's own name (or case number / subject). A label shared by
  // two different records is dropped rather than risk linking the wrong one.
  @TestVisible
  private static List<Map<String, Object>> namedRecordReferences(
    Map<String, Object> payload
  ) {
    Map<String, Object> opportunity = mapValue(payload.get('opportunity'));
    List<Map<String, Object>> candidates = new List<Map<String, Object>>();
    addNamedRecord(
      candidates,
      'User',
      opportunity.get('ownerId'),
      opportunity.get('ownerName'),
      MIN_NAMED_LABEL_LENGTH
    );
    addNamedRecord(
      candidates,
      'Account',
      opportunity.get('accountId'),
      opportunity.get('accountName'),
      MIN_NAMED_LABEL_LENGTH
    );
    // The current opportunity is not linked: it would only reopen this page.
    for (
      Map<String, Object> related : mapListValue(
        payload.get('relatedOpportunities')
      )
    ) {
      addNamedRecord(
        candidates,
        'Opportunity',
        related.get('id'),
        related.get('name'),
        MIN_NAMED_LABEL_LENGTH
      );
    }
    for (
      Map<String, Object> stakeholder : mapListValue(
        payload.get('stakeholders')
      )
    ) {
      addNamedRecord(
        candidates,
        'Contact',
        stakeholder.get('contactId'),
        stakeholder.get('name'),
        MIN_NAMED_LABEL_LENGTH
      );
    }
    for (
      Map<String, Object> lineItem : mapListValue(payload.get('lineItems'))
    ) {
      addNamedRecord(
        candidates,
        'Product2',
        lineItem.get('productId'),
        lineItem.get('productName'),
        MIN_NAMED_LABEL_LENGTH
      );
    }
    Map<String, Object> cases = mapValue(payload.get('cases'));
    List<Map<String, Object>> caseRows = new List<Map<String, Object>>();
    caseRows.addAll(mapListValue(cases.get('open')));
    caseRows.addAll(mapListValue(cases.get('recentlyClosed')));
    for (Map<String, Object> caseRow : caseRows) {
      addNamedRecord(
        candidates,
        'Case',
        caseRow.get('id'),
        caseRow.get('caseNumber'),
        MIN_NAMED_LABEL_LENGTH
      );
      addNamedRecord(
        candidates,
        'Case',
        caseRow.get('id'),
        caseRow.get('subject'),
        MIN_SUBJECT_LABEL_LENGTH
      );
    }
    Map<String, Object> activities = mapValue(payload.get('activities'));
    for (String objectType : new List<String>{ 'Task', 'Event' }) {
      for (
        Map<String, Object> row : mapListValue(
          activities.get(objectType == 'Task' ? 'tasks' : 'events')
        )
      ) {
        addNamedRecord(
          candidates,
          objectType,
          row.get('id'),
          row.get('subject'),
          MIN_SUBJECT_LABEL_LENGTH
        );
      }
    }
    List<Map<String, Object>> participantRows = new List<Map<String, Object>>();
    participantRows.addAll(
      mapListValue(mapValue(payload.get('conversationEvidence')).get('items'))
    );
    participantRows.addAll(mapListValue(activities.get('tasks')));
    participantRows.addAll(mapListValue(activities.get('events')));
    for (Map<String, Object> row : participantRows) {
      for (
        Map<String, Object> participant : mapListValue(row.get('participants'))
      ) {
        addNamedRecord(
          candidates,
          'Contact',
          participant.get('contactId'),
          participant.get('name'),
          MIN_NAMED_LABEL_LENGTH
        );
      }
    }

    Map<String, Set<Id>> idsByLabel = new Map<String, Set<Id>>();
    for (Map<String, Object> candidate : candidates) {
      String labelKey = ((String) candidate.get('label')).toLowerCase();
      if (!idsByLabel.containsKey(labelKey)) {
        idsByLabel.put(labelKey, new Set<Id>());
      }
      idsByLabel.get(labelKey).add((Id) candidate.get('id'));
    }
    List<Map<String, Object>> named = new List<Map<String, Object>>();
    Set<String> seen = new Set<String>();
    for (Map<String, Object> candidate : candidates) {
      String labelKey = ((String) candidate.get('label')).toLowerCase();
      if (
        idsByLabel.get(labelKey).size() == 1 &&
        seen.add(candidate.get('id') + '|' + labelKey)
      ) {
        named.add(candidate);
      }
    }
    return named;
  }

  private static void addNamedRecord(
    List<Map<String, Object>> candidates,
    String objectType,
    Object rawId,
    Object rawLabel,
    Integer minimumLength
  ) {
    Id recordId = toId(rawId);
    String label = normalizedText(rawLabel);
    if (
      recordId == null ||
      recordId.getSObjectType() != REFERENCE_OBJECT_TYPES.get(objectType) ||
      label == null ||
      label.length() < minimumLength
    ) {
      return;
    }
    candidates.add(
      new Map<String, Object>{
        'object_type' => objectType,
        'id' => String.valueOf(recordId),
        'label' => label
      }
    );
  }

  // Record names may appear in any section, so they are offered to every card.
  // A record GCP already referenced (e.g. a case by its number) keeps GCP's link
  // only, so Salesforce never adds a second, overlapping link to it.
  private static List<Object> namedReferencesForCards(
    List<Map<String, Object>> namedRecords,
    List<Object> gcpReferences,
    List<Object> cards
  ) {
    List<Object> references = new List<Object>();
    if (namedRecords == null || namedRecords.isEmpty()) {
      return references;
    }
    Set<String> referencedIds = new Set<String>();
    for (Object reference : gcpReferences) {
      referencedIds.add(
        String.valueOf(((Map<String, Object>) reference).get('id'))
      );
    }
    List<String> sections = new List<String>();
    for (Object card : cards) {
      if (card instanceof Map<String, Object>) {
        putIfText(sections, ((Map<String, Object>) card).get('title'));
      }
    }
    if (sections.isEmpty()) {
      return references;
    }
    for (Map<String, Object> namedRecord : namedRecords) {
      if (referencedIds.contains((String) namedRecord.get('id'))) {
        continue;
      }
      Map<String, Object> reference = new Map<String, Object>(namedRecord);
      reference.put('mentioned_in', sections);
      reference.put('source', 'salesforce');
      references.add(reference);
    }
    return references;
  }

  @TestVisible
  private static List<Object> sanitizedRecordReferences(
    Object rawReferences,
    Set<Id> referenceableIds
  ) {
    List<Object> references = new List<Object>();
    if (!(rawReferences instanceof List<Object>)) {
      return references;
    }
    for (Object candidate : (List<Object>) rawReferences) {
      if (!(candidate instanceof Map<String, Object>)) {
        continue;
      }
      Map<String, Object> reference = (Map<String, Object>) candidate;
      Object objectType = reference.get('object_type');
      Id recordId = toId(reference.get('id'));
      String label = normalizedText(reference.get('label'));
      List<String> sections = new List<String>();
      if (reference.get('mentioned_in') instanceof List<Object>) {
        for (Object section : (List<Object>) reference.get('mentioned_in')) {
          putIfText(sections, section);
        }
      }
      if (
        !(objectType instanceof String) ||
        !REFERENCE_OBJECT_TYPES.containsKey((String) objectType) ||
        recordId == null ||
        recordId.getSObjectType() !=
        REFERENCE_OBJECT_TYPES.get((String) objectType) ||
        !referenceableIds.contains(recordId) ||
        label == null ||
        sections.isEmpty()
      ) {
        continue;
      }
      Map<String, Object> sanitized = new Map<String, Object>{
        'object_type' => objectType,
        'id' => String.valueOf(recordId),
        'label' => label,
        'mentioned_in' => sections
      };
      putIfPresent(
        sanitized,
        'case_number',
        normalizedText(reference.get('case_number'))
      );
      putIfPresent(
        sanitized,
        'activity_kind',
        normalizedText(reference.get('activity_kind'))
      );
      references.add(sanitized);
    }
    return references;
  }

  private static void putIfText(List<String> target, Object value) {
    String text = normalizedText(value);
    if (text != null) {
      target.add(text);
    }
  }

  private static Id toId(Object value) {
    if (!(value instanceof String) && !(value instanceof Id)) {
      return null;
    }
    try {
      return Id.valueOf(String.valueOf(value));
    } catch (Exception ignored) {
      return null;
    }
  }

  private static Object getBody(Object raw) {
    if (raw instanceof Map<String, Object>) {
      return ((Map<String, Object>) raw).get('body');
    }
    if (raw instanceof List<Object>) {
      List<Object> arr = (List<Object>) raw;
      if (!arr.isEmpty() && arr[0] instanceof Map<String, Object>) {
        return ((Map<String, Object>) arr[0]).get('body');
      }
    }
    return null;
  }

  private static String errorJson(String message) {
    return JSON.serializePretty(
      new Map<String, Object>{ 'success' => false, 'message' => message }
    );
  }

  private static String logAndFail(String context, Exception e) {
    System.debug(
      LoggingLevel.ERROR,
      'Opportunity Summary failed: ' + context + '.'
    );
    return errorJson(userFacingError);
  }

  // ---------------- Feature toggle & telemetry ----------------

  @TestVisible
  private static Boolean isOpportunitySummaryEnrichmentEnabled() {
    GCP_Feature_Toggle__c setting = GCP_Feature_Toggle__c.getInstance();
    Object configuredValue = settingField(setting, ENRICHMENT_SWITCH_FIELD);
    return configuredValue != null &&
      Boolean.valueOf(String.valueOf(configuredValue));
  }

  @TestVisible
  private static Boolean isOpportunitySummaryCallTranscriptsEnabled() {
    GCP_Feature_Toggle__c setting = GCP_Feature_Toggle__c.getInstance();
    return setting != null &&
      setting.Opportunity_Summary_Call_Transcripts__c == true;
  }

  @TestVisible
  private static Map<String, String> configurationOverrides = new Map<String, String>();

  /* Technical labels always use the base language so translations cannot change behavior. */
  private static String configurationLabel(String suffix) {
    if (Test.isRunningTest() && configurationOverrides.containsKey(suffix)) {
      return configurationOverrides.get(suffix);
    }
    try {
      return System.Label.get('', 'OpportunitySummary' + suffix, 'en_US');
    } catch (Exception ignored) {
      return null;
    }
  }

  private static Integer configuredInteger(
    String suffix,
    Integer fallback,
    Integer maximum
  ) {
    return parsePositiveInteger(configurationLabel(suffix), fallback, maximum);
  }

  @TestVisible
  private static Integer parsePositiveInteger(
    String raw,
    Integer fallback,
    Integer maximum
  ) {
    if (String.isBlank(raw) || !Pattern.matches('[0-9]+', raw.trim())) {
      return fallback;
    }
    try {
      Integer value = Integer.valueOf(raw.trim());
      return value > 0 && value <= maximum ? value : fallback;
    } catch (Exception ignored) {
      return fallback;
    }
  }

  private static Set<String> configuredList(
    String suffix,
    Set<String> fallback,
    Boolean isDomainList
  ) {
    return parseConfigurationList(
      configurationLabel(suffix),
      fallback,
      isDomainList
    );
  }

  @TestVisible
  private static Set<String> parseConfigurationList(
    String raw,
    Set<String> fallback,
    Boolean isDomainList
  ) {
    Set<String> normalizedFallback = new Set<String>();
    for (String entry : fallback) {
      normalizedFallback.add(entry.trim().toLowerCase());
    }
    if (String.isBlank(raw)) {
      return normalizedFallback;
    }
    Set<String> result = new Set<String>();
    for (String entry : raw.split('[\\r\\n]+')) {
      String value = entry.trim().toLowerCase();
      if (String.isBlank(value)) {
        continue;
      }
      if (
        isDomainList &&
        !Pattern.matches('[a-z0-9]+([.-][a-z0-9]+)*[.][a-z]{2,}', value)
      ) {
        return normalizedFallback;
      }
      result.add(value);
    }
    return result.isEmpty() ? normalizedFallback : result;
  }

  @TestVisible
  private static Integer getRecentEvidenceLookbackDays() {
    return configuredInteger(
      'RecentDays',
      DEFAULT_RECENT_EVIDENCE_DAYS,
      MAX_RECENT_EVIDENCE_DAYS
    );
  }

  private static Object settingField(SObject setting, String fieldApiName) {
    if (setting == null || String.isBlank(fieldApiName)) {
      return null;
    }
    Map<String, Schema.SObjectField> fields = setting
      .getSObjectType()
      .getDescribe()
      .fields
      .getMap();
    for (String availableField : fields.keySet()) {
      if (availableField.equalsIgnoreCase(fieldApiName)) {
        return setting.get(availableField);
      }
    }
    return null;
  }

  @AuraEnabled(cacheable=true)
  public static Boolean isOpportunitySummaryEnabled() {
    GCP_Feature_Toggle__c setting = GCP_Feature_Toggle__c.getInstance();
    return (setting != null && setting.Enable_Opportunity_Summary__c == true);
  }

  @AuraEnabled(cacheable=false)
  public static void logAIHEvent(
    String eventType,
    String subfeature,
    String feedback
  ) {
    Set<String> allowed = new Set<String>{
      'aih_view',
      'aih_like',
      'aih_dislike',
      'aih_feedback'
    };
    if (String.isBlank(eventType) || !allowed.contains(eventType)) {
      return;
    }

    String safeSubfeature = String.isBlank(subfeature)
      ? 'Unknown'
      : subfeature.left(80);
    String safeFeedback = String.isBlank(feedback) ? null : feedback.left(1000);

    Map<String, Object> payload = new Map<String, Object>{
      'subfeature' => safeSubfeature
    };
    if (safeFeedback != null) {
      payload.put('feedback', safeFeedback);
    }

    System.enqueueJob(
      new AIUsageLogQueueable(
        new List<String>{ eventType },
        JSON.serialize(payload)
      )
    );
  }
}
