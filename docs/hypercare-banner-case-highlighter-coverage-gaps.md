# Hypercare Banner — Case Highlighter Coverage Gaps

| Metadata     | Details                                                                                  |
| ------------ | ---------------------------------------------------------------------------------------- |
| Tickets      | PBC-33679 (analysis), PBC-33680 (development), PBC-33684 (GCI QA), LTR-3534 (initiative) |
| BRD          | Hypercare Case Highlights (revision 0.0, signed off 15 May 2026)                         |
| Environments | GCI and BisUAT sandboxes; SF Master branch                                               |
| Prepared by  | Karthik Bharadwaj, 15 October 2026                                                       |

## 1. Executive summary

- **Implementation approach:** The Hypercare banner is embedded within the existing `CaseHighlighter` Visualforce page and will surface only where that page is currently rendered.
- **Coverage gaps:** Most support users see the highlighter across the 12 in-scope record types. However, some profiles view cases on Lightning pages or layouts that omit it, preventing banner visibility.
- **Key impacted areas:** The primary gaps affect:
  - Support T1 and T2 profiles using the `Sofia_Support_Cases` page.
  - Almost all profiles viewing Extended Enterprise Support and Support - Integrations cases.
  - Hypercare/TAM users viewing Extended Enterprise Support cases.
- **Out-of-scope precedents:** Several record types outside the current 12 in-scope types already include the highlighter. They will not receive the banner if implementation is restricted strictly to the specified list.
- **Permissions:** All support profiles have Visualforce page access; permissions are not a blocker.

## 2. Record types in scope

The BRD does not limit the banner by record type; it states that the banner applies to all cases for Hypercare accounts. The following 12 record types were provided by Niki Martschinske in a comment on LTR-3534 on 7 October 2026 and are pending review by James Cai. All 12 are active in GCI, BisUAT, and DevGSS with matching IDs.

| Record type label             | API name                      |
| ----------------------------- | ----------------------------- |
| Support - T1                  | `Support_T1`                  |
| Support - T1 (VAR & Partners) | `Support_T1_VAR_Partners`     |
| Support - T2                  | `Support_T2`                  |
| Support-RCEV-T2               | `Support_RCEV_T2`             |
| Support - T3                  | `Support_T3`                  |
| Support-Case                  | `Support_Case`                |
| Support - Chat                | `Support_Chat`                |
| Support - QoS                 | `Support_QoS`                 |
| Support - Integrations        | `Support_Integrations`        |
| Support-RC App                | `Support_RC_App`              |
| Product / Platform Issues     | `Product_Platform_Issues`     |
| Extended Enterprise Support   | `Extended_Enterprise_Support` |

## 3. Technical rendering logic

Highlighter visibility is determined dynamically by the combination of the user's profile, active app context (RC Service or Lightning Service), and Case record type. Salesforce resolves that combination to determine the assigned layout or Lightning page.

| Rendering mode    | Behavior                                                                                                                                           | Result                                                           |
| ----------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| Directly embedded | The Lightning page embeds the Visualforce page directly. Examples include most `GSS_Cases_*` pages, ERT, Fraud, Telus, Partner, and EU Restricted. | Banner displays                                                  |
| Via page layout   | The Lightning page loads the standard Record Detail component and relies on the assigned page layout's composition.                                | Banner displays only if the layout includes the Visualforce page |
| Omitted           | The assigned Lightning page includes neither the Visualforce component nor a Record Detail layout containing it.                                   | Banner is hidden                                                 |

> **Note:** Permission sets and roles govern Visualforce page access, which is already active for all support profiles. They do not influence page layout or Lightning page assignment logic.

## 4. Detailed coverage-gap analysis

The analysis below reflects the configurations verified in the GCI and BisUAT environments.

| Gap area            | Record types                                               | Affected profiles                                                                             | Root cause                                                                                                                                            |
| ------------------- | ---------------------------------------------------------- | --------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| Sofia page          | Support - T1; Support - T2                                 | Support T1 and Support T2 in RC Service and Lightning Service                                 | Assigned the `Sofia_Support_Cases` Lightning page, which lacks both the component and a layout embed. The page is present in GCI, BisUAT, and Master. |
| Extended Enterprise | Extended Enterprise Support                                | Support Back Office, Operations, TAM, Implementations (EU), ProServices, Sales Engineer       | Assigned the generic Case Layout or Internal Business Services Layout, both of which omit the highlighter component.                                  |
| Integrations        | Support - Integrations                                     | Approximately 75% of users: ProServices, Implementations, Operations, ICSM EU, Sales Engineer | Assigned the generic Case Layout.                                                                                                                     |
| CSM pages           | Support - T1, T1 VAR, T2, T3, RC App                       | Signature - CSM, ICSM EU Restricted                                                           | Assigned `GSS_Cases_CSM` or `CSM_Case_Page_LM`; both lack the highlighter.                                                                            |
| Sales layout        | Support-RCEV-T2, RC App, Extended Enterprise, Integrations | Sales Engineer Lightning (Standard and EU Restricted)                                         | Assigned the Case - Sales Lightning layout, which lacks the highlighter.                                                                              |
| EU Restricted       | Extended Enterprise Support; Support - Integrations        | Support T1/T2 EU Restricted                                                                   | The banner renders in RC Service but not in Lightning Service because of layout assignments.                                                          |

Core support profiles—Support T1, T2, T3, TAM, Operations, and Back Office—render the highlighter in both apps for every in-scope record type except those listed above. None of these gaps are caused by permissions; each is caused by the assigned Lightning page or page layout.

## 5. Out-of-scope record types with an active highlighter

