import {
  resetLabels,
  setLabel
} from "../../../../../../test/jest-mocks/opportunitySummaryLabels";
import { createElement } from "lwc";
import * as summaryConfig from "../opportunitySummaryConfig";
import * as pdfDownload from "../opportunitySummaryPdfDownload";
import OpportunitySummary, {
  citedEvidenceIds,
  buildDateLabel,
  buildDateParts,
  buildSalesforceChips,
  linkRecordReferences,
  buildResearchViewModel,
  indexFindings,
  indexSources,
  parseInlineEvidence,
  splitLabel
} from "c/opportunitySummary";
import makeGCPCallout from "@salesforce/apex/GCPCalloutForOpportunitySummary.makeGCPCallout";
import logAIHEvent from "@salesforce/apex/GCPCalloutForOpportunitySummary.logAIHEvent";
import isOpportunitySummaryEnabled from "@salesforce/apex/GCPCalloutForOpportunitySummary.isOpportunitySummaryEnabled";

jest.mock(
  "@salesforce/apex/GCPCalloutForOpportunitySummary.makeGCPCallout",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/GCPCalloutForOpportunitySummary.logAIHEvent",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/GCPCalloutForOpportunitySummary.isOpportunitySummaryEnabled",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock("@salesforce/user/Id", () => ({ default: "005000000000001AAA" }), {
  virtual: true
});
const RECORD_ID = "006000000000001AAA";
const CACHE_KEY = `opportunitySummary:v1:005000000000001AAA:${RECORD_ID}`;
const ONE_HOUR_MS = 60 * 60 * 1000;
const MAX_CACHE_BYTES = 512 * 1024;
const GOOGLE_REDIRECT_URL =
  "https://vertexaisearch.cloud.google.com/grounding-api-redirect/private-token";
const AI_RESEARCH_DISCLAIMER =
  "AI-generated company research — This information was found and summarized using AI and public web search. It may be incomplete or inaccurate. Verify important details and sources before using it in customer or deal decisions.";

function reloadConfiguration() {
  let configured;
  jest.isolateModules(() => {
    configured = require("../opportunitySummaryConfig");
  });
  [
    "getCachePolicy",
    "getUiLabels",
    "getResearchGroups",
    "getLoadingMessages"
  ].forEach((method) => {
    jest.spyOn(summaryConfig, method).mockImplementation(configured[method]);
  });
}

function publicResearch(overrides = {}) {
  return {
    findings: [
      {
        id: "E1",
        kind: "leadership",
        date: "2026-09-18",
        date_type: "as_of",
        fact: "Avery Example is the Chief Operating Officer.",
        person_name: "Avery Example",
        role: "Chief Operating Officer",
        relevance: "Inference: Operations may influence the evaluation.",
        suggested_action: "Confirm Avery's role in the decision process.",
        source_indices: [0, 9, 3, 0]
      },
      {
        id: "E3",
        kind: "priority",
        date: "2026-01-14",
        date_type: "event",
        fact: "The company announced an operational efficiency program.",
        relevance: "Inference: The program may align with the proposal.",
        suggested_action:
          "Inference: Validate whether the program is in scope.",
        source_indices: [4]
      }
    ],
    sources: [
      {
        index: 9,
        display_label: "company.example",
        title: "Company newsroom",
        url: `${GOOGLE_REDIRECT_URL}-nine`
      },
      {
        index: 0,
        title: "Executive profile",
        url: "https://example.com/executive"
      },
      {
        index: 3,
        display_label: "Invalid source",
        url: "ftp://example.com/unsupported"
      },
      {
        index: 4,
        display_label: GOOGLE_REDIRECT_URL,
        url: GOOGLE_REDIRECT_URL
      },
      {
        index: 7,
        display_label: "Additional research",
        url: "http://example.org/additional"
      }
    ],
    web_search_queries: [
      "Example company leadership",
      "Example company priorities 2026"
    ],
    search_entry_point: {
      rendered_content:
        '<style>.provider-chip{color:blue}</style><svg></svg><a href="https://google.com">Search</a>'
    },
    ...overrides
  };
}

function supplementalCompanyUpdates(overrides = {}) {
  return {
    relationship_to_opportunity: "not_established",
    items: [
      {
        id: "E2",
        kind: "leadership",
        date: "2026-09-22",
        date_type: "as_of",
        fact: "Example Person is the current Chief Operating Officer.",
        relevance:
          "Inference: No relationship to the supplied opportunity is established.",
        suggested_action:
          "Inference: No opportunity action is suggested from this update alone.",
        person_name: "Example Person",
        role: "Chief Operating Officer",
        source_indices: [1]
      }
    ],
    ...overrides
  };
}

function summaryCards() {
  return [
    {
      title: "Overall Deal Score",
      badge: "74/100 (Healthy)",
      items: ["CRM-derived score note [E1]"]
    },
    {
      title: "Executive Summary",
      items: [
        "Focus: <strong>Operational alignment</strong> [E1] and [E3], with unknown [E99]"
      ]
    },
    {
      title: "Opportunity History & Stage Journey",
      items: ["CRM stage changed last week [E3]"]
    }
  ];
}

function response({
  cards = summaryCards(),
  enrichment = publicResearch()
} = {}) {
  const value = { success: true, cards };
  if (enrichment !== undefined) {
    value.opportunity_enrichment = enrichment;
  }
  return JSON.stringify(value);
}

function cachedSummaryEntry(options = {}) {
  const cachedAt = options.cachedAt ?? Date.now();
  const cards = options.cards ?? summaryCards();
  const enrichment = Object.prototype.hasOwnProperty.call(options, "enrichment")
    ? options.enrichment
    : publicResearch();
  const summary = { cards };
  if (enrichment !== undefined) {
    summary.opportunity_enrichment = enrichment;
  }
  return { cachedAt, summary };
}

function deferred() {
  let resolve;
  let reject;
  const promise = new Promise((promiseResolve, promiseReject) => {
    resolve = promiseResolve;
    reject = promiseReject;
  });
  return { promise, resolve, reject };
}

async function flushPromises() {
  await Promise.resolve();
  await Promise.resolve();
  await Promise.resolve();
}

async function mountComponent() {
  const element = createElement("c-opportunity-summary", {
    is: OpportunitySummary
  });
  element.recordId = RECORD_ID;
  document.body.appendChild(element);
  await flushPromises();
  return element;
}

async function createComponent(result = response()) {
  localStorage.removeItem(CACHE_KEY);
  makeGCPCallout.mockResolvedValue(result);
  const element = await mountComponent();

  element.shadowRoot.querySelector("[data-generate-summary]").click();
  await flushPromises();
  element.shadowRoot.querySelector("[data-view-summary]").click();
  await flushPromises();
  return element;
}

// ISO research dates render through lightning-formatted-date-time, so assert the
// prefix text and the value handed to the formatter rather than raw ISO text.
function researchDates(root) {
  return [...root.querySelectorAll(".research-date")].map((node) => {
    const formatted = node.querySelector("lightning-formatted-date-time");
    return {
      text: node.textContent.trim(),
      value: formatted ? formatted.value : null,
      timeZone: formatted ? formatted.timeZone : null
    };
  });
}

function formattedValues(root) {
  return [...root.querySelectorAll("lightning-formatted-rich-text")].map(
    (node) => node.value
  );
}

describe("opportunitySummary helpers", () => {
  it("splits on an eligible em dash", () => {
    expect(splitLabel("Now — Work with Shubham Prabhakar")).toEqual({
      label: "Now",
      text: "Work with Shubham Prabhakar",
      hasLabel: true
    });
  });

  it("uses only the first em dash", () => {
    expect(
      splitLabel("Next — Update the opportunity — after approval")
    ).toEqual({
      label: "Next",
      text: "Update the opportunity — after approval",
      hasLabel: true
    });
  });

  it("ignores an em dash after the label length limit", () => {
    const text = `${"Long prose ".repeat(5)}— remains prose`;

    expect(splitLabel(text)).toEqual({
      label: "",
      text,
      hasLabel: false
    });
  });

  it("preserves colon parsing and an emphasized label", () => {
    expect(splitLabel("Owner: Eric Anderson")).toEqual({
      label: "Owner",
      text: "Eric Anderson",
      hasLabel: true
    });
    expect(
      splitLabel("<strong>Owner:</strong> <strong>Eric Anderson</strong>")
    ).toEqual({
      label: "Owner",
      text: "<strong>Eric Anderson</strong>",
      hasLabel: true
    });
  });

  it("indexes by explicit IDs and indices without mutating the response", () => {
    const enrichment = publicResearch();
    const original = JSON.stringify(enrichment);

    expect(indexFindings(enrichment.findings).get("E3").kind).toBe("priority");
    expect(indexSources(enrichment.sources).get("0").title).toBe(
      "Executive profile"
    );
    expect(JSON.stringify(enrichment)).toBe(original);
  });

  it("replaces multiple known references, preserves unknown references, and keeps strong markup", () => {
    const findings = indexFindings(publicResearch().findings);
    const segments = parseInlineEvidence(
      "A <strong>priority</strong> [E1] and [E3], but [E99] is unknown.",
      findings,
      "test"
    );

    expect(
      segments
        .filter((segment) => segment.isEvidence)
        .map((segment) => segment.evidenceId)
    ).toEqual(["E1", "E3"]);
    const remainingContent = segments
      .filter((segment) => !segment.isEvidence)
      .map((segment) => segment.content)
      .join("");
    expect(remainingContent).toContain("<strong>priority</strong>");
    expect(remainingContent).toContain("[E99]");
    expect(remainingContent).not.toContain("[E1]");
    expect(remainingContent).not.toContain("[E3]");
  });

  it("builds the specified date labels", () => {
    expect(buildDateLabel("2026-09-18", "as_of")).toBe(
      "Current as of 2026-09-18"
    );
    expect(buildDateLabel("2026-01-14", "event")).toBe(
      "Event date: 2026-01-14"
    );
    expect(buildDateLabel("2026-02-02", "publication")).toBe(
      "Published: 2026-02-02"
    );
  });

  it("preserves repeated source relationships and disables invalid URLs", () => {
    const viewModel = buildResearchViewModel(publicResearch());
    const leadership = viewModel.findingById.get("E1");

    expect(leadership.sources.map((source) => source.index)).toEqual([
      0, 9, 3, 0
    ]);
    expect(leadership.sources.map((source) => source.label)).toEqual([
      "Executive profile",
      "company.example",
      "Invalid source",
      "Executive profile"
    ]);
    expect(leadership.sources[2].hasLink).toBe(false);
    expect(viewModel.findingById.get("E3").sources[0].label).toBe("Source 5");
    expect(viewModel.otherSources.map((source) => source.index)).toEqual([7]);
  });
});

describe("opportunitySummary public research", () => {
  beforeEach(() => {
    resetLabels();
    localStorage.clear();
    isOpportunitySummaryEnabled.mockResolvedValue(true);
    logAIHEvent.mockResolvedValue();
  });

  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
    jest.restoreAllMocks();
  });

  it("does not load the PDF renderer until Download PDF is clicked", async () => {
    const load = jest
      .spyOn(pdfDownload, "loadPdfRenderer")
      .mockResolvedValue({});
    const render = jest
      .spyOn(pdfDownload, "renderPdf")
      .mockResolvedValue(new Blob(["pdf"], { type: "application/pdf" }));

    const element = await mountComponent();

    expect(load).not.toHaveBeenCalled();
    expect(render).not.toHaveBeenCalled();
    expect(
      element.shadowRoot.querySelector("[data-generate-summary]")
    ).not.toBeNull();
  });

  it("downloads the displayed snapshot without another callout and includes collapsed supplemental content", async () => {
    const render = jest
      .spyOn(pdfDownload, "renderPdf")
      .mockResolvedValue(new Blob(["pdf"], { type: "application/pdf" }));
    const download = jest
      .spyOn(pdfDownload, "downloadPdf")
      .mockImplementation(() => {});
    const enrichment = publicResearch({
      supplemental_company_updates: supplementalCompanyUpdates()
    });
    const element = await createComponent(response({ enrichment }));
    localStorage.clear();
    expect(
      element.shadowRoot.querySelector("[data-download-pdf]").textContent
    ).toContain("Download PDF");
    element.shadowRoot.querySelector("[data-download-pdf]").click();
    await flushPromises();
    expect(render).toHaveBeenCalledTimes(1);
    expect(download).toHaveBeenCalledTimes(1);
    expect(makeGCPCallout).toHaveBeenCalledTimes(1);
    const documentDefinition = render.mock.calls[0][1];
    expect(JSON.stringify(documentDefinition)).toContain(
      "Example Person is the current Chief Operating Officer."
    );
    expect(JSON.stringify(documentDefinition)).toContain(
      AI_RESEARCH_DISCLAIMER
    );
    expect(download.mock.calls[0][2]).toContain(RECORD_ID);
    expect(
      element.shadowRoot.querySelector('.ai-modal__body [role="status"]')
        .textContent
    ).toBe("PDF download started.");
  });

  it("exports a cached result with its original timestamp without calling GCP", async () => {
    const cachedAt = Date.now() - 10 * 60 * 1000;
    localStorage.setItem(
      CACHE_KEY,
      JSON.stringify(cachedSummaryEntry({ cachedAt }))
    );
    const render = jest
      .spyOn(pdfDownload, "renderPdf")
      .mockResolvedValue(new Blob(["pdf"]));
    jest.spyOn(pdfDownload, "downloadPdf").mockImplementation(() => {});
    const element = await mountComponent();
    element.shadowRoot.querySelector("[data-view-summary]").click();
    await flushPromises();
    element.shadowRoot.querySelector("[data-download-pdf]").click();
    await flushPromises();
    const expectedTime = new Date(cachedAt)
      .toISOString()
      .replace("T", " ")
      .replace(/\.\d{3}Z$/, " UTC");
    expect(JSON.stringify(render.mock.calls[0][1])).toContain(expectedTime);
    expect(makeGCPCallout).not.toHaveBeenCalled();
  });

  it("prevents duplicate exports and recovers from a renderer failure without losing the summary", async () => {
    const pending = deferred();
    const render = jest
      .spyOn(pdfDownload, "renderPdf")
      .mockReturnValue(pending.promise);
    const element = await createComponent();
    const button = element.shadowRoot.querySelector("[data-download-pdf]");
    button.click();
    button.click();
    await flushPromises();
    expect(render).toHaveBeenCalledTimes(1);
    expect(button.disabled).toBe(true);
    expect(button.textContent).toContain("Preparing PDF");
    pending.reject(new Error("Private renderer details"));
    await flushPromises();
    expect(button.disabled).toBe(false);
    expect(
      element.shadowRoot.querySelector("[data-pdf-error]").textContent
    ).toContain("Your summary is still available");
    expect(element.shadowRoot.textContent).not.toContain(
      "Private renderer details"
    );
    expect(
      element.shadowRoot.querySelector('[data-summary-section="score"]')
    ).not.toBeNull();
    render.mockResolvedValue(new Blob(["pdf"]));
    const download = jest
      .spyOn(pdfDownload, "downloadPdf")
      .mockImplementation(() => {});
    button.click();
    await flushPromises();
    expect(download).toHaveBeenCalledTimes(1);
    expect(element.shadowRoot.querySelector("[data-pdf-error]")).toBeNull();
  });

  it.each(["close", "record", "disconnect", "refresh"])(
    "cancels stale downloads after %s",
    async (action) => {
      const pending = deferred();
      jest.spyOn(pdfDownload, "renderPdf").mockReturnValue(pending.promise);
      const download = jest
        .spyOn(pdfDownload, "downloadPdf")
        .mockImplementation(() => {});
      const element = await createComponent();
      element.shadowRoot.querySelector("[data-download-pdf]").click();
      await flushPromises();
      if (action === "close")
        element.shadowRoot.querySelector(".close-button").click();
      if (action === "record") element.recordId = "006000000000002AAA";
      if (action === "disconnect") element.remove();
      if (action === "refresh")
        element.shadowRoot.querySelector("lightning-button-icon").click();
      pending.resolve(new Blob(["pdf"]));
      await flushPromises();
      expect(download).not.toHaveBeenCalled();
    }
  );

  it("does not offer an export for an empty result", async () => {
    const element = await createComponent(
      JSON.stringify({ success: true, cards: [] })
    );
    expect(element.shadowRoot.querySelector("[data-download-pdf]")).toBeNull();
  });

  it("runs on demand without opening the modal and presents completed results on demand", async () => {
    let resolveCallout;
    makeGCPCallout.mockReturnValue(
      new Promise((resolve) => {
        resolveCallout = resolve;
      })
    );
    const element = await mountComponent();

    expect(makeGCPCallout).not.toHaveBeenCalled();
    const generateButton = element.shadowRoot.querySelector(
      "[data-generate-summary]"
    );
    generateButton.click();
    await flushPromises();

    expect(makeGCPCallout).toHaveBeenCalledTimes(1);
    expect(element.shadowRoot.querySelector(".slds-modal")).toBeNull();
    expect(
      element.shadowRoot.querySelector("[data-summary-progress]").textContent
    ).toContain("Building your opportunity brief");

    resolveCallout(response());
    await flushPromises();

    expect(element.shadowRoot.querySelector(".slds-modal")).toBeNull();
    const viewButton = element.shadowRoot.querySelector("[data-view-summary]");
    expect(viewButton.textContent).toContain("View Summary");
    expect(
      element.shadowRoot.querySelector("[data-summary-ready]")
    ).not.toBeNull();

    viewButton.click();
    await flushPromises();

    expect(element.shadowRoot.querySelector(".slds-modal")).not.toBeNull();
    expect(makeGCPCallout).toHaveBeenCalledTimes(1);
  });

  it("restores a 90-minute-old summary when the cache label permits two hours", async () => {
    setLabel("CacheHours", "2");
    reloadConfiguration();
    localStorage.setItem(
      CACHE_KEY,
      JSON.stringify(
        cachedSummaryEntry({
          cachedAt: Date.now() - 90 * 60 * 1000
        })
      )
    );
    const element = await mountComponent();
    expect(
      element.shadowRoot.querySelector("[data-summary-ready]")
    ).not.toBeNull();
    expect(makeGCPCallout).not.toHaveBeenCalled();
  });

  it("discards a summary when the configured shorter TTL has expired", async () => {
    setLabel("CacheHours", "0.25");
    reloadConfiguration();
    localStorage.setItem(
      CACHE_KEY,
      JSON.stringify(
        cachedSummaryEntry({
          cachedAt: Date.now() - 20 * 60 * 1000
        })
      )
    );
    const element = await mountComponent();
    expect(
      element.shadowRoot.querySelector("[data-generate-summary]")
    ).not.toBeNull();
    expect(localStorage.getItem(CACHE_KEY)).toBeNull();
  });

  it("renders fresh results even when a configured smaller cache budget rejects them", async () => {
    setLabel("CacheMaxKB", "1");
    reloadConfiguration();
    const element = await createComponent(response());
    expect(element.shadowRoot.querySelector(".slds-modal")).not.toBeNull();
    expect(localStorage.getItem(CACHE_KEY)).toBeNull();
  });

  it("renders configured UI copy and research kinds without changing the request", async () => {
    setLabel("GenerateButton", "Prepare brief");
    setLabel("ReadyTitle", "Your brief is ready");
    setLabel("ResearchDisclaimer", "Configured research disclaimer");
    setLabel(
      "ResearchGroups",
      JSON.stringify([{ kind: "expansion", label: "Growth news", order: 1 }])
    );
    reloadConfiguration();
    const element = await mountComponent();
    expect(
      element.shadowRoot.querySelector("[data-generate-summary]").textContent
    ).toContain("Prepare brief");
    makeGCPCallout.mockResolvedValue(
      response({
        enrichment: publicResearch({
          findings: [
            {
              id: "E8",
              kind: "expansion",
              fact: "A new office opened.",
              source_indices: [0]
            }
          ]
        })
      })
    );
    element.shadowRoot.querySelector("[data-generate-summary]").click();
    await flushPromises();
    expect(element.shadowRoot.textContent).toContain("Your brief is ready");
    element.shadowRoot.querySelector("[data-view-summary]").click();
    await flushPromises();
    expect(
      element.shadowRoot.querySelector("[data-research-group=expansion]")
        .textContent
    ).toContain("Growth news");
    expect(
      element.shadowRoot.querySelector("[data-enrichment-disclaimer]")
        .textContent
    ).toContain("Configured research disclaimer");
    expect(makeGCPCallout).toHaveBeenCalledWith({
      userId: "005000000000001AAA",
      recordId: RECORD_ID
    });
  });

  it("restores a cached summary for one hour without calling GCP", async () => {
    const cachedAt = Date.now() - 30 * 60 * 1000;
    localStorage.setItem(
      CACHE_KEY,
      JSON.stringify(
        cachedSummaryEntry({
          cachedAt,
          cards: [
            {
              title: "Executive Summary",
              items: ["Source: Restored from the one-hour cache"]
            }
          ],
          enrichment: undefined
        })
      )
    );
    makeGCPCallout.mockResolvedValue(response());

    const element = await mountComponent();

    expect(makeGCPCallout).not.toHaveBeenCalled();
    expect(
      element.shadowRoot.querySelector("[data-summary-ready]")
    ).not.toBeNull();
    expect(element.shadowRoot.textContent).toContain(
      "Generated 30 minutes ago"
    );

    element.shadowRoot.querySelector("[data-view-summary]").click();
    await flushPromises();
    expect(formattedValues(element.shadowRoot)).toContain(
      "Restored from the one-hour cache"
    );
  });

  it("discards expired cache entries and waits for an on-demand request", async () => {
    localStorage.setItem(
      CACHE_KEY,
      JSON.stringify(
        cachedSummaryEntry({ cachedAt: Date.now() - ONE_HOUR_MS - 1 })
      )
    );
    makeGCPCallout.mockResolvedValue(response());

    const element = await mountComponent();

    expect(localStorage.getItem(CACHE_KEY)).toBeNull();
    expect(makeGCPCallout).not.toHaveBeenCalled();
    expect(
      element.shadowRoot.querySelector("[data-generate-summary]")
    ).not.toBeNull();
  });

  it("ignores malformed cache entries without blocking generation", async () => {
    localStorage.setItem(CACHE_KEY, "not-json");
    makeGCPCallout.mockResolvedValue(response());

    const element = await mountComponent();

    expect(localStorage.getItem(CACHE_KEY)).toBeNull();
    expect(makeGCPCallout).not.toHaveBeenCalled();
    element.shadowRoot.querySelector("[data-generate-summary]").click();
    await flushPromises();
    expect(makeGCPCallout).toHaveBeenCalledTimes(1);
  });

  it("force-invalidates the cache and coalesces duplicate refresh clicks", async () => {
    localStorage.setItem(
      CACHE_KEY,
      JSON.stringify(
        cachedSummaryEntry({
          cards: [
            {
              title: "Executive Summary",
              items: ["Status: Cached summary"]
            }
          ],
          enrichment: undefined
        })
      )
    );
    const refreshResponse = deferred();
    makeGCPCallout.mockReturnValue(refreshResponse.promise);
    const element = await mountComponent();
    const refreshButton = element.shadowRoot.querySelector(
      "[data-refresh-summary]"
    );

    refreshButton.click();
    refreshButton.click();
    await flushPromises();

    expect(localStorage.getItem(CACHE_KEY)).toBeNull();
    expect(makeGCPCallout).toHaveBeenCalledTimes(1);
    expect(element.shadowRoot.querySelector(".slds-modal")).toBeNull();
    expect(
      element.shadowRoot.querySelector("[data-summary-progress]")
    ).not.toBeNull();

    refreshResponse.resolve(
      response({
        cards: [
          {
            title: "Executive Summary",
            items: ["Status: Freshly regenerated summary"]
          }
        ],
        enrichment: undefined
      })
    );
    await flushPromises();

    const refreshedEntry = JSON.parse(localStorage.getItem(CACHE_KEY));
    expect(refreshedEntry.summary.cards[0].items).toEqual([
      "Status: Freshly regenerated summary"
    ]);
    expect(
      element.shadowRoot.querySelector("[data-summary-ready]")
    ).not.toBeNull();
  });

  it("caps all Opportunity Summary entries at the default 512 KiB budget", async () => {
    const otherCacheKey =
      "opportunitySummary:v1:005000000000009AAA:006000000000009AAA";
    localStorage.setItem(
      otherCacheKey,
      JSON.stringify(
        cachedSummaryEntry({
          cachedAt: Date.now() - 1000,
          cards: [
            {
              title: "Executive Summary",
              items: [`Old: ${"o".repeat(140000)}`]
            }
          ],
          enrichment: undefined
        })
      )
    );
    makeGCPCallout.mockResolvedValue(
      response({
        cards: [
          {
            title: "Executive Summary",
            items: [`New: ${"n".repeat(140000)}`]
          }
        ],
        enrichment: undefined
      })
    );
    const element = await mountComponent();

    element.shadowRoot.querySelector("[data-generate-summary]").click();
    await flushPromises();

    let cachedBytes = 0;
    for (let index = 0; index < localStorage.length; index += 1) {
      const key = localStorage.key(index);
      if (key.startsWith("opportunitySummary:v1:")) {
        cachedBytes += (key.length + localStorage.getItem(key).length) * 2;
      }
    }
    expect(cachedBytes).toBeLessThanOrEqual(MAX_CACHE_BYTES);
    expect(localStorage.getItem(otherCacheKey)).toBeNull();
    expect(localStorage.getItem(CACHE_KEY)).not.toBeNull();
  });

  it("keeps the existing response unchanged when enrichment is absent", async () => {
    const element = await createComponent(
      JSON.stringify({
        success: true,
        cards: [{ title: "Executive Summary", items: ["Owner: CRM only"] }]
      })
    );

    expect(
      element.shadowRoot.querySelector("[data-public-research]")
    ).toBeNull();
    expect(element.shadowRoot.querySelector(".fact-label").textContent).toBe(
      "Owner"
    );
    expect(formattedValues(element.shadowRoot)).toContain("CRM only");
    expect(element.shadowRoot.querySelector(".status-error")).toBeNull();
    expect(makeGCPCallout).toHaveBeenCalledTimes(1);
    expect(makeGCPCallout).toHaveBeenCalledWith({
      userId: "005000000000001AAA",
      recordId: RECORD_ID
    });
  });

  it("shows the exact accessible AI research disclaimer whenever enrichment is present", async () => {
    const element = await createComponent(
      response({ enrichment: { findings: [] } })
    );
    const disclaimer = element.shadowRoot.querySelector(
      "[data-enrichment-disclaimer]"
    );

    expect(disclaimer.textContent.replace(/\s+/g, " ").trim()).toBe(
      AI_RESEARCH_DISCLAIMER
    );
    expect(disclaimer.getAttribute("role")).toBe("note");
    expect(disclaimer.querySelector("lightning-icon").iconName).toBe(
      "utility:warning"
    );
  });

  it("renders supplemental company updates separately with their complete presentation", async () => {
    const enrichment = publicResearch({
      supplemental_company_updates: supplementalCompanyUpdates(),
      sources: [
        ...publicResearch().sources,
        {
          index: 1,
          display_label: "Example Company Leadership",
          title: "Leadership page",
          url: "https://example.com/leadership"
        }
      ]
    });
    const element = await createComponent(response({ enrichment }));
    const supplemental = element.shadowRoot.querySelector(
      "[data-supplemental-updates]"
    );
    const research = element.shadowRoot.querySelector("[data-public-research]");

    expect(supplemental.textContent).toContain("Additional Company Updates");
    expect(supplemental.open).toBe(false);
    expect(supplemental.dataset.relationshipToOpportunity).toBe(
      "not_established"
    );
    expect(supplemental.textContent).toContain(
      "These public company updates were not linked to the current opportunity by the AI analysis."
    );
    expect(supplemental.textContent).toContain("Leadership");
    expect(researchDates(supplemental)).toEqual([
      { text: "Current as of", value: "2026-09-22", timeZone: "UTC" }
    ]);
    expect(supplemental.textContent).toContain(
      "Example Person · Chief Operating Officer"
    );
    expect(supplemental.textContent).toContain(
      "Example Person is the current Chief Operating Officer."
    );
    expect(supplemental.textContent).toContain(
      "Inference: No relationship to the supplied opportunity is established."
    );
    expect(supplemental.textContent).toContain(
      "Inference: No opportunity action is suggested from this update alone."
    );
    const source = supplemental.querySelector('a[data-source-index="1"]');
    expect(source.textContent.trim()).toBe("Example Company Leadership");
    expect(source.target).toBe("_blank");
    expect(source.rel).toBe("noopener noreferrer");
    expect(research.textContent).not.toContain(
      "Example Person is the current Chief Operating Officer."
    );
    expect(research.textContent).not.toContain("Example Company Leadership");
    expect(
      [...element.shadowRoot.querySelectorAll("[data-summary-section]")].some(
        (section) =>
          section.textContent.includes(
            "Example Person is the current Chief Operating Officer."
          )
      )
    ).toBe(false);
    expect(
      [
        ...element.shadowRoot.querySelectorAll(
          "[data-enrichment-disclaimer], [data-public-research], [data-supplemental-updates]"
        )
      ].map((section) => {
        if (section.hasAttribute("data-enrichment-disclaimer")) {
          return "disclaimer";
        }
        return section.hasAttribute("data-public-research")
          ? "research"
          : "supplemental";
      })
    ).toEqual(["disclaimer", "research", "supplemental"]);
  });

  it("resolves only unique valid supplemental source indices with safe label fallbacks", async () => {
    const updates = supplementalCompanyUpdates({
      items: [
        {
          ...supplementalCompanyUpdates().items[0],
          source_indices: [1, true, -1, 99, 1, 2, 4]
        }
      ]
    });
    const enrichment = publicResearch({
      findings: [],
      supplemental_company_updates: updates,
      sources: [
        {
          index: 1,
          display_label: "Display Label",
          title: "Ignored title",
          url: "https://example.com/display-label"
        },
        {
          index: 2,
          title: "Title Fallback",
          url: "https://example.com/title-fallback"
        },
        {
          index: 4,
          display_label: GOOGLE_REDIRECT_URL,
          url: `${GOOGLE_REDIRECT_URL}-four`
        }
      ]
    });
    const element = await createComponent(response({ enrichment }));
    const supplemental = element.shadowRoot.querySelector(
      "[data-supplemental-updates]"
    );
    const sources = [
      ...supplemental.querySelectorAll(".finding-sources [data-source-index]")
    ];

    expect(sources.map((source) => source.dataset.sourceIndex)).toEqual([
      "1",
      "2",
      "4"
    ]);
    expect(sources.map((source) => source.textContent.trim())).toEqual([
      "Display Label",
      "Title Fallback",
      "Source 5"
    ]);
    expect(supplemental.textContent).not.toContain(GOOGLE_REDIRECT_URL);
    sources.forEach((source) => {
      expect(source.target).toBe("_blank");
      expect(source.rel).toBe("noopener noreferrer");
    });
  });

  it("hides the supplemental section when items are missing or empty", async () => {
    const withoutNode = await createComponent();
    const emptyNode = await createComponent(
      response({
        enrichment: publicResearch({
          supplemental_company_updates: supplementalCompanyUpdates({
            items: []
          })
        })
      })
    );

    expect(
      withoutNode.shadowRoot.querySelector("[data-supplemental-updates]")
    ).toBeNull();
    expect(
      emptyNode.shadowRoot.querySelector("[data-supplemental-updates]")
    ).toBeNull();
  });

  it("shows the disclaimer and supplemental updates when findings are empty", async () => {
    const element = await createComponent(
      response({
        enrichment: publicResearch({
          findings: [],
          supplemental_company_updates: supplementalCompanyUpdates()
        })
      })
    );

    expect(
      element.shadowRoot.querySelector("[data-enrichment-disclaimer]")
    ).not.toBeNull();
    expect(
      element.shadowRoot.querySelector("[data-supplemental-updates]")
    ).not.toBeNull();
    expect(
      element.shadowRoot.querySelector("[data-public-research]")
    ).toBeNull();
  });

  it("shows leadership fields only when supplied and humanizes other kinds", async () => {
    const updates = supplementalCompanyUpdates({
      items: [
        supplementalCompanyUpdates().items[0],
        {
          id: "E4",
          kind: "market_expansion",
          date: "2026-09-01",
          date_type: "event",
          fact: "The company entered a new market.",
          relevance: "No opportunity relationship was established.",
          suggested_action: "Verify before using this information."
        }
      ]
    });
    const element = await createComponent(
      response({
        enrichment: publicResearch({
          supplemental_company_updates: updates
        })
      })
    );
    const cards = [
      ...element.shadowRoot.querySelectorAll(".supplemental-card")
    ];

    expect(cards[0].querySelector(".research-person").textContent).toContain(
      "Example Person · Chief Operating Officer"
    );
    expect(cards[1].querySelector(".research-person")).toBeNull();
    expect(cards[1].textContent).toContain("Market Expansion");
    expect(researchDates(cards[1])).toEqual([
      { text: "Event date:", value: "2026-09-01", timeZone: "UTC" }
    ]);
  });

  it("renders leadership and priority findings with inline evidence badges", async () => {
    const element = await createComponent();
    const research = element.shadowRoot.querySelector("[data-public-research]");
    const executive = element.shadowRoot.querySelector(
      '[data-summary-section="executive"]'
    );

    expect(research).not.toBeNull();
    expect(research.open).toBe(true);
    expect(research.textContent).toContain("Current Leadership");
    expect(research.textContent).toContain("Company Direction and Priorities");
    expect(research.textContent).toContain(
      "Avery Example · Chief Operating Officer"
    );
    expect(researchDates(research)).toEqual([
      { text: "Current as of", value: "2026-09-18", timeZone: "UTC" },
      { text: "Event date:", value: "2026-01-14", timeZone: "UTC" }
    ]);
    expect(research.textContent).toContain("Supported public fact");
    expect(research.textContent).toContain("Inference: Confirm Avery's role");
    expect(research.textContent).toContain(
      "Public signals do not prove customer requirements, budget, buying intent, or decision authority."
    );

    expect(
      [...executive.querySelectorAll(".evidence-badge")].map((badge) =>
        badge.textContent.trim()
      )
    ).toEqual(["Public evidence E1", "Public evidence E3"]);
    expect(formattedValues(executive).join(" ")).toContain("[E99]");
    expect(formattedValues(executive).join(" ")).toContain(
      "<strong>Operational alignment</strong>"
    );
  });

  it("opens, scrolls to, focuses, and highlights the selected finding", async () => {
    const element = await createComponent();
    const research = element.shadowRoot.querySelector("[data-public-research]");
    const target = element.shadowRoot.querySelector(
      '[data-research-finding="E3"]'
    );
    const badge = element.shadowRoot.querySelector(
      '[data-summary-section="executive"] .evidence-badge[data-evidence-id="E3"]'
    );
    const scrollIntoView = jest.fn();
    target.scrollIntoView = scrollIntoView;
    const focus = jest.spyOn(target, "focus");
    research.open = false;

    badge.click();

    expect(research.open).toBe(true);
    expect(scrollIntoView).toHaveBeenCalledWith({
      behavior: "smooth",
      block: "center"
    });
    expect(focus).toHaveBeenCalledTimes(1);
    expect(target.classList).toContain("is-highlighted");
    expect(badge.getAttribute("aria-label")).toBe(
      "View public research evidence E3"
    );
  });

  it("resolves finding sources by source.index with safe labels and links", async () => {
    const element = await createComponent();
    const leadership = element.shadowRoot.querySelector(
      '[data-research-finding="E1"]'
    );
    const sources = [
      ...leadership.querySelectorAll(".finding-sources [data-source-index]")
    ];

    expect(sources.map((source) => source.dataset.sourceIndex)).toEqual([
      "0",
      "9",
      "3",
      "0"
    ]);
    const titleFallback = leadership.querySelector('a[data-source-index="0"]');
    expect(titleFallback.textContent.trim()).toBe("Executive profile");
    expect(titleFallback.target).toBe("_blank");
    expect(titleFallback.rel).toBe("noopener noreferrer");
    expect(leadership.querySelector('a[data-source-index="3"]')).toBeNull();
    expect(
      leadership.querySelector('span[data-source-index="3"]')
    ).not.toBeNull();

    const prioritySource = element.shadowRoot.querySelector(
      '[data-research-finding="E3"] [data-source-index="4"]'
    );
    expect(prioritySource.textContent.trim()).toBe("Source 5");
    expect(element.shadowRoot.textContent).not.toContain(GOOGLE_REDIRECT_URL);

    const aggregateSources = element.shadowRoot.querySelector(
      '[data-testid="research-sources"]'
    );
    expect(aggregateSources.open).toBe(false);
    expect(aggregateSources.querySelector("summary").textContent).toContain(
      "Sources (5)"
    );
    expect(aggregateSources.textContent).toContain("All research sources");
    expect(aggregateSources.textContent).toContain("Additional research");
  });

  it("keeps queries collapsed and reports the exact LWS suggestion limitation", async () => {
    const element = await createComponent();
    const searches = element.shadowRoot.querySelector(
      '[data-testid="research-searches"]'
    );
    const blocker = element.shadowRoot.querySelector(
      '[data-testid="search-suggestions-blocker"]'
    );

    expect(searches.open).toBe(false);
    expect(searches.querySelector("summary").textContent).toContain(
      "Searches performed (2)"
    );
    expect(searches.textContent).toContain("Example company leadership");
    expect(blocker.textContent).toContain("Google Search Suggestions");
    expect(blocker.textContent).toContain(
      "Lightning Web Security sanitizes HTML and SVG strings inserted into the DOM"
    );
    expect(
      element.shadowRoot.querySelector('a[href="https://google.com"]')
    ).toBeNull();
    expect(element.shadowRoot.textContent).not.toContain("provider-chip");
  });

  it("skips only malformed findings and does not fail the summary", async () => {
    const enrichment = publicResearch({
      findings: [
        null,
        { id: "not-evidence", kind: "leadership", fact: "Invalid ID" },
        { id: "E2", kind: "unknown", fact: "Invalid kind" },
        publicResearch().findings[1]
      ]
    });
    const element = await createComponent(response({ enrichment }));

    expect(element.shadowRoot.querySelector(".status-error")).toBeNull();
    expect(
      element.shadowRoot.querySelector('[data-research-finding="E3"]')
    ).not.toBeNull();
    expect(
      element.shadowRoot.querySelector('[data-research-finding="E2"]')
    ).toBeNull();
    expect(
      element.shadowRoot.querySelector('[data-summary-section="executive"]')
    ).not.toBeNull();
  });

  it("ignores wholly malformed enrichment without changing summary success", async () => {
    const element = await createComponent(response({ enrichment: "invalid" }));

    expect(
      element.shadowRoot.querySelector("[data-public-research]")
    ).toBeNull();
    expect(element.shadowRoot.querySelector(".status-error")).toBeNull();
    expect(
      element.shadowRoot.querySelector('[data-summary-section="executive"]')
    ).not.toBeNull();
  });

  it("does not add evidence UI to Deal Score or Opportunity History", async () => {
    const element = await createComponent();
    const score = element.shadowRoot.querySelector(
      '[data-summary-section="score"]'
    );
    const history = element.shadowRoot.querySelector(
      '[data-summary-section="history"]'
    );

    expect(score.querySelector(".evidence-badge")).toBeNull();
    expect(history.querySelector(".evidence-badge")).toBeNull();
    expect(formattedValues(score).join(" ")).toContain("[E1]");
    expect(formattedValues(history).join(" ")).toContain("[E3]");
  });

  it("renders supported strong markup in Deal Score and Opportunity History", async () => {
    const element = await createComponent(
      response({
        cards: [
          {
            title: "Overall Deal Score",
            badge: "50/100 (Needs Attention)",
            items: [
              "Strong late-stage positioning from <strong>Stage 5 (Agreement)</strong>."
            ]
          },
          {
            title: "Opportunity History & Stage Journey",
            items: [
              "The opportunity remained at <strong>Stage 5 (Agreement)</strong>."
            ]
          }
        ],
        enrichment: undefined
      })
    );
    const score = element.shadowRoot.querySelector(
      '[data-summary-section="score"]'
    );
    const history = element.shadowRoot.querySelector(
      '[data-summary-section="history"]'
    );

    expect(score.textContent).not.toContain("<strong>");
    expect(history.textContent).not.toContain("<strong>");
    expect(formattedValues(score)).toContain(
      "Strong late-stage positioning from <strong>Stage 5 (Agreement)</strong>."
    );
    expect(formattedValues(history)).toContain(
      "The opportunity remained at <strong>Stage 5 (Agreement)</strong>."
    );
  });

  it("uses only the original callout across evidence navigation and reopen", async () => {
    const element = await createComponent();

    element.shadowRoot.querySelector(".evidence-badge").click();
    element.shadowRoot.querySelector(".close-button").click();
    element.shadowRoot.querySelector("[data-view-summary]").click();
    await flushPromises();

    expect(makeGCPCallout).toHaveBeenCalledTimes(1);
  });

  it("caches one raw response without duplicating enrichment sources", async () => {
    await createComponent();

    const cachedEntry = JSON.parse(localStorage.getItem(CACHE_KEY));
    expect(cachedEntry.cachedAt).toEqual(expect.any(Number));
    expect(cachedEntry.summary.cards).toEqual(summaryCards());
    expect(cachedEntry.summary.opportunity_enrichment).toEqual(
      publicResearch()
    );
    expect(cachedEntry.summary.opportunity_enrichment.sources).toHaveLength(5);
  });
});

