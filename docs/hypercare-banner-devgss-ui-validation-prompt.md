# Claude for Chrome prompt — DevGSS Case Highlighter UI validation

Copy everything under **Prompt to paste** into Claude for Chrome.

## Prompt to paste

You are validating the existing Salesforce Case Highlighter in the **DevGSS sandbox** using an already authenticated administrator session.

During Salesforce validation, work only on this host:

`https://rc--devgss1.sandbox.my.salesforce.com`

The Salesforce portion is a read-only evidence-gathering run. Do not create, edit, save, submit, delete, close, merge, clone, reassign, or escalate any Salesforce record. Do not change Setup, metadata, users, apps, layouts, Accounts, or Cases. You may navigate, switch apps, use Salesforce **Login As**, inspect pages, and take screenshots.

After completing the Salesforce checks, you are authorized to open `https://docs.google.com` using the user's existing logged-in Google session and create one Google Doc containing the results. Do not request credentials, sign into another account, share the document, change its permissions, email it, or modify any other Google Drive file.

## Objective and important limitation

For each test, determine whether the existing `CaseHighlighterPage` surface is rendered in the specified user/profile/app/Case context.

DevGSS currently has **zero Accounts with `Hyper_Care__c = true`**, and the current implementation does not yet contain the proposed Hypercare condition. Therefore:

- Do not claim that the exact new Hypercare message was tested.
- Use the existing escalated or AT&T/BT brand message as the visual control that proves whether the Case Highlighter is present.
- If a supplied Case has no existing trigger, mark the highlighter result **Inconclusive** unless browser inspection can positively identify the `CaseHighlighterPage` iframe/component.
- Do not modify data to manufacture a trigger.

Recognize these existing control messages:

- Escalated Case: `Please handle with care. This case has been escalated.`
- AT&T brand Case: text matching `This is a AT&T Case, please handle with care.`
- BT brand Case: text matching `This is a ... Case, please handle with care.` with the BT brand emphasized.

Do not confuse `caseBannerForMod` on the CSM page with `CaseHighlighterPage`.

## Login As procedure

For each user group:

1. Return to the administrator session.
2. Open Setup → Users → Users, locate the exact username, confirm the profile shown below, and click Login / Login As.
3. If Login As is unavailable, the user is inactive, the profile differs, or the user cannot access the app/Case, record **Not run** and the exact reason. Do not substitute a profile.
4. Switch to the exact Lightning app specified by the test.
5. Open the Case using `https://rc--devgss1.sandbox.my.salesforce.com/lightning/r/Case/<CASE_ID>/view`.
6. Wait for all page regions and iframes to load. Use desktop/Large form factor and normal browser zoom.
7. Capture one context screenshot showing the app name and Case identity, and one focused screenshot of the area where the highlighter is present or expected. Screenshots are mandatory whenever the expected or observed result is **Not visible**.
8. After that user's tests, use Salesforce's normal Return to admin / Log out as control before impersonating the next user.

## Users

| Alias        | Name                 | Username                                    | User ID              | Profile                                  |
| ------------ | -------------------- | ------------------------------------------- | -------------------- | ---------------------------------------- |
| U-T1         | Nivedha Surendran    | `nivedha.surendran@ringcentral.com.devgss1` | `0052H00000EF9YXQA1` | Support T1                               |
| U-T2         | David Rodriguez      | `david.rodriguez@ringcentral.com.devgss1`   | `0052H00000DsR0XQAV` | Support T2                               |
| U-T3         | Ryan Hawkins         | `ryan.hawkins@ringcentral.com.devgss1`      | `0053400000BMqN0AAL` | Support T3                               |
| U-T1-EU      | Mark Anthony Dumlao  | `mark.dumlao@ringcentral.com.devgss1`       | `0053400000CXoprAAD` | Support T1 - EU Restricted               |
| U-T2-EU      | Mark Anthony Austria | `mark.austria@ringcentral.com.devgss1`      | `00534000009LoqUAAS` | Support T2 - EU Restricted               |
| U-T3-EU      | Bo Lemecha           | `bo.lemecha@ringcentral.com.devgss`         | `005TH00000VHIwLYAX` | Support T3 - EU Restricted               |
| U-CSM        | Matt Good            | `matt.good@ringcentral.com.devgss1`         | `0053400000A4biSAAR` | Signature - CSM Lightning                |
| U-SE-EU      | Carlos Loaiza        | `carlos.loaiza@ringcentral.com.devgss1`     | `0053400000BmNGHAA3` | Sales Engineer Lightning - EU Restricted |
| U-TAM        | Ben Pintilie         | `ben.pintilie@ringcentral.com.devgss1`      | `0052H00000ChgN1QAJ` | Support - TAM                            |
| U-BO         | John Ramirez         | `john.ramirez@ringcentral.com.devgss1`      | `0052H00000DV52pQAD` | Support Back Office                      |
| U-OPS        | Yvonne Gonzales      | `yvonne.gonzales@ringcentral.com.devgss1`   | `0052H00000DsRwCQAV` | Support Operations                       |
| U-IMPL       | Ivo Todorov          | `ivo.todorov@ringcentral.com.devgss1`       | `0052H00000DkDJrQAN` | Support Implementations                  |
| U-PROSERV-EU | Akshay Jaiswal       | `akshay.jaiswal@ringcentral.com.devgss1`    | `0052H00000E6uB3QAJ` | ProServ -Lightning - EU Restricted       |
| U-ICSM-EU    | Rebekah King         | `rebekah.king@ringcentral.com.devgss1`      | `005TU00000ET0NxYAL` | ICSM Lightning - EU Restricted           |

