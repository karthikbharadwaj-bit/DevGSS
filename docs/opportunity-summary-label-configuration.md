# Opportunity Summary Custom Label configuration

All 80 labels live in `force-app/main/default/labels/OpportunitySummary.labels-meta.xml`. Find them in Setup → Custom Labels by the `OpportunitySummary` prefix or the `OpportunitySummary.Configuration` / `OpportunitySummary.UI` categories. The 23 PDF-specific UI labels are listed in [PDF export](opportunity-summary-pdf-export.md).

Every name below has the prefix `OpportunitySummary`. For example, `CacheHours` means `OpportunitySummaryCacheHours`. Defaults preserve the current behavior. Endpoint routing, enrichment enablement, on-demand generation and modal opening, loading cadence, panel defaults, and Beta presentation are unchanged.

## Numeric configuration

| Label suffix           | Default | Accepted values                        |
| ---------------------- | ------- | -------------------------------------- |
| `CacheHours`           | 1       | Browser cache hours: 0.0167-24         |
| `CacheMaxKB`           | 512     | Browser cache KiB: 1-512               |
| `TimeoutSeconds`       | 120     | GCP timeout seconds: 1-120             |
| `ActivityDays`         | 180     | Activity lookback days: 1-365          |
| `ClosedCaseMonths`     | 6       | Closed case lookback months: 1-24      |
| `RecentDays`           | 90      | Recent evidence days: 1-365            |
| `MaxActivities`        | 50      | Tasks and events cap EACH: 1-50        |
| `MaxHistoryRows`       | 50      | Stage and field history cap EACH: 1-50 |
| `MaxOpenCases`         | 50      | Open case cap: 1-50                    |
| `MaxClosedCases`       | 50      | Closed case cap: 1-50                  |
| `MaxRelatedOpps`       | 25      | Related opportunities cap: 1-25        |
| `MaxLineItems`         | 50      | Line item cap: 1-50                    |
| `MaxStakeholders`      | 25      | Stakeholder cap: 1-25                  |
| `MaxConversationItems` | 10      | Conversation evidence cap: 1-10        |

Values are plain numeric text without units. Cache hours may be fractional (minimum one minute, maximum 24 hours); all other numeric values are positive integers. Missing, malformed, zero, negative, fractional integer values and values above the documented maximum use the original default. Record caps can be lowered; the original ceilings remain in code to protect payload size and heap.

`MaxActivities` applies separately to Tasks and Events. `MaxHistoryRows` applies separately to stage history and tracked-field history. The cache cap is a fixed KiB budget over the Opportunity Summary entries available in browser localStorage, including their keys, using UTF-16 size estimation. It is not a measurement of ten percent of browser quota. Entries too large to cache still render normally. TTL is checked when reading/cleaning storage; it does not automatically regenerate an already displayed summary.

Do not translate technical labels. Apex explicitly reads their `en_US` values. LWC imports resolve labels for the current language, so technical label translations must not be created. UI text labels can be translated normally. Reload the Lightning page after label changes; already loaded JavaScript does not hot-reload imported labels.

## Recent-days migration

`OpportunitySummaryRecentDays` replaces runtime reads of `GCP_Feature_Toggle__c.Opportunity_Summary_Recent_Days__c`. The old field is retained, but edits to it no longer affect this flow. The new label defaults to 90. Before a future deployment, review any org/profile/user overrides of the old setting and choose the desired single shared label value; Custom Labels do not preserve hierarchy-setting overrides.

`Enable_Opportunity_Summary__c` and `Enable_Opportunity_Summary_Enrichment__c` continue using their existing feature settings and company-identity checks.

## Structured configuration

- `UnresolvedNames`: one excluded account name per line. Matching trims whitespace, ignores case and removes duplicates. Blank configuration uses the existing five-name fallback.
- `GenericEmailDomains`: one bare domain per line (no scheme or path). Matching trims whitespace, ignores case and removes duplicates. Blank or malformed configuration falls back to the existing fourteen-domain list.
- `ResearchGroups`: JSON array with `kind`, `label`, optional integer `order`, and optional Boolean `active`. `kind` must be unique after lowercasing and contain letters, digits, underscores or hyphens, starting with a letter. Labels must be nonblank. Unknown kinds become supported by adding an entry. Disabled groups are omitted. Invalid JSON, an empty array, duplicate kinds or invalid fields restore the two original groups.

Example research configuration:

```json
[
  {
    "kind": "leadership",
    "label": "Current Leadership",
    "order": 1,
    "active": true
  },
  {
    "kind": "priority",
    "label": "Company Direction and Priorities",
    "order": 2,
    "active": true
  },
  {
    "kind": "expansion",
    "label": "Expansion Updates",
    "order": 3,
    "active": true
  }
]
```

Custom Label values must fit within 1,000 characters. Research group order controls only Public Research Used; supplemental updates retain their independent display and source associations. This label configures response rendering, not which kinds GCP generates.

## UI labels

