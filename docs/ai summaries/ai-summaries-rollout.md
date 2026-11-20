# AI Account / Opportunity Summary: org-wide rollout notes

Read-only findings from BisUAT and DevGSS (`adlc-sandbox`), 2026-11-12. Nothing was changed in either org.
SF Master was pulled to latest; it lags BisUAT (no `aiAccountSummary` in any flexipage).

## Visibility needs four things

1. Component on the page the user is routed to (`aiAccountSummary`, `opportunitySummary`).
2. Flexipage rule `{!$Permission.CustomPermission.AI_Reporting_Access}` = true (comes from permission set `AI_Reporting_Tool`).
3. `GCP_Feature_Toggle__c` hierarchy setting on (`Enable_Account_Summary__c`, `Enable_Opportunity_Summary__c`); resolution is user, then profile, then org default.
4. Apex class access (`GCPCalloutFor*Summary`, `AISummaryController`), granted by `AI_Reporting_Tool` (and the System Administrator profile).

## Conclusions

- RC Sales Lightning has no Account/Opportunity overrides for the target profiles. They fall back to the org-default pages, which already carry the new components in BisUAT. A beta test with the org-wide toggles on showed the listed users could see both components without page edits.
- The Sales app routes profiles to other pages (`Sales_Accounts`, `Sales_Opportunity`, ...), so it needs flexipage edits: 32 pages (20 Account, 12 Opportunity).
- The permission set is mostly in place. The remaining blockers for a full rollout are the toggle and the users missing the permission set.
- Rollout levers: (a) org-wide toggle on, or profile-level rows for a controlled rollout; (b) bulk-assign `AI_Reporting_Tool` to users missing it; (c) fix user-level toggle rows that override profile or org values.
- Existing toggle rows: BisUAT has 94 and DevGSS has 138, including user-level rows that would override an org-wide change.

## User counts (active standard users)

|                            | BisUAT | DevGSS |
| -------------------------- | ------ | ------ |
| Profiles with active users | 110    | 101    |
| Active users               | 4,290  | 4,264  |
| With `AI_Reporting_Tool`   | 3,801  | 3,566  |
| Missing it                 | 489    | 698    |

Largest profiles (full list by query: users per profile, joined to `PermissionSetAssignment`):

| Profile                                         | BisUAT active | BisUAT with PS | DevGSS active | DevGSS with PS |
| ----------------------------------------------- | ------------- | -------------- | ------------- | -------------- |
| Sales Rep - Lightning                           | 381           | 364            | 231           | 219            |
| WWFS Rep - Lightning                            | 240           | 237            | 218           | 191            |
| Sales Operations Lightning                      | 88            | 81             | 84            | 74             |
| Channel Operations - Lightning                  | 29            | 29             | 25            | 24             |
| Expansion - Lightning                           | 205           | 201            | 307           | 257            |
| Sales Engineer Lightning                        | 121           | 118            | 126           | 117            |
| Channel Sales - Lightning                       | 127           | 127            | 121           | 106            |
| System Administrator                            | 310           | 284            | 75            | 35             |
| Support T1 - EU Restricted                      | 236           | 230            | 363           | 294            |
| Professional Services Lightning - EU Restricted | 167           | 162            | 172           | 166            |
| Support Implementations - EU Restricted         | 95            | 94             | 215           | 195            |
| Support Back Office - EU Restricted             | 166           | 163            | 132           | 126            |
| Support T2 - EU Restricted                      | 109           | 105            | 180           | 177            |
| Deal Desk Lightning                             | 160           | 153            | 138           | 135            |
| Marketing User AD Auth                          | 169           | 166            | 122           | 103            |
| ProServ -Lightning - EU Restricted              | 134           | 130            | 143           | 97             |
| Signature - CSM Lightning                       | 84            | 82             | 153           | 129            |
| Finance Admin - EU Restricted                   | 118           | 113            | 98            | 83             |

