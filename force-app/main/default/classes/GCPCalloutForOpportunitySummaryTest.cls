@IsTest
private class GCPCalloutForOpportunitySummaryTest {
  private static final Id OPPORTUNITY_ID = '006000000000001';
  private static final Id ACCOUNT_ID = '001000000000001';
  private static final Id PRODUCT_ID = '01t000000000001';
  private static final Id LINE_ITEM_ID = '00k000000000001';
  private static final Id TASK_ID = '00T000000000001';
  private static final Id EVENT_ID = '00U000000000001';
  private static final Id CONTACT_ID = '003000000000001';
  private static final Id SECOND_CONTACT_ID = '003000000000002';
  private static final Id USER_ID = '005000000000001';

  @IsTest
  static void taskQueryKeepsNewerCompletionFieldOutOfLegacyQueryFactory() {
    QueryFactory taskQuery = GCPCalloutForOpportunitySummary.buildTaskQuery(
      OPPORTUNITY_ID,
      Datetime.now().addDays(-180)
    );

    String soql = taskQuery.setQuery().getQuery();
    System.assert(soql.contains('IsClosed'));
    System.assertEquals(false, soql.contains('CompletedDateTime'));
  }

  @IsTest
  static void loadsExactTaskCompletionTimeOutsideLegacyQueryFactory() {
    Task completedTask = new Task(
      Subject = 'Completed customer follow-up',
      Status = 'Completed',
      ActivityDate = Date.today()
    );
    insert completedTask;

    List<SObject> taskRows = new List<SObject>{
      new Task(Id = completedTask.Id)
    };
    Map<Id, Datetime> completionTimes = GCPCalloutForOpportunitySummary.loadTaskCompletionTimes(
      taskRows
    );
    System.assertNotEquals(null, completionTimes.get(completedTask.Id));
  }

  @IsTest
  static void featureDisabledPreservesExistingShapes() {
    Opportunity opportunityRecord = opportunityWithAccount(true);
    Map<String, Object> opportunityPayload = GCPCalloutForOpportunitySummary.buildOpportunityMap(
      opportunityRecord,
      false
    );

    System.assertEquals('Example Opportunity', opportunityPayload.get('name'));
    System.assertEquals('Example Co', opportunityPayload.get('accountName'));
    System.assertEquals(
      false,
      opportunityPayload.containsKey('accountWebsite')
    );
    System.assertEquals(false, opportunityPayload.containsKey('accountState'));

    List<Map<String, Object>> lineItems = GCPCalloutForOpportunitySummary.buildLineItemRows(
      new List<SObject>{ lineItemWithProduct(true) },
      false
    );
    System.assertEquals(1, lineItems.size());
    System.assertEquals('Example Product', lineItems[0].get('productName'));
    System.assertEquals(false, lineItems[0].containsKey('productFamily'));
    System.assertEquals(false, lineItems[0].containsKey('productCapabilities'));

    GCPCalloutForOpportunitySummary.activityParticipantProvider = new FailingParticipantProvider();
    try {
      GCPCalloutForOpportunitySummary.ActivityData activityData = GCPCalloutForOpportunitySummary.assembleActivityData(
        new List<SObject>{
          taskRecord(
            TASK_ID,
            CONTACT_ID,
            USER_ID,
            true,
            Datetime.now(),
            'Notes'
          )
        },
        new List<SObject>(),
        new Map<Id, String>(),
        false,
        Datetime.now().addDays(-180),
        Datetime.now(),
        90,
        false,
        false
      );
      System.assertEquals(1, activityData.tasks.size());
      System.assertEquals(
        false,
        activityData.tasks[0].containsKey('sourceRecordId')
      );
      System.assertEquals(
        false,
        activityData.tasks[0].containsKey('participants')
      );
      System.assertEquals(0, activityData.conversations.size());
    } finally {
      resetTestHooks();
    }
  }

