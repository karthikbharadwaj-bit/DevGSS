/* eslint-disable no-script-url -- Deliberately malicious fixtures verify unsafe links are rejected. */
import "../../../../../../test/jest-mocks/accountSummaryLabels";
import { buildPdfDocument, pdfFilename, pdfText } from "../aiAccountSummaryPdf";
import { buildAccountViewModel } from "../aiAccountSummaryModel";
import { getUiLabels } from "../aiAccountSummaryConfig";

const RESPONSE = require("./data/accountSummaryResponse.json");
const labels = getUiLabels();
const NOW = Date.parse("2026-06-29T12:00:00Z");
const ORIGIN = "https://example.my.salesforce.com";
const RECORD_ID = "001TH00000iUv7bYAC";

function clone(value) {
  return JSON.parse(JSON.stringify(value));
}

function snapshot(response = RESPONSE, overrides = {}) {
  return {
    recordId: RECORD_ID,
    recordName: "Miles Ahead Brands, LLC",
    recordUrl: `${ORIGIN}/lightning/r/Account/${RECORD_ID}/view`,
    origin: ORIGIN,
    generatedAt: NOW - 600000,
    exportedAt: NOW,
    asOfDate: "Jun 29, 2026",
    view: clone(buildAccountViewModel(response, labels, "en-US")),
    ...overrides
  };
}

function textOf(value) {
  if (typeof value === "string") return value;
  if (Array.isArray(value)) return value.map(textOf).join(" ");
  if (!value || typeof value !== "object") return "";
  return ["text", "content", "stack", "table", "body", "ul", "ol", "columns"]
    .map((key) => textOf(value[key]))
    .join(" ");
}

function nodes(value, predicate, found = []) {
  if (Array.isArray(value)) {
    value.forEach((item) => nodes(item, predicate, found));
  } else if (value && typeof value === "object") {
    if (predicate(value)) found.push(value);
    Object.values(value).forEach((item) => nodes(item, predicate, found));
  }
  return found;
}

