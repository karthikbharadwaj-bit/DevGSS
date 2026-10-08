# Account Summary: where every insight comes from

This document covers the Account Summary (Beta) component on the Account record page. For every insight it shows, you get the Salesforce fields it reads, how the value is calculated, which part of the system does the work, and what it can get wrong.

State as of 2026-10-08, DevGss deploy `0AfTH00000IOK3F0AX`.

## How the pieces fit

| Part                | Component                                         | Job                                                                                                                                                               |
| ------------------- | ------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Salesforce, server  | Apex `GCPCalloutForAccountSummary`                | Reads the Account and its related records, sends them to GCP, returns the response. It filters and limits records but does no maths.                              |
| GCP                 | Cloud Run service, `POST /api/v1/account_summary` | Calculates every count, total, score, band and date difference. Writes all prose: narrative, risks, growth, actions, routing, timeline. Runs public web research. |
| Salesforce, browser | LWC `aiAccountSummary`                            | Lays out the response, formats numbers and dates, shortens long lists, caches the result.                                                                         |

A rule of thumb: **if a number or sentence appears on screen, GCP produced it.** Salesforce decides which records GCP gets to see.

### Switches and settings

| Setting                                                       | Where                                                                 | Effect                                                                               |
| ------------------------------------------------------------- | --------------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| `Enable_Account_Summary__c`                                   | Custom setting `GCP_Feature_Toggle__c` (user, profile or org default) | Shows or hides the whole component.                                                  |
| `Enable_Account_Summary_Enrichment__c`                        | Same                                                                  | Sent as `enableAccountSummaryEnrichment`. Asks GCP to run public web research.       |
| `Account_Summary_Call_Transcripts__c`                         | Same                                                                  | Sent as `enableAccountSummaryCallTranscripts`. Kill switch for call transcripts.     |
| `Account_Summary_Endpoint__c`                                 | Custom setting `GCP_Endpoint_Settings__c`                             | The GCP service URL. Apex always calls its `/api/v1/account_summary` path.           |
| `AccountSummaryTimeoutSeconds`                                | Custom label                                                          | Callout timeout. Default and maximum 120 seconds.                                    |
| `AccountSummaryCacheHours`, `AccountSummaryCacheMaxKB`        | Custom labels                                                         | Browser cache lifetime (default 1 hour) and size (default 512 KB).                   |
| `AccountSummaryListRowsInitial`, `AccountSummaryListRowLimit` | Custom labels                                                         | Opportunity and case rows before and after View more (3 and 10; never more than 10). |

## What Salesforce sends to GCP

Apex runs one query per list. Each list asks for one more row than its limit, so `dataCoverage.<list>.isTruncated` can tell GCP that more records exist. A list that ran and found nothing is sent as `[]`. Fields the user can't read are sent as `null` (Apex uses `Security.stripInaccessible`).

### The Account

`Account.Id, Name, Type, Industry, BillingCity, BillingState, BillingCountry, Website, CurrencyIsoCode, OwnerId, Owner.Name, CSM_Name__c, RC_Account_Status__c, RC_Tier__c, RC_Activation_Date__c (sent as a date), MRR__c, aMRR__c, Total_Net_MRR__c, Total_Won_Opportunities__c, Next_Renewal_Date__c, Licenses_Purchased__c, Number_of_Extensions__c, Days_Since_Activity__c, C360_Overall_Risk_Score__c, C360v2_Overall_Adoption_Score__c, Account_Health__c, Upsell_Potential__c, Rating, AccountSource`

### Related lists

