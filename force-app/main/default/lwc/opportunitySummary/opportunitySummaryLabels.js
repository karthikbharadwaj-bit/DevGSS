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
import pdfPostClose from "@salesforce/label/c.OpportunitySummaryPdfPostClose";
import pdfResearch from "@salesforce/label/c.OpportunitySummaryPdfResearch";
import pdfSupplemental from "@salesforce/label/c.OpportunitySummaryPdfSupplemental";
import pdfSources from "@salesforce/label/c.OpportunitySummaryPdfSources";
import pdfSearches from "@salesforce/label/c.OpportunitySummaryPdfSearches";
import pdfRelevance from "@salesforce/label/c.OpportunitySummaryPdfRelevance";
import pdfAction from "@salesforce/label/c.OpportunitySummaryPdfAction";
import fromCall from "@salesforce/label/c.OpportunitySummaryFromCall";

export const labels = {
  loading1: loading1 || "Gathering opportunity details and stage history…",
  loading2: loading2 || "Reviewing recent activities, tasks, and meetings…",
  loading3: loading3 || "Mapping the buying group and stakeholder engagement…",
  loading4:
    loading4 ||
    "Checking related cases and prior opportunities on this account…",
  loading5:
    loading5 || "Securing sensitive details with advanced protection checks…",
  loading6:
    loading6 ||
    "Activating Gemini to score deal health, risks, and win factors…",
  loading7: loading7 || "Shaping your next best actions and close plan…",
  loading8:
    loading8 || "Almost there — assembling your decision-ready summary.",
  researchDisclaimer:
    researchDisclaimer ||
    "AI-generated company research — This information was found and summarized using AI and public web search. It may be incomplete or inaccurate. Verify important details and sources before using it in customer or deal decisions.",
  searchLimitation:
    searchLimitation ||
    "Google Search Suggestions aren’t shown because Lightning Web Security sanitizes HTML and SVG strings inserted into the DOM. Showing the supplied markup would change it.",
  genericError:
    genericError ||
    "We're having trouble generating this summary right now. Please try again later.",
  emptyMessage:
    emptyMessage || "No summary is available for this opportunity yet.",
  missingRecord: missingRecord || "No opportunity record is available.",
  supplementalHelper:
    supplementalHelper ||
    "These public company updates were not linked to the current opportunity by the AI analysis.",
  researchHelper:
    researchHelper ||
    "Public information used to enrich this opportunity summary. Public signals do not prove customer requirements, budget, buying intent, or decision authority.",
  workingEyebrow: workingEyebrow || "Request in flight",
  workingTitle: workingTitle || "Building your opportunity brief",
  workingHint: workingHint || "You can keep working",
  errorEyebrow: errorEyebrow || "Summary interrupted",
  errorTitle: errorTitle || "We couldn’t finish this request",
  retryButton: retryButton || "Try Again",
  readyEyebrow: readyEyebrow || "Ready to review",
  readyTitle: readyTitle || "Your opportunity summary is ready",
  readyHint: readyHint || "Open whenever you’re ready.",
  viewButton: viewButton || "View Summary",
  idleEyebrow: idleEyebrow || "Decision-ready deal intelligence",
  idleTitle: idleTitle || "Build a fresh opportunity brief",
  idleHint:
    idleHint ||
    "Review deal health, risks, stakeholder context, and recommended next steps while continuing to work on this record.",
  generateButton: generateButton || "Generate Summary",
  refreshButton: refreshButton || "Refresh Opportunity Summary",
  poweredBy: poweredBy || "Powered by",
  generatedNow: generatedNow || "Generated just now",
  generatedMinute: generatedMinute || "Generated {0} minute ago",
  generatedMinutes: generatedMinutes || "Generated {0} minutes ago",
  generatedHour: generatedHour || "Generated {0} hour ago",
  generatedHours: generatedHours || "Generated {0} hours ago",
  elapsed: elapsed || "{0} elapsed",
  errorIcon: errorIcon || "Error",
  readyIcon: readyIcon || "Ready",
  cacheHours: cacheHours || "1",
  cacheMaxKB: cacheMaxKB || "512",
  researchGroups:
    researchGroups ||
    '[{"kind":"leadership","label":"Current Leadership","order":1,"active":true},{"kind":"priority","label":"Company Direction and Priorities","order":2,"active":true}]',
  pdfDownload: pdfDownload || "Download PDF",
  pdfPreparing: pdfPreparing || "Preparing PDF…",
  pdfError:
    pdfError ||
    "We couldn’t download the PDF. Your summary is still available. Please try again.",
  pdfStarted: pdfStarted || "PDF download started.",
  pdfTitle: pdfTitle || "Opportunity Summary",
  pdfSnapshot: pdfSnapshot || "Summary received",
  pdfExported: pdfExported || "Exported",
  pdfRecord: pdfRecord || "Open opportunity in Salesforce",
  pdfFooter:
    pdfFooter ||
    "AI-generated • Verify important details before sharing or making decisions.",
  pdfStage: pdfStage || "Stage at export",
  pdfScore: pdfScore || "Overall Deal Score",
  pdfExecutive: pdfExecutive || "Executive Summary",
  pdfHistory: pdfHistory || "Opportunity History & Stage Journey",
  pdfWin: pdfWin || "Win Factors",
  pdfRisk: pdfRisk || "Risk Flags",
  pdfActions: pdfActions || "Next Best Actions",
  pdfPlan: pdfPlan || "Close Plan",
  pdfPostClose: pdfPostClose || "Post-Close Actions",
  pdfResearch: pdfResearch || "Public Research Used",
  pdfSupplemental: pdfSupplemental || "Additional Company Updates",
  pdfSources: pdfSources || "Other Research Sources",
  pdfSearches: pdfSearches || "Searches Performed",
  pdfRelevance: pdfRelevance || "Relevance",
  pdfAction: pdfAction || "Suggested Action",
  fromCall: fromCall || "From a recorded customer call (RingSense)"
};
