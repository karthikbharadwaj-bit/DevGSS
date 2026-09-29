import { formatLabel } from "./aiAccountSummaryConfig";

const DIAL_RADIUS = 35;
const DIAL_CIRCUMFERENCE = 2 * Math.PI * DIAL_RADIUS;
const STRONG_BAR_RATIO = 0.8;
const WEAK_BAR_RATIO = 0.5;
const TILE_COUNT = 5;
const RENEWAL_WARNING_DAYS = 30;
const OPEN_NOW_PERIOD = "open_now";
const SAFE_URL_PATTERN = /^https?:\/\//i;
const ISO_DATE_PATTERN = /^(\d{4})-(\d{2})(?:-(\d{2}))?/;
const EVIDENCE_REFERENCE_PATTERN = /\s*\[(E\d+)\]/g;
/* The service writes this phrase for every null; those items carry no Salesforce signal. */
const NOT_RECORDED_PATTERN = /not recorded in salesforce/i;
/* The org mixes Critical/High, P0-P4 and "1 – Critical" schemes; all of these are top tier. */
const TOP_PRIORITY_PATTERN = /^(critical|p0|p1|1\s*[–-])/i;
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
  const detail = extractEvidence(item.detail, findingById);
  const source = extractEvidence(item.source, findingById);
  const ids = [
    ...detail.ids,
    ...source.ids.filter((id) => !detail.ids.includes(id))
  ];
  return {
    detail: detail.text,
    source: source.text,
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
  ]
    .filter(([, , value]) => hasValue(value) && !isNotRecorded(value))
    .map(([key, label, value, isMono]) => ({
      key,
      label,
      value: String(value),
      valueClass: isMono ? "mono" : ""
    }));
  return {
    rows,
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
        isNumber(tile.escalated_count) && tile.escalated_count > 0
          ? formatLabel(labels.tileCasesEscalated, tile.escalated_count)
          : ""
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

function primaryTileNumber(tile) {
  return tile.key === "mrr_trajectory" ? tile.value_pct : tile.value;
}

function makeTile(key, label, value, detail, { isAmber, isNegative } = {}) {
  return {
    key,
    label,
    value,
    detail,
    tileClass: isAmber ? "tile tile_amber" : "tile",
    valueClass: isNegative ? "tile-value tile-value_negative" : "tile-value"
  };
}

/*
 * Replacement tiles, in priority order, for any service tile that has no value. Each one is
 * only offered when the service computed it from records that exist on this account, so a
 * zero shown here is a real zero rather than an empty source.
 */
function replacementTiles(metrics, labels, locale) {
  const count = (value) => formatNumber(value, locale);
  const candidates = [
    () =>
      isNumber(metrics.days_to_renewal) &&
      makeTile(
        "days_to_renewal",
        labels.tileRenewal,
        count(metrics.days_to_renewal),
        metrics.days_to_renewal < 0 ? labels.tileRenewalPast : "",
        {
          isAmber: metrics.days_to_renewal <= RENEWAL_WARNING_DAYS,
          isNegative: metrics.days_to_renewal < 0
        }
      ),
    () =>
      isNumber(metrics.days_since_meaningful_activity) &&
      makeTile(
        "days_since_meaningful_activity",
        labels.tileActivity,
        count(metrics.days_since_meaningful_activity),
        metrics.going_cold === true ? labels.tileGoingCold : "",
        { isAmber: metrics.going_cold === true }
      ),
    () =>
      isNumber(metrics.closed_won_total) &&
      metrics.closed_opportunity_sample_size > 0 &&
      makeTile(
        "closed_won_total",
        labels.tileClosedWon,
        formatMoney(
          metrics.closed_won_total,
          metrics.closed_won_currency_iso_code,
          locale
        ),
        formatLabel(
          labels.tileClosedWonDetail,
          count(metrics.closed_won_count),
          count(metrics.closed_opportunity_sample_size)
        )
      ),
    () =>
      isNumber(metrics.active_revenue_at_risk) &&
      makeTile(
        "active_revenue_at_risk",
        labels.tileRevenueAtRisk,
        formatMoney(
          metrics.active_revenue_at_risk,
          metrics.active_revenue_at_risk_currency_iso_code,
          locale
        ),
        isNumber(metrics.open_escalation_count)
          ? formatLabel(
              labels.tileOpenEscalations,
              count(metrics.open_escalation_count)
            )
          : "",
        { isAmber: metrics.active_revenue_at_risk > 0 }
      ),
    () =>
      isNumber(metrics.lifetime_escalation_count) &&
      makeTile(
        "lifetime_escalation_count",
        labels.tileEscalations,
        count(metrics.lifetime_escalation_count),
        isNumber(metrics.cumulative_red_days) && metrics.cumulative_red_days > 0
          ? formatLabel(labels.tileRedDays, count(metrics.cumulative_red_days))
          : ""
      ),
    () =>
      isNumber(metrics.next_step_missing_count) &&
      metrics.open_opp_count > 0 &&
      makeTile(
        "next_step_coverage",
        labels.tileNextStep,
        `${count(metrics.open_opp_count - metrics.next_step_missing_count)} / ${count(metrics.open_opp_count)}`,
        ""
      ),
    () =>
      isNumber(metrics.overdue_open_opp_count) &&
      metrics.open_opp_count > 0 &&
      makeTile(
        "overdue_open_opp_count",
        labels.tileOverdue,
        count(metrics.overdue_open_opp_count),
        metrics.max_opp_days_overdue > 0
          ? formatLabel(
              labels.tileOverdueDetail,
              count(metrics.max_opp_days_overdue)
            )
          : "",
        { isAmber: metrics.overdue_open_opp_count > 0 }
      ),
    () =>
      isNumber(metrics.recently_closed_case_count) &&
      makeTile(
        "recently_closed_case_count",
        labels.tileClosedCases,
        count(metrics.recently_closed_case_count),
        ""
      ),
    () =>
      isNumber(metrics.open_dunning_retention_task_count) &&
      makeTile(
        "open_dunning_retention_task_count",
        labels.tileDunning,
        count(metrics.open_dunning_retention_task_count),
        "",
        { isAmber: metrics.open_dunning_retention_task_count > 0 }
      )
  ];
  return candidates.map((candidate) => candidate()).filter(Boolean);
}

export function buildTiles(keyMetrics, derivedMetrics, labels, locale) {
  const keyToTile = new Map(
    asArray(asObject(keyMetrics).tiles)
      .filter(isObject)
      .map((tile) => [tile.key, tile])
  );
  const tiles = PRIMARY_TILE_ORDER.map((key) => {
    const tile = { key, ...asObject(keyToTile.get(key)) };
    const value = primaryTileValue(tile, labels, locale);
    if (!hasValue(value)) {
      return null;
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
  }).filter(Boolean);

  const replacements = replacementTiles(
    asObject(derivedMetrics),
    labels,
    locale
  );
  while (tiles.length < TILE_COUNT && replacements.length) {
    tiles.push(replacements.shift());
  }
  return tiles;
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
        ...withEvidence(action, findingById, key, labels)
      };
    });
}

