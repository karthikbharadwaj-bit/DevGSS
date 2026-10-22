# Hypercare Banner — SF Master Case Highlighter Audit

## Audit scope

- Source reviewed: `/Users/Karthik.Bharadwaj/Repo/SF Master/src`
- SF Master commit: `c81bb25a91b6a0c27bf676a86bfaabd1b9f378d5`
- Audit target: desktop (`Large` form factor) Lightning Case record pages, profile-to-layout assignments, and the `CaseHighlighterPage` Visualforce component.
- Current in-scope record types: `Support_T1`, `Support_T1_VAR_Partners`, `Support_T2`, `Support_RCEV_T2`, `Support_T3`, `Support_Case`, `Support_Chat`, `Support_QoS`, `Support_Integrations`, `Support_RC_App`, `Product_Platform_Issues`, and `Extended_Enterprise_Support`.

The Hypercare message is implemented inside `CaseHighlighterPage`. The page renders its highlighter content when one of its conditions is true, including `highlighterMsg != NULL` (`pages/CaseHighlighterPage.page`, lines 62–96). Therefore, a user can see the new Hypercare message only when the resolved Lightning page directly embeds `CaseHighlighterPage`, or when it uses `force:detailPanel` and the resolved page layout embeds that Visualforce page.

## Paste-ready conclusion

SF Master proves **35 desktop app/profile/record-type combinations where the Case Highlighter is absent**. They fall into four configuration patterns:

1. `Sofia_Support_Cases` in RC Service and Lightning Service: 8 combinations.
2. `GSS_Cases_CSM` in RC Sales View: 5 combinations.
3. `Sales_Cases_Lightning_EU_Restricted` in Lightning Sales: 12 combinations.
4. Record-detail pages backed by one of four EU layouts that omit `CaseHighlighterPage`: 10 combinations across Dimelo, DocuSign, RC Sales Lightning, and Preconfigured Lightning Service Console.

The checkout also proves **22 out-of-scope record types with at least one configured metadata path to the Case Highlighter**. This is a conservative minimum rather than a complete production list because the repository's Case metadata is incomplete: application/profile metadata references 162 Case record types, but only 47 record-type definition files are present.

## BisUAT UI validation status

A read-only BisUAT validation on 22 October 2026 UI-confirmed representative combinations for both the RC Service/Sofia and EU Sales page-level gap patterns. These checks support the SF Master findings; they do not replace the metadata analysis or change the source-derived count of 35 missing combinations.

| Pattern       | Tested context                                            | Observation                                                                                                                                                                                                                                                                | Assessment                                                                                |
| ------------- | --------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| Sofia page    | Support T2 profile in RC Service                          | A `Developer_Platform` control Case displayed the Case Highlighter with BT Business and Red Account messages. In the same user/app session, escalated `Support_T2` Case 20837178 displayed no Case Highlighter or escalation text; only an unrelated Jira notice appeared. | **UI-confirmed gap.** The same-session positive control passed before the negative check. |
| EU Sales page | Sales Engineer Lightning - EU Restricted profile in Sales | A `Support_AT_T` control Case displayed the AT&T Case Highlighter. In the same user/app session, escalated `Support_T2` Case 20837178 loaded without the Case Highlighter or escalation text.                                                                              | **UI-confirmed gap.** The same-session positive control passed before the negative check. |

The reduced smoke test completed with four Pass verdicts, no failures, and no inconclusive or unrun checks. Earlier broader permutations that depended on unavailable apps were not used as evidence. The browser screenshots were session-local and were not retained as durable artifacts.

The Hypercare-specific message remains untestable in BisUAT because the deployed `CaseHighlighter` implementation does not evaluate `Hyper_Care__c`.

## Confirmed gaps — Case Highlighter will not be visible

The table below is exhaustive for combinations that can be proven absent from this SF Master checkout. Each row represents desktop (`Large`) overrides only.