The BRD requests the banner on all cases for Hypercare accounts. The following record types already show the Case Highlighter but are not in the 12-type list. If the banner is limited to that list, Hypercare accounts with cases under these types will not show the banner, contradicting the BRD's “all cases” statement.

- **Escalation and executive:** Support - Executive Response Team, Support - Office of the President, Support - Red Account, Support - VIPFR.
- **Specialized support:** Support - T1 (Shipping), Support - Implementation Escalation, Support - Fraud Investigation, Developer Platform, RISE Partner Support.
- **Carrier and partner channels:** Telus, AT&T, ATOS, Avaya, Alcatel, Charter, Frontier, MCM, DT, Purolator, Vodafone, NWNC.

**Recommendation:** Strongly evaluate Executive Response Team and Office of the President for inclusion because Hypercare accounts frequently escalate through these channels.

## 6. Options to close the gaps

The BRD limits the change to the `CaseHighlighter` Visualforce page. With Option A alone, all gaps in Section 4 remain. Options B through D close specific gaps but require changes to Lightning pages or layouts, making them follow-up work outside the current BRD.

| Option                                         | Coverage scope                                                                                   | Effort and impact                                                               |
| ---------------------------------------------- | ------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------- |
| **A. Code change only (current BRD scope)**    | The banner renders only where the highlighter exists today. The gaps in Section 4 remain.        | No layout changes. Technical gaps must be accepted and documented.              |
| **B. Update Sofia page**                       | Adds the highlighter to `Sofia_Support_Cases`, covering core Support T1/T2 users.                | One Lightning page update. Outside the current BRD; requires a follow-up item.  |
| **C. Update CSM and Sales pages**              | Extends coverage to CSM, ICSM, and Sales Engineer profiles.                                      | Multiple page/layout updates; needed only if these personas require visibility. |
| **D. Fix Enterprise and Integrations layouts** | Assigns a support layout containing the highlighter, or removes the two record types from scope. | Changes to the generic Case Layout affect a wider, non-support user base.       |

### Suggested path

Deliver Option A under the current BRD and share Section 4 with the business so the gaps are known. If the business wants gaps closed, Option B covers the largest group of users with one page change. Options C and D can be raised as follow-up items.

Keep the record-type list in a Custom Label so the scope can change without a code deployment.

### 6.1 Field rename coverage

Renaming **Hyper Care** to **Hypercare** changes only the field label, not its API name. The new label appears automatically wherever the field is shown:

- Account Support T2 page layout.
- Support TAM page layout.
- Accounts with Cases report type.
- Accounts with Opportunities and Deal Supports report type.

None of these use a custom display name, so the rename leaves no gaps. Only saved reports in which someone manually renamed the column would continue to show the old text.

## 7. Open questions and captured responses

| Topic                          | Question                                                                                                                                                                                                                                           | Response/status                                                                           |
| ------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| Target profiles                | Which profiles, permission sets, or roles must see the banner, and are any explicitly excluded? The BRD does not specify this and puts permission updates out of scope, so the effective audience is everyone who sees the Case Highlighter today. | Anyone who can access a case containing the highlight banner should be able to access it. |
| Brand scope                    | Which brands or sub-brands are in scope or excluded?                                                                                                                                                                                               | No brand restriction; any case worked by Support within RingCentral.                      |
| Field-renaming scope           | Do any saved reports with manually renamed columns need to be updated?                                                                                                                                                                             | Check internally. The business concern is only the label shown on the page layout.        |
| Sofia page                     | Does the business want the `Sofia_Support_Cases` gap closed as follow-up work (Option B), or is a known launch gap acceptable?                                                                                                                     | Open                                                                                      |
| Extended/Integrations scope    | Should layout assignments be fixed through Option D, or should Extended Enterprise Support and Support - Integrations be removed from scope?                                                                                                       | Open                                                                                      |
| Auxiliary profiles             | Should CSM, ICSM, and Sales Engineer profiles require Hypercare banner visibility through Option C?                                                                                                                                                | Out of scope                                                                              |
| Hypercare team profiles        | Which profiles do Hypercare managers use in production? If they use Support - TAM, they will not see the banner on Extended Enterprise Support cases.                                                                                              | Open                                                                                      |
| High-priority escalation types | Should Executive Response Team and Office of the President be added to the in-scope record-type list?                                                                                                                                              | Open                                                                                      |
| Banner stacking                | What is the intended display order when multiple highlighter banners trigger on a case?                                                                                                                                                            | Place the Hypercare banner at the top of the Case Highlighter banners.                    |
| Acceptance-criteria alignment  | PBC-33680 AC 6 and PBC-33684 currently state that visibility is independent of record type. Should the acceptance criteria be updated to specify the 12 record types?                                                                              | Open                                                                                      |
| Record-type confirmation       | Has James Cai confirmed the 12 record types listed on LTR-3534?                                                                                                                                                                                    | Not yet confirmed                                                                         |

## 8. Verification methodology and scope

### Sandbox audits: GCI and BisUAT

Verified:

- Profile-to-layout assignments across all 12 record types.
- Lightning page assignments in the RC Service and Lightning Service apps.
- Presence of the `CaseHighlighterPage` component.
- Profile and permission-set access.
- Active user counts.

### Source-control audit: SF Master

Cross-checked Lightning page compositions, app page assignments, and page access settings.

### Caveats and testing notes

User counts were derived from sandbox environments for relative sizing. Production assignments should be verified in the console during QA execution.

## Developer checklist

- Perform a three-way analysis of profile → layout → record type to identify combinations that do not include the Case Highlighter.
- Provide the combinations in which users cannot see the highlight banner.
- Compile the record types that have the Case Highlighter but are not in scope.
