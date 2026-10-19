/*
 * Builds the request payload for the Opportunity Summary service: the Opportunity, its history,
 * stakeholders, cases, line items and related Opportunities, plus data coverage, trimmed to fit
 * the request size limit. OpportunitySummaryHelper sends it.
 */
public with sharing class OpportunitySummaryPayloadHelper {
  public static final String RELATIONSHIP_OWNER = 'Owner';
  private static final String RELATIONSHIP_ACCOUNT = 'Account';
  private static final String RELATIONSHIP_CONTACT = 'Contact';
  private static final String RELATIONSHIP_PRODUCT = 'Product2';

  private static final String ENRICHMENT_REQUEST_FIELD = 'enableOpportunitySummaryEnrichment';
  private static final String CALL_TRANSCRIPTS_REQUEST_FIELD = 'enableOpportunitySummaryCallTranscripts';

  private static final List<Schema.SObjectField> TRACKED_HISTORY_FIELDS = new List<Schema.SObjectField>{
    Opportunity.CloseDate,
    Opportunity.Amount,
    Opportunity.Probability
  };

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
      return OpportunitySummaryHelper.configuredInteger(
        Summary_Setting__mdt.ClosedCaseMonths__c,
        6,
        24
      );
    }
  }

  private static Integer maxHistoryRows {
    get {
      return OpportunitySummaryHelper.configuredInteger(
        Summary_Setting__mdt.MaxHistoryRows__c,
        50,
        200
      );
    }
  }

  private static Integer maxOpenCases {
    get {
      return OpportunitySummaryHelper.configuredInteger(
        Summary_Setting__mdt.MaxOpenCases__c,
        50,
        200
      );
    }
  }

  private static Integer maxClosedCases {
    get {
      return OpportunitySummaryHelper.configuredInteger(
        Summary_Setting__mdt.MaxClosedCases__c,
        50,
        200
      );
    }
  }

  private static Integer maxRelatedOpps {
    get {
      return OpportunitySummaryHelper.configuredInteger(
        Summary_Setting__mdt.MaxRelatedOpps__c,
        25,
        100
      );
    }
  }

  private static Integer maxLineItems {
    get {
      return OpportunitySummaryHelper.configuredInteger(
        Summary_Setting__mdt.MaxLineItems__c,
        50,
        200
      );
    }
  }

  private static Integer maxStakeholders {
    get {
      return OpportunitySummaryHelper.configuredInteger(
        Summary_Setting__mdt.MaxStakeholders__c,
        25,
        100
      );
    }
  }

  private static final Integer MAX_DESCRIPTION_LENGTH = 1000;
  private static final Integer MAX_LOSS_FIELD_LENGTH = 300;

  private static final Integer MAX_REQUEST_BYTES = 2 * 1024 * 1024;

  @TestVisible
  private static Integer requestSizeLimitBytes = MAX_REQUEST_BYTES;

  private static final String REASON_REQUEST_SIZE_LIMIT = 'request_size_limit';
  /* Coverage entries are marked after trimming, and each can grow by one reason code. */
  private static final Integer COVERAGE_HEADROOM_BYTES = 128;

  public static Map<String, Object> buildPayload(String username, Id recordId) {
    Opportunity opp = getOpportunity(recordId);
    Boolean enrichmentEnabled = effectiveEnrichmentEnabled(
      OpportunitySummaryHelper.isOpportunitySummaryEnrichmentEnabled(),
      opp
    );
    Integer recentEvidenceDays = OpportunitySummaryHelper.getRecentEvidenceLookbackDays();
    // AccountId may have been stripped for FLS; fall back to null (no related account context).
    Id accountId = (Id) GCPSummaryUtil.readableField(
      opp,
      Opportunity.AccountId
    );

    Map<String, Object> caseBuckets = getCases(accountId);
    OpportunitySummaryActivityHelper.ActivityData activityData = OpportunitySummaryActivityHelper.getActivityData(
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
      OpportunitySummaryHelper.isOpportunitySummaryCallTranscriptsEnabled()
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
      .selectOpportunityForSummary(recordId)
      .executeQuery();
    if (opps.isEmpty()) {
      throw new QueryException('Opportunity not found for Id ' + recordId);
    }
    // FLS: QueryFactory runs Database.query (system mode), and `with sharing` only enforces
    // row-level sharing — strip fields the running user cannot read before the GCP payload.
    return (Opportunity) GCPSummaryUtil.stripReadable(opps)[0];
  }

  @TestVisible
  private static Map<String, Object> buildOpportunityMap(
    Opportunity opp,
    Boolean enrichmentEnabled
  ) {
    SObject owner = readableRelated(opp, RELATIONSHIP_OWNER);
    SObject relatedAccount = readableRelated(opp, RELATIONSHIP_ACCOUNT);
    Map<String, Object> opportunityMap = new Map<String, Object>{
      'id' => GCPSummaryUtil.readableField(opp, Opportunity.Id),
      'name' => GCPSummaryUtil.readableField(opp, Opportunity.Name),
      'amount' => GCPSummaryUtil.readableField(opp, Opportunity.Amount),
      'currencyIsoCode' => GCPSummaryUtil.readableField(
        opp,
        Opportunity.CurrencyIsoCode
      ),
      'type' => GCPSummaryUtil.readableField(opp, Opportunity.Type),
      'leadSource' => GCPSummaryUtil.readableField(opp, Opportunity.LeadSource),
      'stageName' => GCPSummaryUtil.readableField(opp, Opportunity.StageName),
      'probability' => GCPSummaryUtil.readableField(
        opp,
        Opportunity.Probability
      ),
      'forecastCategory' => GCPSummaryUtil.readableField(
        opp,
        Opportunity.ForecastCategory
      ),
      'closeDate' => GCPSummaryUtil.readableField(opp, Opportunity.CloseDate),
      'createdDate' => GCPSummaryUtil.readableField(
        opp,
        Opportunity.CreatedDate
      ),
      'lastModifiedDate' => GCPSummaryUtil.readableField(
        opp,
        Opportunity.LastModifiedDate
      ),
      'nextStep' => GCPSummaryUtil.readableField(opp, Opportunity.NextStep),
      'description' => truncateText(
        (String) GCPSummaryUtil.readableField(opp, Opportunity.Description)
      ),
      'ownerId' => GCPSummaryUtil.readableField(opp, Opportunity.OwnerId),
      'ownerName' => GCPSummaryUtil.readableField(owner, User.Name),
      'accountId' => GCPSummaryUtil.readableField(opp, Opportunity.AccountId),
      'accountIndustry' => GCPSummaryUtil.readableField(
        relatedAccount,
        Account.Industry
      ),
      'accountCity' => GCPSummaryUtil.readableField(
        relatedAccount,
        Account.BillingCity
      ),
      'accountCountry' => GCPSummaryUtil.readableField(
        relatedAccount,
        Account.BillingCountry
      )
    };
    putIfPresent(opportunityMap, 'accountName', resolvedAccountName(opp));
    // GCP rejects non-boolean values, so omit the flags when they are unreadable.
    putIfPresent(
      opportunityMap,
      'isClosed',
      GCPSummaryUtil.readableField(opp, Opportunity.IsClosed)
    );
    putIfPresent(
      opportunityMap,
      'isWon',
      GCPSummaryUtil.readableField(opp, Opportunity.IsWon)
    );
    // Order_Type__c is the acquisition/upsell/downsell picklist; sent unchanged.
    // Type (New/Existing/Renewal) is not a deal motion and is already sent as `type`.
    putIfPresent(
      opportunityMap,
      'dealMotion',
      normalizedText(
        GCPSummaryUtil.readableField(opp, Opportunity.Order_Type__c)
      )
    );
    // Loss context for closed deals; GCP accepts at most 300 characters per key.
    putIfPresent(
      opportunityMap,
      'lossReason',
      lossFieldText(
        GCPSummaryUtil.readableField(opp, Opportunity.Downgrade_Reason_Opp__c)
      )
    );
    putIfPresent(
      opportunityMap,
      'lossReasonDetail',
      lossFieldText(
        GCPSummaryUtil.readableField(opp, Opportunity.Primary_Loss_Reason__c)
      )
    );
    putIfPresent(
      opportunityMap,
      'lostToCompetitor',
      lossFieldText(
        GCPSummaryUtil.readableField(opp, Opportunity.Primary_Competitor__c)
      )
    );
    // Sector exists only on Account (text, not a picklist).
    putIfPresent(
      opportunityMap,
      'sector',
      normalizedText(
        GCPSummaryUtil.readableField(relatedAccount, Account.Sector__c)
      )
    );
    putIfPresent(
      opportunityMap,
      'intendedProduct',
      normalizedText(
        GCPSummaryUtil.readableField(opp, Opportunity.Intended_Product__c)
      )
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
        GCPSummaryUtil.readableField(relatedAccount, Account.BillingState)
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
    SObject relatedAccount = readableRelated(opp, RELATIONSHIP_ACCOUNT);
    String accountName = normalizedText(
      GCPSummaryUtil.readableField(relatedAccount, Account.Name)
    );
    return String.isBlank(accountName) ||
      OpportunitySummaryHelper.configuredList(
          Summary_Setting__mdt.UnresolvedNames__c,
          UNRESOLVED_ACCOUNT_NAMES,
          false
        )
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
      String domain : OpportunitySummaryHelper.configuredList(
        Summary_Setting__mdt.GenericEmailDomains__c,
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
    SObject relatedAccount = readableRelated(opp, RELATIONSHIP_ACCOUNT);
    String accountWebsite = normalizedText(
      GCPSummaryUtil.readableField(relatedAccount, Account.Website)
    );
    if (String.isNotBlank(accountWebsite)) {
      return sanitizedPublicWebsite(accountWebsite);
    }
    return sanitizedPublicWebsite(
      normalizedText(GCPSummaryUtil.readableField(opp, Opportunity.Website__c))
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
      // Free-text website values are often not URLs; they are dropped, not reported.
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

  public static String normalizedText(Object rawValue) {
    if (!(rawValue instanceof String)) {
      return null;
    }
    String normalized = ((String) rawValue).trim();
    return String.isBlank(normalized) ? null : normalized;
  }

  private static List<Map<String, Object>> getStageHistory(Id recordId) {
    List<Map<String, Object>> rows = new List<Map<String, Object>>();
    // Selector returns newest first; reverse so the payload stays chronological.
    List<SObject> histories = GCPSummaryUtil.stripReadable(
      new OpportunityHistorySelector()
        .selectStageHistoryByOpportunityId(recordId)
        .setLimit(maxHistoryRows)
        .executeQuery()
    );
    for (Integer i = histories.size() - 1; i >= 0; i--) {
      OpportunityHistory h = (OpportunityHistory) histories[i];
      rows.add(
        new Map<String, Object>{
          'stageName' => GCPSummaryUtil.readableField(
            h,
            OpportunityHistory.StageName
          ),
          'amount' => GCPSummaryUtil.readableField(
            h,
            OpportunityHistory.Amount
          ),
          'probability' => GCPSummaryUtil.readableField(
            h,
            OpportunityHistory.Probability
          ),
          'closeDate' => GCPSummaryUtil.readableField(
            h,
            OpportunityHistory.CloseDate
          ),
          'forecastCategory' => GCPSummaryUtil.readableField(
            h,
            OpportunityHistory.ForecastCategory
          ),
          'createdDate' => GCPSummaryUtil.readableField(
            h,
            OpportunityHistory.CreatedDate
          )
        }
      );
    }
    return rows;
  }

  private static List<Map<String, Object>> getFieldHistory(Id recordId) {
    List<Map<String, Object>> rows = new List<Map<String, Object>>();
    Set<String> trackedFields = new Set<String>();
    for (Schema.SObjectField field : TRACKED_HISTORY_FIELDS) {
      trackedFields.add(field.getDescribe().getName());
    }
    List<SObject> histories = GCPSummaryUtil.stripReadable(
      new OpportunityFieldHistorySelector()
        .selectFieldHistoryByOpportunityIdAndFields(recordId, trackedFields)
        .setLimit(maxHistoryRows)
        .executeQuery()
    );
    for (Integer i = histories.size() - 1; i >= 0; i--) {
      OpportunityFieldHistory fh = (OpportunityFieldHistory) histories[i];
      rows.add(
        new Map<String, Object>{
          'field' => GCPSummaryUtil.readableField(
            fh,
            OpportunityFieldHistory.Field
          ),
          'oldValue' => GCPSummaryUtil.readableField(
            fh,
            OpportunityFieldHistory.OldValue
          ),
          'newValue' => GCPSummaryUtil.readableField(
            fh,
            OpportunityFieldHistory.NewValue
          ),
          'createdDate' => GCPSummaryUtil.readableField(
            fh,
            OpportunityFieldHistory.CreatedDate
          )
        }
      );
    }
    return rows;
  }

  private static CollectionData getStakeholderData(Id recordId) {
    CollectionData data = new CollectionData();
    List<SObject> roles = GCPSummaryUtil.stripReadable(
      new OpportunityContactRoleSelector()
        .selectStakeholdersForSummary(recordId, maxStakeholders + 1)
        .executeQuery()
    );
    data.isTruncated = trimOverflow(roles, maxStakeholders);
    for (SObject sobj : roles) {
      OpportunityContactRole r = (OpportunityContactRole) sobj;
      SObject stakeholderContact = readableRelated(r, RELATIONSHIP_CONTACT);
      data.rows.add(
        new Map<String, Object>{
          'role' => GCPSummaryUtil.readableField(
            r,
            OpportunityContactRole.Role
          ),
          'isPrimary' => GCPSummaryUtil.readableField(
            r,
            OpportunityContactRole.IsPrimary
          ),
          'contactId' => GCPSummaryUtil.readableField(
            r,
            OpportunityContactRole.ContactId
          ),
          'name' => GCPSummaryUtil.readableField(
            stakeholderContact,
            Contact.Name
          ),
          'title' => GCPSummaryUtil.readableField(
            stakeholderContact,
            Contact.Title
          ),
          'email' => GCPSummaryUtil.readableField(
            stakeholderContact,
            Contact.Email
          ),
          'phone' => GCPSummaryUtil.readableField(
            stakeholderContact,
            Contact.Phone
          ),
          'lastActivityDate' => GCPSummaryUtil.readableField(
            stakeholderContact,
            Contact.LastActivityDate
          )
        }
      );
    }
    data.isAccessible = OpportunityContactRole.SObjectType.getDescribe()
      .isAccessible();
    return data;
  }

  private static Map<String, Object> getCases(Id accountId) {
    if (accountId == null) {
      return new Map<String, Object>{
        'open' => new List<Map<String, Object>>(),
        'recentlyClosed' => new List<Map<String, Object>>()
      };
    }

    return new Map<String, Object>{
      'open' => mapCaseRows(buildOpenCaseQuery(accountId).executeQuery()),
      'recentlyClosed' => mapCaseRows(
        buildRecentlyClosedCaseQuery(accountId).executeQuery()
      )
    };
  }

  /* Open and closed cases are queried separately so neither bucket can crowd out the other. */
  @TestVisible
  private static QueryFactory buildOpenCaseQuery(Id accountId) {
    return new CaseSelector()
      .selectOpenCasesForOpportunitySummary(accountId, maxOpenCases);
  }

  @TestVisible
  private static QueryFactory buildRecentlyClosedCaseQuery(Id accountId) {
    return new CaseSelector()
      .selectRecentlyClosedCasesForOpportunitySummary(
        accountId,
        Date.today().addMonths(-closedCaseMonths),
        maxClosedCases
      );
  }

  private static List<Map<String, Object>> mapCaseRows(List<SObject> records) {
    List<Map<String, Object>> rows = new List<Map<String, Object>>();
    for (SObject sobj : GCPSummaryUtil.stripReadable(records)) {
      Case c = (Case) sobj;
      SObject owner = readableRelated(c, RELATIONSHIP_OWNER);
      Map<String, Object> row = new Map<String, Object>{
        'id' => GCPSummaryUtil.readableField(c, Case.Id),
        'caseNumber' => GCPSummaryUtil.readableField(c, Case.CaseNumber),
        'subject' => GCPSummaryUtil.readableField(c, Case.Subject),
        'status' => GCPSummaryUtil.readableField(c, Case.Status),
        'priority' => GCPSummaryUtil.readableField(c, Case.Priority),
        'isEscalated' => GCPSummaryUtil.readableField(c, Case.IsEscalated),
        'createdDate' => GCPSummaryUtil.readableField(c, Case.CreatedDate),
        'closedDate' => GCPSummaryUtil.readableField(c, Case.ClosedDate),
        'ownerName' => GCPSummaryUtil.readableField(owner, User.Name),
        'description' => truncateText(
          (String) GCPSummaryUtil.readableField(c, Case.Description)
        )
      };
      rows.add(row);
    }
    return rows;
  }

  private static CollectionData getLineItemData(
    Id recordId,
    Boolean enrichmentEnabled
  ) {
    CollectionData data = new CollectionData();
    List<SObject> lineItems = GCPSummaryUtil.stripReadable(
      new OpportunityLineItemSelector()
        .selectLineItemsWithProductContextForSummary(recordId, maxLineItems + 1)
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
      SObject product = readableRelated(li, RELATIONSHIP_PRODUCT);
      Map<String, Object> row = new Map<String, Object>{
        'name' => GCPSummaryUtil.readableField(li, OpportunityLineItem.Name),
        'productId' => GCPSummaryUtil.readableField(
          li,
          OpportunityLineItem.Product2Id
        ),
        'productName' => GCPSummaryUtil.readableField(product, Product2.Name),
        'quantity' => GCPSummaryUtil.readableField(
          li,
          OpportunityLineItem.Quantity
        ),
        'unitPrice' => GCPSummaryUtil.readableField(
          li,
          OpportunityLineItem.UnitPrice
        ),
        'totalPrice' => GCPSummaryUtil.readableField(
          li,
          OpportunityLineItem.TotalPrice
        ),
        'discount' => GCPSummaryUtil.readableField(
          li,
          OpportunityLineItem.Discount
        ),
        'serviceDate' => GCPSummaryUtil.readableField(
          li,
          OpportunityLineItem.ServiceDate
        ),
        'description' => truncateText(
          (String) GCPSummaryUtil.readableField(
            li,
            OpportunityLineItem.Description
          )
        )
      };
      if (enrichmentEnabled) {
        putIfPresent(
          row,
          'productFamily',
          activeProductFamily(
            GCPSummaryUtil.readableField(product, Product2.Family)
          )
        );
        putIfPresent(
          row,
          'productLine',
          normalizedText(
            GCPSummaryUtil.readableField(product, Product2.Sub_Category__c)
          )
        );
        putIfPresent(
          row,
          'productSubgroup',
          GCPSummaryUtil.readableField(product, Product2.Subgroup__c)
        );
        putIfPresent(
          row,
          'productGroup',
          GCPSummaryUtil.readableField(product, Product2.Group__c)
        );
        putIfPresent(
          row,
          'productDescription',
          truncateText(
            (String) GCPSummaryUtil.readableField(product, Product2.Description)
          )
        );
        putIfPresent(
          row,
          'productCatalogDescription',
          truncateText(
            (String) GCPSummaryUtil.readableField(
              product,
              Product2.Product_Description__c
            )
          )
        );
        putIfPresent(
          row,
          'productCategoryName',
          GCPSummaryUtil.readableField(product, Product2.CategoryName__c)
        );
        List<String> licenseGroups = splitMultiSelect(
          GCPSummaryUtil.readableField(product, Product2.LicenseGroup__c)
        );
        if (!licenseGroups.isEmpty()) {
          row.put('licenseGroups', licenseGroups);
        }
        putIfPresent(
          row,
          'serviceCategory',
          GCPSummaryUtil.readableField(product, Product2.ServiceCategory__c)
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

  @TestVisible
  private static Map<String, Object> buildDataCoverage(
    OpportunitySummaryActivityHelper.ActivityData activityData,
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

  /**
   * Serializes the payload under the service limit. Conversation evidence goes first, then
   * activity participants, then rows from the end of the longest lists; trimmed collections are
   * marked request_size_limit in their coverage entry.
   */
  public static String serializePayloadWithinLimit(
    Map<String, Object> payload
  ) {
    String serialized = JSON.serialize(payload);
    if (isWithinRequestLimit(serialized)) {
      return serialized;
    }
    Map<String, Object> coverage = mapValue(payload.get('dataCoverage'));

    List<Map<String, Object>> conversationItems = mapListValue(
      mapValue(payload.get('conversationEvidence')).get('items')
    );
    Map<String, List<Object>> conversationLists = new Map<String, List<Object>>{
      'conversations' => conversationItems
    };
    if (!trimToFit(payload, conversationLists).isEmpty()) {
      markSizeTrimmed(coverage, 'conversations', conversationItems.size());
    }
    serialized = JSON.serialize(payload);
    if (isWithinRequestLimit(serialized)) {
      return serialized;
    }

    Map<String, Object> activities = mapValue(payload.get('activities'));
    List<Map<String, Object>> taskRows = mapListValue(activities.get('tasks'));
    List<Map<String, Object>> eventRows = mapListValue(
      activities.get('events')
    );
    Map<String, List<Object>> participantLists = new Map<String, List<Object>>();
    addParticipantLists(participantLists, 'tasks', taskRows);
    addParticipantLists(participantLists, 'events', eventRows);
    if (!trimToFit(payload, participantLists).isEmpty()) {
      markSizeTrimmed(coverage, 'activities', null);
    }
    serialized = JSON.serialize(payload);
    if (isWithinRequestLimit(serialized)) {
      return serialized;
    }

    Map<String, Object> cases = mapValue(payload.get('cases'));
    List<Map<String, Object>> stakeholders = mapListValue(
      payload.get('stakeholders')
    );
    List<Map<String, Object>> lineItems = mapListValue(
      payload.get('lineItems')
    );
    Set<String> trimmedKeys = trimToFit(
      payload,
      new Map<String, List<Object>>{
        'stageHistory' => mapListValue(payload.get('stageHistory')),
        'fieldHistory' => mapListValue(payload.get('fieldHistory')),
        'tasks' => taskRows,
        'events' => eventRows,
        'stakeholders' => stakeholders,
        'openCases' => mapListValue(cases.get('open')),
        'recentlyClosedCases' => mapListValue(cases.get('recentlyClosed')),
        'lineItems' => lineItems,
        'relatedOpportunities' => mapListValue(
          payload.get('relatedOpportunities')
        )
      }
    );
    if (trimmedKeys.contains('tasks') || trimmedKeys.contains('events')) {
      markSizeTrimmed(
        coverage,
        'activities',
        taskRows.size() + eventRows.size()
      );
    }
    if (trimmedKeys.contains('stakeholders')) {
      markSizeTrimmed(coverage, 'stakeholders', stakeholders.size());
    }
    if (trimmedKeys.contains('lineItems')) {
      markSizeTrimmed(coverage, 'lineItems', lineItems.size());
    }
    serialized = JSON.serialize(payload);
    if (isWithinRequestLimit(serialized)) {
      return serialized;
    }

    throw new OpportunitySummaryPayloadException(
      'Opportunity Summary core request exceeds the service size limit.'
    );
  }

  private static Boolean isWithinRequestLimit(String serialized) {
    return Blob.valueOf(serialized).size() < requestSizeLimitBytes;
  }

  private static Set<String> trimToFit(
    Map<String, Object> payload,
    Map<String, List<Object>> keyToRows
  ) {
    return GCPSummaryUtil.trimListsToFit(
      payload,
      keyToRows,
      requestSizeLimitBytes - COVERAGE_HEADROOM_BYTES
    );
  }

  private static void addParticipantLists(
    Map<String, List<Object>> participantLists,
    String listKey,
    List<Map<String, Object>> activityRows
  ) {
    for (Integer index = 0; index < activityRows.size(); index++) {
      Object participants = activityRows[index].get('participants');
      if (participants != null) {
        participantLists.put(listKey + index, (List<Object>) participants);
      }
    }
  }

  private static void markSizeTrimmed(
    Map<String, Object> coverage,
    String coverageKey,
    Integer returnedCount
  ) {
    if (!coverage.containsKey(coverageKey)) {
      return;
    }
    Map<String, Object> entry = mapValue(coverage.get(coverageKey));
    if (returnedCount != null) {
      entry.put('returnedCount', returnedCount);
    }
    entry.put('isTruncated', true);
    entry.put('reasonCode', REASON_REQUEST_SIZE_LIMIT);
  }

  public static Boolean trimOverflow(
    List<SObject> records,
    Integer maximumSize
  ) {
    Boolean isTruncated = records.size() > maximumSize;
    while (records.size() > maximumSize) {
      records.remove(records.size() - 1);
    }
    return isTruncated;
  }

  public static void putIfPresent(
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

  public static Map<String, Object> mapValue(Object value) {
    return value instanceof Map<String, Object>
      ? (Map<String, Object>) value
      : new Map<String, Object>();
  }

  public static List<Map<String, Object>> mapListValue(Object value) {
    return value == null
      ? new List<Map<String, Object>>()
      : (List<Map<String, Object>>) value;
  }

  public class CollectionData {
    public List<Map<String, Object>> rows = new List<Map<String, Object>>();
    public Boolean isTruncated = false;
    public Boolean isAccessible = true;
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
    List<SObject> related = GCPSummaryUtil.stripReadable(
      buildRelatedOpportunitiesQuery(accountId, currentOppId).executeQuery()
    );
    for (SObject sobj : related) {
      Opportunity opp = (Opportunity) sobj;
      rows.add(
        new Map<String, Object>{
          'id' => GCPSummaryUtil.readableField(opp, Opportunity.Id),
          'name' => GCPSummaryUtil.readableField(opp, Opportunity.Name),
          'amount' => GCPSummaryUtil.readableField(opp, Opportunity.Amount),
          'currencyIsoCode' => GCPSummaryUtil.readableField(
            opp,
            Opportunity.CurrencyIsoCode
          ),
          'type' => GCPSummaryUtil.readableField(opp, Opportunity.Type),
          'stageName' => GCPSummaryUtil.readableField(
            opp,
            Opportunity.StageName
          ),
          'forecastCategory' => GCPSummaryUtil.readableField(
            opp,
            Opportunity.ForecastCategory
          ),
          'probability' => GCPSummaryUtil.readableField(
            opp,
            Opportunity.Probability
          ),
          'isWon' => GCPSummaryUtil.readableField(opp, Opportunity.IsWon),
          'isClosed' => GCPSummaryUtil.readableField(opp, Opportunity.IsClosed),
          'closeDate' => GCPSummaryUtil.readableField(
            opp,
            Opportunity.CloseDate
          ),
          'createdDate' => GCPSummaryUtil.readableField(
            opp,
            Opportunity.CreatedDate
          )
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
      .selectRelatedOpportunitiesForSummary(
        accountId,
        currentOppId,
        maxRelatedOpps
      );
  }

  // QueryFactory / selectors run in system mode; `with sharing` only enforces row-level
  // sharing. Strip fields the running user cannot read before they reach the GCP payload.
  // enforceRootObjectCRUD=false so missing object access on related types (Case, Task, …)
  // yields empty field sets instead of NoAccessException aborting the whole summary.
  // stripInaccessible REMOVES an inaccessible field from the record — it does NOT null it
  // out. A direct getter on a removed field throws System.SObjectException. Reading via
  // getPopulatedFieldsAsMap() returns null instead, so the payload still builds from what
  // the user CAN read.
  public static SObject readableRelated(
    SObject record,
    String relationshipName
  ) {
    Object related = GCPSummaryUtil.readableField(record, relationshipName);
    return related instanceof SObject ? (SObject) related : null;
  }

  public static String truncateText(String value) {
    if (String.isBlank(value) || value.length() <= MAX_DESCRIPTION_LENGTH) {
      return value;
    }
    return value.left(MAX_DESCRIPTION_LENGTH) + '…';
  }

  // ---------------- Response handling ----------------
}
