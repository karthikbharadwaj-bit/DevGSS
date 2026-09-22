# GCP INTEGRATION HANDOFF

## 1. Implementation status

Implemented in the existing Salesforce Opportunity Summary request flow:

- Preserved the authenticated `POST /api/v1/opportunity_summary` flow, existing envelope, existing request fields, UI, and response handling.
- Added optional Account website/state and Product family mappings.
- Added customer participants to existing Task/Event rows using activity relationships, without treating the activity owner as a participant.
- Added bounded `conversationEvidence.items` from completed Task/Event descriptions, classified strictly as `notes`.
- Added `dataCoverage` for stakeholders, activities, conversations, and line items.
- Added a hierarchy-custom-setting switch that is disabled by default and a configurable recent-evidence window that defaults to 90 days.
- Added the resolved switch value to every GCP request as the top-level Boolean `enableOpportunitySummaryEnrichment`, allowing GCP to skip or activate public intelligence using the same Salesforce control.
- Added request-size enforcement. Optional conversation items are removed first, then optional activity participants; coverage is updated. Core fields are never silently removed.
- Removed raw request/response/exception logging from this Opportunity Summary callout path.
- Extended the existing response adapter to pass optional `body.opportunity_enrichment` through as `opportunity_enrichment` alongside the established `success` and `cards` fields.
- Integrated evidence references and a collapsible Public Research Used region into the existing `opportunitySummary` LWC. No standalone Company Intelligence request or second GCP call is used.
- Added isolated Apex tests for mapping, participation semantics, provenance, deduplication, limits, source failures, size handling, and feature-disabled behavior.

Unavailable or intentionally not implemented:

- `productCapabilities` is not emitted because no approved maintained capability catalog/mapping was found in the repository. Product names and standard `Product2.Family` are sent.
- No Opportunity-linked call/meeting transcript, voice/conversation record, or maintained existing-summary source was found in tracked source. The existing `LiveChatTranscript` code is Lead/Case-oriented and has no proven Opportunity activity relationship, so it is not reused.
- Generic linked files exist elsewhere in the repository, but there is no reliable metadata that identifies a file as a transcript or prevents duplicate conversation representations. Files are not read.
- Dedicated transcript excerpts and existing conversation summaries remain a backend/Salesforce follow-up.
- Google `search_entry_point.rendered_content` is not injected into the Lightning DOM. Lightning Web Security sanitizes HTML and SVG strings assigned through APIs such as `innerHTML`, so Salesforce cannot guarantee that the provider markup remains unchanged. The UI reports this exact limitation and does not substitute custom suggestion links or chips.
- Check-only DevGss validations compiled the changed Apex, custom fields, and LWC. The latest validation, after the Task compatibility, Boolean GCP control, and rich-text fixes, compiled both Apex classes and the LWC and passed all 18 current Apex test methods. It did not pass the deployment gate only because selected-class coverage was 51.249%, below Salesforce's 75% requirement.

Nothing was deployed, committed, pushed, or changed in GCP.

## 2. Files changed

- `force-app/main/default/classes/GCPCalloutForOpportunitySummary.cls` — extends the existing payload, participant/conversation collection, coverage, security-safe logging, endpoint normalization, and size enforcement.
- `force-app/main/default/classes/GCPCalloutForOpportunitySummaryTest.cls` — isolated Apex tests for the enhanced mappings and failure/limit behavior.
- `force-app/main/default/classes/GCPCalloutForOpportunitySummaryTest.cls-meta.xml` — test-class metadata.
- `force-app/main/default/lwc/opportunitySummary/opportunitySummary.js` — optional enrichment validation, inline evidence parsing, source-index resolution, research grouping, safe links, record-scoped state, and evidence focus behavior.
- `force-app/main/default/lwc/opportunitySummary/opportunitySummary.html` — inline evidence badges and the collapsible Public Research Used region within the existing modal.
- `force-app/main/default/lwc/opportunitySummary/opportunitySummary.css` — evidence badge, finding-card, disclosure, focus, and highlight styling.
- `force-app/main/default/lwc/opportunitySummary/__tests__/opportunitySummary.test.js` — helper and component coverage for legacy and enriched response paths.
- `force-app/main/default/objects/GCP_Feature_Toggle__c/fields/Enable_Opportunity_Summary_Enrichment__c.field-meta.xml` — disabled-by-default hierarchy custom-setting switch.
- `force-app/main/default/objects/GCP_Feature_Toggle__c/fields/Opportunity_Summary_Recent_Days__c.field-meta.xml` — configurable recent conversation-evidence window, default 90 days.
- `docs/opportunity-summary-enrichment-gcp-handoff.md` — this integration handoff.

