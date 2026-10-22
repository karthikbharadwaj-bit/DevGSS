# Case Highlighter Coverage Summary

Source: SF Master commit `c81bb25a91b6a0c27bf676a86bfaabd1b9f378d5`. Results apply to desktop (`Large`) Case record pages.

## 1. Profile → layout/page → record-type combinations without the Case Highlighter

The audit confirms **35 combinations** where the resolved desktop page does not render `CaseHighlighterPage`.

| Profile                                  | App                                     | Record type(s)                                                                        | Resolved page                                | Layout/component result                                                                                                                        | Combinations |
| ---------------------------------------- | --------------------------------------- | ------------------------------------------------------------------------------------- | -------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | -----------: |
| Support T1                               | RC Service                              | `Support_T1`, `Support_T2`                                                            | `Sofia_Support_Cases`                        | Assigned `Case-Sofia Support Cases Layout` contains the highlighter, but the desktop page does not render the layout or embed the highlighter. |            2 |
| Support T2                               | RC Service                              | `Support_T1`, `Support_T2`                                                            | `Sofia_Support_Cases`                        | Same page-level omission.                                                                                                                      |            2 |
| Support T1                               | Lightning Service                       | `Support_T1`, `Support_T2`                                                            | `Sofia_Support_Cases`                        | Same page-level omission.                                                                                                                      |            2 |
| Support T2                               | Lightning Service                       | `Support_T1`, `Support_T2`                                                            | `Sofia_Support_Cases`                        | Same page-level omission.                                                                                                                      |            2 |
| Signature - CSM Lightning                | RC Sales View                           | `Support_T1`, `Support_T1_VAR_Partners`, `Support_T2`, `Support_T3`, `Support_RC_App` | `GSS_Cases_CSM`                              | Page has neither `CaseHighlighterPage` nor desktop Record Detail. `caseBannerForMod` is a different component.                                 |            5 |
| Sales Engineer Lightning - EU Restricted | Lightning Sales                         | All 12 in-scope record types                                                          | `Sales_Cases_Lightning_EU_Restricted`        | Page has neither `CaseHighlighterPage` nor desktop Record Detail.                                                                              |           12 |
| Support T1 - EU Restricted               | Dimelo Console Lightning                | `Support_T1`                                                                          | `EU_Restricted_GSS_Cases_Support_T1_Updated` | Assigned `Case-GSS Cases Support - T1_Updated_ForT1EURestricted` layout omits the highlighter.                                                 |            1 |
| Support T1 - EU Restricted               | Dimelo Lightning                        | `Support_T1`                                                                          | `EU_Restricted_GSS_Cases_Support_T1_Updated` | Same layout omission.                                                                                                                          |            1 |
| Support T1 - EU Restricted               | DocuSign for Salesforce Core            | `Support_T1`                                                                          | `EU_Restricted_GSS_Cases_Support_T1_Updated` | Same layout omission.                                                                                                                          |            1 |
| Support T2 - EU Restricted               | RC Sales Lightning                      | `Support_T2`                                                                          | `EU_Restricted_Case_Generic_Page`            | Assigned `Case-GSS Cases Support T2 For EURestricted` layout omits the highlighter.                                                            |            1 |
| Support T3 - EU Restricted               | RC Sales Lightning                      | `Support_T3`                                                                          | `EU_Restricted_Case_Generic_Page`            | Assigned `Case-Support T3 Layout with Case Tagging For Support T3 EU Restricted` layout omits the highlighter.                                 |            1 |
| Support T1 - EU Restricted               | Preconfigured Lightning Service Console | `Support_Chat`                                                                        | `CaseDefault_Record_Page`                    | Assigned `Case-GSS Cases Chat for Support Chat for Support T1 EU Restricted` layout omits the highlighter.                                     |            1 |
| Support T1 - EU Restricted               | Preconfigured Lightning Service Console | `Support_T1`                                                                          | `CaseDefault_Record_Page`                    | Assigned `Case-GSS Cases Support - T1_Updated_ForT1EURestricted` layout omits the highlighter.                                                 |            1 |
| Support T2 - EU Restricted               | Preconfigured Lightning Service Console | `Support_T2`                                                                          | `CaseDefault_Record_Page`                    | Assigned `Case-GSS Cases Support T2 For EURestricted` layout omits the highlighter.                                                            |            1 |
| Support T3                               | Preconfigured Lightning Service Console | `Support_T3`                                                                          | `CaseDefault_Record_Page`                    | Assigned `Case-Support T3 Layout with Case Tagging For Support T3 EU Restricted` layout omits the highlighter.                                 |            1 |
| Support T3 - EU Restricted               | Preconfigured Lightning Service Console | `Support_T3`                                                                          | `CaseDefault_Record_Page`                    | Same layout omission.                                                                                                                          |            1 |
| **Total**                                |                                         |                                                                                       |                                              |                                                                                                                                                |       **35** |