export function buildOpportunities(section, labels, locale) {
  const source = asObject(section);
  const rows = asArray(source.rows)
    .filter(isObject)
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
  return { rows, agreementText: text(source.agreement_status_text) };
}

export function buildCases(section, labels, locale) {
  const source = asObject(section);
  const open = asArray(source.open)
    .filter(isObject)
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
  const closed = asArray(source.recently_closed)
    .filter(isObject)
    .map((row, index) => ({
      key: row.id || `closed-case-${index}`,
      url: recordUrl(row.id),
      subject: text(row.subject) || text(row.case_number),
      priority: text(row.priority),
      closedMonth: formatDate(row.closed_month || row.closed_date, locale)
    }));
  const closedCount = isNumber(source.recently_closed_count)
    ? source.recently_closed_count
    : closed.length;
  return {
    open,
    closed,
    openHeading: formatLabel(labels.openCasesHeading, open.length),
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

/* Each finding carries its own source links so an evidence chip lands on everything it needs. */
export function buildResearch(enrichment, labels, locale) {
  const source = asObject(enrichment);
  const indexToSource = new Map(
    asArray(source.sources)
      .filter(
        (entry) =>
          isObject(entry) && SAFE_URL_PATTERN.test(String(entry.url || ""))
      )
      .map((entry) => [
        entry.index,
        {
          url: String(entry.url),
          label: String(entry.display_label || entry.title || entry.url)
        }
      ])
  );
  const findings = asArray(source.findings)
    .filter((finding) => isObject(finding) && hasValue(finding.fact))
    .map((finding, index) => {
      const id = text(finding.id) || `F${index + 1}`;
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
        sources: asArray(finding.source_indices)
          .filter((sourceIndex) => indexToSource.has(sourceIndex))
          .map((sourceIndex) => ({
            key: `finding-${id}-source-${sourceIndex}`,
            ...indexToSource.get(sourceIndex)
          }))
      };
    });
  return {
    findings,
    hasResearch: findings.length > 0,
    summary: formatLabel(labels.researchSummary, findings.length)
  };
}

export function buildAccountViewModel(response, labels, locale) {
  const payload = asObject(response);
  const summary = asObject(payload.account_summary);
  const research = buildResearch(payload.account_enrichment, labels, locale);
  const findingById = new Map(
    research.findings.map((finding) => [finding.id, finding])
  );
  const signals = buildSignals(
    summary.risk_growth_signals,
    labels,
    findingById
  );
  return {
    asOfLabel: hasValue(payload.as_of_date)
      ? formatLabel(labels.asOf, formatDate(payload.as_of_date, locale))
      : "",
    header: buildHeader(summary.account_header, labels, locale),
    flag: buildFlag(summary.account_flag, labels, locale),
    tiles: buildTiles(
      summary.key_metrics,
      payload.derived_metrics,
      labels,
      locale
    ),
    risks: signals.risks,
    growth: signals.growth,
    actions: buildActions(summary.recommended_actions, labels, findingById),
    opportunities: buildOpportunities(
      summary.open_opportunities,
      labels,
      locale
    ),
    cases: buildCases(summary.cases, labels, locale),
    contacts: buildContacts(summary.key_contacts, labels),
    history: buildHistory(summary.account_history, labels, locale),
    research
  };
}
