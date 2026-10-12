@IsTest
private class GCPCalloutForOpportunitySummaryTest {
  private static final Id OPPORTUNITY_ID = syntheticId(
    Opportunity.SObjectType,
    1
  );
  private static final Id ACCOUNT_ID = syntheticId(Account.SObjectType, 1);
  private static final Id PRODUCT_ID = syntheticId(Product2.SObjectType, 1);
  private static final Id LINE_ITEM_ID = syntheticId(
    OpportunityLineItem.SObjectType,
    1
  );
  private static final Id TASK_ID = syntheticId(Task.SObjectType, 1);
  private static final Id EVENT_ID = syntheticId(Event.SObjectType, 1);
  private static final Id CONTACT_ID = syntheticId(Contact.SObjectType, 1);
  private static final Id SECOND_CONTACT_ID = syntheticId(
    Contact.SObjectType,
    2
  );
  private static final Id USER_ID = syntheticId(User.SObjectType, 1);
  private static final String SERVICE_HOST = 'https://service.example.invalid';
  private static final String TOKEN_URL = SERVICE_HOST + '/token';
  private static final String SUMMARY_ENDPOINT =
    SERVICE_HOST + '/api/v1/opportunity_summary';
  // Signing certificate configured in GCP_Endpoint_Settings__c and used by the other GCP callout tests.
  private static final String SIGNING_CERTIFICATE = 'privatekey';
  private static final String ID_TOKEN = 'identity-token';
  private static final String SUMMARY_LINE = 'Healthy deal';
  private static final String SUMMARY_RESPONSE =
    '{"body":{"opportunity_summary":{"Executive Summary":["' +
    SUMMARY_LINE +
    '"]}}}';

  @IsTest
  static void shouldKeepCompletionFieldOutOfTaskQueryWhenBuildingActivityQuery() {
    QueryFactory taskQuery = GCPCalloutForOpportunitySummary.buildTaskQuery(
      OPPORTUNITY_ID,
      Datetime.now().addDays(-180)
    );

    String soql = taskQuery.setQuery().getQuery();
    Assert.isTrue(
      soql.contains('IsClosed'),
      'Expected true: soql.contains(\'IsClosed\')'
    );
    Assert.isFalse(
      soql.contains('CompletedDateTime'),
      'Expected false: soql.contains(\'CompletedDateTime\')'
    );
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

    Assert.isTrue(
      soql.contains('ORDER BY CloseDate DESC NULLS FIRST'),
      'The most recent close dates must survive the limit: ' + soql
    );
    Assert.isTrue(soql.contains('LIMIT 25'), soql);
    Assert.isFalse(
      soql.contains('Name ASC'),
      'The selector default Name ordering must not lead the ORDER BY.'
    );
  }