The 12 in-scope record types referenced above are: `Support_T1`, `Support_T1_VAR_Partners`, `Support_T2`, `Support_RCEV_T2`, `Support_T3`, `Support_Case`, `Support_Chat`, `Support_QoS`, `Support_Integrations`, `Support_RC_App`, `Product_Platform_Issues`, and `Extended_Enterprise_Support`.

## 2. Out-of-scope record types with a proven Case Highlighter path

The audit confirms **22 out-of-scope record types** with at least one metadata path to the Case Highlighter.

| Record type API name                           | Proven path           |
| ---------------------------------------------- | --------------------- |
| `Developer_Platform`                           | Direct Lightning page |
| `RISE_Partner_Support`                         | Direct Lightning page |
| `Support_Avaya`                                | Direct Lightning page |
| `Support_CV`                                   | Direct Lightning page |
| `Support_Executive_Response_Team`              | Direct Lightning page |
| `Support_Shipping_Failed_Address_Verification` | Direct Lightning page |
| `Support_T1_Shipping`                          | Direct Lightning page |
| `Support_Telus`                                | Direct Lightning page |
| `GDPR_Request`                                 | Assigned page layout  |
| `Porting_In_IVN_Global_Office`                 | Assigned page layout  |
| `Porting_In_RC`                                | Assigned page layout  |
| `Porting_In_RC_AU`                             | Assigned page layout  |
| `Porting_In_RC_EU`                             | Assigned page layout  |
| `RCC_Issues`                                   | Assigned page layout  |
| `RCLEC`                                        | Assigned page layout  |
| `Support_Customer_ebonding`                    | Assigned page layout  |
| `Support_Glip`                                 | Assigned page layout  |
| `Support_Implementation_Escalation`            | Assigned page layout  |
| `Support_Lead_Team`                            | Assigned page layout  |
| `Support_Subpoena_Request`                     | Assigned page layout  |
| `Support_VIPFR`                                | Assigned page layout  |
| `Support_Voicemail`                            | Assigned page layout  |

“Direct Lightning page” means an app override resolves to a page that embeds `CaseHighlighterPage`. “Assigned page layout” means a proven profile/record-type layout contains the Visualforce page. Each entry proves at least one configured path, not universal visibility across every profile and app.

## 3. Resolution for the in-scope coverage gaps

Use the rendering path to determine the fix: add `CaseHighlighterPage` directly to Lightning pages that bypass Record Detail, and add it to the assigned page layout when the Lightning page renders Record Detail.

| In-scope record type(s)                                                               | Affected surface                                                               | Resolution                                                                                                                                                                                                              |
| ------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Support_T1`, `Support_T2`                                                            | `Sofia_Support_Cases` in RC Service and Lightning Service                      | Add `CaseHighlighterPage` to the desktop Lightning page. The assigned layout already contains the highlighter, but the current desktop page does not render it.                                                         |
| `Support_T1`, `Support_T1_VAR_Partners`, `Support_T2`, `Support_T3`, `Support_RC_App` | `GSS_Cases_CSM` in RC Sales View                                               | Add `CaseHighlighterPage` to the Lightning page. Keep `caseBannerForMod`; it is a separate component and does not render Case Highlighter messages.                                                                     |
| All 12 in-scope record types                                                          | `Sales_Cases_Lightning_EU_Restricted` in Lightning Sales                       | Add `CaseHighlighterPage` to the desktop Lightning page for the Sales Engineer Lightning - EU Restricted assignments.                                                                                                   |
| `Support_T1`                                                                          | `Case-GSS Cases Support - T1_Updated_ForT1EURestricted` layout                 | Add the `CaseHighlighterPage` Visualforce component to the layout used through Record Detail.                                                                                                                           |
| `Support_Chat`                                                                        | `Case-GSS Cases Chat for Support Chat for Support T1 EU Restricted` layout     | Add the `CaseHighlighterPage` Visualforce component to the layout used through Record Detail.                                                                                                                           |
| `Support_T2`                                                                          | `Case-GSS Cases Support T2 For EURestricted` layout                            | Add the `CaseHighlighterPage` Visualforce component to the layout used through Record Detail.                                                                                                                           |
| `Support_T3`                                                                          | `Case-Support T3 Layout with Case Tagging For Support T3 EU Restricted` layout | Add the `CaseHighlighterPage` Visualforce component to the layout used through Record Detail. Confirm both Support T3 and Support T3 - EU Restricted profiles because both resolve to this layout in the audited paths. |

After deployment, validate one existing positive control and one Hypercare-qualified Case for each changed page or layout. Confirm that the banner appears once, displays the intended message, and does not duplicate an existing highlighter.