## 3. Exact final JSON contract

The existing top-level contract is preserved:

```text
username: string | null                         (existing)
recordId: Salesforce ID                         (existing)
redactRequired: "true" | "false"               (existing string representation)
enableOpportunitySummaryEnrichment: boolean     (new; always present)
opportunity: object                             (existing, extended when enabled)
stageHistory: array                             (existing)
fieldHistory: array                             (existing)
activities.tasks: array                         (existing, extended when enabled)
activities.events: array                        (existing, extended when enabled)
stakeholders: array                             (existing)
cases.open: array                               (existing)
cases.recentlyClosed: array                     (existing)
lineItems: array                                (existing, extended when enabled)
relatedOpportunities: array                     (existing)
conversationEvidence: object                    (new; omitted when disabled)
dataCoverage: object                            (new; omitted when disabled)
```

`enableOpportunitySummaryEnrichment` is the resolved hierarchy value of `GCP_Feature_Toggle__c.Enable_Opportunity_Summary_Enrichment__c`. It is always a JSON Boolean (`true` or `false`), never null or a string. GCP should use this field to activate or skip public-intelligence processing.

Added paths when `Enable_Opportunity_Summary_Enrichment__c = true`:

| Path                                                                    | Type and behavior                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| ----------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `opportunity.accountWebsite`                                            | String from `Account.Website`; omitted when blank, stripped, or unavailable.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| `opportunity.accountState`                                              | String from `Account.BillingState`; omitted when blank, stripped, or unavailable.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| `lineItems[].productFamily`                                             | String from `Product2.Family`; omitted when blank, stripped, or unavailable.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| `lineItems[].productCapabilities`                                       | Not emitted. No approved source exists.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| `activities.tasks[].sourceRecordId`                                     | Task Salesforce ID. Present on enhanced Task rows.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| `activities.tasks[].participants`                                       | Array; present when enabled and possibly empty.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| `activities.events[].sourceRecordId`                                    | Event Salesforce ID. Present on enhanced Event rows.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| `activities.events[].participants`                                      | Array; present when enabled and possibly empty.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| `participants[].contactId`                                              | Accessible Contact Salesforce ID. Participants whose Contact record is not visible are omitted.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| `participants[].name`                                                   | Contact name; omitted when inaccessible/blank.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| `participants[].title`                                                  | Contact title; omitted when inaccessible/blank.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| `participants[].participationStatus`                                    | Enum `attended                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       | invited                                   | unknown`. Current Salesforce sources emit only `invited`or`unknown`; no source proves `attended`. |
| `participants[].evidenceSource`                                         | One of `Task.WhoId contact link`, `TaskRelation.RelationId contact link`, `Event.WhoId contact link`, `EventRelation invitee record`, or `EventRelation.RelationId contact link`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| `conversationEvidence.items`                                            | Array; always present when enabled, possibly empty. Maximum 10 items after deduplication, newest first.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| `conversationEvidence.items[].sourceRecordId`                           | Originating Task/Event Salesforce ID.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| `conversationEvidence.items[].relatedActivityId`                        | Same Task/Event Salesforce ID.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| `conversationEvidence.items[].occurredAt`                               | ISO-8601 timestamp serialized from `Task.CompletedDateTime` or `Event.StartDateTime`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| `conversationEvidence.items[].sourceType`                               | `Task                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                | Event`. This is the actual source object. |
| `conversationEvidence.items[].contentType`                              | `notes` only. `transcript_excerpt` and `existing_summary` are not emitted by this implementation.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| `conversationEvidence.items[].text`                                     | Full available description prefix, maximum 4,000 characters. It is not filtered for AI-related terms.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| `conversationEvidence.items[].participants`                             | Same participant structure as activity rows; at least one accessible linked customer participant is required for an item to be included.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| `conversationEvidence.items[].isTruncated`                              | Boolean; true when that item's description exceeded 4,000 characters.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| `dataCoverage.{stakeholders,activities,conversations,lineItems}.status` | Enum `available                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      | not_found                                 | not_accessible                                                                                    | not_supported | error`. Current collection paths emit `available`, `not_found`, `not_accessible`, or `error`; transcript non-support is conveyed by conversation `reasonCode` because activity notes remain a supported conversation source. |
| `dataCoverage.*.returnedCount`                                          | Integer count actually remaining in the corresponding request collection.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| `dataCoverage.*.isTruncated`                                            | Boolean; true for record/text/relation/request-size limits affecting that collection. False means Salesforce did not hit an implemented cap, not that all real-world evidence exists.                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| `dataCoverage.activities.windowStart/windowEnd`                         | ISO-8601 timestamps for the existing 180-day activity retrieval window. Tasks are filtered by `CreatedDate`; Events by `StartDateTime`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| `dataCoverage.conversations.windowStart/windowEnd`                      | ISO-8601 timestamps for the configured recent-evidence window; default 90 days.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| `dataCoverage.*.reasonCode`                                             | Optional safe code: `record_limit`, `activity_limit`, `no_visible_records`, `no_visible_records_in_window`, `object_not_accessible`, `activity_notes_only`, `transcripts_not_supported_no_recent_notes`, `text_limit`, `item_limit`, `item_and_text_limits`, `participant_relation_limit`, `participant_retrieval_error`, `contact_retrieval_error`, `contacts_not_accessible`, `task_relations_error`, `event_relations_error`, `task_relations_not_accessible`, `event_relations_not_accessible`, `task_relations_limit`, `event_relations_limit`, `participant_sources_partial`, `task_completion_time_retrieval_error`, or `request_size_limit`. |