| App                                     | Profile                                  | Record type(s)                                                                        | Assigned Lightning page                      | Assigned layout / reason                                                                                                                                                                                   | Result      |
| --------------------------------------- | ---------------------------------------- | ------------------------------------------------------------------------------------- | -------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| RC Service                              | Support T1                               | `Support_T1`, `Support_T2`                                                            | `Sofia_Support_Cases`                        | `Case-Sofia Support Cases Layout` contains the highlighter, but the desktop Sofia page does not render `force:detailPanel` and does not directly embed `CaseHighlighterPage`.                              | Not visible |
| RC Service                              | Support T2                               | `Support_T1`, `Support_T2`                                                            | `Sofia_Support_Cases`                        | Same as above.                                                                                                                                                                                             | Not visible |
| Lightning Service                       | Support T1                               | `Support_T1`, `Support_T2`                                                            | `Sofia_Support_Cases`                        | Same as above.                                                                                                                                                                                             | Not visible |
| Lightning Service                       | Support T2                               | `Support_T1`, `Support_T2`                                                            | `Sofia_Support_Cases`                        | Same as above.                                                                                                                                                                                             | Not visible |
| RC Sales View                           | Signature - CSM Lightning                | `Support_T1`, `Support_T1_VAR_Partners`, `Support_T2`, `Support_T3`, `Support_RC_App` | `GSS_Cases_CSM`                              | Page has neither `CaseHighlighterPage` nor desktop `force:detailPanel`. Its `caseBannerForMod` component is a different component and will not render a message added only to the Visualforce highlighter. | Not visible |
| Lightning Sales                         | Sales Engineer Lightning - EU Restricted | All 12 in-scope record types                                                          | `Sales_Cases_Lightning_EU_Restricted`        | Page has neither `CaseHighlighterPage` nor desktop `force:detailPanel`.                                                                                                                                    | Not visible |
| Dimelo Console Lightning                | Support T1 - EU Restricted               | `Support_T1`                                                                          | `EU_Restricted_GSS_Cases_Support_T1_Updated` | Page uses `force:detailPanel`; assigned `Case-GSS Cases Support - T1_Updated_ForT1EURestricted` layout omits the highlighter.                                                                              | Not visible |
| Dimelo Lightning                        | Support T1 - EU Restricted               | `Support_T1`                                                                          | `EU_Restricted_GSS_Cases_Support_T1_Updated` | Same layout gap.                                                                                                                                                                                           | Not visible |
| DocuSign for Salesforce Core            | Support T1 - EU Restricted               | `Support_T1`                                                                          | `EU_Restricted_GSS_Cases_Support_T1_Updated` | Same layout gap.                                                                                                                                                                                           | Not visible |
| RC Sales Lightning                      | Support T2 - EU Restricted               | `Support_T2`                                                                          | `EU_Restricted_Case_Generic_Page`            | Page uses `force:detailPanel`; assigned `Case-GSS Cases Support T2 For EURestricted` layout omits the highlighter.                                                                                         | Not visible |
| RC Sales Lightning                      | Support T3 - EU Restricted               | `Support_T3`                                                                          | `EU_Restricted_Case_Generic_Page`            | Page uses `force:detailPanel`; assigned `Case-Support T3 Layout with Case Tagging For Support T3 EU Restricted` layout omits the highlighter.                                                              | Not visible |
| Preconfigured Lightning Service Console | Support T1 - EU Restricted               | `Support_Chat`                                                                        | `CaseDefault_Record_Page`                    | Page uses `force:detailPanel`; assigned `Case-GSS Cases Chat for Support Chat for Support T1 EU Restricted` layout omits the highlighter.                                                                  | Not visible |
| Preconfigured Lightning Service Console | Support T1 - EU Restricted               | `Support_T1`                                                                          | `CaseDefault_Record_Page`                    | Assigned `Case-GSS Cases Support - T1_Updated_ForT1EURestricted` layout omits the highlighter.                                                                                                             | Not visible |
| Preconfigured Lightning Service Console | Support T2 - EU Restricted               | `Support_T2`                                                                          | `CaseDefault_Record_Page`                    | Assigned `Case-GSS Cases Support T2 For EURestricted` layout omits the highlighter.                                                                                                                        | Not visible |
| Preconfigured Lightning Service Console | Support T3                               | `Support_T3`                                                                          | `CaseDefault_Record_Page`                    | Assigned `Case-Support T3 Layout with Case Tagging For Support T3 EU Restricted` layout omits the highlighter.                                                                                             | Not visible |
| Preconfigured Lightning Service Console | Support T3 - EU Restricted               | `Support_T3`                                                                          | `CaseDefault_Record_Page`                    | Same layout gap.                                                                                                                                                                                           | Not visible |

