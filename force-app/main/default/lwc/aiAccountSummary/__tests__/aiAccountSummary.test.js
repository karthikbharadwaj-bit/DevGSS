import { resetLabels } from "../../../../../../test/jest-mocks/accountSummaryLabels";
import { createElement } from "lwc";
import AiAccountSummary from "c/aiAccountSummary";
import makeGCPCallout from "@salesforce/apex/GCPCalloutForAccountSummary.makeGCPCallout";
import isAccountSummaryEnabled from "@salesforce/apex/GCPCalloutForAccountSummary.isAccountSummaryEnabled";
import logAIHEvent from "@salesforce/apex/GCPCalloutForOpportunitySummary.logAIHEvent";

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
});
