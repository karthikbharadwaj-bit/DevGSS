# Hypercare Banner — DevGSS live coverage audit

## Paste-ready conclusion

The DevGSS three-way analysis of **profile → Case page layout → record type**, joined to the SF Master desktop Lightning app/page assignments, identifies **112 desktop app/profile/record-type combinations where the existing `CaseHighlighterPage` is not rendered** for the 12 proposed in-scope record types.

The largest gaps are:

- **Sales Engineer Lightning - EU Restricted:** all 12 in-scope record types are missing the highlighter in each of RC Service, Lightning Service, RC Sales Lightning, Lightning Sales, and Lightning Sales Console (**60 combinations**).
- **Extended Enterprise Support:** its DevGSS layout omits the highlighter for all 23 reviewed support/auxiliary profiles. Where the app page uses Record Detail, the banner cannot render.
- **Sofia page:** Support T1 and Support T2 users cannot see the highlighter for `Support_T1` or `Support_T2` in RC Service or Lightning Service (**8 combinations**).
- **CSM page:** Signature - CSM Lightning cannot see it for `Support_T1`, `Support_T1_VAR_Partners`, `Support_T2`, `Support_T3`, or `Support_RC_App` in RC Sales View (**5 combinations**).
- **Support Integrations:** the DevGSS layout omits the highlighter for 15 of the 23 reviewed profiles, including Support T2, Support Operations, Support Implementations, ProServ, Sales Engineer, CSM/ICSM, and Operations variants.

DevGSS also has **72 active out-of-scope Case record types with at least one live profile-to-layout assignment to a layout that contains `CaseHighlighterPage`**. Of these, **42 are support-related or closely adjacent**. This means restricting the new Hypercare condition to the proposed 12-record-type list will exclude many Case types whose current UI already has a valid highlighter surface.

## Confirmed in-scope desktop gaps

Each row below is a group of combinations. The count is the number of app/profile/record-type permutations represented by the row.

| App(s)                                                                                      | Profile                                                                                  | Record types without the Case Highlighter                                                                                                    | Resolved page                                                              |   Count |
| ------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------- | ------: |
| RC Service; Lightning Service                                                               | Support T1                                                                               | `Support_T1`, `Support_T2`                                                                                                                   | `Sofia_Support_Cases`                                                      |       4 |
| RC Service; Lightning Service                                                               | Support T2                                                                               | `Support_T1`, `Support_T2`                                                                                                                   | `Sofia_Support_Cases`                                                      |       4 |
| RC Sales View                                                                               | Signature - CSM Lightning                                                                | `Support_T1`, `Support_T1_VAR_Partners`, `Support_T2`, `Support_T3`, `Support_RC_App`                                                        | `GSS_Cases_CSM`                                                            |       5 |
| RC Service; Lightning Service; RC Sales Lightning; Lightning Sales; Lightning Sales Console | Sales Engineer Lightning - EU Restricted                                                 | All 12 in-scope record types                                                                                                                 | `EU_Restricted_Case_Generic_Page` or `Sales_Cases_Lightning_EU_Restricted` |      60 |
| RC Sales Lightning                                                                          | ICSM Lightning - EU Restricted                                                           | `Support_T1`, `Support_T1_VAR_Partners`, `Support_T2`, `Support_T3`, `Support_RC_App`, `Support_Integrations`, `Extended_Enterprise_Support` | `EU_Restricted_Case_Generic_Page`                                          |       7 |
| RC Sales Lightning                                                                          | ProServ -Lightning - EU Restricted                                                       | `Support_Integrations`, `Extended_Enterprise_Support`                                                                                        | `EU_Restricted_Case_Generic_Page`                                          |       2 |
| RC Sales Lightning                                                                          | Support T2 - EU Restricted                                                               | `Support_T2`, `Support_Integrations`, `Extended_Enterprise_Support`                                                                          | `EU_Restricted_Case_Generic_Page`                                          |       3 |
| RC Sales Lightning                                                                          | Support T3 - EU Restricted                                                               | `Support_T3`, `Extended_Enterprise_Support`                                                                                                  | `EU_Restricted_Case_Generic_Page`                                          |       2 |
| RingCentral Admin Lightning                                                                 | Support Back Office - EU Restricted                                                      | `Extended_Enterprise_Support`                                                                                                                | `EU_Restricted_Case_Generic_Page`                                          |       1 |
| Dimelo Console Lightning; Dimelo Lightning; DocuSign for Salesforce Core                    | Support T1 - EU Restricted                                                               | `Support_T1`                                                                                                                                 | `EU_Restricted_GSS_Cases_Support_T1_Updated`                               |       3 |
| Preconfigured Lightning Service Console                                                     | Support - TAM; Support - TAM EU; Support Back Office; Support Back Office EU; Support T1 | `Extended_Enterprise_Support`                                                                                                                | `CaseDefault_Record_Page`                                                  |       5 |
| Preconfigured Lightning Service Console                                                     | Support Operations; Support Operations EU; Support T2                                    | `Extended_Enterprise_Support`, `Support_Integrations`                                                                                        | `CaseDefault_Record_Page`                                                  |       6 |
| Preconfigured Lightning Service Console                                                     | Support T1 - EU Restricted                                                               | `Extended_Enterprise_Support`, `Support_Chat`, `Support_T1`                                                                                  | `CaseDefault_Record_Page`                                                  |       3 |
| Preconfigured Lightning Service Console                                                     | Support T2 - EU Restricted                                                               | `Extended_Enterprise_Support`, `Support_Integrations`, `Support_T2`                                                                          | `CaseDefault_Record_Page`                                                  |       3 |
| Preconfigured Lightning Service Console                                                     | Support T3; Support T3 - EU Restricted                                                   | `Extended_Enterprise_Support`, `Support_T3`                                                                                                  | `CaseDefault_Record_Page`                                                  |       4 |
| **Total**                                                                                   |                                                                                          |                                                                                                                                              |                                                                            | **112** |