### Evidence for the page-level gaps

- RC Service assigns the Sofia page to both Support T1 and Support T2 profiles for both `Support_T1` and `Support_T2` (`applications/RC_Service.app-meta.xml`, lines 3955–4025). Lightning Service repeats those assignments (`applications/standard__LightningService.app-meta.xml`, lines 3740–3810).
- Both profiles assign both record types to `Case-Sofia Support Cases Layout` (`profiles/Support T1/layoutAssignments/layoutAssignments-meta.xml`, lines 32–37; `profiles/Support T2/layoutAssignments/layoutAssignments-meta.xml`, lines 32–37).
- `Sofia_Support_Cases.flexipage` is a Case record page (lines 3340–3342), contains only `force:recordDetailPanelMobile` at line 2618, and contains no `CaseHighlighterPage` value or desktop `force:detailPanel`. Its assigned page layout does contain the highlighter (`layouts/Case-Sofia Support Cases Layout.layout`, line 25), which confirms that the desktop Lightning page composition—not the layout itself—is the blocker.
- RC Sales View assigns `GSS_Cases_CSM` to Signature - CSM Lightning for the five listed record types (`applications/RC_Sales_View.app-meta.xml`, starting at lines 4129, 4138, 4147, 4300, and 4318). `GSS_Cases_CSM.flexipage` contains `caseBannerForMod` at lines 47–48, is a Case record page at lines 677–679, and has no `CaseHighlighterPage` or desktop record-detail component.
- Lightning Sales assigns `Sales_Cases_Lightning_EU_Restricted` to Sales Engineer Lightning - EU Restricted for all 12 types (`applications/standard__LightningSales.app-meta.xml`, Large-form-factor blocks starting at lines 767, 803, 857, 974, 992, 1514, 1532, 1577, 2363, 2660, 3063, and 3414). The FlexiPage is a Case record page (`flexipages/Sales_Cases_Lightning_EU_Restricted.flexipage`, lines 773–775) and has neither `CaseHighlighterPage` nor `force:detailPanel`.

### Evidence for the layout-level gaps

- The record-detail FlexiPages used by these combinations are confirmed at:
  - `flexipages/EU_Restricted_GSS_Cases_Support_T1_Updated.flexipage`, line 59.
  - `flexipages/EU_Restricted_Case_Generic_Page.flexipage`, line 129.
  - `flexipages/CaseDefault_Record_Page.flexipage`, line 294.
- The explicit profile-to-layout assignments are:
  - `profiles/Support T1 - EU Restricted/layoutAssignments/layoutAssignments-meta.xml`, lines 12–17 (`Support_Chat` and `Support_T1`).
  - `profiles/Support T2 - EU Restricted/layoutAssignments/layoutAssignments-meta.xml`, lines 12–13 (`Support_T2`).
  - `profiles/Support T3 - EU Restricted/layoutAssignments/layoutAssignments-meta.xml`, lines 16–17 (`Support_T3`).
  - `profiles/Support T3/layoutAssignments/layoutAssignments-meta.xml`, lines 32–33 (`Support_T3`).
- A full-text scan of the four assigned layouts found no `<page>CaseHighlighterPage</page>` element:
  - `layouts/Case-GSS Cases Support - T1_Updated_ForT1EURestricted.layout`
  - `layouts/Case-GSS Cases Chat for Support Chat for Support T1 EU Restricted.layout`
  - `layouts/Case-GSS Cases Support T2 For EURestricted.layout`
  - `layouts/Case-Support T3 Layout with Case Tagging For Support T3 EU Restricted.layout`
- The relevant app override blocks are:
  - `applications/Dimelo__Dimelo_console_lightning.app`, lines 60–68.
  - `applications/Dimelo__Dimelo_lightning.app`, lines 64–72.
  - `applications/dfsle__DocuSignForSalesforceCore.app`, lines 35–43.
  - `applications/RC_Sales_Lightning.app-meta.xml`, lines 18549–18557 and 19719–19727.
  - `applications/standard__PreconfiguredLightningServiceConsole.app`, lines 936–944, 1152–1160, 1278–1286, and 1719–1736.

