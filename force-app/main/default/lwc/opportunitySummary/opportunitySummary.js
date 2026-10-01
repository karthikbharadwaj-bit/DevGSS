import { LightningElement, api, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { getObjectInfo, getPicklistValues } from "lightning/uiObjectInfoApi";
import OPPORTUNITY_OBJECT from "@salesforce/schema/Opportunity";
import ACCOUNT_OBJECT from "@salesforce/schema/Account";
import STAGE_NAME_FIELD from "@salesforce/schema/Opportunity.StageName";
import aiInsightsLogo from "@salesforce/resourceUrl/AI_Insights";
import USER_ID from "@salesforce/user/Id";
import makeGCPCallout from "@salesforce/apex/GCPCalloutForOpportunitySummary.makeGCPCallout";
import logAIHEvent from "@salesforce/apex/GCPCalloutForOpportunitySummary.logAIHEvent";
import isOpportunitySummaryEnabled from "@salesforce/apex/GCPCalloutForOpportunitySummary.isOpportunitySummaryEnabled";

import {
  getCachePolicy,
  getResearchGroups,
  getUiLabels,
  getLoadingMessages,
  formatLabel
} from "./opportunitySummaryConfig";

const SUBFEATURE = "Opportunity Summary";
const LOADING_INTERVAL_MS = 3900;

// Circumference of the gauge arc (2 * PI * r) for the r=42 circle in the template.
const GAUGE_CIRCUMFERENCE = 264;
const CLOCK_INTERVAL_MS = 60000;

// A leading "Label: value" prefix is only treated as a label when it is short
// enough to read as one; longer prefixes are almost always prose.
const LABEL_MAX_LENGTH = 42;
const EVIDENCE_ID_PATTERN = /^E\d+$/;
// The model sometimes bolds a citation: "[<strong>E3</strong>]" or "<strong>[E3]</strong>".
// Each form is matched whole so no tag is left dangling around the badge.
const EVIDENCE_REFERENCE_PATTERN =
  /<(strong|b)>\s*\[\s*(E\d+)\s*\]\s*<\/\1>|\[\s*<(strong|b)>\s*(E\d+)\s*<\/\3>\s*\]|\[\s*(E\d+)\s*\]/gi;
const HIGHLIGHT_DURATION_MS = 1600;
const CACHE_KEY_PREFIX = "opportunitySummary:v1";
const CACHE_STORAGE_PREFIX = `${CACHE_KEY_PREFIX}:`;
const CACHE_USER_KEY_PREFIX = `${CACHE_KEY_PREFIX}:${USER_ID}:`;

// Only these objects may be linked, and only through the Id GCP returned for them.
const REFERENCE_KEY_PREFIXES = {
  Case: "500",
  Task: "00T",
  Event: "00U",
  Account: "001",
  Contact: "003",
  Opportunity: "006",
  User: "005",
  Product2: "01t"
};
const RECORD_ID_PATTERN = /^[a-zA-Z0-9]{15}(?:[a-zA-Z0-9]{3})?$/;
const RICH_TEXT_TAG_PATTERN = /^<\/?([a-zA-Z][a-zA-Z0-9]*)\b[^<>]*>$/;
const VOID_TAGS = new Set(["br", "hr", "img", "wbr"]);
const NAMED_ENTITIES = {
  amp: "&",
  lt: "<",
  gt: ">",
  quot: '"',
  apos: "'",
  nbsp: "\u00a0"
};
const WORD_CHARACTER = /[A-Za-z0-9]/;
const ISO_DATE_PATTERN =
  /^(\d{4})(?:-(\d{2})(?:-(\d{2})(T\d{2}:\d{2}(?::\d{2}(?:\.\d+)?)?(?:Z|[+-]\d{2}:?\d{2})?)?)?)?$/;
const DATE_PREFIXES = {
  as_of: "Current as of",
  event: "Event date:",
  publication: "Published:"
};
const DEAL_STATES = new Set(["open", "closed_won", "closed_lost"]);

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
  if (normalized.includes("post close action")) {
    return "postclose";
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

function storageEntryBytes(key, value) {
  // Web Storage strings use UTF-16 code units. Include both key and value.
  return (key.length + value.length) * 2;
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

// Research dates arrive as ISO text. Date-only values are formatted in UTC so a
// viewer west of Greenwich never sees the previous day.
export function buildDateParts(date, dateType) {
  const value = stringValue(date);
  const prefix = DATE_PREFIXES[stringValue(dateType).toLowerCase()];
  if (!value || !prefix) {
    return { hasDate: false };
  }

  const match = ISO_DATE_PATTERN.exec(value);
  if (!match) {
    return { hasDate: true, prefix, isIso: false, text: value };
  }
  const [, year, month, day, time] = match;
  const hasTime = Boolean(time);
  return {
    hasDate: true,
    prefix,
    isIso: true,
    value: hasTime ? value : `${year}-${month || "01"}-${day || "01"}`,
    month: month ? "short" : undefined,
    day: day ? "numeric" : undefined,
    timeZone: hasTime ? undefined : "UTC",
    text: value
  };
}

function dateViewModel(date, dateType) {
  const parts = buildDateParts(date, dateType);
  return {
    dateLabel: buildDateLabel(date, dateType),
    hasDate: parts.hasDate,
    datePrefix: parts.prefix || "",
    dateIsIso: parts.isIso === true,
    dateValue: parts.value,
    dateMonth: parts.month,
    dateDay: parts.day,
    dateTimeZone: parts.timeZone,
    dateText: parts.text || ""
  };
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

export function indexFindings(findings, researchGroups = getResearchGroups()) {
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
      !researchGroups.some((group) => group.kind === kind) ||
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
    const evidenceId = (match[2] || match[4] || match[5]).toUpperCase();
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

// Evidence IDs cited anywhere in the summary text.
export function citedEvidenceIds(texts) {
  const ids = new Set();
  (Array.isArray(texts) ? texts : []).forEach((value) => {
    const pattern = new RegExp(EVIDENCE_REFERENCE_PATTERN.source, "gi");
    let match;
    while ((match = pattern.exec(String(value == null ? "" : value)))) {
      ids.add((match[2] || match[4] || match[5]).toUpperCase());
    }
  });
  return ids;
}

export function buildResearchViewModel(enrichment, citedIds = new Set()) {
  const safeEnrichment = isObject(enrichment) ? enrichment : {};
  const rawSources = Array.isArray(safeEnrichment.sources)
    ? safeEnrichment.sources
    : [];
  const configuredGroups = getResearchGroups();
  const supplemental = isObject(safeEnrichment.supplemental_company_updates)
    ? safeEnrichment.supplemental_company_updates
    : {};
  const supplementalItems = Array.isArray(supplemental.items)
    ? supplemental.items
    : [];
  // A finding the summary cites is used evidence even when the service filed it as
  // a supplemental update (its citation check missed a bolded "[E#]"). Show it with
  // the used research so the citation has a target, and not as "not linked".
  const findings = Array.isArray(safeEnrichment.findings)
    ? safeEnrichment.findings
    : [];
  const listedIds = new Set(
    findings.filter(isObject).map((finding) => stringValue(finding.id))
  );
  const promotedItems = supplementalItems.filter(
    (item) =>
      isObject(item) &&
      citedIds.has(stringValue(item.id)) &&
      !listedIds.has(stringValue(item.id))
  );
  const rawFindingById = indexFindings(
    [...findings, ...promotedItems],
    configuredGroups
  );
  const promotedIds = new Set(
    promotedItems
      .map((item) => stringValue(item.id))
      .filter((id) => rawFindingById.has(id))
  );
  const sourceByIndex = indexSources(rawSources);
  const referencedIndices = new Set();
  const supplementalReferencedIndices = new Set();
  const findingById = new Map();
  const findingsByKind = new Map(
    configuredGroups.map((group) => [group.kind, []])
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
      ...dateViewModel(finding.date, finding.date_type),
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
  const researchGroups = configuredGroups
    .map((group) => ({
      key: group.kind,
      label: group.label,
      findings: findingsByKind.get(group.kind)
    }))
    .filter((group) => group.findings.length);
  const supplementalUpdates = supplementalItems
    .map((item, itemIndex) => {
      if (
        !isObject(item) ||
        !stringValue(item.fact) ||
        promotedIds.has(stringValue(item.id))
      ) {
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
        ...dateViewModel(item.date, item.date_type),
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

export function normalizeDealState(dealState) {
  if (!isObject(dealState) || typeof dealState.is_closed !== "boolean") {
    return { isClosed: false, state: "" };
  }
  const state = stringValue(dealState.state).toLowerCase();
  return {
    isClosed: dealState.is_closed,
    state: DEAL_STATES.has(state) ? state : ""
  };
}

// Known salesforce_fields keys and the Salesforce field each one comes from. The chip
// shows that field's label from object info, so admins' label changes and translations
// apply; the fallback is used until object info loads or when no field exists.
const SALESFORCE_FIELD_SOURCES = [
  {
    key: "deal_motion",
    objectApiName: "Opportunity",
    fieldApiName: "Order_Type__c",
    fallback: "Order Type"
  },
  {
    key: "sector",
    objectApiName: "Account",
    fieldApiName: "Sector__c",
    fallback: "Sector"
  },
  { key: "npi_product_categories", fallback: "NPI Product Category" }
];

function objectFieldLabel(objectInfo, fieldApiName) {
  const field =
    isObject(objectInfo) && isObject(objectInfo.fields)
      ? objectInfo.fields[fieldApiName]
      : null;
  return isObject(field) ? stringValue(field.label) : "";
}

export function buildSalesforceChips(fields, objectInfos = {}) {
  if (!isObject(fields)) {
    return [];
  }
  const chips = [];
  const seen = new Set();
  const add = (key, label, value) => {
    const text = stringValue(value);
    const dedupeKey = `${key}:${text.toLowerCase().replace(/\s+/g, " ")}`;
    if (text && !seen.has(dedupeKey)) {
      seen.add(dedupeKey);
      chips.push({
        key: `sf-chip-${chips.length}`,
        label,
        prefix: `${label}: `,
        value: text
      });
    }
  };
  const addValues = (key, label, value) =>
    (Array.isArray(value) ? value : [value]).forEach((item) =>
      add(key, label, item)
    );

  SALESFORCE_FIELD_SOURCES.forEach((source) => {
    const label =
      (source.fieldApiName &&
        objectFieldLabel(
          objectInfos[source.objectApiName],
          source.fieldApiName
        )) ||
      source.fallback;
    addValues(source.key, label, fields[source.key]);
  });
  // Keys GCP adds later still read as words, never as raw keys.
  Object.keys(fields)
    .filter((key) => !SALESFORCE_FIELD_SOURCES.some((s) => s.key === key))
    .forEach((key) => addValues(key, humanizeKind(key), fields[key]));
  return chips;
}

// Groups valid references by the normalized heading of each section that mentions them.
export function indexRecordReferences(references) {
  const referencesBySection = new Map();
  if (!Array.isArray(references)) {
    return referencesBySection;
  }
  references.forEach((reference) => {
    if (!isObject(reference)) {
      return;
    }
    const objectApiName = stringValue(reference.object_type);
    const recordId = stringValue(reference.id);
    const label = stringValue(reference.label);
    const keyPrefix = REFERENCE_KEY_PREFIXES[objectApiName];
    if (
      !keyPrefix ||
      !RECORD_ID_PATTERN.test(recordId) ||
      !recordId.startsWith(keyPrefix) ||
      !label ||
      !Array.isArray(reference.mentioned_in)
    ) {
      return;
    }
    reference.mentioned_in.forEach((heading) => {
      const section = normalizeTitle(heading);
      if (!section) {
        return;
      }
      if (!referencesBySection.has(section)) {
        referencesBySection.set(section, []);
      }
      referencesBySection.get(section).push({ objectApiName, recordId, label });
    });
  });
  // Longer labels win when one label contains another.
  referencesBySection.forEach((list) =>
    list.sort((left, right) => right.label.length - left.label.length)
  );
  return referencesBySection;
}

function decodeEntity(entity) {
  const name = entity.toLowerCase();
  if (Object.prototype.hasOwnProperty.call(NAMED_ENTITIES, name)) {
    return NAMED_ENTITIES[name];
  }
  const code = name.startsWith("#x")
    ? parseInt(name.slice(2), 16)
    : name.startsWith("#")
      ? parseInt(name.slice(1), 10)
      : NaN;
  return Number.isInteger(code) && code > 0 && code < 0x10000
    ? String.fromCharCode(code)
    : null;
}

// Maps each visible character of a rich-text string to its source range so a
// plain-text match can be cut out without splitting a tag or an entity.
function indexRichText(html) {
  const characters = [];
  const starts = [];
  const ends = [];
  const tags = [];
  let position = 0;
  while (position < html.length) {
    if (html[position] === "<") {
      const close = html.indexOf(">", position);
      const tag = close === -1 ? null : html.slice(position, close + 1);
      const tagMatch = tag ? RICH_TEXT_TAG_PATTERN.exec(tag) : null;
      if (tagMatch) {
        tags.push({
          start: position,
          raw: tag,
          name: tagMatch[1].toLowerCase(),
          isClosing: tag.startsWith("</"),
          isVoid: VOID_TAGS.has(tagMatch[1].toLowerCase()) || tag.endsWith("/>")
        });
        position = close + 1;
        continue;
      }
    }
    if (html[position] === "&") {
      const entity = /^&(#\d{1,6}|#x[0-9a-f]{1,5}|[a-z]{2,6});/i.exec(
        html.slice(position, position + 10)
      );
      const decoded = entity ? decodeEntity(entity[1]) : null;
      if (decoded !== null) {
        characters.push(decoded);
        starts.push(position);
        ends.push(position + entity[0].length);
        position += entity[0].length;
        continue;
      }
    }
    characters.push(html[position]);
    starts.push(position);
    ends.push(position + 1);
    position += 1;
  }
  return { text: characters.join(""), starts, ends, tags };
}

function openTagsAt(tags, position) {
  const stack = [];
  tags.forEach((tag) => {
    if (tag.start >= position || tag.isVoid) {
      return;
    }
    if (!tag.isClosing) {
      stack.push(tag);
      return;
    }
    const openIndex = stack.map((open) => open.name).lastIndexOf(tag.name);
    if (openIndex !== -1) {
      stack.splice(openIndex);
    }
  });
  return stack;
}

const EMPTY_ELEMENT_PATTERN = /<([a-zA-Z][a-zA-Z0-9]*)\b[^<>]*><\/\1>/g;

function balancedSlice(html, tags, start, end) {
  const reopen = openTagsAt(tags, start)
    .map((tag) => tag.raw)
    .join("");
  const close = openTagsAt(tags, end)
    .reverse()
    .map((tag) => `</${tag.name}>`)
    .join("");
  let balanced = `${reopen}${html.slice(start, end)}${close}`;
  // Cutting next to a tag leaves an empty pair such as <strong></strong>.
  let previous;
  do {
    previous = balanced;
    balanced = balanced.replace(EMPTY_ELEMENT_PATTERN, "");
  } while (balanced !== previous);
  return balanced;
}

// Localized times use U+202F ("9:19 AM PDT"); treat it, U+00A0 and other
// space separators as a plain space. One character in, one out, so indexes hold.
function normalizeSpaces(text) {
  return text.replace(/[\u00a0\u2007\u202f\u2000-\u200a\u3000]/g, " ");
}

function findReferenceMatches(text, references) {
  const matches = [];
  const haystack = normalizeSpaces(text);
  const overlaps = (start, end) =>
    matches.some((match) => start < match.end && end > match.start);
  references.forEach((reference) => {
    const needle = normalizeSpaces(reference.label);
    // A label may start or end with punctuation ("[Nooks Call] - ..."). The edge
    // check applies only where the label itself starts or ends with a letter or
    // digit, so "0001234" never matches inside "000123456".
    const checkBefore = WORD_CHARACTER.test(needle[0] || "");
    const checkAfter = WORD_CHARACTER.test(needle[needle.length - 1] || "");
    let from = 0;
    let start;
    while ((start = haystack.indexOf(needle, from)) !== -1) {
      const end = start + needle.length;
      from = start + 1;
      const before = start > 0 ? haystack[start - 1] : "";
      const after = end < haystack.length ? haystack[end] : "";
      if (
        (checkBefore && WORD_CHARACTER.test(before)) ||
        (checkAfter && WORD_CHARACTER.test(after)) ||
        overlaps(start, end)
      ) {
        continue;
      }
      matches.push({ start, end, reference });
    }
  });
  return matches.sort((left, right) => left.start - right.start);
}

// Turns each reference label found in the line's plain text into a record link.
// Links are built only from GCP's record_references, never from other text.
export function linkRecordReferences(html, references, keyPrefix = "line") {
  const source = html == null ? "" : String(html);
  const content = (text, index) => ({
    key: `${keyPrefix}-text-${index}`,
    isEvidence: false,
    cssClass: "inline-content",
    content: text
  });
  if (!Array.isArray(references) || !references.length || !source) {
    return [content(source, 0)];
  }

  const indexed = indexRichText(source);
  const matches = findReferenceMatches(indexed.text, references);
  if (!matches.length) {
    return [content(source, 0)];
  }

  const segments = [];
  let cursor = 0;
  matches.forEach((match, matchIndex) => {
    const htmlStart = indexed.starts[match.start];
    const htmlEnd = indexed.ends[match.end - 1];
    const before =
      htmlStart > cursor
        ? balancedSlice(source, indexed.tags, cursor, htmlStart)
        : "";
    if (before) {
      segments.push(content(before, segments.length));
    }
    const { objectApiName, recordId } = match.reference;
    segments.push({
      key: `${keyPrefix}-record-${matchIndex}`,
      isEvidence: false,
      isRecordLink: true,
      cssClass: "inline-record",
      recordId,
      objectApiName,
      label: indexed.text.slice(match.start, match.end),
      href: `/lightning/r/${objectApiName}/${recordId}/view`,
      ariaLabel: `Open ${objectApiName} ${indexed.text.slice(match.start, match.end)}`
    });
    cursor = htmlEnd;
  });
  const after =
    cursor < source.length
      ? balancedSlice(source, indexed.tags, cursor, source.length)
      : "";
  if (after) {
    segments.push(content(after, segments.length));
  }
  return segments;
}

function linkContentSegments(segments, references) {
  if (!Array.isArray(references) || !references.length) {
    return segments;
  }
  return segments.flatMap((segment) => {
    if (segment.isEvidence) {
      return [segment];
    }
    const linked = linkRecordReferences(
      segment.content,
      references,
      segment.key
    );
    return linked.length === 1 && !linked[0].isRecordLink ? [segment] : linked;
  });
}

function plainText(html) {
  return indexRichText(String(html)).text.replace(/\s+/g, " ").trim();
}

// A dot ends prose, but dots between digits are a date such as 15.10.2026.
function readsAsProse(label) {
  return /\.(?!\d)/.test(label);
}

// A colon between digits is part of a time such as "9:19 AM", not a label delimiter.
function labelDelimiterIndex(text, delimiter) {
  let index = text.indexOf(delimiter);
  while (
    delimiter === ":" &&
    index > 0 &&
    /\d/.test(text[index - 1]) &&
    /\d/.test(text[index + 1] || "")
  ) {
    index = text.indexOf(delimiter, index + 1);
  }
  return index;
}

// A record name such as "Contact Center: Data Connector" must not be cut at its own
// colon, or the name would be split between the label and the text.
export function delimiterInsideReference(text, references) {
  if (!Array.isArray(references) || !references.length) {
    return false;
  }
  const plain = normalizeSpaces(indexRichText(String(text)).text);
  return [":", "—"].some((delimiter) => {
    const at = labelDelimiterIndex(plain, delimiter);
    return (
      at > 0 &&
      references.some((reference) => {
        const label = normalizeSpaces(reference.label);
        if (!label.includes(delimiter)) {
          return false;
        }
        let start = plain.indexOf(label);
        while (start !== -1) {
          if (start <= at && at < start + label.length) {
            return true;
          }
          start = plain.indexOf(label, start + 1);
        }
        return false;
      })
    );
  });
}

// Labels render as plain text, so any markup in them is removed. A tag opened in the
// label and closed after the delimiter is reopened at the start of the text.
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

  for (const delimiter of [":", "—"]) {
    const separatorIndex = labelDelimiterIndex(text, delimiter);
    if (separatorIndex <= 0) {
      continue;
    }
    const rawLabel = text.slice(0, separatorIndex);
    const label = plainText(rawLabel);
    let remainder = text.slice(separatorIndex + delimiter.length).trim();
    const unclosed = openTagsAt(indexRichText(rawLabel).tags, rawLabel.length);
    if (unclosed.length) {
      // "<strong>By Oct 15:</strong> text" closes right away; drop those closers.
      // "<strong>By Oct 15: text</strong>" closes later; reopen the tags instead.
      const closers = new RegExp(
        `^(?:\\s*</(?:${unclosed.map((tag) => tag.name).join("|")})>)+\\s*`,
        "i"
      );
      remainder = closers.test(remainder)
        ? remainder.replace(closers, "")
        : `${unclosed.map((tag) => tag.raw).join("")}${remainder}`;
    }
    if (
      label &&
      label.length <= LABEL_MAX_LENGTH &&
      plainText(remainder) &&
      !readsAsProse(label)
    ) {
      return { label, text: remainder, hasLabel: true };
    }
  }
  return { label: "", text, hasLabel: false };
}

function healthVariant(label) {
  const match = HEALTH_VARIANTS.find((entry) => entry.pattern.test(label));
  return match ? match.variant : "info";
}

export default class OpportunitySummary extends NavigationMixin(
  LightningElement
) {
  _recordId;
  _isConnected = false;

  labels = getUiLabels();
  loadingMessages = getLoadingMessages();
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
  postCloseActions = [];
  history = [];
  extraSections = [];
  dealState = normalizeDealState(null);
  _salesforceFields = null;
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
  searchSuggestionsLimitation = this.labels.searchLimitation;
  aiResearchDisclaimer = this.labels.researchDisclaimer;

  generatedAt = null;
  generatedLabel = "";
  generationElapsedLabel = formatLabel(this.labels.elapsed, "00:00");
  loadingMessage = this.loadingMessages[0];

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
  _referencesBySection = new Map();

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
    if (this._isConnected && this.isFeatureEnabled) {
      this.restoreCachedSummary();
    }
  }

  connectedCallback() {
    this._isConnected = true;
    isOpportunitySummaryEnabled()
      .then((enabled) => {
        this.isFeatureEnabled = enabled === true;
        if (this.isFeatureEnabled && this._isConnected) {
          this.restoreCachedSummary();
        }
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

  @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
  accountInfo;

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
      this.postCloseActions.length ||
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
    return this.labels.emptyMessage;
  }

  get isClosedDeal() {
    return this.dealState.isClosed === true;
  }

  // Closed deals have no open risks or win factors to manage.
  get hasInsightColumn() {
    return (
      !this.isClosedDeal &&
      Boolean(this.winFactors.length || this.riskFlags.length)
    );
  }

  get showClosePlan() {
    return !this.isClosedDeal && this.closePlan.length > 0;
  }

  // A getter so chip labels update when object info arrives after the summary.
  get salesforceChips() {
    return buildSalesforceChips(this._salesforceFields, {
      Opportunity: this.opportunityInfo && this.opportunityInfo.data,
      Account: this.accountInfo && this.accountInfo.data
    });
  }

  get hasSalesforceChips() {
    return this.salesforceChips.length > 0;
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

  get cacheKey() {
    return `${CACHE_USER_KEY_PREFIX}${this.recordId}`;
  }

  get searchesLabel() {
    return `Searches performed (${this.searchQueries.length})`;
  }

  disconnectedCallback() {
    this._isConnected = false;
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

  handleRefresh() {
    if (this.isLoading) {
      return;
    }
    this.invalidateCachedSummary();
    this.startGeneration();
  }

  async fetchSummary() {
    if (!this.recordId) {
      this.isError = true;
      this.errorMessage = this.labels.missingRecord;
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
        this.errorMessage = this.labels.genericError;
        return;
      }

      if (parsed && parsed.success === true && Array.isArray(parsed.cards)) {
        this._buildSections(
          parsed.cards,
          parsed.opportunity_enrichment,
          parsed
        );
        this.hasFetched = true;
        this.generatedAt = Date.now();
        this._updateGeneratedLabel();
        this._startClock();
        this.cacheSummary(parsed, this.generatedAt);
      } else if (parsed && parsed.success === false && parsed.message) {
        this.isError = true;
        this.errorMessage = parsed.message;
      } else {
        this.isError = true;
        this.errorMessage = this.labels.genericError;
      }
    } catch (error) {
      if (requestToken === this._requestToken) {
        this.isError = true;
        this.errorMessage =
          (error && error.body && error.body.message) ||
          this.labels.genericError;
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
    this.postCloseActions = [];
    this.history = [];
    this.extraSections = [];
    this.dealState = normalizeDealState(null);
    this._salesforceFields = null;
    this._referencesBySection = new Map();
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
    this.generationElapsedLabel = formatLabel(this.labels.elapsed, "00:00");
  }

  restoreCachedSummary() {
    if (!this.recordId || this.hasFetched || this.isLoading) {
      return false;
    }

    const entry = this.readCachedSummary();
    if (!entry) {
      return false;
    }

    this._buildSections(
      entry.summary.cards,
      entry.summary.opportunity_enrichment,
      entry.summary
    );
    this.hasFetched = true;
    this.generatedAt = entry.cachedAt;
    this._updateGeneratedLabel();
    this._startClock();
    return true;
  }

  readCachedSummary() {
    const { ttlMs } = getCachePolicy();
    try {
      const serializedEntry = window.localStorage.getItem(this.cacheKey);
      if (!serializedEntry) {
        return null;
      }

      const entry = JSON.parse(serializedEntry);
      const age = Date.now() - Number(entry.cachedAt);
      const isValid =
        Number.isFinite(age) &&
        age >= 0 &&
        age < ttlMs &&
        isObject(entry.summary) &&
        Array.isArray(entry.summary.cards);

      if (isValid) {
        return entry;
      }
      window.localStorage.removeItem(this.cacheKey);
    } catch {
      try {
        window.localStorage.removeItem(this.cacheKey);
      } catch {
        // Storage is unavailable, so there is nothing else to clean up.
      }
    }
    return null;
  }

  cacheSummary(parsedResponse, cachedAt) {
    const { maxBytes } = getCachePolicy();
    try {
      const storage = window.localStorage;
      const summary = { cards: parsedResponse.cards };
      [
        "opportunity_enrichment",
        "deal_state",
        "salesforce_fields",
        "record_references"
      ].forEach((key) => {
        if (Object.prototype.hasOwnProperty.call(parsedResponse, key)) {
          summary[key] = parsedResponse[key];
        }
      });
      const serializedEntry = JSON.stringify({ cachedAt, summary });
      const incomingBytes = storageEntryBytes(this.cacheKey, serializedEntry);

      if (incomingBytes > maxBytes) {
        storage.removeItem(this.cacheKey);
        return;
      }

      const existingEntries = this.getOpportunitySummaryCacheEntries(
        this.cacheKey
      );
      let totalBytes =
        incomingBytes +
        existingEntries.reduce((total, entry) => total + entry.bytes, 0);

      existingEntries.sort((left, right) => left.cachedAt - right.cachedAt);
      while (totalBytes > maxBytes && existingEntries.length) {
        const oldestEntry = existingEntries.shift();
        storage.removeItem(oldestEntry.key);
        totalBytes -= oldestEntry.bytes;
      }

      storage.setItem(this.cacheKey, serializedEntry);
    } catch {
      try {
        window.localStorage.removeItem(this.cacheKey);
      } catch {
        // Storage failures must not prevent a fresh summary from rendering.
      }
    }
  }

  getOpportunitySummaryCacheEntries(excludedKey) {
    const { ttlMs } = getCachePolicy();
    const storage = window.localStorage;
    const keys = [];
    const entries = [];

    for (let index = 0; index < storage.length; index += 1) {
      const key = storage.key(index);
      if (key && key !== excludedKey && key.startsWith(CACHE_STORAGE_PREFIX)) {
        keys.push(key);
      }
    }

    keys.forEach((key) => {
      const value = storage.getItem(key);
      try {
        const cachedAt = Number(JSON.parse(value).cachedAt);
        const age = Date.now() - cachedAt;
        if (!Number.isFinite(age) || age < 0 || age >= ttlMs) {
          storage.removeItem(key);
          return;
        }
        entries.push({
          key,
          cachedAt,
          bytes: storageEntryBytes(key, value)
        });
      } catch {
        storage.removeItem(key);
      }
    });

    return entries;
  }

  invalidateCachedSummary() {
    try {
      window.localStorage.removeItem(this.cacheKey);
    } catch {
      // Refresh still proceeds when browser storage is unavailable.
    }
  }

  _buildSections(rawCards, enrichment, response = {}) {
    this._resetSections();

    const extras = isObject(response) ? response : {};
    this.dealState = normalizeDealState(extras.deal_state);
    this._salesforceFields = isObject(extras.salesforce_fields)
      ? extras.salesforce_fields
      : null;
    this._referencesBySection = indexRecordReferences(extras.record_references);

    this.hasEnrichment = isObject(enrichment);
    // Score and history never render evidence badges, so their citations don't count.
    const cards = Array.isArray(rawCards) ? rawCards : [];
    const citedIds = citedEvidenceIds(
      cards
        .filter(
          (raw) =>
            isObject(raw) &&
            !["score", "history"].includes(
              bucketFor(raw.title || raw.heading || raw.name || "")
            )
        )
        .flatMap((raw) => toStrings(raw.items || raw.points || raw.bullets))
    );
    const research = buildResearchViewModel(enrichment, citedIds);
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
      const references =
        this._referencesBySection.get(normalizeTitle(title)) || [];

      switch (bucketFor(title)) {
        case "score":
          this.scoreCard = this._buildScoreCard(badge, items, references);
          break;
        case "executive":
          this.executiveFacts = items.map((text, i) =>
            this._buildSummaryLine(text, `fact-${i}`, true, references)
          );
          break;
        case "win":
          this.winFactors = items.map((text, i) =>
            this._buildSummaryLine(text, `win-${i}`, false, references)
          );
          break;
        case "risk":
          this.riskFlags = items.map((text, i) =>
            this._buildSummaryLine(text, `risk-${i}`, false, references)
          );
          break;
        case "actions":
          this.nextActions = items.map((text, i) => ({
            number: i + 1,
            ...this._buildSummaryLine(text, `action-${i}`, false, references)
          }));
          break;
        case "plan":
          this.closePlan = items.map((text, i) =>
            this._buildSummaryLine(text, `plan-${i}`, true, references)
          );
          break;
        case "postclose":
          this.postCloseActions = items.map((text, i) =>
            this._buildSummaryLine(text, `postclose-${i}`, true, references)
          );
          break;
        case "history":
          this.history = items.map((text, i) => ({
            key: `history-${i}`,
            text,
            segments: linkRecordReferences(text, references, `history-${i}`)
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
                  this._buildSummaryLine(
                    text,
                    `extra-${index}-${i}`,
                    false,
                    references
                  )
                )
              }
            ];
          }
      }
    });
  }

  _buildSummaryLine(text, key, hasStructuredLabel, references = []) {
    const line =
      hasStructuredLabel && !delimiterInsideReference(text, references)
        ? splitLabel(text)
        : { label: "", text, hasLabel: false };
    return {
      key,
      ...line,
      labelSegments: line.hasLabel
        ? linkRecordReferences(line.label, references, `${key}-label`)
        : [],
      segments: linkContentSegments(
        parseInlineEvidence(line.text, this._findingById, key),
        references
      )
    };
  }

  handleRecordLinkClick(event) {
    event.preventDefault();
    const { recordId, objectApiName } = event.currentTarget.dataset;
    if (!recordId || !objectApiName) {
      return;
    }
    this.closeModal();
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: { recordId, objectApiName, actionName: "view" }
    });
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
  _buildScoreCard(badge, items, references = []) {
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
      notes: notes.map((text, i) => ({
        key: `score-note-${i}`,
        text,
        segments: linkRecordReferences(text, references, `score-note-${i}`)
      }))
    };
  }

  _updateGeneratedLabel() {
    if (!this.generatedAt) {
      this.generatedLabel = "";
      return;
    }

    const minutes = Math.floor((Date.now() - this.generatedAt) / 60000);
    if (minutes < 1) {
      this.generatedLabel = this.labels.generatedNow;
    } else if (minutes < 60) {
      this.generatedLabel = formatLabel(
        minutes === 1
          ? this.labels.generatedMinute
          : this.labels.generatedMinutes,
        minutes
      );
    } else {
      const hours = Math.floor(minutes / 60);
      this.generatedLabel = formatLabel(
        hours === 1 ? this.labels.generatedHour : this.labels.generatedHours,
        hours
      );
    }
  }

  // Steps through the narration once and holds on the last line, rather than
  // looping, so a slow callout never appears to restart from the beginning.
  _startLoadingMessages() {
    this._stopLoadingMessages();

    let index = 0;
    this.loadingMessage = this.loadingMessages[0];
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    this._loadingMessageId = setInterval(() => {
      index += 1;
      this.loadingMessage = this.loadingMessages[index];
      if (index >= this.loadingMessages.length - 1) {
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
      this.generationElapsedLabel = formatLabel(this.labels.elapsed, "00:00");
      return;
    }

    const totalSeconds = Math.max(
      0,
      Math.floor((Date.now() - this._generationStartedAt) / 1000)
    );
    const minutes = Math.floor(totalSeconds / 60);
    const seconds = totalSeconds % 60;
    this.generationElapsedLabel = formatLabel(
      this.labels.elapsed,
      `${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`
    );
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
