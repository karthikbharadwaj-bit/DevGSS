# PBC-33890 — Porting Phone Survey Recipient (Qualtrics) — Analysis

| Item            | Value                                                                                        |
| --------------- | -------------------------------------------------------------------------------------------- |
| Analysis task   | [PBC-33890](https://jira.ringcentral.com/browse/PBC-33890)                                   |
| Epic            | [PBC-33889](https://jira.ringcentral.com/browse/PBC-33889)                                   |
| Initiative      | [LTR-3869](https://jira.ringcentral.com/browse/LTR-3869)                                     |
| BRD author      | Arty Ramos (8/3/2026)                                                                        |
| Analyst         | Karthik Bharadwaj                                                                            |
| Sources checked | DevGSS repo, DevGss org (read-only Tooling API), SF Master `master` @ `c81bb25` (2026-10-21) |

## Summary

The rule the business is asking for already exists in production, in a narrower form. Porting Phone cases with no Contact already send the Web Email (`SuppliedEmail`) to Qualtrics, but only when the case has `Origin = Email` **and** an inbound email whose `ToAddress` is exactly `ntd.helpdesk@ringcentral.com`. The open question is whether those extra conditions are intended, and whether Qualtrics uses `SuppliedEmail` as the survey recipient.

## 1. The request (BRD and story)

The BRD and the Jira story contain the same text.

**Current process described by the business:**

1. A customer or IT person emails the NTD helpdesk to follow up on a porting request.
2. Email-to-Case creates a Support case with the Porting Phone record type.
3. If the sender's email belongs to a Contact on the Account, the case is saved under that Contact Name.
4. If not, the sender's email is stored in the Web Email field.

**Additional logic requested:**

> If the "Contact Name" is "blank" or "no account", a survey should be sent to the email address on the "Web Email" field.

**What the BRD does not cover:**

- No other conditions (origin, inbound address, brand).
- No definition of "no account".
- No example cases, acceptance criteria or mock-up (Annex A is referenced but empty).
- Sign-off contains only the author.

## 2. Current implementation

### Flow: `Qualtrics_Surveys_triggered_from_Case`

Record-triggered after-save flow on Case. It starts when `Support_Case__c = true` and Status changes to Closed, Duplicate, Closed - No Response or Cancelled.

**Branch A: case has a Contact email.** Applies to brands other than TELUS Business Connect, AT&T Office@Hand, RingCentral Office@Hand from AT&T, Avaya Cloud Office, Biz Dummy and Unify Office. If the record type is `Porting_Phone` and the brand is not BT, the flow sends the outbound message `Qualtrics_Porting_HelpDesk_Support`.

**Branch B: case has no Contact email.** All of these must be true:

| Condition           | Value             |
| ------------------- | ----------------- |
| `ContactEmail`      | is null           |
| `SuppliedEmail`     | is not null       |
| `Origin`            | = `Email`         |
| `RecordTypeName__c` | = `Porting_Phone` |

The flow then looks up an `EmailMessage` where `ParentId` is the case and `ToAddress` equals `$Label.Porting_Phone_Helpdesk_Email`. It sends `Qualtrics_Porting_HelpDesk_Support` only if it finds one. Branch B applies no brand exclusions and no BT check.

### Outbound messages (from `src/workflows/Case.workflow` in SF Master, confirmed in DevGss)

| Outbound message                           | Fields sent           | Used by                                                    |
| ------------------------------------------ | --------------------- | ---------------------------------------------------------- |
| `Qualtrics_Porting_HelpDesk_Support`       | `Id`, `SuppliedEmail` | Both Porting branches                                      |
| `Qualtrics Support Survey - Porting Phone` | `Id`, `SuppliedEmail` | Not referenced by the flow; different Qualtrics trigger ID |
| `Qualtrics_Support_Survey`                 | `Id`                  | Technical Support                                          |
| `Qualtrics_CLF_Support_Porting_Phone`      | `Id`                  | Close-loop feedback flow                                   |

Salesforce does not choose the survey recipient. It sends `Id` and `SuppliedEmail`, and the Qualtrics workflow decides who receives the survey.

### Custom label

`Porting_Phone_Helpdesk_Email` = `ntd.helpdesk@ringcentral.com` (same in DevGss and SF Master).

### Related automation

- **`Send_Closeloop_Feedback_Case_Details_to_Qualtrics`** has a matching Porting branch: parent `Origin = Email`, parent `Original_RecordType__c = Porting_Phone`, parent `SuppliedEmail` not null, parent `ContactEmail` null. It does not perform the helpdesk `EmailMessage` lookup.
- **`MedalliaSurveyHelper.supportSurveyForOrphanCases`** (legacy Medallia) used the same exact-match `ToAddress` rule. The Qualtrics flow carried it over.
- **`CaseTriggerHandler.CreateSurveysForSupportCSATRTCases`** creates internal `Survey__c` records and requires an Account brand, so no-Account cases never get one. This is out of scope for a Qualtrics story.

### History in SF Master

| Commit    | Date       | Author              | Change                                                  |
| --------- | ---------- | ------------------- | ------------------------------------------------------- |
| `bf4ea5f` | 2025-01-31 | Anjana Ravikumar    | PBC-25604: first Qualtrics support survey               |
| `df003d3` | 2025-02-24 | Anjana Ravikumar    | PBC-25604: removed Porting Phone E2C logic              |
| `40b8a97` | 2025-05-15 | Anjana Ravikumar    | Re-added Porting Phone E2C logic (no ticket in message) |
| `343a6f3` | 2025-08-19 | Anjana Ravikumar    | PBC-28131: endpoint URL per survey category             |
| `92b15ff` | 2026-02-26 | Anjana Ravikumar    | PBC-30269: RC Events survey endpoint                    |
| `67b9907` | 2026-07-10 | Saimouni Kethireddi | PBC-31680: RC Events survey brand logic                 |

The DevGSS copy of the flow matches master for all Porting logic. The only differences are the RC Events branch and layout coordinates. No branch or commit references PBC-33890, PBC-33889 or LTR-3869.

### Data

DevGss has no cases with the `Porting - Phone Case` record type and no `EmailMessage` records sent to `ntd.helpdesk@ringcentral.com`. Real behavior cannot be validated in this org.

## 3. Gaps

1. **The flow is stricter than the BRD.** The BRD's only condition is a blank Contact. The flow also requires `Origin = Email` and an `EmailMessage` whose `ToAddress` exactly equals the helpdesk address. A no-Contact case gets no survey if:
   - it came from another origin, or
   - the helpdesk was CC'd, the email was forwarded or sent from an alias, or the To field held more than one address.

   This is the most likely real-world gap.

2. **"No account" is undefined.** The flow only checks `ContactEmail`. If "no account" means a placeholder Contact or Account that has an email, those cases go through Branch A.
3. **Qualtrics picks the recipient.** Salesforce sends both `Id` and `SuppliedEmail`. If the Qualtrics workflow addresses the survey to a Contact it looks up from `Id`, no Salesforce change will fix it.
4. **Brand rules aren't applied to no-Contact cases.** Branch A excludes several brands and BT; Branch B excludes none. No-Contact cases usually have no Account, so brand is blank. The business hasn't confirmed this is acceptable.
5. **Two Porting outbound messages exist.** `Qualtrics Support Survey - Porting Phone` has the same fields but a different Qualtrics trigger and is unused. Confirm which Qualtrics survey is correct.
6. **Intent and evidence are missing.**
   - The E2C logic was removed and re-added in 2025 without a recorded reason.
   - No example cases show a wrong recipient or a missing survey.
   - There's no test data in DevGss.

## 4. Open questions

| #   | Question                                                                                                               | Owner                  |
| --- | ---------------------------------------------------------------------------------------------------------------------- | ---------------------- |
| 1   | Should the rule apply to every Porting Phone case with no Contact, or only to cases emailed to the NTD helpdesk?       | Arty Ramos / Amlan Das |
| 2   | What exactly does "no account" mean (blank Contact, blank Account, placeholder record)?                                | Arty Ramos             |
| 3   | Can you share 2–3 case numbers where the survey went to the wrong person or was not sent?                              | Arty Ramos             |
| 4   | Which payload field does the Qualtrics workflow use as the survey recipient?                                           | Qualtrics admin        |
| 5   | Which Qualtrics survey is correct: `Qualtrics_Porting_HelpDesk_Support` or `Qualtrics Support Survey - Porting Phone`? | Qualtrics admin        |
| 6   | Why was the Porting E2C logic removed and re-added in 2025 (PBC-25604)?                                                | Anjana Ravikumar       |
| 7   | Should no-Contact cases follow the same brand exclusions as other Porting cases?                                       | Arty Ramos             |

## 5. Recommended next steps

1. **Get answers to the open questions**, especially 1, 3 and 4. They decide whether this is a Salesforce change, a Qualtrics change, or no change at all.
2. **Measure the gap in a production-like org.** Pull recently closed Porting cases with no Contact and group them by why they were skipped:

   ```sql
   SELECT Id, CaseNumber, Origin, SuppliedEmail, ContactId, AccountId, Status, ClosedDate
   FROM Case
   WHERE RecordType.DeveloperName = 'Porting_Phone'
     AND ContactId = null
     AND ClosedDate = LAST_N_DAYS:90
   ```

   For each case, check `EmailMessage.ToAddress` and `CcAddress` against `ntd.helpdesk@ringcentral.com`.

3. **If a Salesforce change is needed**, update `Qualtrics_Surveys_triggered_from_Case`. Options:
   - Match the helpdesk address with "contains" on `ToAddress` (and possibly `CcAddress`) instead of exact equality. Confirm the field accepts that filter in Get Records.
   - Or remove the `EmailMessage` lookup and the `Origin = Email` condition, so the rule depends only on the record type, a blank Contact and `SuppliedEmail`.
   - Extend the Branch B condition to cover the agreed meaning of "no account".
4. **Keep `Send_Closeloop_Feedback_Case_Details_to_Qualtrics` consistent** with any change to the eligibility rules.

## 6. Effort and risks

**Effort:** about 2–3 days for a flow-only change, including sandbox and Qualtrics end-to-end testing, plus any Qualtrics-side configuration. No Apex change is expected.

**Risks:**

- Loosening the conditions may send surveys to people who emailed the helpdesk only incidentally.
- A case could match both branches and trigger duplicate surveys.
- The work is blocked until the business clarifies scope and Qualtrics confirms the recipient mapping.