### Why these combinations fail

- `Sofia_Support_Cases`, `GSS_Cases_CSM`, and `Sales_Cases_Lightning_EU_Restricted` neither embed `CaseHighlighterPage` nor render the desktop `force:detailPanel`; a highlighter-bearing page layout therefore cannot rescue those pages.
- The other listed pages use `force:detailPanel`. Their visibility is controlled by the live DevGSS profile/record-type layout assignment. For the listed combinations, the resolved layout does not contain `CaseHighlighterPage`.
- `GSS_Cases_CSM` contains `caseBannerForMod`, but that is a different component and will not display a message implemented only in `CaseHighlighterPage`.

## Extended Enterprise Support and Support Integrations

These two types were the major repo-only unknowns. DevGSS resolves them as follows.

### `Extended_Enterprise_Support`

All 23 reviewed profiles resolve to one of `Case Layout`, `Internal Business Services Layout`, or `Case - Sales Lightning`; none contains `CaseHighlighterPage`:

`ICSM Lightning - EU Restricted`, `Operations`, `Operations - EU Restricted`, `ProServ -Lightning`, `ProServ -Lightning - EU Restricted`, `Sales Engineer Lightning`, `Sales Engineer Lightning - EU Restricted`, `Signature - CSM Lightning`, `Signature - ICSM Lightning - EU Restricted`, `Support - TAM`, `Support - TAM - EU Restricted`, `Support Back Office`, `Support Back Office - EU Restricted`, `Support Implementations`, `Support Implementations - EU Restricted`, `Support Operations`, `Support Operations - EU Restricted`, `Support T1`, `Support T1 - EU Restricted`, `Support T2`, `Support T2 - EU Restricted`, `Support T3`, and `Support T3 - EU Restricted`.

### `Support_Integrations`

The highlighter is absent from the live assigned layout for these 15 profiles:

`ICSM Lightning - EU Restricted`, `Operations`, `Operations - EU Restricted`, `ProServ -Lightning`, `ProServ -Lightning - EU Restricted`, `Sales Engineer Lightning`, `Sales Engineer Lightning - EU Restricted`, `Signature - CSM Lightning`, `Signature - ICSM Lightning - EU Restricted`, `Support Implementations`, `Support Implementations - EU Restricted`, `Support Operations`, `Support Operations - EU Restricted`, `Support T2`, and `Support T2 - EU Restricted`.

It is present in the assigned `Support Integrations Layout with Case Tagging` for Support T1, T3, TAM, and Back Office, including their EU Restricted variants.

## Out-of-scope record types that already have a highlighter path

### Support-related and adjacent types — 42

Each active DevGSS record type below has at least one live profile assignment to a Case layout containing `CaseHighlighterPage`. Some also have a direct highlighter-bearing FlexiPage. This proves at least one configured path, not universal visibility for every profile and app.