const CASE_ID = "500000000000001AAA";
const TASK_ID = "00T000000000001AAA";

function closedDealResponse({ state = "closed_won", references } = {}) {
  return JSON.stringify({
    success: true,
    cards: [
      { title: "Overall Deal Score", badge: "100/100 (Won)", items: [] },
      {
        title: "Executive Summary",
        items: [
          "Salesforce Classification: Upsell · Public Sector · RingCX",
          "Status: Open case <strong>00012345</strong> still needs an owner."
        ]
      },
      { title: "Win Factors", items: ["Should stay hidden"] },
      { title: "Risk Flags", items: ["Should stay hidden"] },
      { title: "Next Best Actions", items: ["Confirm onboarding owner"] },
      {
        title: "Post-Close Actions",
        items: ["Kickoff: Schedule onboarding by 06.10.2026 for 00012345"]
      },
      {
        title: "Opportunity History & Stage Journey",
        items: ["Closed on 30.09.2026 after call Discovery call"]
      }
    ],
    deal_state: {
      state,
      is_closed: true,
      score: state === "closed_won" ? 100 : 0
    },
    salesforce_fields: {
      deal_motion: "Upsell",
      sector: "Public Sector",
      npi_product_categories: ["RingCX", "ringcx ", "AIR"]
    },
    record_references: references ?? [
      {
        object_type: "Case",
        id: CASE_ID,
        label: "00012345",
        case_number: "00012345",
        mentioned_in: ["Executive Summary", "Post-Close Actions"]
      },
      {
        object_type: "Task",
        id: TASK_ID,
        label: "Discovery call",
        activity_kind: "Call",
        mentioned_in: ["Opportunity History & Stage Journey"]
      }
    ]
  });
}

