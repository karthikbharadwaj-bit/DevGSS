import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import vm from "node:vm";
import { buildPdfDocument } from "../force-app/main/default/lwc/opportunitySummary/opportunitySummaryPdf.js";

// Evaluates the vendored scripts the way Lightning Web Security evaluated them
// in DevGss (stage probe, 2026-10-07): strict code, top-level `this` and `self`
// are the sandboxed window, `typeof globalThis === "undefined"`, and
// `new Function("return this")()` returns undefined. Under those rules stock
// pdfmake failed to initialize and LWS rejected loadScript with `undefined`.
const resource = new URL(
  "../force-app/main/default/staticresources/PdfRenderer/",
  import.meta.url
);
const source = (path) => readFileSync(new URL(path, resource), "utf8");

function createLwsSandbox() {
  const context = vm.createContext({
    setTimeout,
    clearTimeout,
    setInterval,
    clearInterval,
    TextEncoder,
    TextDecoder,
    URL,
    atob,
    btoa,
    navigator: { userAgent: "Mozilla/5.0 (Macintosh) Chrome/154.0.0.0" },
    HTMLAnchorElement: class HTMLAnchorElement {
      download = "";
    }
  });
  vm.runInContext(
    `this.window = this;
     this.self = this;
     delete this.globalThis;
     const NativeFunction = Function;
     const SandboxFunction = function (...args) {
       const body = args.length ? args.pop() : "";
       return NativeFunction(...args, '"use strict";' + body);
     };
     SandboxFunction.prototype = NativeFunction.prototype;
     this.Function = SandboxFunction;`,
    context
  );
  return {
    context,
    load: (path) =>
      vm.runInContext(
        `(function () { "use strict";\n${source(path)}\n}).call(window);`,
        context,
        { filename: path }
      )
  };
}

const snapshot = {
  recordId: "006000000000001AAA",
  recordName: "Acme — München / Αθήνα / Москва",
  recordUrl:
    "https://example.my.salesforce.com/lightning/r/Opportunity/006000000000001AAA/view",
  generatedAt: Date.parse("2026-09-28T11:50:00Z"),
  exportedAt: Date.parse("2026-09-28T12:00:00Z"),
  scoreCard: { headline: "74/100 (Healthy)", notes: [{ text: "Fit. [E1]" }] },
  executiveFacts: [{ label: "Account", text: "Acme — Москва" }],
  researchGroups: [
    {
      label: "Company Direction and Priorities",
      findings: [
        {
          id: "E1",
          fact: "The company announced an efficiency program.",
          sources: [
            { label: "Company newsroom", url: "https://example.com/news" }
          ]
        }
      ]
    }
  ]
};
const labels = new Proxy({}, { get: (_, key) => String(key) });

test("stock pdfmake cannot initialize under LWS without a globalThis shim", () => {
  const sandbox = createLwsSandbox();
  assert.equal(
    vm.runInContext(
      '(function () { "use strict"; return typeof globalThis; })()',
      sandbox.context
    ),
    "undefined"
  );
  assert.throws(
    () => sandbox.load("build/pdfmake.min.js"),
    /Cannot read properties of undefined \(reading 'pdfMake'\)/
  );
  assert.equal(sandbox.context.pdfMake, undefined);
});

test("the LWS shim lets the unmodified renderer and fonts load and render", async () => {
  const sandbox = createLwsSandbox();
  sandbox.load("lws-global-this.js");
  sandbox.load("lws-global-this.js"); // retries reload it; must stay harmless
  sandbox.load("build/pdfmake.min.js");
  sandbox.load("build/vfs_fonts.js");
  const renderer = sandbox.context.pdfMake;
  assert.equal(typeof renderer?.createPdf, "function");
  const buffer = await new Promise((resolve) =>
    renderer.createPdf(buildPdfDocument(snapshot, labels)).getBuffer(resolve)
  );
  const pdf = Buffer.from(buffer).toString("latin1");
  assert.ok(pdf.startsWith("%PDF-"));
  assert.match(pdf, /%%EOF/);
  assert.match(pdf, /\/FontFile2/);
  assert.ok(pdf.includes("https://example.com/news"));
  assert.ok(pdf.includes("research-E1"));
});
