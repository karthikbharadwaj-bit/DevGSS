import { labels } from "./opportunitySummaryLabels";

const DEFAULT_RESEARCH_GROUPS = [
  { kind: "leadership", label: "Current Leadership" },
  { kind: "priority", label: "Company Direction and Priorities" }
];

// Labels are text. Reject units, locale separators, booleans and non-finite numbers.
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

export function getCachePolicy() {
  return {
    ttlMs: positiveNumber(labels.cacheHours, 1, 1 / 60, 24) * 60 * 60 * 1000,
    maxBytes: positiveNumber(labels.cacheMaxKB, 512, 1, 512, true) * 1024
  };
}

export function parseResearchGroups(raw) {
  try {
    const entries = JSON.parse(raw);
    if (!Array.isArray(entries) || !entries.length) {
      return DEFAULT_RESEARCH_GROUPS;
    }
    const seen = new Set();
    const groups = entries.map((entry, index) => {
      if (
        !entry ||
        typeof entry !== "object" ||
        typeof entry.kind !== "string" ||
        typeof entry.label !== "string"
      ) {
        throw new Error("Invalid research group");
      }
      const kind = entry.kind.trim().toLowerCase();
      const label = entry.label.trim();
      if (
        !/^[a-z][a-z0-9_-]*$/.test(kind) ||
        !label ||
        seen.has(kind) ||
        (entry.active !== undefined && typeof entry.active !== "boolean") ||
        (entry.order !== undefined && !Number.isSafeInteger(entry.order))
      ) {
        throw new Error("Invalid research group");
      }
      seen.add(kind);
      return {
        kind,
        label,
        active: entry.active !== false,
        order: entry.order ?? index
      };
    });
    return groups
      .filter((group) => group.active)
      .sort((left, right) => left.order - right.order)
      .map(({ kind, label }) => ({ kind, label }));
  } catch {
    return DEFAULT_RESEARCH_GROUPS;
  }
}

export function getResearchGroups() {
  return parseResearchGroups(labels.researchGroups);
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
    pdfRelevance: labels.pdfRelevance,
    pdfAction: labels.pdfAction,
    loading1: labels.loading1,
    loading2: labels.loading2,
    loading3: labels.loading3,
    loading4: labels.loading4,
    loading5: labels.loading5,
    loading6: labels.loading6,
    loading7: labels.loading7,
    loading8: labels.loading8,
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
  return [
    labels.loading1,
    labels.loading2,
    labels.loading3,
    labels.loading4,
    labels.loading5,
    labels.loading6,
    labels.loading7,
    labels.loading8
  ];
}

export function formatLabel(template, value) {
  return template.replace(/\{0\}/g, String(value));
}
