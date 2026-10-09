# Opportunity Summary PDF download

The existing modal offers **Download PDF** after a successful summary. It exports
the in-memory display model, including cached results, without calling GCP,
refreshing, writing Salesforce Files, or changing the request payload. Closing
the modal, refreshing, navigating to another record, or disconnecting cancels a
pending download. Errors are retryable and do not discard the displayed summary.

## Document contents

- Opportunity name (optional UI API field, record ID fallback) and record link.
- Original summary-received timestamp and separate export timestamp, both UTC.
- Current stage explicitly labelled **Stage at export**.
- Deal score and every existing summary section, including additional sections.
- Exact configured AI research disclaimer whenever enrichment is present.
- Public Research Used with internal evidence links and labelled source links.
- Additional Company Updates, even when collapsed, with its relationship helper,
  date classifications, people, relevance, actions, and associated sources.
- Other sources, search queries, page numbering and an AI-generated footer.

## Implementation

`opportunitySummaryPdf.js` builds a text-based document from the existing normalized
view models. It supports basic bold/italic markup and entities, but never executes
HTML or passes response objects directly to the PDF engine. Only HTTP(S) URLs
without credentials become link annotations. Raw grounding URLs are not link text.

`opportunitySummaryPdfDownload.js` loads three scripts from the
`PdfRenderer` static resource on the first Download PDF click, in this
order: `lws-global-this.js` (project shim), unmodified pinned **pdfmake 0.2.23**,
and its Roboto `vfs_fonts.js`. The renderer is reused for later downloads. Each
`platformResourceLoader` stage has a 30-second timeout; rendering has a separate
60-second timeout and uses pdfmake's callback API. A failed load is retryable:
the next attempt adds `?attempt=N` to every script URL. No runtime CDN, external
PDF service, remote fonts/images, or privileged LWS trusted mode is used.
Downloads use `application/pdf` Blob URLs, revoked after 60 seconds, rather than
data URIs.

## Lightning Web Security findings

Established in DevGss on 2026-10-07 with a temporary probe component, since
deleted:

- Code that LWS evaluates for `loadScript` runs in strict mode with
  `typeof globalThis === "undefined"`. Top-level `this` and `self` are the
  namespace's sandboxed window, and `new Function("return this")()` is
  `undefined`. LWC module code also sees no `globalThis`.
- pdfmake's bundled global lookup therefore returns `undefined`, and its entry
  module throws this while initializing:
  `TypeError: Cannot read properties of undefined (reading 'pdfMake')`.
  LWS logs nothing to the console and rejects `loadScript` with `undefined`.
  Stock jsPDF 4.2.1 fails the same way.
- After a URL fails, any later `loadScript` of that URL never settles. A missing
  file never settles either. The earlier `connectedCallback` preload silently
  used up the first rejection, so every click waited for the timeout.
- Resource retrieval, script size (1.4-1.8 MB test scripts) and `vfs_fonts.js`
  were not the problem.
- Setting `self.globalThis = self` first fixes initialization. The shim only
  changes the calling namespace's sandbox window, and only when `globalThis` is
  missing. With it, the unmodified renderer loaded in under 100 ms and rendered
  the summary in about 180 ms in DevGss.

`test/opportunitySummaryPdf.lws.test.mjs` evaluates the real vendored files under
these rules. It reproduces the DevGss error without the shim and renders a PDF
with it. The loader tests use a `loadScript` mock with the observed LWS
behavior (rejecting with `undefined`, and failed URLs never settling again).

The document has selectable text, embedded fonts, source/evidence links and
automatic page breaks. It is not a screenshot or a pixel-exact modal copy. Bundled
Roboto covers Latin, Greek and Cyrillic; CJK, Arabic and other writing systems need
additional fonts/shaping verification. This is not a certified tagged PDF/PDF-UA
export. The UI button, status and errors are screen-reader accessible.

Downloads are independent snapshots: cache expiry, refresh and later permission
changes cannot revoke a saved file. Users must handle customer/deal information
appropriately. Library provenance and licenses are retained in the static resource.

## Components

- Modified LWC bundle: `opportunitySummary`.
- New static resource: `PdfRenderer` (approximately 1.9 MB unpacked).
- 23 new UI labels, prefixed `OpportunitySummaryPdf`: `Download`, `Preparing`,
  `Error`, `Started`, `Title`, `Snapshot`, `Exported`, `Record`, `Footer`, `Stage`,
  `Score`, `Executive`, `History`, `Win`, `Risk`, `Actions`, `Plan`, `Research`,
  `Supplemental`, `Sources`, `Searches`, `Relevance`, `Action`.

No Apex, endpoint, cache policy, enrichment toggle, or GCP changes. Deploy the
bundle, static resource and new labels together when approved. Preserve any
admin-configured values of previously deployed labels.

## Verification

```sh
npm run test:unit -- -- --runInBand --runTestsByPath force-app/main/default/lwc/opportunitySummary/__tests__/opportunitySummary.test.js force-app/main/default/lwc/opportunitySummary/__tests__/opportunitySummaryConfig.test.js force-app/main/default/lwc/opportunitySummary/__tests__/opportunitySummaryPdf.test.js force-app/main/default/lwc/opportunitySummary/__tests__/opportunitySummaryPdfDownload.test.js
node --test test/opportunitySummaryPdf.engine.test.mjs test/opportunitySummaryPdf.lws.test.mjs
npx eslint force-app/main/default/lwc/opportunitySummary/*.js force-app/main/default/lwc/opportunitySummary/__tests__/*.js
```

The Node 22+ engine tests use the actual vendored renderer/fonts and verify PDF
structure, embedded fonts, links and long-document pagination. Set
`OPPORTUNITY_PDF_PREVIEW_PATH` to a temporary `.pdf` path for a synthetic preview.

Validation performed: 117 focused LWC tests, actual-renderer tests, headless Chrome
Blob/PDF generation, visual inspection, Unicode text extraction with PDFKit, and
Salesforce check-only compilation (`0AfTH00000IHY1J0AX`). The LWC bundle, static
resource, and 23 new labels were deployed to DevGss on 2026-10-07
(`0AfTH00000INShB0AX`). The LWS callback-renderer fix and pdfmake 0.2.23 resource
were deployed in `0AfTH00000INSxJ0AX` after the 0.3.11 promise did not settle in
the DevGss Lightning runtime. Eager initialization and bounded static-resource
loading were deployed in `0AfTH00000INT6z0AH` after the loader itself was observed
remaining pending when started by the Download PDF click. Neither change fixed
the real cause, the missing `globalThis` (see Lightning Web Security findings).
The shim, on-click loading and fresh-URL retries were deployed in
`0AfTH00000INU1R0AX`. Retrieved files match source, apart from the trailing
newline Salesforce strips. Local checks for that deploy: 119 focused Jest tests,
4 Node renderer/LWS-boundary tests, ESLint and Prettier.

Before release, smoke-test downloading inside the target org's Lightning Web
Security environment and supported browsers. Local browser tests and check-only
compilation do not prove LWS runtime compatibility or mobile download behavior.

## References

- [Salesforce third-party libraries](https://developer.salesforce.com/docs/platform/lwc/guide/js-third-party-library)
- [Salesforce Blob downloads](https://developer.salesforce.com/docs/platform/lightning-components-security/guide/lws-blob-download.html)
- [pdfmake browser API](https://pdfmake.github.io/docs/0.3/getting-started/client-side/methods/)
