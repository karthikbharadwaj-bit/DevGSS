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

## Needs a decision

- [ ] **Who can run Account Summary.** Only System Administrator has Apex access to
      `GCPCalloutForAccountSummary`. Opportunity Summary is granted through
      `AI_Reporting_Tool` and `Support_Agent_AI_Assist_Access`. Decide whether the same
      permission sets should get Account Summary.
- [ ] **Where Account Summary appears.** `Account_Record_Page2` (the default Account page
      for RC Sales View and System Administrator) has not been retrieved or changed,
      so the component is not placed on it yet.
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

## Needs a person to test in Lightning

- [ ] Click Download PDF on a few real Accounts in DevGss: a long history, no research,
      a red band, and an account with many cases. Jest and the local renders use sample
      data, and only a real browser exercises Lightning Web Security.
- [ ] Same check on a closed-won and a closed-lost Opportunity, to confirm Post-Close
      Actions prints and Win Factors, Risk Flags and Close Plan do not.

## Can be done on request (no access or decision needed)

- [ ] **Shared PDF building blocks.** Both document builders still carry their own copy of
      the HTML-to-text converter (`pdfText`) and the rule that keeps headings with their
      content. They cannot move into `lwcPdfRenderer` yet: the Node renderer tests import
      `opportunitySummaryPdf.js` directly and cannot resolve `c/` imports. Moving them
      needs a module alias for those tests first.
- [ ] **Renderer test names.** `test/opportunitySummaryPdf.engine.test.mjs` and
      `test/opportunitySummaryPdf.lws.test.mjs` now test the shared `PdfRenderer`
      resource; rename them to match.