| List                  | Object and filter                                                                                                   | Sort                            | Limit |
| --------------------- | ------------------------------------------------------------------------------------------------------------------- | ------------------------------- | ----- |
| `openOpportunities`   | Opportunity, `AccountId` = account, `IsClosed = false`                                                              | CloseDate, oldest first         | 200   |
| `closedOpportunities` | Opportunity, `IsClosed = true`                                                                                      | CloseDate, newest first         | 15    |
| `openCases`           | Case, `IsClosed = false`                                                                                            | CreatedDate, oldest first       | 200   |
| `recentlyClosedCases` | Case, `IsClosed = true`, closed in the last 183 days                                                                | ClosedDate, newest first        | 15    |
| `escalations`         | Red_Account__c, `EscalatedAccount__c` = account, open and resolved                                                  | Red_Start_Date__c, newest first | 200   |
| `entitlements`        | Entitlement__c, `Account__c` = account, `Active__c = true`                                                          | none                            | 100   |
| `accountTeamMembers`  | AccountTeamMember                                                                                                   | none                            | 50    |
| `contacts`            | Contact                                                                                                             | LastActivityDate, newest first  | 20    |
| `tasks`               | Task, `AccountId` = account, plus the activity filters below                                                        | ActivityDate, newest first      | 20    |
| `caseTasks`           | Task on the account's Cases whose `AccountId` is not the account, plus the activity filters below                   | ActivityDate, newest first      | 10    |
| `events`              | Event, `AccountId` = account, dated today or earlier, Type is not "System Use"                                      | ActivityDate, newest first      | 10    |
| `upcomingEvents`      | Event, `AccountId` = account, next 30 days, Type is not "System Use"                                                | StartDateTime, soonest first    | 5     |
| `retentionTasks`      | Retention_Task__c, `Account__c` = account                                                                           | CreatedDate, newest first       | 5     |
| `orders`              | Order                                                                                                               | EffectiveDate, newest first     | 5     |
| `contracts`           | Contract                                                                                                            | EndDate, newest first           | 5     |
| `accountHistory`      | AccountHistory, changes to `RC_Account_Status__c` and `Owner` in the last 90 days, names only (`DataType = 'Text'`) | CreatedDate, newest first       | 20    |

Fields sent per list:

- **Opportunities:** Id, Name, StageName, Type, Amount, CurrencyIsoCode, CloseDate, Owner.Name. Open ones add NextStep, Probability, ForecastCategoryName; closed ones add IsWon.
- **Cases:** Id, CaseNumber, Subject, Status, Priority, IsEscalated, CreatedDate, Reason, Type, Owner.Name. Closed ones add ClosedDate.
- **Escalations:** Status__c, Risk_Type__c, Risk_Reason__c, Revenue_at_Risk__c, CurrencyIsoCode, Escalation_Category__c, Escalation_Trend__c, Red_Start_Date__c, Red_End_Date__c, Yellow_Start_Date__c.
- **Entitlements:** Display_Name__c, DisplayQuantity__c, Total_Monthly_Price__c, CurrencyIsoCode, Start_Date__c, End_Date__c, Active__c.
- **Account team:** TeamMemberRole, User.Name. **Contacts:** Id, Name, Title, Customer_Contact_Role__c, LastActivityDate.
- **Tasks and case tasks:** Id, Subject, CreatedDate, Description (first 1,000 characters), ActivityDate, TaskSubtype, Type, CallDurationInSeconds, WhatId (`relatedToId`), the object type of WhatId (`relatedToType`), What.Name, Who.Name, Owner.Name.
- **Events and upcoming events:** Id, Subject, CreatedDate, Description (first 1,000 characters), ActivityDate, StartDateTime, DurationInMinutes, Type, WhatId, its object type, What.Name, Who.Name, CreatedBy.Name.
- **Retention tasks:** Status__c, Dunning_Status__c. **Orders:** Status, EffectiveDate. **Contracts:** Status, EndDate. **Account history:** Field, OldValue, NewValue, CreatedDate.

### Activity filters (tasks and case tasks)

The rules come from an analysis of a year of BISUAT activity (2026-10-08). The goal is to send contact with the customer, not to-dos or system notices.

- **Completed only** (`IsClosed = true`). Open tasks are plans. In BISUAT almost all of them were system to-dos: 1,252 "The account for case # has not been found, please reassign." tasks on cases, and 269 "Follow up with X regarding their expiring trial" tasks on accounts.
- **No list emails** (`TaskSubtype != 'ListEmail'`).
- **Nothing dated in the future.** A blank ActivityDate is allowed.
- **No automated senders**, matched on the creator's name: Automation Service (third-party activation and quantity-change emails on opportunities), RC Support Agent (case auto-acknowledgements), User Marketo, Workato Integration User, AIM GTM Intelligence and Comm ODS Integration.
- **No auto-acknowledgements:** subjects starting "Email: Thank you for contacting us".

**Why case tasks are a separate list.** Salesforce fills `Task.AccountId` from the Account, Opportunity, Contract, a custom child of Account, or the task's Contact. It does not fill it from a Case. In DevGss, 122 of 129 case tasks from the last 90 days had no `AccountId`. A task on a Case whose Contact belongs to the account already has `AccountId` set, so it goes in `tasks`, and `caseTasks` leaves it out to avoid duplicates.