## Case manifest

All Cases below are read-only controls. `Hyper_Care__c` is false for every Account listed here.

| Alias     | Record type                   | Case number | Case ID              | Existing visual trigger          |
| --------- | ----------------------------- | ----------- | -------------------- | -------------------------------- |
| C-T1      | `Support_T1`                  | 30744551    | `500TH00000ZgqioYAB` | BT brand                         |
| C-T1VAR   | `Support_T1_VAR_Partners`     | 30737048    | `500TH00000VRqANYA1` | AT&T brand                       |
| C-T2      | `Support_T2`                  | 30744553    | `500TH00000ZmQdcYAF` | Escalated — deterministic text   |
| C-RCEV    | `Support_RCEV_T2`             | 30728512    | `500TH00000SRc4KYAT` | AT&T brand                       |
| C-T3      | `Support_T3`                  | 30740700    | `500TH00000YCKaUYAX` | BT brand                         |
| C-CASE    | `Support_Case`                | 30742815    | `500TH00000ZbgKHYAZ` | BT brand                         |
| C-CHAT    | `Support_Chat`                | 30737263    | `500TH00000WRqmYYAT` | BT brand                         |
| C-QOS     | `Support_QoS`                 | 30737265    | `500TH00000WRqmaYAD` | BT brand                         |
| C-INT     | `Support_Integrations`        | 30737264    | `500TH00000WRqmZYAT` | BT brand                         |
| C-RCAPP   | `Support_RC_App`              | 30731736    | `500TH00000TleXuYAJ` | None — component inspection only |
| C-PRODUCT | `Product_Platform_Issues`     | 30737262    | `500TH00000WRqmXYAT` | BT brand                         |
| C-EXT     | `Extended_Enterprise_Support` | 30737261    | `500TH00000WRqmWYAT` | BT brand                         |
| C-DEV     | `Developer_Platform`          | 30737260    | `500TH00000WRqmVYAT` | BT brand                         |
| C-RISE    | `RISE_Partner_Support`        | 30731741    | `500TH00000TleXzYAJ` | BT brand                         |
| C-AVAYA   | `Support_Avaya`               | 30738518    | `500TH00000XCA8gYAH` | AT&T brand                       |
| C-CV      | `Support_CV`                  | 30728722    | `500TH00000TScrYYAT` | AT&T brand                       |
| C-SHIP    | `Support_T1_Shipping`         | 30728723    | `500TH00000TSjJKYA1` | AT&T brand                       |
| C-TELUS   | `Support_Telus`               | 30732729    | `500TH00000UOsfWYAT` | BT brand                         |
| C-RCC     | `RCC_Issues`                  | 30728514    | `500TH00000SRpXlYAL` | AT&T brand                       |
| C-RCLEC   | `RCLEC`                       | 30728516    | `500TH00000SRpRKYA1` | AT&T brand                       |
| C-ATT     | `Support_AT_T`                | 30732660    | `500TH00000TtPRrYAN` | AT&T brand                       |
| C-RED     | `Support_Red_Account`         | 30728515    | `500TH00000SRqK9YAL` | AT&T brand                       |
| C-BILLING | `Support_Billing`             | 30737113    | `500TH00000VsGKUYA3` | BT brand                         |

## Phase 0 — mandatory positive calibration

| Test | User | App           | Case | Expected                                                |
| ---- | ---- | ------------- | ---- | ------------------------------------------------------- |
| P00  | U-T2 | RC Sales View | C-T2 | `CaseHighlighterPage` visible with exact escalated text |

If P00 fails to show the escalated message after the page fully loads, stop pass/fail judgments and mark all later visual-absence checks **Blocked by failed calibration**. You may continue gathering screenshots and context.

## Phase 1 — highest-confidence page-level gaps

Run every permutation represented below.

