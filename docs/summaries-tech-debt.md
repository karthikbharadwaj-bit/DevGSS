# Opportunity and Account Summary: open tech debt

Items that need someone with Setup access, a product decision, or another team.
The component trackers (`account-summary-components.csv` and
`opportunity-summary-components-since-4a375fc.csv`) hold the per-component history.

## Needs Setup access in DevGss

These deletes are blocked through the API ("Requires Extra Verification") and have
to be done by hand in Setup.

- [ ] Delete `GCP_Feature_Toggle__c.IsAccountSummaryEnabled__c` and
      `GCP_Feature_Toggle__c.IsAccountSummaryEnrichmentEnabled__c`. They were
      named wrongly and were replaced by the `Enable_Account_Summary*` fields (deploy
      0AfTH00000IMjP70AL); nothing reads them.
- [ ] Delete `GCP_Endpoint_Settings__c.AccountSummaryEndpoint__c`. It was the first,
      wrongly named version and has been unused since deploy 0AfTH00000IJDSE0A5.
      This one exists in DevGss only.
- [ ] **Tests cannot create users in DevGss.** The managed `Dimelo__User_sync` process
      fails every User insert, for every profile including System Administrator. The
      existing `Test_AccountSelector` tests fail there the same way, while user-creating
      tests pass in BisUAT and GCI. Until the Engage Digital user sync is configured or
      turned off in DevGss, `Test_GCPSummaryUtil.shouldRemoveFieldWhenRunningUserCannotReadIt`
      can only be checked in GCI or BisUAT.

## Deferred from the MR !63735 review (2026-10-15)

- [ ] **Look-back windows and row caps are class constants.** The 90-day account history
      and 30-day upcoming events windows, and the 16 `*_LIMIT` caps in
      `GCPCalloutForAccountSummary`, are not in `Summary_Setting__mdt`. They are sized to
      the service's input budget, so changing them needs the GCP service team. The
      closed-case window now reads `ClosedCaseMonths__c` (default 6, capped at 24), the
      same setting Opportunity Summary uses.
- [ ] **Screen readers can still browse behind the summary modals.** Both modals now move
      focus in on open, keep Tab inside, and return focus to View summary on close
      (`c/lwcModalFocus`). A component cannot hide the rest of the Lightning page, so a
      screen reader's browse mode can still read it. Moving both modals to
      `LightningModal` fixes that; it was judged too large a change for this MR.
- [ ] **Automated senders are matched by `CreatedBy.Name`.** The names come from
      `ExcludedActivityCreators__c`, so a rename is a metadata edit. Usernames carry a
      per-sandbox suffix and IDs differ per org, so neither works as a single value.
- [ ] **`GCPCalloutForAccountSummary` holds payload building and the callout.** Splitting it
      into a helper and a thin `@AuraEnabled` entry point should be done for both summary
      callouts together.
- [ ] **Underscores in `Summary_Setting__mdt` and the `Enable_Account_Summary*` toggles.** The
      naming rule wants `SummarySetting__mdt` and `Is*` checkboxes. Neighbouring objects use
      the same pattern; renaming means redeploying both repos.
- [ ] **No server-side check of `AI_Reporting_Access`.** `AI_Reporting_Tool` is the only
      permission set with class access, and the only one carrying the permission (checked in
      DevGss and BisUAT on 2026-10-15). In DevGss the System Administrator profile also has
      class access, so admins can call it without the permission. Add a check if another
      permission set or profile is given access to `GCPCalloutForAccountSummary`.

## Needs a decision

- [ ] **Who can run Account Summary.** `AI_Reporting_Tool` got Apex access to
      `GCPCalloutForAccountSummary` on 2026-10-13 in DevGss, matching Opportunity Summary.
      `Support_Agent_AI_Assist_Access` still has Opportunity Summary only; decide whether it
      should get Account Summary too. Source has only a partial `AI_Reporting_Tool` (the two
      callout class accesses), because every permission set retrieve from DevGss fails
      with `UNKNOWN_EXCEPTION` (-494916924).
- [x] **Where Account Summary appears.** `Account_Record_Page2` (the default Account page
      for RC Sales View and System Administrator) shows `aiAccountSummary` at the top of the
      sidebar since 2026-10-14, for users with the `AI_Reporting_Access` custom permission.
- [ ] **Unused Opportunity field.** `GCP_Feature_Toggle__c.Opportunity_Summary_Recent_Days__c`
      is no longer read by Opportunity Summary. Keep it or delete it (a Setup delete).
- [ ] **Google Search Suggestions in the Opportunity PDF.** The modal shows them and the
      PDF leaves them out. Check whether Google's grounding terms require them wherever
      grounded results are shown, including exported files.
