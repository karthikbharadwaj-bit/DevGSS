import { LightningElement, api } from "lwc";
import LOCALE from "@salesforce/i18n/locale";
import USER_ID from "@salesforce/user/Id";
import aiInsightsLogo from "@salesforce/resourceUrl/AI_Insights";
import makeGCPCallout from "@salesforce/apex/GCPCalloutForAccountSummary.makeGCPCallout";
import isAccountSummaryEnabled from "@salesforce/apex/GCPCalloutForAccountSummary.isAccountSummaryEnabled";
import logAIHEvent from "@salesforce/apex/GCPCalloutForOpportunitySummary.logAIHEvent";
import {
  formatLabel,
  getCachePolicy,
  getListRowLimits,
  getLoadingMessages,
  getUiLabels
} from "./aiAccountSummaryConfig";
import { buildAccountViewModel, isObject } from "./aiAccountSummaryModel";

const SUBFEATURE = "Account Summary";
const LOADING_INTERVAL_MS = 3900;
const CLOCK_INTERVAL_MS = 60000;
const CACHE_KEY_PREFIX = "aiAccountSummary:v1";
const CACHE_STORAGE_PREFIX = `${CACHE_KEY_PREFIX}:`;
const CACHE_USER_KEY_PREFIX = `${CACHE_KEY_PREFIX}:${USER_ID}:`;
const HIGHLIGHT_DURATION_MS = 1600;
const EVIDENCE_ID_PATTERN = /^E\d+$/;
const HIGHLIGHT_CLASS = "is-highlighted";
const CACHED_KEYS = ["as_of_date", "account_summary", "account_enrichment"];
const LIST_OPPORTUNITIES = "opportunities";
const LIST_OPEN_CASES = "open-cases";
const LIST_CLOSED_CASES = "closed-cases";
const RELATED_LIST_OPPORTUNITIES = "Opportunities";
const RELATED_LIST_CASES = "Cases";
/* Account history grows with its entries up to this many, then scrolls inside the card. */
const HISTORY_VISIBLE_EVENTS = 10;

function storageEntryBytes(key, value) {
  return (String(key).length + String(value).length) * 2;
}

function isSummaryResponse(value) {
  return isObject(value) && isObject(value.account_summary);
}

export default class AiAccountSummary extends LightningElement {
  _recordId;
  _isConnected = false;

  labels = getUiLabels();
  loadingMessages = getLoadingMessages();
  aiInsightsLogo = aiInsightsLogo;

  isFeatureEnabled = false;
  isModalOpen = false;
  isLoading = false;
  isError = false;
  errorMessage = "";
  hasFetched = false;
  aihViewLogged = false;
  view = null;
  /* Lists the user expanded with View more; cleared whenever the modal opens. */
  expandedLists = [];
  listRowLimits = getListRowLimits();
  isHistoryScrolledToEnd = false;
  isHistoryScrolledFromTop = false;

  generatedAt = null;
  generatedLabel = "";
  generationElapsedLabel = formatLabel(this.labels.elapsed, "00:00");
  loadingMessage = this.loadingMessages[0];

