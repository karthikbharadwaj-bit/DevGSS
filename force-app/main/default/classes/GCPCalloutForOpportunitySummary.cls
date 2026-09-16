public with sharing class GCPCalloutForOpportunitySummary {

    // Cases closed within this window are sent to the model for trend context.
    private static final Integer RECENTLY_CLOSED_MONTHS = 6;

    // Caps keep heap and callout body size in check on busy accounts.
    private static final Integer ACTIVITY_LOOKBACK_DAYS = 180;
    private static final Integer MAX_ACTIVITIES = 50;
    private static final Integer MAX_HISTORY_ROWS = 50;
    private static final Integer MAX_OPEN_CASES = 50;
    private static final Integer MAX_CLOSED_CASES = 50;
    private static final Integer MAX_RELATED_OPPS = 25;
    private static final Integer MAX_LINE_ITEMS = 50;
    private static final Integer MAX_STAKEHOLDERS = 25;
    private static final Integer MAX_DESCRIPTION_LENGTH = 1000;

    // Technical failures (callout, config, query, parsing) are logged for support and
    // reported to the user with this message only — endpoints, status codes and stack
    // details must never reach the UI.
    private static final String USER_FACING_ERROR =
        'We\'re experiencing a temporary issue with summary generation. Please contact your administrator if this continues.';

    @AuraEnabled(cacheable=false)
    public static String makeGCPCallout(String userId, String recordId) {
        try {
            if (String.isBlank(recordId)) {
                System.debug(LoggingLevel.ERROR, 'Opportunity Summary called without a record Id.');
                return errorJson(USER_FACING_ERROR);
            }

            String username = getUsername(userId);

            GCPAuthUtil.GCPConfig config = GCPAuthUtil.loadConfig(GCPAuthUtil.OPPORTUNITY_SUMMARY);
            String jwt = GCPAuthUtil.createSignedJWT(config);
            String idToken = GCPAuthUtil.exchangeJWTForIdentityToken(jwt, config.identityTokenUrl);

            return callCloudRun(username, (Id) recordId, idToken, config.cloudRunEndpoint);

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

    private static String callCloudRun(String username, Id recordId, String idToken, String endpoint) {
        Map<String, Object> payload = buildPayload(username, recordId);
        System.debug('Heap after payload built (queries):: ' + Limits.getHeapSize() + ' / ' + Limits.getLimitHeapSize());

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + idToken);
        req.setBody(JSON.serialize(payload));
        req.setTimeout(120000);

        System.debug('Opportunity Summary payload::' + JSON.serialize(payload));
        System.debug('Heap after payload serialized:: ' + Limits.getHeapSize() + ' / ' + Limits.getLimitHeapSize());

        Http h = new Http();
        HttpResponse res = h.send(req);
        System.debug('Opportunity Summary response::' + res);
        System.debug('Opportunity Summary response body::' + res.getBody());

        if (res.getStatusCode() != 200) {
            throw new CalloutException('Cloud Run call failed. Status: ' + res.getStatusCode() + ' - ' + res.getBody());
        }

        String responseBody = res.getBody();
        if (String.isBlank(responseBody)) {
            return errorJson(USER_FACING_ERROR);
        }

        String result = buildResult(JSON.deserializeUntyped(responseBody));
        System.debug('Heap after summary generated:: ' + Limits.getHeapSize() + ' / ' + Limits.getLimitHeapSize());
        return result;
    }

    // ---------------- Payload assembly ----------------

    private static Map<String, Object> buildPayload(String username, Id recordId) {
        Opportunity opp = getOpportunity(recordId);
        // AccountId may have been stripped for FLS; fall back to null (no related account context).
        Id accountId = (Id) readableField(opp, 'AccountId');

        Map<String, Object> caseBuckets = getCases(accountId);

        return new Map<String, Object>{
            'username'       => username,
            'recordId'       => recordId,
            'redactRequired' => String.valueOf(GCPAuthUtil.getRedactionFlag()),
            'opportunity'    => buildOpportunityMap(opp),
            'stageHistory'   => getStageHistory(recordId),
            'fieldHistory'   => getFieldHistory(recordId),
            'activities'     => new Map<String, Object>{
                'tasks'  => getTasks(recordId),
                'events' => getEvents(recordId)
            },
            'stakeholders'   => getStakeholders(recordId),
            'cases'          => caseBuckets,
            'lineItems'      => getLineItems(recordId),
            'relatedOpportunities' => getRelatedOpportunities(accountId, recordId)
        };
    }

    private static Opportunity getOpportunity(Id recordId) {
        List<Opportunity> opps = (List<Opportunity>) new OpportunitySelector()
            .selectOpportunities()
            .withoutSelectorFieldsIncluded()
            .selectFields(new List<String>{
                'Id', 'Name', 'Amount', 'CurrencyIsoCode', 'Type', 'LeadSource', 'StageName', 'Probability', 'ForecastCategory',
                'CloseDate', 'CreatedDate', 'LastModifiedDate', 'NextStep', 'Description',
                'OwnerId', 'Owner.Name', 'AccountId', 'Account.Name', 'Account.Industry',
                'Account.BillingCity', 'Account.BillingCountry'
            })
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

    private static Map<String, Object> buildOpportunityMap(Opportunity opp) {
        SObject owner = readableRelated(opp, 'Owner');
        SObject account = readableRelated(opp, 'Account');
        return new Map<String, Object>{
            'id'               => readableField(opp, 'Id'),
            'name'             => readableField(opp, 'Name'),
            'amount'           => readableField(opp, 'Amount'),
            'currencyIsoCode'  => readableField(opp, 'CurrencyIsoCode'),
            'type'             => readableField(opp, 'Type'),
            'leadSource'       => readableField(opp, 'LeadSource'),
            'stageName'        => readableField(opp, 'StageName'),
            'probability'      => readableField(opp, 'Probability'),
            'forecastCategory' => readableField(opp, 'ForecastCategory'),
            'closeDate'        => readableField(opp, 'CloseDate'),
            'createdDate'      => readableField(opp, 'CreatedDate'),
            'lastModifiedDate' => readableField(opp, 'LastModifiedDate'),
            'nextStep'         => readableField(opp, 'NextStep'),
            'description'      => truncateText((String) readableField(opp, 'Description')),
            'ownerId'          => readableField(opp, 'OwnerId'),
            'ownerName'        => readableField(owner, 'Name'),
            'accountId'        => readableField(opp, 'AccountId'),
            'accountName'      => readableField(account, 'Name'),
            'accountIndustry'  => readableField(account, 'Industry'),
            'accountCity'      => readableField(account, 'BillingCity'),
            'accountCountry'   => readableField(account, 'BillingCountry')
        };
    }

    private static List<Map<String, Object>> getStageHistory(Id recordId) {
        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        // Selector returns newest first; reverse so the payload stays chronological.
        List<SObject> histories = stripReadable(
            new OpportunityHistorySelector()
                .selectStageHistoryByOpportunityId(recordId)
                .setLimit(MAX_HISTORY_ROWS)
                .executeQuery()
        );
        for (Integer i = histories.size() - 1; i >= 0; i--) {
            OpportunityHistory h = (OpportunityHistory) histories[i];
            rows.add(new Map<String, Object>{
                'stageName'        => readableField(h, 'StageName'),
                'amount'           => readableField(h, 'Amount'),
                'probability'      => readableField(h, 'Probability'),
                'closeDate'        => readableField(h, 'CloseDate'),
                'forecastCategory' => readableField(h, 'ForecastCategory'),
                'createdDate'      => readableField(h, 'CreatedDate')
            });
        }
        return rows;
    }

    private static List<Map<String, Object>> getFieldHistory(Id recordId) {
        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        Set<String> trackedFields = new Set<String>{ 'CloseDate', 'Amount', 'Probability' };
        List<SObject> histories = stripReadable(
            new OpportunityFieldHistorySelector()
                .selectFieldHistoryByOpportunityIdAndFields(recordId, trackedFields)
                .setLimit(MAX_HISTORY_ROWS)
                .executeQuery()
        );
        for (Integer i = histories.size() - 1; i >= 0; i--) {
            OpportunityFieldHistory fh = (OpportunityFieldHistory) histories[i];
            rows.add(new Map<String, Object>{
                'field'       => readableField(fh, 'Field'),
                'oldValue'    => readableField(fh, 'OldValue'),
                'newValue'    => readableField(fh, 'NewValue'),
                'createdDate' => readableField(fh, 'CreatedDate')
            });
        }
        return rows;
    }

    private static List<Map<String, Object>> getTasks(Id recordId) {
        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        Datetime activitySince = Datetime.now().addDays(-ACTIVITY_LOOKBACK_DAYS);
        List<SObject> tasks = stripReadable(
            new TaskSelector()
                .selectTasksByWhatIdForOpportunitySummary(recordId)
                .setCondition('WhatId = :bind0 AND CreatedDate >= :bind1')
                .setQueryBindings(new List<Object>{ recordId, activitySince })
                .setLimit(MAX_ACTIVITIES)
                .executeQuery()
        );
        for (SObject sobj : tasks) {
            Task t = (Task) sobj;
            SObject owner = readableRelated(t, 'Owner');
            rows.add(new Map<String, Object>{
                'subject'      => readableField(t, 'Subject'),
                'status'       => readableField(t, 'Status'),
                'type'         => readableField(t, 'Type'),
                'activityDate' => readableField(t, 'ActivityDate'),
                'createdDate'  => readableField(t, 'CreatedDate'),
                'ownerName'    => readableField(owner, 'Name'),
                'description'  => truncateText((String) readableField(t, 'Description'))
            });
        }
        return rows;
    }

    private static List<Map<String, Object>> getEvents(Id recordId) {
        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        // QueryFactory cannot validate Owner.Name on Event — Owner is polymorphic
        // (User | Calendar) and Calendar has no Name field. Resolve User names separately.
        Datetime activitySince = Datetime.now().addDays(-ACTIVITY_LOOKBACK_DAYS);
        List<SObject> events = stripReadable(
            new EventSelector()
                .selectEventsByWhatIds(new Set<Id>{ recordId })
                .selectFields(new List<String>{
                    'Subject', 'StartDateTime', 'EndDateTime', 'CreatedDate', 'OwnerId', 'Description'
                })
                .withoutSelectorOrderByIncluded()
                .setCondition('WhatId IN :bind0 AND StartDateTime >= :bind1')
                .setQueryBindings(new List<Object>{ new Set<Id>{ recordId }, activitySince })
                .addOrdering(Event.StartDateTime, QueryFactory.SortOrder.DESCENDING)
                .setLimit(MAX_ACTIVITIES)
                .executeQuery()
        );

        Set<Id> ownerIds = new Set<Id>();
        for (SObject sobj : events) {
            Id ownerId = (Id) readableField(sobj, 'OwnerId');
            if (ownerId != null && String.valueOf(ownerId).startsWith('005')) {
                ownerIds.add(ownerId);
            }
        }

        Map<Id, String> ownerNamesById = new Map<Id, String>();
        if (!ownerIds.isEmpty()) {
            for (SObject sobj : stripReadable(
                new UserSelector()
                    .selectUsersByIds(ownerIds)
                    .executeQuery()
            )) {
                Id userId = (Id) readableField(sobj, 'Id');
                String userName = (String) readableField(sobj, 'Name');
                if (userId != null) {
                    ownerNamesById.put(userId, userName);
                }
            }
        }

        for (SObject sobj : events) {
            Event e = (Event) sobj;
            Id ownerId = (Id) readableField(e, 'OwnerId');
            rows.add(new Map<String, Object>{
                'subject'       => readableField(e, 'Subject'),
                'startDateTime' => readableField(e, 'StartDateTime'),
                'endDateTime'   => readableField(e, 'EndDateTime'),
                'createdDate'   => readableField(e, 'CreatedDate'),
                'ownerName'     => ownerNamesById.get(ownerId),
                'description'   => truncateText((String) readableField(e, 'Description'))
            });
        }
        return rows;
    }

    private static List<Map<String, Object>> getStakeholders(Id recordId) {
        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        List<SObject> roles = stripReadable(
            new OpportunityContactRoleSelector()
                .selectOpportunityContactRolesByOppId(new List<Object>{ recordId })
                .selectFields(new List<String>{
                    'Contact.Name', 'Contact.Title', 'Contact.Email', 'Contact.Phone', 'Contact.LastActivityDate'
                })
                .addOrdering(OpportunityContactRole.IsPrimary, QueryFactory.SortOrder.DESCENDING)
                .setLimit(MAX_STAKEHOLDERS)
                .executeQuery()
        );
        for (SObject sobj : roles) {
            OpportunityContactRole r = (OpportunityContactRole) sobj;
            SObject contact = readableRelated(r, 'Contact');
            rows.add(new Map<String, Object>{
                'role'             => readableField(r, 'Role'),
                'isPrimary'        => readableField(r, 'IsPrimary'),
                'contactId'        => readableField(r, 'ContactId'),
                'name'             => readableField(contact, 'Name'),
                'title'            => readableField(contact, 'Title'),
                'email'            => readableField(contact, 'Email'),
                'phone'            => readableField(contact, 'Phone'),
                'lastActivityDate' => readableField(contact, 'LastActivityDate')
            });
        }
        return rows;
    }

    private static Map<String, Object> getCases(Id accountId) {
        List<Map<String, Object>> openCases = new List<Map<String, Object>>();
        List<Map<String, Object>> recentlyClosed = new List<Map<String, Object>>();

        if (accountId == null) {
            return new Map<String, Object>{ 'open' => openCases, 'recentlyClosed' => recentlyClosed };
        }

        Date closedSince = Date.today().addMonths(-RECENTLY_CLOSED_MONTHS);
        List<SObject> cases = stripReadable(
            new CaseSelector()
                .selectCases()
                .selectFields(new List<String>{
                    'Id', 'CaseNumber', 'Subject', 'Status', 'Priority', 'IsClosed', 'IsEscalated',
                    'CreatedDate', 'ClosedDate', 'Owner.Name', 'Description'
                })
                .setCondition('AccountId = :bind0 AND (IsClosed = false OR ClosedDate >= :bind1)')
                .addOrdering(Case.CreatedDate, QueryFactory.SortOrder.DESCENDING)
                .setQueryBindings(new List<Object>{ accountId, closedSince })
                .setLimit(MAX_OPEN_CASES + MAX_CLOSED_CASES)
                .executeQuery()
        );

        for (SObject sobj : cases) {
            Case c = (Case) sobj;
            SObject owner = readableRelated(c, 'Owner');
            Map<String, Object> row = new Map<String, Object>{
                'caseNumber'  => readableField(c, 'CaseNumber'),
                'subject'     => readableField(c, 'Subject'),
                'status'      => readableField(c, 'Status'),
                'priority'    => readableField(c, 'Priority'),
                'isEscalated' => readableField(c, 'IsEscalated'),
                'createdDate' => readableField(c, 'CreatedDate'),
                'closedDate'  => readableField(c, 'ClosedDate'),
                'ownerName'   => readableField(owner, 'Name'),
                'description' => truncateText((String) readableField(c, 'Description'))
            };
            // IsClosed may be stripped; treat missing as open so we do not drop the row.
            Boolean isClosed = (Boolean) readableField(c, 'IsClosed');
            if (isClosed == true) {
                if (recentlyClosed.size() < MAX_CLOSED_CASES) {
                    recentlyClosed.add(row);
                }
            } else if (openCases.size() < MAX_OPEN_CASES) {
                openCases.add(row);
            }
        }

        return new Map<String, Object>{ 'open' => openCases, 'recentlyClosed' => recentlyClosed };
    }

    private static List<Map<String, Object>> getLineItems(Id recordId) {
        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        List<SObject> lineItems = stripReadable(
            new OpportunityLineItemSelector()
                .selectLineItemsByOpportunityIdForSummary(recordId)
                .setLimit(MAX_LINE_ITEMS)
                .executeQuery()
        );
        for (SObject sobj : lineItems) {
            OpportunityLineItem li = (OpportunityLineItem) sobj;
            SObject product = readableRelated(li, 'Product2');
            rows.add(new Map<String, Object>{
                'name'        => readableField(li, 'Name'),
                'productId'   => readableField(li, 'Product2Id'),
                'productName' => readableField(product, 'Name'),
                'quantity'    => readableField(li, 'Quantity'),
                'unitPrice'   => readableField(li, 'UnitPrice'),
                'totalPrice'  => readableField(li, 'TotalPrice'),
                'discount'    => readableField(li, 'Discount'),
                'serviceDate' => readableField(li, 'ServiceDate'),
                'description' => truncateText((String) readableField(li, 'Description'))
            });
        }
        return rows;
    }

    // Sibling opportunities on the same account (excluding the current one) give the model
    // the account's win/downgrade/expansion history, which powers the "account pattern" and
    // stage-journey narrative in the summary.
    private static List<Map<String, Object>> getRelatedOpportunities(Id accountId, Id currentOppId) {
        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        if (accountId == null) {
            return rows;
        }
        List<SObject> related = stripReadable(
            new OpportunitySelector()
                .selectOpportunities()
                .withoutSelectorFieldsIncluded()
                .selectFields(new List<String>{
                    'Id', 'Name', 'Amount', 'CurrencyIsoCode', 'Type', 'StageName', 'ForecastCategory',
                    'Probability', 'IsWon', 'IsClosed', 'CloseDate', 'CreatedDate'
                })
                .setCondition('AccountId = :bind0 AND Id != :bind1')
                .addOrdering(Opportunity.CloseDate, QueryFactory.SortOrder.DESCENDING)
                .setQueryBindings(new List<Object>{ accountId, currentOppId })
                .setLimit(MAX_RELATED_OPPS)
                .executeQuery()
        );
        for (SObject sobj : related) {
            Opportunity opp = (Opportunity) sobj;
            rows.add(new Map<String, Object>{
                'id'               => readableField(opp, 'Id'),
                'name'             => readableField(opp, 'Name'),
                'amount'           => readableField(opp, 'Amount'),
                'currencyIsoCode'  => readableField(opp, 'CurrencyIsoCode'),
                'type'             => readableField(opp, 'Type'),
                'stageName'        => readableField(opp, 'StageName'),
                'forecastCategory' => readableField(opp, 'ForecastCategory'),
                'probability'      => readableField(opp, 'Probability'),
                'isWon'            => readableField(opp, 'IsWon'),
                'isClosed'         => readableField(opp, 'IsClosed'),
                'closeDate'        => readableField(opp, 'CloseDate'),
                'createdDate'      => readableField(opp, 'CreatedDate')
            });
        }
        return rows;
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
        ).getRecords();
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

    private static SObject readableRelated(SObject record, String relationshipName) {
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
    private static String buildResult(Object raw) {
        List<Object> cards = extractCards(raw);
        if (cards != null) {
            return JSON.serializePretty(new Map<String, Object>{ 'success' => true, 'cards' => cards });
        }

        Object body = getBody(raw);
        if (body instanceof String) {
            System.debug(LoggingLevel.ERROR, 'Opportunity Summary service message: ' + (String) body);
        } else {
            System.debug(LoggingLevel.ERROR, 'Opportunity Summary unexpected response format: ' + JSON.serialize(raw));
        }

        return errorJson(USER_FACING_ERROR);
    }

    private static List<Object> extractCards(Object raw) {
        Object body = getBody(raw);

        if (body instanceof List<Object>) {
            return (List<Object>) body;
        }

        if (body instanceof Map<String, Object>) {
            Map<String, Object> bodyMap = (Map<String, Object>) body;
            for (String key : new List<String>{ 'opportunity_summary', 'sections', 'cards' }) {
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
        'risk flags'         => 'risk',
        'win factors'        => 'success',
        'next best actions'  => 'info',
        'overall deal score' => 'success'
    };

    private static List<Object> cardsFromSummaryMap(Map<String, Object> summaryMap) {
        List<Object> cards = new List<Object>();
        Set<String> used = new Set<String>();

        for (String preferred : SECTION_ORDER) {
            for (String key : summaryMap.keySet()) {
                if (!used.contains(key) && key != null && key.equalsIgnoreCase(preferred)) {
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
        return JSON.serializePretty(new Map<String, Object>{ 'success' => false, 'message' => message });
    }

    private static String logAndFail(String context, Exception e) {
        System.debug(
            LoggingLevel.ERROR,
            'Opportunity Summary ' + context + ': ' + e.getMessage() + '\n' + e.getStackTraceString()
        );
        return errorJson(USER_FACING_ERROR);
    }

    // ---------------- Feature toggle & telemetry ----------------

    @AuraEnabled(cacheable=true)
    public static Boolean isOpportunitySummaryEnabled() {
        GCP_Feature_Toggle__c setting = GCP_Feature_Toggle__c.getInstance();
        return (setting != null && setting.Enable_Opportunity_Summary__c == true);
    }

    @AuraEnabled(cacheable=false)
    public static void logAIHEvent(String eventType, String subfeature, String feedback) {
        Set<String> allowed = new Set<String>{ 'aih_view', 'aih_like', 'aih_dislike', 'aih_feedback' };
        if (String.isBlank(eventType) || !allowed.contains(eventType)) {
            return;
        }

        String safeSubfeature = String.isBlank(subfeature) ? 'Unknown' : subfeature.left(80);
        String safeFeedback   = String.isBlank(feedback) ? null : feedback.left(1000);

        Map<String, Object> payload = new Map<String, Object>{ 'subfeature' => safeSubfeature };
        if (safeFeedback != null) {
            payload.put('feedback', safeFeedback);
        }

        System.enqueueJob(new AIUsageLogQueueable(new List<String>{ eventType }, JSON.serialize(payload)));
    }
}