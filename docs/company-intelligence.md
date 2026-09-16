# Company Intelligence

Company Intelligence is a dedicated `companyIntelligence` LWC for Opportunity record pages. It is exposed to `lightning__RecordPage` and can be placed directly below the existing Opportunity Summary component in Lightning App Builder. The Opportunity Summary component and its Apex contract are unchanged.

## Opportunity Summary architecture reused

- The dedicated component reuses the existing SLDS card and loading-state conventions without coupling its lifecycle to Opportunity Summary.
- Authentication reuses `GCPAuthUtil`: the `opportunitySummary` environment setting supplies the Cloud Run endpoint, service account, certificate, token URL, and audience. No endpoint, username, token, or credential is stored in source.
- The existing selector layer queries the Opportunity and Account, followed by `Security.stripInaccessible` before request construction.
- The callout uses the same authenticated JSON POST pattern. The configured host is retained and the request path is replaced with `/api/v1/company_intelligence`.
- Service errors are converted into safe, label-backed UI messages. Raw bodies and exceptions are neither logged nor returned.
- Company Intelligence loads once when its record-page component initializes, exposes an independent refresh action, and coalesces duplicate lifecycle or refresh calls.

The Opportunity Summary Apex request and response contract is unchanged.

## Request mapping

| Service field | Salesforce source | Rule |
| --- | --- | --- |
| `username` | `UserInfo.getUserName()` | Always sent; never accepted from the browser. |
| `company_name` | `Account.Name` | Required. Missing or unreadable data produces a safe 400 result. |
| `company_url` | `Account.Website` | Omitted when blank. |
| `address` | Available Account billing street, city, state, postal code, and country | Nonblank parts are joined in that order; omitted when all are blank. |
| `additional_context.industry` | `Account.Industry` | Omitted when blank. |
| `additional_context.opportunity_type` | `Opportunity.Type` | Omitted when blank. |

Serialization suppresses null optional fields. Contact names, email addresses, phone numbers, record IDs, and other personal data are not included.

## Grounding and Search Suggestions

Sources are joined to claims by `sources[].index`, not array position. The UI displays only `display_label`; each HTTPS `url` remains the hidden target of a new-tab link with `noopener noreferrer`. Search queries are placed in a collapsed diagnostic section.

The backend preserves `search_entry_point.rendered_content` exactly. The LWC does not inject or rewrite it because Lightning Web Security sanitizes inserted HTML and its allowlist does not permit the complete Google-supplied style/SVG bundle. Whenever markup is returned, the UI reports this limitation explicitly.

## POC placement and access

- Add `Company Intelligence` to the applicable Opportunity Lightning record page directly below Opportunity Summary. No FlexiPage metadata is tracked in this repository, and DevGss currently reports four pages that reference `opportunitySummary` (`GSS_Opportunities_ProServ`, `Sales_Opportunities_Lite`, `Sales_Opportunities_Lite_EU_Restricted`, and `EU_Restricted_Sales_Opportunity`). The POC therefore exposes the component without guessing which org-owned page should be imported and changed.
- No permission set, custom permission, or new custom setting is included for this POC. Test users still need Apex class access through their existing profile or administrator-managed access.
- The POC reuses the existing `GCP_Endpoint_Settings__c` Opportunity Summary configuration and JWT signing certificate. The configured Cloud Run service must expose `/api/v1/company_intelligence` on the same host.
- No new Named Credential or CSP Trusted Site metadata is introduced. Source links are browser navigation targets, not browser resource requests.
