import loading1 from "@salesforce/label/c.OpportunitySummaryLoading1";
import loading2 from "@salesforce/label/c.OpportunitySummaryLoading2";
import loading3 from "@salesforce/label/c.OpportunitySummaryLoading3";
import loading4 from "@salesforce/label/c.OpportunitySummaryLoading4";
import loading5 from "@salesforce/label/c.OpportunitySummaryLoading5";
import loading6 from "@salesforce/label/c.OpportunitySummaryLoading6";
import loading7 from "@salesforce/label/c.OpportunitySummaryLoading7";
import loading8 from "@salesforce/label/c.OpportunitySummaryLoading8";
import researchDisclaimer from "@salesforce/label/c.OpportunitySummaryResearchDisclaimer";
import searchLimitation from "@salesforce/label/c.OpportunitySummarySearchLimitation";
import genericError from "@salesforce/label/c.OpportunitySummaryGenericError";
import emptyMessage from "@salesforce/label/c.OpportunitySummaryEmptyMessage";
import missingRecord from "@salesforce/label/c.OpportunitySummaryMissingRecord";
import supplementalHelper from "@salesforce/label/c.OpportunitySummarySupplementalHelper";
import researchHelper from "@salesforce/label/c.OpportunitySummaryResearchHelper";
import workingEyebrow from "@salesforce/label/c.OpportunitySummaryWorkingEyebrow";
import workingTitle from "@salesforce/label/c.OpportunitySummaryWorkingTitle";
import workingHint from "@salesforce/label/c.OpportunitySummaryWorkingHint";
import errorEyebrow from "@salesforce/label/c.OpportunitySummaryErrorEyebrow";
import errorTitle from "@salesforce/label/c.OpportunitySummaryErrorTitle";
import retryButton from "@salesforce/label/c.OpportunitySummaryRetryButton";
import readyEyebrow from "@salesforce/label/c.OpportunitySummaryReadyEyebrow";
import readyTitle from "@salesforce/label/c.OpportunitySummaryReadyTitle";
import readyHint from "@salesforce/label/c.OpportunitySummaryReadyHint";
import viewButton from "@salesforce/label/c.OpportunitySummaryViewButton";
import idleEyebrow from "@salesforce/label/c.OpportunitySummaryIdleEyebrow";
import idleTitle from "@salesforce/label/c.OpportunitySummaryIdleTitle";
import idleHint from "@salesforce/label/c.OpportunitySummaryIdleHint";
import generateButton from "@salesforce/label/c.OpportunitySummaryGenerateButton";
import refreshButton from "@salesforce/label/c.OpportunitySummaryRefreshButton";
import poweredBy from "@salesforce/label/c.OpportunitySummaryPoweredBy";
import generatedNow from "@salesforce/label/c.OpportunitySummaryGeneratedNow";
import generatedMinute from "@salesforce/label/c.OpportunitySummaryGeneratedMinute";
import generatedMinutes from "@salesforce/label/c.OpportunitySummaryGeneratedMinutes";
import generatedHour from "@salesforce/label/c.OpportunitySummaryGeneratedHour";
import generatedHours from "@salesforce/label/c.OpportunitySummaryGeneratedHours";
import elapsed from "@salesforce/label/c.OpportunitySummaryElapsed";
import errorIcon from "@salesforce/label/c.OpportunitySummaryErrorIcon";
import readyIcon from "@salesforce/label/c.OpportunitySummaryReadyIcon";
import cacheHours from "@salesforce/label/c.OpportunitySummaryCacheHours";
import cacheMaxKB from "@salesforce/label/c.OpportunitySummaryCacheMaxKB";
import researchGroups from "@salesforce/label/c.OpportunitySummaryResearchGroups";
import pdfDownload from "@salesforce/label/c.OpportunitySummaryPdfDownload";
import pdfPreparing from "@salesforce/label/c.OpportunitySummaryPdfPreparing";
import pdfError from "@salesforce/label/c.OpportunitySummaryPdfError";
import pdfStarted from "@salesforce/label/c.OpportunitySummaryPdfStarted";
import pdfTitle from "@salesforce/label/c.OpportunitySummaryPdfTitle";
import pdfSnapshot from "@salesforce/label/c.OpportunitySummaryPdfSnapshot";
import pdfExported from "@salesforce/label/c.OpportunitySummaryPdfExported";
import pdfRecord from "@salesforce/label/c.OpportunitySummaryPdfRecord";
import pdfFooter from "@salesforce/label/c.OpportunitySummaryPdfFooter";
import pdfStage from "@salesforce/label/c.OpportunitySummaryPdfStage";
import pdfScore from "@salesforce/label/c.OpportunitySummaryPdfScore";
import pdfExecutive from "@salesforce/label/c.OpportunitySummaryPdfExecutive";
import pdfHistory from "@salesforce/label/c.OpportunitySummaryPdfHistory";
import pdfWin from "@salesforce/label/c.OpportunitySummaryPdfWin";
import pdfRisk from "@salesforce/label/c.OpportunitySummaryPdfRisk";
import pdfActions from "@salesforce/label/c.OpportunitySummaryPdfActions";
import pdfPlan from "@salesforce/label/c.OpportunitySummaryPdfPlan";
import pdfResearch from "@salesforce/label/c.OpportunitySummaryPdfResearch";
import pdfSupplemental from "@salesforce/label/c.OpportunitySummaryPdfSupplemental";
import pdfSources from "@salesforce/label/c.OpportunitySummaryPdfSources";
import pdfSearches from "@salesforce/label/c.OpportunitySummaryPdfSearches";
import pdfRelevance from "@salesforce/label/c.OpportunitySummaryPdfRelevance";
import pdfAction from "@salesforce/label/c.OpportunitySummaryPdfAction";
import fromCall from "@salesforce/label/c.OpportunitySummaryFromCall";

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
    ttlMs: positiveNumber(cacheHours, 1, 1 / 60, 24) * 60 * 60 * 1000,
    maxBytes: positiveNumber(cacheMaxKB, 512, 1, 512, true) * 1024
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
  return parseResearchGroups(researchGroups);
}

