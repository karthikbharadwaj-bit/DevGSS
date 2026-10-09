import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync, writeFileSync } from "node:fs";
import { createRequire } from "node:module";
import { buildPdfDocument } from "../force-app/main/default/lwc/opportunitySummary/opportunitySummaryPdf.js";

const require = createRequire(import.meta.url);
const pdfMake = require("../force-app/main/default/staticresources/PdfRenderer/build/pdfmake.min.js");
pdfMake.addVirtualFileSystem(
  require("../force-app/main/default/staticresources/PdfRenderer/build/vfs_fonts.js")
);
const renderBuffer = (definition) =>
  new Promise((resolve, reject) => {
    try {
      pdfMake.createPdf(definition).getBuffer(resolve);
    } catch (error) {
      reject(error);
    }
  });
const xml = readFileSync(
  new URL(
    "../force-app/main/default/labels/OpportunitySummary.labels-meta.xml",
    import.meta.url
  ),
  "utf8"
);
const labels = Object.fromEntries(
  [...xml.matchAll(/<labels>([\s\S]*?)<\/labels>/g)].map((match) => {
    const name = match[1]
      .match(/<fullName\s*>([\s\S]*?)<\/fullName>/)[1]
      .replace("OpportunitySummary", "");
    const value = match[1]
      .match(/<value\s*>([\s\S]*?)<\/value>/)[1]
      .replaceAll("&amp;", "&")
      .replaceAll("&lt;", "<")
      .replaceAll("&gt;", ">");
    return [name[0].toLowerCase() + name.slice(1), value];
  })
);
const snapshot = {
  recordId: "006000000000001AAA",
  recordName: "Acme — München / Αθήνα / Москва",
  recordUrl:
    "https://example.my.salesforce.com/lightning/r/Opportunity/006000000000001AAA/view",
  generatedAt: Date.parse("2026-09-28T11:50:00Z"),
  exportedAt: Date.parse("2026-09-28T12:00:00Z"),
  currentStage: "5. Agreement",
  scoreCard: {
    headline: "74/100 (Healthy)",
    notes: [
      { text: "Strong fit, with commercial details still to confirm. [E1]" }
    ]
  },
  executiveFacts: [
    { label: "Account", text: "Acme — München / Αθήνα / Москва" },
    {
      label: "Overview",
      text: "<strong>Operational alignment</strong> supports the evaluation. Budget and decision authority remain unconfirmed. [E1]"
    }
  ],
  history: [{ text: "The opportunity advanced to Agreement on 2026-09-22." }],
  winFactors: [{ text: "Customer priorities align with the proposal. [E1]" }],
  riskFlags: [{ text: "Budget is not yet confirmed." }],
  nextActions: [
    { text: "Confirm commercial terms with the buying group." },
    { text: "Schedule a decision meeting." }
  ],
  closePlan: [
    {
      label: "This week",
      text: "Confirm evaluation criteria and agree next steps."
    }
  ],
  hasEnrichment: true,
  researchGroups: [
    {
      label: "Company Direction and Priorities",
      findings: [
        {
          id: "E1",
          fact: "The company announced an operational efficiency program.",
          dateLabel: "Published: 2026-09-20",
          relevance: "Inference: The program may align with the proposal.",
          suggestedAction: "Inference: Validate scope with the customer.",
          sources: [
            { label: "Company newsroom", url: "https://example.com/news" }
          ]
        }
      ]
    }
  ],
  supplementalUpdates: [
    {
      id: "E2",
      kindLabel: "Leadership",
      fact: "Avery Example is the Chief Operating Officer.",
      personLine: "Avery Example · Chief Operating Officer",
      dateLabel: "Current as of 2026-09-22",
      relevance:
        "Inference: No relationship to this opportunity is established.",
      suggestedAction:
        "Inference: No opportunity action is suggested from this update alone.",
      sources: [
        { label: "Company leadership", url: "https://example.com/leadership" }
      ]
    }
  ]
};

test("bundled browser renderer produces a real linked PDF with embedded fonts", async () => {
  const buffer = await renderBuffer(buildPdfDocument(snapshot, labels));
  const bytes = Buffer.from(buffer);
  const pdf = bytes.toString("latin1");
  assert.ok(pdf.startsWith("%PDF-"));
  assert.match(pdf, /%%EOF/);
  assert.match(pdf, /\/FontFile2/);
  assert.match(pdf, /\/Subtype \/Link/);
  assert.ok(pdf.includes("https://example.com/news"));
  assert.ok(pdf.includes("https://example.com/leadership"));
  assert.ok(pdf.includes("research-E1"));
  // Optional local artifact for visual inspection; never deploy test output.
  if (process.env.OPPORTUNITY_PDF_PREVIEW_PATH)
    writeFileSync(process.env.OPPORTUNITY_PDF_PREVIEW_PATH, bytes);
});

test("long content paginates with the real bundled renderer", async () => {
  const long = {
    ...snapshot,
    executiveFacts: Array.from({ length: 100 }, (_, index) => ({
      text: `Paragraph ${index + 1}. ${"Long narrative with preserved evidence [E1]. ".repeat(12)}`
    }))
  };
  const buffer = await renderBuffer(buildPdfDocument(long, labels));
  const pdf = Buffer.from(buffer).toString("latin1");
  assert.ok((pdf.match(/\/Type \/Page\b/g) || []).length > 3);
  assert.match(pdf, /%%EOF/);
});