  @IsTest
  static void mapsPublicCompanyIdentityAndOmitsUnreadableOptionalFields() {
    Map<String, Object> populated = GCPCalloutForOpportunitySummary.buildOpportunityMap(
      opportunityWithAccount(true),
      true
    );
    System.assertEquals(
      'https://www.example.invalid',
      populated.get('accountWebsite')
    );
    System.assertEquals('California', populated.get('accountState'));

    Map<String, Object> inaccessible = GCPCalloutForOpportunitySummary.buildOpportunityMap(
      opportunityWithAccount(false),
      true
    );
    System.assertEquals(false, inaccessible.containsKey('accountWebsite'));
    System.assertEquals(false, inaccessible.containsKey('accountState'));
  }

  @IsTest
  static void mapsProductFamilyWithoutInventingCapabilities() {
    List<Map<String, Object>> populated = GCPCalloutForOpportunitySummary.buildLineItemRows(
      new List<SObject>{ lineItemWithProduct(true) },
      true
    );
    System.assertEquals('Collaboration', populated[0].get('productFamily'));
    System.assertEquals(false, populated[0].containsKey('productCapabilities'));

    List<Map<String, Object>> unavailable = GCPCalloutForOpportunitySummary.buildLineItemRows(
      new List<SObject>{ lineItemWithProduct(false) },
      true
    );
    System.assertEquals(false, unavailable[0].containsKey('productFamily'));
    System.assertEquals('Example Product', unavailable[0].get('productName'));
  }

  @IsTest
  static void mapsLinkedParticipantsWithoutTreatingOwnerAsCustomer() {
    Task taskRecord = taskRecord(
      TASK_ID,
      null,
      USER_ID,
      true,
      Datetime.now(),
      'Customer task notes'
    );
    Event eventRecord = eventRecord(
      EVENT_ID,
      SECOND_CONTACT_ID,
      USER_ID,
      Datetime.now().addHours(-2),
      Datetime.now().addHours(-1),
      'Customer meeting notes'
    );
    TaskRelation taskRelation = taskRelation(TASK_ID, CONTACT_ID);
    EventRelation eventRelation = eventRelation(EVENT_ID, CONTACT_ID, true);

    List<GCPCalloutForOpportunitySummary.ParticipantEvidence> evidence = GCPCalloutForOpportunitySummary.collectParticipantEvidence(
      new List<SObject>{ taskRecord },
      new List<SObject>{ eventRecord },
      new List<SObject>{ taskRelation },
      new List<SObject>{ eventRelation }
    );
    Map<Id, List<Map<String, Object>>> participants = GCPCalloutForOpportunitySummary.materializeParticipants(
      evidence,
      new List<SObject>{
        contactRecord(CONTACT_ID, 'Avery Customer', 'CIO'),
        contactRecord(SECOND_CONTACT_ID, 'Blake Customer', 'IT Director')
      }
    );

    System.assertEquals(1, participants.get(TASK_ID).size());
    System.assertEquals(
      CONTACT_ID,
      participants.get(TASK_ID)[0].get('contactId'),
      'A TaskRelation contact is included even without an Opportunity Contact Role.'
    );
    System.assertEquals(
      'unknown',
      participants.get(TASK_ID)[0].get('participationStatus')
    );
    System.assertEquals(2, participants.get(EVENT_ID).size());
    System.assertEquals(
      false,
      containsContact(participants, TASK_ID, USER_ID),
      'The Salesforce activity owner must not become a customer participant.'
    );

    Map<String, Object> invitedParticipant = participantByContact(
      participants.get(EVENT_ID),
      CONTACT_ID
    );
    System.assertEquals(
      'invited',
      invitedParticipant.get('participationStatus')
    );
    System.assertNotEquals(
      'attended',
      invitedParticipant.get('participationStatus'),
      'Invitation evidence must not be promoted to attendance.'
    );
    System.assertEquals(
      'EventRelation invitee record',
      invitedParticipant.get('evidenceSource')
    );
  }

