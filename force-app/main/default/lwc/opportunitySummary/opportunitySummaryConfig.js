import { labels } from "./opportunitySummaryLabels";

/* Public Research Used shows these kinds in this order; findings of any other kind are dropped. */
const RESEARCH_GROUPS = [
  { kind: "leadership", label: labels.researchLeadership },
  { kind: "priority", label: labels.researchPriority }
];

// Settings arrive as text. Reject units, locale separators, booleans and non-finite numbers.
export function positiveNumber(
  raw,
  fallback,
  minimum,
  maximum,
  integerOnly = false
) {
  if (
    typeof raw !== "string" ||
    !/^(?:\d+(?:\.\d+)?|\.\d+)$/.test(raw.trim())
  ) {
    return fallback;
  }
  const value = Number(raw.trim());
  return Number.isFinite(value) &&
    value >= minimum &&
    value <= maximum &&
    (!integerOnly || Number.isInteger(value))
    ? value
    : fallback;
}

let clientSettings = {};

/* Values from Summary_Setting__mdt, read through Apex. Until they arrive, every setting uses its default. */
export function applyClientSettings(settings) {
  clientSettings =
    settings && typeof settings === "object" ? { ...settings } : {};
}

export function getCachePolicy() {
  return {
    ttlMs:
      positiveNumber(clientSettings.CacheHours, 1, 1 / 60, 24) * 60 * 60 * 1000,
    maxBytes:
      positiveNumber(clientSettings.CacheMaxKB, 512, 1, 512, true) * 1024
  };
}

export function getResearchGroups() {
  return RESEARCH_GROUPS.map((group) => ({ ...group }));
}

export function getUiLabels() {
  return {
    pdfDownload: labels.pdfDownload,
    pdfPreparing: labels.pdfPreparing,
    pdfError: labels.pdfError,
    pdfStarted: labels.pdfStarted,
    pdfTitle: labels.pdfTitle,
    pdfSnapshot: labels.pdfSnapshot,
    pdfExported: labels.pdfExported,
    pdfRecord: labels.pdfRecord,
    pdfFooter: labels.pdfFooter,
    pdfStage: labels.pdfStage,
    pdfScore: labels.pdfScore,
    pdfExecutive: labels.pdfExecutive,
    pdfHistory: labels.pdfHistory,
    pdfWin: labels.pdfWin,
    pdfRisk: labels.pdfRisk,
    pdfActions: labels.pdfActions,
    pdfPlan: labels.pdfPlan,
    pdfPostClose: labels.pdfPostClose,
    pdfResearch: labels.pdfResearch,
    pdfSupplemental: labels.pdfSupplemental,
    pdfSources: labels.pdfSources,
    pdfSearches: labels.pdfSearches,
    searchSuggestions: labels.searchSuggestions,
    pdfSearchSuggestionsNote: labels.pdfSearchSuggestionsNote,
    pdfRelevance: labels.pdfRelevance,
    pdfAction: labels.pdfAction,
    researchDisclaimer: labels.researchDisclaimer,
    searchLimitation: labels.searchLimitation,
    genericError: labels.genericError,
    emptyMessage: labels.emptyMessage,
    fromCall: labels.fromCall,
    missingRecord: labels.missingRecord,
    supplementalHelper: labels.supplementalHelper,
    researchHelper: labels.researchHelper,
    workingEyebrow: labels.workingEyebrow,
    workingTitle: labels.workingTitle,
    workingHint: labels.workingHint,
    errorEyebrow: labels.errorEyebrow,
    errorTitle: labels.errorTitle,
    retryButton: labels.retryButton,
    readyEyebrow: labels.readyEyebrow,
    readyTitle: labels.readyTitle,
    readyHint: labels.readyHint,
    viewButton: labels.viewButton,
    idleEyebrow: labels.idleEyebrow,
    idleTitle: labels.idleTitle,
    idleHint: labels.idleHint,
    generateButton: labels.generateButton,
    refreshButton: labels.refreshButton,
    poweredBy: labels.poweredBy,
    generatedNow: labels.generatedNow,
    generatedMinute: labels.generatedMinute,
    generatedMinutes: labels.generatedMinutes,
    generatedHour: labels.generatedHour,
    generatedHours: labels.generatedHours,
    elapsed: labels.elapsed,
    errorIcon: labels.errorIcon,
    readyIcon: labels.readyIcon
  };
}

export function getLoadingMessages() {
  return [...labels.loadingMessages];
}

export function formatLabel(template, value) {
  return template.replace(/\{0\}/g, String(value));
}