- [ ] **Old deployment record.** `docs/opportunity-summary-devgss-deployment-2026-09-28.csv`
      is deleted in the working copy but not committed. Commit the delete or restore the
      file.
- [ ] **Tracker gaps.** Several Opportunity tracker rows have no Developer, and the
      baseline fields (`Enable_Opportunity_Summary_Enrichment__c`,
      `Opportunity_Summary_Recent_Days__c`) have unverified deployment dates.

## Needs release planning for other orgs

- [ ] The PDF renderer static resource was renamed from `OpportunitySummaryPdf` to
      `PdfRenderer` (DevGss deploy 0AfTH00000IPBnY0AX). In every other org, deploy
      `PdfRenderer` together with `opportunitySummary` and `aiAccountSummary`, then delete
      `OpportunitySummaryPdf` in a separate destructive deploy (DevGss used
      0AfTH00000IPI5p0AH). Salesforce will not delete it while a deployed LWC still
      imports it.
- [ ] Never delete `PdfRenderer` when rolling back only one summary; both load it.
- [ ] The new `lwcPdfRenderer` service component must deploy in the same deploy as
      `opportunitySummary` and `aiAccountSummary`, since both import it (DevGss
      0AfTH00000IPIU10AP). The same rollback rule applies: keep it while either summary
      is deployed.
- [ ] Sixteen Account labels left over from the old fallback tiles were deleted from DevGss
      with a destructive deploy (0AfTH00000IPHPu0AP). Orgs that received them need the
      same delete: `AccountSummaryTileRenewal`, `…RenewalPast`, `…Activity`,
      `…GoingCold`, `…ClosedWon`, `…ClosedWonDetail`, `…RevenueAtRisk`,
      `…OpenEscalations`, `…Escalations`, `…RedDays`, `…NextStep`, `…Overdue`,
      `…OverdueDetail`, `…ClosedCases`, `…Dunning` and `AccountSummaryShowingCount`.

- [ ] The 28 strings both summaries show (button text, status text, errors and seven PDF
      strings) became shared `Summary*` labels in `Summary.labels-meta.xml` (DevGss deploy
      0AfTH00000IQU6X0AX). In every other org, deploy `Summary.labels-meta.xml` together
      with both feature label files, both callout classes and their tests, and both LWC
      bundles. Then delete the 56 old copies (`OpportunitySummary<Name>` and
      `AccountSummary<Name>` for the same 28 names) in a separate destructive deploy;
      DevGss used 0AfTH00000IQMdf0AH. Salesforce refuses the delete while a deployed
      component still imports an old label. Before deleting, copy any admin-edited value
      or translation of an old label onto its shared label; DevGss had none.
- [ ] The numbered loading labels became one `|`-separated label per summary:
      `AccountSummaryLoadingMessages` replaces `AccountSummaryLoading1`–`6`, and
      `OpportunitySummaryLoadingMessages` replaces `OpportunitySummaryLoading1`–`8`
      (DevGss deploy 0AfTH00000IQmoD0AT). In every other org, deploy both feature label
      files with the new `lwcLabelUtils` module and both LWC bundles first, then delete the
      14 numbered labels in a separate destructive deploy; DevGss used 0AfTH00000IQmpp0AD.
      Before deleting, join any admin-edited lines into the new label in order; a
      translation of a numbered label has to be re-entered as one `|`-separated translation.
- [ ] Three Account Summary labels repeated another label's text and were removed (DevGss
      deploy 0AfTH00000IQnSX0A1): the Owner column now uses `AccountSummaryFieldOwner`,
      the PDF title uses `AccountSummaryTitle`, and the PDF source link uses
      `AccountSummaryFieldSource`. In every other org, deploy `AccountSummary.labels-meta.xml`
      with the `aiAccountSummary` bundle, then delete `AccountSummaryColOwner`,
      `AccountSummaryPdfTitle` and `AccountSummaryPdfSourceLink` separately; DevGss used
      0AfTH00000IQnU90AL. An admin edit to a deleted label is lost, so check them first.