  @IsTest
  static void omitsInaccessibleOptionalContactFields() {
    List<GCPCalloutForOpportunitySummary.ParticipantEvidence> evidence = GCPCalloutForOpportunitySummary.collectParticipantEvidence(
      new List<SObject>{
        taskRecord(TASK_ID, CONTACT_ID, USER_ID, true, Datetime.now(), 'Notes')
      },
      new List<SObject>(),
      new List<SObject>(),
      new List<SObject>()
    );
    Map<Id, List<Map<String, Object>>> participants = GCPCalloutForOpportunitySummary.materializeParticipants(
      evidence,
      new List<SObject>{ contactRecord(CONTACT_ID, null, null) }
    );
    Map<String, Object> participant = participants.get(TASK_ID)[0];

    System.assertEquals(CONTACT_ID, participant.get('contactId'));
    System.assertEquals(false, participant.containsKey('name'));
    System.assertEquals(false, participant.containsKey('title'));
  }

  @IsTest
  static void reportsEmptyAndInaccessibleCoverageWithoutClaimingAbsence() {
    Datetime windowEnd = Datetime.now();
    GCPCalloutForOpportunitySummary.ActivityData activityData = new GCPCalloutForOpportunitySummary.ActivityData();
    activityData.activityWindowStart = windowEnd.addDays(-180);
    activityData.activityWindowEnd = windowEnd;
    activityData.conversationWindowStart = windowEnd.addDays(-90);
    activityData.conversationReasonCode = 'transcripts_not_supported_no_recent_notes';

    GCPCalloutForOpportunitySummary.CollectionData stakeholders = new GCPCalloutForOpportunitySummary.CollectionData();
    GCPCalloutForOpportunitySummary.CollectionData lineItems = new GCPCalloutForOpportunitySummary.CollectionData();
    Map<String, Object> emptyCoverage = GCPCalloutForOpportunitySummary.buildDataCoverage(
      activityData,
      stakeholders,
      lineItems
    );
    System.assertEquals(
      'not_found',
      coverageEntry(emptyCoverage, 'lineItems').get('status')
    );

    lineItems.isAccessible = false;

    Map<String, Object> coverage = GCPCalloutForOpportunitySummary.buildDataCoverage(
      activityData,
      stakeholders,
      lineItems
    );
    System.assertEquals(
      'not_found',
      coverageEntry(coverage, 'stakeholders').get('status')
    );
    System.assertEquals(
      'not_found',
      coverageEntry(coverage, 'activities').get('status')
    );
    System.assertEquals(
      'not_found',
      coverageEntry(coverage, 'conversations').get('status')
    );
    System.assertEquals(
      'not_accessible',
      coverageEntry(coverage, 'lineItems').get('status')
    );
    System.assertEquals(
      'transcripts_not_supported_no_recent_notes',
      coverageEntry(coverage, 'conversations').get('reasonCode')
    );
  }

  @IsTest
  static void buildsTraceableDeduplicatedAndTruncatedConversationNotes() {
    Datetime windowEnd = Datetime.now();
    Event meeting = eventRecord(
      EVENT_ID,
      CONTACT_ID,
      USER_ID,
      windowEnd.addHours(-2),
      windowEnd.addHours(-1),
      'n'.repeat(4001)
    );
    Map<Id, List<Map<String, Object>>> participants = participantMap(
      EVENT_ID,
      CONTACT_ID,
      'unknown'
    );

    GCPCalloutForOpportunitySummary.ConversationResult result = GCPCalloutForOpportunitySummary.buildConversationEvidence(
      new List<SObject>(),
      new List<SObject>{ meeting, meeting },
      participants,
      windowEnd.addDays(-90),
      windowEnd
    );

    System.assertEquals(
      1,
      result.items.size(),
      'Duplicate source records are removed.'
    );
    Map<String, Object> item = result.items[0];
    System.assertEquals(EVENT_ID, item.get('sourceRecordId'));
    System.assertEquals(EVENT_ID, item.get('relatedActivityId'));
    System.assertEquals('Event', item.get('sourceType'));
    System.assertEquals('notes', item.get('contentType'));
    System.assertEquals(4000, ((String) item.get('text')).length());
    System.assertEquals(true, item.get('isTruncated'));
    System.assertEquals(true, result.isTruncated);
    System.assertEquals('text_limit', result.reasonCode);
  }

