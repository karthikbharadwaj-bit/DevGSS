import { test } from "node:test";
import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { toPdfDefinition } from "../force-app/main/default/lwc/lwcPdfRenderer/pdfText.js";

const require = createRequire(import.meta.url);
const pdfMake = require("../force-app/main/default/staticresources/PdfRenderer/build/pdfmake.min.js");
pdfMake.addVirtualFileSystem(
  require("../force-app/main/default/staticresources/PdfRenderer/build/vfs_fonts.js")
);

const SUMMARY_TEXT =
  "Opportunity was created on Sep 16, 2026 7:38\u202FAM\u2009PDT and last modified on " +
  "Sep 23, 2026 10:02\u202FPM\u200APDT. Stages: Qualify \u2192 Problem\u200B\u2060\uFEFF.";

const renderText = (definition) =>
  new Promise((resolve, reject) => {
    try {
      pdfMake
        .createPdf({ compress: false, ...definition })
        .getBuffer((buffer) => resolve(Buffer.from(buffer).toString("latin1")));
    } catch (error) {
      reject(error);
    }
  });

// Glyph 0 is the font's missing-glyph box. Only TJ text runs are read; the font's
// ToUnicode table also contains <0000>.
const missingGlyphCount = (pdf) =>
  [...pdf.matchAll(/\[([^\]]*)\]\s*TJ/g)]
    .flatMap((run) => [...run[1].matchAll(/<([0-9a-f]+)>/gi)])
    .flatMap((match) => match[1].match(/.{4}/g) ?? [])
    .filter((glyph) => glyph === "0000").length;

test("raw summary text with Unicode spaces draws missing-glyph boxes", async () => {
  const pdf = await renderText({ content: [{ text: SUMMARY_TEXT }] });
  assert.ok(
    missingGlyphCount(pdf) > 0,
    "the uncleaned text should reproduce the bug"
  );
});

test("cleaned summary text draws with the bundled Roboto and no boxes", async () => {
  const pdf = await renderText(
    toPdfDefinition({
      content: [{ text: SUMMARY_TEXT }, { text: SUMMARY_TEXT, bold: true }],
      footer: () => ({ text: "Page\u202F1" })
    })
  );
  assert.equal(missingGlyphCount(pdf), 0);
});
