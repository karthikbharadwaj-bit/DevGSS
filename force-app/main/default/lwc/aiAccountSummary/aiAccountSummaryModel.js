import { formatLabel } from "./aiAccountSummaryConfig";

const DIAL_RADIUS = 35;
const DIAL_CIRCUMFERENCE = 2 * Math.PI * DIAL_RADIUS;
const STRONG_BAR_RATIO = 0.8;
const WEAK_BAR_RATIO = 0.5;
const OPEN_NOW_PERIOD = "open_now";
const SAFE_URL_PATTERN = /^https?:\/\//i;
const ISO_DATE_PATTERN = /^(\d{4})-(\d{2})(?:-(\d{2}))?/;
/* The org mixes Critical/High, P0-P4 and "1 – Critical" schemes; all of these are top tier. */
const TOP_PRIORITY_PATTERN = /^(critical|p0|p1|1\s*[–-])/i;
const TILE_ORDER = [
  "mrr",
  "mrr_trajectory",
  "total_open_pipeline",
  "open_cases",
  "licenses"
];
const WHEN_CHIPS = {
  today: { labelKey: "whenToday", chipClass: "chip chip_red" },
  this_week: { labelKey: "whenThisWeek", chipClass: "chip chip_amber" },
  post_close: { labelKey: "whenPostClose", chipClass: "chip chip_grey" }
};
const LANE_LABELS = { sales: "laneSales", service: "laneService" };
const BAND_KEYS = { green: "green", amber: "amber", red: "red" };

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

function display(value, labels) {
  return hasValue(value)
    ? { value: String(value), isNil: false }
    : { value: labels.notRecorded, isNil: true };
}

function joinPresent(parts, separator = " · ") {
  return parts.filter(hasValue).join(separator);
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

// ---------------- Section builders ----------------

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
    const shown = display(value, labels);
    return {
      key,
      label,
      value: shown.value,
      valueClass: shown.isNil ? "nil" : isMono ? "mono" : ""
    };
  });
  return {
    rows,
    narrative: toHtmlLines(asObject(header).narrative, "narrative")
  };
}