  @IsTest
  static void enforcesConversationCountAndCompletedActivityRules() {
    Datetime windowEnd = Datetime.now();
    List<SObject> tasks = new List<SObject>();
    Map<Id, List<Map<String, Object>>> participants = new Map<Id, List<Map<String, Object>>>();
    for (Integer i = 1; i <= 11; i++) {
      Id taskId = syntheticId('00T', i);
      tasks.add(
        taskRecord(
          taskId,
          CONTACT_ID,
          USER_ID,
          true,
          windowEnd.addHours(-i),
          'Complete conversation note ' + i
        )
      );
      participants.put(
        taskId,
        participantMap(taskId, CONTACT_ID, 'unknown').get(taskId)
      );
    }
    Id openTaskId = syntheticId('00T', 20);
    tasks.add(
      taskRecord(
        openTaskId,
        CONTACT_ID,
        USER_ID,
        false,
        null,
        'Scheduled work is not a completed conversation.'
      )
    );
    participants.put(
      openTaskId,
      participantMap(openTaskId, CONTACT_ID, 'unknown').get(openTaskId)
    );

    GCPCalloutForOpportunitySummary.ConversationResult result = GCPCalloutForOpportunitySummary.buildConversationEvidence(
      tasks,
      new List<SObject>(),
      participants,
      windowEnd.addDays(-90),
      windowEnd
    );

    System.assertEquals(10, result.items.size());
    System.assertEquals(true, result.isTruncated);
    System.assertEquals('item_limit', result.reasonCode);
  }

  @IsTest
  static void optionalParticipantFailurePreservesCoreActivities() {
    Datetime windowEnd = Datetime.now();
    GCPCalloutForOpportunitySummary.activityParticipantProvider = new FailingParticipantProvider();
    try {
      GCPCalloutForOpportunitySummary.ActivityData data = GCPCalloutForOpportunitySummary.assembleActivityData(
        new List<SObject>{
          taskRecord(
            TASK_ID,
            CONTACT_ID,
            USER_ID,
            true,
            windowEnd.addHours(-1),
            'Notes remain in the core activity.'
          )
        },
        new List<SObject>(),
        new Map<Id, String>(),
        true,
        windowEnd.addDays(-180),
        windowEnd,
        90,
        false,
        false
      );

      System.assertEquals(1, data.tasks.size());
      System.assertEquals(TASK_ID, data.tasks[0].get('sourceRecordId'));
      System.assertEquals(
        0,
        ((List<Map<String, Object>>) data.tasks[0].get('participants')).size()
      );
      System.assertEquals('error', data.participantStatus);
      System.assertEquals('error', data.conversationStatus);
      System.assertEquals(0, data.conversations.size());

      Map<String, Object> coverage = GCPCalloutForOpportunitySummary.buildDataCoverage(
        data,
        new GCPCalloutForOpportunitySummary.CollectionData(),
        new GCPCalloutForOpportunitySummary.CollectionData()
      );
      System.assertEquals(
        'error',
        coverageEntry(coverage, 'conversations').get('status')
      );
    } finally {
      resetTestHooks();
    }
  }

