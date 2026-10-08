import { formatLabel, getListRowLimits } from "./aiAccountSummaryConfig";

const DIAL_RADIUS = 35;
const DIAL_CIRCUMFERENCE = 2 * Math.PI * DIAL_RADIUS;
const STRONG_BAR_RATIO = 0.8;
const WEAK_BAR_RATIO = 0.5;
const OPEN_NOW_PERIOD = "open_now";
const SAFE_URL_PATTERN = /^https?:\/\//i;
const ISO_DATE_PATTERN = /^(\d{4})-(\d{2})(?:-(\d{2}))?/;
const EVIDENCE_REFERENCE_PATTERN = /\s*\[(E\d+)\]/g;
/* The service writes this phrase for every null; those items carry no Salesforce signal. */
const NOT_RECORDED_PATTERN = /not recorded in salesforce/i;
/* The org mixes Critical/High, P0-P4 and "1 – Critical" schemes; all of these are top tier. */
const TOP_PRIORITY_PATTERN = /^(critical|p0|p1|1\s*[–-])/i;
/* Shown wherever a Salesforce source is empty, so header rows and tiles keep their places. */
const EMPTY_VALUE = "—";
const PRIMARY_TILE_ORDER = [
  "mrr",
  "mrr_trajectory",
  "total_open_pipeline",
  "open_cases",
  "licenses"
];
const PRIMARY_TILE_LABEL_KEYS = {
  mrr: "tileMrr",
  mrr_trajectory: "tileTrajectory",
  total_open_pipeline: "tilePipeline",
  open_cases: "tileCases",
  licenses: "tileLicenses"
};
const WHEN_CHIPS = {
  today: { labelKey: "whenToday", chipClass: "chip chip_red" },
  this_week: { labelKey: "whenThisWeek", chipClass: "chip chip_amber" },
  post_close: { labelKey: "whenPostClose", chipClass: "chip chip_grey" }
};
const LANE_LABELS = { sales: "laneSales", service: "laneService" };
const BAND_KEYS = { green: "green", amber: "amber", red: "red" };
const RESEARCH_KIND_LABELS = {
  business_event: "researchKindBusinessEvent",
  financial_signal: "researchKindFinancialSignal",
  leadership_change: "researchKindLeadership",
  leadership: "researchKindLeadership"
};
const EVENT_CLASSES = {
  opportunity: "event event_opportunity",
  case: "event event_case",
  entitlement: "event event_entitlement",
  escalation: "event event_escalation",
  activation: "event event_activation"
};

export function isObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function asArray(value) {
  return Array.isArray(value) ? value : [];
}

function asObject(value) {
  return isObject(value) ? value : {};
}

export function hasValue(value) {
  return (
    value !== null &&
    value !== undefined &&
    !(typeof value === "string" && value.trim() === "")
  );
}

function isNumber(value) {
  return typeof value === "number" && Number.isFinite(value);
}

function text(value) {
  return hasValue(value) ? String(value) : "";
}

export function formatNumber(value, locale, maximumFractionDigits = 2) {
  if (!isNumber(value)) {
    return "";
  }
  return new Intl.NumberFormat(locale, { maximumFractionDigits }).format(value);
}

/* Amounts carry an ISO code, never a symbol, so tiles match the narrative. */
export function formatMoney(value, currencyIsoCode, locale) {
  if (!isNumber(value)) {
    return "";
  }
  const amount = formatNumber(value, locale);
  return hasValue(currencyIsoCode) ? `${currencyIsoCode} ${amount}` : amount;
}

export function formatDate(value, locale) {
  if (!hasValue(value)) {
    return "";
  }
  const match = ISO_DATE_PATTERN.exec(String(value));
  if (!match) {
    return String(value);
  }
  const year = Number(match[1]);
  const month = Number(match[2]) - 1;
  const hasDay = match[3] !== undefined;
  const date = new Date(Date.UTC(year, month, hasDay ? Number(match[3]) : 1));
  if (Number.isNaN(date.getTime())) {
    return String(value);
  }
  const options = hasDay
    ? { day: "numeric", month: "short", year: "numeric", timeZone: "UTC" }
    : { month: "short", year: "numeric", timeZone: "UTC" };
  return new Intl.DateTimeFormat(locale, options).format(date);
}

function recordUrl(id) {
  return hasValue(id) ? `/${encodeURIComponent(String(id))}` : null;
}

