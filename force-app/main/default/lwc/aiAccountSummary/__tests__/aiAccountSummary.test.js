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
    expect(query(element, "[data-summary-override]")).not.toBeNull();
    expect(logAIHEvent).toHaveBeenCalledTimes(1);
    expect(logAIHEvent).toHaveBeenCalledWith({
      eventType: "aih_view",
      subfeature: "Account Summary",
      feedback: null
    });
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