  @IsTest
  static void trimsConversationEvidenceBeforeRejectingOversizedCorePayload() {
    GCPCalloutForOpportunitySummary.requestSizeLimitBytes = 600;
    try {
      Map<String, Object> payload = new Map<String, Object>{
        'username' => 'fictional@example.invalid',
        'core' => 'c'.repeat(100),
        'conversationEvidence' => new Map<String, Object>{
          'items' => new List<Map<String, Object>>{
            new Map<String, Object>{ 'text' => 'a'.repeat(350) },
            new Map<String, Object>{ 'text' => 'b'.repeat(350) }
          }
        },
        'dataCoverage' => new Map<String, Object>{
          'conversations' => new Map<String, Object>{
            'status' => 'available',
            'returnedCount' => 2,
            'isTruncated' => false
          }
        }
      };

      String serialized = GCPCalloutForOpportunitySummary.serializePayloadWithinLimit(
        payload
      );
      System.assert(Blob.valueOf(serialized).size() < 600);
      Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(
        serialized
      );
      Map<String, Object> coverage = (Map<String, Object>) parsed.get(
        'dataCoverage'
      );
      Map<String, Object> conversations = (Map<String, Object>) coverage.get(
        'conversations'
      );
      System.assertEquals(true, conversations.get('isTruncated'));
      System.assertEquals(
        'request_size_limit',
        conversations.get('reasonCode')
      );

      Map<String, Object> participantPayload = new Map<String, Object>{
        'core' => 'core',
        'conversationEvidence' => new Map<String, Object>{
          'items' => new List<Map<String, Object>>()
        },
        'activities' => new Map<String, Object>{
          'tasks' => new List<Map<String, Object>>{
            new Map<String, Object>{
              'subject' => 'Customer follow-up',
              'participants' => new List<Map<String, Object>>{
                new Map<String, Object>{ 'name' => 'p'.repeat(700) }
              }
            }
          },
          'events' => new List<Map<String, Object>>()
        },
        'dataCoverage' => new Map<String, Object>{
          'activities' => new Map<String, Object>{
            'status' => 'available',
            'returnedCount' => 1,
            'isTruncated' => false
          },
          'conversations' => new Map<String, Object>{
            'status' => 'not_found',
            'returnedCount' => 0,
            'isTruncated' => false
          }
        }
      };
      String participantTrimmed = GCPCalloutForOpportunitySummary.serializePayloadWithinLimit(
        participantPayload
      );
      Map<String, Object> participantParsed = (Map<String, Object>) JSON.deserializeUntyped(
        participantTrimmed
      );
      Map<String, Object> parsedActivities = (Map<String, Object>) participantParsed.get(
        'activities'
      );
      List<Object> parsedTasks = (List<Object>) parsedActivities.get('tasks');
      Map<String, Object> parsedTask = (Map<String, Object>) parsedTasks[0];
      System.assertEquals(
        0,
        ((List<Object>) parsedTask.get('participants')).size()
      );
      Map<String, Object> participantCoverage = (Map<String, Object>) participantParsed.get(
        'dataCoverage'
      );
      System.assertEquals(
        'request_size_limit',
        ((Map<String, Object>) participantCoverage.get('activities'))
          .get('reasonCode')
      );

      payload.put('core', 'x'.repeat(700));
      payload.put(
        'conversationEvidence',
        new Map<String, Object>{ 'items' => new List<Map<String, Object>>() }
      );
      try {
        GCPCalloutForOpportunitySummary.serializePayloadWithinLimit(payload);
        System.assert(false, 'An oversized core payload must fail explicitly.');
      } catch (Exception expected) {
        System.assert(expected.getMessage().contains('core request exceeds'));
      }
    } finally {
      resetTestHooks();
    }
  }

  @IsTest
  static void featureSettingDefaultsOffAndConfiguresRecentWindow() {
    GCP_Feature_Toggle__c setting = new GCP_Feature_Toggle__c(
      SetupOwnerId = UserInfo.getOrganizationId()
    );
    setting.put('Enable_Opportunity_Summary_Enrichment__c', false);
    setting.put('Opportunity_Summary_Recent_Days__c', 0);
    insert setting;

    System.assertEquals(
      false,
      GCPCalloutForOpportunitySummary.isOpportunitySummaryEnrichmentEnabled()
    );
    System.assertEquals(
      90,
      GCPCalloutForOpportunitySummary.getRecentEvidenceLookbackDays()
    );

    setting.put('Enable_Opportunity_Summary_Enrichment__c', true);
    setting.put('Opportunity_Summary_Recent_Days__c', 45);
    update setting;
    System.assertEquals(
      true,
      GCPCalloutForOpportunitySummary.isOpportunitySummaryEnrichmentEnabled()
    );
    System.assertEquals(
      45,
      GCPCalloutForOpportunitySummary.getRecentEvidenceLookbackDays()
    );
  }