describe("opportunitySummary record links and dates", () => {
  const references = [
    { objectApiName: "Case", recordId: CASE_ID, label: "00012345" }
  ];

  it("links a label inside strong markup and keeps both sides balanced", () => {
    const segments = linkRecordReferences(
      "Open case <strong>00012345 &amp; more</strong> today",
      references,
      "line"
    );
    expect(segments.map((segment) => segment.content || segment.label)).toEqual(
      ["Open case ", "00012345", "<strong> &amp; more</strong> today"]
    );
    expect(segments[1]).toMatchObject({
      isRecordLink: true,
      recordId: CASE_ID,
      objectApiName: "Case"
    });
  });

  it("matches across tags and entities on plain text only", () => {
    const segments = linkRecordReferences(
      "Ticket <strong>R&amp;D</strong> 42 is open",
      [{ objectApiName: "Case", recordId: CASE_ID, label: "R&D 42" }],
      "line"
    );
    const link = segments.find((segment) => segment.isRecordLink);
    expect(link.label).toBe("R&D 42");
    expect(segments[0].content).toBe("Ticket ");
    expect(segments[segments.length - 1].content).toBe(" is open");
  });

  it("does not link a label that is part of a longer word or number", () => {
    const segments = linkRecordReferences(
      "Case 000123456 and X00012345",
      references,
      "line"
    );
    expect(segments).toHaveLength(1);
    expect(segments[0].isRecordLink).toBeUndefined();
  });

  it("formats date-only ISO values in UTC and keeps partial precision", () => {
    expect(buildDateParts("2026-09-18", "as_of")).toMatchObject({
      prefix: "Current as of",
      isIso: true,
      value: "2026-09-18",
      month: "short",
      day: "numeric",
      timeZone: "UTC"
    });
    expect(buildDateParts("2026-05", "event")).toMatchObject({
      value: "2026-05-01",
      month: "short",
      day: undefined
    });
    expect(buildDateParts("2026-09-18T14:00:00Z", "publication")).toMatchObject(
      { value: "2026-09-18T14:00:00Z", timeZone: undefined }
    );
    expect(buildDateParts("Q3 2026", "event")).toMatchObject({
      isIso: false,
      text: "Q3 2026"
    });
    expect(buildDateParts("2026-09-18", "unknown").hasDate).toBe(false);
  });

  it("de-duplicates NPI chips that differ only in case or spacing", () => {
    expect(
      buildSalesforceChips({
        deal_motion: "Upsell",
        npi_product_categories: ["RingCX", "ringcx ", "AIR", 7]
      }).map((chip) => `${chip.label}:${chip.value}`)
    ).toEqual([
      "Order Type:Upsell",
      "NPI Product Category:RingCX",
      "NPI Product Category:AIR"
    ]);
  });

  it("labels chips with Salesforce field labels and humanizes unknown keys", () => {
    expect(
      buildSalesforceChips(
        {
          deal_motion: "Upsell",
          sector: "Public Sector",
          renewal_term: "12"
        },
        {
          Opportunity: { fields: { Order_Type__c: { label: "Deal Motion" } } },
          Account: { fields: { Sector__c: { label: "Branche" } } }
        }
      ).map((chip) => `${chip.label}:${chip.value}`)
    ).toEqual([
      "Deal Motion:Upsell",
      "Branche:Public Sector",
      "Renewal Term:12"
    ]);
  });
});