function timeOf(value) {
  const time = hasValue(value) ? Date.parse(value) : NaN;
  return Number.isNaN(time) ? null : time;
}

/* Sorts on a date field; rows without a usable date go last whatever the direction. */
function byDate(field, isNewestFirst) {
  return (left, right) => {
    const leftTime = timeOf(left[field]);
    const rightTime = timeOf(right[field]);
    if (leftTime === rightTime) {
      return 0;
    }
    if (leftTime === null) {
      return 1;
    }
    if (rightTime === null) {
      return -1;
    }
    return isNewestFirst ? rightTime - leftTime : leftTime - rightTime;
  };
}

function joinPresent(parts, separator = " · ") {
  return parts.filter(hasValue).join(separator);
}

function isNotRecorded(value) {
  return NOT_RECORDED_PATTERN.test(String(value || ""));
}

function toHtmlLines(value, keyPrefix) {
  const lines = Array.isArray(value) ? value : [value];
  return lines.filter(hasValue).map((html, index) => ({
    key: `${keyPrefix}-${index}`,
    html: String(html)
  }));
}

function isTopPriority(priority) {
  return hasValue(priority) && TOP_PRIORITY_PATTERN.test(String(priority));
}

// ---------------- Evidence ----------------

/*
 * Model prose cites public research as "[E7]". Known ids are lifted out of the text and
 * returned as evidence chips; unknown ids stay in the text so nothing is silently lost.
 */
export function extractEvidence(value, findingById) {
  const ids = [];
  const cleaned = text(value).replace(
    EVIDENCE_REFERENCE_PATTERN,
    (match, id) => {
      if (!findingById.has(id)) {
        return match;
      }
      if (!ids.includes(id)) {
        ids.push(id);
      }
      return "";
    }
  );
  return { text: cleaned.trim(), ids };
}

function withEvidence(item, findingById, keyPrefix, labels) {
  /* source names the field or metric behind the item; only its evidence ids are shown. */
  const detail = extractEvidence(item.detail, findingById);
  const source = extractEvidence(item.source, findingById);
  const ids = [
    ...detail.ids,
    ...source.ids.filter((id) => !detail.ids.includes(id))
  ];
  return {
    detail: detail.text,
    evidence: ids.map((id) => ({
      key: `${keyPrefix}-${id}`,
      id,
      label: id,
      ariaLabel: formatLabel(labels.evidenceButton, id)
    }))
  };
}

// ---------------- Section builders ----------------

/* Rows without a recorded value are left out rather than shown as placeholders. */
function headerValueClass(isMono, isEmpty) {
  if (isEmpty) {
    return "value_empty";
  }
  return isMono ? "mono" : "";
}

export function buildHeader(header, labels, locale) {
  const fields = asObject(asObject(header).fields);
  const since = joinPresent([
    formatDate(fields.customer_since, locale),
    isNumber(fields.account_age_months)
      ? formatLabel(labels.ageMonths, fields.account_age_months)
      : "",
    fields.tenure_band
  ]);
  const rows = [
    ["account", labels.fieldAccount, fields.account_name],
    ["industry", labels.fieldIndustry, fields.industry],
    ["location", labels.fieldLocation, fields.location],
    [
      "type",
      labels.fieldTypeStatus,
      joinPresent([fields.type, fields.rc_account_status])
    ],
    ["tier", labels.fieldTier, fields.tier, true],
    ["owner", labels.fieldOwner, fields.owner_name],
    ["csm", labels.fieldCsm, fields.csm_display || fields.csm_name],
    ["since", labels.fieldCustomerSince, since],
    ["rating", labels.fieldRating, fields.rating],
    ["source", labels.fieldSource, fields.account_source]
  ].map(([key, label, value, isMono]) => {
    const isEmpty = !hasValue(value) || isNotRecorded(value);
    return {
      key,
      label,
      value: isEmpty ? EMPTY_VALUE : String(value),
      valueClass: headerValueClass(isMono, isEmpty)
    };
  });
  return {
    /* With no header at all there is nothing to line up, so no rows are shown. */
    rows: Object.keys(fields).length ? rows : [],
    narrative: toHtmlLines(asObject(header).narrative, "narrative")
  };
}