  @IsTest
  static void sendsEnrichmentSettingToGcpAsBooleanControl() {
    Map<String, Object> payload = new Map<String, Object>();

    GCPCalloutForOpportunitySummary.addEnrichmentRequestControl(payload, false);
    System.assertEquals(
      false,
      payload.get('enableOpportunitySummaryEnrichment')
    );

    GCPCalloutForOpportunitySummary.addEnrichmentRequestControl(payload, true);
    System.assertEquals(
      true,
      payload.get('enableOpportunitySummaryEnrichment')
    );
  }

  @IsTest
  static void retainsExactOpportunitySummaryEndpoint() {
    System.assertEquals(
      'https://service.example.invalid/api/v1/opportunity_summary',
      GCPCalloutForOpportunitySummary.buildServiceEndpoint(
        'https://service.example.invalid/api/v1/another_route'
      )
    );
  }

  @IsTest
  static void legacyResponseRemainsBackwardCompatibleWithoutEnrichment() {
    Object raw = JSON.deserializeUntyped(
      '{"statusCode":200,"body":{"opportunity_summary":{"Executive Summary":["CRM summary"]}}}'
    );

    Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(
      GCPCalloutForOpportunitySummary.buildResult(raw)
    );

    System.assertEquals(true, result.get('success'));
    System.assertEquals(1, ((List<Object>) result.get('cards')).size());
    System.assertEquals(
      false,
      result.containsKey('opportunity_enrichment'),
      'The optional field must remain absent for legacy responses.'
    );
  }

  @IsTest
  static void passesOptionalEnrichmentThroughWithSnakeCaseFields() {
    Object raw = JSON.deserializeUntyped(
      '{"statusCode":200,"body":{' +
        '"opportunity_summary":{"Executive Summary":["Research-backed summary. [E1]"]},' +
        '"opportunity_enrichment":{' +
        '"findings":[{"id":"E1","kind":"leadership","fact":"Public fact","source_indices":[7]}],' +
        '"supplemental_company_updates":{' +
        '"relationship_to_opportunity":"not_established",' +
        '"items":[{"id":"E2","kind":"leadership","fact":"Supplemental public fact","source_indices":[8]}]' +
        '},' +
        '"sources":[{"index":7,"display_label":"example.com","url":"https://example.com"}],' +
        '"web_search_queries":["example leadership"],' +
        '"search_entry_point":{"rendered_content":"<style>.chip{}</style><a href=\\"https://google.com\\">Search</a>"}' +
        '}}}'
    );

    Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(
      GCPCalloutForOpportunitySummary.buildResult(raw)
    );
    Map<String, Object> enrichment = (Map<String, Object>) result.get(
      'opportunity_enrichment'
    );
    Map<String, Object> finding = (Map<String, Object>) ((List<Object>) enrichment.get(
      'findings'
    ))[0];
    Map<String, Object> searchEntryPoint = (Map<String, Object>) enrichment.get(
      'search_entry_point'
    );
    Map<String, Object> supplementalUpdates = (Map<String, Object>) enrichment.get(
      'supplemental_company_updates'
    );
    Map<String, Object> supplementalItem = (Map<String, Object>) ((List<Object>) supplementalUpdates.get(
      'items'
    ))[0];

    System.assertEquals(true, result.get('success'));
    System.assertEquals(7, ((List<Object>) finding.get('source_indices'))[0]);
    System.assertEquals(
      'not_established',
      supplementalUpdates.get('relationship_to_opportunity')
    );
    System.assertEquals('E2', supplementalItem.get('id'));
    System.assertEquals(
      8,
      ((List<Object>) supplementalItem.get('source_indices'))[0]
    );
    System.assertEquals(
      '<style>.chip{}</style><a href="https://google.com">Search</a>',
      searchEntryPoint.get('rendered_content')
    );
  }

