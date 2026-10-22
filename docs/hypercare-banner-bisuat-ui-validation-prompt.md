# Claude for Chrome prompt — reduced BisUAT Case Highlighter smoke test

Copy everything under **Prompt to paste** into Claude for Chrome.

## Basis for the reduced scope

The complete coverage analysis already comes from SF Master plus live BisUAT profile-to-layout metadata. This UI run is only a six-check smoke test of the major rendering patterns; it is not intended to repeat every profile/app/record-type permutation.

BisUAT has Hypercare Accounts and Cases, but its deployed `CaseHighlighter` class does not evaluate `Hyper_Care__c`. The proposed Hypercare-specific message is therefore not deployed or testable. These checks validate placement of the existing Case Highlighter using known escalation or brand triggers.

## Prompt to paste

Validate the existing Salesforce Case Highlighter in the **BisUAT sandbox** using the authenticated administrator session.

Salesforce host:

`https://rc--bisuat.sandbox.my.salesforce.com`

This entire run is strictly read-only. Do not create, edit, save, submit, delete, close, merge, clone, reassign, escalate, or otherwise change any Salesforce record or metadata. Do not change users, permissions, apps, layouts, Accounts, or Cases. Do not create or update a Google Doc, local file, email, message, or other external artifact.

You may navigate, switch Lightning apps, use Salesforce **Login As**, inspect rendered pages, and capture screenshots. Return all results in the final chat response.

## Execution rules

- Run exactly the six checks below unless a check is blocked.
- Use only the three listed users.
- Batch checks by user. Do not log in as a different user for each Case.
- Complete all four U-T2 checks in one impersonation session, switching apps as needed.
- Switch profiles only for the CSM and Sales Engineer checks.
- Return to the administrator session before impersonating the next user.
- If the required app, user, or Case is unavailable, mark the check **Not run**. Do not substitute another profile or modify data.

## Users

| Alias   | Name           | Username                                | User ID              | Profile                                  |
| ------- | -------------- | --------------------------------------- | -------------------- | ---------------------------------------- |
| U-T2    | Georgi Petrov  | `georgi.petrov@ringcentral.com.bisuat`  | `005D5000005OtbcIAC` | Support T2                               |
| U-CSM   | Brian Price    | `brian.price@ringcentral.com.bisuat`    | `0052H00000CB4SfQAL` | Signature - CSM Lightning                |
| U-SE-EU | Riyaz Mohammed | `riyaz.mohammed@ringcentral.com.bisuat` | `0052H00000DCjIuQAL` | Sales Engineer Lightning - EU Restricted |

## Cases

| Alias   | Record type            | Case number | Case ID              | Existing trigger                                                                   |
| ------- | ---------------------- | ----------- | -------------------- | ---------------------------------------------------------------------------------- |
| C-T2    | `Support_T2`           | 20837178    | `500D500000BA8ZkIAL` | Escalated; expected text: `Please handle with care. This case has been escalated.` |
| C-INT   | `Support_Integrations` | 21423246    | `500U700000cspm1IAA` | BT brand                                                                           |
| C-AVAYA | `Support_Avaya`        | 21416291    | `500U700000c9YjlIAE` | BT brand                                                                           |

Open a Case using:

`https://rc--bisuat.sandbox.my.salesforce.com/lightning/r/Case/<CASE_ID>/view`

Wait for the page and all iframes to finish loading. Use desktop/Large form factor and normal browser zoom.

## Six checks

Run the U-T2 checks first in the order shown so the positive calibration is established before judging absence.

| Test | User    | App                                     | Case    | Pattern validated                                       | Expected result                                                               |
| ---- | ------- | --------------------------------------- | ------- | ------------------------------------------------------- | ----------------------------------------------------------------------------- |
| P01  | U-T2    | RC Sales View                           | C-T2    | Positive calibration                                    | Existing Case Highlighter visible with the exact escalated text               |
| O01  | U-T2    | RC Sales View                           | C-AVAYA | Out-of-scope record type with a direct highlighter page | Existing BT Case Highlighter visible                                          |
| G01  | U-T2    | RC Service                              | C-T2    | Sofia page gap                                          | Escalated message and Case Highlighter not visible                            |
| G04  | U-T2    | Preconfigured Lightning Service Console | C-INT   | Record Detail plus missing assigned-layout component    | BT message and Case Highlighter not visible                                   |
| G02  | U-CSM   | RC Sales View                           | C-T2    | CSM page gap                                            | Escalated message and Case Highlighter not visible; ignore `caseBannerForMod` |
| G03  | U-SE-EU | Lightning Sales                         | C-T2    | EU Sales page gap                                       | Escalated message and Case Highlighter not visible                            |

If P01 fails after the page fully loads, continue collecting evidence but mark G01–G04 **Inconclusive — positive calibration failed** rather than passing or failing them.

## Observation rules

For every check:

1. Confirm the username/profile, Lightning app, Case number/ID, and record type.
2. Record the Case Highlighter as **Visible**, **Not visible**, or **Unclear**.
3. If visible, transcribe the exact banner text.
4. Record the proposed Hypercare message as: `Not testable — deployed BisUAT CaseHighlighter does not evaluate Hyper_Care__c`.
5. Use these verdicts:

   - **Pass:** observed behavior matches the expected result.
   - **Fail:** the correct context loaded and behavior contradicts the expected result.
   - **Inconclusive:** calibration failure, unexpected page resolution, partial load, or ambiguous component identity.
   - **Not run:** required user/app/Case is inaccessible.

Never infer absence from access denial, a loading error, or an unloaded iframe.

## Screenshot evidence

- Screenshots are mandatory for G01–G04 when the correct context loads.
- For each missing-banner check, capture:

  1. a context screenshot showing the app and Case identity; and
  2. a focused screenshot of the fully loaded area where the highlighter should appear.

- Assign a soft evidence reference matching the test ID, such as `E-G01`.
- Put only the evidence reference in the result table.
- Place all screenshots in a **Screenshot Evidence Appendix** at the very end of the response. Do not insert screenshots into or between table rows.
- Each appendix entry must state the test ID, user/profile, app, Case, record type, observed result, and capture time before showing its screenshots.

## Required concise output

Be clear and precise. Use short factual statements, exact counts, and exact observed banner text. Do not repeat the test plan or provide speculative commentary.

Return this text-only table:

| Test | User/profile | App | Case / record type | Expected | Observed | Verdict | Evidence ref | Blocker or concise note |
| ---- | ------------ | --- | ------------------ | -------- | -------- | ------- | ------------ | ----------------------- |

After the table, include only:

1. **Summary:** no more than five bullets.
2. **Confirmed gaps:** test IDs and one-sentence findings.
3. **Contradictions or blockers:** test IDs and concise details.
4. **Hypercare limitation:** one sentence explaining that the proposed message is not deployed.
5. **Screenshot Evidence Appendix:** final section containing the referenced images.

Return everything in chat only. Make no changes to Salesforce or any external system.
