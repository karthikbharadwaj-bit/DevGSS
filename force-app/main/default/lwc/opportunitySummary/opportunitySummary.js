import { LightningElement, api, wire } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { getObjectInfo, getPicklistValues } from "lightning/uiObjectInfoApi";
import OPPORTUNITY_OBJECT from "@salesforce/schema/Opportunity";
import STAGE_NAME_FIELD from "@salesforce/schema/Opportunity.StageName";
import aiInsightsLogo from "@salesforce/resourceUrl/AI_Insights";
import USER_ID from "@salesforce/user/Id";
import makeGCPCallout from "@salesforce/apex/GCPCalloutForOpportunitySummary.makeGCPCallout";
import logAIHEvent from "@salesforce/apex/GCPCalloutForOpportunitySummary.logAIHEvent";
import isOpportunitySummaryEnabled from "@salesforce/apex/GCPCalloutForOpportunitySummary.isOpportunitySummaryEnabled";

const SUBFEATURE = "Opportunity Summary";
const GENERIC_ERROR =
  "We're having trouble generating this summary right now. Please try again later.";
const EMPTY_MESSAGE = "No summary is available for this opportunity yet.";

// Progress narration shown under the spinner while the Cloud Run call is in flight.
const LOADING_MESSAGES = [
  "Gathering opportunity details and stage history…",
  "Reviewing recent activities, tasks, and meetings…",
  "Mapping the buying group and stakeholder engagement…",
  "Checking related cases and prior opportunities on this account…",
  "Securing sensitive details with advanced protection checks…",
  "Activating Gemini to score deal health, risks, and win factors…",
  "Shaping your next best actions and close plan…",
  "Almost there — assembling your decision-ready summary."
];
const LOADING_INTERVAL_MS = 3900;

// Circumference of the gauge arc (2 * PI * r) for the r=42 circle in the template.
const GAUGE_CIRCUMFERENCE = 264;
const CLOCK_INTERVAL_MS = 60000;

// A leading "Label: value" prefix is only treated as a label when it is short
// enough to read as one; longer prefixes are almost always prose.
const LABEL_MAX_LENGTH = 42;
const EVIDENCE_ID_PATTERN = /^E\d+$/;
const EVIDENCE_REFERENCE_PATTERN = /\[(E\d+)\]/g;
const HIGHLIGHT_DURATION_MS = 1600;
const SEARCH_SUGGESTIONS_LIMITATION =
  "Google Search Suggestions aren’t shown because Lightning Web Security sanitizes HTML and SVG strings inserted into the DOM. Showing the supplied markup would change it.";
const AI_RESEARCH_DISCLAIMER =
  "AI-generated company research — This information was found and summarized using AI and public web search. It may be incomplete or inaccurate. Verify important details and sources before using it in customer or deal decisions.";

const RESEARCH_GROUPS = [
  { kind: "leadership", label: "Current Leadership" },
  { kind: "priority", label: "Company Direction and Priorities" }
];

const HEALTH_VARIANTS = [
  {
    pattern: /(at risk|off track|critical|poor|weak|unhealthy|low)/i,
    variant: "risk"
  },
  {
    pattern: /(healthy|strong|excellent|on track|good|high)/i,
    variant: "success"
  },
  { pattern: /(moderate|medium|fair|watch|caution)/i, variant: "warning" }
];

