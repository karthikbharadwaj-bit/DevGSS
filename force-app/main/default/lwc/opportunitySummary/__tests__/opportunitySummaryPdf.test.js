/* eslint-disable no-script-url -- Deliberately malicious fixtures verify unsafe links are rejected. */
import "../../../../../../test/jest-mocks/opportunitySummaryLabels";
import {
  buildPdfDocument,
  pdfText,
  pdfFilename
} from "../opportunitySummaryPdf";
import { getUiLabels } from "../opportunitySummaryConfig";

const labels = getUiLabels();
const NOW = Date.parse("2026-09-28T12:00:00Z");
const DISCLAIMER =
  "AI-generated company research — This information was found and summarized using AI and public web search. It may be incomplete or inaccurate. Verify important details and sources before using it in customer or deal decisions.";

function fixture(overrides = {}) {
  return {
    recordId: "006000000000001AAA",
    recordName: "Acme • München — Αθήνα — Москва",
    recordUrl:
      "https://example.my.salesforce.com/lightning/r/Opportunity/006000000000001AAA/view",
    generatedAt: NOW - 600000,
    exportedAt: NOW,
    currentStage: "5. Agreement",
    scoreCard: {
      headline: "74/100 (Healthy)",
      notes: [{ text: "Grounded score [E1]." }]
    },
    executiveFacts: [
      {
        label: "Focus",
        text: "<strong>Operational alignment</strong> [E1] and unknown [E99]"
      }
    ],
    history: [{ text: "Stage changed." }],
    winFactors: [{ text: "Strong fit" }],
    riskFlags: [{ text: "Budget unconfirmed" }],
    nextActions: [{ text: "Confirm budget" }],
    closePlan: [{ label: "Next", text: "Meet the buyer" }],
    extraSections: [
      { title: "Other context", items: [{ text: "Additional context" }] }
    ],
    hasEnrichment: true,
    researchGroups: [
      {
        label: "Current Leadership",
        findings: [
          {
            id: "E1",
            fact: "Avery is COO.",
            dateLabel: "Current as of 2026-09-22",
            personLine: "Avery · COO",
            relevance: "Inference: May influence evaluation.",
            suggestedAction: "Inference: Confirm buying role.",
            sources: [
              {
                label: "Company leadership",
                url: "https://vertexaisearch.cloud.google.com/grounding-api-redirect/token"
              },
              {
                label: "Company leadership",
                url: "https://vertexaisearch.cloud.google.com/grounding-api-redirect/token"
              },
              { label: "Unsafe", url: "javascript:alert(1)" }
            ]
          }
        ]
      }
    ],
    supplementalUpdates: [
      {
        id: "E2",
        fact: "A new facility opened.",
        kindLabel: "Expansion",
        dateLabel: "Event date: 2026-09-20",
        relevance: "Inference: No opportunity relationship established.",
        suggestedAction: "Inference: No opportunity action suggested.",
        sources: [{ label: "Newsroom", url: "https://example.com/news" }]
      }
    ],
    otherResearchSources: [
      { label: "Other source", url: "https://example.com/other" }
    ],
    searchQueries: [{ text: "Acme company updates" }],
    ...overrides
  };
}

function textOf(value) {
  if (typeof value === "string") return value;
  if (Array.isArray(value)) return value.map(textOf).join(" ");
  if (!value || typeof value !== "object") return "";
  return ["text", "content", "stack", "table", "body", "ul", "ol"]
    .map((key) => textOf(value[key]))
    .join(" ");
}