Limits:

- Existing activities: at most 50 Tasks and 50 Events, preserving the existing 180-day behavior.
- Participant relations: at most 250 TaskRelation rows and 250 EventRelation rows.
- Stakeholders: at most 25.
- Line items: at most 50.
- Conversation items: at most 10, deduplicated by source activity ID.
- Conversation text: at most 4,000 characters per item.
- Complete UTF-8 JSON body: strictly less than 2 MiB.

Null/omission behavior:

- Existing fields retain their existing serialization behavior, including null values.
- New scalar optional fields are omitted when unavailable.
- New `participants` and `conversationEvidence.items` arrays are present but empty when enabled and no accessible qualifying records exist.
- All enrichment fields and `dataCoverage` are omitted when the enrichment switch is disabled. The top-level `enableOpportunitySummaryEnrichment: false` control remains present so GCP can explicitly skip intelligence processing.

## 4. Salesforce source mapping

| JSON path                            | Salesforce source                                                                                                                                                                                                                          |
| ------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `enableOpportunitySummaryEnrichment` | Resolved hierarchy value of `GCP_Feature_Toggle__c.Enable_Opportunity_Summary_Enrichment__c`; always sent as a Boolean.                                                                                                                    |
| `opportunity.accountName`            | `Opportunity.Account.Name` (existing)                                                                                                                                                                                                      |
| `opportunity.accountWebsite`         | `Opportunity.Account.Website`                                                                                                                                                                                                              |
| `opportunity.accountIndustry`        | `Opportunity.Account.Industry` (existing)                                                                                                                                                                                                  |
| `opportunity.accountCity`            | `Opportunity.Account.BillingCity` (existing)                                                                                                                                                                                               |
| `opportunity.accountState`           | `Opportunity.Account.BillingState`                                                                                                                                                                                                         |
| `opportunity.accountCountry`         | `Opportunity.Account.BillingCountry` (existing)                                                                                                                                                                                            |
| `lineItems[].productName`            | `OpportunityLineItem.Product2.Name` (existing)                                                                                                                                                                                             |
| `lineItems[].productFamily`          | `OpportunityLineItem.Product2.Family`                                                                                                                                                                                                      |
| Stakeholder contact fields           | `OpportunityContactRole.ContactId`, `Role`, `IsPrimary`, and related `Contact.Name`, `Title`, `Email`, `Phone`, `LastActivityDate` (existing collection)                                                                                   |
| Task participants                    | Direct `Task.WhoId` Contact and shared-activity `TaskRelation.RelationId` Contact                                                                                                                                                          |
| Event participants                   | Direct `Event.WhoId` Contact and `EventRelation.RelationId` Contact                                                                                                                                                                        |
| Conversation Task notes              | Completed Task `Description`, with `CompletedDateTime` and Task ID provenance. `CompletedDateTime` is loaded by a bounded API-64 query because the shared API-41 describe helper used by `QueryFactory` rejects this newer standard field. |
| Conversation Event notes             | Past Event `Description`, with `StartDateTime`, `EndDateTime`, and Event ID provenance                                                                                                                                                     |