function normalizeTitle(title) {
  return String(title || "")
    .toLowerCase()
    .replace(/&/g, "and")
    .replace(/[^a-z0-9 ]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

// Maps a section heading coming back from the model onto the panel that renders it.
function bucketFor(title) {
  const normalized = normalizeTitle(title);
  if (!normalized) {
    return null;
  }
  if (normalized.includes("deal score")) {
    return "score";
  }
  if (normalized.includes("win factor")) {
    return "win";
  }
  if (normalized.includes("risk")) {
    return "risk";
  }
  if (normalized.includes("next best action")) {
    return "actions";
  }
  if (normalized.includes("close plan")) {
    return "plan";
  }
  if (normalized.includes("stage journey") || normalized.includes("history")) {
    return "history";
  }
  if (normalized.includes("executive summary")) {
    return "executive";
  }
  return null;
}

function toStrings(value) {
  const list = Array.isArray(value) ? value : value == null ? [] : [value];
  return list
    .map((item) => (item == null ? "" : String(item)).trim())
    .filter(Boolean);
}

function isObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function stringValue(value) {
  return typeof value === "string" ? value.trim() : "";
}

function normalizedSourceIndex(value) {
  if (
    value === null ||
    value === undefined ||
    value === "" ||
    typeof value === "boolean"
  ) {
    return null;
  }
  const index = typeof value === "number" ? value : Number(value);
  return Number.isInteger(index) && index >= 0 ? index : null;
}

function safeHttpUrl(value) {
  const candidate = stringValue(value);
  if (!candidate) {
    return "";
  }

  try {
    const parsed = new URL(candidate);
    return parsed.protocol === "http:" || parsed.protocol === "https:"
      ? candidate
      : "";
  } catch {
    return "";
  }
}

function isGoogleRedirectLabel(value) {
  const label = stringValue(value);
  if (!label) {
    return false;
  }

  const normalizedLabel = label.toLowerCase().replace(/\/$/, "");
  if (
    normalizedLabel === "vertexaisearch.cloud.google.com" ||
    normalizedLabel.startsWith("vertexaisearch.cloud.google.com/")
  ) {
    return true;
  }

  try {
    return (
      new URL(label).hostname.toLowerCase() ===
      "vertexaisearch.cloud.google.com"
    );
  } catch {
    return false;
  }
}

function sourceLabel(source, sourceIndex) {
  for (const candidate of [source.display_label, source.title]) {
    if (stringValue(candidate) && !isGoogleRedirectLabel(candidate)) {
      return stringValue(candidate);
    }
  }
  return `Source ${sourceIndex + 1}`;
}

function sourceViewModel(source, keyPrefix) {
  const index = normalizedSourceIndex(source && source.index);
  if (index === null || !isObject(source)) {
    return null;
  }

  const url = safeHttpUrl(source.url);
  return {
    key: `${keyPrefix}-${index}`,
    index,
    label: sourceLabel(source, index),
    url,
    hasLink: Boolean(url)
  };
}

function inferenceText(value) {
  const text = stringValue(value);
  if (!text || /^inference\s*:/i.test(text)) {
    return text;
  }
  return `Inference: ${text}`;
}

function humanizeKind(value) {
  const normalized = stringValue(value)
    .replace(/[_-]+/g, " ")
    .replace(/\s+/g, " ");
  if (!normalized) {
    return "Company Update";
  }
  return normalized.replace(/\b\w/g, (character) => character.toUpperCase());
}

export function buildDateLabel(date, dateType) {
  const value = stringValue(date);
  if (!value) {
    return "";
  }

  switch (stringValue(dateType).toLowerCase()) {
    case "as_of":
      return `Current as of ${value}`;
    case "event":
      return `Event date: ${value}`;
    case "publication":
      return `Published: ${value}`;
    default:
      return "";
  }
}

export function indexFindings(findings) {
  const findingById = new Map();
  if (!Array.isArray(findings)) {
    return findingById;
  }

  findings.forEach((finding) => {
    if (!isObject(finding)) {
      return;
    }
    const id = stringValue(finding.id);
    const kind = stringValue(finding.kind).toLowerCase();
    const fact = stringValue(finding.fact);
    if (
      !EVIDENCE_ID_PATTERN.test(id) ||
      !RESEARCH_GROUPS.some((group) => group.kind === kind) ||
      !fact ||
      findingById.has(id)
    ) {
      return;
    }
    findingById.set(id, finding);
  });

  return findingById;
}

export function indexSources(sources) {
  const sourceByIndex = new Map();
  if (!Array.isArray(sources)) {
    return sourceByIndex;
  }

  sources.forEach((source) => {
    if (!isObject(source)) {
      return;
    }
    const index = normalizedSourceIndex(source.index);
    if (index !== null && !sourceByIndex.has(String(index))) {
      sourceByIndex.set(String(index), source);
    }
  });

  return sourceByIndex;
}

export function parseInlineEvidence(value, findingById, keyPrefix = "line") {
  const text = value == null ? "" : String(value);
  const segments = [];
  const referencePattern = new RegExp(EVIDENCE_REFERENCE_PATTERN.source, "g");
  let cursor = 0;
  let match;
  let segmentIndex = 0;

  while ((match = referencePattern.exec(text)) !== null) {
    const evidenceId = match[1];
    if (!findingById || !findingById.has(evidenceId)) {
      continue;
    }

    if (match.index > cursor) {
      segments.push({
        key: `${keyPrefix}-content-${segmentIndex}`,
        isEvidence: false,
        cssClass: "inline-content",
        content: text.slice(cursor, match.index)
      });
      segmentIndex += 1;
    }

    segments.push({
      key: `${keyPrefix}-evidence-${segmentIndex}`,
      isEvidence: true,
      cssClass: "inline-evidence",
      evidenceId,
      label: `Public evidence ${evidenceId}`,
      ariaLabel: `View public research evidence ${evidenceId}`
    });
    segmentIndex += 1;
    cursor = referencePattern.lastIndex;
  }

  if (cursor < text.length || segments.length === 0) {
    segments.push({
      key: `${keyPrefix}-content-${segmentIndex}`,
      isEvidence: false,
      cssClass: "inline-content",
      content: text.slice(cursor)
    });
  }

  return segments;
}

export function buildResearchViewModel(enrichment) {
  const safeEnrichment = isObject(enrichment) ? enrichment : {};
  const rawSources = Array.isArray(safeEnrichment.sources)
    ? safeEnrichment.sources
    : [];
  const rawFindingById = indexFindings(safeEnrichment.findings);
  const sourceByIndex = indexSources(rawSources);
  const referencedIndices = new Set();
  const supplementalReferencedIndices = new Set();
  const findingById = new Map();
  const findingsByKind = new Map(
    RESEARCH_GROUPS.map((group) => [group.kind, []])
  );

  rawFindingById.forEach((finding, id) => {
    const sourceIndices = Array.isArray(finding.source_indices)
      ? finding.source_indices
      : [];
    const sources = [];

    sourceIndices.forEach((rawIndex, relationIndex) => {
      const sourceIndex = normalizedSourceIndex(rawIndex);
      if (sourceIndex === null) {
        return;
      }
      const source = sourceByIndex.get(String(sourceIndex));
      if (!source) {
        return;
      }
      const viewModel = sourceViewModel(
        source,
        `${id}-source-${relationIndex}`
      );
      if (viewModel) {
        referencedIndices.add(String(sourceIndex));
        sources.push(viewModel);
      }
    });

    const personName = stringValue(finding.person_name);
    const role = stringValue(finding.role);
    const relevance = inferenceText(finding.relevance);
    const suggestedAction = inferenceText(finding.suggested_action);
    const findingViewModel = {
      key: `finding-${id}`,
      id,
      domId: `public-research-${id}`,
      fact: stringValue(finding.fact),
      dateLabel: buildDateLabel(finding.date, finding.date_type),
      personName,
      role,
      personLine: [personName, role].filter(Boolean).join(" · "),
      hasPerson: Boolean(personName || role),
      relevance,
      hasRelevance: Boolean(relevance),
      suggestedAction,
      hasSuggestedAction: Boolean(suggestedAction),
      sources,
      hasSources: sources.length > 0
    };

    const kind = stringValue(finding.kind).toLowerCase();
    findingsByKind.get(kind).push(findingViewModel);
    findingById.set(id, findingViewModel);
  });

  const allSources = rawSources
    .map((source, sourcePosition) =>
      sourceViewModel(source, `aggregate-source-${sourcePosition}`)
    )
    .filter(Boolean);
  const referencedSources = allSources.filter((source) =>
    referencedIndices.has(String(source.index))
  );
  let otherSources = allSources.filter(
    (source) => !referencedIndices.has(String(source.index))
  );
  const searchQueries = (
    Array.isArray(safeEnrichment.web_search_queries)
      ? safeEnrichment.web_search_queries
      : []
  )
    .filter((query) => typeof query === "string" && query.trim())
    .map((query, index) => ({ key: `research-query-${index}`, text: query }));
  const searchEntryPoint = isObject(safeEnrichment.search_entry_point)
    ? safeEnrichment.search_entry_point
    : {};
  const researchGroups = RESEARCH_GROUPS.map((group) => ({
    key: group.kind,
    label: group.label,
    findings: findingsByKind.get(group.kind)
  })).filter((group) => group.findings.length);
  const supplemental = isObject(safeEnrichment.supplemental_company_updates)
    ? safeEnrichment.supplemental_company_updates
    : {};
  const supplementalUpdates = (
    Array.isArray(supplemental.items) ? supplemental.items : []
  )
    .map((item, itemIndex) => {
      if (!isObject(item) || !stringValue(item.fact)) {
        return null;
      }

      const id = stringValue(item.id);
      const personName = stringValue(item.person_name);
      const role = stringValue(item.role);
      const relevance = inferenceText(item.relevance);
      const suggestedAction = inferenceText(item.suggested_action);
      const resolvedSourceIndices = new Set();
      const sources = (
        Array.isArray(item.source_indices) ? item.source_indices : []
      )
        .map((rawIndex, relationIndex) => {
          const sourceIndex = normalizedSourceIndex(rawIndex);
          const sourceIndexKey = String(sourceIndex);
          if (
            sourceIndex === null ||
            resolvedSourceIndices.has(sourceIndexKey)
          ) {
            return null;
          }
          const source = sourceByIndex.get(sourceIndexKey);
          if (!source) {
            return null;
          }
          resolvedSourceIndices.add(sourceIndexKey);
          supplementalReferencedIndices.add(sourceIndexKey);
          return sourceViewModel(
            source,
            `supplemental-${itemIndex}-source-${relationIndex}`
          );
        })
        .filter(Boolean);

      return {
        key: `supplemental-${id || itemIndex}-${itemIndex}`,
        id,
        kindLabel: humanizeKind(item.kind),
        dateLabel: buildDateLabel(item.date, item.date_type),
        fact: stringValue(item.fact),
        personLine: [personName, role].filter(Boolean).join(" · "),
        hasPerson: Boolean(personName || role),
        relevance,
        hasRelevance: Boolean(relevance),
        suggestedAction,
        hasSuggestedAction: Boolean(suggestedAction),
        sources,
        hasSources: sources.length > 0
      };
    })
    .filter(Boolean);
  const supplementalRelationshipToOpportunity = stringValue(
    supplemental.relationship_to_opportunity
  ).toLowerCase();
  otherSources = allSources.filter((source) => {
    const indexKey = String(source.index);
    return (
      !referencedIndices.has(indexKey) &&
      !supplementalReferencedIndices.has(indexKey)
    );
  });
  const researchSourceCount = allSources.filter((source) => {
    const indexKey = String(source.index);
    return (
      referencedIndices.has(indexKey) ||
      !supplementalReferencedIndices.has(indexKey)
    );
  }).length;

  return {
    findingById,
    researchGroups,
    hasPublicResearch: findingById.size > 0,
    supplementalUpdates,
    hasSupplementalUpdates: supplementalUpdates.length > 0,
    supplementalRelationshipToOpportunity,
    referencedSources,
    otherSources,
    sourceCount: researchSourceCount,
    searchQueries,
    hasSearchSuggestionsMarkup: Boolean(
      stringValue(searchEntryPoint.rendered_content)
    )
  };
}

export function focusEvidenceTarget(componentTemplate, evidenceId) {
  if (
    !componentTemplate ||
    !EVIDENCE_ID_PATTERN.test(String(evidenceId || ""))
  ) {
    return null;
  }

  const researchSection = componentTemplate.querySelector(
    "[data-public-research]"
  );
  if (researchSection) {
    researchSection.open = true;
  }

  const target = componentTemplate.querySelector(
    `[data-research-finding="${evidenceId}"]`
  );
  if (!target) {
    return null;
  }

  if (typeof target.scrollIntoView === "function") {
    target.scrollIntoView({ behavior: "smooth", block: "center" });
  }
  if (typeof target.focus === "function") {
    target.focus();
  }
  return target;
}

export function splitLabel(text) {
  const emphasizedLabel =
    /^\s*<(strong|b)>([^<>]{1,42})(:|—)\s*<\/\1>\s*(.+)$/is.exec(text);
  if (emphasizedLabel) {
    return {
      label: emphasizedLabel[2].trim(),
      text: emphasizedLabel[4].trim(),
      hasLabel: true
    };
  }

  let delimiter = ":";
  let separatorIndex = text.indexOf(delimiter);

  if (separatorIndex <= 0 || separatorIndex > LABEL_MAX_LENGTH) {
    delimiter = "—";
    separatorIndex = text.indexOf(delimiter);
  }

  if (separatorIndex > 0 && separatorIndex <= LABEL_MAX_LENGTH) {
    const label = text.slice(0, separatorIndex).trim();
    const remainder = text.slice(separatorIndex + delimiter.length).trim();
    if (label && remainder && !label.includes(".")) {
      return { label, text: remainder, hasLabel: true };
    }
  }
  return { label: "", text, hasLabel: false };
}

function healthVariant(label) {
  const match = HEALTH_VARIANTS.find((entry) => entry.pattern.test(label));
  return match ? match.variant : "info";
}

export default class OpportunitySummary extends LightningElement {
  _recordId;

  aiInsightsLogo = aiInsightsLogo;
  loggedInUserId = USER_ID;

  isFeatureEnabled = false;
  isModalOpen = false;
  isLoading = false;
  isError = false;
  errorMessage = "";
  hasFetched = false;
  aihViewLogged = false;

  scoreCard = null;
  executiveFacts = [];
  winFactors = [];
  riskFlags = [];
  nextActions = [];
  closePlan = [];
  history = [];
  extraSections = [];
  researchGroups = [];
  referencedResearchSources = [];
  otherResearchSources = [];
  researchSourceCount = 0;
  searchQueries = [];
  hasSearchSuggestionsMarkup = false;
  hasPublicResearch = false;
  hasEnrichment = false;
  supplementalUpdates = [];
  hasSupplementalUpdates = false;
  supplementalRelationshipToOpportunity = "";
  searchSuggestionsLimitation = SEARCH_SUGGESTIONS_LIMITATION;
  aiResearchDisclaimer = AI_RESEARCH_DISCLAIMER;

  generatedAt = null;
  generatedLabel = "";
  generationElapsedLabel = "00:00 elapsed";
  loadingMessage = LOADING_MESSAGES[0];

  stageOptions = [];
  currentStage = null;

  _clockId = null;
  _elapsedClockId = null;
  _generationStartedAt = null;
  _loadingMessageId = null;
  _escapeHandler = null;
  _findingById = new Map();
  _highlightTimeoutId = null;
  _highlightedTarget = null;
  _requestToken = 0;

  @api
  get recordId() {
    return this._recordId;
  }

  set recordId(value) {
    if (value === this._recordId) {
      return;
    }
    this._recordId = value;
    this._requestToken += 1;
    this.hasFetched = false;
    this.isLoading = false;
    this.isError = false;
    this.errorMessage = "";
    this.isModalOpen = false;
    this._stopClock();
    this._stopElapsedClock();
    this._stopLoadingMessages();
    this._unbindEscape();
    this._resetSections();
  }

  connectedCallback() {
    isOpportunitySummaryEnabled()
      .then((enabled) => {
        this.isFeatureEnabled = enabled === true;
      })
      .catch(() => {
        this.isFeatureEnabled = false;
      });
  }

  @wire(getRecord, { recordId: "$recordId", fields: [STAGE_NAME_FIELD] })
  wiredOpportunity({ data }) {
    if (data) {
      this.currentStage = getFieldValue(data, STAGE_NAME_FIELD);
    }
  }

  @wire(getObjectInfo, { objectApiName: OPPORTUNITY_OBJECT })
  opportunityInfo;

  @wire(getPicklistValues, {
    recordTypeId: "$opportunityInfo.data.defaultRecordTypeId",
    fieldApiName: STAGE_NAME_FIELD
  })
  wiredStages({ data }) {
    if (data) {
      this.stageOptions = data.values.map((entry) => ({
        label: entry.label,
        value: entry.value
      }));
    }
  }

  get hasContent() {
    return Boolean(
      this.scoreCard ||
      this.executiveFacts.length ||
      this.winFactors.length ||
      this.riskFlags.length ||
      this.nextActions.length ||
      this.closePlan.length ||
      this.history.length ||
      this.extraSections.length ||
      this.hasPublicResearch ||
      this.hasEnrichment ||
      this.hasSupplementalUpdates
    );
  }

  get showEmptyState() {
    return !this.isLoading && !this.isError && !this.hasContent;
  }

  get emptyMessage() {
    return EMPTY_MESSAGE;
  }

  get hasInsightColumn() {
    return Boolean(this.winFactors.length || this.riskFlags.length);
  }

  get stageTrail() {
    if (!this.stageOptions.length) {
      return [];
    }

    // Without the record's stage the rail would render as a row of
    // indistinguishable grey chips, so wait until it resolves.
    const currentIndex = this.stageOptions.findIndex(
      (stage) => stage.value === this.currentStage
    );
    if (currentIndex === -1) {
      return [];
    }

    return this.stageOptions.map((stage, index) => {
      const isComplete = index < currentIndex;
      const isCurrent = index === currentIndex;
      let modifier = " is-upcoming";
      if (isComplete) {
        modifier = " is-complete";
      } else if (isCurrent) {
        modifier = " is-current";
      }

      return {
        key: `stage-${index}`,
        label: stage.label,
        showCheck: isComplete,
        chipClass: `stage-chip${modifier}`
      };
    });
  }

  get hasStageTrail() {
    return this.stageTrail.length > 0;
  }

  get sourcesLabel() {
    return `Sources (${this.researchSourceCount})`;
  }

  get searchesLabel() {
    return `Searches performed (${this.searchQueries.length})`;
  }

  disconnectedCallback() {
    this._stopClock();
    this._stopElapsedClock();
    this._stopLoadingMessages();
    this._unbindEscape();
    this._clearEvidenceHighlight();
  }

  openModal() {
    if (!this.hasFetched || this.isLoading || this.isError) {
      return;
    }
    this.isModalOpen = true;
    this._logView();
    this._bindEscape();
  }

  closeModal() {
    this.isModalOpen = false;
    this._unbindEscape();
  }

  startGeneration() {
    if (this.isLoading) {
      return;
    }
    this.isModalOpen = false;
    this._unbindEscape();
    this.fetchSummary();
  }

  async fetchSummary() {
    if (!this.recordId) {
      this.isError = true;
      this.errorMessage = "No opportunity record is available.";
      return;
    }

    const requestToken = ++this._requestToken;
    this.isLoading = true;
    this.isError = false;
    this.errorMessage = "";
    this.hasFetched = false;
    this._stopClock();
    this._resetSections();
    this._startLoadingMessages();
    this._startElapsedClock();

    try {
      const result = await makeGCPCallout({
        userId: this.loggedInUserId,
        recordId: this.recordId
      });

      if (requestToken !== this._requestToken) {
        return;
      }

      let parsed;
      try {
        parsed = JSON.parse(result);
      } catch {
        this.isError = true;
        this.errorMessage = GENERIC_ERROR;
        return;
      }

      if (parsed && parsed.success === true && Array.isArray(parsed.cards)) {
        this._buildSections(parsed.cards, parsed.opportunity_enrichment);
        this.hasFetched = true;
        this.generatedAt = Date.now();
        this._updateGeneratedLabel();
        this._startClock();
      } else if (parsed && parsed.success === false && parsed.message) {
        this.isError = true;
        this.errorMessage = parsed.message;
      } else {
        this.isError = true;
        this.errorMessage = GENERIC_ERROR;
      }
    } catch (error) {
      if (requestToken === this._requestToken) {
        this.isError = true;
        this.errorMessage =
          (error && error.body && error.body.message) || GENERIC_ERROR;
      }
    } finally {
      if (requestToken === this._requestToken) {
        this._stopLoadingMessages();
        this._stopElapsedClock();
        this.isLoading = false;
      }
    }
  }

  _resetSections() {
    this.scoreCard = null;
    this.executiveFacts = [];
    this.winFactors = [];
    this.riskFlags = [];
    this.nextActions = [];
    this.closePlan = [];
    this.history = [];
    this.extraSections = [];
    this.researchGroups = [];
    this.referencedResearchSources = [];
    this.otherResearchSources = [];
    this.researchSourceCount = 0;
    this.searchQueries = [];
    this.hasSearchSuggestionsMarkup = false;
    this.hasPublicResearch = false;
    this.hasEnrichment = false;
    this.supplementalUpdates = [];
    this.hasSupplementalUpdates = false;
    this.supplementalRelationshipToOpportunity = "";
    this._findingById = new Map();
    this._clearEvidenceHighlight();
    this.generatedAt = null;
    this.generatedLabel = "";
    this.generationElapsedLabel = "00:00 elapsed";
  }

  _buildSections(rawCards, enrichment) {
    this._resetSections();

    this.hasEnrichment = isObject(enrichment);
    const research = buildResearchViewModel(enrichment);
    this.researchGroups = research.researchGroups;
    this.referencedResearchSources = research.referencedSources;
    this.otherResearchSources = research.otherSources;
    this.researchSourceCount = research.sourceCount;
    this.searchQueries = research.searchQueries;
    this.hasSearchSuggestionsMarkup = research.hasSearchSuggestionsMarkup;
    this.hasPublicResearch = research.hasPublicResearch;
    this.supplementalUpdates = research.supplementalUpdates;
    this.hasSupplementalUpdates = research.hasSupplementalUpdates;
    this.supplementalRelationshipToOpportunity =
      research.supplementalRelationshipToOpportunity;
    this._findingById = research.findingById;

    rawCards.forEach((raw, index) => {
      if (!raw || typeof raw !== "object") {
        return;
      }

      const title = raw.title || raw.heading || raw.name || "";
      const items = toStrings(raw.items || raw.points || raw.bullets);
      const badge = (raw.badge || raw.label || "").toString().trim();

      switch (bucketFor(title)) {
        case "score":
          this.scoreCard = this._buildScoreCard(badge, items);
          break;
        case "executive":
          this.executiveFacts = items.map((text, i) =>
            this._buildSummaryLine(text, `fact-${i}`, true)
          );
          break;
        case "win":
          this.winFactors = items.map((text, i) =>
            this._buildSummaryLine(text, `win-${i}`, false)
          );
          break;
        case "risk":
          this.riskFlags = items.map((text, i) =>
            this._buildSummaryLine(text, `risk-${i}`, false)
          );
          break;
        case "actions":
          this.nextActions = items.map((text, i) => ({
            number: i + 1,
            ...this._buildSummaryLine(text, `action-${i}`, false)
          }));
          break;
        case "plan":
          this.closePlan = items.map((text, i) =>
            this._buildSummaryLine(text, `plan-${i}`, true)
          );
          break;
        case "history":
          this.history = items.map((text, i) => ({
            key: `history-${i}`,
            text
          }));
          break;
        default:
          if (title || items.length) {
            this.extraSections = [
              ...this.extraSections,
              {
                key: `extra-${index}`,
                title,
                items: items.map((text, i) =>
                  this._buildSummaryLine(text, `extra-${index}-${i}`, false)
                )
              }
            ];
          }
      }
    });
  }

  _buildSummaryLine(text, key, hasStructuredLabel) {
    const line = hasStructuredLabel
      ? splitLabel(text)
      : { label: "", text, hasLabel: false };
    return {
      key,
      ...line,
      segments: parseInlineEvidence(line.text, this._findingById, key)
    };
  }

  handleEvidenceClick(event) {
    const evidenceId = event.currentTarget.dataset.evidenceId;
    const target = focusEvidenceTarget(this.template, evidenceId);
    if (!target) {
      return;
    }

    this._clearEvidenceHighlight();
    target.classList.add("is-highlighted");
    this._highlightedTarget = target;
    // The timeout provides a brief visual confirmation after keyboard or pointer navigation.
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    this._highlightTimeoutId = setTimeout(() => {
      if (this._highlightedTarget) {
        this._highlightedTarget.classList.remove("is-highlighted");
      }
      this._highlightedTarget = null;
      this._highlightTimeoutId = null;
    }, HIGHLIGHT_DURATION_MS);
  }

  _clearEvidenceHighlight() {
    if (this._highlightTimeoutId) {
      clearTimeout(this._highlightTimeoutId);
      this._highlightTimeoutId = null;
    }
    if (this._highlightedTarget) {
      this._highlightedTarget.classList.remove("is-highlighted");
      this._highlightedTarget = null;
    }
  }

  // The score arrives as free text such as "76/100 (Healthy)", with the
  // headline in either the badge or the first bullet depending on the payload.
  _buildScoreCard(badge, items) {
    const headline = badge || items[0] || "";
    const notes = badge ? items : items.slice(1);

    const scoreMatch = /(\d+(?:\.\d+)?)\s*\/\s*(\d+(?:\.\d+)?)/.exec(headline);
    const labelMatch = /\(([^)]+)\)/.exec(headline);
    const healthLabel = labelMatch ? labelMatch[1].trim() : "";
    const variant = healthVariant(healthLabel || headline);

    const value = scoreMatch ? Number(scoreMatch[1]) : null;
    const max = scoreMatch ? Number(scoreMatch[2]) : 100;
    const ratio =
      value !== null && max > 0 ? Math.min(Math.max(value / max, 0), 1) : 0;

    return {
      hasValue: value !== null,
      headline,
      value,
      max,
      healthLabel,
      hasHealthLabel: Boolean(healthLabel),
      healthClass: `health-pill health-pill_${variant}`,
      gaugeClass: `gauge-value gauge-value_${variant}`,
      dashArray: GAUGE_CIRCUMFERENCE,
      dashOffset: GAUGE_CIRCUMFERENCE * (1 - ratio),
      notes: notes.map((text, i) => ({ key: `score-note-${i}`, text }))
    };
  }

  _updateGeneratedLabel() {
    if (!this.generatedAt) {
      this.generatedLabel = "";
      return;
    }

    const minutes = Math.floor((Date.now() - this.generatedAt) / 60000);
    if (minutes < 1) {
      this.generatedLabel = "Generated just now";
    } else if (minutes < 60) {
      this.generatedLabel = `Generated ${minutes} minute${minutes === 1 ? "" : "s"} ago`;
    } else {
      const hours = Math.floor(minutes / 60);
      this.generatedLabel = `Generated ${hours} hour${hours === 1 ? "" : "s"} ago`;
    }
  }

  // Steps through the narration once and holds on the last line, rather than
  // looping, so a slow callout never appears to restart from the beginning.
  _startLoadingMessages() {
    this._stopLoadingMessages();

    let index = 0;
    this.loadingMessage = LOADING_MESSAGES[0];
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    this._loadingMessageId = setInterval(() => {
      index += 1;
      this.loadingMessage = LOADING_MESSAGES[index];
      if (index >= LOADING_MESSAGES.length - 1) {
        this._stopLoadingMessages();
      }
    }, LOADING_INTERVAL_MS);
  }

  _stopLoadingMessages() {
    if (this._loadingMessageId) {
      clearInterval(this._loadingMessageId);
      this._loadingMessageId = null;
    }
  }

  _updateGenerationElapsedLabel() {
    if (!this._generationStartedAt) {
      this.generationElapsedLabel = "00:00 elapsed";
      return;
    }

    const totalSeconds = Math.max(
      0,
      Math.floor((Date.now() - this._generationStartedAt) / 1000)
    );
    const minutes = Math.floor(totalSeconds / 60);
    const seconds = totalSeconds % 60;
    this.generationElapsedLabel = `${String(minutes).padStart(2, "0")}:${String(
      seconds
    ).padStart(2, "0")} elapsed`;
  }

  _startElapsedClock() {
    this._stopElapsedClock();
    this._generationStartedAt = Date.now();
    this._updateGenerationElapsedLabel();
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    this._elapsedClockId = setInterval(
      () => this._updateGenerationElapsedLabel(),
      1000
    );
  }

  _stopElapsedClock() {
    if (this._elapsedClockId) {
      clearInterval(this._elapsedClockId);
      this._elapsedClockId = null;
    }
    this._generationStartedAt = null;
  }

  _startClock() {
    if (this._clockId) {
      return;
    }
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    this._clockId = setInterval(
      () => this._updateGeneratedLabel(),
      CLOCK_INTERVAL_MS
    );
  }

  _stopClock() {
    if (this._clockId) {
      clearInterval(this._clockId);
      this._clockId = null;
    }
  }

  _bindEscape() {
    if (this._escapeHandler) {
      return;
    }
    this._escapeHandler = (event) => {
      if (event.key === "Escape") {
        this.closeModal();
      }
    };
    document.addEventListener("keydown", this._escapeHandler);
  }

  _unbindEscape() {
    if (this._escapeHandler) {
      document.removeEventListener("keydown", this._escapeHandler);
      this._escapeHandler = null;
    }
  }

  _logView() {
    if (this.aihViewLogged) {
      return;
    }
    this.aihViewLogged = true;
    logAIHEvent({
      eventType: "aih_view",
      subfeature: SUBFEATURE,
      feedback: null
    }).catch(() => {
      this.aihViewLogged = false;
    });
  }
}