## Insight by insight

### Account intelligence header

| On screen      | Salesforce source                                                                              | Calculation                   | Limitations                                                                                                                                                                           |
| -------------- | ---------------------------------------------------------------------------------------------- | ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Account        | `Account.Name`                                                                                 | none                          |                                                                                                                                                                                       |
| Industry       | `Account.Industry`                                                                             | none                          |                                                                                                                                                                                       |
| Location       | `Account.BillingCity`, `BillingState`, `BillingCountry`                                        | joined with commas            | Billing address only.                                                                                                                                                                 |
| Type / status  | `Account.Type`, `Account.RC_Account_Status__c`                                                 | joined                        | Production stores "PAID"; sandboxes store "Paid". Compare without regard to case.                                                                                                     |
| Tier           | `Account.RC_Tier__c`                                                                           | none                          | 99.9% filled in production, but on only one DevGss account.                                                                                                                           |
| Owner          | `Account.Owner.Name`                                                                           | none                          |                                                                                                                                                                                       |
| CSM            | `Account.CSM_Name__c`; else the account team member with role "Customer Success Manager (CSM)" | GCP picks the first available | Filled on about 18% of active customers. "No CSM assigned" is a real state. Automation overwrites `CSM_Name__c` from the account team, so set the account team rather than the field. |
| Customer since | `Account.RC_Activation_Date__c`                                                                | GCP: months since activation  | The field is a date and time; Apex sends the date only.                                                                                                                               |
| Rating         | `Account.Rating`                                                                               | none                          | Usually empty.                                                                                                                                                                        |
| Source         | `Account.AccountSource`                                                                        | none                          | Usually empty.                                                                                                                                                                        |
| Narrative      | All lists above                                                                                | Written by GCP                | Prose; check it against the tiles.                                                                                                                                                    |

The browser shows every header row. An empty field shows a grey dash, and so does a value GCP marks "not recorded in Salesforce".

### Key metrics (the five tiles)

All five always show. A tile whose fields are empty shows a grey dash and "No value in Salesforce".

| Tile                         | Salesforce source                                                                | Calculation (GCP)                                                                                       | Limitations                                                                                                                                                                                                    |
| ---------------------------- | -------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Monthly recurring revenue    | `Account.MRR__c` (label "Combined Current Total MRR"), `Account.CurrencyIsoCode` | Second line: MRR × 12, "annualized"                                                                     | The org has no ARR field. Production fill is 100%, but only within the active-customer filter, which itself requires MRR above 0.                                                                              |
| MRR trajectory               | `MRR__c`, `aMRR__c` ("Combined Acquisition MRR")                                 | (MRR − aMRR) ÷ aMRR × 100, to one decimal place. Second line shows aMRR.                                | Blank when aMRR is 0 or empty. Compares now with acquisition, not with last month.                                                                                                                             |
| Total open pipeline          | `Opportunity.Amount`, `CurrencyIsoCode` on open opportunities                    | Sum of amounts; second line is the count                                                                | Can be negative (downsell and credit deals). Shows "Mixed currencies" instead of a total when currencies differ. DevGss automation sets Amount to 0 on new opportunities. Counts up to 200 open opportunities. |
| Open cases                   | `Case.Priority`, `CreatedDate`, `IsEscalated` on open cases                      | Count; second line is the highest priority, oldest age in days and escalated count (or "not escalated") | Production has open cases from 2011 that were never closed, so "oldest" can be years. Priority naming is mixed (Critical, P0 to P4, "1 – Critical"). Counts up to 200 open cases.                              |
| Licenses purchased vs in use | `Licenses_Purchased__c`, `Number_of_Extensions__c`                               | Second line: extensions ÷ purchased (utilization %) and purchased − extensions (unassigned)             | "In use" is the extension count, which includes non-user extensions, so utilization can pass 100%. Purchased is 91.5% filled in production.                                                                    |

### Account flag (score, band, components)

GCP calculates a score out of 100 from seven parts, picks a band (Green, Amber or Red) and can override the band. The point values below come from the production audit's scoring design (2026-09-10); GCP owns the exact rules.