describe("opportunitySummary closed deals", () => {
  beforeEach(() => {
    resetLabels();
    localStorage.clear();
    isOpportunitySummaryEnabled.mockResolvedValue(true);
    logAIHEvent.mockResolvedValue();
  });

  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
    jest.restoreAllMocks();
  });

  function section(element, name) {
    return element.shadowRoot.querySelector(`[data-summary-section="${name}"]`);
  }

  it("hides Risk Flags and Win Factors and shows Post-Close Actions", async () => {
    const element = await createComponent(closedDealResponse());

    expect(section(element, "risk")).toBeNull();
    expect(section(element, "win")).toBeNull();
    expect(section(element, "plan")).toBeNull();
    const postClose = section(element, "postclose");
    expect(postClose.querySelector(".panel-title").textContent).toBe(
      "Post-Close Actions"
    );
    expect(postClose.querySelector(".timeline-label").textContent).toBe(
      "Kickoff"
    );
    expect(section(element, "actions")).not.toBeNull();
  });

  it("hides the tiles for Closed Lost too", async () => {
    const element = await createComponent(
      closedDealResponse({ state: "closed_lost" })
    );
    expect(section(element, "risk")).toBeNull();
    expect(section(element, "win")).toBeNull();
    expect(section(element, "postclose")).not.toBeNull();
  });

  it("keeps Risk Flags, Win Factors and Close Plan on open deals", async () => {
    const element = await createComponent(
      JSON.stringify({
        success: true,
        cards: [
          { title: "Win Factors", items: ["Champion engaged"] },
          { title: "Risk Flags", items: ["No budget"] },
          { title: "Close Plan", items: ["Legal: Send MSA"] }
        ],
        deal_state: { state: "open", is_closed: false }
      })
    );
    expect(section(element, "risk")).not.toBeNull();
    expect(section(element, "win")).not.toBeNull();
    expect(section(element, "plan")).not.toBeNull();
  });

  it("ignores a deal_state whose is_closed is not a boolean", async () => {
    const element = await createComponent(
      JSON.stringify({
        success: true,
        cards: [{ title: "Risk Flags", items: ["No budget"] }],
        deal_state: { state: "closed_won", is_closed: "true" }
      })
    );
    expect(section(element, "risk")).not.toBeNull();
  });

  it("shows the classification line as-is and Salesforce field chips", async () => {
    const element = await createComponent(closedDealResponse());
    const executive = section(element, "executive");

    expect(executive.textContent).toContain("Salesforce Classification");
    expect(formattedValues(executive)).toContain(
      "Upsell · Public Sector · RingCX"
    );
    const chips = [...executive.querySelectorAll(".salesforce-chip")].map(
      (chip) => chip.textContent.replace(/\s+/g, " ").trim()
    );
    expect(chips).toEqual([
      "Order Type: Upsell",
      "Sector: Public Sector",
      "NPI Product Category: RingCX",
      "NPI Product Category: AIR"
    ]);
  });

  it("links references only in their mentioned_in sections and opens them safely in a new tab", async () => {
    const element = await createComponent(closedDealResponse());

    const executiveLinks = section(element, "executive").querySelectorAll(
      "a.record-link"
    );
    expect(executiveLinks).toHaveLength(1);
    expect(executiveLinks[0].textContent).toBe("00012345");
    expect(executiveLinks[0].dataset.recordId).toBe(CASE_ID);
    expect(
      section(element, "postclose").querySelector("a.record-link").textContent
    ).toBe("00012345");
    expect(
      section(element, "history").querySelector("a.record-link").dataset
        .objectApiName
    ).toBe("Task");
    expect(
      section(element, "actions").querySelector("a.record-link")
    ).toBeNull();

    expect(executiveLinks[0].getAttribute("href")).toBe(
      `/lightning/r/Case/${CASE_ID}/view`
    );
    expect(executiveLinks[0].getAttribute("target")).toBe("_blank");
    expect(executiveLinks[0].getAttribute("rel")).toBe("noopener noreferrer");
  });

  it("drops references with unsupported objects or mismatched Ids", async () => {
    const element = await createComponent(
      closedDealResponse({
        references: [
          {
            object_type: "Quote",
            id: "0Q0000000000001AAA",
            label: "00012345",
            mentioned_in: ["Executive Summary"]
          },
          {
            object_type: "Case",
            id: TASK_ID,
            label: "00012345",
            mentioned_in: ["Executive Summary"]
          }
        ]
      })
    );
    expect(element.shadowRoot.querySelector("a.record-link")).toBeNull();
  });

  it("caches deal state and references so a restored summary keeps the closed layout", async () => {
    await createComponent(closedDealResponse());
    const cached = JSON.parse(localStorage.getItem(CACHE_KEY));
    expect(cached.summary.deal_state.is_closed).toBe(true);
    expect(cached.summary.record_references).toHaveLength(2);

    document.body.removeChild(document.body.firstChild);
    makeGCPCallout.mockClear();
    const element = await mountComponent();
    element.shadowRoot.querySelector("[data-view-summary]").click();
    await flushPromises();

    expect(makeGCPCallout).not.toHaveBeenCalled();
    expect(section(element, "risk")).toBeNull();
    expect(element.shadowRoot.querySelector("a.record-link")).not.toBeNull();
  });
});