export function getUiLabels() {
  return {
    pdfDownload,
    pdfPreparing,
    pdfError,
    pdfStarted,
    pdfTitle,
    pdfSnapshot,
    pdfExported,
    pdfRecord,
    pdfFooter,
    pdfStage,
    pdfScore,
    pdfExecutive,
    pdfHistory,
    pdfWin,
    pdfRisk,
    pdfActions,
    pdfPlan,
    pdfResearch,
    pdfSupplemental,
    pdfSources,
    pdfSearches,
    pdfRelevance,
    pdfAction,
    loading1,
    loading2,
    loading3,
    loading4,
    loading5,
    loading6,
    loading7,
    loading8,
    researchDisclaimer,
    searchLimitation,
    genericError,
    emptyMessage,
    fromCall,
    missingRecord,
    supplementalHelper,
    researchHelper,
    workingEyebrow,
    workingTitle,
    workingHint,
    errorEyebrow,
    errorTitle,
    retryButton,
    readyEyebrow,
    readyTitle,
    readyHint,
    viewButton,
    idleEyebrow,
    idleTitle,
    idleHint,
    generateButton,
    refreshButton,
    poweredBy,
    generatedNow,
    generatedMinute,
    generatedMinutes,
    generatedHour,
    generatedHours,
    elapsed,
    errorIcon,
    readyIcon
  };
}

export function getLoadingMessages() {
  return [
    loading1,
    loading2,
    loading3,
    loading4,
    loading5,
    loading6,
    loading7,
    loading8
  ];
}

export function formatLabel(template, value) {
  return template.replace(/\{0\}/g, String(value));
}