| Tests   | User    | App(s)                        | Case(s)                                  | Expected                                                                                                          |
| ------- | ------- | ----------------------------- | ---------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| N01–N04 | U-T1    | RC Service; Lightning Service | C-T1; C-T2                               | Existing trigger message not visible; highlighter omitted by `Sofia_Support_Cases`                                |
| N05–N08 | U-T2    | RC Service; Lightning Service | C-T1; C-T2                               | Existing trigger message not visible; highlighter omitted by `Sofia_Support_Cases`                                |
| N09–N13 | U-CSM   | RC Sales View                 | C-T1; C-T1VAR; C-T2; C-T3; C-RCAPP       | Highlighter absent. Ignore `caseBannerForMod`. C-RCAPP is Inconclusive unless component inspection proves absence |
| N14–N25 | U-SE-EU | Lightning Sales               | All 12 in-scope Cases C-T1 through C-EXT | Highlighter absent. C-RCAPP is Inconclusive unless component inspection proves absence                            |

These 25 UI rows cover the core Sofia, CSM, and EU Sales page-composition failures.

## Phase 2 — live DevGSS layout-gap checks

| Test | User         | App                                     | Case      | Expected                                                                                               |
| ---- | ------------ | --------------------------------------- | --------- | ------------------------------------------------------------------------------------------------------ |
| L01  | U-T1-EU      | Dimelo Console Lightning                | C-T1      | Not visible                                                                                            |
| L02  | U-T1-EU      | Dimelo Lightning                        | C-T1      | Not visible                                                                                            |
| L03  | U-T1-EU      | DocuSign for Salesforce Core            | C-T1      | Not visible                                                                                            |
| L04  | U-T2-EU      | RC Sales Lightning                      | C-T2      | Not visible                                                                                            |
| L05  | U-T3-EU      | RC Sales Lightning                      | C-T3      | Not visible                                                                                            |
| L06  | U-T1-EU      | Preconfigured Lightning Service Console | C-CHAT    | Not visible                                                                                            |
| L07  | U-T1-EU      | Preconfigured Lightning Service Console | C-T1      | Not visible                                                                                            |
| L08  | U-T2-EU      | Preconfigured Lightning Service Console | C-T2      | Not visible                                                                                            |
| L09  | U-T3         | Preconfigured Lightning Service Console | C-T3      | Not visible                                                                                            |
| L10  | U-T3-EU      | Preconfigured Lightning Service Console | C-T3      | Not visible                                                                                            |
| L11  | U-TAM        | Preconfigured Lightning Service Console | C-EXT     | Not visible                                                                                            |
| L12  | U-BO         | Preconfigured Lightning Service Console | C-EXT     | Not visible                                                                                            |
| L13  | U-OPS        | Preconfigured Lightning Service Console | C-EXT     | Not visible                                                                                            |
| L14  | U-OPS        | Preconfigured Lightning Service Console | C-INT     | Not visible                                                                                            |
| L15  | U-T2         | Preconfigured Lightning Service Console | C-INT     | Not visible                                                                                            |
| L16  | U-PROSERV-EU | RC Sales Lightning                      | C-EXT     | Not visible                                                                                            |
| L17  | U-PROSERV-EU | RC Sales Lightning                      | C-INT     | Not visible                                                                                            |
| L18  | U-ICSM-EU    | RC Sales Lightning                      | C-EXT     | Not visible                                                                                            |
| L19  | U-ICSM-EU    | RC Sales Lightning                      | C-INT     | Not visible                                                                                            |
| L20  | U-T2         | RC Sales View                           | C-BILLING | Not visible; best triggered control for an active support-related type with no mapped highlighter path |

If an app is unavailable to the impersonated user, mark **Not run — app unavailable**. That is not evidence that the component is absent.

## Phase 3 — out-of-scope record types expected to show the highlighter

### Direct Lightning-page paths

| Test | User    | App           | Case    | Expected                 |
| ---- | ------- | ------------- | ------- | ------------------------ |
| O01  | U-T1    | RC Service    | C-DEV   | BT highlighter visible   |
| O02  | U-T1-EU | RC Service    | C-RISE  | BT highlighter visible   |
| O03  | U-T2    | RC Sales View | C-AVAYA | AT&T highlighter visible |
| O04  | U-T2    | RC Sales View | C-CV    | AT&T highlighter visible |
| O05  | U-T2    | RC Sales View | C-SHIP  | AT&T highlighter visible |
| O06  | U-T2    | RC Sales View | C-TELUS | BT highlighter visible   |

### Layout-backed paths through Record Detail

| Test | User | App                                     | Case    | Expected                                                                             |
| ---- | ---- | --------------------------------------- | ------- | ------------------------------------------------------------------------------------ |
| O07  | U-T2 | Preconfigured Lightning Service Console | C-RCC   | AT&T highlighter visible                                                             |
| O08  | U-T2 | Preconfigured Lightning Service Console | C-RCLEC | AT&T highlighter visible                                                             |
| O09  | U-T2 | Preconfigured Lightning Service Console | C-ATT   | AT&T highlighter visible                                                             |
| O10  | U-T2 | Preconfigured Lightning Service Console | C-RED   | AT&T highlighter visible; record whether a separate Red Account message also appears |