describe("opportunitySummary evidence citations and plan labels", () => {
  beforeEach(() => {
    resetLabels();
    localStorage.clear();
    isOpportunitySummaryEnabled.mockResolvedValue(true);
    logAIHEvent.mockResolvedValue();
  });

  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
    jest.restoreAllMocks();
  });

  const findings = new Map([
    ["E3", {}],
    ["E4", {}]
  ]);

  it("turns bolded citations into badges without leaving tags behind", () => {
    const segments = parseInlineEvidence(
      "Not confirmed in CRM notes [E3] [<strong>E4</strong>] and <strong>[E3]</strong>.",
      findings,
      "line"
    );
    expect(
      segments.filter((segment) => segment.isEvidence).map((s) => s.evidenceId)
    ).toEqual(["E3", "E4", "E3"]);
    const text = segments
      .filter((segment) => !segment.isEvidence)
      .map((segment) => segment.content)
      .join("");
    expect(text).not.toMatch(/<\/?strong>/);
    expect(citedEvidenceIds(["[ <b>E1</b> ] and [E2]"])).toEqual(
      new Set(["E1", "E2"])
    );
  });

  it("shows cited findings the service filed as supplemental as used research", async () => {
    const research = publicResearch();
    const element = await createComponent(
      response({
        cards: [
          {
            title: "Executive Summary",
            items: [
              "Inference: Signals are material [E1] [<strong>E3</strong>]"
            ]
          },
          { title: "Next Best Actions", items: ["Ask about the rollout [E3]"] }
        ],
        enrichment: {
          ...research,
          findings: [],
          supplemental_company_updates: {
            relationship_to_opportunity: "not_established",
            items: [...research.findings, ...supplementalCompanyUpdates().items]
          }
        }
      })
    );

    const badges = [
      ...element.shadowRoot.querySelectorAll(".evidence-badge")
    ].map((badge) => badge.dataset.evidenceId);
    expect(badges).toEqual(["E1", "E3", "E3"]);
    const research_ = element.shadowRoot.querySelector(
      "[data-public-research]"
    );
    expect(
      [...research_.querySelectorAll("[data-research-finding]")].map(
        (card) => card.dataset.researchFinding
      )
    ).toEqual(["E1", "E3"]);
    const supplemental = element.shadowRoot.querySelector(
      "[data-supplemental-updates]"
    );
    expect(supplemental.querySelectorAll(".supplemental-card")).toHaveLength(1);
    expect(supplemental.textContent).not.toContain("Avery Example");
  });

  it("strips markup from plan labels and keeps the emphasis in the text", () => {
    expect(
      splitLabel("By <strong>Oct 15, 2026</strong>: Update Salesforce")
    ).toEqual({
      label: "By Oct 15, 2026",
      text: "Update Salesforce",
      hasLabel: true
    });
    expect(
      splitLabel("<strong>By 15.10.2026: Update</strong> the buying team")
    ).toEqual({
      label: "By 15.10.2026",
      text: "<strong>Update</strong> the buying team",
      hasLabel: true
    });
    expect(
      splitLabel("<strong>After <em>validation</em>:</strong> Advance the deal")
    ).toEqual({
      label: "After validation",
      text: "Advance the deal",
      hasLabel: true
    });
    expect(splitLabel("The customer said no. Then: nothing").hasLabel).toBe(
      false
    );
  });

  it("renders a Close Plan deadline label as plain text", async () => {
    const element = await createComponent(
      response({
        cards: [
          {
            title: "Close Plan",
            items: ["By <strong>Oct 15, 2026</strong>: Update Salesforce"]
          }
        ],
        enrichment: undefined
      })
    );
    const label = element.shadowRoot.querySelector(
      '[data-summary-section="plan"] .timeline-label'
    );
    expect(label.textContent).toBe("By Oct 15, 2026");
  });
});