- [ ] Deployed to DevGss only (0AfTH00000IRh050AD; the 23 old labels were deleted there
      with 0AfTH00000IRh890AD): the 22 configuration labels moved to the new custom
      metadata type `Summary_Setting__mdt`. Each setting is a typed field (Number, or long
      text for the three lists; 19 fields), and each summary has one record:
      `AccountSummary` and `OpportunitySummary`. Lead and Deal summaries add a record and
      only the fields they don't share. `OpportunitySummaryResearchGroups` (JSON) was
      replaced by the fixed list in `opportunitySummaryConfig.js` plus two heading labels,
      `OpportunitySummaryResearchLeadership` and `OpportunitySummaryResearchPriority`.
      Deploy the type, its 19 fields and 2 records, `SummarySettingSelector`,
      `SummarySettingHelper` and `Test_SummarySettingHelper`, both feature label files,
      both callout classes and their tests, and both LWC bundles together. Then delete the
      23 old labels (6 `AccountSummary*` and 17 `OpportunitySummary*`) in a separate
      destructive deploy. Before deploying to an org, copy any admin-edited label value
      onto the matching field; DevGss values matched the repo on 2026-10-13. Users need no
      permission on the type because only Apex reads it. The pre-commit Prettier hook
      reformats `.cls` files to 2-space indentation, so check the three new classes keep 4
      spaces after committing.

## Needs a person to test in Lightning

- [ ] Click Download PDF on a few real Accounts in DevGss: a long history, no research,
      a red band, and an account with many cases. Jest and the local renders use sample
      data, and only a real browser exercises Lightning Web Security.
- [ ] Same check on a closed-won and a closed-lost Opportunity, to confirm Post-Close
      Actions prints and Win Factors, Risk Flags and Close Plan do not.
- [ ] Open both summaries with the keyboard only: focus should land on Download PDF, Tab
      and Shift+Tab should stay inside the modal, and Escape should return focus to View
      summary. Jest covers this, but not focus inside Lightning base components.

## Deferred from the 2026-10-12 standards review

These were kept as they are on purpose. Each one needs a design change, not a cleanup.

- [ ] **Numbers and JSON stored as Custom Labels.** `*TimeoutSeconds`, `*CacheHours`,
      `*ActivityDays`, `*ExcludedActivityCreators` and the list caps are settings, which
      the standards put in Custom Metadata or Custom Settings. Moving them means a new
      metadata type, a migration of admin-set values, and rewriting both technical-label
      readers.
- [ ] **Raw `HttpRequest` instead of `HttpHelper`.** Both callouts and `GCPAuthUtil` build
      the request themselves, because the endpoint and bearer token come from
      `GCPAuthUtil` rather than a Named Credential. Moving to `HttpHelper` needs a Named
      Credential for each GCP service.
- [ ] **JSON error replies.** Both `@AuraEnabled` callouts return `{success:false, message}`
      instead of an `'Error: '` string. Both LWCs parse this shape; changing it changes the
      Apex and both components together.
- [ ] **GCP payload keys are string literals.** The keys (`opportunity`, `accountWebsite`
      and so on) are the GCP contract and appear once each, so they were not turned into
      constants.
- [ ] **Field lists for the Account lists live in the callout class.** The
      `*_FIELD_TO_KEY` maps choose both the fields and their payload keys, so
      `GCPCalloutForAccountSummary` adds the fields to the selector's query. The
      standards want field lists in the selector.
- [ ] **Similar helpers that are not identical.** Only `stripReadable` and
      `readableField` matched, and they moved to `GCPSummaryUtil`. The others differ:
  - `buildServiceEndpoint`: Opportunity removes every trailing slash, Account removes one.
  - `errorJson`: Opportunity pretty-prints, Account does not.
  - The toggle getters read different `GCP_Feature_Toggle__c` fields.
  - The PDF builders' `pdfText` and heading-keep rule (see below).
- [ ] **Shared usage logger.** Both summaries now call `AISummaryController.logAIHEvent`.
      Its comment says it "will diverge soon"; if it does, give the summaries their own.
- [ ] **Opportunity test class.** It is still named `GCPCalloutForOpportunitySummaryTest`
      (the standard is `Test_GCPCalloutForOpportunitySummary`) and has no `@TestSetup`,
      because it builds records in memory. Its fake Ids now come from each object's key
      prefix instead of literals.
- [ ] **Selectors without their own test class.** `TaskSelector` and
      `OpportunityLineItemSelector` came from DevGss without one. The summary callout
      tests run every summary method on them.
- [ ] **`derived_metrics` is unused.** Account Summary passes it through to the LWC,
      which never reads it.

## Can be done on request (no access or decision needed)

- [ ] **Shared PDF building blocks.** Both document builders still carry their own copy of
      the HTML-to-text converter (`pdfText`) and the rule that keeps headings with their
      content. They cannot move into `lwcPdfRenderer` yet: the Node renderer tests import
      `opportunitySummaryPdf.js` directly and cannot resolve `c/` imports. Moving them
      needs a module alias for those tests first.
- [ ] **Renderer test names.** `test/opportunitySummaryPdf.engine.test.mjs` and
      `test/opportunitySummaryPdf.lws.test.mjs` now test the shared `PdfRenderer`
      resource; rename them to match.