| Component          | Salesforce source                                                 | Points | Notes                                                                                                                                              |
| ------------------ | ----------------------------------------------------------------- | ------ | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| Revenue trajectory | `MRR__c`, `aMRR__c`                                               | 15     | Higher when MRR is above acquisition MRR.                                                                                                          |
| Renewal risk       | `Account.Next_Renewal_Date__c`                                    | 15     | Days to renewal. **The field's Salesforce label is "Account Next Billing Date"**, so check that it really is the renewal date.                     |
| Ownership coverage | `OwnerId`, `CSM_Name__c`, account team CSM role                   | 10     | Full points need an owner and a CSM.                                                                                                               |
| Pipeline health    | `Opportunity.NextStep` on open opportunities                      | 15     | Share of open opportunities with a next step. Production fills NextStep on 0.055% of open opportunities, so this is low almost everywhere.         |
| Engagement recency | `tasks`, `caseTasks`, `events`; fallback `Days_Since_Activity__c` | 15     | Days since the latest activity. GCP has been asked to use all three lists (handover 2026-10-08).                                                   |
| Escalation history | `Red_Account__c` status and Red dates                             | 15     | Lifetime count, days in Red, open escalations. In DevGss, 10,117 of 10,622 resolved Red records have no end date, so a missing end date is common. |
| Open case burden   | Open cases: count, oldest age, escalated                          | 15     |                                                                                                                                                    |

- **"… — set by override":** shown when a rule forces the band. Example: an open opportunity past its close date.
- **"Amber floor from …":** the date the oldest open case pushes the flag to Amber.
- **Escalation routing (Notify, Record, Watch):** written by GCP from the owner, account team, opportunities and cases.

### Risk vs growth signals and Recommended actions

- **Source:** written by GCP from every list above.
- **Calculation:** each item has a title and detail. Actions add a timing chip (Today, This week, Post-close) and a lane (Sales, Service).
- **Evidence chips:** E1, E2 and so on link to a public web research finding.
- **Display rule:** the browser drops any item GCP marks "not recorded in Salesforce".
- **Limitations:**
  - These are generated text. They can repeat the same fact as a tile.
  - Status changes in `accountHistory` show up here, including changes made only to load test data. On Bank of America in DevGss, a blank → PAID fill appears as "Account status returned to paid".

### Open opportunities

| Column           | Salesforce source                                                  | Notes                                                          |
| ---------------- | ------------------------------------------------------------------ | -------------------------------------------------------------- |
| Name             | `Opportunity.Name` (links to the record), `Owner.Name`, `NextStep` | Next step hidden when empty.                                   |
| Stage            | `StageName`, `ForecastCategoryName`, `Probability`                 |                                                                |
| Amount           | `Amount`, `CurrencyIsoCode`                                        |                                                                |
| Close date       | `CloseDate`                                                        | Overdue chip when the date has passed.                         |
| Agreement status | `Order.Status`                                                     | A stand-in; Salesforce has no agreement status field for this. |

The browser shows 3 rows, then View more expands to 10, sorted by soonest close date. View all opens the Account's Opportunities related list, which also shows closed opportunities. The heading count is the full number GCP returned.

### Cases

| Column                            | Salesforce source                                                                                           | Notes                                              |
| --------------------------------- | ----------------------------------------------------------------------------------------------------------- | -------------------------------------------------- |
| Open · N                          | Open cases                                                                                                  | Count GCP returned.                                |
| Subject                           | `Case.Subject` (links to the record) or `CaseNumber`; second line `CaseNumber`, `Status`, `Reason` / `Type` |                                                    |
| Priority                          | `Case.Priority`                                                                                             | Critical, P0, P1 and "1 – Critical" show in red.   |
| Owner                             | `Case.Owner.Name`                                                                                           |                                                    |
| Age                               | `Case.CreatedDate`                                                                                          | Days open.                                         |
| Escalated                         | `Case.IsEscalated`                                                                                          |                                                    |
| Recently closed · N in six months | `Subject`, `Priority`, `ClosedDate`                                                                         | Apex sends up to 15; the heading uses GCP's count. |

Both lists show 3 rows, then up to 10 with View more. Open cases are sorted newest opened first; closed cases newest closed first. View all opens the Cases related list.

### Account history (timeline)

