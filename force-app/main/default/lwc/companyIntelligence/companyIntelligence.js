import { LightningElement, api } from "lwc";
import aiInsightsLogo from "@salesforce/resourceUrl/AI_Insights";
import requestCompanyIntelligence from "@salesforce/apex/CompanyIntelligenceController.requestCompanyIntelligence";

const GENERIC_ERROR =
  "Company Intelligence is temporarily unavailable. Try again later.";
const EMPTY_MESSAGE = "No reliable public information found.";
// A leading "Label: value" prefix is only treated as a label when it is short
// enough to read as one. Mirrors c/opportunitySummary so both cards format alike.
const LABEL_MAX_LENGTH = 42;
const DISCLOSURE_KEYS = ["claims", "sources", "searches"];
const SECTION_DEFINITIONS = [
  { key: "companySnapshot", title: "Company Snapshot" },
  { key: "latestCompanyAnnouncements", title: "Latest Company Announcements" },
  {
    key: "executiveLeadershipAnnouncements",
    title: "Executive Leadership Announcements"
  },
  {
    key: "businessAndFinancialSignals",
    title: "Business and Financial Signals"
  },
  {
    key: "competitiveAndMarketContext",
    title: "Competitive and Market Context"
  },
  { key: "opportunityRelevance", title: "Opportunity Relevance" },
  { key: "informationGaps", title: "Information Gaps" }
];

function toStrings(value) {
  const values = Array.isArray(value) ? value : value == null ? [] : [value];
  return values.map((item) => String(item || "").trim()).filter(Boolean);
}

export function splitLabel(text) {
  let delimiter = ":";
  let separatorIndex = text.indexOf(delimiter);

  if (separatorIndex <= 0 || separatorIndex > LABEL_MAX_LENGTH) {
    delimiter = "—";
    separatorIndex = text.indexOf(delimiter);
  }

  if (separatorIndex > 0 && separatorIndex <= LABEL_MAX_LENGTH) {
    const label = text.slice(0, separatorIndex).trim();
    const remainder = text.slice(separatorIndex + delimiter.length).trim();
    // A "//" remainder means the colon belonged to a URL scheme, not a label.
    if (
      label &&
      remainder &&
      !label.includes(".") &&
      !remainder.startsWith("//")
    ) {
      return { label, text: remainder, hasLabel: true };
    }
  }
  return { label: "", text, hasLabel: false };
}

function safeSourceUrl(value) {
  const url = String(value || "").trim();
  return /^https:\/\//i.test(url) ? url : "";
}

export function buildCompanyViewModel(intelligence = {}) {
  const summary = intelligence.summary || {};
  const sections = SECTION_DEFINITIONS.map((definition) => {
    const items = toStrings(summary[definition.key]).map((text, index) => ({
      key: `${definition.key}-${index}`,
      ...splitLabel(text)
    }));
    return {
      key: definition.key,
      title: definition.title,
      count: items.length,
      items
    };
  }).filter((section) => section.items.length);

  const sources = (
    Array.isArray(intelligence.sources) ? intelligence.sources : []
  )
    .map((source) => ({
      key: `source-${source && source.index}`,
      index: source && source.index,
      label: String((source && source.displayLabel) || "").trim(),
      url: safeSourceUrl(source && source.url)
    }))
    .filter(
      (source) =>
        source.label &&
        source.url &&
        source.index !== null &&
        source.index !== undefined
    );
  const sourceIndexToSourceMap = new Map(
    sources.map((source) => [String(source.index), source])
  );

  const claims = (
    Array.isArray(intelligence.derivedInformation)
      ? intelligence.derivedInformation
      : []
  )
    .map((claim, claimIndex) => ({
      key: `claim-${claimIndex}`,
      text: String((claim && claim.text) || "").trim(),
      sources: (Array.isArray(claim && claim.sourceIndices)
        ? claim.sourceIndices
        : []
      )
        .map((sourceIndex) => sourceIndexToSourceMap.get(String(sourceIndex)))
        .filter(Boolean)
        .map((source) => ({
          ...source,
          key: `claim-${claimIndex}-source-${source.index}`
        }))
    }))
    .filter((claim) => claim.text);

  return {
    sections,
    sources,
    claims,
    searches: toStrings(intelligence.webSearchQueries).map((text, index) => ({
      key: `search-${index}`,
      text
    })),
    hasSearchSuggestionsMarkup: Boolean(
      intelligence.searchEntryPoint &&
      intelligence.searchEntryPoint.renderedContent
    )
  };
}