function primaryTileValue(tile, labels, locale) {
  switch (tile.key) {
    case "mrr":
      return formatMoney(tile.value, tile.currencyIsoCode, locale);
    case "total_open_pipeline":
      return tile.currency_mixed === true
        ? labels.tilePipelineMixed
        : formatMoney(tile.value, tile.currencyIsoCode, locale);
    case "mrr_trajectory":
      return isNumber(tile.value_pct)
        ? `${tile.value_pct > 0 ? "+" : ""}${formatNumber(tile.value_pct, locale, 1)}%`
        : "";
    case "open_cases":
      return isNumber(tile.value) ? formatNumber(tile.value, locale) : "";
    case "licenses":
      return isNumber(tile.purchased) && isNumber(tile.in_use)
        ? `${formatNumber(tile.purchased, locale)} / ${formatNumber(tile.in_use, locale)}`
        : "";
    default:
      return "";
  }
}

function primaryTileDetail(tile, labels, locale) {
  const code = tile.currencyIsoCode;
  switch (tile.key) {
    case "mrr":
      return isNumber(tile.annualized_mrr)
        ? formatLabel(
            labels.tileMrrDetail,
            formatMoney(tile.annualized_mrr, code, locale)
          )
        : "";
    case "mrr_trajectory":
      return isNumber(tile.acquisition_mrr)
        ? formatLabel(
            labels.tileTrajectoryDetail,
            formatMoney(tile.acquisition_mrr, code, locale)
          )
        : "";
    case "total_open_pipeline":
      return isNumber(tile.open_opp_count)
        ? formatLabel(labels.tilePipelineDetail, tile.open_opp_count)
        : "";
    case "open_cases":
      return joinPresent([
        tile.top_priority,
        isNumber(tile.oldest_age_days)
          ? formatLabel(labels.tileCasesOldest, tile.oldest_age_days)
          : "",
        tileEscalationText(tile.escalated_count, labels)
      ]);
    case "licenses":
      return joinPresent([
        isNumber(tile.utilization_pct)
          ? formatLabel(
              labels.tileLicensesDetail,
              formatNumber(tile.utilization_pct, locale, 1)
            )
          : "",
        isNumber(tile.unassigned)
          ? formatLabel(labels.tileLicensesUnassigned, tile.unassigned)
          : ""
      ]);
    default:
      return "";
  }
}

function tileEscalationText(escalatedCount, labels) {
  if (!isNumber(escalatedCount)) {
    return "";
  }
  return escalatedCount > 0
    ? formatLabel(labels.tileCasesEscalated, escalatedCount)
    : labels.tileCasesNotEscalated;
}

function primaryTileNumber(tile) {
  return tile.key === "mrr_trajectory" ? tile.value_pct : tile.value;
}

function tileValueClass(isNegative, isEmpty) {
  if (isEmpty) {
    return "tile-value tile-value_empty";
  }
  return isNegative ? "tile-value tile-value_negative" : "tile-value";
}

function makeTile(
  key,
  label,
  value,
  detail,
  { isAmber, isNegative, isEmpty } = {}
) {
  return {
    key,
    label,
    value,
    detail,
    tileClass: isAmber ? "tile tile_amber" : "tile",
    valueClass: tileValueClass(isNegative, isEmpty)
  };
}

export function buildTiles(keyMetrics, labels, locale) {
  const keyToTile = new Map(
    asArray(asObject(keyMetrics).tiles)
      .filter(isObject)
      .map((tile) => [tile.key, tile])
  );
  return PRIMARY_TILE_ORDER.map((key) => {
    const tile = { key, ...asObject(keyToTile.get(key)) };
    const value = primaryTileValue(tile, labels, locale);
    if (!hasValue(value)) {
      return makeTile(
        key,
        labels[PRIMARY_TILE_LABEL_KEYS[key]],
        EMPTY_VALUE,
        labels.tileNoValue,
        { isEmpty: true }
      );
    }
    const number = primaryTileNumber(tile);
    return makeTile(
      key,
      labels[PRIMARY_TILE_LABEL_KEYS[key]],
      value,
      primaryTileDetail(tile, labels, locale),
      {
        isAmber: tile.flag === "amber",
        isNegative:
          (key === "mrr" ||
            key === "mrr_trajectory" ||
            key === "total_open_pipeline") &&
          isNumber(number) &&
          number < 0
      }
    );
  });
}

function buildSignalItems(items, keyPrefix, findingById, labels) {
  return asArray(items)
    .filter(
      (item) =>
        isObject(item) &&
        !isNotRecorded(item.title) &&
        !isNotRecorded(item.detail)
    )
    .map((item, index) => {
      const key = `${keyPrefix}-${index}`;
      return {
        key,
        title: text(item.title),
        // A missing from_call means the item did not come from a call.
        fromCall: item.from_call === true,
        ...withEvidence(item, findingById, key, labels)
      };
    });
}