## In-scope combinations that SF Master cannot decide

Do not treat a Lightning page that lacks a direct Visualforce component as an automatic gap if it contains `force:detailPanel`: the effective result then depends on the profile/record-type page-layout assignment.

SF Master contains 483 Large-form-factor overrides across the 12 in-scope record types where the FlexiPage uses a record-detail component but the corresponding explicit profile/record-type layout assignment is absent from the checkout. The largest unresolved groups are:

| Page                              | Apps                                                                                                                                                 | Profiles / scope                                                                                  | Why unresolved                                                                                                              |
| --------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| `EU_Restricted_Case_Generic_Page` | ERT, RC Channel Sales Manager Lightning, RC Marketing, RC Sales Lightning, RC Service, RingCentral Admin, Lightning Sales Console, Lightning Service | Numerous EU Restricted profiles across all 12 types                                               | Page uses `force:detailPanel`, but the checkout lacks the matching explicit layout assignments for most profile/type pairs. |
| `CaseDefault_Record_Page`         | Preconfigured Lightning Service Console                                                                                                              | Support - TAM, Back Office, Operations, T1, T2, T3 and EU Restricted variants across all 12 types | Same dependency on missing layout assignments.                                                                              |
| `Sales_Cases`                     | Lightning Sales                                                                                                                                      | GSP Sales Rep for `Product_Platform_Issues`, `Support_Case`, `Support_T1`, and `Support_T2`       | Same dependency on missing layout assignments.                                                                              |

This is where live sandbox metadata is necessary. In particular, the repository by itself cannot prove the previously reported Extended Enterprise Support and Support Integrations layout gaps because it does not contain explicit profile/record-type layout assignments for those two record types.

## Out-of-scope record types that have the Case Highlighter

The following 22 out-of-scope record types have a **confirmed source-control path** to the highlighter. “Direct” means an app override resolves to a FlexiPage that embeds `CaseHighlighterPage`; “Layout” means an explicit profile/record-type assignment resolves to a layout containing `<page>CaseHighlighterPage</page>`. This proves the highlighter is present for at least one profile/app path; it does not prove universal coverage across every profile and app.