function tileDetail(tile, labels, locale) {
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

function tileValue(tile, locale) {
  switch (tile.key) {
    case "mrr":
    case "total_open_pipeline":
      return formatMoney(tile.value, tile.currencyIsoCode, locale);
    case "mrr_trajectory":
      if (!isNumber(tile.value_pct)) {
        return "";
      }
      return `${tile.value_pct > 0 ? "+" : ""}${formatNumber(tile.value_pct, locale, 1)}%`;
    case "open_cases":
      return isNumber(tile.value) ? formatNumber(tile.value, locale) : "";
    case "licenses":
      return isNumber(tile.purchased) || isNumber(tile.in_use)
        ? `${isNumber(tile.purchased) ? formatNumber(tile.purchased, locale) : "–"} / ${
            isNumber(tile.in_use) ? formatNumber(tile.in_use, locale) : "–"
          }`
        : "";
    default:
      return "";
  }
}

function tileNumber(tile) {
  if (tile.key === "mrr_trajectory") {
    return tile.value_pct;
  }
  return tile.value;
}

const TILE_LABEL_KEYS = {
  mrr: "tileMrr",
  mrr_trajectory: "tileTrajectory",
  total_open_pipeline: "tilePipeline",
  open_cases: "tileCases",
  licenses: "tileLicenses"
};

export function buildTiles(keyMetrics, labels, locale) {
  const tilesByKey = new Map(
    asArray(asObject(keyMetrics).tiles)
      .filter(isObject)
      .map((tile) => [tile.key, tile])
  );
  return TILE_ORDER.map((key) => {
    const tile = { key, ...asObject(tilesByKey.get(key)) };
    let value = tileValue(tile, locale);
    let isNil = !hasValue(value);
    if (key === "total_open_pipeline" && tile.currency_mixed === true) {
      value = labels.tilePipelineMixed;
      isNil = false;
    }
    const number = tileNumber(tile);
    const isNegative =
      key !== "open_cases" &&
      key !== "licenses" &&
      isNumber(number) &&
      number < 0;
    return {
      key,
      label: labels[TILE_LABEL_KEYS[key]],
      value: isNil ? labels.notRecorded : value,
      detail: tileDetail(tile, labels, locale),
      tileClass: tile.flag === "amber" ? "tile tile_amber" : "tile",
      valueClass: isNil
        ? "tile-value tile-value_nil"
        : isNegative
          ? "tile-value tile-value_negative"
          : "tile-value"
    };
  });
}

function buildSignalItems(items, keyPrefix) {
  return asArray(items)
    .filter(isObject)
    .map((item, index) => ({
      key: `${keyPrefix}-${index}`,
      title: hasValue(item.title) ? String(item.title) : "",
      detail: hasValue(item.detail) ? String(item.detail) : "",
      source: hasValue(item.source) ? String(item.source) : ""
    }));
}

export function buildSignals(signals) {
  const source = asObject(signals);
  return {
    risks: buildSignalItems(source.risks, "risk"),
    growth: buildSignalItems(source.growth, "growth")
  };
}

export function buildActions(actions, labels) {
  const items = asArray(actions).filter(isObject);
  return items.map((action, index) => {
    const chip = WHEN_CHIPS[action.when] || {
      labelKey: null,
      chipClass: "chip chip_grey"
    };
    const isWide = items.length % 2 === 1 && index === items.length - 1;
    return {
      key: `action-${index}`,
      whenLabel: chip.labelKey
        ? labels[chip.labelKey]
        : String(action.when || ""),
      chipClass: chip.chipClass,
      laneLabel: LANE_LABELS[action.lane]
        ? labels[LANE_LABELS[action.lane]]
        : "",
      title: hasValue(action.title) ? String(action.title) : "",
      detail: hasValue(action.detail) ? String(action.detail) : "",
      source: hasValue(action.source) ? String(action.source) : "",
      cardClass: isWide ? "action action_wide" : "action"
    };
  });
}

export function buildOpportunities(section, labels, locale) {
  const source = asObject(section);
  const rows = asArray(source.rows)
    .filter(isObject)
    .map((row, index) => {
      const amount = formatMoney(row.amount, row.currencyIsoCode, locale);
      return {
        key: row.id || `opportunity-${index}`,
        url: recordUrl(row.id),
        name: hasValue(row.name) ? String(row.name) : labels.notRecorded,
        owner: hasValue(row.owner_name) ? String(row.owner_name) : "",
        stage: display(row.stage_name, labels).value,
        forecast: joinPresent([
          row.forecast_category,
          isNumber(row.probability)
            ? `${formatNumber(row.probability, locale)}%`
            : ""
        ]),
        amount: amount || labels.notRecorded,
        amountClass: !amount
          ? "num nil"
          : row.amount < 0
            ? "num negative"
            : "num",
        closeDate: formatDate(row.close_date, locale) || labels.notRecorded,
        overdueLabel: hasValue(row.overdue_label)
          ? String(row.overdue_label)
          : "",
        nextStepDisplay: hasValue(row.next_step)
          ? String(row.next_step)
          : hasValue(row.next_step_display)
            ? String(row.next_step_display)
            : labels.notRecorded,
        nextStepClass: hasValue(row.next_step) ? "" : "nil"
      };
    });
  return {
    rows,
    agreementText: hasValue(source.agreement_status_text)
      ? String(source.agreement_status_text)
      : ""
  };
}

function priorityChipClass(priority) {
  return isTopPriority(priority) ? "chip chip_red" : "chip chip_grey";
}

export function buildCases(section, labels, locale) {
  const source = asObject(section);
  const open = asArray(source.open)
    .filter(isObject)
    .map((row, index) => ({
      key: row.id || `open-case-${index}`,
      url: recordUrl(row.id),
      subject: hasValue(row.subject) ? String(row.subject) : labels.notRecorded,
      detail: joinPresent([
        row.case_number,
        row.status,
        joinPresent([row.reason, row.type], " / ")
      ]),
      priority: display(row.priority, labels).value,
      priorityClass: priorityChipClass(row.priority),
      owner: display(row.owner_name, labels).value,
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
      subject: hasValue(row.subject) ? String(row.subject) : labels.notRecorded,
      priority: display(row.priority, labels).value,
      closedMonth: formatDate(row.closed_month || row.closed_date, locale)
    }));
  const closedCount = isNumber(source.recently_closed_count)
    ? source.recently_closed_count
    : closed.length;
  return {
    open,
    closed,
    openHeading: formatLabel(labels.openCasesHeading, open.length),
    closedHeading: formatLabel(labels.closedCasesHeading, closedCount),
    detailNote: hasValue(source.case_detail_note)
      ? String(source.case_detail_note)
      : ""
  };
}

export function buildContacts(section, labels) {
  const source = asObject(section);
  const contacts = asArray(source.contacts)
    .filter(isObject)
    .map((row, index) => {
      const title = display(row.title, labels);
      const role = display(row.customer_contact_role, labels);
      return {
        key: row.id || `contact-${index}`,
        url: recordUrl(row.id),
        name: hasValue(row.name) ? String(row.name) : labels.notRecorded,
        title: title.value,
        titleClass: title.isNil ? "contact-title nil" : "contact-title",
        role: role.value,
        roleClass: role.isNil ? "nil" : "chip chip_blue",
        lastActivity: isNumber(row.days_since_activity)
          ? formatLabel(labels.daysAgo, row.days_since_activity)
          : labels.notRecorded,
        lastActivityClass: isNumber(row.days_since_activity) ? "" : "nil"
      };
    });
  const team = asArray(source.account_team)
    .filter(isObject)
    .map((member, index) => ({
      key: `team-${index}`,
      name: display(member.user_name, labels).value,
      role: display(member.team_member_role, labels).value
    }));
  return {
    contacts,
    team,
    roleNote: hasValue(source.role_note) ? String(source.role_note) : ""
  };
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
        label: hasValue(component.label) ? String(component.label) : "",
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
    scoreLabel: hasValue(source.score_label) ? String(source.score_label) : "",
    band: hasValue(source.band) ? String(source.band) : "",
    bandChipClass: `chip chip_${bandKey}`,
    dialClass: `dial-value dial-value_${bandKey}`,
    dialDash: `${score === null ? 0 : ((score / 100) * DIAL_CIRCUMFERENCE).toFixed(1)} ${DIAL_CIRCUMFERENCE.toFixed(1)}`,
    hasOverride,
    overrideClass: `override override_${bandKey}`,
    overrideTitle: hasOverride
      ? formatLabel(labels.overrideCallout, String(source.band || ""))
      : "",
    overrideExplanation: hasValue(source.override_explanation)
      ? String(source.override_explanation)
      : hasOverride
        ? String(source.override_reason)
        : "",
    bars,
    routing: asArray(source.routing)
      .filter(isObject)
      .map((step, index) => ({
        key: `route-${index}`,
        kind: hasValue(step.kind) ? String(step.kind) : "",
        text: hasValue(step.text) ? String(step.text) : ""
      })),
    amberFloor: hasValue(source.open_case_amber_floor_date)
      ? formatLabel(
          labels.amberFloor,
          formatDate(source.open_case_amber_floor_date, locale)
        )
      : ""
  };
}

