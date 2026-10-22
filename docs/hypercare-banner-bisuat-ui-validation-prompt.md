# Claude for Chrome prompt — final BisUAT EU Sales validation

Copy everything under **Prompt to paste** into Claude for Chrome.

## Purpose

The RC Service/Sofia gap is already UI-confirmed and does not need to be rerun. This final read-only check covers only the remaining EU Sales pattern. It uses one user, one app, and two Cases: an accessible positive control followed by the previously observed negative Case.

## Prompt to paste

Complete the remaining Salesforce Case Highlighter validation in the **BisUAT sandbox** using the already authenticated administrator session.

Work only on:

`https://rc--bisuat.sandbox.my.salesforce.com`

This run is strictly read-only. Do not create, edit, save, submit, delete, close, merge, clone, reassign, escalate, or otherwise change any Salesforce record or metadata. Do not change Setup, users, permissions, apps, layouts, Accounts, or Cases. Do not create or update a Google Doc, local file, email, message, or other external artifact.

You may navigate, switch Lightning apps, use Salesforce **Login As**, inspect rendered pages, and capture screenshots. Return the results only in the final chat response.

### Run only these two checks

Use one Login As session:

| Name           | Username                                | User ID              | Profile                                  |
| -------------- | --------------------------------------- | -------------------- | ---------------------------------------- |
| Riyaz Mohammed | `riyaz.mohammed@ringcentral.com.bisuat` | `0052H00000DCjIuQAL` | Sales Engineer Lightning - EU Restricted |

1. Return to the administrator session if necessary.
2. Open Setup → Users → Users, locate the exact username, confirm that the user is active and has the listed profile, and click Login / Login As.
3. Switch to the app whose visible label is exactly **Sales**.
4. Run P02 first and then G02 without changing user or app.

| Test | Case number | Case ID              | Record type    | Purpose           | Expected result                                          |
| ---- | ----------- | -------------------- | -------------- | ----------------- | -------------------------------------------------------- |
| P02  | 19049676    | `500D500000Am3QwIAJ` | `Support_AT_T` | Positive control  | Case Highlighter visible with AT&T and/or escalated text |
| G02  | 20837178    | `500D500000BA8ZkIAL` | `Support_T2`   | EU Sales page gap | Escalated Case Highlighter not visible                   |

Open each Case directly with:

`https://rc--bisuat.sandbox.my.salesforce.com/lightning/r/Case/<CASE_ID>/view`

Live BisUAT metadata reports that Riyaz has read access to both Case IDs. If either Case is nevertheless inaccessible in the UI, mark that row **Not run** and record the exact error. Do not substitute another user, app, Case, profile, or record type.

Wait for the Case page and all page regions or iframes to finish loading. Use desktop/Large form factor and normal browser zoom. Before judging a row, confirm the logged-in user/profile, `Sales` app, Case number or ID, and record type.

Recognize these existing Case Highlighter messages:

- AT&T brand: text matching `This is a AT&T Case, please handle with care.`
- Escalated Case: `Please handle with care. This case has been escalated.`

P02 may show both messages. Either recognized message inside the Case Highlighter proves the positive control. Do not mistake an orange Jira notice, `caseBannerForMod`, or another banner for `CaseHighlighterPage`.

### Calibration and verdicts

For each row, record `Highlighter: Visible / Not visible / Unclear` and transcribe the exact Case Highlighter text when visible.

- **Pass:** the correct context loaded and the observation matches the expected result.
- **Fail:** the correct context loaded and the observation contradicts the expected result.
- **Inconclusive:** the page partially loaded, component identity is ambiguous, or P02 did not Pass before G02 was judged.
- **Not run:** the required user, app, Case, or record access was unavailable.

If P02 is not a Pass, G02 cannot be a Pass. Collect G02 evidence if possible and mark it **Inconclusive — paired positive control not established**.

For both rows, record the proposed Hypercare message as:

`Not testable — the deployed BisUAT CaseHighlighter does not evaluate Hyper_Care__c.`

### Screenshot evidence

- Capture screenshots for both rows when the correct context loads.
- For P02, capture the user/app/Case context and the visible Case Highlighter.
- For G02, capture:
  1. a context screenshot showing the logged-in user, Sales app, Case identity, and record type; and
  2. a focused screenshot of the fully loaded area where the highlighter would appear.
- Use soft references `E-P02` and `E-G02` in the results table.
- Put all images in a **Screenshot Evidence Appendix** at the end; do not place images in or between table rows.
- If screenshots cannot be embedded or persisted outside the browser session, state that clearly. Do not present a session-local path as a durable artifact.

### Required concise output

Return exactly two result rows:

| Test | User/profile | App | Case / record type | Expected | Observed | Verdict | Evidence ref | Blocker or concise note |
| ---- | ------------ | --- | ------------------ | -------- | -------- | ------- | ------------ | ----------------------- |

Then include only:

1. **Summary:** at most three bullets with exact verdict counts.
2. **Confirmed EU Sales gap:** include G02 only if P02 Passed.
3. **Contradictions or blockers:** concise facts only.
4. **Hypercare limitation:** one sentence.
5. **Screenshot Evidence Appendix:** the final section containing the softly referenced screenshots.

Keep the response clear, precise, and stakeholder-ready. Do not repeat the test plan, include navigation logs, or speculate. Return everything in chat only and make no changes to Salesforce or any external system.
