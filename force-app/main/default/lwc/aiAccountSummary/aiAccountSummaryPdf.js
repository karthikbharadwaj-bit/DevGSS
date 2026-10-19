import {
  HEADING_PART,
  keepHeadingWithContent,
  pdfText as sharedPdfText,
  plainText,
  safeLink
} from "c/lwcPdfBlocks";
import { formatLabel } from "./aiAccountSummaryConfig";

// Design tokens: one accent, neutrals, and semantic tints for growth, risk and red flags.
const INK = "#16325c";
const TEXT = "#2b3a4f";
const BLUE = "#0176d3";
const MUTED = "#5c6f88";
const RULE = "#d8dee6";
const PANEL = "#f4f7fb";
const WIN = "#2e844a";
const RISK = "#a35200";
const ALERT = "#ba0517";
const PAGE_X = 48;
const CONTENT_WIDTH = 499; // A4 width (595) minus margins (48 * 2)
const TILES_PER_ROW = 3;
const HEADER_FIELDS_PER_ROW = 3;
const EVIDENCE_ID = /^E\d+$/;
const HISTORY_EVENT_LIMIT = 20;
// Stage names such as "5. Agreement" read as a sentence end when a line wraps after the number.
const NUMBERED_STAGE = /(^|[^\d.])(\d{1,2}\.) (?=[A-Z])/g;
const BAND_COLORS = { green: WIN, amber: RISK, red: ALERT };
const BAND_TINTS = { green: "#ebf7e6", amber: "#fef1e6", red: "#feded8" };
const FLAG_PADDING = 14;
const BAR_LABEL_WIDTH = 150;
const BAR_POINTS_WIDTH = 40;
const BAR_TRACK_WIDTH = 220;
const BAR_FILL_COLORS = {
  "bar-fill": WIN,
  "bar-fill bar-fill_warn": RISK,
  "bar-fill bar-fill_bad": ALERT
};

function timestamp(value) {
  const date = new Date(value);
  return value !== null &&
    value !== undefined &&
    Number.isFinite(date.getTime())
    ? date
        .toISOString()
        .replace("T", " ")
        .replace(/\.\d{3}Z$/, " UTC")
    : "—";
}

const keepStageNumbers = (text) => text.replace(NUMBERED_STAGE, "$1$2\u00a0");

export function pdfText(value, evidenceIds = new Set()) {
  return sharedPdfText(value, evidenceIds, keepStageNumbers);
}

const plain = (value) => plainText(value, keepStageNumbers);

