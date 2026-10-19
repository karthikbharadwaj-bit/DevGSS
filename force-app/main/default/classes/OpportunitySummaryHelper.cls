/*
 * Sends one Opportunity's summary request to the Opportunity Summary service on GCP Cloud Run and
 * shapes the service's cards for the opportunitySummary LWC. OpportunitySummaryPayloadHelper builds
 * the request. GCPCalloutForOpportunitySummary is the LWC's entry point.
 */
public with sharing class OpportunitySummaryHelper {
  private static final String AUTH_CONFIG_NAME = 'opportunitySummary';
  private static final String ENDPOINT_PATH = '/api/v1/opportunity_summary';
  private static final String HTTP_METHOD_POST = 'POST';
  private static final String HEADER_CONTENT_TYPE = 'Content-Type';
  private static final String HEADER_AUTHORIZATION = 'Authorization';
  private static final String CONTENT_TYPE_JSON = 'application/json';
  private static final String BEARER_PREFIX = 'Bearer ';
  private static final Integer HTTP_OK = 200;
  private static final String SETTING_NAME = 'OpportunitySummary';
  private static final List<Schema.SObjectField> CLIENT_SETTING_FIELDS = new List<Schema.SObjectField>{
    Summary_Setting__mdt.CacheHours__c,
    Summary_Setting__mdt.CacheMaxKB__c
  };
  private static final Integer DEFAULT_TIMEOUT_SECONDS = 120;
  private static final Integer MAX_TIMEOUT_SECONDS = 120;
  private static final Integer MILLISECONDS_PER_SECOND = 1000;
  private static final String LOG_SOURCE = 'GCPCalloutForOpportunitySummary';

  private static final String LOG_CONTEXT_SEPARATOR = ': ';
  private static final String CONTEXT_CALLOUT = 'Callout error';
  private static final String CONTEXT_QUERY = 'Database query error';
  private static final String CONTEXT_CONFIGURATION = 'Configuration error';
  private static final String CONTEXT_UNEXPECTED = 'Unexpected error';

  private static final String HTTP_FAILURE_MESSAGE = 'Cloud Run call failed. Status: ';
  private static final String MISSING_RECORD_ID_MESSAGE = 'Opportunity Summary was called without a record Id.';
  private static final String EMPTY_RESPONSE_MESSAGE = 'Opportunity Summary service returned an empty body.';
  private static final String NON_CARD_RESPONSE_MESSAGE = 'Opportunity Summary service returned a non-card message.';
  private static final String UNEXPECTED_RESPONSE_MESSAGE = 'Opportunity Summary service returned an unexpected response format.';
  private static final String ENRICHMENT_SWITCH_FIELD = 'Enable_Opportunity_Summary_Enrichment__c';

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

  private static final Integer DEFAULT_RECENT_EVIDENCE_DAYS = 90;
  private static final Integer MAX_RECENT_EVIDENCE_DAYS = 365;

  // Technical failures (callout, config, query, parsing) are logged for support and
  // reported to the user with this message only — endpoints, status codes and stack
  // details must never reach the UI.
  private static String userFacingError {
    get {
      return System.Label.SummaryServerError;
    }
  }

  /**
   * Generates the summary for one Opportunity. Technical failures are logged and the user only
   * sees a label-backed 'Error: ' reply.
   */
  public static String generateSummary(String userId, String recordId) {
    try {
      if (String.isBlank(recordId)) {
        recordFailure(MISSING_RECORD_ID_MESSAGE);
        return GCPSummaryUtil.errorReply(userFacingError);
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
      return logAndFail(CONTEXT_CALLOUT, ce);
    } catch (QueryException qe) {
      return logAndFail(CONTEXT_QUERY, qe);
    } catch (GCPAuthUtil.GCPCalloutException ae) {
      return logAndFail(CONTEXT_CONFIGURATION, ae);
    } catch (Exception e) {
      return logAndFail(CONTEXT_UNEXPECTED, e);
    } finally {
      flushFailureLogs();
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
    Map<String, Object> payload = OpportunitySummaryPayloadHelper.buildPayload(
      username,
      recordId
    );
    String requestBody = OpportunitySummaryPayloadHelper.serializePayloadWithinLimit(
      payload
    );

    HttpRequest req = new HttpRequest();
    req.setEndpoint(
      GCPSummaryUtil.buildServiceEndpoint(endpoint, ENDPOINT_PATH)
    );
    req.setMethod(HTTP_METHOD_POST);
    req.setHeader(HEADER_CONTENT_TYPE, CONTENT_TYPE_JSON);
    req.setHeader(HEADER_AUTHORIZATION, BEARER_PREFIX + idToken);
    req.setBody(requestBody);
    req.setTimeout(
      configuredInteger(
        Summary_Setting__mdt.TimeoutSeconds__c,
        DEFAULT_TIMEOUT_SECONDS,
        MAX_TIMEOUT_SECONDS
      ) * MILLISECONDS_PER_SECOND
    );

    HttpResponse res = new Http().send(req);
    if (res.getStatusCode() != HTTP_OK) {
      throw new CalloutException(HTTP_FAILURE_MESSAGE + res.getStatusCode());
    }

    String responseBody = res.getBody();
    if (String.isBlank(responseBody)) {
      recordFailure(EMPTY_RESPONSE_MESSAGE);
      return GCPSummaryUtil.errorReply(userFacingError);
    }

    return buildResult(
      JSON.deserializeUntyped(responseBody),
      referenceableRecordIds(payload),
      namedRecordReferences(payload)
    );
  }

  // ---------------- Payload assembly ----------------

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
        // Optional [{section, index}] list marking summary lines drawn from a call.
        if (bodyMap.get('call_insights') instanceof List<Object>) {
          result.put('call_insights', bodyMap.get('call_insights'));
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

    recordFailure(
      getBody(raw) instanceof String
        ? NON_CARD_RESPONSE_MESSAGE
        : UNEXPECTED_RESPONSE_MESSAGE
    );
    return GCPSummaryUtil.errorReply(userFacingError);
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
    Map<String, Object> cases = OpportunitySummaryPayloadHelper.mapValue(
      payload.get('cases')
    );
    Map<String, Object> activities = OpportunitySummaryPayloadHelper.mapValue(
      payload.get('activities')
    );
    for (
      Object rows : new List<Object>{
        cases.get('open'),
        cases.get('recentlyClosed'),
        activities.get('tasks'),
        activities.get('events')
      }
    ) {
      for (
        Map<String, Object> row : OpportunitySummaryPayloadHelper.mapListValue(
          rows
        )
      ) {
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
    Map<String, Object> opportunity = OpportunitySummaryPayloadHelper.mapValue(
      payload.get('opportunity')
    );
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
      Map<String, Object> related : OpportunitySummaryPayloadHelper.mapListValue(
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
      Map<String, Object> stakeholder : OpportunitySummaryPayloadHelper.mapListValue(
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
      Map<String, Object> lineItem : OpportunitySummaryPayloadHelper.mapListValue(
        payload.get('lineItems')
      )
    ) {
      addNamedRecord(
        candidates,
        'Product2',
        lineItem.get('productId'),
        lineItem.get('productName'),
        MIN_NAMED_LABEL_LENGTH
      );
    }
    Map<String, Object> cases = OpportunitySummaryPayloadHelper.mapValue(
      payload.get('cases')
    );
    List<Map<String, Object>> caseRows = new List<Map<String, Object>>();
    caseRows.addAll(
      OpportunitySummaryPayloadHelper.mapListValue(cases.get('open'))
    );
    caseRows.addAll(
      OpportunitySummaryPayloadHelper.mapListValue(cases.get('recentlyClosed'))
    );
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
    Map<String, Object> activities = OpportunitySummaryPayloadHelper.mapValue(
      payload.get('activities')
    );
    for (String objectType : new List<String>{ 'Task', 'Event' }) {
      for (
        Map<String, Object> row : OpportunitySummaryPayloadHelper.mapListValue(
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
      OpportunitySummaryPayloadHelper.mapListValue(
        OpportunitySummaryPayloadHelper.mapValue(
            payload.get('conversationEvidence')
          )
          .get('items')
      )
    );
    participantRows.addAll(
      OpportunitySummaryPayloadHelper.mapListValue(activities.get('tasks'))
    );
    participantRows.addAll(
      OpportunitySummaryPayloadHelper.mapListValue(activities.get('events'))
    );
    for (Map<String, Object> row : participantRows) {
      for (
        Map<String, Object> participant : OpportunitySummaryPayloadHelper.mapListValue(
          row.get('participants')
        )
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
    String label = OpportunitySummaryPayloadHelper.normalizedText(rawLabel);
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
      String label = OpportunitySummaryPayloadHelper.normalizedText(
        reference.get('label')
      );
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
      OpportunitySummaryPayloadHelper.putIfPresent(
        sanitized,
        'case_number',
        OpportunitySummaryPayloadHelper.normalizedText(
          reference.get('case_number')
        )
      );
      OpportunitySummaryPayloadHelper.putIfPresent(
        sanitized,
        'activity_kind',
        OpportunitySummaryPayloadHelper.normalizedText(
          reference.get('activity_kind')
        )
      );
      references.add(sanitized);
    }
    return references;
  }

  private static void putIfText(List<String> target, Object value) {
    String text = OpportunitySummaryPayloadHelper.normalizedText(value);
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
      // Ids in the service response are model output; malformed ones are filtered out.
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

  private static String logAndFail(String context, Exception e) {
    recordFailure(context, e);
    return GCPSummaryUtil.errorReply(userFacingError);
  }

  /*
   * Failures are collected and written once the callout has finished: Salesforce rejects a
   * callout after uncommitted DML, so logging mid-request would break the summary itself.
   */
  @TestVisible
  private static List<PlatformLog__c> pendingFailureLogs = new List<PlatformLog__c>();

  public static void recordFailure(String context, Exception e) {
    pendingFailureLogs.add(
      PlatformLog.buildLog(
        LOG_SOURCE + LOG_CONTEXT_SEPARATOR + context,
        e.getMessage(),
        e.getStackTraceString(),
        null,
        null
      )
    );
  }

  public static void recordFailure(String message) {
    pendingFailureLogs.add(
      PlatformLog.buildLog(LOG_SOURCE, message, null, null, null)
    );
  }

  private static void flushFailureLogs() {
    if (pendingFailureLogs.isEmpty()) {
      return;
    }
    PlatformLog.logResults(pendingFailureLogs);
    pendingFailureLogs = new List<PlatformLog__c>();
  }

  // ---------------- Feature toggle & telemetry ----------------

  public static Boolean isOpportunitySummaryEnrichmentEnabled() {
    GCP_Feature_Toggle__c setting = GCP_Feature_Toggle__c.getInstance();
    Object configuredValue = settingField(setting, ENRICHMENT_SWITCH_FIELD);
    return configuredValue != null &&
      Boolean.valueOf(String.valueOf(configuredValue));
  }

  public static Boolean isOpportunitySummaryCallTranscriptsEnabled() {
    GCP_Feature_Toggle__c setting = GCP_Feature_Toggle__c.getInstance();
    return setting != null &&
      setting.Opportunity_Summary_Call_Transcripts__c == true;
  }

  /* A missing record or blank field falls back to the coded default. */
  private static Object settingValue(Schema.SObjectField field) {
    return SummarySettingHelper.getSetting(SETTING_NAME).get(field);
  }

  public static Integer configuredInteger(
    Schema.SObjectField field,
    Integer fallback,
    Integer maximum
  ) {
    return SummarySettingHelper.positiveInteger(
      (Decimal) settingValue(field),
      fallback,
      maximum
    );
  }

  public static Set<String> configuredList(
    Schema.SObjectField field,
    Set<String> fallback,
    Boolean isDomainList
  ) {
    return parseConfigurationList(
      (String) settingValue(field),
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

  public static Integer getRecentEvidenceLookbackDays() {
    return configuredInteger(
      Summary_Setting__mdt.RecentDays__c,
      DEFAULT_RECENT_EVIDENCE_DAYS,
      MAX_RECENT_EVIDENCE_DAYS
    );
  }

  private static Object settingField(SObject setting, String fieldApiName) {
    if (setting == null || String.isBlank(fieldApiName)) {
      return null;
    }
    Map<String, Schema.SObjectField> fields = setting.getSObjectType()
      .getDescribe()
      .fields.getMap();
    for (String availableField : fields.keySet()) {
      if (availableField.equalsIgnoreCase(fieldApiName)) {
        return setting.get(availableField);
      }
    }
    return null;
  }

  public static Boolean isOpportunitySummaryEnabled() {
    GCP_Feature_Toggle__c setting = GCP_Feature_Toggle__c.getInstance();
    return (setting != null && setting.Enable_Opportunity_Summary__c == true);
  }

  /**
   * Browser-cache settings for the opportunitySummary LWC, keyed CacheHours and CacheMaxKB. The
   * LWC validates each value and keeps its own default for a missing or invalid one.
   */
  public static Map<String, String> getClientSettings() {
    return SummarySettingHelper.toClientSettings(
      SummarySettingHelper.getSetting(SETTING_NAME),
      CLIENT_SETTING_FIELDS
    );
  }
}
