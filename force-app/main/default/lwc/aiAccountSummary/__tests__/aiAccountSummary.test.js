import { resetLabels } from "../../../../../../test/jest-mocks/accountSummaryLabels";
import { createElement } from "lwc";
import AiAccountSummary from "c/aiAccountSummary";
import makeGCPCallout from "@salesforce/apex/GCPCalloutForAccountSummary.makeGCPCallout";
import isAccountSummaryEnabled from "@salesforce/apex/GCPCalloutForAccountSummary.isAccountSummaryEnabled";
import logAIHEvent from "@salesforce/apex/GCPCalloutForOpportunitySummary.logAIHEvent";
import * as pdfDownload from "../aiAccountSummaryPdfDownload";

jest.mock(
  "@salesforce/apex/GCPCalloutForAccountSummary.makeGCPCallout",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/GCPCalloutForAccountSummary.isAccountSummaryEnabled",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/GCPCalloutForOpportunitySummary.logAIHEvent",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock("@salesforce/user/Id", () => ({ default: "005000000000001AAA" }), {
  virtual: true
});

const RESPONSE = require("./data/accountSummaryResponse.json");
const RECORD_ID = "001TH00000iUv7bYAC";
const CACHE_KEY = `aiAccountSummary:v1:005000000000001AAA:${RECORD_ID}`;
const ONE_HOUR_MS = 60 * 60 * 1000;
const MAX_CACHE_BYTES = 512 * 1024;

async function flushPromises() {
  for (let index = 0; index < 5; index += 1) {
    // eslint-disable-next-line no-await-in-loop
    await Promise.resolve();
  }
}

async function mount() {
  const element = createElement("c-ai-account-summary", {
    is: AiAccountSummary
  });
  element.recordId = RECORD_ID;
  document.body.appendChild(element);
  await flushPromises();
  return element;
}

function query(element, selector) {
  return element.shadowRoot.querySelector(selector);
}

async function generate(element) {
  query(element, "[data-generate-summary]").click();
  await flushPromises();
}

describe("c-ai-account-summary", () => {
  beforeEach(() => {
    resetLabels();
    window.localStorage.clear();
    isAccountSummaryEnabled.mockResolvedValue(true);
    makeGCPCallout.mockResolvedValue(JSON.stringify(RESPONSE));
    logAIHEvent.mockResolvedValue(undefined);
  });

  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders nothing while the feature toggle is off", async () => {
    isAccountSummaryEnabled.mockResolvedValue(false);
    const element = await mount();
    expect(query(element, "[data-summary-launcher]")).toBeNull();
  });

  it("generates on demand and sends only the record Id", async () => {
    const element = await mount();
    expect(makeGCPCallout).not.toHaveBeenCalled();

    await generate(element);

    expect(makeGCPCallout).toHaveBeenCalledWith({ recordId: RECORD_ID });
    expect(query(element, "[data-summary-ready]")).not.toBeNull();
  });

  it("opens all section cards with rich-text prose and logs one view", async () => {
    const element = await mount();
    await generate(element);
    query(element, "[data-view-summary]").click();
    await flushPromises();

    [
      "header",
      "flag",
      "metrics",
      "signals",
      "actions",
      "opportunities",
      "cases",
      "history",
      "contacts",
      "research"
    ].forEach((section) => {
      expect(
        query(element, `[data-summary-section="${section}"]`)
      ).not.toBeNull();
    });
    const narrative = element.shadowRoot.querySelectorAll(
      "[data-summary-narrative] lightning-formatted-rich-text"
    );
    expect(narrative).toHaveLength(2);
    expect(narrative[0].value).toContain("<strong>25.2%</strong>");
    expect(query(element, "[data-summary-score]").textContent).toBe("72");
    const shownText = element.shadowRoot.textContent;
    ["Opportunity.CloseDate", "next_step_missing_count"].forEach((sourceText) =>
      expect(shownText).not.toContain(sourceText)
    );
    expect(
      element.shadowRoot.querySelectorAll("[data-summary-signal] .src-line")
    ).toHaveLength(1);
    expect(query(element, "[data-summary-override]")).not.toBeNull();
    expect(logAIHEvent).toHaveBeenCalledTimes(1);
    expect(logAIHEvent).toHaveBeenCalledWith({
      eventType: "aih_view",
      subfeature: "Account Summary",
      feedback: null
    });
  });

  it("shows the five key metric tiles inside the header card", async () => {
    const element = await mount();
    await generate(element);
    query(element, "[data-view-summary]").click();
    await flushPromises();

    const header = query(element, '[data-summary-section="header"]');
    expect(
      header.querySelector('[data-summary-section="metrics"]')
    ).not.toBeNull();
    expect(header.querySelectorAll("[data-summary-tile]")).toHaveLength(5);
  });

  function responseWithOpportunities(count) {
    const rows = Array.from({ length: count }, (unused, index) => ({
      id: `006TH0000000${String(index).padStart(2, "0")}AAA`,
      name: `Deal ${index}`,
      close_date: `2026-10-${String(index + 1).padStart(2, "0")}`
    }));
    return JSON.stringify({
      ...RESPONSE,
      account_summary: {
        ...RESPONSE.account_summary,
        open_opportunities: { rows }
      }
    });
  }

  async function openOpportunities(count) {
    makeGCPCallout.mockResolvedValue(responseWithOpportunities(count));
    const element = await mount();
    await generate(element);
    query(element, "[data-view-summary]").click();
    await flushPromises();
    return element;
  }

  function opportunityRows(element) {
    return query(
      element,
      '[data-summary-section="opportunities"]'
    ).querySelectorAll("tbody tr");
  }

  it("shows three opportunities first and the rest on View more", async () => {
    const element = await openOpportunities(8);
    const toggle = query(element, '[data-list-toggle="opportunities"]');

    expect(opportunityRows(element)).toHaveLength(3);
    expect(toggle.textContent.trim()).toBe("View 5 more");
    expect(toggle.getAttribute("aria-expanded")).toBe("false");
    expect(
      query(element, '[data-summary-section="opportunities"] .count')
        .textContent
    ).toBe("8");
    expect(query(element, '[data-list-all="opportunities"]')).toBeNull();

    toggle.click();
    await flushPromises();
    expect(opportunityRows(element)).toHaveLength(8);
    expect(toggle.textContent.trim()).toBe("Show less");
    expect(toggle.getAttribute("aria-expanded")).toBe("true");

    toggle.click();
    await flushPromises();
    expect(opportunityRows(element)).toHaveLength(3);
  });

  it("links to the related list when there are more than ten", async () => {
    const element = await openOpportunities(14);
    query(element, '[data-list-toggle="opportunities"]').click();
    await flushPromises();

    expect(opportunityRows(element)).toHaveLength(10);
    const allLink = query(element, '[data-list-all="opportunities"]');
    expect(allLink.textContent).toBe("View all 14 in Salesforce");
    expect(allLink.getAttribute("href")).toBe(
      `/lightning/r/Account/${RECORD_ID}/related/Opportunities/view`
    );
  });

  it("shows no toggle when every row already fits", async () => {
    const element = await openOpportunities(2);
    expect(opportunityRows(element)).toHaveLength(2);
    expect(query(element, '[data-list-toggle="opportunities"]')).toBeNull();
  });

  it("collapses expanded lists when the modal opens again", async () => {
    const element = await openOpportunities(8);
    query(element, '[data-list-toggle="opportunities"]').click();
    await flushPromises();
    document.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape" }));
    await flushPromises();

    query(element, "[data-view-summary]").click();
    await flushPromises();
    expect(opportunityRows(element)).toHaveLength(3);
  });

  async function openWithHistoryEvents(count) {
    const events = Array.from({ length: count }, (unused, index) => ({
      type: "case",
      title: `Event ${index}`,
      date: "2026-09-01"
    }));
    makeGCPCallout.mockResolvedValue(
      JSON.stringify({
        ...RESPONSE,
        account_summary: {
          ...RESPONSE.account_summary,
          account_history: [{ period: "2026-09", events }]
        }
      })
    );
    const element = await mount();
    await generate(element);
    query(element, "[data-view-summary]").click();
    await flushPromises();
    return element;
  }

  it("lets account history grow while it has ten entries or fewer", async () => {
    const element = await openWithHistoryEvents(10);
    const scroller = query(element, "[data-history-scroll]");

    expect(scroller.className).toBe("history-scroll");
    expect(scroller.getAttribute("tabindex")).toBe("-1");
    expect(scroller.querySelectorAll("[data-history-event]")).toHaveLength(10);
  });

  it("scrolls account history past ten entries and keeps every entry", async () => {
    const element = await openWithHistoryEvents(25);
    const scroller = query(element, "[data-history-scroll]");

    expect(scroller.className).toBe(
      "history-scroll history-scroll_capped history-scroll_fade-bottom"
    );
    expect(scroller.getAttribute("tabindex")).toBe("0");
    expect(scroller.getAttribute("aria-label")).toBe("Account history");
    expect(scroller.querySelectorAll("[data-history-event]")).toHaveLength(25);
  });

  function scrollHistory(scroller, scrollTop) {
    Object.defineProperty(scroller, "scrollHeight", {
      configurable: true,
      value: 713
    });
    Object.defineProperty(scroller, "clientHeight", {
      configurable: true,
      value: 433
    });
    scroller.scrollTop = scrollTop;
    scroller.dispatchEvent(new CustomEvent("scroll"));
  }

  it("fades whichever history edge still has entries beyond it", async () => {
    const element = await openWithHistoryEvents(25);
    const scroller = query(element, "[data-history-scroll]");
    const fades = () =>
      ["history-scroll_fade-top", "history-scroll_fade-bottom"].filter((name) =>
        scroller.classList.contains(name)
      );

    expect(fades()).toEqual(["history-scroll_fade-bottom"]);

    scrollHistory(scroller, 100);
    await flushPromises();
    expect(fades()).toEqual([
      "history-scroll_fade-top",
      "history-scroll_fade-bottom"
    ]);

    scrollHistory(scroller, 280);
    await flushPromises();
    expect(fades()).toEqual(["history-scroll_fade-top"]);

    scrollHistory(scroller, 0);
    await flushPromises();
    expect(fades()).toEqual(["history-scroll_fade-bottom"]);
  });

  it("stops the history card at the bottom of the tenth entry", async () => {
    const rect = jest
      .spyOn(Element.prototype, "getBoundingClientRect")
      .mockImplementation(function measure() {
        return this.hasAttribute("data-history-event")
          ? { top: 280, bottom: 312 }
          : { top: 12, bottom: 400 };
      });
    try {
      const element = await openWithHistoryEvents(25);
      expect(query(element, "[data-history-scroll]").style.maxHeight).toBe(
        "300px"
      );
    } finally {
      rect.mockRestore();
    }
  });

  it("shows the Apex message when generation fails", async () => {
    makeGCPCallout.mockResolvedValue(
      JSON.stringify({ success: false, message: "Service is busy." })
    );
    const element = await mount();
    await generate(element);

    expect(query(element, ".launcher-state_error")).not.toBeNull();
    expect(
      query(element, ".launcher-state_error .launcher-message").textContent
    ).toBe("Service is busy.");
    expect(window.localStorage.getItem(CACHE_KEY)).toBeNull();
  });

  it("treats a success flag without account_summary as an error", async () => {
    makeGCPCallout.mockResolvedValue(JSON.stringify({ success: true }));
    const element = await mount();
    await generate(element);

    expect(query(element, ".launcher-state_error")).not.toBeNull();
  });

  it("caches a generated summary and restores it on the next load", async () => {
    const first = await mount();
    await generate(first);
    const cached = JSON.parse(window.localStorage.getItem(CACHE_KEY));
    expect(cached.summary.account_summary).toBeDefined();
    document.body.removeChild(first);

    makeGCPCallout.mockClear();
    const second = await mount();
    expect(query(second, "[data-summary-ready]")).not.toBeNull();
    expect(makeGCPCallout).not.toHaveBeenCalled();
  });

  it("keeps the summary and research in the cached entry", async () => {
    const element = await mount();
    await generate(element);

    const cached = JSON.parse(window.localStorage.getItem(CACHE_KEY));
    expect(Object.keys(cached.summary).sort()).toEqual([
      "account_enrichment",
      "account_summary",
      "as_of_date"
    ]);
    expect(cached.summary.success).toBeUndefined();
  });

  it("discards an expired entry and waits for an on-demand request", async () => {
    window.localStorage.setItem(
      CACHE_KEY,
      JSON.stringify({
        cachedAt: Date.now() - ONE_HOUR_MS - 1,
        summary: RESPONSE
      })
    );
    const element = await mount();

    expect(query(element, "[data-summary-ready]")).toBeNull();
    expect(query(element, "[data-generate-summary]")).not.toBeNull();
    expect(window.localStorage.getItem(CACHE_KEY)).toBeNull();
    expect(makeGCPCallout).not.toHaveBeenCalled();
  });

  it("ignores a malformed entry without blocking generation", async () => {
    window.localStorage.setItem(CACHE_KEY, "{not json");
    const element = await mount();
    expect(window.localStorage.getItem(CACHE_KEY)).toBeNull();

    await generate(element);
    expect(query(element, "[data-summary-ready]")).not.toBeNull();
  });

  it("does not cache an entry that is bigger than the storage budget", async () => {
    const oversized = {
      ...RESPONSE,
      account_summary: {
        ...RESPONSE.account_summary,
        padding: "x".repeat(MAX_CACHE_BYTES)
      }
    };
    makeGCPCallout.mockResolvedValue(JSON.stringify(oversized));
    const element = await mount();
    await generate(element);

    expect(query(element, "[data-summary-ready]")).not.toBeNull();
    expect(window.localStorage.getItem(CACHE_KEY)).toBeNull();
  });

  it("evicts the oldest other summary to stay within the budget", async () => {
    const oldKey = "aiAccountSummary:v1:005000000000001AAA:001OLD";
    const newerKey = "aiAccountSummary:v1:005000000000001AAA:001NEW";
    const filler = "y".repeat(Math.floor(MAX_CACHE_BYTES / 4) - 200);
    window.localStorage.setItem(
      oldKey,
      JSON.stringify({ cachedAt: Date.now() - 2000, summary: { filler } })
    );
    window.localStorage.setItem(
      newerKey,
      JSON.stringify({ cachedAt: Date.now() - 1000, summary: { filler } })
    );
    const element = await mount();
    await generate(element);

    expect(window.localStorage.getItem(CACHE_KEY)).not.toBeNull();
    expect(window.localStorage.getItem(oldKey)).toBeNull();
    expect(window.localStorage.getItem(newerKey)).not.toBeNull();
  });

  it("still renders a fresh summary when browser storage is unavailable", async () => {
    const setItem = jest
      .spyOn(Storage.prototype, "setItem")
      .mockImplementation(() => {
        throw new Error("QuotaExceededError");
      });
    try {
      const element = await mount();
      await generate(element);
      expect(query(element, "[data-summary-ready]")).not.toBeNull();
    } finally {
      setItem.mockRestore();
    }
  });

  it("drops the cache and calls the service again on refresh", async () => {
    const element = await mount();
    await generate(element);
    makeGCPCallout.mockClear();

    query(element, "[data-refresh-summary]").click();
    await flushPromises();

    expect(makeGCPCallout).toHaveBeenCalledTimes(1);
  });

  it("keeps research collapsed and opens it on an evidence click", async () => {
    const element = await mount();
    await generate(element);
    query(element, "[data-view-summary]").click();
    await flushPromises();

    const drawer = query(element, "[data-public-research]");
    expect(drawer.open).toBe(false);
    expect(element.shadowRoot.textContent).not.toContain("§");

    const evidence = query(element, '[data-evidence-id="E1"]');
    expect(evidence.textContent.trim()).toBe("E1");
    evidence.click();
    await flushPromises();

    const finding = query(element, '[data-research-finding="E1"]');
    expect(drawer.open).toBe(true);
    expect(finding.classList.contains("is-highlighted")).toBe(true);
    expect(query(element, '[data-research-group="additional"]').open).toBe(
      false
    );
  });

  it("keeps additional findings collapsed inside the drawer", async () => {
    const element = await mount();
    await generate(element);
    query(element, "[data-view-summary]").click();
    await flushPromises();

    const additional = query(element, '[data-research-group="additional"]');
    expect(additional.open).toBe(false);
    expect(
      additional.querySelector('[data-research-finding="E3"]')
    ).not.toBeNull();
    expect(
      query(element, '[data-research-group="cited"]').querySelectorAll(
        "[data-research-finding]"
      )
    ).toHaveLength(2);
  });

  it("closes the modal on Escape", async () => {
    const element = await mount();
    await generate(element);
    query(element, "[data-view-summary]").click();
    await flushPromises();

    document.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape" }));
    await flushPromises();

    expect(query(element, "[role=dialog]")).toBeNull();
  });

  describe("PDF download", () => {
    async function openSummary() {
      const element = await mount();
      await generate(element);
      query(element, "[data-view-summary]").click();
      await flushPromises();
      return element;
    }

    afterEach(() => {
      jest.restoreAllMocks();
    });

    it("does not load the PDF renderer until Download PDF is clicked", async () => {
      const load = jest
        .spyOn(pdfDownload, "loadPdfRenderer")
        .mockResolvedValue({});
      const element = await openSummary();

      expect(query(element, "[data-download-pdf]").textContent).toContain(
        "Download PDF"
      );
      expect(load).not.toHaveBeenCalled();
    });

    it("downloads the displayed summary without another callout", async () => {
      const render = jest
        .spyOn(pdfDownload, "renderPdf")
        .mockResolvedValue(new Blob(["pdf"], { type: "application/pdf" }));
      const download = jest
        .spyOn(pdfDownload, "downloadPdf")
        .mockImplementation(() => {});
      const element = await openSummary();

      query(element, "[data-download-pdf]").click();
      await flushPromises();

      expect(render).toHaveBeenCalledTimes(1);
      expect(makeGCPCallout).toHaveBeenCalledTimes(1);
      const documentDefinition = JSON.stringify(render.mock.calls[0][1]);
      [
        "Miles Ahead Brands, LLC",
        "Renewal 2026 is 122 days overdue",
        "Bring the close date current",
        "Provisioning for Renewal",
        "Jaeline Dure",
        "Opened a new depot."
      ].forEach((value) => expect(documentDefinition).toContain(value));
      expect(download).toHaveBeenCalledTimes(1);
      expect(download.mock.calls[0][2]).toMatch(
        /^Account Summary - Miles Ahead Brands, LLC - \d{4}-\d{2}-\d{2}\.pdf$/
      );
      expect(
        query(element, '.ai-modal__body [role="status"]').textContent.trim()
      ).toBe("PDF download started.");
    });

    it("shows an error and keeps the summary open when rendering fails", async () => {
      jest.spyOn(pdfDownload, "renderPdf").mockRejectedValue(new Error("x"));
      const download = jest
        .spyOn(pdfDownload, "downloadPdf")
        .mockImplementation(() => {});
      const element = await openSummary();

      query(element, "[data-download-pdf]").click();
      await flushPromises();

      expect(download).not.toHaveBeenCalled();
      expect(query(element, "[data-pdf-error]").textContent).toContain(
        "couldn’t download the PDF"
      );
      expect(query(element, "[data-download-pdf]").disabled).toBe(false);
      expect(query(element, '[data-summary-section="header"]')).not.toBeNull();
    });
  });

  describe("call insights", () => {
    function withFromCall() {
      const response = JSON.parse(JSON.stringify(RESPONSE));
      const summary = response.account_summary;
      summary.risk_growth_signals.risks[0].from_call = true;
      summary.risk_growth_signals.growth[1].from_call = true;
      summary.recommended_actions[2].from_call = true;
      return response;
    }

    async function openSummary(response) {
      makeGCPCallout.mockResolvedValue(JSON.stringify(response));
      const element = await mount();
      await generate(element);
      query(element, "[data-view-summary]").click();
      await flushPromises();
      return element;
    }

    function flaggedIndexes(element, selector) {
      const rows = [...element.shadowRoot.querySelectorAll(selector)];
      return rows
        .map((row, index) => ({
          index,
          isFlagged: Boolean(row.querySelector(".call-insight-icon"))
        }))
        .filter((row) => row.isFlagged)
        .map((row) => row.index);
    }

    it("shows the call icon only on items marked from_call", async () => {
      const element = await openSummary(withFromCall());

      expect(flaggedIndexes(element, ".signal-list_risk li")).toEqual([0]);
      expect(flaggedIndexes(element, ".signal-list_growth li")).toEqual([1]);
      expect(flaggedIndexes(element, "li.action")).toEqual([2]);
      const icon = query(element, ".call-insight-icon");
      expect(icon.iconName).toBe("utility:call");
      expect(icon.size).toBe("xx-small");
      expect(icon.alternativeText).toBe(
        "From a recorded customer call (RingSense)"
      );
      expect(
        query(element, '[data-summary-section="signals"]').parentElement
          .classList
      ).toContain("has-call-insights");
    });

    it("keeps today's layout when no item has from_call", async () => {
      const element = await openSummary(RESPONSE);

      expect(
        element.shadowRoot.querySelectorAll(".call-insight-icon")
      ).toHaveLength(0);
      expect(
        query(element, '[data-summary-section="signals"]').parentElement
          .classList
      ).not.toContain("has-call-insights");
    });
  });
});