export function buildSignals(signals, labels, findingById = new Map()) {
  const source = asObject(signals);
  return {
    risks: buildSignalItems(source.risks, "risk", findingById, labels),
    growth: buildSignalItems(source.growth, "growth", findingById, labels)
  };
}

export function buildActions(actions, labels, findingById = new Map()) {
  return asArray(actions)
    .filter(isObject)
    .map((action, index) => {
      const key = `action-${index}`;
      const chip = WHEN_CHIPS[action.when] || {
        labelKey: null,
        chipClass: "chip chip_grey"
      };
      return {
        key,
        whenLabel: chip.labelKey ? labels[chip.labelKey] : text(action.when),
        chipClass: chip.chipClass,
        laneLabel: LANE_LABELS[action.lane]
          ? labels[LANE_LABELS[action.lane]]
          : "",
        title: text(action.title),
        fromCall: action.from_call === true,
        ...withEvidence(action, findingById, key, labels)
      };
    });
}

/* Soonest close date first, so overdue deals lead; rows past the expanded limit are dropped. */
export function buildOpportunities(
  section,
  labels,
  locale,
  rowLimit = getListRowLimits().maxRows
) {
  const source = asObject(section);
  const allRows = asArray(source.rows).filter(isObject);
  const rows = [...allRows]
    .sort(byDate("close_date", false))
    .slice(0, rowLimit)
    .map((row, index) => ({
      key: row.id || `opportunity-${index}`,
      url: recordUrl(row.id),
      name: text(row.name),
      owner: text(row.owner_name),
      stage: text(row.stage_name),
      forecast: joinPresent([
        row.forecast_category,
        isNumber(row.probability)
          ? `${formatNumber(row.probability, locale)}%`
          : ""
      ]),
      amount: formatMoney(row.amount, row.currencyIsoCode, locale),
      amountClass: row.amount < 0 ? "num negative" : "num",
      closeDate: formatDate(row.close_date, locale),
      overdueLabel: text(row.overdue_label),
      nextStep: hasValue(row.next_step)
        ? `${labels.nextStep}: ${row.next_step}`
        : ""
    }));
  return {
    rows,
    totalCount: allRows.length,
    agreementText: text(source.agreement_status_text)
  };
}

/* Newest first: most recently opened open cases and most recently closed ones. */
export function buildCases(
  section,
  labels,
  locale,
  rowLimit = getListRowLimits().maxRows
) {
  const source = asObject(section);
  const allOpen = asArray(source.open).filter(isObject);
  const allClosed = asArray(source.recently_closed).filter(isObject);
  const open = [...allOpen]
    .sort(byDate("created_date", true))
    .slice(0, rowLimit)
    .map((row, index) => ({
      key: row.id || `open-case-${index}`,
      url: recordUrl(row.id),
      subject: text(row.subject) || text(row.case_number),
      detail: joinPresent([
        row.case_number,
        row.status,
        joinPresent([row.reason, row.type], " / ")
      ]),
      priority: text(row.priority),
      priorityClass: isTopPriority(row.priority)
        ? "chip chip_red"
        : "chip chip_grey",
      owner: text(row.owner_name),
      age: isNumber(row.age_days)
        ? formatLabel(labels.ageDays, row.age_days)
        : "",
      isEscalated: row.is_escalated === true
    }));
  const closed = [...allClosed]
    .sort(byDate("closed_date", true))
    .slice(0, rowLimit)
    .map((row, index) => ({
      key: row.id || `closed-case-${index}`,
      url: recordUrl(row.id),
      subject: text(row.subject) || text(row.case_number),
      priority: text(row.priority),
      closedMonth: formatDate(row.closed_month || row.closed_date, locale)
    }));
  const closedCount = isNumber(source.recently_closed_count)
    ? Math.max(source.recently_closed_count, allClosed.length)
    : allClosed.length;
  return {
    open,
    closed,
    openTotal: allOpen.length,
    closedTotal: closedCount,
    openHeading: formatLabel(labels.openCasesHeading, allOpen.length),
    closedHeading: formatLabel(labels.closedCasesHeading, closedCount)
  };
}