describe("opportunitySummary GCP revision 00400 label rules", () => {
  beforeEach(() => {
    resetLabels();
    localStorage.clear();
    isOpportunitySummaryEnabled.mockResolvedValue(true);
    logAIHEvent.mockResolvedValue();
  });

  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
    jest.restoreAllMocks();
  });

  const NOOKS_TASK_ID = "00T000000000002AAA";

  it("links a Task label that starts with [ and ends with a name", async () => {
    const label = "[Nooks Call] - Convo - Follow-Up - Nituna Diaz";
    const element = await createComponent(
      JSON.stringify({
        success: true,
        cards: [
          {
            title: "Opportunity History & Stage Journey",
            items: [`Logged <strong>${label}</strong>, then a quote.`]
          }
        ],
        record_references: [
          {
            object_type: "Task",
            id: NOOKS_TASK_ID,
            label,
            activity_kind: "Call",
            mentioned_in: ["Opportunity History & Stage Journey"]
          }
        ]
      })
    );
    const link = element.shadowRoot.querySelector(
      '[data-summary-section="history"] a.record-link'
    );
    expect(link.textContent).toBe(label);
    expect(link.dataset.recordId).toBe(NOOKS_TASK_ID);
  });

  it("links labels with punctuation at either edge, wherever they sit", () => {
    const references = [
      {
        objectApiName: "Task",
        recordId: NOOKS_TASK_ID,
        label: "(Discovery call)"
      }
    ];
    const segments = linkRecordReferences(
      "See notes(Discovery call)for detail",
      references,
      "line"
    );
    expect(segments.find((segment) => segment.isRecordLink).label).toBe(
      "(Discovery call)"
    );
  });

  it("links a shortened, re-cased call label that is not the Task subject", () => {
    // Subject: "[Nooks Call] - Convo - Follow-Up - Nituna Diaz - by Rep One"
    const segments = linkRecordReferences(
      "Follow up on the nooks call with Nituna Diaz.",
      [
        {
          objectApiName: "Task",
          recordId: NOOKS_TASK_ID,
          label: "nooks call with Nituna Diaz"
        }
      ],
      "line"
    );
    expect(segments.find((segment) => segment.isRecordLink).recordId).toBe(
      NOOKS_TASK_ID
    );
  });

  it("matches labels whose spaces are U+202F or U+00A0", () => {
    const references = [
      {
        objectApiName: "Event",
        recordId: "00U000000000001AAA",
        label: "Demo at 9:19 AM PDT"
      }
    ];
    for (const line of [
      "Booked Demo at 9:19\u202fAM PDT with IT.",
      "Booked Demo at 9:19&nbsp;AM PDT with IT.",
      "Booked Demo at 9:19\u00a0AM PDT with IT."
    ]) {
      const link = linkRecordReferences(line, references, "line").find(
        (segment) => segment.isRecordLink
      );
      expect(link).toBeDefined();
      expect(link.label.replace(/\s/g, " ")).toBe("Demo at 9:19 AM PDT");
    }
    const narrowLabel = linkRecordReferences(
      "Booked Demo at 9:19 AM PDT with IT.",
      [{ ...references[0], label: "Demo at 9:19\u202fAM PDT" }],
      "line"
    );
    expect(narrowLabel.some((segment) => segment.isRecordLink)).toBe(true);
  });

  it("does not split a label on the colon inside a localized time", () => {
    expect(splitLabel("At 9:19\u202fAM PDT: Call the buyer")).toEqual({
      label: "At 9:19 AM PDT",
      text: "Call the buyer",
      hasLabel: true
    });
    expect(splitLabel("Call at 9:19\u202fAM PDT with the buyer").hasLabel).toBe(
      false
    );
  });
});

