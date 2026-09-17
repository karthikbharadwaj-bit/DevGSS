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

| Service field                         | Salesforce source                                                       | Rule                                                                 |
| ------------------------------------- | ----------------------------------------------------------------------- | -------------------------------------------------------------------- |
| `username`                            | `UserInfo.getUserName()`                                                | Always sent; never accepted from the browser.                        |
| `company_name`                        | `Account.Name`                                                          | Required. Missing or unreadable data produces a safe 400 result.     |
| `company_url`                         | `Account.Website`                                                       | Omitted when blank.                                                  |
| `address`                             | Available Account billing street, city, state, postal code, and country | Nonblank parts are joined in that order; omitted when all are blank. |
| `additional_context.industry`         | `Account.Industry`                                                      | Omitted when blank.                                                  |
| `additional_context.opportunity_type` | `Opportunity.Type`                                                      | Omitted when blank.                                                  |

Serialization suppresses null optional fields. Contact names, email addresses, phone numbers, record IDs, and other personal data are not included.

## Grounding and Search Suggestions

Sources are joined to claims by `sources[].index`, not array position. The UI displays only `display_label`; each HTTPS `url` remains the hidden target of a new-tab link with `noopener noreferrer`. Search queries are placed in a collapsed diagnostic section.

The backend preserves `search_entry_point.rendered_content` exactly. The LWC does not inject or rewrite it because Lightning Web Security sanitizes inserted HTML and its allowlist does not permit the complete Google-supplied style/SVG bundle. Whenever markup is returned, the UI reports this limitation explicitly.

## Client-side cache behavior

The POC stores successful Company Intelligence responses in `localStorage` for
24 hours. Failures are not cached. Lightning Web Security partitions Web
Storage by Salesforce namespace, and the component additionally scopes every
entry by the current Salesforce user and Opportunity:

```text
companyIntelligence:v1:<salesforce-user-id>:<opportunity-id>
```

`v1` is the cache schema version. It is not a TTL or Opportunity number. A
future incompatible cache structure can use `v2` rather than attempting to
parse entries written in the earlier format.

The cache has the following behavior:

- A page load uses a valid cached response without invoking Apex or making an
  external callout.
- The Refresh button always bypasses the cached response and makes a fresh
  callout. A successful refresh replaces that Opportunity's cache entry. A
  failed refresh leaves the previous cached entry available for a later page
  load.
- Expired, malformed, and future-dated entries are ignored and removed.
- Storage access and quota failures do not prevent a fresh response from being
  displayed.
- The entire Company Intelligence cache is capped at 512 KiB, approximately
  one tenth of the conventional 5 MiB `localStorage` allowance. The size
  calculation includes keys and values using their UTF-16 representation.
- When adding an entry would exceed the cap, the oldest Company Intelligence
  entries are removed first. Storage belonging to other features is not
  touched.
- A single response larger than 512 KiB is displayed but is not cached.

### Multiple Opportunities for the same company

The cache can hold separate entries for multiple Opportunities. With the
current Opportunity-scoped key, opening another Opportunity makes a new
callout even when both Opportunities belong to the same Account. Subsequent
loads of each Opportunity can then reuse their respective cached response.

This conservative behavior prevents Opportunity-specific context—especially
`Opportunity.Type` and the generated Opportunity Relevance section—from being
reused for a different sales motion. The cache stores only the latest response
for each user and Opportunity; it is not a history or audit log.

## Open points for business confirmation

1. **Cache reuse boundary:** Should intelligence be cached per Opportunity
   (current behavior), per Account and Opportunity Type, or per Account only?
2. **Same-Account reuse:** Should two Opportunities for the same Account and
   the same Opportunity Type share one response? This would reduce callouts
   while retaining the most important opportunity-specific input.
3. **Opportunity-specific relevance:** If Account-level reuse is preferred,
   is it acceptable for Opportunity Relevance to have been generated using a
   different Opportunity's type or context? If not, the Account-level and
   Opportunity-level portions should be requested or cached separately.
4. **Freshness window:** Is a fixed 24-hour TTL acceptable, or should the TTL
   vary by section or user action?
5. **Data-change invalidation:** Should changes to Account name, website,
   address, industry, or Opportunity type invalidate the cache immediately?
   The POC currently relies on the TTL or manual Refresh.
6. **Refresh failure behavior:** Should a failed manual refresh retain the last
   successful cached result (current behavior), or remove it?
7. **Storage policy:** Is browser-local storage acceptable for this public
   company intelligence, or should the production implementation move to
   Platform Cache or a server-side cache?
8. **Eviction expectations:** Is oldest-first eviction within the 512 KiB cap
   acceptable, given that the number of Opportunities retained depends on the
   size of each response?

## POC placement and access

- `Company Intelligence` is placed directly below Opportunity Summary on the
  `GSS_Opportunities_ProServ` Opportunity Lightning record page. Its FlexiPage
  metadata is tracked locally.
- No permission set, custom permission, or new custom setting is included for this POC. Test users still need Apex class access through their existing profile or administrator-managed access.
- The POC reuses the existing `GCP_Endpoint_Settings__c` Opportunity Summary configuration and JWT signing certificate. The configured Cloud Run service must expose `/api/v1/company_intelligence` on the same host.
- No new Named Credential or CSP Trusted Site metadata is introduced. Source links are browser navigation targets, not browser resource requests.