Profiles with little or no permission set coverage (BisUAT / DevGSS): No Access (1 of 47 / 0 of 53), Com Integration Profile (0 of 32 / 0 of 20), OPS Member (0 of 16 / 0 of 33), OPS Member - EU Restricted (2 of 34 / 0 of 20), Signature - ICSM Lightning - EU Restricted (2 of 43 / 0 of 13), No Access (API) (0 of 33 / 0 of 5).

## Open items

- Decide the scope for "all users": include or exclude EU Restricted, service/integration profiles and `No Access` profiles.
- Decide whether the Sales app is in scope (page edits) or only RC Sales.
- Confirm the org-default page assignment (not readable via API) in each org.
- DevGSS routing was not re-checked for this note, only user and permission set counts.

## Pages with the existing summaries (SF Master, `master` at 33b7d83cdb7, 2026-11-12)

Pages holding `accountAISummary` or `opportunityAISummary`; the new components go on the same pages.
Totals: 24 Account and 16 Opportunity pages (13 + 7 non-EU, 11 + 9 EU Restricted).
The new `opportunitySummary` is already on `Sales_Opportunities_Lite` and `GSS_Opportunities_ProServ`.
`aiAccountSummary` is on no page in master.

**Account pages (`accountAISummary`)**

- Non-EU (13): `ATT_Account`, `Account_Record_Page2`, `Finance_Admin_Accounts_Default`, `GSSProserv_Accounts`, `GSS_Accounts_CSM`, `GSS_Accounts_Proserv`, `GSS_Accounts_Support_T2`, `Legal_Team_Accounts_Default`, `Marketing_Accounts`, `Sales_Account_MPUB_Data_Model`, `Sales_Accounts`, `Sales_Accounts_CERT_Winback`, `ZI_Customer_Shell_Accounts`
- EU Restricted (11): `EU_Restricted_Account_Default_Page`, `EU_Restricted_Account_Gereric_Page`, `EU_Restricted_GSS_Accounts_Support_T2`, `EU_Restricted_Sales_Accounts`, `EU_Restricted_ZI_Customer_Shell_Accounts`, `Finance_Admin_Accounts_Default_EU_Restricted`, `GSSProserv_Accounts1_EU_Restricted`, `GSS_Accounts_CSM_EU_Restricted`, `GSS_Accounts_Proserv_EU_Restricted`, `Legal_Team_Accounts_Default_EU_Restricted`, `Marketing_Accounts_EU_Restricted`

**Opportunity pages (`opportunityAISummary`)**

- Non-EU (7): `GSS_Opportunities_ProServ` (new component present), `GSS_Opportunities_ProServ_FinanceAdmin`, `Legal_Team_Opportunities_Default`, `Marketing_Opportunity`, `Proserv_Sales_Opportunity`, `Sales_Opportunities_Lite` (new component present), `Sales_Opportunity`
- EU Restricted (9): `EU_Restricted_Opportunity_Generic_Page`, `EU_Restricted_Sales_Opportunity`, `GSS_Opportunities_EU_RestrictedSupport`, `GSS_Opportunities_ProServ1_EU_Restricted`, `GSS_Opportunities_ProServ_FinanceAdmin_EU_Restricted`, `Legal_Team_Opportunities_Default_EU_Restricted`, `Marketing_Opportunity_EU_Restricted`, `Proserv_Sales_Opportunity1_EU_Restricted`, `Sales_Opportunities_Lite_EU_Restricted`

To add: `aiAccountSummary` on all 24 Account pages (23 if `Account_Record_Page2` already has it in prod; it does in BisUAT), `opportunitySummary` on 14 more Opportunity pages (16 less the 2 that have it), subject to the EU Restricted scope decision.

## Prod: profiles that get access (handover for testing)