  @IsTest
  static void malformedOptionalEnrichmentDoesNotInvalidateSummary() {
    Object raw = JSON.deserializeUntyped(
      '{"statusCode":200,"body":{"opportunity_summary":{"Risk Flags":["CRM risk"]},"opportunity_enrichment":["invalid"]}}'
    );

    Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(
      GCPCalloutForOpportunitySummary.buildResult(raw)
    );

    System.assertEquals(true, result.get('success'));
    System.assertEquals(1, ((List<Object>) result.get('cards')).size());
    System.assertEquals(false, result.containsKey('opportunity_enrichment'));
  }

  private static Opportunity opportunityWithAccount(Boolean includeOptional) {
    Map<String, Object> accountFields = new Map<String, Object>{
      'attributes' => new Map<String, Object>{ 'type' => 'Account' },
      'Id' => ACCOUNT_ID,
      'Name' => 'Example Co',
      'Industry' => 'Technology',
      'BillingCity' => 'San Mateo',
      'BillingCountry' => 'United States'
    };
    if (includeOptional) {
      accountFields.put('Website', 'https://www.example.invalid');
      accountFields.put('BillingState', 'California');
    }
    Map<String, Object> opportunityFields = new Map<String, Object>{
      'attributes' => new Map<String, Object>{ 'type' => 'Opportunity' },
      'Id' => OPPORTUNITY_ID,
      'Name' => 'Example Opportunity',
      'AccountId' => ACCOUNT_ID,
      'Account' => accountFields
    };
    return (Opportunity) JSON.deserialize(
      JSON.serialize(opportunityFields),
      Opportunity.class
    );
  }

  private static OpportunityLineItem lineItemWithProduct(
    Boolean includeFamily
  ) {
    Map<String, Object> productFields = new Map<String, Object>{
      'attributes' => new Map<String, Object>{ 'type' => 'Product2' },
      'Id' => PRODUCT_ID,
      'Name' => 'Example Product'
    };
    if (includeFamily) {
      productFields.put('Family', 'Collaboration');
    }
    Map<String, Object> lineItemFields = new Map<String, Object>{
      'attributes' => new Map<String, Object>{
        'type' => 'OpportunityLineItem'
      },
      'Id' => LINE_ITEM_ID,
      'Name' => 'Example Product',
      'Product2Id' => PRODUCT_ID,
      'Quantity' => 25,
      'UnitPrice' => 20,
      'TotalPrice' => 500,
      'Discount' => 10,
      'Description' => 'Commercial description',
      'Product2' => productFields
    };
    return (OpportunityLineItem) JSON.deserialize(
      JSON.serialize(lineItemFields),
      OpportunityLineItem.class
    );
  }

  private static Task taskRecord(
    Id taskId,
    Id whoId,
    Id ownerId,
    Boolean isClosed,
    Datetime completedDateTime,
    String description
  ) {
    Map<String, Object> fields = new Map<String, Object>{
      'attributes' => new Map<String, Object>{ 'type' => 'Task' },
      'Id' => taskId,
      'WhoId' => whoId,
      'OwnerId' => ownerId,
      'Subject' => 'Customer follow-up',
      'Status' => isClosed ? 'Completed' : 'Not Started',
      'IsClosed' => isClosed,
      'ActivityDate' => Date.today(),
      'CreatedDate' => Datetime.now().addDays(-1),
      'CompletedDateTime' => completedDateTime,
      'Description' => description
    };
    return (Task) JSON.deserialize(JSON.serialize(fields), Task.class);
  }