If O07–O10 resolve to a page that does not render Record Detail, record the actual page context and mark the row **Inconclusive — unexpected page resolution** rather than Fail.

## Observation and verdict rules

For every row:

1. Confirm the exact username/profile, app, Case number/ID, and record type before judging the result.
2. Record `Highlighter: Visible / Not visible / Unclear`.
3. Transcribe the exact existing banner text if visible.
4. Record `Hypercare message: Not testable — no Hypercare-qualified DevGSS data and implementation not deployed`.
5. Use these verdicts:

   - **Pass:** observed existing highlighter behavior matches expected behavior.
   - **Fail:** correct context loaded and observed behavior contradicts the expectation.
   - **Inconclusive:** no visual trigger, unexpected page resolution, context mismatch, partial load, or ambiguous component identity.
   - **Not run:** cannot Login As, inactive user, app unavailable, or record access denied.

6. Never infer absence from access denial or an unloaded/blank iframe.
7. For every correct-context **Not visible** observation, capture both:

   - a context screenshot showing the Lightning app, Case identity, and enough of the page to establish where the banner should appear; and
   - a focused screenshot of the missing-banner area after the page and all iframes have fully loaded.

8. Assign one soft evidence reference to each test, using `E-<TEST_ID>` such as `E-N01` or `E-L14`. Put only that reference in the result table; do not insert images, thumbnails, long links, or captions inside table cells.

## Required result format

Return one row for every test ID:

| Test ID | Username | Profile | App | Case number / ID | Record type | Expected highlighter | Observed highlighter | Exact observed text | Verdict | Evidence ref | Notes / blocker |
| ------- | -------- | ------- | --- | ---------------- | ----------- | -------------------- | -------------------- | ------------------- | ------- | ------------ | --------------- |

Finish with:

1. **Confirmed UI gaps** — only correct-context rows with a known existing trigger whose expected highlighter was absent.
2. **Confirmed out-of-scope types with visible highlighter** — include exact user/profile/app/Case evidence.
3. **Contradictions to metadata expectations** — every Fail.
4. **Inconclusive or not run** — with exact blocker.
5. **Hypercare-specific blocker** — state that the proposed new message remains unvalidated because DevGSS has no `Hyper_Care__c = true` Account and the implementation is not deployed.

## Create the Google Doc

After all runnable tests are complete:

1. Return to the administrator Salesforce session and confirm that no edit dialog or unsaved Salesforce change remains open.
2. Open Google Docs in the user's existing logged-in browser session.
3. Create exactly one new Google Doc named **DevGSS Hypercare Banner — Case Highlighter UI Validation Results**.
4. Add the execution date and time, DevGSS environment, tester identity if visible, and a statement that the Salesforce run was read-only.
5. Structure the document in this order:

   - Executive summary, including totals for Pass, Fail, Inconclusive, and Not run.
   - Hypercare-specific test-data limitation.
   - Calibration result.
   - Confirmed UI gaps.
   - Confirmed out-of-scope record types with a visible Case Highlighter.
   - Contradictions to metadata expectations.
   - Inconclusive and Not run checks with blockers.
   - Complete result table containing every test ID. Keep this table text-only and place only soft evidence references such as `E-N01` in its **Evidence ref** column.
   - **Screenshot Evidence Appendix** as the final section of the document, after every table and conclusion. Do not place screenshots between table rows or immediately below individual test rows.

6. Preserve exact Salesforce usernames, profile names, Case numbers, record types, observed banner text, verdicts, and blockers. Do not invent missing results or represent an unexecuted test as completed.
7. In the **Screenshot Evidence Appendix**:

   - create one subsection per evidence reference, titled like `E-N01 — Missing Case Highlighter`;
   - show the test ID, username/profile, app, Case number/ID, record type, expected result, observed result, and capture time as a short caption above the images;
   - place the context screenshot first and focused screenshot second;
   - include screenshots for every confirmed or suspected missing-banner row, including Fail, Pass-with-expected-absence, and Inconclusive absence observations;
   - use the same evidence reference in the result table and appendix so readers can find the images without disrupting the table; and
   - if no screenshot could be captured, keep the evidence reference and explain the reason in both the row's Notes field and the appendix entry.

8. Do not share the document or alter its permissions. Leave it private under the currently logged-in Google account.
9. After creating the document, return its title and direct Google Docs URL in your final response. If Google Docs is unavailable or document creation fails, report the exact blocker and return the complete formatted results in the chat instead.

Do not modify any Salesforce record or metadata during this run. The only authorized write is creation of the single results Google Doc described above.