`Developer_Platform`, `RCC_Issues`, `RCLEC`, `RISE_Partner_Support`, `Support_APBA`, `Support_ATOS`, `Support_AT_T`, `Support_Alcatel`, `Support_Avaya`, `Support_CV`, `Support_Charter`, `Support_Charter_SMB`, `Support_Customer_Compliance`, `Support_Customer_ebonding`, `Support_DT`, `Support_DirectCustomer`, `Support_Ecotel`, `Support_Engineering`, `Support_Executive_Response_Team`, `Support_Fax_Broadcast`, `Support_FeedBack`, `Support_Fraud_Investigation`, `Support_Frontier`, `Support_Glip`, `Support_IA_Inbound`, `Support_Implementation_Escalation`, `Support_MCM`, `Support_Mobile`, `Support_Office_of_the_President`, `Support_Purolator`, `Support_Red_Account`, `Support_Shipping_Failed_Address_Verification`, `Support_Social_Media`, `Support_Subpoena_Request`, `Support_System_Ops`, `Support_T1_Shipping`, `Support_TalkToRCMgmt`, `Support_Telecom_Ops`, `Support_Telus`, `Support_VIPFR`, `Support_Versatel`, and `Support_Vodafone`.

Direct page paths in SF Master additionally confirm these UI-ready examples: `Developer_Platform`, `RISE_Partner_Support`, `Support_Avaya`, `Support_CV`, `Support_Executive_Response_Team`, `Support_Shipping_Failed_Address_Verification`, `Support_T1_Shipping`, and `Support_Telus`.

### Other active out-of-scope types — 30

`AT_T_O_H_Meetings_RCC_Issues`, `CAP_Request`, `CIF_Escalate_to_CERT`, `Close_Loop_Feedback_Medallia_Relationship`, `Engage_Order_Desk`, `Finance_Deal_Review`, `GDPR_Request`, `GSP_Escalation`, `Internal_OPS_to_OPS`, `Maintenance`, `OfficeAtHand_ATT`, `Partner_Commissions`, `Porting_In`, `Porting_In_IVN_Global_Office`, `Porting_In_Inteliquent`, `Porting_In_RC`, `Porting_In_RC_AU`, `Porting_In_RC_EU`, `Porting_In_TELUS`, `Porting_Out`, `Porting_Vanity`, `SFDC_Data_Deletion`, `SO_Compensation`, `Sales_Internal_Cases`, `Service_Engineer`, `Solutions_Engineer`, `Solutions_Engineer_APPS`, `System_Operations`, `TELUS_TRASH_RECORD_TYPE`, and `inContract_Order`.

### Support-related types with no mapped highlighter path

No live profile-to-layout assignment for these active DevGSS types resolves to a highlighter-bearing layout, and no direct highlighter-bearing app/page override was found in SF Master:

`Close_Loop_Feedback_Medallia_SupportSurvey`, `Deal_And_Order_Support`, `IT_Deskside_Support`, `Support_Billing`, `Support_Training_Request`, and `Support_Verizon`.

Treat these as strong coverage-gap candidates, not as proof for every possible UI route. `Support_Billing` has a concrete DevGSS brand-triggered Case and a Record Detail page path, so it is included in the UI validation prompt as the best representative check.

## DevGSS UI-test data status

- DevGSS contains **zero Accounts where `Hyper_Care__c = true`** and therefore zero Cases currently eligible for the proposed Hypercare condition.
- The local/SF Master `CaseHighlighter` implementation reviewed during this audit does not yet contain the new Hypercare condition.
- Existing AT&T/BT brand and escalated Cases can prove whether the highlighter surface is present or absent today.
- The exact new Hypercare message cannot be UI-validated until an authorized tester seeds or identifies a Hypercare Account and the implementation is deployed. This audit did not mutate DevGSS data.

## Evidence and limits

- Live DevGSS sources: 163 Case record types, 36,088 Tooling API `ProfileLayout` rows, 170 Case layouts, 221 profiles, active users, and Case test records queried on 21 October 2026.
- SF Master source: `/Users/Karthik.Bharadwaj/Repo/SF Master/src` at commit `c81bb25a91b6a0c27bf676a86bfaabd1b9f378d5`, used for the bodies of layouts, FlexiPages, and application overrides.
- A targeted Metadata API retrieve of app/page bodies from DevGSS did not complete within the CLI session. Consequently, live assignment names are authoritative, while app/page bodies are corroborated from the cited SF Master checkout.
- The companion browser procedure is in `docs/hypercare-banner-devgss-ui-validation-prompt.md`.
