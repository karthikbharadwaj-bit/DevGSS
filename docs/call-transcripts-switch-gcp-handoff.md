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
- The Opportunity request still sends `recordId`, `opportunity.accountId`, `activities.tasks[].id` / `description` and `conversationEvidence`. The Account request also sends `recordId`, plus new activity row fields and a wider activity filter (see the 2026-10-08 update below).
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

## Update 2026-10-08: Account Summary activity rows

Deployed to DevGss in deploy `0AfTH00000IOG650AH` (20/20 tests passed).

- **New fields on each `tasks` and `events` row:**
  - `id`: the 18-character record Id.
  - `subject`.
  - `createdDate`: an ISO-8601 datetime.
  - `description`: cut to the first 1000 characters, with URLs left intact.
  - Any of the four can be `null`, for example when the user can't read the field. DevGss clears `Event.Subject` when an event is saved, so event `subject` is often `null` there.
- **Which activities are selected:** Tasks and Events now match on `AccountId = <account>` instead of `WhatId = <account>`. Activities logged on the account's opportunities, cases and contacts are now included. Before this change, Bank of America's call Task `00TTH00000MtVsv2AF` and both opportunity Events were missing because they are logged on the opportunity.
- **Unchanged:**
  - Caps: 5 tasks and 5 events, latest `ActivityDate` first.
  - Date filter: `ActivityDate <= TODAY`, which includes today.
  - Tasks with subtype `ListEmail` are still excluded.
  - Activities with no `ActivityDate` are still left out.

Sample `tasks` row (Ids masked):

```json
{
  "id": "00TXXXXXXXXXXXXXXX",
  "subject": "Call with Bank of America",
  "createdDate": "2026-10-08T04:30:29.000Z",
  "description": "RingSense call details link - https://ringsense.ops.ringcentral.com/calls/<UUID>\n…",
  "activityDate": "2026-10-08",
  "taskSubtype": "Call"
}
```

New tests in `Test_GCPCalloutForAccountSummary`:

- `shouldSendRingSenseFieldsOnTaskAndEventRows`: a Task and an Event logged on the account's opportunity are both sent, with all four fields and a 1000-character description that keeps the link.
- `shouldSerializeTasksAsEmptyListWhenAccountHasNoTasks`: with no Tasks, the request still sends `tasks: []`.

## Update 2026-10-08: call-insight icon

Deployed to DevGss in deploy `0AfTH00000IOGpF0AX`.

- **Correction:** neither summary uses typed response DTOs. Account Summary already passed `account_summary` through untouched, so `from_call` needed no Apex change. Opportunity Summary keeps only response keys it knows, so it now passes `call_insights` through unchanged, but only when the value is a list.
- **Opportunity:**
  - A small grey `utility:call` icon shows at the right of each line named in `call_insights`.
  - `section` must match an `opportunity_summary` key. `index` is the 0-based position in that key's list as GCP sent it. Blank lines and the score badge don't shift positions.
  - Stage history lines never show the icon.
  - Malformed entries are ignored.
- **Account:** the same icon shows on risk, growth and recommended-action items with `from_call: true`. A missing key, or any value other than `true`, means no icon.
- **Layout:** the icon's space is reserved only when the summary flags at least one line or item. Otherwise the layout is exactly as before.
- **Tooltip and alternative text:** labels `OpportunitySummaryFromCall` and `AccountSummaryFromCall` ("From a recorded customer call (RingSense)").

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