export function pdfFilename(recordName, recordId, exportedAt) {
  const name =
    plain(recordName || recordId || "Account")
      .normalize("NFKC")
      // eslint-disable-next-line no-control-regex
      .replace(/[<>:"/\\|?*\u0000-\u001f\u007f]/g, "-")
      .replace(/[\u202a-\u202e\u2066-\u2069]/g, "")
      .replace(/\s+/g, " ")
      .replace(/[. ]+$/g, "")
      .slice(0, 90) || "Account";
  return `Account Summary - ${name} - ${timestamp(exportedAt).slice(0, 10)}.pdf`;
}

function eyebrow(text, color = MUTED, margin = [0, 0, 0, 4]) {
  return {
    text: plain(text).toUpperCase(),
    fontSize: 7.5,
    bold: true,
    color,
    characterSpacing: 1.2,
    margin
  };
}

// Thin rules between table rows only, never above the first or below the last.
function rowRuleWidth(index, node) {
  return index === 0 || index === node.table.body.length ? 0 : 0.5;
}

function cellPaddingRight(index, node) {
  return index === node.table.widths.length - 1 ? 0 : 8;
}

function barRatio(bar) {
  const match = /width:\s*(\d+)%/.exec(bar.fillStyle || "");
  return match ? Number(match[1]) / 100 : 0;
}

// One component score per row, laid out like the modal: label, track, points.
function scoreBarRow(bar) {
  const fill = BAR_TRACK_WIDTH * barRatio(bar);
  const isWeak = String(bar.barClass || "").includes("bar_weak");
  return [
    { text: plain(bar.label), color: isWeak ? ALERT : TEXT },
    {
      canvas: [
        {
          type: "rect",
          x: 0,
          y: 0,
          w: BAR_TRACK_WIDTH,
          h: 6,
          r: 3,
          color: RULE
        },
        ...(fill > 0
          ? [
              {
                type: "rect",
                x: 0,
                y: 0,
                w: fill,
                h: 6,
                r: 3,
                color: BAR_FILL_COLORS[bar.fillClass] || BLUE
              }
            ]
          : [])
      ],
      margin: [0, 5, 0, 0]
    },
    {
      text: plain(bar.points),
      bold: true,
      color: isWeak ? ALERT : INK,
      alignment: "right"
    },
    { text: "" }
  ];
}

function bandChip(band, color) {
  return {
    table: {
      body: [
        [
          {
            text: plain(band).toUpperCase(),
            fontSize: 7.5,
            bold: true,
            characterSpacing: 1,
            color: "#ffffff",
            fillColor: color
          }
        ]
      ]
    },
    layout: {
      defaultBorder: false,
      paddingLeft: () => 7,
      paddingRight: () => 7,
      paddingTop: () => 2,
      paddingBottom: () => 1
    }
  };
}

function chunk(items, size) {
  const rows = [];
  for (let index = 0; index < items.length; index += size) {
    rows.push(items.slice(index, index + size));
  }
  return rows;
}

// Borderless shaded grid used for the header fields and metric tiles.
function panelGrid(cells, perRow, margin = [0, 0, 0, 12]) {
  return {
    table: {
      widths: Array(perRow).fill("*"),
      dontBreakRows: true,
      body: chunk(cells, perRow).map((row) => [
        ...row,
        ...Array(perRow - row.length).fill({ text: "" })
      ])
    },
    layout: {
      defaultBorder: false,
      fillColor: () => PANEL,
      paddingLeft: () => 14,
      paddingRight: () => 14,
      paddingTop: () => 10,
      paddingBottom: () => 10
    },
    margin
  };
}

export function buildPdfDocument(snapshot, labels) {
  const view = snapshot.view;
  const research = view.research || {};
  const findings = [
    ...(research.findings || []),
    ...(research.additional || [])
  ];
  const evidenceIds = new Set(
    findings.map((finding) => finding.id).filter((id) => EVIDENCE_ID.test(id))
  );
  const anchoredIds = new Set();
  const recordTitle = plain(snapshot.recordName || snapshot.recordId);
  const content = [];

  const recordLink = (url) => (url ? safeLink(url, snapshot.origin) : null);

  const heading = (title, color = INK) => ({
    stack: [
      {
        text: plain(title),
        fontSize: 13.5,
        bold: true,
        color,
        headlineLevel: HEADING_PART
      },
      {
        headlineLevel: HEADING_PART,
        canvas: [
          {
            type: "line",
            x1: 0,
            y1: 0,
            x2: CONTENT_WIDTH,
            y2: 0,
            lineWidth: 1,
            lineColor: RULE
          }
        ],
        margin: [0, 6, 0, 0]
      }
    ],
    margin: [0, 24, 0, 12],
    headlineLevel: 1
  });

  const subheading = (text, color = MUTED, margin = [0, 8, 0, 6]) => ({
    ...eyebrow(text, color, margin),
    headlineLevel: 1
  });

  const note = (text, margin = [0, 0, 0, 10]) => ({
    text: pdfText(text),
    style: "meta",
    margin
  });

  const evidenceRuns = (evidence) =>
    (evidence || [])
      .filter((item) => evidenceIds.has(item.id))
      .flatMap((item) => [
        " ",
        {
          text: `[${item.id}]`,
          linkToDestination: `research-${item.id}`,
          color: BLUE,
          bold: true
        }
      ]);

  const linked = (text, url) => {
    const link = recordLink(url);
    return link
      ? { text: plain(text), link, color: BLUE }
      : { text: plain(text) };
  };

  const dataTable = (headers, rows, widths, rightAligned = []) => ({
    table: {
      headerRows: headers ? 1 : 0,
      widths,
      dontBreakRows: true,
      body: [
        ...(headers
          ? [
              headers.map((header, index) => ({
                ...eyebrow(header, MUTED, [0, 0, 0, 0]),
                ...(rightAligned.includes(index) ? { alignment: "right" } : {})
              }))
            ]
          : []),
        ...rows
      ]
    },
    layout: {
      hLineWidth: rowRuleWidth,
      vLineWidth: () => 0,
      hLineColor: () => RULE,
      paddingLeft: (index) => (index === 0 ? 0 : 8),
      paddingRight: cellPaddingRight,
      paddingTop: () => 6,
      paddingBottom: () => 6
    },
    fontSize: 9.5,
    margin: [0, 0, 0, 8]
  });

  // A record name with its secondary details on one muted line beneath it.
  const cellWithSub = (main, subs) => {
    const sub = subs.filter(Boolean).map(plain).join("  ·  ");
    return sub
      ? { stack: [main, { text: sub, style: "meta", margin: [0, 2, 0, 0] }] }
      : main;
  };

  const showing = (shown, total) => {
    if (total <= shown) return [];
    return [note(formatLabel(labels.pdfShowing, shown, total))];
  };

  const sourceRuns = (sources) => {
    const seen = new Set();
    return (sources || []).flatMap((source) => {
      const link = safeLink(source.url);
      if (!link || seen.has(link)) return [];
      seen.add(link);
      const label = plain(source.label);
      const text =
        label && !/https?:\/\//i.test(label) ? label : labels.pdfSourceLink;
      return [{ text, link, color: BLUE }];
    });
  };

  // "Title — detail [E1]" as one paragraph per item.
  const titledLine = (title, detail, evidence) => [
    { text: plain(title), bold: true, color: INK },
    ...(detail ? [" — ", ...pdfText(detail, evidenceIds)] : []),
    ...evidenceRuns(evidence)
  ];

  // The label is a subheading, so it moves with its items when it lands at a page bottom.
  const signalRow = (title, items, color, emptyText) => [
    subheading(title, color, [0, 4, 0, 8]),
    items?.length
      ? {
          ul: items.map((item) => ({
            text: titledLine(item.title, item.detail, item.evidence),
            margin: [0, 0, 0, 8]
          })),
          type: "square",
          markerColor: color,
          margin: [6, 0, 0, 8]
        }
      : note(emptyText)
  ];

  // Only cited findings carry an E tag; additional ones are never referenced.
  const finding = (item) => {
    const isCited = EVIDENCE_ID.test(item.id);
    const canAnchor = isCited && !anchoredIds.has(item.id);
    if (canAnchor) anchoredIds.add(item.id);
    const meta = [item.kind, item.meta].filter(Boolean).map(plain);
    const links = sourceRuns(item.sources);
    return {
      columns: [
        ...(isCited
          ? [
              {
                width: 22,
                text: plain(item.id),
                bold: true,
                color: BLUE,
                ...(canAnchor ? { id: `research-${item.id}` } : {})
              }
            ]
          : []),
        {
          width: "*",
          text: [
            ...pdfText(item.fact).map((run) => ({ ...run, color: INK })),
            ...(meta.length || links.length
              ? [
                  {
                    text: `   ${meta.join("  ·  ")}${meta.length && links.length ? "  ·  " : ""}`,
                    style: "meta"
                  },
                  ...links.flatMap((run, i) => [
                    ...(i ? [{ text: ", ", style: "meta" }] : []),
                    { ...run, fontSize: 8.5 }
                  ])
                ]
              : [])
          ]
        }
      ],
      columnGap: 6,
      margin: [0, 0, 0, 10],
      unbreakable: true
    };
  };

  // Title block, then the snapshot facts in a shaded band beneath it.
  content.push(eyebrow(labels.pdfTitle, BLUE, [0, 0, 0, 8]));
  content.push({
    text: recordTitle,
    fontSize: 24,
    bold: true,
    color: INK,
    lineHeight: 1.15,
    margin: [0, 0, 0, 6]
  });
  const accountLink = safeLink(snapshot.recordUrl);
  if (accountLink) {
    content.push({
      text: labels.pdfRecord,
      link: accountLink,
      color: BLUE,
      fontSize: 9.5,
      margin: [0, 0, 0, 18]
    });
  }
  const facts = [
    ...(snapshot.asOfDate
      ? [[labels.pdfDataAsOf, plain(snapshot.asOfDate)]]
      : []),
    [labels.pdfSnapshot, timestamp(snapshot.generatedAt)],
    [labels.pdfExported, timestamp(snapshot.exportedAt)]
  ];
  content.push(
    panelGrid(
      facts.map(([label, value]) => ({
        stack: [eyebrow(label), { text: value, color: INK, bold: true }]
      })),
      facts.length,
      [0, 0, 0, 16]
    )
  );

  // Account flag, row by row as in the modal: title and band, override, score, components, routing.
  const flag = view.flag || {};
  const bandKey = String(flag.band || "").toLowerCase();
  const bandColor = BAND_COLORS[bandKey] || BLUE;
  const flagStack = [
    {
      columns: [
        { ...eyebrow(labels.sectionFlag, INK, [0, 2, 0, 0]), width: "auto" },
        ...(flag.band
          ? [{ width: "auto", stack: [bandChip(flag.band, bandColor)] }]
          : [])
      ],
      columnGap: 8
    }
  ];
  if (flag.hasOverride) {
    flagStack.push({
      table: {
        widths: ["*"],
        body: [
          [
            {
              stack: [
                {
                  text: plain(flag.overrideTitle),
                  bold: true,
                  color: bandColor
                },
                {
                  text: pdfText(flag.overrideExplanation, evidenceIds),
                  color: TEXT
                }
              ],
              fillColor: BAND_TINTS[bandKey] || "#ffffff"
            }
          ]
        ]
      },
      layout: {
        hLineWidth: () => 0,
        vLineWidth: (index) => (index === 0 ? 3 : 0),
        vLineColor: () => bandColor,
        paddingLeft: () => 12,
        paddingRight: () => 12,
        paddingTop: () => 8,
        paddingBottom: () => 8
      },
      margin: [0, 12, 0, 0]
    });
  }
  if (flag.hasScore || flag.scoreLabel || flag.amberFloor) {
    flagStack.push({
      columns: [
        ...(flag.hasScore
          ? [
              {
                width: "auto",
                text: [
                  {
                    text: plain(flag.score),
                    fontSize: 24,
                    bold: true,
                    color: bandColor
                  },
                  { text: ` ${plain(labels.scoreOf)}`, color: MUTED }
                ]
              }
            ]
          : []),
        {
          width: "*",
          stack: [
            ...(flag.scoreLabel
              ? [{ text: plain(flag.scoreLabel), bold: true, color: INK }]
              : []),
            ...(flag.amberFloor
              ? [{ text: plain(flag.amberFloor), style: "meta" }]
              : [])
          ],
          margin: [0, 3, 0, 0]
        }
      ],
      columnGap: 16,
      margin: [0, 12, 0, 0]
    });
  }
  if (flag.bars?.length) {
    flagStack.push({
      table: {
        widths: [BAR_LABEL_WIDTH, BAR_TRACK_WIDTH, BAR_POINTS_WIDTH, "*"],
        dontBreakRows: true,
        body: flag.bars.map(scoreBarRow)
      },
      layout: {
        defaultBorder: false,
        paddingLeft: (index) => (index === 0 ? 0 : 10),
        paddingRight: () => 0,
        paddingTop: () => 3,
        paddingBottom: () => 3
      },
      margin: [0, 10, 0, 0]
    });
  }
  if (flag.routing?.length) {
    flagStack.push(eyebrow(labels.routingHeading, MUTED, [0, 14, 0, 6]));
    flagStack.push({
      // The step text already says what to do, so the routing kind is not repeated as a tag.
      ol: flag.routing.map((step) => ({
        text: pdfText(step.text, evidenceIds),
        margin: [0, 0, 0, 6]
      })),
      margin: [6, 0, 0, 0]
    });
  }
  if (flagStack.length > 1) {
    content.push({
      table: { widths: ["*"], body: [[{ stack: flagStack }]] },
      layout: {
        defaultBorder: false,
        fillColor: () => PANEL,
        paddingLeft: () => FLAG_PADDING,
        paddingRight: () => FLAG_PADDING,
        paddingTop: () => 12,
        paddingBottom: () => 12
      }
    });
  }

  const header = view.header || {};
  if (header.rows?.length || header.narrative?.length) {
    content.push(heading(labels.sectionHeader));
    if (header.rows?.length) {
      content.push(
        panelGrid(
          header.rows.map((row) => ({
            stack: [
              eyebrow(row.label),
              { text: plain(row.value), color: INK, bold: true }
            ]
          })),
          HEADER_FIELDS_PER_ROW
        )
      );
    }
    if (header.narrative?.length) {
      content.push({
        ul: header.narrative.map((line) => ({
          text: pdfText(line.html, evidenceIds),
          margin: [0, 0, 0, 8]
        })),
        type: "square",
        markerColor: BLUE,
        margin: [6, 2, 0, 6]
      });
    }
  }

  if (view.tiles?.length) {
    content.push(heading(labels.sectionMetrics));
    content.push(
      panelGrid(
        view.tiles.map((tile) => ({
          stack: [
            eyebrow(tile.label),
            {
              text: plain(tile.value),
              color: INK,
              fontSize: 15,
              bold: true
            },
            ...(tile.detail
              ? [
                  {
                    text: plain(tile.detail),
                    style: "meta",
                    margin: [0, 2, 0, 0]
                  }
                ]
              : [])
          ]
        })),
        TILES_PER_ROW
      )
    );
  }

  content.push(heading(labels.sectionSignals));
  content.push(...signalRow(labels.risks, view.risks, RISK, labels.noRisks));
  content.push(...signalRow(labels.growth, view.growth, WIN, labels.noGrowth));

  if (view.actions?.length) {
    content.push(heading(labels.sectionActions));
    content.push({
      ol: view.actions.map((action) => {
        const tags = [action.whenLabel, action.laneLabel]
          .filter(Boolean)
          .map((tag) => plain(tag).toUpperCase())
          .join(" · ");
        return {
          text: [
            ...(tags
              ? [
                  {
                    text: `${tags}   `,
                    fontSize: 7.5,
                    bold: true,
                    color: BLUE
                  }
                ]
              : []),
            ...titledLine(action.title, action.detail, action.evidence)
          ],
          margin: [0, 0, 0, 8]
        };
      }),
      markerColor: BLUE,
      margin: [6, 0, 0, 6]
    });
  }

  const opportunities = view.opportunities || { rows: [] };
  content.push(heading(labels.sectionOpportunities));
  if (opportunities.rows.length) {
    content.push(
      dataTable(
        [
          labels.colName,
          labels.colStage,
          labels.colAmount,
          labels.colCloseDate
        ],
        opportunities.rows.map((row) => [
          cellWithSub(linked(row.name, row.url), [row.owner, row.nextStep]),
          cellWithSub({ text: plain(row.stage) }, [row.forecast]),
          { text: plain(row.amount), alignment: "right", noWrap: true },
          cellWithSub({ text: plain(row.closeDate), noWrap: true }, [
            row.overdueLabel
          ])
        ]),
        ["*", "auto", "auto", "auto"],
        [2]
      ),
      ...showing(opportunities.rows.length, opportunities.totalCount)
    );
  } else {
    content.push(note(labels.noOpenOpportunities));
  }
  if (opportunities.agreementText) {
    content.push({
      text: [
        { text: `${plain(labels.agreementHeading)}: `, bold: true, color: INK },
        ...pdfText(opportunities.agreementText)
      ],
      margin: [0, 2, 0, 8]
    });
  }

  const cases = view.cases || { open: [], closed: [] };
  content.push(heading(labels.sectionCases));
  content.push(subheading(cases.openHeading, MUTED, [0, 0, 0, 6]));
  if (cases.open.length) {
    content.push(
      dataTable(
        [labels.colSubject, labels.colPriority, labels.colOwner, labels.colAge],
        cases.open.map((row) => [
          cellWithSub(linked(row.subject, row.url), [row.detail]),
          cellWithSub({ text: plain(row.priority) }, [
            row.isEscalated ? labels.escalatedChip : ""
          ]),
          { text: plain(row.owner) },
          { text: plain(row.age), alignment: "right", noWrap: true }
        ]),
        ["*", "auto", "auto", "auto"],
        [3]
      ),
      ...showing(cases.open.length, cases.openTotal)
    );
  } else {
    content.push(note(labels.noOpenCases));
  }
  content.push(subheading(cases.closedHeading));
  if (cases.closed.length) {
    content.push(
      dataTable(
        [labels.colSubject, labels.colPriority, labels.colClosed],
        cases.closed.map((row) => [
          linked(row.subject, row.url),
          { text: plain(row.priority) },
          { text: plain(row.closedMonth), alignment: "right", noWrap: true }
        ]),
        ["*", "auto", "auto"],
        [2]
      ),
      ...showing(cases.closed.length, cases.closedTotal)
    );
  } else {
    content.push(note(labels.noClosedCases));
  }

  const contacts = view.contacts || { contacts: [], team: [] };
  content.push(heading(labels.sectionContacts));
  const contactStack = [];
  if (contacts.contacts.length) {
    contactStack.push(
      dataTable(
        [labels.colContact, labels.colRole, labels.colLastActivity],
        contacts.contacts.map((row) => [
          cellWithSub(linked(row.name, row.url), [row.title]),
          { text: plain(row.role) },
          { text: plain(row.lastActivity), alignment: "right", noWrap: true }
        ]),
        ["*", "auto", "auto"],
        [2]
      )
    );
  } else {
    contactStack.push(note(labels.noContacts));
  }
  if (contacts.team.length) {
    contactStack.push({
      text: [
        {
          text: `${plain(labels.accountTeamHeading)}: `,
          bold: true,
          color: INK
        },
        ...contacts.team.flatMap((member, i) => [
          ...(i ? ["  ·  "] : []),
          plain(member.name),
          ...(member.role
            ? [{ text: ` (${plain(member.role)})`, color: MUTED }]
            : [])
        ])
      ],
      margin: [0, 4, 0, 8]
    });
  }
  if (contacts.roleNote) contactStack.push(note(contacts.roleNote));

  content.push(...contactStack);

  if (research.hasResearch) {
    content.push(heading(labels.sectionResearch));
    content.push(note(labels.researchDisclaimer, [0, 0, 0, 12]));
    if (research.findings?.length) {
      content.push(
        subheading(labels.researchCitedHeading, MUTED, [0, 0, 0, 8])
      );
      research.findings.forEach((item) => content.push(finding(item)));
    }
    if (research.additional?.length) {
      content.push(subheading(research.additionalHeading));
      research.additional.forEach((item) => content.push(finding(item)));
    }
  }
  if (research.hasSearchSuggestions) {
    content.push(heading(labels.searchSuggestions));
    content.push(note(labels.pdfSearchSuggestionsNote));
  }

  // History reads as a ledger: one event per row, its period shown once per group.
  // It is reference material, so it comes last and keeps only the latest events.
  const historyGroups = view.history || [];
  const historyTotal = historyGroups.reduce(
    (sum, group) => sum + group.events.length,
    0
  );
  let historyRemaining = HISTORY_EVENT_LIMIT;
  const latestHistory = historyGroups
    .map((group) => {
      const events = group.events.slice(0, Math.max(0, historyRemaining));
      historyRemaining -= events.length;
      return { ...group, events };
    })
    .filter((group) => group.events.length);
  content.push(heading(labels.sectionHistory));
  if (latestHistory.length) {
    content.push(
      dataTable(
        null,
        latestHistory.flatMap((group) => {
          const isOpenNow = group.periodLabel === labels.openNow;
          return group.events.map((event, index) => [
            index === 0
              ? {
                  ...eyebrow(
                    group.periodLabel,
                    isOpenNow ? RISK : MUTED,
                    [0, 2, 0, 0]
                  ),
                  noWrap: true
                }
              : { text: "" },
            { text: plain(event.title), bold: true, color: INK },
            {
              text: plain(event.chip),
              color: isOpenNow ? RISK : TEXT
            },
            { text: plain(event.date), alignment: "right", noWrap: true }
          ]);
        }),
        [80, "*", "auto", "auto"]
      ),
      ...showing(HISTORY_EVENT_LIMIT - historyRemaining, historyTotal)
    );
  } else {
    content.push(note(labels.noHistory));
  }

  return {
    info: {
      title: `${labels.pdfTitle} - ${recordTitle}`,
      creator: "Salesforce Account Summary",
      creationDate: new Date(snapshot.exportedAt)
    },
    pageSize: "A4",
    pageMargins: [PAGE_X, 56, PAGE_X, 56],
    background: (page, size) => ({
      canvas: [
        { type: "rect", x: 0, y: 0, w: size.width, h: 6, color: BLUE },
        {
          type: "line",
          x1: PAGE_X,
          y1: size.height - 44,
          x2: size.width - PAGE_X,
          y2: size.height - 44,
          lineWidth: 0.5,
          lineColor: RULE
        }
      ]
    }),
    defaultStyle: {
      font: "Roboto",
      fontSize: 10.5,
      lineHeight: 1.45,
      color: TEXT
    },
    styles: {
      meta: { fontSize: 8.5, color: MUTED }
    },
    header: (page) => {
      if (page <= 1) return null;
      return {
        columns: [
          {
            text: labels.pdfTitle.toUpperCase(),
            bold: true,
            characterSpacing: 1.2
          },
          { text: recordTitle, alignment: "right" }
        ],
        margin: [PAGE_X, 24, PAGE_X, 0],
        color: MUTED,
        fontSize: 7.5
      };
    },
    footer: (page, total) => ({
      columns: [
        { text: labels.pdfFooter, width: "*" },
        { text: `${page} / ${total}`, width: 45, alignment: "right" }
      ],
      fontSize: 8,
      color: MUTED,
      margin: [PAGE_X, 22, PAGE_X, 0]
    }),
    pageBreakBefore: keepHeadingWithContent,
    content
  };
}