Participant/attendance rules:

- `OwnerId` is used only to preserve the existing `ownerName`; it is never added to `participants`.
- `Task.WhoId`, `TaskRelation.RelationId`, and non-invitee Event relationships produce `unknown`.
- An `EventRelation` with `IsInvitee = true` produces `invited`, regardless of response status. Invitation/acceptance does not prove attendance.
- No tracked source proves actual attendance, so Salesforce never emits `attended` today.
- Participant queries do not depend on Opportunity Contact Roles, so an activity-linked customer Contact can be included without being a stakeholder.
- Only Contact records returned under the running user's sharing and readable-field context are materialized.
- `Contact.LastActivityDate` remains only a stakeholder field; it is not interpreted as Opportunity participation.

Product capabilities:

- No approved product capability catalog or maintained mapping was found.
- No capability is inferred from product name/family and no LLM is called from Salesforce.
- `productCapabilities` is therefore omitted.

## 5. Conversation availability

Actually present in tracked source:

- Standard Opportunity-related Tasks and Events with descriptions.
- Shared activity relationships through TaskRelation/EventRelation.
- A Live Chat transcript integration used for sales Leads and Case-oriented chat summaries.
- Generic Salesforce Files/ContentDocumentLink usage in unrelated workflows.

Accessible through the implemented request flow:

- Completed Task descriptions and past Event descriptions, only when linked to at least one accessible customer Contact. These are labeled `notes`, not transcripts.

Not implemented/verified:

- Opportunity-linked call/meeting transcripts.
- VoiceCall or conversation-intelligence records linked to these activities.
- Existing conversation summaries with traceable source provenance.
- Files reliably classified as transcripts.

To add transcript or summary sources, Salesforce and GCP owners must agree on the real source object(s), relationship to Opportunity/Task/Event, readable text/summary field, timestamp, participant/attendance evidence, deduplication key, retention limits, and permission model. The configured org schema must be inspected with a valid authorized org before adding those adapters.

## 6. Two complete synthetic request examples

### Populated opportunity