| Label suffix         | Default text                                                                                                                                                                                                                      |
| -------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Loading1`           | Gathering opportunity details and stage history…                                                                                                                                                                                  |
| `Loading2`           | Reviewing recent activities, tasks, and meetings…                                                                                                                                                                                 |
| `Loading3`           | Mapping the buying group and stakeholder engagement…                                                                                                                                                                              |
| `Loading4`           | Checking related cases and prior opportunities on this account…                                                                                                                                                                   |
| `Loading5`           | Securing sensitive details with advanced protection checks…                                                                                                                                                                       |
| `Loading6`           | Activating Gemini to score deal health, risks, and win factors…                                                                                                                                                                   |
| `Loading7`           | Shaping your next best actions and close plan…                                                                                                                                                                                    |
| `Loading8`           | Almost there — assembling your decision-ready summary.                                                                                                                                                                            |
| `ResearchDisclaimer` | AI-generated company research — This information was found and summarized using AI and public web search. It may be incomplete or inaccurate. Verify important details and sources before using it in customer or deal decisions. |
| `SearchLimitation`   | Google Search Suggestions aren’t shown because Lightning Web Security sanitizes HTML and SVG strings inserted into the DOM. Showing the supplied markup would change it.                                                          |
| `GenericError`       | We're having trouble generating this summary right now. Please try again later.                                                                                                                                                   |
| `ServerError`        | We're experiencing a temporary issue with summary generation. Please contact your administrator if this continues.                                                                                                                |
| `EmptyMessage`       | No summary is available for this opportunity yet.                                                                                                                                                                                 |
| `MissingRecord`      | No opportunity record is available.                                                                                                                                                                                               |
| `SupplementalHelper` | These public company updates were not linked to the current opportunity by the AI analysis.                                                                                                                                       |
| `ResearchHelper`     | Public information used to enrich this opportunity summary. Public signals do not prove customer requirements, budget, buying intent, or decision authority.                                                                      |
| `WorkingEyebrow`     | Request in flight                                                                                                                                                                                                                 |
| `WorkingTitle`       | Building your opportunity brief                                                                                                                                                                                                   |
| `WorkingHint`        | You can keep working                                                                                                                                                                                                              |
| `ErrorEyebrow`       | Summary interrupted                                                                                                                                                                                                               |
| `ErrorTitle`         | We couldn’t finish this request                                                                                                                                                                                                   |
| `RetryButton`        | Try Again                                                                                                                                                                                                                         |
| `ReadyEyebrow`       | Ready to review                                                                                                                                                                                                                   |
| `ReadyTitle`         | Your opportunity summary is ready                                                                                                                                                                                                 |
| `ReadyHint`          | Open whenever you’re ready.                                                                                                                                                                                                       |
| `ViewButton`         | View Summary                                                                                                                                                                                                                      |
| `IdleEyebrow`        | Decision-ready deal intelligence                                                                                                                                                                                                  |
| `IdleTitle`          | Build a fresh opportunity brief                                                                                                                                                                                                   |
| `IdleHint`           | Review deal health, risks, stakeholder context, and recommended next steps while continuing to work on this record.                                                                                                               |
| `GenerateButton`     | Generate Summary                                                                                                                                                                                                                  |
| `RefreshButton`      | Refresh Opportunity Summary                                                                                                                                                                                                       |
| `PoweredBy`          | Powered by                                                                                                                                                                                                                        |
| `GeneratedNow`       | Generated just now                                                                                                                                                                                                                |
| `GeneratedMinute`    | Generated {0} minute ago                                                                                                                                                                                                          |
| `GeneratedMinutes`   | Generated {0} minutes ago                                                                                                                                                                                                         |
| `GeneratedHour`      | Generated {0} hour ago                                                                                                                                                                                                            |
| `GeneratedHours`     | Generated {0} hours ago                                                                                                                                                                                                           |
| `Elapsed`            | {0} elapsed                                                                                                                                                                                                                       |
| `ErrorIcon`          | Error                                                                                                                                                                                                                             |
| `ReadyIcon`          | Ready                                                                                                                                                                                                                             |

`GeneratedMinute`, `GeneratedMinutes`, `GeneratedHour`, `GeneratedHours`, and `Elapsed` use `{0}` for the number or elapsed clock. Preserve that placeholder when editing or translating. Loading messages remain eight ordered messages with the existing 3.9-second cadence; they are time-based narration, not backend progress notifications.

## Verification

```sh
npm run test:unit -- -- --runInBand --runTestsByPath force-app/main/default/lwc/opportunitySummary/__tests__/opportunitySummary.test.js force-app/main/default/lwc/opportunitySummary/__tests__/opportunitySummaryConfig.test.js
```

The LWC tests load the deployable label defaults and cover configured TTL/budget, fallback validation, configurable research groups and UI text, source handling, and the existing on-demand flow. `GCPCalloutForOpportunitySummaryTest` covers numeric/list parsing, identity exclusions, the recent-days migration, and configurable activity/conversation caps.

Deploy the label metadata together with both Apex classes and the entire `opportunitySummary` bundle when the changes are approved. No custom setting fields need to be added. Existing request and response field names are unchanged.