  _clockId = null;
  _elapsedClockId = null;
  _generationStartedAt = null;
  _loadingMessageId = null;
  _escapeHandler = null;
  _requestToken = 0;
  _highlightTimeoutId = null;
  _highlightedTarget = null;

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
    this.view = null;
    this._stopClock();
    this._stopElapsedClock();
    this._stopLoadingMessages();
    this._unbindEscape();
    if (this._isConnected && this.isFeatureEnabled) {
      this.restoreCachedSummary();
    }
  }

  connectedCallback() {
    this._isConnected = true;
    isAccountSummaryEnabled()
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

  disconnectedCallback() {
    this._isConnected = false;
    this._stopClock();
    this._stopElapsedClock();
    this._stopLoadingMessages();
    this._unbindEscape();
    this._clearEvidenceHighlight();
  }

  get cacheKey() {
    return `${CACHE_USER_KEY_PREFIX}${this.recordId}`;
  }

  get hasContent() {
    const view = this.view;
    return Boolean(
      view &&
      (view.header.narrative.length ||
        view.flag.hasScore ||
        view.risks.length ||
        view.growth.length ||
        view.actions.length ||
        view.opportunities.rows.length ||
        view.cases.open.length ||
        view.cases.closed.length ||
        view.contacts.contacts.length ||
        view.history.length)
    );
  }

  get showEmptyState() {
    return !this.isLoading && !this.isError && !this.hasContent;
  }

  get hasOpportunities() {
    return Boolean(this.view && this.view.opportunities.rows.length);
  }

  get hasOpenCases() {
    return Boolean(this.view && this.view.cases.open.length);
  }

  get hasClosedCases() {
    return Boolean(this.view && this.view.cases.closed.length);
  }

  get hasContacts() {
    return Boolean(this.view && this.view.contacts.contacts.length);
  }

  get hasAccountTeam() {
    return Boolean(this.view && this.view.contacts.team.length);
  }

  get hasHistory() {
    return Boolean(this.view && this.view.history.length);
  }

  get historyEventCount() {
    return this.view
      ? this.view.history.reduce(
          (total, group) => total + group.events.length,
          0
        )
      : 0;
  }

  get isHistoryCapped() {
    return this.historyEventCount > HISTORY_VISIBLE_EVENTS;
  }

  get historyScrollClass() {
    if (!this.isHistoryCapped) {
      return "history-scroll";
    }
    return [
      "history-scroll history-scroll_capped",
      this.isHistoryScrolledFromTop ? "history-scroll_fade-top" : "",
      this.isHistoryScrolledToEnd ? "" : "history-scroll_fade-bottom"
    ]
      .filter(Boolean)
      .join(" ");
  }

  /*
   * Each edge fades only while entries are hidden past it, so the first and last entries are
   * never left faded.
   */
  handleHistoryScroll(event) {
    const { scrollTop, clientHeight, scrollHeight } = event.currentTarget;
    const isAtEnd = scrollTop + clientHeight >= scrollHeight - 2;
    const isFromTop = scrollTop > 2;
    if (isAtEnd !== this.isHistoryScrolledToEnd) {
      this.isHistoryScrolledToEnd = isAtEnd;
    }
    if (isFromTop !== this.isHistoryScrolledFromTop) {
      this.isHistoryScrolledFromTop = isFromTop;
    }
  }

  /* A scrolling region must be reachable by keyboard so it can be scrolled without a mouse. */
  get historyScrollTabIndex() {
    return this.isHistoryCapped ? "0" : "-1";
  }

  // The icon slot is reserved only when an item is flagged, so summaries without
  // call insights keep today's layout exactly.
  get signalsRowClass() {
    return this.view && this.view.hasCallInsights
      ? "as-row has-call-insights"
      : "as-row";
  }

  get hasRisks() {
    return Boolean(this.view && this.view.risks.length);
  }

  get hasGrowth() {
    return Boolean(this.view && this.view.growth.length);
  }

  get hasRouting() {
    return Boolean(this.view && this.view.flag.routing.length);
  }

  get hasHeaderRows() {
    return Boolean(this.view && this.view.header.rows.length);
  }

  get hasTiles() {
    return Boolean(this.view && this.view.tiles.length);
  }

  get hasBars() {
    return Boolean(this.view && this.view.flag.bars.length);
  }

  get hasActions() {
    return Boolean(this.view && this.view.actions.length);
  }

  get opportunityCount() {
    return this.view ? this.view.opportunities.totalCount : 0;
  }

  get contactCount() {
    return this.view ? this.view.contacts.contacts.length : 0;
  }

  get actionCount() {
    return this.view ? this.view.actions.length : 0;
  }

  get opportunityList() {
    return this._listState(
      LIST_OPPORTUNITIES,
      this.view.opportunities.rows,
      this.view.opportunities.totalCount,
      RELATED_LIST_OPPORTUNITIES
    );
  }

  get openCaseList() {
    return this._listState(
      LIST_OPEN_CASES,
      this.view.cases.open,
      this.view.cases.openTotal,
      RELATED_LIST_CASES
    );
  }

  get closedCaseList() {
    return this._listState(
      LIST_CLOSED_CASES,
      this.view.cases.closed,
      this.view.cases.closedTotal,
      RELATED_LIST_CASES
    );
  }

  /*
   * Shows the first rows, all rows up to the expanded limit after View more, and a link to the
   * Account related list once the total is more than the expanded limit can hold.
   */
  _listState(listKey, rows, totalCount, relatedListName) {
    const { initialRows } = this.listRowLimits;
    const isExpanded = this.expandedLists.includes(listKey);
    const hiddenCount = Math.max(rows.length - initialRows, 0);
    const hasAllLink = totalCount > rows.length && (isExpanded || !hiddenCount);
    return {
      key: listKey,
      rows: isExpanded ? rows : rows.slice(0, initialRows),
      hasToggle: hiddenCount > 0,
      isExpanded: String(isExpanded),
      toggleLabel: isExpanded
        ? this.labels.showLess
        : formatLabel(this.labels.viewMore, hiddenCount),
      hasAllLink,
      allLabel: formatLabel(this.labels.viewAll, totalCount),
      allUrl: hasAllLink
        ? `/lightning/r/Account/${this.recordId}/related/${relatedListName}/view`
        : ""
    };
  }

  handleListToggle(event) {
    const listKey = event.currentTarget.dataset.listToggle;
    this.expandedLists = this.expandedLists.includes(listKey)
      ? this.expandedLists.filter((key) => key !== listKey)
      : [...this.expandedLists, listKey];
  }

  renderedCallback() {
    this._fitHistoryHeight();
  }

  /*
   * Stops the history card at the bottom of its tenth entry. Entries wrap to different
   * heights, so the cut is measured; the CSS max-height covers a failed measurement.
   */
  _fitHistoryHeight() {
    const scroller = this.template.querySelector("[data-history-scroll]");
    if (!scroller) {
      return;
    }
    const events = scroller.querySelectorAll("[data-history-event]");
    if (events.length <= HISTORY_VISIBLE_EVENTS) {
      scroller.style.maxHeight = "";
      return;
    }
    const lastVisible = events[HISTORY_VISIBLE_EVENTS - 1];
    const height =
      lastVisible.getBoundingClientRect().bottom -
      scroller.getBoundingClientRect().top +
      scroller.scrollTop;
    scroller.style.maxHeight = height > 0 ? `${Math.ceil(height)}px` : "";
  }

  openModal() {
    if (!this.hasFetched || this.isLoading || this.isError) {
      return;
    }
    this.expandedLists = [];
    this.isHistoryScrolledToEnd = false;
    this.isHistoryScrolledFromTop = false;
    this.isModalOpen = true;
    this._logView();
    this._bindEscape();
  }

  closeModal() {
    this.isModalOpen = false;
    this._unbindEscape();
    this._clearEvidenceHighlight();
  }

  /*
   * Evidence chips point at a finding inside the research drawer, which is collapsed by
   * default, so its sections are opened before the finding is scrolled to and highlighted.
   */
  handleEvidenceClick(event) {
    const evidenceId = event.currentTarget.dataset.evidenceId;
    if (!EVIDENCE_ID_PATTERN.test(String(evidenceId || ""))) {
      return;
    }
    const target = this.template.querySelector(
      `[data-research-finding="${evidenceId}"]`
    );
    if (!target) {
      return;
    }
    /* Open every collapsed section around the finding, including the additional group. */
    for (let node = target.parentElement; node; node = node.parentElement) {
      if (node.tagName === "DETAILS") {
        node.open = true;
      }
    }
    if (typeof target.scrollIntoView === "function") {
      target.scrollIntoView({ behavior: "smooth", block: "center" });
    }
    target.focus();
    this._clearEvidenceHighlight();
    target.classList.add(HIGHLIGHT_CLASS);
    this._highlightedTarget = target;
    // A brief highlight confirms where pointer or keyboard navigation landed.
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    this._highlightTimeoutId = setTimeout(
      () => this._clearEvidenceHighlight(),
      HIGHLIGHT_DURATION_MS
    );
  }

  _clearEvidenceHighlight() {
    if (this._highlightTimeoutId) {
      clearTimeout(this._highlightTimeoutId);
      this._highlightTimeoutId = null;
    }
    if (this._highlightedTarget) {
      this._highlightedTarget.classList.remove(HIGHLIGHT_CLASS);
      this._highlightedTarget = null;
    }
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
    this.view = null;
    this._stopClock();
    this._startLoadingMessages();
    this._startElapsedClock();

    try {
      const result = await makeGCPCallout({ recordId: this.recordId });
      if (requestToken !== this._requestToken) {
        return;
      }

      let parsed;
      try {
        parsed = JSON.parse(result);
      } catch {
        this._showError(this.labels.genericError);
        return;
      }

      if (parsed && parsed.success === true && isSummaryResponse(parsed)) {
        this._applySummary(parsed, Date.now());
        this.cacheSummary(parsed, this.generatedAt);
      } else if (parsed && parsed.success === false && parsed.message) {
        this._showError(parsed.message);
      } else {
        this._showError(this.labels.genericError);
      }
    } catch (error) {
      if (requestToken === this._requestToken) {
        this._showError(
          (error && error.body && error.body.message) ||
            this.labels.genericError
        );
      }
    } finally {
      if (requestToken === this._requestToken) {
        this._stopLoadingMessages();
        this._stopElapsedClock();
        this.isLoading = false;
      }
    }
  }

  _applySummary(response, generatedAt) {
    this.view = buildAccountViewModel(response, this.labels, LOCALE);
    this.hasFetched = true;
    this.generatedAt = generatedAt;
    this._updateGeneratedLabel();
    this._startClock();
  }

  _showError(message) {
    this.isError = true;
    this.errorMessage = message;
  }

  // ---------------- Browser cache ----------------

  restoreCachedSummary() {
    if (!this.recordId || this.hasFetched || this.isLoading) {
      return false;
    }
    const entry = this.readCachedSummary();
    if (!entry) {
      return false;
    }
    this._applySummary(entry.summary, entry.cachedAt);
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
      if (
        Number.isFinite(age) &&
        age >= 0 &&
        age < ttlMs &&
        isSummaryResponse(entry.summary)
      ) {
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

  cacheSummary(response, cachedAt) {
    const { maxBytes } = getCachePolicy();
    try {
      const storage = window.localStorage;
      const summary = {};
      CACHED_KEYS.forEach((key) => {
        if (Object.prototype.hasOwnProperty.call(response, key)) {
          summary[key] = response[key];
        }
      });
      const serializedEntry = JSON.stringify({ cachedAt, summary });
      const incomingBytes = storageEntryBytes(this.cacheKey, serializedEntry);
      if (incomingBytes > maxBytes) {
        storage.removeItem(this.cacheKey);
        return;
      }

      const existingEntries = this.getCacheEntries(this.cacheKey);
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

  getCacheEntries(excludedKey) {
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
        entries.push({ key, cachedAt, bytes: storageEntryBytes(key, value) });
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

  // ---------------- Clocks and modal ----------------

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

  // Steps through the narration once and holds on the last line, so a slow
  // callout never appears to restart from the beginning.
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
    const minutes = String(Math.floor(totalSeconds / 60)).padStart(2, "0");
    const seconds = String(totalSeconds % 60).padStart(2, "0");
    this.generationElapsedLabel = formatLabel(
      this.labels.elapsed,
      `${minutes}:${seconds}`
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
