import { createElement } from "lwc";
import OpportunitySummary, {
  buildDateLabel,
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
const GOOGLE_REDIRECT_URL =
  "https://vertexaisearch.cloud.google.com/grounding-api-redirect/private-token";
const AI_RESEARCH_DISCLAIMER =
  "AI-generated company research — This information was found and summarized using AI and public web search. It may be incomplete or inaccurate. Verify important details and sources before using it in customer or deal decisions.";

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
  makeGCPCallout.mockResolvedValue(result);
  const element = await mountComponent();

  element.shadowRoot.querySelector("[data-generate-summary]").click();
  await flushPromises();
  element.shadowRoot.querySelector("[data-view-summary]").click();
  await flushPromises();
  return element;
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
    isOpportunitySummaryEnabled.mockResolvedValue(true);
    logAIHEvent.mockResolvedValue();
  });

  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
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
    expect(supplemental.textContent).toContain("Current as of 2026-09-22");
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
    expect(cards[1].textContent).toContain("Event date: 2026-09-01");
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
    expect(research.textContent).toContain("Current as of 2026-09-18");
    expect(research.textContent).toContain("Event date: 2026-01-14");
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

  it("does not write enrichment or summary data to browser storage", async () => {
    const localStorageWrite = jest.spyOn(Storage.prototype, "setItem");

    await createComponent();

    expect(localStorageWrite).not.toHaveBeenCalled();
    localStorageWrite.mockRestore();
  });
});