Source: prod analysis Google Doc "AI Summaries: Org-wide Rollout Analysis (Prod)", run 2026-11-12 (org ID 00D80000000aRUXEA2). Counts are active standard users.
Rule: a profile is included when at least one active user holds `AI_Reporting_Tool`. Users on included profiles who do not hold it are ignored (no visibility without `AI_Reporting_Access`).
Pages: the components go on the pages that hold `accountAISummary` / `opportunityAISummary` (list above).

### Cardinality

| Measure                                                                | Count                                                                            |
| ---------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| Profiles with active standard users                                    | 98                                                                               |
| Profiles included (at least one holder)                                | 77 (42 standard, 35 EU Restricted)                                               |
| Profiles excluded (no holder)                                          | 21                                                                               |
| Active standard users                                                  | 3,874                                                                            |
| Users who get access (hold the permission set, on an included profile) | 3,616 (2,027 standard, 1,589 EU Restricted)                                      |
| Users ignored on included profiles (no permission set)                 | 135 (51 standard, 84 EU Restricted)                                              |
| Users on excluded profiles                                             | 123                                                                              |
| Total without `AI_Reporting_Tool`                                      | 258 (135 + 123)                                                                  |
| Active user toggle rows to update (Opportunity off)                    | 3,416 of 3,421 (5 keep Opportunity on)                                           |
| Profile toggle rows: update existing / create in scope                 | 4 / 42 (EU Restricted profile rows are a separate decision)                      |
| Pages to edit (existing summary component present)                     | 24 Account + 14 Opportunity (2 Opportunity pages already have the new component) |

### Excluded profiles (21, no users with the permission set)

- No Access (45 users) and No Access (API) (29 users).
- 13 integration and API profiles (43 users in total).
- Terminated User (1 user).
- GSP Sales, Operations, SE Manager, Service Engineer - Manager, Business Services - Advanced - EU Restricted (1 user each).

### Standard profiles (42 profiles, 2,027 users)

| Profile                             | Users with `AI_Reporting_Tool` | Active users on profile |
| ----------------------------------- | ------------------------------ | ----------------------- |
| Expansion - Lightning               | 285                            | 291                     |
| Signature - CSM Lightning           | 207                            | 221                     |
| Sales Rep - Lightning               | 197                            | 199                     |
| WWFS Rep - Lightning                | 189                            | 189                     |
| Deal Desk Lightning                 | 123                            | 123                     |
| Sales Engineer Lightning            | 107                            | 107                     |
| Marketing User AD Auth              | 90                             | 101                     |
| Sales Operations Lightning          | 89                             | 92                      |
| Channel Sales - Lightning           | 88                             | 89                      |
| Support Porting Cases Users Only    | 84                             | 84                      |
| GSP Sales Rep                       | 81                             | 81                      |
| Finance Admin                       | 57                             | 59                      |
| Support Back Office                 | 49                             | 49                      |
| CRM Support Engineer                | 38                             | 38                      |
| Support T2                          | 38                             | 38                      |
| Channel Sales Manager - Lightning   | 35                             | 35                      |
| Marketing Admin AD Auth             | 34                             | 35                      |
| OPS Member                          | 34                             | 34                      |
| Support T1                          | 25                             | 25                      |
| ProServ -Lightning                  | 23                             | 23                      |
| Professional Services Lightning     | 23                             | 24                      |
| Channel Operations - Lightning      | 22                             | 22                      |
| System Administrator                | 19                             | 24                      |
| Support - TAM                       | 11                             | 12                      |
| Support T3                          | 11                             | 11                      |
| Global Operations                   | 8                              | 8                       |
| Legal Team AD Auth                  | 8                              | 8                       |
| Sales 4.0 inContact Order Lightning | 8                              | 8                       |
| Support Fraud Investigation         | 7                              | 8                       |
| Support Implementations             | 7                              | 7                       |
| Support Operations                  | 5                              | 5                       |
| Restricted System Administrator     | 4                              | 4                       |
| Service Engineer - Agent            | 4                              | 4                       |
| Support Porting Shipping            | 4                              | 5                       |
| CRM QA Engineer                     | 3                              | 3                       |
| Deal Desk                           | 2                              | 2                       |
| Read Only                           | 2                              | 3                       |
| Sales Agent SDR w Insidesales       | 2                              | 2                       |
| Avaya - Report Access               | 1                              | 1                       |
| Business Services - Advanced        | 1                              | 1                       |
| Business Services - Basic           | 1                              | 2                       |
| Restricted Profile - LP (RUL)       | 1                              | 1                       |
| **Total (42 profiles)**             | **2027**                       | **2078**                |