  private static Event eventRecord(
    Id eventId,
    Id whoId,
    Id ownerId,
    Datetime startDateTime,
    Datetime endDateTime,
    String description
  ) {
    Map<String, Object> fields = new Map<String, Object>{
      'attributes' => new Map<String, Object>{ 'type' => 'Event' },
      'Id' => eventId,
      'WhoId' => whoId,
      'OwnerId' => ownerId,
      'Subject' => 'Customer meeting',
      'StartDateTime' => startDateTime,
      'EndDateTime' => endDateTime,
      'CreatedDate' => Datetime.now().addDays(-1),
      'Description' => description
    };
    return (Event) JSON.deserialize(JSON.serialize(fields), Event.class);
  }

  private static TaskRelation taskRelation(Id taskId, Id contactId) {
    return (TaskRelation) JSON.deserialize(
      JSON.serialize(
        new Map<String, Object>{
          'attributes' => new Map<String, Object>{ 'type' => 'TaskRelation' },
          'TaskId' => taskId,
          'RelationId' => contactId,
          'IsWhat' => false
        }
      ),
      TaskRelation.class
    );
  }

  private static EventRelation eventRelation(
    Id eventId,
    Id contactId,
    Boolean isInvitee
  ) {
    return (EventRelation) JSON.deserialize(
      JSON.serialize(
        new Map<String, Object>{
          'attributes' => new Map<String, Object>{ 'type' => 'EventRelation' },
          'EventId' => eventId,
          'RelationId' => contactId,
          'IsInvitee' => isInvitee
        }
      ),
      EventRelation.class
    );
  }

  private static Contact contactRecord(
    Id contactId,
    String name,
    String title
  ) {
    Map<String, Object> fields = new Map<String, Object>{
      'attributes' => new Map<String, Object>{ 'type' => 'Contact' },
      'Id' => contactId
    };
    if (name != null) {
      fields.put('Name', name);
    }
    if (title != null) {
      fields.put('Title', title);
    }
    return (Contact) JSON.deserialize(JSON.serialize(fields), Contact.class);
  }

  private static Map<Id, List<Map<String, Object>>> participantMap(
    Id activityId,
    Id contactId,
    String status
  ) {
    return new Map<Id, List<Map<String, Object>>>{
      activityId => new List<Map<String, Object>>{
        new Map<String, Object>{
          'contactId' => contactId,
          'name' => 'Fictional Customer',
          'title' => 'CIO',
          'participationStatus' => status,
          'evidenceSource' => 'Test relationship'
        }
      }
    };
  }

  private static Boolean containsContact(
    Map<Id, List<Map<String, Object>>> participants,
    Id activityId,
    Id contactId
  ) {
    return participantByContact(participants.get(activityId), contactId) !=
      null;
  }

  private static Map<String, Object> participantByContact(
    List<Map<String, Object>> participants,
    Id contactId
  ) {
    if (participants == null) {
      return null;
    }
    for (Map<String, Object> participant : participants) {
      if (participant.get('contactId') == contactId) {
        return participant;
      }
    }
    return null;
  }

  private static Map<String, Object> coverageEntry(
    Map<String, Object> coverage,
    String key
  ) {
    return (Map<String, Object>) coverage.get(key);
  }

  private static Id syntheticId(String prefix, Integer sequence) {
    return Id.valueOf(prefix + String.valueOf(sequence).leftPad(12, '0'));
  }

  private static void resetTestHooks() {
    GCPCalloutForOpportunitySummary.activityParticipantProvider = new GCPCalloutForOpportunitySummary.ActivityParticipantProvider();
    GCPCalloutForOpportunitySummary.requestSizeLimitBytes = 2 * 1024 * 1024;
  }

  private class FailingParticipantProvider extends GCPCalloutForOpportunitySummary.ActivityParticipantProvider {
    public override GCPCalloutForOpportunitySummary.ActivityParticipantResult load(
      List<SObject> tasks,
      List<SObject> events
    ) {
      throw new OptionalSourceException();
    }
  }

  private class OptionalSourceException extends Exception {
  }
}
