import { createElement } from "lwc";
import CompanyIntelligence, { splitLabel } from "c/companyIntelligence";
import requestCompanyIntelligence from "@salesforce/apex/CompanyIntelligenceController.requestCompanyIntelligence";

jest.mock(
  "@salesforce/apex/CompanyIntelligenceController.requestCompanyIntelligence",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock("@salesforce/user/Id", () => ({ default: "005000000000001AAA" }), {
  virtual: true
});

const RECORD_ID = "006000000000001AAA";
const SECOND_RECORD_ID = "006000000000002AAA";
const CACHE_KEY = `companyIntelligence:v1:005000000000001AAA:${RECORD_ID}`;
const SECOND_CACHE_KEY = `companyIntelligence:v1:005000000000001AAA:${SECOND_RECORD_ID}`;
const ONE_DAY_MS = 24 * 60 * 60 * 1000;
const MAX_CACHE_BYTES = 512 * 1024;
const GOOGLE_REDIRECT_URL =
  "https://vertexaisearch.cloud.google.com/grounding-api-redirect/private-token";

function successfulResponse(overrides = {}) {
  return {
    success: true,
    statusCode: 200,
    intelligence: {
      sources: [
        {
          index: 9,
          displayLabel: "nine.example",
          title: "Nine",
          url: `${GOOGLE_REDIRECT_URL}-nine`,
          domain: "nine.example"
        },
        {
          index: 0,
          displayLabel: "zero.example",
          title: "Zero",
          url: `${GOOGLE_REDIRECT_URL}-zero`,
          domain: "zero.example"
        }
      ],
      derivedInformation: [
        { text: "A claim supported by source nine", sourceIndices: [9] }
      ],
      webSearchQueries: ["Example latest company announcements"],
      summary: {
        companySnapshot: ["Public software company"],
        latestCompanyAnnouncements: ["Launched a new service"],
        executiveLeadershipAnnouncements: ["Named a new executive"],
        businessAndFinancialSignals: ["Reported revenue growth"],
        competitiveAndMarketContext: ["Competes in a growing market"],
        opportunityRelevance: ["Renewal aligns with public strategy"],
        informationGaps: ["No reliable regional breakdown found"]
      },
      searchEntryPoint: {
        renderedContent:
          '<style>.suggestion{color:blue}</style><svg></svg><a href="https://google.com">Search</a>'
      },
      ...overrides
    }
  };
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

async function createComponent(recordId = RECORD_ID) {
  const element = createElement("c-company-intelligence", {
    is: CompanyIntelligence
  });
  element.recordId = recordId;
  document.body.appendChild(element);
  await flushPromises();
  return element;
}

describe("companyIntelligence", () => {
  beforeEach(() => {
    localStorage.clear();
    requestCompanyIntelligence.mockResolvedValue(successfulResponse());
  });

  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("loads independently when placed on an Opportunity record page", async () => {
    const element = await createComponent();

    expect(requestCompanyIntelligence).toHaveBeenCalledTimes(1);
    expect(requestCompanyIntelligence).toHaveBeenCalledWith({
      recordId: RECORD_ID
    });
    expect(element.shadowRoot.textContent).toContain("Public software company");
  });

  it("prevents duplicate lifecycle requests while loading", async () => {
    const response = deferred();
    requestCompanyIntelligence.mockReturnValue(response.promise);
    const element = await createComponent();

    element.recordId = RECORD_ID;
    await flushPromises();

    expect(requestCompanyIntelligence).toHaveBeenCalledTimes(1);
    expect(
      element.shadowRoot.querySelector('[data-testid="loading"]')
    ).not.toBeNull();

    response.resolve(successfulResponse());
    await flushPromises();
  });

  it("reuses successful intelligence from local storage for one day", async () => {
    const firstElement = await createComponent();
    document.body.removeChild(firstElement);

    const secondElement = await createComponent();

    expect(requestCompanyIntelligence).toHaveBeenCalledTimes(1);
    expect(secondElement.shadowRoot.textContent).toContain(
      "Public software company"
    );
    expect(JSON.parse(localStorage.getItem(CACHE_KEY))).toEqual({
      cachedAt: expect.any(Number),
      intelligence: successfulResponse().intelligence
    });
  });

  it("requests fresh intelligence when the local cache is older than one day", async () => {
    localStorage.setItem(
      CACHE_KEY,
      JSON.stringify({
        cachedAt: Date.now() - ONE_DAY_MS - 1,
        intelligence: successfulResponse({
          summary: { companySnapshot: ["Stale company snapshot"] }
        }).intelligence
      })
    );

    const element = await createComponent();

    expect(requestCompanyIntelligence).toHaveBeenCalledTimes(1);
    expect(element.shadowRoot.textContent).toContain("Public software company");
    expect(element.shadowRoot.textContent).not.toContain(
      "Stale company snapshot"
    );
  });

  it("ignores malformed local cache entries", async () => {
    localStorage.setItem(CACHE_KEY, "not-json");

    const element = await createComponent();

    expect(requestCompanyIntelligence).toHaveBeenCalledTimes(1);
    expect(element.shadowRoot.textContent).toContain("Public software company");
  });

  it("keeps separate cached intelligence for multiple Opportunities", async () => {
    requestCompanyIntelligence
      .mockResolvedValueOnce(successfulResponse())
      .mockResolvedValueOnce(
        successfulResponse({
          summary: { companySnapshot: ["Second Opportunity company"] }
        })
      );

    const firstElement = await createComponent();
    document.body.removeChild(firstElement);
    const secondElement = await createComponent(SECOND_RECORD_ID);
    document.body.removeChild(secondElement);
    const reloadedFirstElement = await createComponent();

    expect(requestCompanyIntelligence).toHaveBeenCalledTimes(2);
    expect(requestCompanyIntelligence).toHaveBeenNthCalledWith(2, {
      recordId: SECOND_RECORD_ID
    });
    expect(localStorage.getItem(CACHE_KEY)).not.toBeNull();
    expect(localStorage.getItem(SECOND_CACHE_KEY)).not.toBeNull();
    expect(reloadedFirstElement.shadowRoot.textContent).toContain(
      "Public software company"
    );
  });

  it("caps all Company Intelligence cache entries at 512 KiB", async () => {
    const otherUserCacheKey = `companyIntelligence:v1:005000000000009AAA:${RECORD_ID}`;
    localStorage.setItem(
      otherUserCacheKey,
      JSON.stringify({
        cachedAt: Date.now() - 1000,
        intelligence: successfulResponse({
          summary: { companySnapshot: ["o".repeat(140000)] }
        }).intelligence
      })
    );
    requestCompanyIntelligence.mockResolvedValue(
      successfulResponse({
        summary: { companySnapshot: ["n".repeat(140000)] }
      })
    );

    await createComponent(SECOND_RECORD_ID);

    let cachedBytes = 0;
    for (let index = 0; index < localStorage.length; index += 1) {
      const key = localStorage.key(index);
      if (key.startsWith("companyIntelligence:v1:")) {
        cachedBytes += (key.length + localStorage.getItem(key).length) * 2;
      }
    }
    expect(cachedBytes).toBeLessThanOrEqual(MAX_CACHE_BYTES);
    expect(localStorage.getItem(otherUserCacheKey)).toBeNull();
    expect(localStorage.getItem(SECOND_CACHE_KEY)).not.toBeNull();
  });

  it("does not cache an individual response larger than the cache cap", async () => {
    requestCompanyIntelligence.mockResolvedValue(
      successfulResponse({
        summary: { companySnapshot: ["x".repeat(270000)] }
      })
    );

    const element = await createComponent();

    expect(element.shadowRoot.textContent).toContain("x".repeat(100));
    expect(localStorage.getItem(CACHE_KEY)).toBeNull();
  });

  it("renders a safe service error", async () => {
    requestCompanyIntelligence.mockResolvedValue({
      success: false,
      statusCode: 429,
      message:
        "Company Intelligence is temporarily busy. Try again in a few minutes."
    });
    const element = await createComponent();

    expect(
      element.shadowRoot.querySelector('[data-testid="error"]')
    ).not.toBeNull();
    expect(element.shadowRoot.textContent).toContain("temporarily busy");
  });

  it("renders summary sections in the required order", async () => {
    const element = await createComponent();

    const sectionElements = [
      ...element.shadowRoot.querySelectorAll("[data-section-key]")
    ];
    const titles = sectionElements.map((section) => section.label);
    expect(titles).toEqual([
      "Company Snapshot",
      "Latest Company Announcements",
      "Executive Leadership Announcements",
      "Business and Financial Signals",
      "Competitive and Market Context",
      "Opportunity Relevance",
      "Information Gaps"
    ]);
    expect(
      element.shadowRoot.querySelector("lightning-accordion").activeSectionName
    ).toEqual(["companySnapshot"]);
  });

  it("keeps the active section closed after the user collapses it", async () => {
    const element = await createComponent();
    const accordion = element.shadowRoot.querySelector("lightning-accordion");

    accordion.dispatchEvent(
      new CustomEvent("sectiontoggle", {
        detail: { openSections: [] }
      })
    );
    await flushPromises();

    expect(accordion.activeSectionName).toEqual([]);
  });

  it("expands and collapses all intelligence sections", async () => {
    const element = await createComponent();
    const toggle = element.shadowRoot.querySelector(
      '[data-testid="sections-toggle"]'
    );

    toggle.click();
    await flushPromises();

    expect(
      element.shadowRoot.querySelector("lightning-accordion").activeSectionName
    ).toEqual([
      "companySnapshot",
      "latestCompanyAnnouncements",
      "executiveLeadershipAnnouncements",
      "businessAndFinancialSignals",
      "competitiveAndMarketContext",
      "opportunityRelevance",
      "informationGaps"
    ]);
    expect(
      element.shadowRoot.querySelector('[data-testid="sections-toggle"]')
        .alternativeText
    ).toBe("Collapse all sections");

    element.shadowRoot.querySelector('[data-testid="sections-toggle"]').click();
    await flushPromises();

    expect(
      element.shadowRoot.querySelector("lightning-accordion").activeSectionName
    ).toEqual([]);
  });

  it("collapses and restores the whole Company Intelligence region", async () => {
    const element = await createComponent();
    const toggle = element.shadowRoot.querySelector(
      '[data-testid="region-toggle"]'
    );

    toggle.click();
    await flushPromises();

    expect(element.shadowRoot.textContent).toContain("Company Intelligence");
    expect(
      element.shadowRoot.querySelector('[data-testid="content"]')
    ).toBeNull();
    expect(
      element.shadowRoot.querySelector('[data-testid="region-toggle"]')
        .alternativeText
    ).toBe("Expand Company Intelligence");
    expect(requestCompanyIntelligence).toHaveBeenCalledTimes(1);

    element.shadowRoot.querySelector('[data-testid="region-toggle"]').click();
    await flushPromises();

    expect(
      element.shadowRoot.querySelector('[data-testid="content"]')
    ).not.toBeNull();
    expect(requestCompanyIntelligence).toHaveBeenCalledTimes(1);
  });

  it("hides empty sections and shows the concise empty state", async () => {
    requestCompanyIntelligence.mockResolvedValue(
      successfulResponse({
        sources: [],
        derivedInformation: [],
        webSearchQueries: [],
        summary: {},
        searchEntryPoint: { renderedContent: "" }
      })
    );
    const element = await createComponent();

    expect(
      element.shadowRoot.querySelectorAll("[data-section-key]")
    ).toHaveLength(0);
    expect(
      element.shadowRoot.querySelector('[data-testid="empty"]')
    ).not.toBeNull();
    expect(element.shadowRoot.textContent).toContain(
      "No reliable public information found."
    );
  });

  it("maps claims by explicit source index and hides raw URLs from text", async () => {
    const element = await createComponent();

    const claimSource = element.shadowRoot.querySelector(
      '.claims [data-source-index="9"]'
    );
    expect(claimSource.textContent).toBe("nine.example");
    expect(claimSource.href).toBe(`${GOOGLE_REDIRECT_URL}-nine`);
    expect(claimSource.target).toBe("_blank");
    expect(claimSource.rel).toBe("noopener noreferrer");
    expect(
      element.shadowRoot.querySelector('.claims [data-source-index="0"]')
    ).toBeNull();
    expect(element.shadowRoot.textContent).not.toContain(GOOGLE_REDIRECT_URL);
  });

  it("keeps searches collapsed and reports the Search Suggestions blocker", async () => {
    const element = await createComponent();

    const searchesToggle = element.shadowRoot.querySelector("button.searches");
    expect(searchesToggle.getAttribute("aria-expanded")).toBe("false");
    expect(
      element.shadowRoot.querySelector(".slds-section__content.searches")
        .textContent
    ).toContain("Example latest company announcements");
    expect(
      element.shadowRoot.querySelector(
        '[data-testid="search-suggestions-blocker"]'
      )
    ).not.toBeNull();
    expect(element.shadowRoot.querySelector("style")).toBeNull();
    expect(
      element.shadowRoot.querySelector('a[href="https://google.com"]')
    ).toBeNull();
  });

  it("reports the Search Suggestions blocker when it is the only returned content", async () => {
    requestCompanyIntelligence.mockResolvedValue(
      successfulResponse({
        sources: [],
        derivedInformation: [],
        webSearchQueries: [],
        summary: {},
        searchEntryPoint: { renderedContent: "<style></style><svg></svg>" }
      })
    );
    const element = await createComponent();

    expect(
      element.shadowRoot.querySelector(
        '[data-testid="search-suggestions-blocker"]'
      )
    ).not.toBeNull();
    expect(
      element.shadowRoot.querySelector('[data-testid="empty"]')
    ).toBeNull();
    expect(element.shadowRoot.querySelector("style")).toBeNull();
    expect(element.shadowRoot.querySelector("svg")).toBeNull();
  });

  it("refreshes independently and coalesces duplicate refresh clicks", async () => {
    const element = await createComponent();
    const refreshResponse = deferred();
    requestCompanyIntelligence.mockReturnValue(refreshResponse.promise);

    const refreshButton = element.shadowRoot.querySelector(
      '[data-testid="refresh"]'
    );
    refreshButton.click();
    refreshButton.click();
    await flushPromises();

    expect(requestCompanyIntelligence).toHaveBeenCalledTimes(2);
    expect(
      element.shadowRoot.querySelector('[data-testid="loading"]')
    ).not.toBeNull();

    refreshResponse.resolve(
      successfulResponse({
        summary: { companySnapshot: ["Freshly regenerated snapshot"] }
      })
    );
    await flushPromises();

    expect(
      JSON.parse(localStorage.getItem(CACHE_KEY)).intelligence.summary
        .companySnapshot
    ).toEqual(["Freshly regenerated snapshot"]);
  });

  it("expands and collapses an evidence disclosure on click", async () => {
    const element = await createComponent();

    const sourcesToggle = element.shadowRoot.querySelector("button.sources");
    const sourcesSection = element.shadowRoot.querySelector(
      ".slds-section__content.sources"
    ).parentElement;
    expect(sourcesToggle.getAttribute("aria-expanded")).toBe("false");
    expect(sourcesSection.className).not.toContain("slds-is-open");

    sourcesToggle.click();
    await flushPromises();

    expect(
      element.shadowRoot
        .querySelector("button.sources")
        .getAttribute("aria-expanded")
    ).toBe("true");
    expect(
      element.shadowRoot.querySelector(".slds-section__content.sources")
        .parentElement.className
    ).toContain("slds-is-open");

    element.shadowRoot.querySelector("button.sources").click();
    await flushPromises();

    expect(
      element.shadowRoot
        .querySelector("button.sources")
        .getAttribute("aria-expanded")
    ).toBe("false");
  });

  it('splits a short "Label: value" prefix into its own label', async () => {
    requestCompanyIntelligence.mockResolvedValue(
      successfulResponse({
        summary: {
          companySnapshot: [
            "Legal Entity: One Love Periodic Services, Inc.",
            "Operates across Western North Carolina with no labelled prefix",
            "Site: https://example.com is reachable"
          ]
        }
      })
    );
    const element = await createComponent();

    const labels = [...element.shadowRoot.querySelectorAll(".fact-label")].map(
      (node) => node.textContent
    );
    expect(labels).toEqual(["Legal Entity", "Site"]);
    expect(
      element.shadowRoot.querySelectorAll(".fact-value_full")
    ).toHaveLength(1);
    expect(element.shadowRoot.textContent).toContain(
      "One Love Periodic Services, Inc."
    );
  });

  it("leaves a URL scheme colon alone", () => {
    expect(splitLabel("https://example.com/path is the source")).toEqual({
      label: "",
      text: "https://example.com/path is the source",
      hasLabel: false
    });
  });

  it("reports the item count for each rendered section", async () => {
    const element = await createComponent();

    const counts = [
      ...element.shadowRoot.querySelectorAll(".section-count")
    ].map((node) => node.textContent);
    expect(counts).toEqual(["1", "1", "1", "1", "1", "1", "1"]);
  });
});