- **Source:** written by GCP, grouped into "Open now" and months, from:
  - open, won and lost opportunities
  - cases
  - entitlements
  - Red Account escalations
  - `RC_Activation_Date__c`
  - `accountHistory` (status and owner changes, last 90 days)
- **Display rule:** the card grows to 10 entries. After that it stops at the bottom of the tenth entry and scrolls inside the card. The card has no scrollbar; instead, the bottom fades while more entries are below, and the fade goes away at the end.
- **Limitations:**
  - GCP sets no limit on entries, so "Open now" can repeat items already in the Opportunities and Cases cards.
  - AccountHistory only covers Account Status and Owner. The other tracked fields (Health, Sentiment, Tier, Upsell, C360 risk) have no history rows in production.
  - AccountHistory only goes back 90 days.

### Key contacts and Account team

| Column         | Salesforce source                               | Notes                                                                                               |
| -------------- | ----------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| Name and title | `Contact.Name`, `Title`                         | Up to 20, most recent activity first.                                                               |
| Role in CRM    | `Contact.Customer_Contact_Role__c`              | Values in this org are RC Admin User, Signatory, Other and Super Admin. None mean "decision maker". |
| Last activity  | `Contact.LastActivityDate`                      |                                                                                                     |
| Account team   | `AccountTeamMember.TeamMemberRole`, `User.Name` | Up to 50.                                                                                           |

### Public web research

- **Source:** not Salesforce. GCP runs a public web search when `Enable_Account_Summary_Enrichment__c` is on.
- **Display:** a collapsed drawer.
  - Cited findings: those referenced by an E# chip.
  - Additional findings: in a further collapsed group.
  - Each finding has its source links. The browser prefers the publisher's URL over Google's redirect link.
- **Limitations, seen in DevGss on 2026-10-01:**
  - GCP returned no research on 2 of 4 calls.
  - When it did return research, it never cited any of it in the summary, so no E# chips appeared.
  - Both are with the GCP team.

## Browser behaviour

- **On demand:** Apex only runs when the user clicks Generate.
- **Cache:** the result is kept in the browser's local storage, per user and per account. It lasts 1 hour, within a 512 KB total. When space runs out, the oldest summaries are removed first. Refresh skips the cache.
- **Usage logging:** opening the summary logs one view event through `GCPCalloutForOpportunitySummary.logAIHEvent`.
- **Errors:** the user only sees label-based messages for rate limits (429), service unavailable (422) and any other failure. Technical details go to `PlatformLog`.

## Known limitations at a glance

1. **No maths in Salesforce.** Any number on screen is only as good as GCP's rules and the records it was sent.
2. **Limits can hide records.** Lists over their limit are cut, with `isTruncated` set. The tightest limits are the 15 closed opportunities, 15 recently closed cases, 20 tasks, 10 case tasks and 10 events.
3. **Automated senders are matched by display name.** If someone renames one of those users, their tasks come back. A new automation user needs a code change.
4. **Event owner isn't sent.** An event's owner can be a Calendar, which the query framework can't read, so events send the creator.
5. **Archived activities are left out.** Salesforce archives activities older than 365 days, and the queries don't include them.
6. **Child accounts are not included.** A parent account's summary ignores activity, cases and opportunities on its child accounts.
7. **Data quality in production:**
   - NextStep is almost never filled.
   - Some cases have been open since 2011.
   - CSM is filled on 18% of active customers.
   - "In use" licenses count every extension.
8. **Contract dates:** Apex sends the standard `Contract.EndDate`. The org also has a custom `End_Date__c` that its contract batch uses, which may be more reliable.
9. **Payload size:** Apex stops at 2 MB and shows the server error. A very large account could reach this.
10. **Resolved Red Account records usually lack an end date** (10,117 of 10,622 in DevGss).
11. **DevGss data is thin.** Most DevGss accounts lack MRR, licenses and tier. Bank of America Corporation and Miles Ahead Brands, LLC have been filled with test data for demos.
12. **DevGss automation bug:** closing an opportunity at stage "7.1. Closed Won for ProServ" fails, because the stage name is longer than `Account.Most_Recent_Opportunity_Stage__c` allows (25 characters).

## Related documents

- `docs/account-summary-components.csv`: every Salesforce component created or changed, with deploy IDs.
- Label-to-field mapping (HTML, pasted into Google Docs): `~/Downloads/Account Summary - labels and Salesforce sources.html`.
