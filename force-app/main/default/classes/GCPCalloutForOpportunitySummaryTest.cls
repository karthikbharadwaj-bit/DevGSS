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
  static void shouldOrderRelatedOpportunitiesByCloseDateWhenLimiting() {
    Test.startTest();
    String soql = GCPCalloutForOpportunitySummary.buildRelatedOpportunitiesQuery(
        ACCOUNT_ID,
        OPPORTUNITY_ID
      )
      .setQuery()
      .getQuery();
    Test.stopTest();

    System.assert(
      soql.contains('ORDER BY CloseDate DESC NULLS FIRST'),
      'The most recent close dates must survive the limit: ' + soql
    );
    System.assert(soql.contains('LIMIT 25'), soql);
    System.assertEquals(
      false,
      soql.contains('Name ASC'),
      'The selector default Name ordering must not lead the ORDER BY.'
    );
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
    System.assertEquals(false, lineItems[0].containsKey('productLine'));
    System.assertEquals(false, lineItems[0].containsKey('productSubgroup'));
    System.assertEquals(false, lineItems[0].containsKey('productGroup'));
    System.assertEquals(false, lineItems[0].containsKey('productDescription'));
    System.assertEquals(
      false,
      lineItems[0].containsKey('productCatalogDescription')
    );
    System.assertEquals(false, lineItems[0].containsKey('productCategoryName'));
    System.assertEquals(false, lineItems[0].containsKey('licenseGroups'));
    System.assertEquals(false, lineItems[0].containsKey('serviceCategory'));
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
      'https://www.example.com',
      populated.get('accountWebsite')
    );
    System.assertEquals('Technology', populated.get('accountIndustry'));
    System.assertEquals('United States', populated.get('accountCountry'));
    System.assertEquals('California', populated.get('accountState'));

    Map<String, Object> inaccessible = GCPCalloutForOpportunitySummary.buildOpportunityMap(
      opportunityWithAccount(false),
      true
    );
    System.assertEquals(false, inaccessible.containsKey('accountWebsite'));
    System.assertEquals(false, inaccessible.containsKey('accountState'));
  }

  @IsTest
  static void mapsCampaignDerivedProductAndValidatedWebsiteFallback() {
    Opportunity fallbackOpportunity = opportunityWithIdentity(
      ' Example Co ',
      null,
      'https://research.example.com/company?tracking=1#overview',
      ' RingCX '
    );
    Map<String, Object> fallback = GCPCalloutForOpportunitySummary.buildOpportunityMap(
      fallbackOpportunity,
      true
    );

    System.assertEquals('Example Co', fallback.get('accountName'));
    System.assertEquals('RingCX', fallback.get('intendedProduct'));
    System.assertEquals(
      'https://research.example.com/company',
      fallback.get('accountWebsite')
    );

    Opportunity accountWebsitePreferred = opportunityWithIdentity(
      'Example Co',
      'https://official.example.com/about?source=crm#company',
      'https://fallback.example.com',
      null
    );
    Map<String, Object> preferred = GCPCalloutForOpportunitySummary.buildOpportunityMap(
      accountWebsitePreferred,
      true
    );
    System.assertEquals(
      'https://official.example.com/about',
      preferred.get('accountWebsite')
    );
    System.assertEquals(false, preferred.containsKey('intendedProduct'));

    Opportunity invalidAccountWebsite = opportunityWithIdentity(
      'Example Co',
      'javascript:alert(1)',
      'https://fallback.example.com',
      null
    );
    Map<String, Object> invalid = GCPCalloutForOpportunitySummary.buildOpportunityMap(
      invalidAccountWebsite,
      true
    );
    System.assertEquals(
      false,
      invalid.containsKey('accountWebsite'),
      'Opportunity.Website__c is used only when Account.Website is blank.'
    );
  }

  @IsTest
  static void disablesOnlyEnrichmentForUnresolvedCompanyIdentity() {
    Opportunity placeholder = opportunityWithIdentity(
      ' NEW COMPANY ',
      null,
      null,
      null
    );
    System.assertEquals(
      false,
      GCPCalloutForOpportunitySummary.effectiveEnrichmentEnabled(
        true,
        placeholder
      )
    );
    Map<String, Object> placeholderPayload = GCPCalloutForOpportunitySummary.buildOpportunityMap(
      placeholder,
      false
    );
    System.assertEquals('Example Opportunity', placeholderPayload.get('name'));
    System.assertEquals(false, placeholderPayload.containsKey('accountName'));

    Opportunity genericDomainWithoutWebsite = opportunityWithIdentity(
      'yahoo.com',
      null,
      null,
      null
    );
    System.assertEquals(
      false,
      GCPCalloutForOpportunitySummary.effectiveEnrichmentEnabled(
        true,
        genericDomainWithoutWebsite
      )
    );

    Opportunity genericDomainWithWebsite = opportunityWithIdentity(
      'yahoo.com',
      'https://verified-company.example.com',
      null,
      null
    );
    System.assertEquals(
      true,
      GCPCalloutForOpportunitySummary.effectiveEnrichmentEnabled(
        true,
        genericDomainWithWebsite
      )
    );
    System.assertEquals(
      false,
      GCPCalloutForOpportunitySummary.effectiveEnrichmentEnabled(
        false,
        genericDomainWithWebsite
      ),
      'Company identity must never override the configured feature toggle.'
    );
  }

  @IsTest
  static void rejectsPrivateCredentialedAndNonHttpWebsites() {
    System.assertEquals(
      null,
      GCPCalloutForOpportunitySummary.sanitizedPublicWebsite(
        'https://user:secret@example.com'
      )
    );
    System.assertEquals(
      null,
      GCPCalloutForOpportunitySummary.sanitizedPublicWebsite(
        'http://192.168.1.10/internal'
      )
    );
    System.assertEquals(
      null,
      GCPCalloutForOpportunitySummary.sanitizedPublicWebsite(
        'ftp://example.com/file'
      )
    );
    System.assertEquals(
      'https://www.example.com/public',
      GCPCalloutForOpportunitySummary.sanitizedPublicWebsite(
        ' https://www.example.com/public?token=removed#section '
      )
    );
  }

  @IsTest
  static void mapsProductCatalogContextWithoutInventingCapabilities() {
    List<Map<String, Object>> populated = GCPCalloutForOpportunitySummary.buildLineItemRows(
      new List<SObject>{ lineItemWithProductContext() },
      true
    );
    System.assertEquals('Service', populated[0].get('productFamily'));
    System.assertEquals('Contact Center', populated[0].get('productLine'));
    System.assertEquals('[210] Main', populated[0].get('productSubgroup'));
    System.assertEquals('[200] Services', populated[0].get('productGroup'));
    System.assertEquals(
      'Customer-facing product description',
      populated[0].get('productDescription')
    );
    System.assertEquals(
      1001,
      ((String) populated[0].get('productCatalogDescription')).length(),
      'The existing text limit applies to catalogue descriptions.'
    );
    System.assertEquals(
      'Collaboration Services',
      populated[0].get('productCategoryName')
    );
    System.assertEquals(
      new List<String>{ 'Core Licenses', 'Digital Lines' },
      (List<String>) populated[0].get('licenseGroups')
    );
    System.assertEquals('OFFICE_LICENSE', populated[0].get('serviceCategory'));
    System.assertEquals(false, populated[0].containsKey('productCapabilities'));

    List<Map<String, Object>> unavailable = GCPCalloutForOpportunitySummary.buildLineItemRows(
      new List<SObject>{ lineItemWithProduct(false) },
      true
    );
    System.assertEquals(false, unavailable[0].containsKey('productFamily'));
    System.assertEquals(false, unavailable[0].containsKey('productLine'));
    System.assertEquals(false, unavailable[0].containsKey('productSubgroup'));
    System.assertEquals(false, unavailable[0].containsKey('productGroup'));
    System.assertEquals(
      false,
      unavailable[0].containsKey('productDescription')
    );
    System.assertEquals(
      false,
      unavailable[0].containsKey('productCatalogDescription')
    );
    System.assertEquals(
      false,
      unavailable[0].containsKey('productCategoryName')
    );
    System.assertEquals(false, unavailable[0].containsKey('licenseGroups'));
    System.assertEquals(false, unavailable[0].containsKey('serviceCategory'));
    System.assertEquals('Example Product', unavailable[0].get('productName'));

    List<Map<String, Object>> inactiveFamily = GCPCalloutForOpportunitySummary.buildLineItemRows(
      new List<SObject>{ lineItemWithProductValues('Overage', ' Main ') },
      true
    );
    System.assertEquals(
      false,
      inactiveFamily[0].containsKey('productFamily'),
      'Inactive or historical family values are not promoted into research context.'
    );
    System.assertEquals('Main', inactiveFamily[0].get('productLine'));
  }

  @IsTest
  static void mapsMultipleLineItemsWithoutQueriesInTheLoop() {
    Integer queriesBefore = Limits.getQueries();
    List<Map<String, Object>> rows = GCPCalloutForOpportunitySummary.buildLineItemRows(
      new List<SObject>{
        lineItemWithProductContext(),
        lineItemWithProductValues('Service', 'Main')
      },
      true
    );

    System.assertEquals(2, rows.size());
    System.assertEquals('Contact Center', rows[0].get('productLine'));
    System.assertEquals('Main', rows[1].get('productLine'));
    System.assertEquals(queriesBefore, Limits.getQueries());
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
  private static void shouldUseLabelWindowWhenLegacySettingDiffers() {
    GCP_Feature_Toggle__c setting = new GCP_Feature_Toggle__c(
      SetupOwnerId = UserInfo.getOrganizationId()
    );
    setting.put('Enable_Opportunity_Summary_Enrichment__c', false);
    setting.put('Opportunity_Summary_Recent_Days__c', 45);
    insert setting;
    GCPCalloutForOpportunitySummary.configurationOverrides.put(
      'RecentDays',
      '30'
    );
    String labelMessage = 'The recent evidence label must supersede the legacy setting.';
    String toggleMessage = 'Enrichment enablement must still honor the existing feature setting.';

    Test.startTest();
    System.assertEquals(
      30,
      GCPCalloutForOpportunitySummary.getRecentEvidenceLookbackDays(),
      labelMessage
    );
    System.assertEquals(
      false,
      GCPCalloutForOpportunitySummary.isOpportunitySummaryEnrichmentEnabled(),
      toggleMessage
    );
    setting.put('Enable_Opportunity_Summary_Enrichment__c', true);
    update setting;
    System.assertEquals(
      true,
      GCPCalloutForOpportunitySummary.isOpportunitySummaryEnrichmentEnabled(),
      toggleMessage
    );
    GCPCalloutForOpportunitySummary.configurationOverrides.put(
      'RecentDays',
      '366'
    );
    System.assertEquals(
      90,
      GCPCalloutForOpportunitySummary.getRecentEvidenceLookbackDays(),
      'Invalid lookback must use the default.'
    );
    Test.stopTest();
    resetTestHooks();
  }

  @IsTest
  private static void shouldUseDefaultsWhenNumericLabelsAreInvalid() {
    String fallbackMessage = 'Malformed or unsafe numeric configuration must use the default.';
    Test.startTest();
    for (
      String raw : new List<String>{
        null,
        '',
        ' ',
        '0',
        '-1',
        '1.5',
        '51',
        '50 days',
        '1e1',
        '999999999999999999'
      }
    ) {
      System.assertEquals(
        50,
        GCPCalloutForOpportunitySummary.parsePositiveInteger(raw, 50, 50),
        fallbackMessage
      );
    }
    System.assertEquals(
      1,
      GCPCalloutForOpportunitySummary.parsePositiveInteger(' 1 ', 50, 50),
      'The lower bound must be accepted.'
    );
    System.assertEquals(
      50,
      GCPCalloutForOpportunitySummary.parsePositiveInteger('50', 50, 50),
      'The upper bound must be accepted.'
    );
    System.assertEquals(
      15,
      GCPCalloutForOpportunitySummary.parsePositiveInteger('15', 50, 50),
      'A lower valid cap must be accepted.'
    );
    Test.stopTest();
  }

  @IsTest
  private static void shouldNormalizeListsAndPreserveFallbackWhenMalformed() {
    Set<String> fallback = new Set<String>{ 'GMAIL.COM' };
    String fallbackMessage = 'Invalid domain configuration must retain the safe fallback.';
    Test.startTest();
    System.assertEquals(
      new Set<String>{ 'example.com', 'mail.example.org' },
      GCPCalloutForOpportunitySummary.parseConfigurationList(
        ' Example.com\n\nMAIL.EXAMPLE.ORG\r\nexample.com ',
        fallback,
        true
      ),
      'Lists must normalize case and whitespace and remove duplicates.'
    );
    System.assertEquals(
      new Set<String>{ 'gmail.com' },
      GCPCalloutForOpportunitySummary.parseConfigurationList(
        '  ',
        fallback,
        true
      ),
      fallbackMessage
    );
    System.assertEquals(
      new Set<String>{ 'gmail.com' },
      GCPCalloutForOpportunitySummary.parseConfigurationList(
        'example.com\nhttps://unsafe.example.com',
        fallback,
        true
      ),
      fallbackMessage
    );
    Test.stopTest();
  }

  @IsTest
  private static void shouldApplyConfiguredIdentityExclusions() {
    GCPCalloutForOpportunitySummary.configurationOverrides.put(
      'UnresolvedNames',
      ' Placeholder Customer\nPLACEHOLDER CUSTOMER '
    );
    GCPCalloutForOpportunitySummary.configurationOverrides.put(
      'GenericEmailDomains',
      'personal.example'
    );
    Test.startTest();
    System.assertEquals(
      false,
      GCPCalloutForOpportunitySummary.effectiveEnrichmentEnabled(
        true,
        opportunityWithIdentity('placeholder customer', null, null, null)
      ),
      'Configured placeholder names must disable enrichment.'
    );
    System.assertEquals(
      false,
      GCPCalloutForOpportunitySummary.effectiveEnrichmentEnabled(
        true,
        opportunityWithIdentity('personal.example', null, null, null)
      ),
      'Configured generic domains must require a company website.'
    );
    System.assertEquals(
      true,
      GCPCalloutForOpportunitySummary.effectiveEnrichmentEnabled(
        true,
        opportunityWithIdentity(
          'personal.example',
          'https://company.example',
          null,
          null
        )
      ),
      'A usable website must retain the existing identity behavior.'
    );
    Test.stopTest();
    resetTestHooks();
  }

  @IsTest
  private static void shouldApplyConfiguredActivityAndConversationCaps() {
    GCPCalloutForOpportunitySummary.configurationOverrides.put(
      'MaxActivities',
      '4'
    );
    GCPCalloutForOpportunitySummary.configurationOverrides.put(
      'MaxConversationItems',
      '1'
    );
    Datetime windowEnd = Datetime.now();
    List<SObject> tasks = new List<SObject>();
    Map<Id, List<Map<String, Object>>> participants = new Map<Id, List<Map<String, Object>>>();
    for (Integer sequence = 1; sequence <= 2; sequence++) {
      Id taskId = syntheticId('00T', sequence);
      tasks.add(
        taskRecord(
          taskId,
          CONTACT_ID,
          USER_ID,
          true,
          windowEnd.addHours(-sequence),
          'Customer discussion'
        )
      );
      participants.put(
        taskId,
        participantMap(taskId, CONTACT_ID, 'unknown').get(taskId)
      );
    }
    Test.startTest();
    String query = GCPCalloutForOpportunitySummary.buildTaskQuery(
        OPPORTUNITY_ID,
        windowEnd.addDays(-30)
      )
      .setQuery()
      .getQuery();
    GCPCalloutForOpportunitySummary.ConversationResult result = GCPCalloutForOpportunitySummary.buildConversationEvidence(
      tasks,
      new List<SObject>(),
      participants,
      windowEnd.addDays(-30),
      windowEnd
    );
    Test.stopTest();
    System.assert(
      query.toLowerCase().contains('limit 5'),
      'Query must request the configured cap plus one overflow row.'
    );
    System.assertEquals(
      1,
      result.items.size(),
      'Conversation cap must come from the label.'
    );
    System.assertEquals(
      true,
      result.isTruncated,
      'Coverage must still report truncation under configured caps.'
    );
    resetTestHooks();
  }

  @IsTest
  private static void shouldApplyLabelLimitsToOutgoingRequest() {
    new SObjectBuilder(ByPassTrigger__c.SObjectType)
      .setField(ByPassTrigger__c.SetupOwnerId, UserInfo.getOrganizationId())
      .setField(ByPassTrigger__c.Bypass_Account_Trigger__c, true)
      .setField(ByPassTrigger__c.Bypass_Opportunity_Trigger__c, true)
      .create();
    new SObjectBuilder(GCP_Feature_Toggle__c.SObjectType)
      .setField(
        GCP_Feature_Toggle__c.SetupOwnerId,
        UserInfo.getOrganizationId()
      )
      .setField(
        GCP_Feature_Toggle__c.Enable_Opportunity_Summary_Enrichment__c,
        true
      )
      .create();
    Account account = (Account) new SObjectBuilder(Account.SObjectType)
      .setField(
        Account.Name,
        ValueProviderBuilder.provideUniqueString('Summary company')
      )
      .setField(Account.Website, 'https://example.com')
      .create()
      .getRecord();
    List<Opportunity> opportunities = (List<Opportunity>) new SObjectBuilder(
        Opportunity.SObjectType
      )
      .setField(Opportunity.AccountId, account.Id)
      .setField(Opportunity.CloseDate, Date.today().addDays(30))
      .quantity(3)
      .create()
      .getRecords();
    Opportunity opportunity = opportunities[0];
    new SObjectBuilder(Task.SObjectType)
      .setField(Task.WhatId, opportunity.Id)
      .setField(
        Task.Subject,
        ValueProviderBuilder.provideUniqueString('Summary task')
      )
      .setField(Task.Status, 'Not Started')
      .setField(Task.ActivityDate, Date.today())
      .quantity(2)
      .create();
    new SObjectBuilder(Event.SObjectType)
      .setField(Event.WhatId, opportunity.Id)
      .setField(
        Event.Subject,
        ValueProviderBuilder.provideUniqueString('Summary meeting')
      )
      .setField(Event.StartDateTime, Datetime.now().addHours(-2))
      .setField(Event.EndDateTime, Datetime.now().addHours(-1))
      .setField(
        Event.Description,
        'Customer confirmed the next evaluation step.'
      )
      .quantity(2)
      .create();

    for (
      String suffix : new List<String>{
        'MaxActivities',
        'MaxHistoryRows',
        'MaxOpenCases',
        'MaxClosedCases',
        'MaxRelatedOpps',
        'MaxLineItems',
        'MaxStakeholders',
        'MaxConversationItems'
      }
    ) {
      GCPCalloutForOpportunitySummary.configurationOverrides.put(suffix, '1');
    }
    GCPCalloutForOpportunitySummary.configurationOverrides.put(
      'TimeoutSeconds',
      '45'
    );
    GCPCalloutForOpportunitySummary.configurationOverrides.put(
      'ActivityDays',
      '30'
    );
    GCPCalloutForOpportunitySummary.configurationOverrides.put(
      'RecentDays',
      '14'
    );
    GCPCalloutForOpportunitySummary.configurationOverrides.put(
      'ClosedCaseMonths',
      '3'
    );
    Test.setMock(
      HttpCalloutMock.class,
      new ConfiguredSummaryCalloutMock(opportunity.Id)
    );

    Test.startTest();
    String rawResult = GCPCalloutForOpportunitySummary.callCloudRun(
      'summary-test@example.com',
      opportunity.Id,
      'test-token',
      'https://service.example.invalid'
    );
    Test.stopTest();
    Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(
      rawResult
    );
    System.assertEquals(
      true,
      result.get('success'),
      'Configured request must still return the standard summary response.'
    );
    resetTestHooks();
  }

  private class ConfiguredSummaryCalloutMock implements HttpCalloutMock {
    private Id expectedOpportunityId;

    private ConfiguredSummaryCalloutMock(Id opportunityId) {
      expectedOpportunityId = opportunityId;
    }

    public HttpResponse respond(HttpRequest request) {
      System.assertEquals(
        'https://service.example.invalid/api/v1/opportunity_summary',
        request.getEndpoint(),
        'Configuration must preserve the existing endpoint path.'
      );
      Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(
        request.getBody()
      );
      System.assertEquals(
        String.valueOf(expectedOpportunityId),
        payload.get('recordId'),
        'Request record must be preserved.'
      );
      System.assertEquals(
        true,
        payload.get('enableOpportunitySummaryEnrichment'),
        'Feature toggle must retain its existing behavior.'
      );
      Map<String, Object> activities = (Map<String, Object>) payload.get(
        'activities'
      );
      System.assertEquals(
        1,
        ((List<Object>) activities.get('tasks')).size(),
        'Configured activity cap must trim tasks.'
      );
      System.assertEquals(
        1,
        ((List<Object>) activities.get('events')).size(),
        'Configured activity cap must trim events.'
      );
      System.assertEquals(
        1,
        ((List<Object>) payload.get('relatedOpportunities')).size(),
        'Configured related-opportunity cap must reach SOQL.'
      );
      Map<String, Object> coverage = (Map<String, Object>) payload.get(
        'dataCoverage'
      );
      Map<String, Object> activityCoverage = (Map<String, Object>) coverage.get(
        'activities'
      );
      Map<String, Object> conversationCoverage = (Map<String, Object>) coverage.get(
        'conversations'
      );
      System.assertEquals(
        true,
        activityCoverage.get('isTruncated'),
        'Truncated activities must still be reported in data coverage.'
      );
      Datetime windowEnd = (Datetime) JSON.deserialize(
        JSON.serialize(activityCoverage.get('windowEnd')),
        Datetime.class
      );
      Datetime activityStart = (Datetime) JSON.deserialize(
        JSON.serialize(activityCoverage.get('windowStart')),
        Datetime.class
      );
      Datetime conversationStart = (Datetime) JSON.deserialize(
        JSON.serialize(conversationCoverage.get('windowStart')),
        Datetime.class
      );
      System.assertEquals(
        windowEnd.addDays(-30),
        activityStart,
        'Activity lookback must use its label.'
      );
      System.assertEquals(
        windowEnd.addDays(-14),
        conversationStart,
        'Conversation lookback must use its label.'
      );
      HttpResponse response = new HttpResponse();
      response.setStatusCode(200);
      response.setBody(
        '{"body":{"opportunity_summary":{"Executive Summary":["Configured summary"]}}}'
      );
      return response;
    }
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

  @IsTest
  static void shouldSendViewerContextWhenBuildingPayload() {
    Map<String, Object> payload = new Map<String, Object>();

    Test.startTest();
    GCPCalloutForOpportunitySummary.addViewerContext(payload);
    Test.stopTest();

    System.assertEquals(
      UserInfo.getTimeZone().getID(),
      payload.get('viewerTimeZone'),
      'Time zone must describe the viewing user.'
    );
    System.assertEquals(
      UserInfo.getLocale(),
      payload.get('viewerLocale'),
      'Locale must describe the viewing user.'
    );
  }

  @IsTest
  static void shouldSendClosedFlagsAsBooleansWhenReadable() {
    Map<String, Object> opportunityFields = (Map<String, Object>) JSON.deserializeUntyped(
      JSON.serialize(opportunityWithAccount(false))
    );
    opportunityFields.put('IsClosed', true);
    opportunityFields.put('IsWon', false);
    Opportunity closedOpportunity = (Opportunity) JSON.deserialize(
      JSON.serialize(opportunityFields),
      Opportunity.class
    );

    Test.startTest();
    Map<String, Object> closedPayload = GCPCalloutForOpportunitySummary.buildOpportunityMap(
      closedOpportunity,
      false
    );
    Map<String, Object> unreadablePayload = GCPCalloutForOpportunitySummary.buildOpportunityMap(
      opportunityWithAccount(false),
      false
    );
    Test.stopTest();

    System.assert(closedPayload.get('isClosed') instanceof Boolean);
    System.assertEquals(true, closedPayload.get('isClosed'));
    System.assertEquals(false, closedPayload.get('isWon'));
    System.assertEquals(
      false,
      unreadablePayload.containsKey('isClosed'),
      'Unreadable flags must be omitted, never sent as null or text.'
    );
    System.assertEquals(false, unreadablePayload.containsKey('isWon'));
  }

  @IsTest
  static void shouldSendDealMotionAndSectorUnchangedWhenPopulated() {
    Map<String, Object> opportunityFields = (Map<String, Object>) JSON.deserializeUntyped(
      JSON.serialize(opportunityWithAccount(false))
    );
    opportunityFields.put('Order_Type__c', 'Upsell + Downsell');
    ((Map<String, Object>) opportunityFields.get('Account'))
      .put('Sector__c', 'Transportation, Travel & Leisure');
    Opportunity classifiedOpportunity = (Opportunity) JSON.deserialize(
      JSON.serialize(opportunityFields),
      Opportunity.class
    );

    Test.startTest();
    Map<String, Object> classifiedPayload = GCPCalloutForOpportunitySummary.buildOpportunityMap(
      classifiedOpportunity,
      false
    );
    Map<String, Object> blankPayload = GCPCalloutForOpportunitySummary.buildOpportunityMap(
      opportunityWithAccount(false),
      false
    );
    Test.stopTest();

    System.assertEquals(
      'Upsell + Downsell',
      classifiedPayload.get('dealMotion')
    );
    System.assertEquals(
      'Transportation, Travel & Leisure',
      classifiedPayload.get('sector')
    );
    System.assertEquals(false, blankPayload.containsKey('dealMotion'));
    System.assertEquals(false, blankPayload.containsKey('sector'));
    System.assertEquals(
      false,
      blankPayload.containsKey('npiProductCategories'),
      'No NPI field exists in the org, so none is sent.'
    );
  }

  @IsTest
  static void shouldBuildConversationEvidenceWhenEnrichmentDisabled() {
    Datetime windowEnd = Datetime.now();
    GCPCalloutForOpportunitySummary.activityParticipantProvider = new StubParticipantProvider(
      participantMap(TASK_ID, CONTACT_ID, 'unknown')
    );
    try {
      Test.startTest();
      GCPCalloutForOpportunitySummary.ActivityData activityData = GCPCalloutForOpportunitySummary.assembleActivityData(
        new List<SObject>{
          taskRecord(
            TASK_ID,
            CONTACT_ID,
            USER_ID,
            true,
            windowEnd.addDays(-1),
            'Buyer agreed to the pricing.'
          )
        },
        new List<SObject>(),
        new Map<Id, String>(),
        false,
        windowEnd.addDays(-180),
        windowEnd,
        90,
        false,
        false
      );
      Test.stopTest();

      System.assertEquals(
        1,
        activityData.conversations.size(),
        'Conversation notes must not depend on the enrichment toggle.'
      );
      System.assertEquals(
        'Buyer agreed to the pricing.',
        activityData.conversations[0].get('text')
      );
      System.assertEquals(
        false,
        activityData.tasks[0].containsKey('participants'),
        'Activity rows keep their non-enrichment shape.'
      );
      System.assertEquals(
        false,
        activityData.tasks[0].containsKey('sourceRecordId')
      );
    } finally {
      resetTestHooks();
    }
  }

  @IsTest
  static void shouldSendLossFieldsWithinLimitWhenPopulated() {
    Map<String, Object> opportunityFields = (Map<String, Object>) JSON.deserializeUntyped(
      JSON.serialize(opportunityWithAccount(false))
    );
    opportunityFields.put('Downgrade_Reason_Opp__c', 'Lost');
    opportunityFields.put('Primary_Loss_Reason__c', '  Price  ');
    opportunityFields.put('Primary_Competitor__c', 'A'.repeat(320));
    Opportunity lostOpportunity = (Opportunity) JSON.deserialize(
      JSON.serialize(opportunityFields),
      Opportunity.class
    );

    Test.startTest();
    Map<String, Object> lostPayload = GCPCalloutForOpportunitySummary.buildOpportunityMap(
      lostOpportunity,
      false
    );
    Map<String, Object> blankPayload = GCPCalloutForOpportunitySummary.buildOpportunityMap(
      opportunityWithAccount(false),
      false
    );
    Test.stopTest();

    System.assertEquals('Lost', lostPayload.get('lossReason'));
    System.assertEquals('Price', lostPayload.get('lossReasonDetail'));
    System.assertEquals(
      300,
      ((String) lostPayload.get('lostToCompetitor')).length(),
      'Loss fields are capped at the 300 characters GCP accepts.'
    );
    for (
      String key : new List<String>{
        'lossReason',
        'lossReasonDetail',
        'lostToCompetitor'
      }
    ) {
      System.assertEquals(
        false,
        blankPayload.containsKey(key),
        'Blank loss fields are left out, never sent as null.'
      );
    }
  }

  @IsTest
  static void shouldSendTaskSubtypeWhenAssemblingActivities() {
    Map<String, Object> taskFields = (Map<String, Object>) JSON.deserializeUntyped(
      JSON.serialize(
        taskRecord(TASK_ID, CONTACT_ID, USER_ID, true, Datetime.now(), 'Notes')
      )
    );
    taskFields.put('TaskSubtype', 'Call');
    Task callTask = (Task) JSON.deserialize(
      JSON.serialize(taskFields),
      Task.class
    );

    Test.startTest();
    GCPCalloutForOpportunitySummary.ActivityData activityData = GCPCalloutForOpportunitySummary.assembleActivityData(
      new List<SObject>{
        callTask,
        taskRecord(
          syntheticId('00T', 2),
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
    Test.stopTest();

    System.assertEquals('Call', activityData.tasks[0].get('taskSubtype'));
    System.assertEquals(
      false,
      activityData.tasks[1].containsKey('taskSubtype'),
      'A blank subtype is left out.'
    );
  }

  @IsTest
  static void shouldNameAccountAndContactsSentWhenBuildingReferences() {
    Id sharedNameContactId = syntheticId('003', 3);
    Map<String, Object> payload = new Map<String, Object>{
      'opportunity' => new Map<String, Object>{
        'id' => OPPORTUNITY_ID,
        'name' => 'Example Opportunity',
        'ownerId' => USER_ID,
        'ownerName' => 'Riley Rep',
        'accountId' => ACCOUNT_ID,
        'accountName' => 'Example Co'
      },
      'relatedOpportunities' => new List<Map<String, Object>>{
        new Map<String, Object>{
          'id' => syntheticId('006', 2),
          'name' => 'Example Co - Renewal 2025'
        }
      },
      'lineItems' => new List<Map<String, Object>>{
        new Map<String, Object>{
          'productId' => PRODUCT_ID,
          'productName' => 'Example Product'
        }
      },
      'cases' => new Map<String, Object>{
        'open' => new List<Map<String, Object>>{
          new Map<String, Object>{
            'id' => syntheticId('500', 1),
            'caseNumber' => '00012345',
            'subject' => 'Porting delay on main line'
          }
        },
        'recentlyClosed' => new List<Map<String, Object>>()
      },
      'activities' => new Map<String, Object>{
        'tasks' => new List<Map<String, Object>>{
          new Map<String, Object>{ 'id' => TASK_ID, 'subject' => 'Call' },
          new Map<String, Object>{
            'id' => syntheticId('00T', 2),
            'subject' => 'Discovery call with IT'
          }
        },
        'events' => new List<Map<String, Object>>{
          new Map<String, Object>{
            'id' => EVENT_ID,
            'subject' => 'Quarterly business review'
          }
        }
      },
      'stakeholders' => new List<Map<String, Object>>{
        new Map<String, Object>{
          'contactId' => CONTACT_ID,
          'name' => 'Avery Buyer'
        },
        new Map<String, Object>{
          'contactId' => SECOND_CONTACT_ID,
          'name' => 'Jo'
        },
        new Map<String, Object>{
          'contactId' => syntheticId('003', 4),
          'name' => 'Sam Same'
        }
      },
      'conversationEvidence' => new Map<String, Object>{
        'items' => new List<Map<String, Object>>{
          new Map<String, Object>{
            'participants' => new List<Map<String, Object>>{
              new Map<String, Object>{
                'contactId' => CONTACT_ID,
                'name' => 'Avery Buyer'
              },
              new Map<String, Object>{
                'contactId' => sharedNameContactId,
                'name' => 'sam same'
              }
            }
          }
        }
      }
    };

    Test.startTest();
    List<Map<String, Object>> named = GCPCalloutForOpportunitySummary.namedRecordReferences(
      payload
    );
    Set<Id> referenceableIds = GCPCalloutForOpportunitySummary.referenceableRecordIds(
      payload
    );
    Test.stopTest();

    List<String> labels = new List<String>();
    for (Map<String, Object> namedRecord : named) {
      labels.add(
        namedRecord.get('object_type') + ':' + namedRecord.get('label')
      );
    }
    System.assertEquals(
      new List<String>{
        'User:Riley Rep',
        'Account:Example Co',
        'Opportunity:Example Co - Renewal 2025',
        'Contact:Avery Buyer',
        'Product2:Example Product',
        'Case:00012345',
        'Case:Porting delay on main line',
        'Task:Discovery call with IT',
        'Event:Quarterly business review'
      },
      labels,
      'Every sent record with a quotable name is offered. The current opportunity, ' +
      'short names, generic subjects and names shared by two records are not.'
    );
    for (
      Id expectedId : new List<Id>{
        ACCOUNT_ID,
        CONTACT_ID,
        USER_ID,
        PRODUCT_ID,
        TASK_ID,
        EVENT_ID
      }
    ) {
      System.assert(referenceableIds.contains(expectedId), expectedId);
    }
    System.assertEquals(false, referenceableIds.contains(OPPORTUNITY_ID));
  }

  @IsTest
  static void shouldOfferNamedReferencesToEverySectionWhenBuildingResult() {
    String body =
      '{"body":{"opportunity_summary":{' +
      '"Executive Summary":["Account: Example Co"],' +
      '"Next Best Actions":["Call Avery Buyer"]},' +
      '"record_references":[{"object_type":"Contact","id":"' +
      CONTACT_ID +
      '","label":"Avery","mentioned_in":["Next Best Actions"]}]}}';
    List<Map<String, Object>> named = new List<Map<String, Object>>{
      new Map<String, Object>{
        'object_type' => 'Account',
        'id' => String.valueOf(ACCOUNT_ID),
        'label' => 'Example Co'
      },
      new Map<String, Object>{
        'object_type' => 'Contact',
        'id' => String.valueOf(CONTACT_ID),
        'label' => 'Avery Buyer'
      }
    };

    Test.startTest();
    Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(
      GCPCalloutForOpportunitySummary.buildResult(
        JSON.deserializeUntyped(body),
        new Set<Id>{ ACCOUNT_ID, CONTACT_ID },
        named
      )
    );
    Test.stopTest();

    List<Object> references = (List<Object>) result.get('record_references');
    System.assertEquals(
      2,
      references.size(),
      'A record GCP referenced keeps only GCP\'s link; Salesforce adds the Account.'
    );
    Map<String, Object> accountReference = (Map<String, Object>) references[1];
    System.assertEquals('Account', accountReference.get('object_type'));
    System.assertEquals('salesforce', accountReference.get('source'));
    System.assertEquals(
      new List<Object>{ 'Executive Summary', 'Next Best Actions' },
      accountReference.get('mentioned_in')
    );
  }

  @IsTest
  static void shouldCollectReferenceableIdsWhenPayloadHasCasesAndActivities() {
    Id caseId = syntheticId('500', 1);
    Map<String, Object> payload = new Map<String, Object>{
      'cases' => new Map<String, Object>{
        'open' => new List<Map<String, Object>>{
          new Map<String, Object>{ 'id' => caseId }
        },
        'recentlyClosed' => new List<Map<String, Object>>()
      },
      'activities' => new Map<String, Object>{
        'tasks' => new List<Map<String, Object>>{
          new Map<String, Object>{ 'id' => TASK_ID }
        },
        'events' => new List<Map<String, Object>>{
          new Map<String, Object>{ 'id' => EVENT_ID },
          new Map<String, Object>{ 'subject' => 'No id' }
        }
      }
    };

    Test.startTest();
    Set<Id> ids = GCPCalloutForOpportunitySummary.referenceableRecordIds(
      payload
    );
    Test.stopTest();

    System.assertEquals(
      new Set<Id>{ caseId, TASK_ID, EVENT_ID },
      ids,
      'Only Case, Task and Event Ids sent to GCP may become links.'
    );
  }

  @IsTest
  static void shouldPassClosedDealFieldsAndOnlySentReferencesWhenBuildingResult() {
    Id caseId = syntheticId('500', 1);
    Id unsentCaseId = syntheticId('500', 2);
    String body =
      '{"body":{' +
      '"opportunity_summary":{"Executive Summary":["Case 00012345 is open"],"Post-Close Actions":["Kickoff: Schedule onboarding"]},' +
      '"deal_state":{"state":"closed_won","is_closed":true,"score":100},' +
      '"salesforce_fields":{"deal_motion":"Upsell","npi_product_categories":["RingCX"]},' +
      '"record_references":[' +
      '{"object_type":"Case","id":"' +
      caseId +
      '","label":"00012345","case_number":"00012345","mentioned_in":["Executive Summary"]},' +
      '{"object_type":"Case","id":"' +
      unsentCaseId +
      '","label":"00099999","mentioned_in":["Executive Summary"]},' +
      '{"object_type":"Task","id":"' +
      caseId +
      '","label":"Mismatched type","mentioned_in":["Executive Summary"]},' +
      '{"object_type":"Account","id":"' +
      ACCOUNT_ID +
      '","label":"Example Co","mentioned_in":["Executive Summary"]},' +
      '{"object_type":"Task","id":"' +
      TASK_ID +
      '","label":"Discovery call","activity_kind":"Call","mentioned_in":[]},' +
      '"not an object"]' +
      '}}';
    Set<Id> sentIds = new Set<Id>{ caseId, TASK_ID };

    Test.startTest();
    Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(
      GCPCalloutForOpportunitySummary.buildResult(
        JSON.deserializeUntyped(body),
        sentIds,
        new List<Map<String, Object>>()
      )
    );
    Test.stopTest();

    System.assertEquals(true, result.get('success'));
    System.assertEquals(2, ((List<Object>) result.get('cards')).size());
    Map<String, Object> dealState = (Map<String, Object>) result.get(
      'deal_state'
    );
    System.assertEquals(true, dealState.get('is_closed'));
    System.assertEquals(
      'Upsell',
      ((Map<String, Object>) result.get('salesforce_fields')).get('deal_motion')
    );
    List<Object> references = (List<Object>) result.get('record_references');
    System.assertEquals(
      1,
      references.size(),
      'Unsent, mistyped, unsupported and unplaced references must be dropped.'
    );
    Map<String, Object> reference = (Map<String, Object>) references[0];
    System.assertEquals(String.valueOf(caseId), reference.get('id'));
    System.assertEquals('00012345', reference.get('case_number'));
  }

  @IsTest
  static void shouldSendIdsAndViewerContextWhenCallingCloudRun() {
    new SObjectBuilder(ByPassTrigger__c.SObjectType)
      .setField(ByPassTrigger__c.SetupOwnerId, UserInfo.getOrganizationId())
      .setField(ByPassTrigger__c.Bypass_Account_Trigger__c, true)
      .setField(ByPassTrigger__c.Bypass_Opportunity_Trigger__c, true)
      .create();
    new SObjectBuilder(GCP_Feature_Toggle__c.SObjectType)
      .setField(
        GCP_Feature_Toggle__c.SetupOwnerId,
        UserInfo.getOrganizationId()
      )
      .setField(
        GCP_Feature_Toggle__c.Enable_Opportunity_Summary_Enrichment__c,
        false
      )
      .create();
    Account account = (Account) new SObjectBuilder(Account.SObjectType)
      .setField(
        Account.Name,
        ValueProviderBuilder.provideUniqueString('Reference company')
      )
      .create()
      .getRecord();
    Opportunity opportunity = (Opportunity) new SObjectBuilder(
        Opportunity.SObjectType
      )
      .setField(Opportunity.AccountId, account.Id)
      .setField(Opportunity.CloseDate, Date.today().addDays(30))
      .create()
      .getRecord();
    Task callTask = (Task) new SObjectBuilder(Task.SObjectType)
      .setField(Task.WhatId, opportunity.Id)
      .setField(
        Task.Subject,
        ValueProviderBuilder.provideUniqueString('Discovery call')
      )
      .setField(Task.Status, 'Not Started')
      .setField(Task.ActivityDate, Date.today())
      .create()
      .getRecord();
    Test.setMock(
      HttpCalloutMock.class,
      new ReferenceSummaryCalloutMock(callTask.Id)
    );

    Test.startTest();
    String rawResult = GCPCalloutForOpportunitySummary.callCloudRun(
      'summary-test@example.com',
      opportunity.Id,
      'test-token',
      'https://service.example.invalid'
    );
    Test.stopTest();

    Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(
      rawResult
    );
    System.assertEquals(true, result.get('success'));
    List<Object> references = (List<Object>) result.get('record_references');
    Map<String, Object> taskReference = (Map<String, Object>) references[0];
    System.assertEquals(
      String.valueOf(callTask.Id),
      taskReference.get('id'),
      'A reference to a sent Task must survive the Id filter.'
    );
    Set<String> referencedTypes = new Set<String>();
    Set<String> referencedIds = new Set<String>();
    for (Object reference : references) {
      referencedTypes.add(
        (String) ((Map<String, Object>) reference).get('object_type')
      );
      referencedIds.add((String) ((Map<String, Object>) reference).get('id'));
    }
    System.assert(
      referencedIds.contains(String.valueOf(account.Id)),
      'The sent Account is offered as a link under its own name.'
    );
    System.assert(referencedTypes.contains('User'), referencedTypes);
    System.assertEquals(
      false,
      referencedIds.contains(String.valueOf(opportunity.Id)),
      'The current opportunity never links to itself.'
    );
  }

  private class ReferenceSummaryCalloutMock implements HttpCalloutMock {
    private Id expectedTaskId;

    private ReferenceSummaryCalloutMock(Id taskId) {
      expectedTaskId = taskId;
    }

    public HttpResponse respond(HttpRequest request) {
      Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(
        request.getBody()
      );
      System.assertEquals(
        UserInfo.getTimeZone().getID(),
        payload.get('viewerTimeZone')
      );
      System.assertEquals(UserInfo.getLocale(), payload.get('viewerLocale'));
      Map<String, Object> opportunityPayload = (Map<String, Object>) payload.get(
        'opportunity'
      );
      System.assertEquals(false, opportunityPayload.get('isClosed'));
      System.assertEquals(false, opportunityPayload.get('isWon'));
      Map<String, Object> taskRow = (Map<String, Object>) ((List<Object>) ((Map<String, Object>) payload.get(
          'activities'
        ))
        .get('tasks'))[0];
      System.assertEquals(String.valueOf(expectedTaskId), taskRow.get('id'));
      Map<String, Object> cases = (Map<String, Object>) payload.get('cases');
      System.assert(cases.containsKey('open'));
      System.assertEquals(
        false,
        payload.get('enableOpportunitySummaryEnrichment')
      );
      System.assert(
        payload.get('conversationEvidence') instanceof Map<String, Object>,
        'conversationEvidence must be sent with enrichment off.'
      );
      System.assertEquals(
        false,
        payload.containsKey('dataCoverage'),
        'dataCoverage stays tied to the enrichment toggle.'
      );

      HttpResponse response = new HttpResponse();
      response.setStatusCode(200);
      response.setBody(
        '{"body":{"opportunity_summary":{"Opportunity History & Stage Journey":["Discovery call logged"]},' +
          '"deal_state":{"state":"open","is_closed":false},' +
          '"record_references":[{"object_type":"Task","id":"' +
          expectedTaskId +
          '","label":"Discovery call","activity_kind":"Call","mentioned_in":["Opportunity History & Stage Journey"]}]}}'
      );
      return response;
    }
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
      accountFields.put('Website', 'https://www.example.com');
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
      productFields.put('Family', 'Service');
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

  private static Opportunity opportunityWithIdentity(
    String accountName,
    String accountWebsite,
    String opportunityWebsite,
    String intendedProduct
  ) {
    Map<String, Object> accountFields = new Map<String, Object>{
      'attributes' => new Map<String, Object>{ 'type' => 'Account' },
      'Id' => ACCOUNT_ID,
      'Name' => accountName,
      'Industry' => 'Technology',
      'BillingCity' => 'San Mateo',
      'BillingState' => 'California',
      'BillingCountry' => 'United States'
    };
    if (accountWebsite != null) {
      accountFields.put('Website', accountWebsite);
    }
    Map<String, Object> opportunityFields = new Map<String, Object>{
      'attributes' => new Map<String, Object>{ 'type' => 'Opportunity' },
      'Id' => OPPORTUNITY_ID,
      'Name' => 'Example Opportunity',
      'AccountId' => ACCOUNT_ID,
      'Account' => accountFields
    };
    if (opportunityWebsite != null) {
      opportunityFields.put('Website__c', opportunityWebsite);
    }
    if (intendedProduct != null) {
      opportunityFields.put('Intended_Product__c', intendedProduct);
    }
    return (Opportunity) JSON.deserialize(
      JSON.serialize(opportunityFields),
      Opportunity.class
    );
  }

  private static OpportunityLineItem lineItemWithProductValues(
    String family,
    String productLine
  ) {
    Map<String, Object> productFields = new Map<String, Object>{
      'attributes' => new Map<String, Object>{ 'type' => 'Product2' },
      'Id' => PRODUCT_ID,
      'Name' => 'Example Product',
      'Family' => family,
      'Sub_Category__c' => productLine
    };
    Map<String, Object> lineItemFields = new Map<String, Object>{
      'attributes' => new Map<String, Object>{
        'type' => 'OpportunityLineItem'
      },
      'Id' => LINE_ITEM_ID,
      'Name' => 'Example Product',
      'Product2Id' => PRODUCT_ID,
      'Quantity' => 1,
      'UnitPrice' => 1,
      'TotalPrice' => 1,
      'Product2' => productFields
    };
    return (OpportunityLineItem) JSON.deserialize(
      JSON.serialize(lineItemFields),
      OpportunityLineItem.class
    );
  }

  private static OpportunityLineItem lineItemWithProductContext() {
    Map<String, Object> productFields = new Map<String, Object>{
      'attributes' => new Map<String, Object>{ 'type' => 'Product2' },
      'Id' => PRODUCT_ID,
      'Name' => 'Example Product',
      'Family' => 'Service',
      'Sub_Category__c' => 'Contact Center',
      'Subgroup__c' => '[210] Main',
      'Group__c' => '[200] Services',
      'Description' => 'Customer-facing product description',
      'Product_Description__c' => 'p'.repeat(1001),
      'CategoryName__c' => 'Collaboration Services',
      'LicenseGroup__c' => 'Core Licenses;Digital Lines;Core Licenses',
      'ServiceCategory__c' => 'OFFICE_LICENSE'
    };
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
    GCPCalloutForOpportunitySummary.configurationOverrides.clear();
    GCPCalloutForOpportunitySummary.activityParticipantProvider = new GCPCalloutForOpportunitySummary.ActivityParticipantProvider();
    GCPCalloutForOpportunitySummary.requestSizeLimitBytes = 2 * 1024 * 1024;
  }

  private class StubParticipantProvider extends GCPCalloutForOpportunitySummary.ActivityParticipantProvider {
    private Map<Id, List<Map<String, Object>>> participantsByActivityId;

    private StubParticipantProvider(
      Map<Id, List<Map<String, Object>>> participantsByActivityId
    ) {
      this.participantsByActivityId = participantsByActivityId;
    }

    public override GCPCalloutForOpportunitySummary.ActivityParticipantResult load(
      List<SObject> tasks,
      List<SObject> events
    ) {
      GCPCalloutForOpportunitySummary.ActivityParticipantResult result = new GCPCalloutForOpportunitySummary.ActivityParticipantResult();
      result.participantsByActivityId = participantsByActivityId;
      return result;
    }
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

  // ---------------- Call transcripts switch ----------------

  private static Map<String, Object> serializedPayloadWithTranscriptSetting(
    Boolean settingValue
  ) {
    new SObjectBuilder(ByPassTrigger__c.SObjectType)
      .setField(ByPassTrigger__c.SetupOwnerId, UserInfo.getOrganizationId())
      .setField(ByPassTrigger__c.Bypass_Account_Trigger__c, true)
      .setField(ByPassTrigger__c.Bypass_Opportunity_Trigger__c, true)
      .create();
    if (settingValue != null) {
      new SObjectBuilder(GCP_Feature_Toggle__c.SObjectType)
        .setField(
          GCP_Feature_Toggle__c.SetupOwnerId,
          UserInfo.getOrganizationId()
        )
        .setField(
          GCP_Feature_Toggle__c.Opportunity_Summary_Call_Transcripts__c,
          settingValue
        )
        .create();
    }
    Account account = (Account) new SObjectBuilder(Account.SObjectType)
      .setField(
        Account.Name,
        ValueProviderBuilder.provideUniqueString('Transcript company')
      )
      .create()
      .getRecord();
    Opportunity opportunity = (Opportunity) new SObjectBuilder(
        Opportunity.SObjectType
      )
      .setField(Opportunity.AccountId, account.Id)
      .setField(Opportunity.CloseDate, Date.today().addDays(30))
      .create()
      .getRecord();

    Test.startTest();
    Map<String, Object> payload = GCPCalloutForOpportunitySummary.buildPayload(
      'summary-test@example.com',
      opportunity.Id
    );
    Test.stopTest();
    return (Map<String, Object>) JSON.deserializeUntyped(
      JSON.serialize(payload)
    );
  }

  @IsTest
  static void sendsCallTranscriptsTrueAsJsonBooleanWhenSettingOn() {
    Map<String, Object> payload = serializedPayloadWithTranscriptSetting(true);

    System.assert(
      payload.get('enableOpportunitySummaryCallTranscripts') instanceof Boolean,
      'The switch must serialize as a JSON boolean, not a string.'
    );
    System.assertEquals(
      true,
      payload.get('enableOpportunitySummaryCallTranscripts')
    );
  }

  @IsTest
  static void sendsCallTranscriptsFalseAsJsonBooleanWhenSettingOff() {
    Map<String, Object> payload = serializedPayloadWithTranscriptSetting(false);

    System.assert(
      payload.get('enableOpportunitySummaryCallTranscripts') instanceof Boolean,
      'The switch must serialize as a JSON boolean, not a string.'
    );
    System.assertEquals(
      false,
      payload.get('enableOpportunitySummaryCallTranscripts')
    );
  }

  @IsTest
  static void sendsCallTranscriptsFalseWhenNoSettingRecordExists() {
    System.assertEquals(0, [SELECT COUNT() FROM GCP_Feature_Toggle__c]);

    Map<String, Object> payload = serializedPayloadWithTranscriptSetting(null);

    System.assertEquals(
      true,
      payload.containsKey('enableOpportunitySummaryCallTranscripts'),
      'The field is always sent, never omitted.'
    );
    System.assertEquals(
      false,
      payload.get('enableOpportunitySummaryCallTranscripts')
    );
  }

  @IsTest
  static void requestControlIsNeverNull() {
    Map<String, Object> payload = new Map<String, Object>();

    GCPCalloutForOpportunitySummary.addCallTranscriptsRequestControl(
      payload,
      null
    );

    System.assertEquals(
      false,
      payload.get('enableOpportunitySummaryCallTranscripts')
    );
  }

  @IsTest
  static void responseWithAndWithoutCallTranscriptsBlockRendersTheSame() {
    String summary = '"opportunity_summary":{"Executive Summary":["CRM summary"]}';
    Object withoutBlock = JSON.deserializeUntyped(
      '{"statusCode":200,"body":{' + summary + '}}'
    );
    Object withBlock = JSON.deserializeUntyped(
      '{"statusCode":200,"body":{' +
        summary +
        ',"call_transcripts":{"status":"ok",' +
        '"counts":{"calls":1,"ace":1,"salesforce":0,"none":0},' +
        '"calls":[{"task_id":"00T000000000001AAA","source":"ace","in_request":true}]}}}'
    );

    String resultWithout = GCPCalloutForOpportunitySummary.buildResult(
      withoutBlock
    );
    String resultWith = GCPCalloutForOpportunitySummary.buildResult(withBlock);

    System.assertEquals(
      true,
      ((Map<String, Object>) JSON.deserializeUntyped(resultWith)).get('success')
    );
    System.assertEquals(
      resultWithout,
      resultWith,
      'The optional call_transcripts block must not change what the UI receives.'
    );
  }
}