```json
{
  "username": "seller@example.invalid",
  "recordId": "006000000000101",
  "enableOpportunitySummaryEnrichment": true,
  "redactRequired": "true",
  "opportunity": {
    "id": "006000000000101",
    "name": "Fictional Global Collaboration Expansion",
    "amount": 125000,
    "currencyIsoCode": "USD",
    "type": "Expansion",
    "leadSource": "Web",
    "stageName": "Proposal/Price Quote",
    "probability": 65,
    "forecastCategory": "Pipeline",
    "closeDate": "2026-11-30",
    "createdDate": "2026-06-01T09:00:00.000Z",
    "lastModifiedDate": "2026-09-17T10:30:00.000Z",
    "nextStep": "Review security requirements",
    "description": "Expansion of the fictional collaboration deployment.",
    "ownerId": "005000000000101",
    "ownerName": "Sam Seller",
    "accountId": "001000000000101",
    "accountName": "Northstar Example Holdings",
    "accountIndustry": "Manufacturing",
    "accountCity": "Austin",
    "accountCountry": "United States",
    "accountWebsite": "https://northstar.example.invalid",
    "accountState": "Texas"
  },
  "stageHistory": [
    {
      "stageName": "Discovery",
      "amount": 100000,
      "probability": 30,
      "closeDate": "2026-11-30",
      "forecastCategory": "Pipeline",
      "createdDate": "2026-07-01T12:00:00.000Z"
    }
  ],
  "fieldHistory": [
    {
      "field": "Amount",
      "oldValue": 100000,
      "newValue": 125000,
      "createdDate": "2026-09-01T12:00:00.000Z"
    }
  ],
  "activities": {
    "tasks": [
      {
        "subject": "Customer security follow-up",
        "status": "Completed",
        "type": "Call",
        "activityDate": "2026-09-15",
        "createdDate": "2026-09-14T08:00:00.000Z",
        "ownerName": "Sam Seller",
        "description": "Customer asked about regional data controls and rollout sequencing.",
        "sourceRecordId": "00T000000000101",
        "participants": [
          {
            "contactId": "003000000000101",
            "name": "Alex Example",
            "title": "Chief Information Officer",
            "participationStatus": "unknown",
            "evidenceSource": "Task.WhoId contact link"
          }
        ]
      }
    ],
    "events": [
      {
        "subject": "Architecture workshop",
        "startDateTime": "2026-09-16T15:00:00.000Z",
        "endDateTime": "2026-09-16T16:00:00.000Z",
        "createdDate": "2026-09-10T10:00:00.000Z",
        "ownerName": "Sam Seller",
        "description": "The team discussed consolidation, resilience, and phased migration.",
        "sourceRecordId": "00U000000000101",
        "participants": [
          {
            "contactId": "003000000000102",
            "name": "Jordan Example",
            "title": "VP, Infrastructure",
            "participationStatus": "invited",
            "evidenceSource": "EventRelation invitee record"
          }
        ]
      }
    ]
  },
  "stakeholders": [
    {
      "role": "Technical Decision Maker",
      "isPrimary": true,
      "contactId": "003000000000101",
      "name": "Alex Example",
      "title": "Chief Information Officer",
      "email": "alex@example.invalid",
      "phone": "+1 555 010 0101",
      "lastActivityDate": "2026-09-16"
    }
  ],
  "cases": {
    "open": [
      {
        "caseNumber": "00001001",
        "subject": "Fictional provisioning question",
        "status": "Working",
        "priority": "Medium",
        "isEscalated": false,
        "createdDate": "2026-09-01T08:00:00.000Z",
        "closedDate": null,
        "ownerName": "Support Agent",
        "description": "Customer requested clarification."
      }
    ],
    "recentlyClosed": []
  },
  "lineItems": [
    {
      "name": "Fictional Collaboration Suite",
      "productId": "01t000000000101",
      "productName": "Fictional Collaboration Suite",
      "quantity": 500,
      "unitPrice": 20,
      "totalPrice": 10000,
      "discount": 5,
      "serviceDate": "2026-12-01",
      "description": "Commercial line description supplied by Salesforce.",
      "productFamily": "Collaboration"
    }
  ],
  "relatedOpportunities": [
    {
      "id": "006000000000102",
      "name": "Fictional Initial Purchase",
      "amount": 60000,
      "currencyIsoCode": "USD",
      "type": "New Business",
      "stageName": "Closed Won",
      "forecastCategory": "Closed",
      "probability": 100,
      "isWon": true,
      "isClosed": true,
      "closeDate": "2025-12-15",
      "createdDate": "2025-09-01T09:00:00.000Z"
    }
  ],
  "conversationEvidence": {
    "items": [
      {
        "sourceRecordId": "00U000000000101",
        "relatedActivityId": "00U000000000101",
        "occurredAt": "2026-09-16T15:00:00.000Z",
        "sourceType": "Event",
        "contentType": "notes",
        "text": "The team discussed consolidation, resilience, and phased migration.",
        "participants": [
          {
            "contactId": "003000000000102",
            "name": "Jordan Example",
            "title": "VP, Infrastructure",
            "participationStatus": "invited",
            "evidenceSource": "EventRelation invitee record"
          }
        ],
        "isTruncated": false
      }
    ]
  },
  "dataCoverage": {
    "stakeholders": {
      "status": "available",
      "returnedCount": 1,
      "isTruncated": false
    },
    "activities": {
      "status": "available",
      "windowStart": "2026-03-22T10:30:00.000Z",
      "windowEnd": "2026-09-18T10:30:00.000Z",
      "returnedCount": 2,
      "isTruncated": false
    },
    "conversations": {
      "status": "available",
      "windowStart": "2026-06-20T10:30:00.000Z",
      "windowEnd": "2026-09-18T10:30:00.000Z",
      "returnedCount": 1,
      "isTruncated": false,
      "reasonCode": "activity_notes_only"
    },
    "lineItems": {
      "status": "available",
      "returnedCount": 1,
      "isTruncated": false
    }
  }
}
```