export default class CompanyIntelligence extends LightningElement {
  _recordId;
  _isConnected = false;
  _hasRequested = false;
  _requestPromise;
  _expandedDisclosures = {};

  aiInsightsLogo = aiInsightsLogo;
  isLoading = false;
  isError = false;
  errorMessage = "";
  sections = [];
  claims = [];
  sources = [];
  searches = [];
  hasSearchSuggestionsMarkup = false;
  activeSectionName = "";

  @api
  get recordId() {
    return this._recordId;
  }

  set recordId(value) {
    this._recordId = value;
    this.loadInitialIntelligence();
  }

  connectedCallback() {
    this._isConnected = true;
    this.loadInitialIntelligence();
  }

  disconnectedCallback() {
    this._isConnected = false;
  }

  get hasContent() {
    return Boolean(
      this.sections.length ||
      this.claims.length ||
      this.sources.length ||
      this.searches.length ||
      this.hasSearchSuggestionsMarkup
    );
  }

  get showEmptyState() {
    return (
      !this.isLoading && !this.isError && this._hasRequested && !this.hasContent
    );
  }

  get emptyMessage() {
    return EMPTY_MESSAGE;
  }

  get disableRefresh() {
    return this.isLoading;
  }

  get claimsLabel() {
    return `Grounded claims (${this.claims.length})`;
  }

  get sourcesLabel() {
    return `Sources (${this.sources.length})`;
  }

  get searchesLabel() {
    return `Searches performed (${this.searches.length})`;
  }

  get claimsDisclosure() {
    return this.disclosureState("claims");
  }

  get sourcesDisclosure() {
    return this.disclosureState("sources");
  }

  get searchesDisclosure() {
    return this.disclosureState("searches");
  }

  disclosureState(key) {
    const isExpanded = Boolean(this._expandedDisclosures[key]);
    return {
      expanded: String(isExpanded),
      sectionClass: isExpanded ? "slds-section slds-is-open" : "slds-section"
    };
  }

  handleDisclosureToggle(event) {
    const { disclosure } = event.currentTarget.dataset;
    if (!DISCLOSURE_KEYS.includes(disclosure)) {
      return;
    }
    this._expandedDisclosures = {
      ...this._expandedDisclosures,
      [disclosure]: !this._expandedDisclosures[disclosure]
    };
  }

  loadInitialIntelligence() {
    if (!this._isConnected || !this.recordId || this._hasRequested) {
      return;
    }
    this._hasRequested = true;
    this.fetchIntelligence();
  }

  fetchIntelligence() {
    if (this._requestPromise) {
      return this._requestPromise;
    }

    this._requestPromise = this.requestIntelligence().finally(() => {
      this._requestPromise = null;
    });
    return this._requestPromise;
  }

  async requestIntelligence() {
    this.isLoading = true;
    this.isError = false;
    this.errorMessage = "";
    this.resetContent();

    try {
      const result = await requestCompanyIntelligence({
        recordId: this.recordId
      });
      if (result && result.success && result.intelligence) {
        this.applyIntelligence(result.intelligence);
      } else {
        this.isError = true;
        this.errorMessage = (result && result.message) || GENERIC_ERROR;
      }
    } catch {
      this.isError = true;
      this.errorMessage = GENERIC_ERROR;
    } finally {
      this.isLoading = false;
    }
  }

  handleRefresh() {
    this.fetchIntelligence();
  }

  resetContent() {
    this.sections = [];
    this.claims = [];
    this.sources = [];
    this.searches = [];
    this.hasSearchSuggestionsMarkup = false;
    this.activeSectionName = "";
    this._expandedDisclosures = {};
  }

  applyIntelligence(intelligence) {
    const viewModel = buildCompanyViewModel(intelligence);
    this.sections = viewModel.sections;
    this.claims = viewModel.claims;
    this.sources = viewModel.sources;
    this.searches = viewModel.searches;
    this.hasSearchSuggestionsMarkup = viewModel.hasSearchSuggestionsMarkup;
    this.activeSectionName = this.sections.length ? this.sections[0].key : "";
  }
}