describe("opportunitySummary account and contact links", () => {
  beforeEach(() => {
    resetLabels();
    localStorage.clear();
    isOpportunitySummaryEnabled.mockResolvedValue(true);
    logAIHEvent.mockResolvedValue();
  });

  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
    jest.restoreAllMocks();
  });

  it("links the account and contact names in every section they appear", async () => {
    const sections = [
      "Overall Deal Score",
      "Executive Summary",
      "Next Best Actions",
      "Close Plan",
      "Opportunity History & Stage Journey"
    ];
    const element = await createComponent(
      JSON.stringify({
        success: true,
        cards: [
          {
            title: "Overall Deal Score",
            badge: "62/100 (Moderate)",
            items: ["Note"]
          },
          {
            title: "Executive Summary",
            items: [
              "Account: <strong>Bank of America Corporation</strong>",
              "Contact: <strong>Morgan Banking DevGSS Test</strong> is the evaluator"
            ]
          },
          {
            title: "Next Best Actions",
            items: ["Ask <strong>Morgan Banking DevGSS Test</strong>’s team"]
          },
          {
            title: "Close Plan",
            items: ["Now: Book Morgan Banking DevGSS Test"]
          },
          {
            title: "Opportunity History & Stage Journey",
            items: ["Bank of America Corporation moved to Stage 3"]
          }
        ],
        record_references: [
          {
            object_type: "Account",
            id: "001000000000001AAA",
            label: "Bank of America Corporation",
            mentioned_in: sections,
            source: "salesforce"
          },
          {
            object_type: "Contact",
            id: "003000000000001AAA",
            label: "Morgan Banking DevGSS Test",
            mentioned_in: sections,
            source: "salesforce"
          }
        ]
      })
    );
    const links = [...element.shadowRoot.querySelectorAll("a.record-link")].map(
      (link) => `${link.dataset.objectApiName}:${link.textContent}`
    );
    expect(links.sort()).toEqual([
      "Account:Bank of America Corporation",
      "Account:Bank of America Corporation",
      "Contact:Morgan Banking DevGSS Test",
      "Contact:Morgan Banking DevGSS Test",
      "Contact:Morgan Banking DevGSS Test"
    ]);
    const accountLink = element.shadowRoot.querySelector("a.record-link");
    expect(accountLink.getAttribute("href")).toBe(
      "/lightning/r/Account/001000000000001AAA/view"
    );
    expect(accountLink.getAttribute("target")).toBe("_blank");
    expect(accountLink.getAttribute("rel")).toBe("noopener noreferrer");
  });
});