| Record type API name                           | Confirmation | Example metadata evidence                                                                                                                                                             |
| ---------------------------------------------- | ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Developer_Platform`                           | Direct       | RC Service override: `applications/RC_Service.app-meta.xml`, lines 4126–4134; component: `flexipages/GSS_Cases_Default_Developer_Platform_Page.flexipage`, line 206.                  |
| `RISE_Partner_Support`                         | Direct       | RC Service override: `applications/RC_Service.app-meta.xml`, lines 90–98; component: `flexipages/EU_Restricted_GSS_Cases_Support_T1.flexipage`, line 70.                              |
| `Support_Avaya`                                | Direct       | RC Sales View override: `applications/RC_Sales_View.app-meta.xml`, lines 3111–3119; component: `flexipages/GSS_Cases_Partner.flexipage`, line 52.                                     |
| `Support_CV`                                   | Direct       | RC Sales View override: `applications/RC_Sales_View.app-meta.xml`, lines 3077–3085; component: `flexipages/GSS_Cases_Fraud_Information.flexipage`, line 52.                           |
| `Support_Executive_Response_Team`              | Direct       | RC Sales View override: `applications/RC_Sales_View.app-meta.xml`, lines 2979–2987; component: `flexipages/GSS_Cases_ERT.flexipage`, line 52.                                         |
| `Support_Shipping_Failed_Address_Verification` | Direct       | RC Sales View override: `applications/RC_Sales_View.app-meta.xml`, lines 2170–2178; component: `flexipages/GSS_Cases_Support_T1_Shipping.flexipage`, line 52.                         |
| `Support_T1_Shipping`                          | Direct       | ProServ Sales override: `applications/ProServ_Sales.app-meta.xml`, lines 14461–14469; component: `flexipages/GSS_Cases_Support_T1_Shipping.flexipage`, line 52.                       |
| `Support_Telus`                                | Direct       | RC Sales View override: `applications/RC_Sales_View.app-meta.xml`, lines 2830–2838; component: `flexipages/GSS_Cases_Telus.flexipage`, line 52.                                       |
| `GDPR_Request`                                 | Layout       | Assignment: `profiles/IT Helpdesk Community Login/layoutAssignments/layoutAssignments-meta.xml`, lines 260–262; highlighter: `layouts/Case-Support T2 Layout.layout`, line 22.        |
| `Porting_In_IVN_Global_Office`                 | Layout       | Assignment: same profile file, lines 156–158; highlighter: `layouts/Case-Porting - In IVN%2FGlobal Office.layout`, line 15.                                                           |
| `Porting_In_RC`                                | Layout       | Assignment: same profile file, lines 152–154; highlighter: `layouts/Case-Porting - In %28RC%29.layout`, line 15.                                                                      |
| `Porting_In_RC_AU`                             | Layout       | Assignment: same profile file, lines 136–138; highlighter: `layouts/Case-Porting - In %28RC AU%29.layout`, line 15.                                                                   |
| `Porting_In_RC_EU`                             | Layout       | Assignment: same profile file, lines 144–146; highlighter: `layouts/Case-Porting - In %28RC EU%29.layout`, line 15.                                                                   |
| `RCC_Issues`                                   | Layout       | Assignment: same profile file, lines 268–270; highlighter: `layouts/Case-Support T3 Layout.layout`, line 22.                                                                          |
| `RCLEC`                                        | Layout       | Assignment: same profile file, lines 184–186; highlighter: `layouts/Case-RCLEC Layout.layout`, line 36.                                                                               |
| `Support_Customer_ebonding`                    | Layout       | Assignment: `profiles/ProServ -Lightning/layoutAssignments/layoutAssignments-meta.xml`, lines 40–42; highlighter: `layouts/Case-Proserv Support - Customer ebonding.layout`, line 19. |
| `Support_Glip`                                 | Layout       | Assignment: `profiles/IT Helpdesk Community Login/layoutAssignments/layoutAssignments-meta.xml`, lines 248–250; highlighter: `layouts/Case-Support T1 Layout.layout`, line 34.        |
| `Support_Implementation_Escalation`            | Layout       | Assignment: same profile file, lines 232–234; highlighter: `layouts/Case-Support Implementation Escalation Layout.layout`, line 34.                                                   |
| `Support_Lead_Team`                            | Layout       | Assignment: same profile file, lines 236–238; highlighter: `layouts/Case-Support Lead Team.layout`, line 33.                                                                          |
| `Support_Subpoena_Request`                     | Layout       | Assignment: same profile file, lines 244–246; highlighter: `layouts/Case-Support Subpoena Layout.layout`, line 18.                                                                    |
| `Support_VIPFR`                                | Layout       | Assignment: same profile file, lines 276–278; highlighter: `layouts/Case-Support VIIPFR Layout.layout`, line 34.                                                                      |
| `Support_Voicemail`                            | Layout       | Assignment: same profile file, lines 252–254; highlighter: `layouts/Case-Support T1 Layout %28Agent%29.layout`, line 35.                                                              |

### Additional highlighter candidates that SF Master does not conclusively map

SF Master contains highlighter-bearing layouts whose names strongly correspond to other support record types—for example AT&T, ATOS, Alcatel, Charter, DT, Frontier, MCM, Purolator, Vodafone, Office of the President, and Fraud Investigation. However, no explicit profile/record-type layout assignment for these pairs is present in the checkout. They should be confirmed in DevGSS before being called “record types that have the highlighter.” Layout-name similarity alone is not an assignment.

Examples of the unmapped layout evidence include:

- `layouts/Case-Support - AT%26T with Case Tagging.layout`, line 23.
- `layouts/Case-Support - ATOS with Case Tagging.layout`, line 19.
- `layouts/Case-Support - Charter with Case Tagging.layout`, line 20.
- `layouts/Case-Support- Frontier with Case Tagging.layout`, line 19.
- `layouts/Case-Office of the President Cases.layout`, line 34.
- `layouts/Case-Support Fraud Layout.layout`, line 34.

## Support-related Case record-type inventory in SF Master

### Active definitions present in `objects/Case/recordTypes`

Using a broad, reproducible definition—API name, label, or description contains “Support,” plus adjacent customer-support types (`Developer_Platform`, `Product_Platform_Issues`, `RCC_Issues`, `Reseller_VAR_Partners`, `Partners_Escalations`, and `GSP_Escalation`)—the checkout contains these 38 active definitions:

`Chargeback_Support`, `Close_Loop_Feedback_Medallia_SupportSurvey`, `Deal_And_Order_Support`, `Developer_Platform`, `Extended_Enterprise_Support`, `GSP_Escalation`, `Partners_Escalations`, `Product_Platform_Issues`, `RCC_Issues`, `RISE_Partner_Support`, `Reseller_VAR_Partners`, `Support_APBA`, `Support_ATOS`, `Support_AT_T`, `Support_Avaya`, `Support_Billing`, `Support_Case`, `Support_Charter`, `Support_Charter_SMB`, `Support_Chat`, `Support_DT`, `Support_Ecotel`, `Support_Frontier`, `Support_Integrations`, `Support_MCM`, `Support_Purolator`, `Support_QoS`, `Support_RCEV_T2`, `Support_RC_App`, `Support_T1`, `Support_T1_VAR_Partners`, `Support_T2`, `Support_T3`, `Support_Telus`, `Support_VIPFR`, `Support_Verizon`, `Support_Versatel`, and `Support_Vodafone`.

Each corresponding file under `objects/Case/recordTypes/` contains `<active>true</active>` and a `<label>` element. All 12 currently in-scope types are included in this active-definition set.

### Referenced support record types with no definition file in the checkout

The following 39 support-named API values appear in application or profile metadata but have no corresponding file under `objects/Case/recordTypes/`:

`IT_Deskside_Support`, `RingShuffle_Support`, `Support_Alcatel`, `Support_CV`, `Support_Customer_Compliance`, `Support_Customer_ebonding`, `Support_DSAT`, `Support_DirectCustomer`, `Support_Email`, `Support_Engineering`, `Support_Executive_Response_Team`, `Support_Fax_Broadcast`, `Support_FeedBack`, `Support_Fraud_Investigation`, `Support_Glip`, `Support_IA_Inbound`, `Support_Implementation_Escalation`, `Support_Lead_Team`, `Support_Manager`, `Support_Mobile`, `Support_Office_of_the_President`, `Support_Offline_Case`, `Support_PS`, `Support_Premium_Escalation`, `Support_Queue_Management`, `Support_Red_Account`, `Support_Reports_Team`, `Support_Shipping_Failed_Address_Verification`, `Support_Shipping_Rec_RMA`, `Support_Snap`, `Support_Social_Media`, `Support_Subpoena_Request`, `Support_System_Ops`, `Support_T1_Shipping`, `Support_TalkToRCMgmt`, `Support_TechAssist`, `Support_Telecom_Ops`, `Support_Training_Request`, and `Support_Voicemail`.

These may be valid production record types omitted from the retrieval, deleted/stale references, or types defined outside this checkout. Their active status cannot be inferred from SF Master.

## Metadata limitations and assumptions

- The source tree contains 47 Case record-type definition files, while app/profile metadata references 162 distinct Case record-type API names. Source control is therefore not a complete record-type catalog.
- `objects/Case/recordTypes/Partners_Escalations.recordType-meta.xml` is not well-formed XML (`mismatched tag` at line 377), although its readable header contains `<active>true</active>` and its label. This is additional evidence that the checkout should not be treated as deploy-ready authoritative metadata without validation.
- Explicit layout assignments are absent for many profile/record-type pairs. A `force:detailPanel` page cannot be classified without that missing assignment.
- Only desktop (`Large`) overrides are counted as confirmed gaps. Mobile behavior differs because `Sofia_Support_Cases` contains `force:recordDetailPanelMobile`.
- Visualforce page/class access was not used as proof of rendering. Permission enables access but does not place the component on the page.
- The 22 out-of-scope record types are a conservative “present in at least one proven path” list, not proof that every user sees the highlighter for those types.
- Live sandbox metadata should be used to resolve the 483 unknown combinations, verify whether the 39 referenced-only record types still exist and are active, and confirm the additional layout-name candidates.