### Sparse opportunity without optional sources

```json
{
  "username": "seller@example.invalid",
  "recordId": "006000000000201",
  "enableOpportunitySummaryEnrichment": false,
  "redactRequired": "false",
  "opportunity": {
    "id": "006000000000201",
    "name": "Fictional Sparse Opportunity",
    "amount": null,
    "currencyIsoCode": "USD",
    "type": null,
    "leadSource": null,
    "stageName": "Prospecting",
    "probability": 10,
    "forecastCategory": "Pipeline",
    "closeDate": "2027-01-31",
    "createdDate": "2026-09-18T09:00:00.000Z",
    "lastModifiedDate": "2026-09-18T09:00:00.000Z",
    "nextStep": null,
    "description": null,
    "ownerId": "005000000000201",
    "ownerName": "Taylor Seller",
    "accountId": "001000000000201",
    "accountName": "Sparse Example Ltd",
    "accountIndustry": null,
    "accountCity": null,
    "accountCountry": null
  },
  "stageHistory": [],
  "fieldHistory": [],
  "activities": {
    "tasks": [],
    "events": []
  },
  "stakeholders": [],
  "cases": {
    "open": [],
    "recentlyClosed": []
  },
  "lineItems": [],
  "relatedOpportunities": [],
  "conversationEvidence": {
    "items": []
  },
  "dataCoverage": {
    "stakeholders": {
      "status": "not_found",
      "returnedCount": 0,
      "isTruncated": false,
      "reasonCode": "no_visible_records"
    },
    "activities": {
      "status": "not_found",
      "windowStart": "2026-03-22T10:30:00.000Z",
      "windowEnd": "2026-09-18T10:30:00.000Z",
      "returnedCount": 0,
      "isTruncated": false,
      "reasonCode": "no_visible_records_in_window"
    },
    "conversations": {
      "status": "not_found",
      "windowStart": "2026-06-20T10:30:00.000Z",
      "windowEnd": "2026-09-18T10:30:00.000Z",
      "returnedCount": 0,
      "isTruncated": false,
      "reasonCode": "transcripts_not_supported_no_recent_notes"
    },
    "lineItems": {
      "status": "not_found",
      "returnedCount": 0,
      "isTruncated": false,
      "reasonCode": "no_visible_records"
    }
  }
}
```

## 7. Coverage semantics