export function buildContacts(section, labels) {
  const source = asObject(section);
  const contacts = asArray(source.contacts)
    .filter(isObject)
    .map((row, index) => ({
      key: row.id || `contact-${index}`,
      url: recordUrl(row.id),
      name: text(row.name),
      title: text(row.title),
      role: text(row.customer_contact_role),
      lastActivity: isNumber(row.days_since_activity)
        ? formatLabel(labels.daysAgo, row.days_since_activity)
        : ""
    }));
  const team = asArray(source.account_team)
    .filter((member) => isObject(member) && hasValue(member.user_name))
    .map((member, index) => ({
      key: `team-${index}`,
      name: String(member.user_name),
      role: text(member.team_member_role)
    }));
  return { contacts, team, roleNote: text(source.role_note) };
}

export function buildFlag(flag, labels, locale) {
  const source = asObject(flag);
  const score = isNumber(source.score)
    ? Math.max(0, Math.min(100, source.score))
    : null;
  const bandKey = BAND_KEYS[String(source.band || "").toLowerCase()] || "grey";
  const bars = asArray(source.component_scores)
    .filter(isObject)
    .map((component, index) => {
      const ratio =
        isNumber(component.points) &&
        isNumber(component.max) &&
        component.max > 0
          ? Math.max(0, Math.min(1, component.points / component.max))
          : 0;
      let fillClass = "bar-fill bar-fill_bad";
      if (ratio >= STRONG_BAR_RATIO) {
        fillClass = "bar-fill";
      } else if (ratio >= WEAK_BAR_RATIO) {
        fillClass = "bar-fill bar-fill_warn";
      }
      return {
        key: component.key || `component-${index}`,
        label: text(component.label),
        points: `${isNumber(component.points) ? component.points : "–"}/${
          isNumber(component.max) ? component.max : "–"
        }`,
        fillClass,
        fillStyle: `width: ${Math.round(ratio * 100)}%`,
        barClass: ratio < WEAK_BAR_RATIO ? "bar bar_weak" : "bar"
      };
    });
  const hasOverride = hasValue(source.override_reason);
  return {
    hasScore: score !== null,
    score: score === null ? "" : String(Math.round(score)),
    scoreLabel: text(source.score_label),
    band: text(source.band),
    bandChipClass: `chip chip_${bandKey}`,
    dialClass: `dial-value dial-value_${bandKey}`,
    dialDash: `${score === null ? 0 : ((score / 100) * DIAL_CIRCUMFERENCE).toFixed(1)} ${DIAL_CIRCUMFERENCE.toFixed(1)}`,
    hasOverride,
    overrideClass: `override override_${bandKey}`,
    overrideTitle: hasOverride
      ? formatLabel(labels.overrideCallout, text(source.band))
      : "",
    overrideExplanation:
      text(source.override_explanation) ||
      (hasOverride ? String(source.override_reason) : ""),
    bars,
    routing: asArray(source.routing)
      .filter((step) => isObject(step) && hasValue(step.text))
      .map((step, index) => ({
        key: `route-${index}`,
        kind: text(step.kind),
        text: String(step.text)
      })),
    amberFloor: hasValue(source.open_case_amber_floor_date)
      ? formatLabel(
          labels.amberFloor,
          formatDate(source.open_case_amber_floor_date, locale)
        )
      : ""
  };
}

export function buildHistory(history, labels, locale) {
  return asArray(history)
    .filter(isObject)
    .map((group, groupIndex) => {
      const isOpenNow = group.period === OPEN_NOW_PERIOD;
      return {
        key: `period-${groupIndex}`,
        periodLabel: isOpenNow
          ? labels.openNow
          : formatDate(group.period, locale),
        events: asArray(group.events)
          .filter((event) => isObject(event) && hasValue(event.title))
          .map((event, eventIndex) => ({
            key: `event-${groupIndex}-${eventIndex}`,
            eventClass: isOpenNow
              ? "event event_open"
              : EVENT_CLASSES[event.type] || "event",
            title: String(event.title),
            chip: joinPresent([
              event.chip,
              formatMoney(event.amount, event.currencyIsoCode, locale)
            ]),
            chipClass: isOpenNow ? "chip chip_amber" : "chip chip_grey",
            date: formatDate(event.date, locale)
          }))
      };
    })
    .filter((group) => group.events.length);
}