describe("Opportunity Summary PDF document", () => {
  it("includes all summary sections and keeps research and supplemental updates separate", () => {
    const input = fixture();
    const original = JSON.stringify(input);
    const doc = buildPdfDocument(input, labels);
    const text = textOf(doc);
    [
      labels.pdfScore,
      labels.pdfExecutive,
      labels.pdfHistory,
      labels.pdfWin,
      labels.pdfRisk,
      labels.pdfActions,
      labels.pdfPlan,
      "Other context",
      labels.pdfResearch,
      labels.pdfSupplemental,
      labels.pdfSearches,
      "Avery · COO",
      "Expansion",
      "Current as of 2026-09-22",
      "Event date: 2026-09-20"
    ].forEach((value) => expect(text).toContain(value));
    expect(text).toContain(DISCLAIMER);
    expect(text.indexOf(DISCLAIMER)).toBeLessThan(
      text.indexOf(labels.pdfResearch)
    );
    expect(text.indexOf(labels.pdfResearch)).toBeLessThan(
      text.indexOf(labels.pdfSupplemental)
    );
    expect(text).toContain(labels.supplementalHelper);
    expect(text).not.toContain("<strong>");
    expect(text).not.toContain("grounding-api-redirect");
    expect(text).not.toContain("Unsafe");
    expect(text.match(/Company leadership/g)).toHaveLength(1);
    expect(JSON.stringify(doc)).toContain('"linkToDestination":"research-E1"');
    expect(JSON.stringify(doc)).toContain('"id":"research-E1"');
    expect(JSON.stringify(doc)).not.toContain(
      '"linkToDestination":"research-E99"'
    );
    expect(JSON.stringify(doc)).toContain('"link":"https://example.com/news"');
    expect(JSON.stringify(input)).toBe(original);
  });

  it("exports supplemental-only responses and enrichment-only disclaimers", () => {
    const doc = buildPdfDocument(fixture({ researchGroups: [] }), labels);
    expect(textOf(doc)).toContain(DISCLAIMER);
    expect(textOf(doc)).toContain("A new facility opened.");
    expect(textOf(doc)).not.toContain(labels.pdfResearch);
    const emptyEnrichment = buildPdfDocument(
      fixture({ researchGroups: [], supplementalUpdates: [] }),
      labels
    );
    expect(textOf(emptyEnrichment)).toContain(DISCLAIMER);
    expect(textOf(emptyEnrichment)).not.toContain(labels.pdfSupplemental);
  });

  it("omits research disclaimers and empty sections for legacy responses", () => {
    const doc = buildPdfDocument(
      {
        recordId: "006000000000001AAA",
        generatedAt: NOW,
        exportedAt: NOW,
        executiveFacts: [{ text: "Legacy summary" }]
      },
      labels
    );
    expect(textOf(doc)).toContain("Legacy summary");
    expect(textOf(doc)).not.toContain(DISCLAIMER);
    expect(textOf(doc)).not.toContain(labels.pdfSupplemental);
    expect(textOf(doc)).not.toContain(labels.pdfResearch);
    expect(textOf(doc)).not.toContain(labels.pdfScore);
  });

  it("preserves absolute snapshot/export times, Unicode, and page numbering", () => {
    const doc = buildPdfDocument(fixture(), labels);
    expect(textOf(doc)).toContain("2026-09-28 11:50:00 UTC");
    expect(textOf(doc)).toContain("2026-09-28 12:00:00 UTC");
    expect(textOf(doc)).toContain("München — Αθήνα — Москва");
    expect(doc.footer(2, 5).columns[1].text).toBe("2 / 5");
    expect(doc.header(1)).toBeNull();
    expect(doc.header(2).text).toBe(labels.pdfTitle);
    expect(
      doc.pageBreakBefore(
        { headlineLevel: 1 },
        { getFollowingNodesOnPage: () => [] }
      )
    ).toBe(true);
    expect(doc.pageBreakBefore({ headlineLevel: 1 }, [])).toBe(true);
    expect(doc.pageBreakBefore({ headlineLevel: 1 }, [{}])).toBe(false);
  });

  it("uses text only for supplied markup and never creates dangerous PDF actions", () => {
    const runs = pdfText(
      '<script>alert(1)</script><img src="https://evil.example"><a href="javascript:alert(1)">Safe text</a><strong>Bold &amp; &#x20ac;</strong><br><em>Italics</em>'
    );
    expect(runs.map((run) => run.text).join("")).toBe(
      "Safe textBold & €\nItalics"
    );
    expect(runs.find((run) => run.text === "Bold & €").bold).toBe(true);
    expect(runs.find((run) => run.text === "Italics").italics).toBe(true);
    expect(
      runs.every((run) => !run.link && !run.image && !run.attachment)
    ).toBe(true);
    const doc = buildPdfDocument(
      fixture({
        recordUrl: "javascript:alert(1)",
        otherResearchSources: [
          { url: "file:///private.txt", label: "Bad" },
          { url: "https://user:pass@example.com/", label: "Credentials" }
        ]
      }),
      labels
    );
    expect(JSON.stringify(doc)).not.toContain("javascript:");
    expect(JSON.stringify(doc)).not.toContain("file://");
    expect(textOf(doc)).not.toContain("Credentials");
  });

  it("retains long text for automatic pagination instead of clipping or truncating it", () => {
    const longText = "Long summary paragraph. ".repeat(3000);
    const doc = buildPdfDocument(
      fixture({ executiveFacts: [{ text: longText }] }),
      labels
    );
    expect(textOf(doc)).toContain(longText);
  });

  it("creates safe filenames with a record-id fallback", () => {
    const name = pdfFilename(
      '../Acme: "north"/west?*',
      "006000000000001AAA",
      NOW
    );
    expect(name).not.toMatch(/[<>:"/\\|?*]/);
    expect(name).toMatch(/2026-09-28\.pdf$/);
    expect(pdfFilename("", "006000000000001AAA", NOW)).toContain(
      "006000000000001AAA"
    );
    expect(pdfFilename("A".repeat(200), "", NOW).length).toBeLessThan(150);
  });

  it("links only bracketed known evidence markers", () => {
    const known = new Set(["E1"]);
    expect(pdfText("xE1x", known)[0].linkToDestination).toBeUndefined();
    expect(pdfText("[E1]", known)[0].linkToDestination).toBe("research-E1");
    expect(pdfText("[E2]", known)[0].linkToDestination).toBeUndefined();
  });
});
