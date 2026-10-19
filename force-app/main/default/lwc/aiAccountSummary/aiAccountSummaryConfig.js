import { labels } from "./aiAccountSummaryLabels";

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

/* Admins can change both settings, but a list never shows more than this many rows. */
const MAX_LIST_ROWS = 10;
const DEFAULT_INITIAL_ROWS = 3;

function cappedRowCount(raw, fallback) {
  return Math.min(
    positiveNumber(raw, fallback, 1, Number.MAX_SAFE_INTEGER, true),
    MAX_LIST_ROWS
  );
}

/* Rows shown first, and after View more; the first count never exceeds the second. */
export function getListRowLimits() {
  const maxRows = cappedRowCount(clientSettings.ListRowLimit, MAX_LIST_ROWS);
  return {
    initialRows: Math.min(
      cappedRowCount(clientSettings.ListRowsInitial, DEFAULT_INITIAL_ROWS),
      maxRows
    ),
    maxRows
  };
}

export function getUiLabels() {
  return {
    researchCitedHeading: labels.researchCitedHeading,
    researchAdditionalHeading: labels.researchAdditionalHeading,
    fromCall: labels.fromCall,
    genericError: labels.genericError,
    missingRecord: labels.missingRecord,
    emptyMessage: labels.emptyMessage,
    title: labels.title,
    modalTitle: labels.modalTitle,
    betaChip: labels.betaChip,
    closeButton: labels.closeButton,
    workingEyebrow: labels.workingEyebrow,
    workingTitle: labels.workingTitle,
    workingHint: labels.workingHint,
    errorEyebrow: labels.errorEyebrow,
    errorTitle: labels.errorTitle,
    errorIcon: labels.errorIcon,
    retryButton: labels.retryButton,
    readyEyebrow: labels.readyEyebrow,
    readyTitle: labels.readyTitle,
    readyHint: labels.readyHint,
    readyIcon: labels.readyIcon,
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
    notRecorded: labels.notRecorded,
    asOf: labels.asOf,
    sectionHeader: labels.sectionHeader,
    sectionMetrics: labels.sectionMetrics,
    sectionSignals: labels.sectionSignals,
    sectionOpportunities: labels.sectionOpportunities,
    sectionCases: labels.sectionCases,
    sectionContacts: labels.sectionContacts,
    sectionFlag: labels.sectionFlag,
    sectionActions: labels.sectionActions,
    sectionHistory: labels.sectionHistory,
    sectionResearch: labels.sectionResearch,
    fieldAccount: labels.fieldAccount,
    fieldIndustry: labels.fieldIndustry,
    fieldLocation: labels.fieldLocation,
    fieldTypeStatus: labels.fieldTypeStatus,
    fieldTier: labels.fieldTier,
    fieldOwner: labels.fieldOwner,
    fieldCsm: labels.fieldCsm,
    fieldCustomerSince: labels.fieldCustomerSince,
    fieldRating: labels.fieldRating,
    fieldSource: labels.fieldSource,
    ageMonths: labels.ageMonths,
    tileMrr: labels.tileMrr,
    tileMrrDetail: labels.tileMrrDetail,
    tileTrajectory: labels.tileTrajectory,
    tileTrajectoryDetail: labels.tileTrajectoryDetail,
    tilePipeline: labels.tilePipeline,
    tilePipelineDetail: labels.tilePipelineDetail,
    tilePipelineMixed: labels.tilePipelineMixed,
    tileCases: labels.tileCases,
    tileCasesEscalated: labels.tileCasesEscalated,
    tileCasesOldest: labels.tileCasesOldest,
    tileCasesNotEscalated: labels.tileCasesNotEscalated,
    tileNoValue: labels.tileNoValue,
    viewMore: labels.viewMore,
    showLess: labels.showLess,
    viewAll: labels.viewAll,
    tileLicenses: labels.tileLicenses,
    tileLicensesDetail: labels.tileLicensesDetail,
    tileLicensesUnassigned: labels.tileLicensesUnassigned,
    scoreOf: labels.scoreOf,
    overrideCallout: labels.overrideCallout,
    routingHeading: labels.routingHeading,
    amberFloor: labels.amberFloor,
    risks: labels.risks,
    growth: labels.growth,
    noRisks: labels.noRisks,
    noGrowth: labels.noGrowth,
    whenToday: labels.whenToday,
    whenThisWeek: labels.whenThisWeek,
    whenPostClose: labels.whenPostClose,
    laneSales: labels.laneSales,
    laneService: labels.laneService,
    colName: labels.colName,
    colStage: labels.colStage,
    colAmount: labels.colAmount,
    colCloseDate: labels.colCloseDate,
    colSubject: labels.colSubject,
    colPriority: labels.colPriority,
    colOwner: labels.colOwner,
    colAge: labels.colAge,
    colClosed: labels.colClosed,
    colContact: labels.colContact,
    colRole: labels.colRole,
    colLastActivity: labels.colLastActivity,
    ageDays: labels.ageDays,
    daysAgo: labels.daysAgo,
    nextStep: labels.nextStep,
    agreementHeading: labels.agreementHeading,
    noOpenOpportunities: labels.noOpenOpportunities,
    openCasesHeading: labels.openCasesHeading,
    closedCasesHeading: labels.closedCasesHeading,
    noOpenCases: labels.noOpenCases,
    noClosedCases: labels.noClosedCases,
    escalatedChip: labels.escalatedChip,
    noContacts: labels.noContacts,
    accountTeamHeading: labels.accountTeamHeading,
    openNow: labels.openNow,
    noHistory: labels.noHistory,
    researchDisclaimer: labels.researchDisclaimer,
    researchSources: labels.researchSources,
    searchSuggestions: labels.searchSuggestions,
    searchLimitation: labels.searchLimitation,
    searchesHeading: labels.searchesHeading,
    pdfSearchSuggestionsNote: labels.pdfSearchSuggestionsNote,
    researchSummary: labels.researchSummary,
    researchKindBusinessEvent: labels.researchKindBusinessEvent,
    researchKindFinancialSignal: labels.researchKindFinancialSignal,
    researchKindLeadership: labels.researchKindLeadership,
    evidenceButton: labels.evidenceButton,
    pdfDownload: labels.pdfDownload,
    pdfPreparing: labels.pdfPreparing,
    pdfError: labels.pdfError,
    pdfStarted: labels.pdfStarted,
    pdfTitle: labels.pdfTitle,
    pdfSnapshot: labels.pdfSnapshot,
    pdfExported: labels.pdfExported,
    pdfDataAsOf: labels.pdfDataAsOf,
    pdfRecord: labels.pdfRecord,
    pdfFooter: labels.pdfFooter,
    pdfShowing: labels.pdfShowing,
    pdfSourceLink: labels.pdfSourceLink
  };
}

export function getLoadingMessages() {
  return [...labels.loadingMessages];
}

/* Replaces {0}, {1}… with the matching values, leaving unknown placeholders untouched. */
export function formatLabel(template, ...values) {
  return String(template).replace(/\{(\d+)\}/g, (match, index) => {
    return index < values.length ? String(values[index]) : match;
  });
}