function toSourceLink(entry, key) {
  const publisherUrl = String(entry.publisher_url || "");
  const redirectUrl = String(entry.url || "");
  /* Link to the real article when the service resolved it; the redirect stays as fallback. */
  const url = SAFE_URL_PATTERN.test(publisherUrl)
    ? publisherUrl
    : SAFE_URL_PATTERN.test(redirectUrl)
      ? redirectUrl
      : "";
  return url
    ? {
        key,
        url,
        label: String(
          entry.publisher_domain || entry.display_label || entry.title || url
        )
      }
    : null;
}

/*
 * A finding either carries its own sources or points into the shared sources list by
 * index; both shapes are accepted so the drawer keeps its links while the service moves
 * from one to the other.
 */
function findingSources(finding, id, indexToSource) {
  if (Array.isArray(finding.sources)) {
    return finding.sources
      .filter(isObject)
      .map((entry, index) =>
        toSourceLink(entry, `finding-${id}-source-${index}`)
      )
      .filter(Boolean);
  }
  return asArray(finding.source_indices)
    .filter((sourceIndex) => indexToSource.has(sourceIndex))
    .map((sourceIndex) =>
      toSourceLink(
        indexToSource.get(sourceIndex),
        `finding-${id}-source-${sourceIndex}`
      )
    )
    .filter(Boolean);
}

function buildFindings(findings, keyPrefix, labels, locale, indexToSource) {
  return asArray(findings)
    .filter((finding) => isObject(finding) && hasValue(finding.fact))
    .map((finding, index) => {
      const id = text(finding.id) || `${keyPrefix}${index + 1}`;
      return {
        key: `finding-${id}`,
        id,
        fact: String(finding.fact),
        kind: RESEARCH_KIND_LABELS[finding.kind]
          ? labels[RESEARCH_KIND_LABELS[finding.kind]]
          : "",
        meta: joinPresent([
          finding.person_name,
          finding.role,
          formatDate(finding.date, locale)
        ]),
        sources: findingSources(finding, id, indexToSource)
      };
    });
}

/* Cited findings back the summary's evidence chips; additional ones are context only. */
export function buildResearch(enrichment, labels, locale) {
  const source = asObject(enrichment);
  const indexToSource = new Map(
    asArray(source.sources)
      .filter(isObject)
      .map((entry) => [entry.index, entry])
  );
  const cited = buildFindings(
    source.findings,
    "C",
    labels,
    locale,
    indexToSource
  );
  const citedIds = new Set(cited.map((finding) => finding.id));
  const additional = buildFindings(
    source.supplemental_findings,
    "S",
    labels,
    locale,
    indexToSource
  ).filter((finding) => !citedIds.has(finding.id));
  return {
    findings: cited,
    additional,
    hasCited: cited.length > 0,
    hasAdditional: additional.length > 0,
    hasResearch: cited.length > 0 || additional.length > 0,
    summary: formatLabel(
      labels.researchSummary,
      cited.length,
      additional.length
    ),
    additionalHeading: formatLabel(
      labels.researchAdditionalHeading,
      additional.length
    )
  };
}

export function buildAccountViewModel(
  response,
  labels,
  locale,
  rowLimit = getListRowLimits().maxRows
) {
  const payload = asObject(response);
  const summary = asObject(payload.account_summary);
  const research = buildResearch(payload.account_enrichment, labels, locale);
  const findingById = new Map(
    [...research.findings, ...research.additional].map((finding) => [
      finding.id,
      finding
    ])
  );
  const signals = buildSignals(
    summary.risk_growth_signals,
    labels,
    findingById
  );
  const actions = buildActions(
    summary.recommended_actions,
    labels,
    findingById
  );
  return {
    asOfLabel: hasValue(payload.as_of_date)
      ? formatLabel(labels.asOf, formatDate(payload.as_of_date, locale))
      : "",
    header: buildHeader(summary.account_header, labels, locale),
    flag: buildFlag(summary.account_flag, labels, locale),
    tiles: buildTiles(summary.key_metrics, labels, locale),
    risks: signals.risks,
    growth: signals.growth,
    actions,
    hasCallInsights: [...signals.risks, ...signals.growth, ...actions].some(
      (item) => item.fromCall
    ),
    opportunities: buildOpportunities(
      summary.open_opportunities,
      labels,
      locale,
      rowLimit
    ),
    cases: buildCases(summary.cases, labels, locale, rowLimit),
    contacts: buildContacts(summary.key_contacts, labels),
    history: buildHistory(summary.account_history, labels, locale),
    research
  };
}