- An empty collection means no qualifying records visible to the running user were returned by that bounded query. It is not proof that the real-world evidence does not exist.
- `not_accessible` means the relevant object/source was not readable; inaccessible scalar fields are omitted.
- `error` is reserved for a narrowly caught optional enrichment failure. Core activity rows still proceed.
- Activity coverage describes the preserved 180-day query. Conversation coverage describes the configurable recent window, default 90 days.
- `isTruncated = true` means at least one local item, relation, text, or request-size cap affected the collection.
- `isTruncated = false` does not mean globally complete. Sharing, retention, integrations, and Salesforce data-entry practices can still limit evidence.
- Missing conversations cannot be interpreted as “the topic was not discussed.” The backend must not derive a global “AI was not discussed” conclusion from empty or truncated evidence.
- `Contact.LastActivityDate` cannot be used as proof of Opportunity participation.
- `invited` cannot be interpreted as attended, and `unknown` cannot be interpreted as absent.

## 8. Configuration and activation

Hierarchy custom setting: `GCP_Feature_Toggle__c`

- `Enable_Opportunity_Summary_Enrichment__c` — Checkbox, default `false`. When false, optional enrichment evidence is omitted and the request carries only the new top-level control `enableOpportunitySummaryEnrichment: false`.
- `Opportunity_Summary_Recent_Days__c` — Number(3,0), default `90`. Accepted runtime range is 1–365; missing, zero, negative, nonnumeric, or greater-than-365 values fall back to 90.

The existing Opportunity Summary feature switch `Enable_Opportunity_Summary__c`, authentication, endpoint configuration, service account, certificate, token exchange, and redaction flag remain unchanged. No credentials, endpoint URLs, IDs, or environment-specific values were added.

The resolved `Enable_Opportunity_Summary_Enrichment__c` value is sent on every request as `enableOpportunitySummaryEnrichment`. Salesforce omits the optional enrichment evidence when false; GCP must also skip public-intelligence processing when the value is false.

Activation requires deploying the two custom-setting fields, class, and test metadata, then setting `Enable_Opportunity_Summary_Enrichment__c = true` at the intended hierarchy level only after the GCP parser is ready. No broader object/field permissions were added. Users continue to receive only data allowed by existing sharing and read access.

## 9. Tests

Added `GCPCalloutForOpportunitySummaryTest` with isolated checks for:

- Existing field shapes and feature-disabled behavior.
- Empty activities, conversations, stakeholders, and line items.
- Product name/family mapping without invented capabilities.
- Direct/shared participant relationships, non-OCR participants, unknown attendance, and invited-not-attended behavior.
- Activity owners excluded from customer participants.
- Missing/inaccessible optional values.
- Conversation provenance, content classification, deduplication, completion checks, 10-item limit, and 4,000-character truncation.
- Unsupported transcript coverage semantics.
- Optional participant-source failure preserving core activity rows.
- Conversation-first and participant-second request-size trimming, plus explicit rejection of an oversized core payload.
- Feature setting defaults/configured recent window.
- Exact Boolean GCP control mapping for the resolved enrichment setting.
- Exact `/api/v1/opportunity_summary` endpoint normalization.
- Legacy, enriched, and malformed optional response-adapter behavior with snake_case fields preserved.
- Legacy `QueryFactory` compatibility for Task retrieval and exact `CompletedDateTime` loading through the API-64 query path.
- LWC evidence parsing, ID-based badge resolution, focus/highlight navigation, finding groups, explicit source-index mapping, URL validation, collapsed queries, LWS suggestion-markup handling, sanitized `<strong>` rendering in Deal Score and History, CRM-only score/history behavior, storage privacy, and single-callout behavior.

Executed locally:

```text
npx prettier --check <changed Apex/XML/Markdown files>
npx eslint force-app/main/default/lwc/opportunitySummary/opportunitySummary.js force-app/main/default/lwc/opportunitySummary/__tests__/opportunitySummary.test.js
npx sfdx-lwc-jest -- --runInBand --runTestsByPath <absolute opportunitySummary.test.js path>
git diff --check
```

The focused Opportunity Summary Jest suite passes all 19 tests.