describe("Account Summary PDF document", () => {
  it("includes every summary section shown in the modal", () => {
    const doc = buildPdfDocument(snapshot(), labels);
    const text = textOf(doc).toLowerCase();

    [
      "Miles Ahead Brands, LLC",
      labels.pdfDataAsOf,
      "Jun 29, 2026",
      labels.sectionFlag,
      "72",
      "of 100",
      "Amber",
      "Steady",
      labels.sectionHeader,
      labels.fieldIndustry,
      labels.sectionMetrics,
      labels.tileMrr,
      labels.sectionSignals,
      "Renewal 2026 is 122 days overdue",
      "SMS Booster won Feb 2026",
      labels.sectionActions,
      "Bring the close date current",
      labels.whenToday,
      labels.laneSales,
      labels.sectionOpportunities,
      "Renewal 2026",
      labels.sectionCases,
      "Provisioning for Renewal",
      labels.sectionHistory,
      labels.openNow,
      labels.sectionContacts,
      "Jaeline Dure",
      labels.accountTeamHeading,
      "Lealyn Lacia",
      labels.sectionResearch,
      labels.researchCitedHeading,
      "Opened a new depot."
    ].forEach((value) =>
      // Eyebrow labels are styled in uppercase; presence is what matters.
      expect(text).toContain(String(value).toLowerCase())
    );
    expect(textOf(doc)).toContain(labels.researchDisclaimer);
    expect(textOf(doc)).not.toContain("<strong>");
  });

  it("links evidence references to the cited research findings", () => {
    const doc = buildPdfDocument(snapshot(), labels);
    const links = nodes(doc, (node) => Boolean(node.linkToDestination)).map(
      (node) => node.linkToDestination
    );
    const anchors = nodes(doc, (node) => /^research-/.test(node.id || "")).map(
      (node) => node.id
    );

    expect(links.length).toBeGreaterThan(0);
    links.forEach((link) => expect(anchors).toContain(link));
    expect(new Set(anchors).size).toBe(anchors.length);
  });

  it("resolves relative record links against the org", () => {
    const doc = buildPdfDocument(snapshot(), labels);
    const links = nodes(doc, (node) => typeof node.link === "string").map(
      (node) => node.link
    );

    expect(links).toContain(`${ORIGIN}/lightning/r/Account/${RECORD_ID}/view`);
    links.forEach((link) => expect(link).toMatch(/^https?:\/\//));
    expect(links.some((link) => link.startsWith(`${ORIGIN}/`))).toBe(true);
  });

  it("drops source links that are not http or https", () => {
    const response = clone(RESPONSE);
    response.account_enrichment.findings[0].sources = [
      { publisher_domain: "Unsafe", url: "javascript:alert(1)" }
    ];
    delete response.account_enrichment.findings[0].source_indices;

    const doc = buildPdfDocument(snapshot(response), labels);

    expect(JSON.stringify(doc)).not.toContain("javascript:");
  });

  it("shows the empty messages when lists are empty", () => {
    const response = clone(RESPONSE);
    const summary = response.account_summary;
    summary.risk_growth_signals = { risks: [], growth: [] };
    summary.open_opportunities = { rows: [] };
    summary.cases = { open: [], recently_closed: [] };
    summary.key_contacts = { contacts: [], account_team: [] };
    summary.account_history = [];
    delete response.account_enrichment;

    const text = textOf(buildPdfDocument(snapshot(response), labels));

    [
      labels.noRisks,
      labels.noGrowth,
      labels.noOpenOpportunities,
      labels.noOpenCases,
      labels.noClosedCases,
      labels.noContacts,
      labels.noHistory
    ].forEach((value) => expect(text).toContain(value));
    expect(text).not.toContain(labels.researchDisclaimer);
  });

  it("notes how many rows are shown when the list is longer than the summary", () => {
    const data = snapshot();
    data.view.opportunities.totalCount = 23;

    const text = textOf(buildPdfDocument(data, labels));

    expect(text).toContain(
      `Showing ${data.view.opportunities.rows.length} of 23`
    );
  });

  it("puts history last and keeps only the latest 20 events", () => {
    const data = snapshot();
    data.view.history = [
      {
        key: "open",
        periodLabel: labels.openNow,
        events: [{ key: "e-open", title: "Open renewal", date: "Feb 27, 2026" }]
      },
      ...Array.from({ length: 6 }, (unused, month) => ({
        key: `period-${month}`,
        periodLabel: `Month ${month}`,
        events: Array.from({ length: 4 }, (none, index) => ({
          key: `e-${month}-${index}`,
          title: `Event ${month}-${index}`,
          date: "Jan 1, 2026"
        }))
      }))
    ];

    const doc = buildPdfDocument(data, labels);
    const text = textOf(doc);

    expect(text).toContain("Event 4-2");
    expect(text).not.toContain("Event 4-3");
    expect(text).not.toContain("Month 5");
    expect(text).toContain("Showing 20 of 25");
    const lastHeading = doc.content
      .filter((node) => node.headlineLevel === 1 && node.stack)
      .map((node) => textOf(node))
      .pop();
    expect(lastHeading).toContain(labels.sectionHistory);
  });

  it("tags routing steps only when the text does not already say the kind", () => {
    const data = snapshot();
    data.view.flag.routing = [
      { key: "r1", kind: "NOTIFY", text: "Notify the renewals manager." },
      { key: "r2", kind: "WATCH", text: "The case crosses 90 days." }
    ];

    const text = textOf(buildPdfDocument(data, labels));

    expect(text).not.toMatch(/NOTIFY\s+Notify/);
    expect(text).toMatch(/WATCH\s+The case crosses 90 days/);
  });

  it("keeps a numbered stage name together across a line wrap", () => {
    expect(textOf(pdfText("now in 5. Agreement, overdue"))).toContain(
      "5.\u00a0Agreement"
    );
    expect(textOf(pdfText("grew 3230.5% in 2025. Then"))).toContain(
      "2025. Then"
    );
  });

  it("adds the page header, footer and heading page breaks", () => {
    const doc = buildPdfDocument(snapshot(), labels);

    expect(doc.pageSize).toBe("A4");
    expect(doc.info.title).toBe(`${labels.pdfTitle} - Miles Ahead Brands, LLC`);
    expect(doc.header(1)).toBeNull();
    expect(textOf(doc.header(2))).toContain(labels.pdfTitle.toUpperCase());
    expect(textOf(doc.header(2))).toContain("Miles Ahead Brands, LLC");
    expect(doc.footer(2, 5).columns[1].text).toBe("2 / 5");
    expect(doc.footer(2, 5).columns[0].text).toBe(labels.pdfFooter);
    expect(
      doc.pageBreakBefore(
        { headlineLevel: 1 },
        { getFollowingNodesOnPage: () => [] }
      )
    ).toBe(true);
    expect(doc.pageBreakBefore({ headlineLevel: 1 }, [{ text: "Row" }])).toBe(
      false
    );

    const bottomHeading = { headlineLevel: 1, startPosition: { top: 780 } };
    const ownRule = { headlineLevel: 2, startPosition: { top: 795 } };
    const pageFooter = { text: "Footer", startPosition: { top: 430 } };
    const nextContent = { text: "Row", startPosition: { top: 800 } };
    const movedTableWrapper = { table: {}, startPosition: { top: 800 } };
    expect(doc.pageBreakBefore(bottomHeading, [ownRule, pageFooter])).toBe(
      true
    );
    expect(
      doc.pageBreakBefore(bottomHeading, [ownRule, movedTableWrapper])
    ).toBe(true);
    const nearBottom = { pageInnerHeight: 770, verticalRatio: 0.95, top: 768 };
    const midPage = { pageInnerHeight: 770, verticalRatio: 0.5, top: 400 };
    expect(
      doc.pageBreakBefore({ headlineLevel: 1, startPosition: nearBottom }, [
        { text: "Row", startPosition: { top: 790 } }
      ])
    ).toBe(true);
    expect(
      doc.pageBreakBefore({ headlineLevel: 1, startPosition: midPage }, [
        { text: "Row", startPosition: { top: 420 } }
      ])
    ).toBe(false);
    expect(
      doc.pageBreakBefore(bottomHeading, [ownRule, nextContent, pageFooter])
    ).toBe(false);
  });

  it("builds a safe filename from the account name", () => {
    expect(pdfFilename('Acme: "West"/East?', RECORD_ID, NOW)).toBe(
      "Account Summary - Acme- -West--East- - 2026-06-29.pdf"
    );
    expect(pdfFilename("", RECORD_ID, NOW)).toBe(
      `Account Summary - ${RECORD_ID} - 2026-06-29.pdf`
    );
  });

  it("keeps emphasis and drops scripts from rich text", () => {
    const runs = pdfText(
      "<strong>Bold</strong> &amp; <em>italic</em><script>alert(1)</script>"
    );

    expect(runs.map((run) => run.text).join("")).toBe("Bold & italic");
    expect(runs[0].bold).toBe(true);
    expect(runs.find((run) => run.text === "italic").italics).toBe(true);
  });
});