const EVENT_CLASSES = {
  opportunity: "event event_opportunity",
  case: "event event_case",
  entitlement: "event event_entitlement",
  escalation: "event event_escalation",
  activation: "event event_activation"
};

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
          .filter(isObject)
          .map((event, eventIndex) => ({
            key: `event-${groupIndex}-${eventIndex}`,
            eventClass: isOpenNow
              ? "event event_open"
              : EVENT_CLASSES[event.type] || "event",
            title: hasValue(event.title) ? String(event.title) : "",
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

export function buildResearch(enrichment, locale) {
  const source = asObject(enrichment);
  const findings = asArray(source.findings)
    .filter((finding) => isObject(finding) && hasValue(finding.fact))
    .map((finding, index) => ({
      key: finding.id || `finding-${index}`,
      id: hasValue(finding.id) ? String(finding.id) : "",
      fact: String(finding.fact),
      meta: joinPresent([
        finding.person_name,
        finding.role,
        formatDate(finding.date, locale)
      ])
    }));
  const sources = asArray(source.sources)
    .filter(
      (entry) =>
        isObject(entry) && SAFE_URL_PATTERN.test(String(entry.url || ""))
    )
    .map((entry, index) => ({
      key: `source-${entry.index ?? index}`,
      url: String(entry.url),
      label: String(entry.display_label || entry.title || entry.url)
    }));
  return { findings, sources, hasResearch: findings.length > 0 };
}

export function buildAccountViewModel(response, labels, locale) {
  const summary = asObject(asObject(response).account_summary);
  const header = buildHeader(summary.account_header, labels, locale);
  const signals = buildSignals(summary.risk_growth_signals);
  const research = buildResearch(asObject(response).account_enrichment, locale);
  return {
    asOfLabel: hasValue(asObject(response).as_of_date)
      ? formatLabel(labels.asOf, formatDate(response.as_of_date, locale))
      : "",
    header,
    flag: buildFlag(summary.account_flag, labels, locale),
    tiles: buildTiles(summary.key_metrics, labels, locale),
    risks: signals.risks,
    growth: signals.growth,
    actions: buildActions(summary.recommended_actions, labels),
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