An attempted local Salesforce code-analyzer run could not execute because the CLI plugin was unavailable and installation failed. The latest Salesforce check-only validation job, `0AfTH00000IBrD70AL`, compiled `GCPCalloutForOpportunitySummary`, its test class, and the `opportunitySummary` LWC and passed all 18/18 Apex tests with no component or test errors. Its overall status was Failed only because selected-class coverage was 51.249%, below the 75% deployment threshold. No metadata was deployed because the operation was check-only.

The focused Apex test command for a future authorized validation remains:

```text
sf apex run test --class-names GCPCalloutForOpportunitySummaryTest --result-format human --wait 30 --target-org <authorized-alias>
```

## 10. Backend follow-up

GCP must parse, behind the same experiment rollout:

- `enableOpportunitySummaryEnrichment` (required Boolean control; skip intelligence when false)
- `opportunity.accountWebsite`
- `opportunity.accountState`
- `lineItems[].productFamily`
- `activities.tasks[].sourceRecordId`
- `activities.tasks[].participants[]`
- `activities.events[].sourceRecordId`
- `activities.events[].participants[]`
- `conversationEvidence.items[]`
- `dataCoverage.{stakeholders,activities,conversations,lineItems}`

Before enabling:

- Confirm the backend treats all new fields as optional and ignores unknown fields while disabled/rolling out.
- Confirm it never equates `invited` with attendance or `unknown` with nonparticipation.
- Confirm it treats `notes` as notes, not transcripts.
- Confirm public research receives only the backend-selected/redacted company/product context; private Salesforce activities, contacts, and notes must remain inside the authenticated summary request.
- Confirm missing/truncated evidence does not yield a definitive “not discussed” conclusion.
- Decide whether a real approved product-capability catalog will be supplied and owned.
- Identify/agree on any real Opportunity-linked transcript/summary objects and permissions before Salesforce adds another source adapter.
- Validate target-org availability of TaskRelation, EventRelation, Contact fields, and the new custom-setting fields before activation. `Task.CompletedDateTime` availability and the isolated API-64 query path were verified in DevGss.

## 11. Salesforce response and UI handling

The Salesforce-to-GCP interaction remains one authenticated `POST /api/v1/opportunity_summary` call. The Apex adapter still returns the existing UI contract:

```json
{
  "success": true,
  "cards": []
}
```

When `body.opportunity_enrichment` is an object, Apex adds it without renaming its nested snake_case fields:

```text
opportunity_enrichment.findings[].id
opportunity_enrichment.findings[].kind
opportunity_enrichment.findings[].date
opportunity_enrichment.findings[].date_type
opportunity_enrichment.findings[].fact
opportunity_enrichment.findings[].person_name
opportunity_enrichment.findings[].role
opportunity_enrichment.findings[].relevance
opportunity_enrichment.findings[].suggested_action
opportunity_enrichment.findings[].source_indices
opportunity_enrichment.sources[].index
opportunity_enrichment.sources[].title
opportunity_enrichment.sources[].display_label
opportunity_enrichment.sources[].url
opportunity_enrichment.web_search_queries[]
opportunity_enrichment.search_entry_point.rendered_content
```

The LWC validates this optional object independently from the summary. Valid `[E<number>]` references in eligible summary sections become keyboard-accessible buttons linked by finding ID. Unknown references remain visible. Deal Score and Opportunity History remain CRM-only, but now use `lightning-formatted-rich-text` so supported `<strong>` tags render instead of appearing literally. The research region groups valid findings into Current Leadership and Company Direction and Priorities, keeps source relationships in the order returned by each finding, resolves sources by explicit `sources[].index`, and renders only valid HTTP/HTTPS URLs as links.

Queries and aggregate sources are collapsed initially. Search queries, facts, relevance, and suggested actions are rendered as text. Existing summary text fragments use `lightning-formatted-rich-text` so supported `<strong>` formatting remains while Salesforce sanitization stays in force.

The Google Search Suggestions provider markup is intentionally not injected or rewritten. Salesforce documents that Lightning Web Security sanitizes content strings inserted into HTML and SVG elements, including strings assigned through `innerHTML`: <https://developer.salesforce.com/docs/platform/lightning-components-security/guide/lws-sanitize.html>.