describe("opportunitySummary links for every referenced object", () => {
  beforeEach(() => {
    resetLabels();
    localStorage.clear();
    isOpportunitySummaryEnabled.mockResolvedValue(true);
    logAIHEvent.mockResolvedValue();
  });

  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
    jest.restoreAllMocks();
  });

  it("links owner, related opportunity, product, case, task and event names", async () => {
    const sections = [
      "Executive Summary",
      "Opportunity History & Stage Journey"
    ];
    const reference = (object_type, id, label) => ({
      object_type,
      id,
      label,
      mentioned_in: sections,
      source: "salesforce"
    });
    const element = await createComponent(
      JSON.stringify({
        success: true,
        cards: [
          {
            title: "Executive Summary",
            items: [
              "Owner Avery Rep is pricing <strong>Contact Center: Data Connector  (per connector)</strong>",
              "Case 00012345 (Porting delay on main line) is open"
            ]
          },
          {
            title: "Opportunity History & Stage Journey",
            items: [
              "Follows Example Co - Renewal 2025; Discovery call with IT and Quarterly business review held"
            ]
          }
        ],
        record_references: [
          reference("User", "005000000000001AAA", "Avery Rep"),
          reference(
            "Opportunity",
            "006000000000002AAA",
            "Example Co - Renewal 2025"
          ),
          reference(
            "Product2",
            "01t000000000001AAA",
            "Contact Center: Data Connector  (per connector)"
          ),
          reference("Case", "500000000000001AAA", "00012345"),
          reference("Case", "500000000000001AAA", "Porting delay on main line"),
          reference("Task", "00T000000000001AAA", "Discovery call with IT"),
          reference("Event", "00U000000000001AAA", "Quarterly business review")
        ]
      })
    );
    const links = [...element.shadowRoot.querySelectorAll("a.record-link")]
      .map((link) => `${link.dataset.objectApiName}:${link.textContent}`)
      .sort();
    expect(links).toEqual([
      "Case:00012345",
      "Case:Porting delay on main line",
      "Event:Quarterly business review",
      "Opportunity:Example Co - Renewal 2025",
      "Product2:Contact Center: Data Connector  (per connector)",
      "Task:Discovery call with IT",
      "User:Avery Rep"
    ]);
  });
});

describe("opportunitySummary GCP case links stay as they were", () => {
  beforeEach(() => {
    resetLabels();
    localStorage.clear();
    isOpportunitySummaryEnabled.mockResolvedValue(true);
    logAIHEvent.mockResolvedValue();
  });

  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
    jest.restoreAllMocks();
  });

  it("keeps a GCP case link in its own sections next to Salesforce name links", async () => {
    const element = await createComponent(
      JSON.stringify({
        success: true,
        cards: [
          {
            title: "Executive Summary",
            items: ["Open case <strong>00012345</strong> for Example Co"]
          },
          {
            title: "Next Best Actions",
            items: ["Close case 00012345 with Example Co"]
          },
          {
            title: "Close Plan",
            items: ["Riley Buyer: confirm budget with Example Co"]
          }
        ],
        record_references: [
          {
            object_type: "Case",
            id: CASE_ID,
            label: "00012345",
            case_number: "00012345",
            mentioned_in: ["Executive Summary"]
          },
          {
            object_type: "Account",
            id: "001000000000001AAA",
            label: "Example Co",
            mentioned_in: [
              "Executive Summary",
              "Next Best Actions",
              "Close Plan"
            ],
            source: "salesforce"
          },
          {
            object_type: "Contact",
            id: "003000000000001AAA",
            label: "Riley Buyer",
            mentioned_in: [
              "Executive Summary",
              "Next Best Actions",
              "Close Plan"
            ],
            source: "salesforce"
          }
        ]
      })
    );
    const linksIn = (name) =>
      [
        ...element.shadowRoot.querySelectorAll(
          `[data-summary-section="${name}"] a.record-link`
        )
      ].map((link) => `${link.dataset.objectApiName}:${link.textContent}`);

    expect(linksIn("executive")).toEqual([
      "Case:00012345",
      "Account:Example Co"
    ]);
    expect(linksIn("actions")).toEqual(["Account:Example Co"]);
    expect(linksIn("plan")).toEqual([
      "Contact:Riley Buyer",
      "Account:Example Co"
    ]);
    expect(
      element.shadowRoot.querySelector(
        '[data-summary-section="plan"] .timeline-label'
      ).textContent
    ).toBe("Riley Buyer");
  });

  it("does not split a line at the colon inside a product name", async () => {
    const element = await createComponent(
      JSON.stringify({
        success: true,
        cards: [
          {
            title: "Executive Summary",
            items: [
              "Proposal covers <strong>Contact Center: Data Connector</strong>",
              "Products: Contact Center: Data Connector"
            ]
          }
        ],
        record_references: [
          {
            object_type: "Product2",
            id: "01t000000000001AAA",
            label: "Contact Center: Data Connector",
            mentioned_in: ["Executive Summary"],
            source: "salesforce"
          }
        ]
      })
    );
    const executive = element.shadowRoot.querySelector(
      '[data-summary-section="executive"]'
    );
    expect(
      [...executive.querySelectorAll("a.record-link")].map(
        (link) => link.textContent
      )
    ).toEqual([
      "Contact Center: Data Connector",
      "Contact Center: Data Connector"
    ]);
    expect(
      [...executive.querySelectorAll(".fact-label")].map(
        (label) => label.textContent
      )
    ).toEqual(["Products"]);
  });
});
