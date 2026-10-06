# Call transcripts switch: Salesforce handover for GCP

To: GCP agent (Opportunity Summary + Account Summary services)
From: Karthik, 2026-10-06
Status: the Salesforce half is built and deployed to DevGss (deploy `0AfTH00000IMi3I0AT`). Both switches are OFF.

## What Salesforce now sends

Each request body has one new top-level field. It is always present, and it is always a JSON boolean, never null and never a string.

| Request                                             | Field                                     | Source                                                          |
| --------------------------------------------------- | ----------------------------------------- | --------------------------------------------------------------- |
| Opportunity Summary (`/api/v1/opportunity_summary`) | `enableOpportunitySummaryCallTranscripts` | `GCP_Feature_Toggle__c.Opportunity_Summary_Call_Transcripts__c` |
| Account Summary (`/api/v1/account_summary`)         | `enableAccountSummaryCallTranscripts`     | `GCP_Feature_Toggle__c.Account_Summary_Call_Transcripts__c`     |

- `GCP_Feature_Toggle__c` is a hierarchy custom setting, so an admin can flip either switch without a deploy. The setting resolves for the viewing user, then the profile, then the org default.
- Both fields default to `false`. With no setting record at all, Salesforce sends `false`.
- Nothing else in either request changed. The Opportunity request still sends `recordId`, `opportunity.accountId`, `activities.tasks[].id` / `description` and `conversationEvidence`. The Account request still sends `recordId`.
- Salesforce sends no credentials and calls nothing new.

Sample (Ids masked, other fields unchanged and left out):

```json
// Opportunity Summary
{ "recordId": "006XXXXXXXXXXXXXXX",
  "enableOpportunitySummaryEnrichment": true,
  "enableOpportunitySummaryCallTranscripts": false, ... }

// Account Summary
{ "recordId": "001XXXXXXXXXXXXXXX",
  "enableAccountSummaryEnrichment": true,
  "enableAccountSummaryCallTranscripts": false, ... }
```

## What Salesforce expects from GCP

These match the behaviour in your brief. Salesforce relies on them:

- `false` or a non-boolean value means transcripts are OFF. Make no ACE++ call, and return exactly today's response.
- `true` means the GCP switch decides (`ACE_TRANSCRIPTS_OPPORTUNITY_ENABLED` / `ACE_TRANSCRIPTS_ACCOUNT_ENABLED`).
- A bad value never causes an error response.
- `record_references` is unchanged:
  - Links only ever use Ids that were in the request.
  - Calls found only through ACE++ are never linked.
  - Call links keep `object_type: "Task"` and `activity_kind: "Call"`.
- The ACE++ step finishes inside the existing 120s callout timeout.

## How Salesforce handles the response

- Salesforce copies only the response fields it knows. The optional `call_transcripts` block is dropped and is not logged, so the UI is identical with or without it.
- If you need the block in Salesforce for diagnostics, tell us and we'll pass it through. It must still carry no transcript text.

## Tests (DevGss, deploy `0AfTH00000IMi3I0AT`, 62/62 passed)

- `GCPCalloutForOpportunitySummaryTest` (44 tests; class coverage 88.57%)
  - `sendsCallTranscriptsTrueAsJsonBooleanWhenSettingOn`
  - `sendsCallTranscriptsFalseAsJsonBooleanWhenSettingOff`
  - `sendsCallTranscriptsFalseWhenNoSettingRecordExists`
  - `requestControlIsNeverNull`
  - `responseWithAndWithoutCallTranscriptsBlockRendersTheSame`
- `Test_GCPCalloutForAccountSummary` (18 tests; class coverage 97.15%)
  - `shouldSendCallTranscriptsTrueAsJsonBooleanWhenSettingOn`
  - `shouldSendCallTranscriptsFalseAsJsonBooleanWhenSettingOff`
  - `shouldSendCallTranscriptsFalseWhenNoSettingRecordExists`
  - `shouldRenderTheSameWhenResponseHasCallTranscriptsBlock`

## Where the code lives

- `GCPCalloutForOpportunitySummary.buildPayload` → `addCallTranscriptsRequestControl`, which reads `isOpportunitySummaryCallTranscriptsEnabled()`
- `GCPCalloutForAccountSummary.buildPayload`, which reads `isAccountSummaryCallTranscriptsEnabled()`

## Not done yet

- Both switches stay OFF in every org until Karthik confirms data-handling approval for production transcripts.
- Nothing has been deployed outside DevGss. BisUAT is read-only.
- End-to-end testing needs the GCP side deployed to the DevGss service. Then:
  1. Set the DevGss org default row (or one test user's row) to `true`.
  2. Turn the matching GCP switch on.
  3. Check that the `call_transcripts` status comes back, and that the summary and `record_references` are unchanged.
