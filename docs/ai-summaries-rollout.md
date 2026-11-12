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