  @IsTest
  static void shouldPreserveExistingShapesWhenEnrichmentDisabled() {
    Opportunity opportunityRecord = opportunityWithAccount(true);
    Map<String, Object> opportunityPayload = GCPCalloutForOpportunitySummary.buildOpportunityMap(
      opportunityRecord,
      false
    );

    Assert.areEqual(
      'Example Opportunity',
      opportunityPayload.get('name'),
      'Unexpected value for opportunityPayload.get(\'name\')'
    );
    Assert.areEqual(
      'Example Co',
      opportunityPayload.get('accountName'),
      'Unexpected value for opportunityPayload.get(\'accountName\')'
    );
    Assert.isFalse(
      opportunityPayload.containsKey('accountWebsite'),
      'Expected false: opportunityPayload.containsKey(\'accountWebsite\')'
    );
    Assert.isFalse(
      opportunityPayload.containsKey('accountState'),
      'Expected false: opportunityPayload.containsKey(\'accountState\')'
    );

    List<Map<String, Object>> lineItems = GCPCalloutForOpportunitySummary.buildLineItemRows(
      new List<SObject>{ lineItemWithProduct(true) },
      false
    );
    Assert.areEqual(
      1,
      lineItems.size(),
      'Unexpected value for lineItems.size()'
    );
    Assert.areEqual(
      'Example Product',
      lineItems[0].get('productName'),
      'Unexpected value for lineItems[0].get(\'productName\')'
    );
    Assert.isFalse(
      lineItems[0].containsKey('productFamily'),
      'Expected false: lineItems[0].containsKey(\'productFamily\')'
    );
    Assert.isFalse(
      lineItems[0].containsKey('productLine'),
      'Expected false: lineItems[0].containsKey(\'productLine\')'
    );
    Assert.isFalse(
      lineItems[0].containsKey('productSubgroup'),
      'Expected false: lineItems[0].containsKey(\'productSubgroup\')'
    );
    Assert.isFalse(
      lineItems[0].containsKey('productGroup'),
      'Expected false: lineItems[0].containsKey(\'productGroup\')'
    );
    Assert.isFalse(
      lineItems[0].containsKey('productDescription'),
      'Expected false: lineItems[0].containsKey(\'productDescription\')'
    );
    Assert.isFalse(
      lineItems[0].containsKey('productCatalogDescription'),
      'Expected false: lineItems[0].containsKey(\'productCatalogDescription\')'
    );
    Assert.isFalse(
      lineItems[0].containsKey('productCategoryName'),
      'Expected false: lineItems[0].containsKey(\'productCategoryName\')'
    );
    Assert.isFalse(
      lineItems[0].containsKey('licenseGroups'),
      'Expected false: lineItems[0].containsKey(\'licenseGroups\')'
    );
    Assert.isFalse(
      lineItems[0].containsKey('serviceCategory'),
      'Expected false: lineItems[0].containsKey(\'serviceCategory\')'
    );
    Assert.isFalse(
      lineItems[0].containsKey('productCapabilities'),
      'Expected false: lineItems[0].containsKey(\'productCapabilities\')'
    );

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
      Assert.areEqual(
        1,
        activityData.tasks.size(),
        'Unexpected value for activityData.tasks.size()'
      );
      Assert.isFalse(
        activityData.tasks[0].containsKey('sourceRecordId'),
        'Expected false: activityData.tasks[0].containsKey(\'sourceRecordId\')'
      );
      Assert.isFalse(
        activityData.tasks[0].containsKey('participants'),
        'Expected false: activityData.tasks[0].containsKey(\'participants\')'
      );
      Assert.areEqual(
        0,
        activityData.conversations.size(),
        'Unexpected value for activityData.conversations.size()'
      );
    } finally {
      resetTestHooks();
    }
  }

  @IsTest
  static void shouldMapCompanyIdentityWhenOptionalFieldsUnreadable() {
    Map<String, Object> populated = GCPCalloutForOpportunitySummary.buildOpportunityMap(
      opportunityWithAccount(true),
      true
    );
    Assert.areEqual(
      'https://www.example.com',
      populated.get('accountWebsite'),
      'Unexpected value for populated.get(\'accountWebsite\')'
    );
    Assert.areEqual(
      'Technology',
      populated.get('accountIndustry'),
      'Unexpected value for populated.get(\'accountIndustry\')'
    );
    Assert.areEqual(
      'United States',
      populated.get('accountCountry'),
      'Unexpected value for populated.get(\'accountCountry\')'
    );
    Assert.areEqual(
      'California',
      populated.get('accountState'),
      'Unexpected value for populated.get(\'accountState\')'
    );

    Map<String, Object> inaccessible = GCPCalloutForOpportunitySummary.buildOpportunityMap(
      opportunityWithAccount(false),
      true
    );
    Assert.isFalse(
      inaccessible.containsKey('accountWebsite'),
      'Expected false: inaccessible.containsKey(\'accountWebsite\')'
    );
    Assert.isFalse(
      inaccessible.containsKey('accountState'),
      'Expected false: inaccessible.containsKey(\'accountState\')'
    );
  }

  @IsTest
  static void shouldMapCampaignProductAndWebsiteFallbackWhenBuildingRequest() {
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

    Assert.areEqual(
      'Example Co',
      fallback.get('accountName'),
      'Unexpected value for fallback.get(\'accountName\')'
    );
    Assert.areEqual(
      'RingCX',
      fallback.get('intendedProduct'),
      'Unexpected value for fallback.get(\'intendedProduct\')'
    );
    Assert.areEqual(
      'https://research.example.com/company',
      fallback.get('accountWebsite'),
      'Unexpected value for fallback.get(\'accountWebsite\')'
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
    Assert.areEqual(
      'https://official.example.com/about',
      preferred.get('accountWebsite'),
      'Unexpected value for preferred.get(\'accountWebsite\')'
    );
    Assert.isFalse(
      preferred.containsKey('intendedProduct'),
      'Expected false: preferred.containsKey(\'intendedProduct\')'
    );

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
    Assert.isFalse(
      invalid.containsKey('accountWebsite'),
      'Opportunity.Website__c is used only when Account.Website is blank.'
    );
  }

  @IsTest
  static void shouldDisableOnlyEnrichmentWhenCompanyIdentityUnresolved() {
    Opportunity placeholder = opportunityWithIdentity(
      ' NEW COMPANY ',
      null,
      null,
      null
    );
    Assert.isFalse(
      GCPCalloutForOpportunitySummary.effectiveEnrichmentEnabled(
        true,
        placeholder
      ),
      'Expected false: GCPCalloutForOpportunitySummary.effectiveEnrichmentEnabled( true, placeholder )'
    );
    Map<String, Object> placeholderPayload = GCPCalloutForOpportunitySummary.buildOpportunityMap(
      placeholder,
      false
    );
    Assert.areEqual(
      'Example Opportunity',
      placeholderPayload.get('name'),
      'Unexpected value for placeholderPayload.get(\'name\')'
    );
    Assert.isFalse(
      placeholderPayload.containsKey('accountName'),
      'Expected false: placeholderPayload.containsKey(\'accountName\')'
    );

    Opportunity genericDomainWithoutWebsite = opportunityWithIdentity(
      'yahoo.com',
      null,
      null,
      null
    );
    Assert.isFalse(
      GCPCalloutForOpportunitySummary.effectiveEnrichmentEnabled(
        true,
        genericDomainWithoutWebsite
      ),
      'Expected false: GCPCalloutForOpportunitySummary.effectiveEnrichmentEnabled( true, genericDomainWithoutW...'
    );

    Opportunity genericDomainWithWebsite = opportunityWithIdentity(
      'yahoo.com',
      'https://verified-company.example.com',
      null,
      null
    );
    Assert.isTrue(
      GCPCalloutForOpportunitySummary.effectiveEnrichmentEnabled(
        true,
        genericDomainWithWebsite
      ),
      'Expected true: GCPCalloutForOpportunitySummary.effectiveEnrichmentEnabled( true, genericDomainWithWebs...'
    );
    Assert.isFalse(
      GCPCalloutForOpportunitySummary.effectiveEnrichmentEnabled(
        false,
        genericDomainWithWebsite
      ),
      'Company identity must never override the configured feature toggle.'
    );
  }

  @IsTest
  static void shouldRejectWebsiteWhenPrivateCredentialedOrNonHttp() {
    Assert.isNull(
      GCPCalloutForOpportunitySummary.sanitizedPublicWebsite(
        'https://user:secret@example.com'
      ),
      'Expected null: GCPCalloutForOpportunitySummary.sanitizedPublicWebsite( \'https://user:secret@example.co...'
    );
    Assert.isNull(
      GCPCalloutForOpportunitySummary.sanitizedPublicWebsite(
        'http://192.168.1.10/internal'
      ),
      'Expected null: GCPCalloutForOpportunitySummary.sanitizedPublicWebsite( \'http://192.168.1.10/internal\' )'
    );
    Assert.isNull(
      GCPCalloutForOpportunitySummary.sanitizedPublicWebsite(
        'ftp://example.com/file'
      ),
      'Expected null: GCPCalloutForOpportunitySummary.sanitizedPublicWebsite( \'ftp://example.com/file\' )'
    );
    Assert.areEqual(
      'https://www.example.com/public',
      GCPCalloutForOpportunitySummary.sanitizedPublicWebsite(
        ' https://www.example.com/public?token=removed#section '
      ),
      'Unexpected value for GCPCalloutForOpportunitySummary.sanitizedPublicWebsite( \' https://www.example.com/publi...'
    );
  }

  @IsTest
  static void shouldMapProductCatalogContextWhenLineItemsLoaded() {
    List<Map<String, Object>> populated = GCPCalloutForOpportunitySummary.buildLineItemRows(
      new List<SObject>{ lineItemWithProductContext() },
      true
    );
    Assert.areEqual(
      'Service',
      populated[0].get('productFamily'),
      'Unexpected value for populated[0].get(\'productFamily\')'
    );
    Assert.areEqual(
      'Contact Center',
      populated[0].get('productLine'),
      'Unexpected value for populated[0].get(\'productLine\')'
    );
    Assert.areEqual(
      '[210] Main',
      populated[0].get('productSubgroup'),
      'Unexpected value for populated[0].get(\'productSubgroup\')'
    );
    Assert.areEqual(
      '[200] Services',
      populated[0].get('productGroup'),
      'Unexpected value for populated[0].get(\'productGroup\')'
    );
    Assert.areEqual(
      'Customer-facing product description',
      populated[0].get('productDescription'),
      'Unexpected value for populated[0].get(\'productDescription\')'
    );
    Assert.areEqual(
      1001,
      ((String) populated[0].get('productCatalogDescription')).length(),
      'The existing text limit applies to catalogue descriptions.'
    );
    Assert.areEqual(
      'Collaboration Services',
      populated[0].get('productCategoryName'),
      'Unexpected value for populated[0].get(\'productCategoryName\')'
    );
    Assert.areEqual(
      new List<String>{ 'Core Licenses', 'Digital Lines' },
      (List<String>) populated[0].get('licenseGroups'),
      'Unexpected value for (List<String>) populated[0].get(\'licenseGroups\')'
    );
    Assert.areEqual(
      'OFFICE_LICENSE',
      populated[0].get('serviceCategory'),
      'Unexpected value for populated[0].get(\'serviceCategory\')'
    );
    Assert.isFalse(
      populated[0].containsKey('productCapabilities'),
      'Expected false: populated[0].containsKey(\'productCapabilities\')'
    );

    List<Map<String, Object>> unavailable = GCPCalloutForOpportunitySummary.buildLineItemRows(
      new List<SObject>{ lineItemWithProduct(false) },
      true
    );
    Assert.isFalse(
      unavailable[0].containsKey('productFamily'),
      'Expected false: unavailable[0].containsKey(\'productFamily\')'
    );
    Assert.isFalse(
      unavailable[0].containsKey('productLine'),
      'Expected false: unavailable[0].containsKey(\'productLine\')'
    );
    Assert.isFalse(
      unavailable[0].containsKey('productSubgroup'),
      'Expected false: unavailable[0].containsKey(\'productSubgroup\')'
    );
    Assert.isFalse(
      unavailable[0].containsKey('productGroup'),
      'Expected false: unavailable[0].containsKey(\'productGroup\')'
    );
    Assert.isFalse(
      unavailable[0].containsKey('productDescription'),
      'Expected false: unavailable[0].containsKey(\'productDescription\')'
    );
    Assert.isFalse(
      unavailable[0].containsKey('productCatalogDescription'),
      'Expected false: unavailable[0].containsKey(\'productCatalogDescription\')'
    );
    Assert.isFalse(
      unavailable[0].containsKey('productCategoryName'),
      'Expected false: unavailable[0].containsKey(\'productCategoryName\')'
    );
    Assert.isFalse(
      unavailable[0].containsKey('licenseGroups'),
      'Expected false: unavailable[0].containsKey(\'licenseGroups\')'
    );
    Assert.isFalse(
      unavailable[0].containsKey('serviceCategory'),
      'Expected false: unavailable[0].containsKey(\'serviceCategory\')'
    );
    Assert.areEqual(
      'Example Product',
      unavailable[0].get('productName'),
      'Unexpected value for unavailable[0].get(\'productName\')'
    );

    List<Map<String, Object>> inactiveFamily = GCPCalloutForOpportunitySummary.buildLineItemRows(
      new List<SObject>{ lineItemWithProductValues('Overage', ' Main ') },
      true
    );
    Assert.isFalse(
      inactiveFamily[0].containsKey('productFamily'),
      'Inactive or historical family values are not promoted into research context.'
    );
    Assert.areEqual(
      'Main',
      inactiveFamily[0].get('productLine'),
      'Unexpected value for inactiveFamily[0].get(\'productLine\')'
    );
  }

  @IsTest
  static void shouldMapAllLineItemsWhenOpportunityHasSeveral() {
    Integer queriesBefore = Limits.getQueries();
    List<Map<String, Object>> rows = GCPCalloutForOpportunitySummary.buildLineItemRows(
      new List<SObject>{
        lineItemWithProductContext(),
        lineItemWithProductValues('Service', 'Main')
      },
      true
    );

    Assert.areEqual(2, rows.size(), 'Unexpected value for rows.size()');
    Assert.areEqual(
      'Contact Center',
      rows[0].get('productLine'),
      'Unexpected value for rows[0].get(\'productLine\')'
    );
    Assert.areEqual(
      'Main',
      rows[1].get('productLine'),
      'Unexpected value for rows[1].get(\'productLine\')'
    );
    Assert.areEqual(
      queriesBefore,
      Limits.getQueries(),
      'Unexpected value for Limits.getQueries()'
    );
  }

  @IsTest
  static void shouldExcludeOwnerFromCustomersWhenMappingParticipants() {
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

    Assert.areEqual(
      1,
      participants.get(TASK_ID).size(),
      'Unexpected value for participants.get(TASK_ID).size()'
    );
    Assert.areEqual(
      CONTACT_ID,
      participants.get(TASK_ID)[0].get('contactId'),
      'A TaskRelation contact is included even without an Opportunity Contact Role.'
    );
    Assert.areEqual(
      'unknown',
      participants.get(TASK_ID)[0].get('participationStatus'),
      'Unexpected value for participants.get(TASK_ID)[0].get(\'participationStatus\')'
    );
    Assert.areEqual(
      2,
      participants.get(EVENT_ID).size(),
      'Unexpected value for participants.get(EVENT_ID).size()'
    );
    Assert.isFalse(
      containsContact(participants, TASK_ID, USER_ID),
      'The Salesforce activity owner must not become a customer participant.'
    );

    Map<String, Object> invitedParticipant = participantByContact(
      participants.get(EVENT_ID),
      CONTACT_ID
    );
    Assert.areEqual(
      'invited',
      invitedParticipant.get('participationStatus'),
      'Unexpected value for invitedParticipant.get(\'participationStatus\')'
    );
    Assert.areNotEqual(
      'attended',
      invitedParticipant.get('participationStatus'),
      'Invitation evidence must not be promoted to attendance.'
    );
    Assert.areEqual(
      'EventRelation invitee record',
      invitedParticipant.get('evidenceSource'),
      'Unexpected value for invitedParticipant.get(\'evidenceSource\')'
    );
  }

  @IsTest
  static void shouldOmitContactFieldsWhenInaccessible() {
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

    Assert.areEqual(
      CONTACT_ID,
      participant.get('contactId'),
      'Unexpected value for participant.get(\'contactId\')'
    );
    Assert.isFalse(
      participant.containsKey('name'),
      'Expected false: participant.containsKey(\'name\')'
    );
    Assert.isFalse(
      participant.containsKey('title'),
      'Expected false: participant.containsKey(\'title\')'
    );
  }

  @IsTest
  static void shouldReportCoverageStatusWhenDataEmptyOrInaccessible() {
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
    Assert.areEqual(
      'not_found',
      coverageEntry(emptyCoverage, 'lineItems').get('status'),
      'Unexpected value for coverageEntry(emptyCoverage, \'lineItems\').get(\'status\')'
    );

    lineItems.isAccessible = false;

    Map<String, Object> coverage = GCPCalloutForOpportunitySummary.buildDataCoverage(
      activityData,
      stakeholders,
      lineItems
    );
    Assert.areEqual(
      'not_found',
      coverageEntry(coverage, 'stakeholders').get('status'),
      'Unexpected value for coverageEntry(coverage, \'stakeholders\').get(\'status\')'
    );
    Assert.areEqual(
      'not_found',
      coverageEntry(coverage, 'activities').get('status'),
      'Unexpected value for coverageEntry(coverage, \'activities\').get(\'status\')'
    );
    Assert.areEqual(
      'not_found',
      coverageEntry(coverage, 'conversations').get('status'),
      'Unexpected value for coverageEntry(coverage, \'conversations\').get(\'status\')'
    );
    Assert.areEqual(
      'not_accessible',
      coverageEntry(coverage, 'lineItems').get('status'),
      'Unexpected value for coverageEntry(coverage, \'lineItems\').get(\'status\')'
    );
    Assert.areEqual(
      'transcripts_not_supported_no_recent_notes',
      coverageEntry(coverage, 'conversations').get('reasonCode'),
      'Unexpected value for coverageEntry(coverage, \'conversations\').get(\'reasonCode\')'
    );
  }

  @IsTest
  static void shouldDeduplicateAndTruncateNotesWhenBuildingConversationEvidence() {
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

    Assert.areEqual(
      1,
      result.items.size(),
      'Duplicate source records are removed.'
    );
    Map<String, Object> item = result.items[0];
    Assert.areEqual(
      EVENT_ID,
      item.get('sourceRecordId'),
      'Unexpected value for item.get(\'sourceRecordId\')'
    );
    Assert.areEqual(
      EVENT_ID,
      item.get('relatedActivityId'),
      'Unexpected value for item.get(\'relatedActivityId\')'
    );
    Assert.areEqual(
      'Event',
      item.get('sourceType'),
      'Unexpected value for item.get(\'sourceType\')'
    );
    Assert.areEqual(
      'notes',
      item.get('contentType'),
      'Unexpected value for item.get(\'contentType\')'
    );
    Assert.areEqual(
      4000,
      ((String) item.get('text')).length(),
      'Unexpected value for ((String) item.get(\'text\')).length()'
    );
    Assert.areEqual(
      true,
      item.get('isTruncated'),
      'Expected true: item.get(\'isTruncated\')'
    );
    Assert.isTrue(result.isTruncated, 'Expected true: result.isTruncated');
    Assert.areEqual(
      'text_limit',
      result.reasonCode,
      'Unexpected value for result.reasonCode'
    );
  }

  @IsTest
  static void shouldEnforceCountAndCompletionRulesWhenSelectingConversations() {
    Datetime windowEnd = Datetime.now();
    List<SObject> tasks = new List<SObject>();
    Map<Id, List<Map<String, Object>>> participants = new Map<Id, List<Map<String, Object>>>();
    for (Integer i = 1; i <= 11; i++) {
      Id taskId = syntheticId(Task.SObjectType, i);
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
    Id openTaskId = syntheticId(Task.SObjectType, 20);
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

    Assert.areEqual(
      10,
      result.items.size(),
      'Unexpected value for result.items.size()'
    );
    Assert.isTrue(result.isTruncated, 'Expected true: result.isTruncated');
    Assert.areEqual(
      'item_limit',
      result.reasonCode,
      'Unexpected value for result.reasonCode'
    );
  }

  @IsTest
  static void shouldPreserveCoreActivitiesWhenParticipantLookupFails() {
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

      Assert.areEqual(
        1,
        data.tasks.size(),
        'Unexpected value for data.tasks.size()'
      );
      Assert.areEqual(
        TASK_ID,
        data.tasks[0].get('sourceRecordId'),
        'Unexpected value for data.tasks[0].get(\'sourceRecordId\')'
      );
      Assert.areEqual(
        0,
        ((List<Map<String, Object>>) data.tasks[0].get('participants')).size(),
        'Unexpected value for ((List<Map<String, Object>>) data.tasks[0].get(\'participants\')).size()'
      );
      Assert.areEqual(
        'error',
        data.participantStatus,
        'Unexpected value for data.participantStatus'
      );
      Assert.areEqual(
        'error',
        data.conversationStatus,
        'Unexpected value for data.conversationStatus'
      );
      Assert.areEqual(
        0,
        data.conversations.size(),
        'Unexpected value for data.conversations.size()'
      );

      Map<String, Object> coverage = GCPCalloutForOpportunitySummary.buildDataCoverage(
        data,
        new GCPCalloutForOpportunitySummary.CollectionData(),
        new GCPCalloutForOpportunitySummary.CollectionData()
      );
      Assert.areEqual(
        'error',
        coverageEntry(coverage, 'conversations').get('status'),
        'Unexpected value for coverageEntry(coverage, \'conversations\').get(\'status\')'
      );
    } finally {
      resetTestHooks();
    }
  }

  @IsTest
  static void shouldTrimConversationEvidenceWhenPayloadOversized() {
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
      Assert.isTrue(
        Blob.valueOf(serialized).size() < 600,
        'Expected true: Blob.valueOf(serialized).size() < 600'
      );
      Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(
        serialized
      );
      Map<String, Object> coverage = (Map<String, Object>) parsed.get(
        'dataCoverage'
      );
      Map<String, Object> conversations = (Map<String, Object>) coverage.get(
        'conversations'
      );
      Assert.areEqual(
        true,
        conversations.get('isTruncated'),
        'Expected true: conversations.get(\'isTruncated\')'
      );
      Assert.areEqual(
        'request_size_limit',
        conversations.get('reasonCode'),
        'Unexpected value for conversations.get(\'reasonCode\')'
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
      Assert.areEqual(
        0,
        ((List<Object>) parsedTask.get('participants')).size(),
        'Unexpected value for ((List<Object>) parsedTask.get(\'participants\')).size()'
      );
      Map<String, Object> participantCoverage = (Map<String, Object>) participantParsed.get(
        'dataCoverage'
      );
      Assert.areEqual(
        'request_size_limit',
        ((Map<String, Object>) participantCoverage.get('activities'))
          .get('reasonCode'),
        'Unexpected value for ((Map<String, Object>) participantCoverage.get(\'activities\')) .get(\'reasonCode\')'
      );

      payload.put('core', 'x'.repeat(700));
      payload.put(
        'conversationEvidence',
        new Map<String, Object>{ 'items' => new List<Map<String, Object>>() }
      );
      try {
        GCPCalloutForOpportunitySummary.serializePayloadWithinLimit(payload);
        Assert.isTrue(false, 'An oversized core payload must fail explicitly.');
      } catch (Exception expected) {
        Assert.isTrue(
          expected.getMessage().contains('core request exceeds'),
          'Expected true: expected.getMessage().contains(\'core request exceeds\')'
        );
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
    Assert.areEqual(
      30,
      GCPCalloutForOpportunitySummary.getRecentEvidenceLookbackDays(),
      labelMessage
    );
    Assert.isFalse(
      GCPCalloutForOpportunitySummary.isOpportunitySummaryEnrichmentEnabled(),
      toggleMessage
    );
    setting.put('Enable_Opportunity_Summary_Enrichment__c', true);
    update setting;
    Assert.isTrue(
      GCPCalloutForOpportunitySummary.isOpportunitySummaryEnrichmentEnabled(),
      toggleMessage
    );
    GCPCalloutForOpportunitySummary.configurationOverrides.put(
      'RecentDays',
      '366'
    );
    Assert.areEqual(
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
      Assert.areEqual(
        50,
        GCPCalloutForOpportunitySummary.parsePositiveInteger(raw, 50, 50),
        fallbackMessage
      );
    }
    Assert.areEqual(
      1,
      GCPCalloutForOpportunitySummary.parsePositiveInteger(' 1 ', 50, 50),
      'The lower bound must be accepted.'
    );
    Assert.areEqual(
      50,
      GCPCalloutForOpportunitySummary.parsePositiveInteger('50', 50, 50),
      'The upper bound must be accepted.'
    );
    Assert.areEqual(
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
    Assert.areEqual(
      new Set<String>{ 'example.com', 'mail.example.org' },
      GCPCalloutForOpportunitySummary.parseConfigurationList(
        ' Example.com\n\nMAIL.EXAMPLE.ORG\r\nexample.com ',
        fallback,
        true
      ),
      'Lists must normalize case and whitespace and remove duplicates.'
    );
    Assert.areEqual(
      new Set<String>{ 'gmail.com' },
      GCPCalloutForOpportunitySummary.parseConfigurationList(
        '  ',
        fallback,
        true
      ),
      fallbackMessage
    );
    Assert.areEqual(
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
  private static void shouldExcludeIdentityValuesWhenConfigured() {
    GCPCalloutForOpportunitySummary.configurationOverrides.put(
      'UnresolvedNames',
      ' Placeholder Customer\nPLACEHOLDER CUSTOMER '
    );
    GCPCalloutForOpportunitySummary.configurationOverrides.put(
      'GenericEmailDomains',
      'personal.example'
    );
    Test.startTest();
    Assert.isFalse(
      GCPCalloutForOpportunitySummary.effectiveEnrichmentEnabled(
        true,
        opportunityWithIdentity('placeholder customer', null, null, null)
      ),
      'Configured placeholder names must disable enrichment.'
    );
    Assert.isFalse(
      GCPCalloutForOpportunitySummary.effectiveEnrichmentEnabled(
        true,
        opportunityWithIdentity('personal.example', null, null, null)
      ),
      'Configured generic domains must require a company website.'
    );
    Assert.isTrue(
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
  private static void shouldCapActivitiesAndConversationsWhenConfigured() {
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
      Id taskId = syntheticId(Task.SObjectType, sequence);
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
    Assert.isTrue(
      query.toLowerCase().contains('limit 5'),
      'Query must request the configured cap plus one overflow row.'
    );
    Assert.areEqual(
      1,
      result.items.size(),
      'Conversation cap must come from the label.'
    );
    Assert.isTrue(
      result.isTruncated,
      'Coverage must still report truncation under configured caps.'
    );
    resetTestHooks();
  }

  @IsTest
  static void shouldSendEnrichmentFlagAsBooleanWhenBuildingRequest() {
    Map<String, Object> payload = new Map<String, Object>();

    GCPCalloutForOpportunitySummary.addEnrichmentRequestControl(payload, false);
    Assert.areEqual(
      false,
      payload.get('enableOpportunitySummaryEnrichment'),
      'Expected false: payload.get(\'enableOpportunitySummaryEnrichment\')'
    );

    GCPCalloutForOpportunitySummary.addEnrichmentRequestControl(payload, true);
    Assert.areEqual(
      true,
      payload.get('enableOpportunitySummaryEnrichment'),
      'Expected true: payload.get(\'enableOpportunitySummaryEnrichment\')'
    );
  }

  @IsTest
  static void shouldUseExactEndpointWhenBaseUrlConfigured() {
    Assert.areEqual(
      'https://service.example.invalid/api/v1/opportunity_summary',
      GCPCalloutForOpportunitySummary.buildServiceEndpoint(
        'https://service.example.invalid/api/v1/another_route'
      ),
      'Unexpected value for GCPCalloutForOpportunitySummary.buildServiceEndpoint( \'https://service.example.invalid/...'
    );
  }

  @IsTest
  static void shouldParseLegacyResponseWhenEnrichmentAbsent() {
    Object raw = JSON.deserializeUntyped(
      '{"statusCode":200,"body":{"opportunity_summary":{"Executive Summary":["CRM summary"]}}}'
    );

    Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(
      GCPCalloutForOpportunitySummary.buildResult(raw)
    );

    Assert.areEqual(
      true,
      result.get('success'),
      'Expected true: result.get(\'success\')'
    );
    Assert.areEqual(
      1,
      ((List<Object>) result.get('cards')).size(),
      'Unexpected value for ((List<Object>) result.get(\'cards\')).size()'
    );
    Assert.isFalse(
      result.containsKey('opportunity_enrichment'),
      'The optional field must remain absent for legacy responses.'
    );
  }

  @IsTest
  static void shouldPassEnrichmentThroughWhenFieldsAreSnakeCase() {
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

    Assert.areEqual(
      true,
      result.get('success'),
      'Expected true: result.get(\'success\')'
    );
    Assert.areEqual(
      7,
      ((List<Object>) finding.get('source_indices'))[0],
      'Unexpected value for ((List<Object>) finding.get(\'source_indices\'))[0]'
    );
    Assert.areEqual(
      'not_established',
      supplementalUpdates.get('relationship_to_opportunity'),
      'Unexpected value for supplementalUpdates.get(\'relationship_to_opportunity\')'
    );
    Assert.areEqual(
      'E2',
      supplementalItem.get('id'),
      'Unexpected value for supplementalItem.get(\'id\')'
    );
    Assert.areEqual(
      8,
      ((List<Object>) supplementalItem.get('source_indices'))[0],
      'Unexpected value for ((List<Object>) supplementalItem.get(\'source_indices\'))[0]'
    );
    Assert.areEqual(
      '<style>.chip{}</style><a href="https://google.com">Search</a>',
      searchEntryPoint.get('rendered_content'),
      'Unexpected value for searchEntryPoint.get(\'rendered_content\')'
    );
  }

  @IsTest
  static void shouldKeepSummaryWhenEnrichmentMalformed() {
    Object raw = JSON.deserializeUntyped(
      '{"statusCode":200,"body":{"opportunity_summary":{"Risk Flags":["CRM risk"]},"opportunity_enrichment":["invalid"]}}'
    );

    Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(
      GCPCalloutForOpportunitySummary.buildResult(raw)
    );

    Assert.areEqual(
      true,
      result.get('success'),
      'Expected true: result.get(\'success\')'
    );
    Assert.areEqual(
      1,
      ((List<Object>) result.get('cards')).size(),
      'Unexpected value for ((List<Object>) result.get(\'cards\')).size()'
    );
    Assert.isFalse(
      result.containsKey('opportunity_enrichment'),
      'Expected false: result.containsKey(\'opportunity_enrichment\')'
    );
  }

  @IsTest
  static void shouldSendViewerContextWhenBuildingPayload() {
    Map<String, Object> payload = new Map<String, Object>();

    Test.startTest();
    GCPCalloutForOpportunitySummary.addViewerContext(payload);
    Test.stopTest();

    Assert.areEqual(
      UserInfo.getTimeZone().getID(),
      payload.get('viewerTimeZone'),
      'Time zone must describe the viewing user.'
    );
    Assert.areEqual(
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

    Assert.isTrue(
      closedPayload.get('isClosed') instanceof Boolean,
      'Expected true: closedPayload.get(\'isClosed\') instanceof Boolean'
    );
    Assert.areEqual(
      true,
      closedPayload.get('isClosed'),
      'Expected true: closedPayload.get(\'isClosed\')'
    );
    Assert.areEqual(
      false,
      closedPayload.get('isWon'),
      'Expected false: closedPayload.get(\'isWon\')'
    );
    Assert.isFalse(
      unreadablePayload.containsKey('isClosed'),
      'Unreadable flags must be omitted, never sent as null or text.'
    );
    Assert.isFalse(
      unreadablePayload.containsKey('isWon'),
      'Expected false: unreadablePayload.containsKey(\'isWon\')'
    );
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

    Assert.areEqual(
      'Upsell + Downsell',
      classifiedPayload.get('dealMotion'),
      'Unexpected value for classifiedPayload.get(\'dealMotion\')'
    );
    Assert.areEqual(
      'Transportation, Travel & Leisure',
      classifiedPayload.get('sector'),
      'Unexpected value for classifiedPayload.get(\'sector\')'
    );
    Assert.isFalse(
      blankPayload.containsKey('dealMotion'),
      'Expected false: blankPayload.containsKey(\'dealMotion\')'
    );
    Assert.isFalse(
      blankPayload.containsKey('sector'),
      'Expected false: blankPayload.containsKey(\'sector\')'
    );
    Assert.isFalse(
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

      Assert.areEqual(
        1,
        activityData.conversations.size(),
        'Conversation notes must not depend on the enrichment toggle.'
      );
      Assert.areEqual(
        'Buyer agreed to the pricing.',
        activityData.conversations[0].get('text'),
        'Unexpected value for activityData.conversations[0].get(\'text\')'
      );
      Assert.isFalse(
        activityData.tasks[0].containsKey('participants'),
        'Activity rows keep their non-enrichment shape.'
      );
      Assert.isFalse(
        activityData.tasks[0].containsKey('sourceRecordId'),
        'Expected false: activityData.tasks[0].containsKey(\'sourceRecordId\')'
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

    Assert.areEqual(
      'Lost',
      lostPayload.get('lossReason'),
      'Unexpected value for lostPayload.get(\'lossReason\')'
    );
    Assert.areEqual(
      'Price',
      lostPayload.get('lossReasonDetail'),
      'Unexpected value for lostPayload.get(\'lossReasonDetail\')'
    );
    Assert.areEqual(
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
      Assert.isFalse(
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
          syntheticId(Task.SObjectType, 2),
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

    Assert.areEqual(
      'Call',
      activityData.tasks[0].get('taskSubtype'),
      'Unexpected value for activityData.tasks[0].get(\'taskSubtype\')'
    );
    Assert.isFalse(
      activityData.tasks[1].containsKey('taskSubtype'),
      'A blank subtype is left out.'
    );
  }

  @IsTest
  static void shouldNameAccountAndContactsSentWhenBuildingReferences() {
    Id sharedNameContactId = syntheticId(Contact.SObjectType, 3);
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
          'id' => syntheticId(Opportunity.SObjectType, 2),
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
            'id' => syntheticId(Case.SObjectType, 1),
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
            'id' => syntheticId(Task.SObjectType, 2),
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
          'contactId' => syntheticId(Contact.SObjectType, 4),
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
    Assert.areEqual(
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
      Assert.isTrue(referenceableIds.contains(expectedId), expectedId);
    }
    Assert.isFalse(
      referenceableIds.contains(OPPORTUNITY_ID),
      'Expected false: referenceableIds.contains(OPPORTUNITY_ID)'
    );
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
    Assert.areEqual(
      2,
      references.size(),
      'A record GCP referenced keeps only GCP\'s link; Salesforce adds the Account.'
    );
    Map<String, Object> accountReference = (Map<String, Object>) references[1];
    Assert.areEqual(
      'Account',
      accountReference.get('object_type'),
      'Unexpected value for accountReference.get(\'object_type\')'
    );
    Assert.areEqual(
      'salesforce',
      accountReference.get('source'),
      'Unexpected value for accountReference.get(\'source\')'
    );
    Assert.areEqual(
      new List<Object>{ 'Executive Summary', 'Next Best Actions' },
      accountReference.get('mentioned_in'),
      'Unexpected value for accountReference.get(\'mentioned_in\')'
    );
  }

  @IsTest
  static void shouldCollectReferenceableIdsWhenPayloadHasCasesAndActivities() {
    Id caseId = syntheticId(Case.SObjectType, 1);
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

    Assert.areEqual(
      new Set<Id>{ caseId, TASK_ID, EVENT_ID },
      ids,
      'Only Case, Task and Event Ids sent to GCP may become links.'
    );
  }

  @IsTest
  static void shouldPassClosedDealFieldsAndOnlySentReferencesWhenBuildingResult() {
    Id caseId = syntheticId(Case.SObjectType, 1);
    Id unsentCaseId = syntheticId(Case.SObjectType, 2);
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

    Assert.areEqual(
      true,
      result.get('success'),
      'Expected true: result.get(\'success\')'
    );
    Assert.areEqual(
      2,
      ((List<Object>) result.get('cards')).size(),
      'Unexpected value for ((List<Object>) result.get(\'cards\')).size()'
    );
    Map<String, Object> dealState = (Map<String, Object>) result.get(
      'deal_state'
    );
    Assert.areEqual(
      true,
      dealState.get('is_closed'),
      'Expected true: dealState.get(\'is_closed\')'
    );
    Assert.areEqual(
      'Upsell',
      ((Map<String, Object>) result.get('salesforce_fields'))
        .get('deal_motion'),
      'Unexpected value for ((Map<String, Object>) result.get(\'salesforce_fields\')).get(\'deal_motion\')'
    );
    List<Object> references = (List<Object>) result.get('record_references');
    Assert.areEqual(
      1,
      references.size(),
      'Unsent, mistyped, unsupported and unplaced references must be dropped.'
    );
    Map<String, Object> reference = (Map<String, Object>) references[0];
    Assert.areEqual(
      String.valueOf(caseId),
      reference.get('id'),
      'Unexpected value for reference.get(\'id\')'
    );
    Assert.areEqual(
      '00012345',
      reference.get('case_number'),
      'Unexpected value for reference.get(\'case_number\')'
    );
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

  private static Id syntheticId(Schema.SObjectType type, Integer sequence) {
    return Id.valueOf(
      type.getDescribe().getKeyPrefix() +
      String.valueOf(sequence).leftPad(12, '0')
    );
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
  static void shouldSendCallTranscriptsTrueWhenSettingOn() {
    Map<String, Object> payload = serializedPayloadWithTranscriptSetting(true);

    Assert.isTrue(
      payload.get('enableOpportunitySummaryCallTranscripts') instanceof Boolean,
      'The switch must serialize as a JSON boolean, not a string.'
    );
    Assert.areEqual(
      true,
      payload.get('enableOpportunitySummaryCallTranscripts'),
      'Expected true: payload.get(\'enableOpportunitySummaryCallTranscripts\')'
    );
  }

  @IsTest
  static void shouldSendCallTranscriptsFalseWhenSettingOff() {
    Map<String, Object> payload = serializedPayloadWithTranscriptSetting(false);

    Assert.isTrue(
      payload.get('enableOpportunitySummaryCallTranscripts') instanceof Boolean,
      'The switch must serialize as a JSON boolean, not a string.'
    );
    Assert.areEqual(
      false,
      payload.get('enableOpportunitySummaryCallTranscripts'),
      'Expected false: payload.get(\'enableOpportunitySummaryCallTranscripts\')'
    );
  }

  @IsTest
  static void shouldSendCallTranscriptsFalseWhenNoSettingRecordExists() {
    Assert.areEqual(
      0,
      [SELECT COUNT() FROM GCP_Feature_Toggle__c],
      'Unexpected value for [SELECT COUNT() FROM GCP_Feature_Toggle__c]'
    );

    Map<String, Object> payload = serializedPayloadWithTranscriptSetting(null);

    Assert.isTrue(
      payload.containsKey('enableOpportunitySummaryCallTranscripts'),
      'The field is always sent, never omitted.'
    );
    Assert.areEqual(
      false,
      payload.get('enableOpportunitySummaryCallTranscripts'),
      'Expected false: payload.get(\'enableOpportunitySummaryCallTranscripts\')'
    );
  }

  @IsTest
  static void shouldAlwaysSendRequestControlWhenBuildingRequest() {
    Map<String, Object> payload = new Map<String, Object>();

    GCPCalloutForOpportunitySummary.addCallTranscriptsRequestControl(
      payload,
      null
    );

    Assert.areEqual(
      false,
      payload.get('enableOpportunitySummaryCallTranscripts'),
      'Expected false: payload.get(\'enableOpportunitySummaryCallTranscripts\')'
    );
  }

  @IsTest
  static void shouldRenderSameCardWhenCallTranscriptsBlockPresentOrAbsent() {
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

    Assert.areEqual(
      true,
      ((Map<String, Object>) JSON.deserializeUntyped(resultWith))
        .get('success'),
      'Expected true: ((Map<String, Object>) JSON.deserializeUntyped(resultWith)).get(\'success\')'
    );
    Assert.areEqual(
      resultWithout,
      resultWith,
      'The optional call_transcripts block must not change what the UI receives.'
    );
  }

  @IsTest
  static void shouldPassCallInsightsThroughWhenPresent() {
    Object raw = JSON.deserializeUntyped(
      '{"statusCode":200,"body":{' +
        '"opportunity_summary":{"Executive Summary":["Healthy deal","Buyer needs 400 seats by March"]},' +
        '"call_insights":[{"section":"Executive Summary","index":1}]}}'
    );

    Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(
      GCPCalloutForOpportunitySummary.buildResult(raw)
    );

    List<Object> insights = (List<Object>) result.get('call_insights');
    Assert.areEqual(1, insights.size(), 'Unexpected value for insights.size()');
    Map<String, Object> insight = (Map<String, Object>) insights[0];
    Assert.areEqual(
      'Executive Summary',
      insight.get('section'),
      'Unexpected value for insight.get(\'section\')'
    );
    Assert.areEqual(
      1,
      insight.get('index'),
      'Unexpected value for insight.get(\'index\')'
    );
    Assert.areEqual(
      'Buyer needs 400 seats by March',
      ((List<Object>) ((Map<String, Object>) ((List<Object>) result.get(
          'cards'
        ))[0])
        .get('items'))[1],
      'Line text must reach the UI unchanged.'
    );
  }

  @IsTest
  static void shouldOmitCallInsightsWhenAbsentOrMalformed() {
    String summary = '"opportunity_summary":{"Executive Summary":["CRM summary"]}';
    Map<String, Object> absent = (Map<String, Object>) JSON.deserializeUntyped(
      GCPCalloutForOpportunitySummary.buildResult(
        JSON.deserializeUntyped('{"statusCode":200,"body":{' + summary + '}}')
      )
    );
    Map<String, Object> malformed = (Map<String, Object>) JSON.deserializeUntyped(
      GCPCalloutForOpportunitySummary.buildResult(
        JSON.deserializeUntyped(
          '{"statusCode":200,"body":{' +
            summary +
            ',"call_insights":"Executive Summary"}}'
        )
      )
    );

    Assert.isFalse(
      absent.containsKey('call_insights'),
      'Expected false: absent.containsKey(\'call_insights\')'
    );
    Assert.isFalse(
      malformed.containsKey('call_insights'),
      'Expected false: malformed.containsKey(\'call_insights\')'
    );
    Assert.areEqual(
      true,
      malformed.get('success'),
      'Expected true: malformed.get(\'success\')'
    );
  }

  // ---------------- makeGCPCallout entry point ----------------
  // These tests insert no Task or Event, so they do not depend on activity triggers.

  private static Id summaryOpportunityId(Boolean hasEndpointSettings) {
    new SObjectBuilder(ByPassTrigger__c.SObjectType)
      .setField(ByPassTrigger__c.SetupOwnerId, UserInfo.getOrganizationId())
      .setField(ByPassTrigger__c.Bypass_Account_Trigger__c, true)
      .setField(ByPassTrigger__c.Bypass_Opportunity_Trigger__c, true)
      .create();
    if (hasEndpointSettings) {
      new SObjectBuilder(GCP_Endpoint_Settings__c.SObjectType)
        .setField(
          GCP_Endpoint_Settings__c.SetupOwnerId,
          UserInfo.getOrganizationId()
        )
        .setField(
          GCP_Endpoint_Settings__c.Service_Account_Email__c,
          'service@example.invalid'
        )
        .setField(GCP_Endpoint_Settings__c.Identity_Token_URL__c, TOKEN_URL)
        .setField(
          GCP_Endpoint_Settings__c.Certificate_Name__c,
          SIGNING_CERTIFICATE
        )
        .setField(
          GCP_Endpoint_Settings__c.Opportunity_Summary_Endpoint__c,
          SUMMARY_ENDPOINT
        )
        .create();
    }
    Account account = (Account) new SObjectBuilder(Account.SObjectType)
      .setField(
        Account.Name,
        ValueProviderBuilder.provideUniqueString('Callout company')
      )
      .create()
      .getRecord();
    return new SObjectBuilder(Opportunity.SObjectType)
      .setField(Opportunity.AccountId, account.Id)
      .setField(Opportunity.CloseDate, Date.today().addDays(30))
      .create()
      .getRecord()
      .Id;
  }

  private static Map<String, Object> calloutResult(Id opportunityId) {
    return (Map<String, Object>) JSON.deserializeUntyped(
      GCPCalloutForOpportunitySummary.makeGCPCallout(
        UserInfo.getUserId(),
        opportunityId
      )
    );
  }

  @IsTest
  static void shouldReturnSummaryCardsWhenCalloutSucceeds() {
    Id opportunityId = summaryOpportunityId(true);
    Test.setMock(
      HttpCalloutMock.class,
      new SummaryServiceMock(200, SUMMARY_RESPONSE)
    );

    Test.startTest();
    Map<String, Object> result = calloutResult(opportunityId);
    Test.stopTest();

    String successMessage = 'A 200 response with a summary must succeed.';
    String cardMessage = 'The summary line must reach the UI as a card item.';
    Assert.areEqual(true, result.get('success'), successMessage);
    List<Object> cards = (List<Object>) result.get('cards');
    Assert.isFalse(cards.isEmpty(), cardMessage);
    Assert.areEqual(
      SUMMARY_LINE,
      ((List<Object>) ((Map<String, Object>) cards[0]).get('items'))[0],
      cardMessage
    );
  }

  @IsTest
  static void shouldReturnGenericErrorWhenCloudRunRejects() {
    Id opportunityId = summaryOpportunityId(true);
    Test.setMock(
      HttpCalloutMock.class,
      new SummaryServiceMock(500, '{"error":"boom"}')
    );

    Test.startTest();
    Map<String, Object> result = calloutResult(opportunityId);
    Test.stopTest();

    String failureMessage = 'A failed Cloud Run call must return the generic error only.';
    Assert.areEqual(false, result.get('success'), failureMessage);
    Assert.areEqual(
      System.Label.SummaryServerError,
      result.get('message'),
      failureMessage
    );
  }

  @IsTest
  static void shouldReturnGenericErrorWhenResponseBodyIsBlank() {
    Id opportunityId = summaryOpportunityId(true);
    Test.setMock(HttpCalloutMock.class, new SummaryServiceMock(200, ''));

    Test.startTest();
    Map<String, Object> result = calloutResult(opportunityId);
    Test.stopTest();

    String blankMessage = 'An empty Cloud Run response must return the generic error.';
    Assert.areEqual(false, result.get('success'), blankMessage);
    Assert.areEqual(
      System.Label.SummaryServerError,
      result.get('message'),
      blankMessage
    );
  }

  @IsTest
  static void shouldReturnGenericErrorWhenEndpointSettingsAreMissing() {
    Id opportunityId = summaryOpportunityId(false);

    Test.startTest();
    Map<String, Object> result = calloutResult(opportunityId);
    Test.stopTest();

    String configMessage = 'Missing endpoint settings must return the generic error.';
    Assert.areEqual(false, result.get('success'), configMessage);
    Assert.areEqual(
      System.Label.SummaryServerError,
      result.get('message'),
      configMessage
    );
  }

  @IsTest
  static void shouldReturnGenericErrorWhenRecordIdIsBlank() {
    Test.startTest();
    Map<String, Object> result = calloutResult(null);
    Test.stopTest();

    String blankIdMessage = 'A blank record Id must return the generic error.';
    Assert.areEqual(false, result.get('success'), blankIdMessage);
    Assert.areEqual(
      System.Label.SummaryServerError,
      result.get('message'),
      blankIdMessage
    );
  }

  @IsTest
  static void shouldReportSummaryEnabledWhenToggleIsOn() {
    new SObjectBuilder(GCP_Feature_Toggle__c.SObjectType)
      .setField(
        GCP_Feature_Toggle__c.SetupOwnerId,
        UserInfo.getOrganizationId()
      )
      .setField(GCP_Feature_Toggle__c.Enable_Opportunity_Summary__c, true)
      .create();

    Test.startTest();
    Boolean isEnabled = GCPCalloutForOpportunitySummary.isOpportunitySummaryEnabled();
    Test.stopTest();

    String enabledMessage = 'The Opportunity Summary toggle must read the org default.';
    Assert.isTrue(isEnabled, enabledMessage);
  }

  private class SummaryServiceMock implements HttpCalloutMock {
    private Integer summaryStatusCode;
    private String summaryBody;

    private SummaryServiceMock(Integer summaryStatusCode, String summaryBody) {
      this.summaryStatusCode = summaryStatusCode;
      this.summaryBody = summaryBody;
    }

    public HttpResponse respond(HttpRequest request) {
      HttpResponse response = new HttpResponse();
      if (request.getEndpoint() == TOKEN_URL) {
        response.setStatusCode(200);
        response.setBody(
          JSON.serialize(new Map<String, Object>{ 'id_token' => ID_TOKEN })
        );
        return response;
      }
      String endpointMessage = 'The summary request must go to the Opportunity Summary path.';
      String tokenMessage = 'The exchanged identity token must be sent.';
      Assert.areEqual(SUMMARY_ENDPOINT, request.getEndpoint(), endpointMessage);
      Assert.areEqual(
        'Bearer ' + ID_TOKEN,
        request.getHeader('Authorization'),
        tokenMessage
      );
      response.setStatusCode(summaryStatusCode);
      response.setBody(summaryBody);
      return response;
    }
  }
}