### EU Restricted profiles (35 profiles, 1,589 users; scope decision pending)

| Profile                                             | Users with `AI_Reporting_Tool` | Active users on profile |
| --------------------------------------------------- | ------------------------------ | ----------------------- |
| Support T1 - EU Restricted                          | 319                            | 331                     |
| Support Implementations - EU Restricted             | 209                            | 213                     |
| Support T2 - EU Restricted                          | 206                            | 206                     |
| Professional Services Lightning - EU Restricted     | 158                            | 160                     |
| CERT - Lightning - EU Restricted                    | 120                            | 129                     |
| ProServ -Lightning - EU Restricted                  | 102                            | 112                     |
| Support Back Office - EU Restricted                 | 96                             | 97                      |
| Finance Admin - EU Restricted                       | 89                             | 100                     |
| Support T3 - EU Restricted                          | 71                             | 71                      |
| Support Operations - EU Restricted                  | 51                             | 51                      |
| Support - TAM - EU Restricted                       | 28                             | 28                      |
| Sales Rep - Lightning - EU Restricted               | 20                             | 26                      |
| Legal Team AD Auth - EU Restricted                  | 16                             | 17                      |
| OPS Member - EU Restricted                          | 16                             | 17                      |
| Sales Engineer Lightning - EU Restricted            | 16                             | 17                      |
| Signature - ICSM Lightning - EU Restricted          | 11                             | 11                      |
| ERT Lightning - EU Restricted                       | 10                             | 10                      |
| CRM Support Engineer - EU Restricted                | 7                              | 7                       |
| Marketing User AD Auth - EU Restricted              | 7                              | 7                       |
| ICSM Lightning - EU Restricted                      | 5                              | 12                      |
| Support Porting Shipping - EU Restricted            | 5                              | 5                       |
| Sales Operations Lightning - EU Restricted          | 4                              | 5                       |
| Support Fraud Investigation - EU Restricted         | 4                              | 4                       |
| WWFS Rep - Lightning - EU Restricted                | 4                              | 4                       |
| Sales 4.0 inContact Order Lightning - EU Restricted | 3                              | 5                       |
| Business Services - Basic - EU Restricted           | 2                              | 8                       |
| Sales Director 3.0 - EU Restricted                  | 2                              | 2                       |
| Channel Sales - Lightning - EU Restricted           | 1                              | 3                       |
| Deal Desk Lightning - EU Restricted                 | 1                              | 5                       |
| Global Operations - EU Restricted                   | 1                              | 1                       |
| OPS Manager - EU Restricted                         | 1                              | 2                       |
| Operations - EU Restricted                          | 1                              | 4                       |
| Sales 4.0 inContact Order - EU Restricted           | 1                              | 1                       |
| Sales Manager - Business Processing - EU Restricted | 1                              | 1                       |
| Support Manager - KB - EU Restricted                | 1                              | 1                       |
| **Total (35 profiles)**                             | **1589**                       | **1673**                |

### Beta users in prod (profile differs from the sandboxes)

Bill Farmer: WWFS Rep - Lightning. Cody Turner and Michael Throssel: CRM Support Engineer. Adam Walworth: Sales Engineer Lightning. Molly Bohon: WWFS Rep - Lightning - EU Restricted. These 5 are the only active users with Opportunity on in prod today.
