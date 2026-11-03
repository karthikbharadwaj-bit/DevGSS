# PBC-33890 — Porting Phone Survey Recipient (Qualtrics) — Analysis

| Item            | Value                                                                                                                                                               |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Analysis task   | [PBC-33890](https://jira.ringcentral.com/browse/PBC-33890)                                                                                                          |
| Epic            | [PBC-33889](https://jira.ringcentral.com/browse/PBC-33889)                                                                                                          |
| Initiative      | [LTR-3869](https://jira.ringcentral.com/browse/LTR-3869)                                                                                                            |
| Prior work      | [LTR-1160](https://jira.ringcentral.com/browse/LTR-1160) (2023–2024, Medallia), [PBC-26213](https://jira.ringcentral.com/browse/PBC-26213) (2025, Qualtrics)        |
| BRD author      | Arty Ramos (8/3/2026)                                                                                                                                               |
| Analyst         | Karthik Bharadwaj                                                                                                                                                   |
| Sources checked | DevGSS repo; SF Master `master` @ `c81bb25` (2026-10-21) and its git history; Jira history; DevGss and BisUAT orgs (read-only queries). Production was not queried. |

## Summary

This is the third time this requirement has been built.

| When             | Ticket                                        | Survey vendor | What happened                                                                                                                                                                                            |
| ---------------- | --------------------------------------------- | ------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Jun 2024         | LTR-1160 / PBC-17692 / PBC-21069              | Medallia      | Went live 20 Jun 2024. Smoke testing found Medallia discarding the invitations. LTR-1160 was closed on 27 Jun as "smoke testing sign-off received" while Medallia's fix was still listed as in progress. |
| Feb–May 2025     | PBC-25604, then PBC-26213 / PBC-26714         | Qualtrics     | The orphan-case logic was removed before the Qualtrics go-live and re-added in production on 15 May 2025. Production checks only confirmed the configuration existed; no end-to-end test was run.        |
| Aug 2025 – today | PBC-28131                                     | Qualtrics     | Each survey type got its own Qualtrics trigger. Porting cases now use `Qualtrics_Porting_HelpDesk_Support`.                                                                                              |
| 2026             | LTR-3869 / PBC-33889 / PBC-33890 (this story) | Qualtrics     | Same BRD text as LTR-1160, re-raised for Qualtrics.                                                                                                                                                      |

In BisUAT, the current setup works end to end. Orphan Porting cases (no Contact) get a Qualtrics survey record, and their survey responses come from the case's Web Email. The Salesforce rule therefore matches the BRD's intent for cases created by email to `ntd.helpdesk@ringcentral.com`.

The reasons it may "never have worked properly" in production are therefore most likely:

- **Before May 2025:** there was no working path. Medallia discarded the invitations, and the logic was missing from the Qualtrics flow from the go-live until 15 May 2025.
- **May–Aug 2025:** orphan cases went to the generic support survey trigger.
- **Throughout:** Qualtrics discards a much larger share of orphan surveys than of Contact surveys. The cause sits on the Qualtrics side.
- **Edge cases:** some no-Contact cases fall outside the flow's gates or the sharing rule.

The most useful next step is to run the production queries in section 5. They will show whether orphan Porting cases in production get a `Qualtrics_Survey__c` record, what status it gets, and whether a `Response__c` comes back.

## 1. The request (BRD and story)

The BRD, LTR-3869 and the 2023 LTR-1160 all contain the same text.

**Current process described by the business:**

1. A customer or IT person emails the NTD helpdesk to follow up on a porting request.
2. Email-to-case creates a Support case with the Porting Phone record type.
3. If the sender's email belongs to a Contact on the Account, the case is saved under that Contact Name.
4. If not, the sender's email is stored in the Web Email field.

**Additional logic requested:**

> If the "Contact Name" is "blank" or "no account", a survey should be sent to the email address on the "Web Email" field.

**What the BRD does not cover:**

- No other conditions (origin, inbound address, brand).
- No definition of "no account".
- No example cases, acceptance criteria or mock-up (Annex A is referenced but empty).
- Sign-off contains only the author.

**The 2024 requirement was more specific.** PBC-21069 defined these trigger criteria, and today's flow implements all of them:

1. Status changed to Closed, Closed - No Response, Cancelled or Duplicate.
2. `Support_Case__c` = true.
3. `ContactEmail` is null.
4. `SuppliedEmail` is not null.
5. `Origin` = Email.
6. Record type = Porting - Phone.
7. Created through email-to-case for `ntd.helpdesk@ringcentral.com`.

It also listed the orphan scenarios: the sender's email isn't on any Contact, or it's on two Contacts so email-to-case can't pick one.

## 2. Current implementation

### Flow: `Qualtrics_Surveys_triggered_from_Case`

This is a record-triggered after-save flow on Case. It starts when `Support_Case__c = true` and Status changes to Closed, Duplicate, Closed - No Response or Cancelled.

The entry gates were checked against org metadata:

- `Support_Case__c` is a formula that includes `RecordType.Name = 'Porting - Phone'`.
- `RecordTypeName__c` is a formula returning `RecordType.DeveloperName`, which is `Porting_Phone`. This field is not in source control; it was read from the org.

**Branch A: case has a Contact email.** Applies to brands other than TELUS Business Connect, AT&T Office@Hand, RingCentral Office@Hand from AT&T, Avaya Cloud Office, Biz Dummy and Unify Office. If the record type is `Porting_Phone` and the brand is not BT, the flow sends the outbound message `Qualtrics_Porting_HelpDesk_Support`.

**Branch B: case has no Contact email.** All of these must be true:

| Condition           | Value             |
| ------------------- | ----------------- |
| `ContactEmail`      | is null           |
| `SuppliedEmail`     | is not null       |
| `Origin`            | = `Email`         |
| `RecordTypeName__c` | = `Porting_Phone` |

The flow then looks up an `EmailMessage` where `ParentId` is the case and `ToAddress` equals `$Label.Porting_Phone_Helpdesk_Email`. It sends `Qualtrics_Porting_HelpDesk_Support` only if it finds one. Branch B applies no brand exclusions and no BT check.

### What the payload contains and who picks the recipient

| Outbound message (master)             | Fields sent           | Used by                  |
| ------------------------------------- | --------------------- | ------------------------ |
| `Qualtrics_Porting_HelpDesk_Support`  | `Id`, `SuppliedEmail` | Both Porting branches    |
| `Qualtrics_Support_Survey`            | `Id`                  | Technical Support        |
| `Qualtrics_CLF_Support_Porting_Phone` | `Id`                  | Close-loop feedback flow |

- **Where the Web Email comes from.** `SuppliedEmail` (label "Web Email") is set by standard email-to-case to the sender's From address when the case is created. No Apex, flow or workflow field update overwrites it for Porting cases.
- **Qualtrics reads the case itself.** In BisUAT, Qualtrics fills `Qualtrics_Survey__c.Contact__c` for Contact cases even though the payload has no Contact field. For orphan cases, the responses come from the Web Email. So Qualtrics calls back into Salesforce as the integration user using the case `Id`. It needs read access to the case, but doesn't depend only on the payload fields.

### Record access for Qualtrics

Qualtrics reads cases as `qualtrics_survey.integration@ringcentral.com`. In BisUAT this user has:

- the "No Access" profile and no role;
- no View All Data and no View All on Case (permission sets `Qualtrics_Surveys`, `Customize_Application`, `Manage_Users`).

Case, Account and Contact are all Private, so the user can read a case only through sharing. There are two routes.

**Route 1: cases without an Account.** PBC-26213 (Mar 2025) added the criteria-based rule `Qualtrics_Integration_User_cases_Access`. It gives the `Qualtrics_Integration_User` group read access when either:

- the record type is Porting - Phone **and** `AccountId` is blank, or
- the record type is Close Loop Feedback Qualtrics SupportSurvey.

**Route 2: cases with an Account.** Access comes from the case's Account. The user is a member of `Non_Telus_Users` (label "Non GSP"), `BT_Users` and `Qualtrics_Integration_User`. `AccountTriggerHandler` (Status Based Access Controls) gives each Account a manual `AccountShare` with Case access Edit, to exactly one group:

| Account                                                     | Group the Account is shared to                                                                             | Qualtrics can read its cases? |
| ----------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- | ----------------------------- |
| RingCentral brands (Paid, or Canceled/Free within 30 days)  | `Non_Telus_Users`                                                                                          | Yes                           |
| BT                                                          | `BT_Users`                                                                                                 | Yes                           |
| Canceled more than 30 days ago                              | `Canceled_Accounts_Group`                                                                                  | **No**                        |
| Free, created more than 30 days ago                         | `Free_Accounts_Group`                                                                                      | **No**                        |
| Partner brands and sub-brands in `AccessControlSettings__c` | Brand group (Avaya, Brightspeed, Cox, Optus, Rise America/International, Zayo, AllNet, EDV, Salt, TTBS, …) | **No**                        |

The Canceled and Free routing is new. It came from "Status Based Access Controls - Revamp" (PBC-32803, Aug–Sep 2026):

- `AccountTriggerHandler` sends Canceled Accounts past 30 days to `Canceled_Accounts_Group` and Free Accounts past 30 days to `Free_Accounts_Group`.
- `AccountStatusSharingBatch`, scheduled daily (it's in BisUAT as "Account Status Sharing Batch"), moves existing `Non_Telus_Users` shares to those groups.

The Qualtrics integration user is in neither group.

**Measured in BisUAT** (`UserRecordAccess` for the integration user against all 211 closed Porting Phone cases):

| Case type                       | Readable | Not readable                                                |
| ------------------------------- | -------- | ----------------------------------------------------------- |
| No Contact, no Account (orphan) | 99       | 0                                                           |
| No Contact, with Account        | 1        | 0                                                           |
| Contact and Account             | 107      | 4 (AT&T and TELUS test accounts, 1 Vodafone; all from 2024) |

The one case with no Contact but an Account is readable through Route 2 (a "RingCentral UK" Account shared to `Non_Telus_Users`), and it is a Phone case with no Web Email anyway. All Porting Accounts in BisUAT are Paid, so the Canceled and Free routing can't be observed there.

### Related automation

- **`Send_Closeloop_Feedback_Case_Details_to_Qualtrics`** has a matching Porting branch: parent `Origin = Email`, parent `Original_RecordType__c = Porting_Phone`, parent `SuppliedEmail` not null, parent `ContactEmail` null. It does not do the helpdesk `EmailMessage` lookup.
- **`Send_Medallia_Invitation_triggered_from_Case`** (Process Builder) is still `Active` in master. It still calls `MedalliaSurveyHelper.supportSurveyForOrphanCases`, the 2024 Medallia version of this logic.
- **`CaseTriggerHandler.CreateSurveysForSupportCSATRTCases`** creates internal `Survey__c` records and requires an Account brand, so no-Account cases never get one. This is out of scope for a Qualtrics story.

## 3. History

### Jira

| Ticket                                                     | Dates             | Summary                                                                                                                                                                                                                                                               |
| ---------------------------------------------------------- | ----------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [LTR-1160](https://jira.ringcentral.com/browse/LTR-1160)   | 2023-09 → 2024-06 | Original initiative, same BRD text. Nov 2023: Salesforce can't choose the recipient, so the vendor must change their logic. Jun 2024: production smoke test found Medallia discarding invitations because of filters on case tagging tool fields. Closed 27 Jun 2024. |
| [PBC-17692](https://jira.ringcentral.com/browse/PBC-17692) | 2023-10 → 2024-08 | Epic. Added Web Email to the Medallia payload.                                                                                                                                                                                                                        |
| [PBC-21069](https://jira.ringcentral.com/browse/PBC-21069) | 2024-04 → 2024-05 | Defined the seven trigger criteria listed in section 1.                                                                                                                                                                                                               |
| [PBC-20844](https://jira.ringcentral.com/browse/PBC-20844) | 2024-06           | Production deployment (Medallia).                                                                                                                                                                                                                                     |
| [PBC-25604](https://jira.ringcentral.com/browse/PBC-25604) | 2025-02 → 2025-03 | Qualtrics support survey production deployment. The Porting smoke test covered only cases with a Contact, because the orphan logic had been removed (`df003d3`).                                                                                                      |
| [PBC-26213](https://jira.ringcentral.com/browse/PBC-26213) | 2025-03           | Qualtrics orphan Porting survey. Found the integration user had no access to orphan cases and added the sharing rule.                                                                                                                                                 |
| [PBC-26394](https://jira.ringcentral.com/browse/PBC-26394) | 2025-04           | BISUAT testing. Delayed by Qualtrics workflow problems and a wrong endpoint.                                                                                                                                                                                          |
| [PBC-26714](https://jira.ringcentral.com/browse/PBC-26714) | 2025-05           | Production deployment, 15 May 2025. Qualtrics was having production problems at the time. Checks covered only the outbound messages and sharing rules ("we cannot create or update any records in Production").                                                       |
| [PBC-28131](https://jira.ringcentral.com/browse/PBC-28131) | 2025-08 → 2025-10 | A separate endpoint for each support survey category. Introduced `Qualtrics_Porting_HelpDesk_Support`.                                                                                                                                                                |

### SF Master commits

| Commit    | Date       | Change                                                                                                                                                                                                                  |
| --------- | ---------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `42ddb59` | 2024-05-31 | PBC-20842: Medallia version (`supportSurveyForOrphanCases` and a Process Builder rule).                                                                                                                                 |
| `bf4ea5f` | 2025-01-31 | PBC-25604: first Qualtrics support survey flow.                                                                                                                                                                         |
| `df003d3` | 2025-02-24 | Removed the Porting orphan logic before the Qualtrics go-live.                                                                                                                                                          |
| `40b8a97` | 2025-05-15 | Re-added the orphan logic, but both branches fired the generic `Qualtrics_Support_Survey` (payload `Id` only).                                                                                                          |
| `e8fd2d1` | 2025-05-07 | LTR-2391: updated the endpoint of `Qualtrics_Support_Survey_Porting_Phone` (`Id`, `SuppliedEmail`). The flow never used this message.                                                                                   |
| `343a6f3` | 2025-08-19 | PBC-28131: Porting branches switched to the new `Qualtrics_Porting_HelpDesk_Support`. `Qualtrics_Support_Survey_Porting_Phone` was deleted from source but still exists in DevGss (no destructive change was deployed). |

## 4. Evidence from BisUAT

These are read-only queries. BisUAT had 283 Porting Phone cases, the latest created on 2026-10-25. All the orphan surveys used RingCentral test addresses, so this is QA traffic, not customer traffic.

| Check                                                                                  | Result                                                                           |
| -------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| Closed Porting cases with no Contact, by origin                                        | Email 98, NTD Sales 1, Phone 1                                                   |
| Orphan email cases whose inbound email `ToAddress` exactly equals the helpdesk address | 98 of 98 (none had the helpdesk only in CC)                                      |
| Closed Porting cases with no Contact but with an Account                               | 1                                                                                |
| Closed Porting cases with a Contact but no Web Email                                   | 101 of 111 (Phone 96, Walk In 3, Email 1, Web 1)                                 |
| `Qualtrics_Survey__c` for orphan cases                                                 | 62 Received, 24 Discarded (28%)                                                  |
| `Qualtrics_Survey__c` for Contact cases                                                | 81 Received, 4 Discarded (5%)                                                    |
| Orphan discards by month                                                               | Apr 2025: 14 of 35; Mar 2026: 10 of 12                                           |
| `Response__c` from orphan cases                                                        | 33, all with the respondent email equal to the case's Web Email                  |
| Survey name on orphan records                                                          | "Support Survey" (Apr–Jul 2025), then "Porting Support Survey" (Sep 2025 onward) |

What this tells us:

- **The chain works when nothing is discarded.** Salesforce sends, Qualtrics reads the case, the survey goes to the Web Email and the response syncs back.
- **Cases with a Contact don't need a Web Email.** Qualtrics resolves the Contact itself, so the 101 Contact cases without a Web Email still got surveys.
- **The exact `ToAddress` match didn't block anything here.** Production email traffic (CC'd, forwarded, several recipients) may still differ.
- **Qualtrics discards orphan surveys far more often than Contact surveys.** `Qualtrics_Survey__c` has no reason field, so Salesforce can't tell why.

## 5. Gaps

1. **Qualtrics discards orphan surveys at a much higher rate (28% vs 5% in BisUAT).** This matches the 2024 Medallia failure, where vendor-side filters discarded orphan invitations. Possible causes include contact-frequency or deduplication rules on the recipient email, or filters on fields that orphan cases don't have (Account, Contact, brand, case tagging fields). This is the most likely production cause and needs the Qualtrics admin.
2. **Production has never been verified end to end.** The 2025 production deployment checked only configuration. No ticket shows an orphan survey being received in production since the Aug 2025 endpoint change.
3. **Historical gaps in production.**
   - Jun 2024 – Feb 2025: Medallia discarded invitations, and it isn't confirmed that this was ever fixed.
   - Mar – 15 May 2025: the orphan logic was not in the flow.
   - May – Aug 2025: orphan cases went to the generic support survey trigger rather than a Porting-specific one.
4. **Qualtrics can't read Porting cases on Canceled, Free or partner-brand Accounts.** The Qualtrics sharing rule only covers cases with a blank Account. Every other case relies on Account sharing to `Non_Telus_Users` or `BT_Users`, and the integration user can't read:
   - cases on Accounts Canceled more than 30 days ago (`Canceled_Accounts_Group`);
   - cases on Free Accounts created more than 30 days ago (`Free_Accounts_Group`);
   - cases on partner-brand Accounts mapped in `AccessControlSettings__c` (Brightspeed, Cox, Optus, Rise, Zayo and others). The survey flow doesn't exclude these brands.

   The flow still sends the outbound message, but Qualtrics can't read the case, so the survey can't be built.

   The Canceled and Free part came in with PBC-32803 (Aug–Sep 2026), so it doesn't explain the history. It is a new regression risk, and Porting cases, especially port-outs, are often on cancelled Accounts.

   The original concern (no Contact but with an Account) is a subset of this. For a Paid RingCentral or BT Account the case is readable. For a Canceled, Free or partner-brand Account it isn't. This could not be measured in BisUAT, where all Porting Accounts are Paid.

5. **The flow's gates are narrower than the BRD.** It requires `Origin = Email` and an inbound `ToAddress` exactly equal to the helpdesk address. This was the agreed 2024 design (PBC-21069), but the 2026 BRD doesn't mention it. No-Contact cases from other origins, or emails where the helpdesk was CC'd, forwarded or one of several recipients, get no survey. This was not seen in BisUAT, but it's unverified in production.
6. **"No account" is undefined.** The flow only checks `ContactEmail`. A placeholder Contact or Account that has an email takes Branch A instead.
7. **Brand rules aren't applied to no-Contact cases.** Branch A excludes several brands and BT; Branch B excludes none.
8. **Leftover metadata.**
   - The Medallia Process Builder (`Send_Medallia_Invitation_triggered_from_Case`) is still active and still calls `supportSurveyForOrphanCases`.
   - `Qualtrics_Support_Survey_Porting_Phone` was removed from source but not deleted from the orgs.

   Both should be confirmed as harmless or cleaned up.

9. **A sharing rule uses a hardcoded user ID.** `Qualtrics_Integration_User_Access` matches on `CreatedById = 005Ot00000CZz4vIAD`. That ID exists in neither DevGss nor BisUAT, so the rule does nothing in sandboxes. It probably points to the production integration user. It affects only records created by the integration user, so it isn't a direct cause, but it makes sandbox testing differ from production.

## 6. Open questions

| #   | Question                                                                                                                                                                                                                                                           | Owner                                                                                 |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------- |
| 1   | What exactly "never worked": no survey sent, survey sent to the wrong person, or responses not syncing? Please share 2–3 production case numbers.                                                                                                                  | Arty Ramos                                                                            |
| 2   | Why does Qualtrics discard orphan Porting surveys (frequency, dedupe or field filters)? What are the discard reasons for the production records?                                                                                                                   | Qualtrics admin                                                                       |
| 3   | Which field does the `Qualtrics_Porting_HelpDesk_Support` workflow (trigger `OC_sG8MKIVX0X1sI8q`) use as the recipient, and is it the same in production?                                                                                                          | Qualtrics admin                                                                       |
| 4   | Should the rule apply to every Porting Phone case with no Contact, or only to cases emailed to the NTD helpdesk (the 2024 design)?                                                                                                                                 | Arty Ramos / Amlan Das                                                                |
| 5   | What exactly does "no account" mean (blank Contact, blank Account, placeholder record)?                                                                                                                                                                            | Arty Ramos                                                                            |
| 6   | Was the 2024 Medallia filter fix ever confirmed? Can the Medallia Process Builder be deactivated?                                                                                                                                                                  | Ranjani Narayanan / Rini Rathnaraj                                                    |
| 7   | Should no-Contact cases follow the same brand exclusions as other Porting cases?                                                                                                                                                                                   | Arty Ramos                                                                            |
| 8   | Should Porting cases on Canceled, Free and partner-brand Accounts get a survey? If yes, how should Qualtrics get read access: add the integration user to `Canceled_Accounts_Group` and `Free_Accounts_Group`, or widen `Qualtrics_Integration_User_cases_Access`? | Arty Ramos / PBC-32803 owners (Yuvaana Sundarakrishnan, Jerslin Alexander) / Security |

## 7. Recommended next steps

1. **Run read-only queries in production** (or a fresh full-copy sandbox) to see what actually happens to orphan cases:

   ```sql
   -- Closed orphan Porting cases in the last 180 days
   SELECT Id, CaseNumber, Origin, SuppliedEmail, AccountId, ClosedDate
   FROM Case
   WHERE RecordType.DeveloperName = 'Porting_Phone'
     AND ContactId = null
     AND IsClosed = true
     AND ClosedDate = LAST_N_DAYS:180

   -- Did Qualtrics receive them, and with what status?
   SELECT Status__c, Survey_Name__c, COUNT(Id)
   FROM Qualtrics_Survey__c
   WHERE Case__r.RecordType.DeveloperName = 'Porting_Phone'
     AND Case__r.ContactId = null
     AND CreatedDate = LAST_N_DAYS:180
   GROUP BY Status__c, Survey_Name__c

   -- Did anyone respond?
   SELECT COUNT(Id)
   FROM Response__c
   WHERE Case_Number__r.RecordType.DeveloperName = 'Porting_Phone'
     AND Case_Number__r.ContactId = null
     AND CreatedDate = LAST_N_DAYS:180
   ```

   Compare orphan cases with no `Qualtrics_Survey__c` against the flow gates: `Origin`, `ToAddress` and `CcAddress` on the inbound `EmailMessage`, and `AccountId` (for the sharing rule).

   Also measure gap 4. Find Porting cases on Accounts that Qualtrics can't read, then check the integration user's access to them:

   ```sql
   SELECT Account.RC_Account_Status__c, Account.RC_Brand__c, COUNT(Id)
   FROM Case
   WHERE RecordType.DeveloperName = 'Porting_Phone'
     AND IsClosed = true
     AND ClosedDate = LAST_N_DAYS:180
     AND AccountId != null
   GROUP BY Account.RC_Account_Status__c, Account.RC_Brand__c

   -- For a sample of those case Ids
   SELECT RecordId, HasReadAccess
   FROM UserRecordAccess
   WHERE UserId = '<production qualtrics_survey.integration user Id>'
     AND RecordId IN (...)
   ```

2. **Read the results this way:**
   - Orphan cases closed with no `Qualtrics_Survey__c`: the Salesforce gates or sharing are the problem (gaps 4 and 5). Fix it in the flow and the sharing rule.
   - `Qualtrics_Survey__c` mostly `Discarded`: the problem is on the Qualtrics side (gap 1). It needs a Qualtrics configuration change, not a Salesforce change.
   - `Received` but no responses and no complaints of delivery: confirm delivery in Qualtrics' distribution logs.
3. **Possible Salesforce changes**, depending on the answers above:
   - Give Qualtrics read access to Porting cases on Canceled, Free and partner-brand Accounts. One option is to change `Qualtrics_Integration_User_cases_Access` from "Porting - Phone and blank Account" to "Porting - Phone". Another is to add the integration user to `Canceled_Accounts_Group` and `Free_Accounts_Group`. That second option also exposes their Opportunities and Contacts, so the case-level rule is the narrower choice.
   - Loosen or remove the `Origin = Email` condition and the exact `ToAddress` lookup if the business wants every no-Contact Porting case covered.
   - Keep `Send_Closeloop_Feedback_Case_Details_to_Qualtrics` consistent with any eligibility change.
   - Deactivate the Medallia Process Builder rule and remove `Qualtrics_Support_Survey_Porting_Phone` from the orgs.
4. **Make production smoke tests end to end:** close a real orphan Porting test case in production and confirm the `Qualtrics_Survey__c` record, the email delivery and the `Response__c` sync.

## 8. Effort and risks

**Effort:**

- Production data analysis: about half a day.
- Salesforce changes (flow condition, sharing rule, cleanup): about 2–3 days including sandbox and Qualtrics end-to-end testing. No Apex change is expected.
- Qualtrics-side changes: owned and estimated by the Qualtrics admin.

**Risks:**

- If the real cause is Qualtrics discards, Salesforce changes alone won't fix it. That is what happened with LTR-1160 in 2024.
- Loosening the conditions may send surveys to people who emailed the helpdesk only incidentally.
- Widening the sharing rule gives the Qualtrics integration user read access to more cases. Security should sign off on that.
- A case could match more than one branch or automation (Qualtrics flow plus the active Medallia Process Builder) and trigger duplicate surveys.
