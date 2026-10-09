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
const PAGE_X = 36;
const CONTENT_WIDTH = 523; // A4 width (595) minus margins (36 * 2)
const TILES_PER_ROW = 5;
const HEADER_FIELDS_PER_ROW = 4;
const EVIDENCE_ID = /^E\d+$/;
const HISTORY_EVENT_LIMIT = 20;
// Room for a heading plus its first couple of rows.
const MIN_SPACE_AFTER_HEADING = 60;
// Stage names such as "5. Agreement" read as a sentence end when a line wraps after the number.
const NUMBERED_STAGE = /(^|[^\d.])(\d{1,2}\.) (?=[A-Z])/g;
// Marks the title and rule inside a heading, which never count as content following it.
const HEADING_PART = 2;
const BAND_COLORS = { green: WIN, amber: RISK, red: ALERT };
const BAND_TINTS = { green: "#ebf7e6", amber: "#fef1e6", red: "#feded8" };
const FLAG_PADDING = 10;
const BAR_LABEL_WIDTH = 130;
const BAR_POINTS_WIDTH = 34;
const BAR_TRACK_WIDTH = 220;
const BAR_FILL_COLORS = {
  "bar-fill": WIN,
  "bar-fill bar-fill_warn": RISK,
  "bar-fill bar-fill_bad": ALERT
};

const ENTITIES = {
  amp: "&",
  lt: "<",
  gt: ">",
  quot: '"',
  apos: "'",
  nbsp: " ",
  ndash: "–",
  mdash: "—",
  lsquo: "‘",
  rsquo: "’",
  ldquo: "“",
  rdquo: "”",
  hellip: "…",
  bull: "•",
  euro: "€",
  pound: "£",
  copy: "©",
  reg: "®"
};

function decodeEntities(value) {
  return value.replace(/&(#x[\da-f]+|#\d+|[a-z]+);/gi, (match, entity) => {
    if (entity[0] !== "#") return ENTITIES[entity.toLowerCase()] ?? match;
    const hex = entity[1].toLowerCase() === "x";
    const code = Number.parseInt(entity.slice(hex ? 2 : 1), hex ? 16 : 10);
    return code > 0 && code <= 0x10ffff && !(code >= 0xd800 && code <= 0xdfff)
      ? String.fromCodePoint(code)
      : "";
  });
}

export function pdfText(value, evidenceIds = new Set()) {
  const source = String(value ?? "")
    .replace(/<(script|style|iframe|object|svg)\b[^>]*>[\s\S]*?<\/\1\s*>/gi, "")
    .replace(/<!--[\s\S]*?-->/g, "");
  const runs = [];
  let bold = 0;
  let italics = 0;

  const append = (text) => {
    decodeEntities(text)
      .replace(NUMBERED_STAGE, "$1$2\u00a0")
      .split(/(\[E\d+\])/g)
      .filter(Boolean)
      .forEach((part) => {
        const id = part.slice(1, -1);
        runs.push({
          text: part,
          bold: bold > 0,
          italics: italics > 0,
          ...(/^\[E\d+\]$/.test(part) && evidenceIds.has(id)
            ? { linkToDestination: `research-${id}`, color: BLUE, bold: true }
            : {})
        });
      });
  };

  source.split(/(<[^>]*>)/g).forEach((part) => {
    if (!part.startsWith("<") || !part.endsWith(">")) {
      append(part);
      return;
    }
    const tag = /^<\s*(\/?)\s*([a-z][\w-]*)\b/i.exec(part);
    if (!tag) {
      append(part);
      return;
    }
    const closing = Boolean(tag[1]);
    switch (tag[2].toLowerCase()) {
      case "b":
      case "strong":
        bold = Math.max(0, bold + (closing ? -1 : 1));
        break;
      case "i":
      case "em":
        italics = Math.max(0, italics + (closing ? -1 : 1));
        break;
      case "br":
        append("\n");
        break;
      case "p":
      case "div":
      case "li":
        if (closing) append("\n");
        break;
      default:
        break;
    }
  });
  return runs.length ? runs : [{ text: "" }];
}

function plain(value) {
  return pdfText(value)
    .map((run) => run.text)
    .join("")
    .trim();
}

function safeLink(value, base) {
  try {
    const url = base ? new URL(value, base) : new URL(value);
    return ["https:", "http:"].includes(url.protocol) &&
      !url.username &&
      !url.password
      ? url.href
      : null;
  } catch {
    return null;
  }
}

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

function eyebrow(text, color = MUTED, margin = [0, 0, 0, 2]) {
  return {
    text: plain(text).toUpperCase(),
    fontSize: 6.5,
    bold: true,
    color,
    characterSpacing: 0.8,
    margin
  };
}

// Thin rules between table rows only, never above the first or below the last.
function rowRuleWidth(index, node) {
  return index === 0 || index === node.table.body.length ? 0 : 0.5;
}

function cellPaddingRight(index, node) {
  return index === node.table.widths.length - 1 ? 0 : 6;
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
          h: 4,
          r: 2,
          color: RULE
        },
        ...(fill > 0
          ? [
              {
                type: "rect",
                x: 0,
                y: 0,
                w: fill,
                h: 4,
                r: 2,
                color: BAR_FILL_COLORS[bar.fillClass] || BLUE
              }
            ]
          : [])
      ],
      margin: [0, 3.5, 0, 0]
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
            fontSize: 6.5,
            bold: true,
            characterSpacing: 0.6,
            color: "#ffffff",
            fillColor: color
          }
        ]
      ]
    },
    layout: {
      defaultBorder: false,
      paddingLeft: () => 5,
      paddingRight: () => 5,
      paddingTop: () => 1,
      paddingBottom: () => 0.5
    }
  };
}

// The routing kind as a tag, unless the step already opens with that word ("Notify …").
function routeTag(step) {
  const kind = plain(step.kind);
  if (!kind) return "";
  const opensWithKind = plain(step.text)
    .toLowerCase()
    .startsWith(kind.toLowerCase());
  return opensWithKind ? "" : kind.toUpperCase();
}

function chunk(items, size) {
  const rows = [];
  for (let index = 0; index < items.length; index += size) {
    rows.push(items.slice(index, index + size));
  }
  return rows;
}

// Borderless shaded grid used for the header fields and metric tiles.
function panelGrid(cells, perRow, margin = [0, 0, 0, 6]) {
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
      paddingLeft: () => 8,
      paddingRight: () => 8,
      paddingTop: () => 5,
      paddingBottom: () => 5
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
        fontSize: 10.5,
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
            lineWidth: 0.75,
            lineColor: RULE
          }
        ],
        margin: [0, 2, 0, 0]
      }
    ],
    margin: [0, 12, 0, 5],
    headlineLevel: 1
  });

  const subheading = (text, color = MUTED, margin = [0, 4, 0, 2]) => ({
    ...eyebrow(text, color, margin),
    headlineLevel: 1
  });

  const note = (text, margin = [0, 0, 0, 4]) => ({
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
      paddingLeft: (index) => (index === 0 ? 0 : 6),
      paddingRight: cellPaddingRight,
      paddingTop: () => 2.5,
      paddingBottom: () => 2.5
    },
    fontSize: 8.5,
    margin: [0, 0, 0, 4]
  });

  // A record name with its secondary details on one muted line beneath it.
  const cellWithSub = (main, subs) => {
    const sub = subs.filter(Boolean).map(plain).join("  ·  ");
    return sub ? { stack: [main, { text: sub, style: "meta" }] } : main;
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
    subheading(title, color, [0, 2, 0, 2]),
    items?.length
      ? {
          ul: items.map((item) => ({
            text: titledLine(item.title, item.detail, item.evidence),
            margin: [0, 0, 0, 2]
          })),
          type: "square",
          markerColor: color,
          margin: [0, 0, 0, 4]
        }
      : note(emptyText)
  ];

  const finding = (item) => {
    const canAnchor = EVIDENCE_ID.test(item.id) && !anchoredIds.has(item.id);
    if (canAnchor) anchoredIds.add(item.id);
    const meta = [item.kind, item.meta].filter(Boolean).map(plain);
    const links = sourceRuns(item.sources);
    return {
      columns: [
        {
          width: 18,
          text: plain(item.id),
          bold: true,
          color: BLUE,
          ...(canAnchor ? { id: `research-${item.id}` } : {})
        },
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
                    { ...run, fontSize: 7.5 }
                  ])
                ]
              : [])
          ]
        }
      ],
      columnGap: 4,
      margin: [0, 0, 0, 4],
      unbreakable: true
    };
  };

  // Title block, with the snapshot facts set to the right of the account name.
  const facts = [
    ...(snapshot.asOfDate
      ? [[labels.pdfDataAsOf, plain(snapshot.asOfDate)]]
      : []),
    [labels.pdfSnapshot, timestamp(snapshot.generatedAt)],
    [labels.pdfExported, timestamp(snapshot.exportedAt)]
  ];
  const accountLink = safeLink(snapshot.recordUrl);
  content.push({
    columns: [
      {
        width: "*",
        stack: [
          eyebrow(labels.pdfTitle, BLUE),
          {
            text: recordTitle,
            fontSize: 17,
            bold: true,
            color: INK,
            lineHeight: 1.1
          },
          ...(accountLink
            ? [
                {
                  text: labels.pdfRecord,
                  link: accountLink,
                  color: BLUE,
                  fontSize: 8,
                  margin: [0, 2, 0, 0]
                }
              ]
            : [])
        ]
      },
      {
        width: "auto",
        table: {
          body: facts.map(([label, value]) => [
            { ...eyebrow(label, MUTED, [0, 1, 0, 0]), alignment: "right" },
            { text: value, bold: true, color: INK, fontSize: 8 }
          ])
        },
        layout: "noBorders",
        margin: [0, 2, 0, 0]
      }
    ],
    columnGap: 12,
    margin: [0, 0, 0, 8]
  });

  // Account flag, row by row as in the modal: title and band, override, score, components, routing.
  const flag = view.flag || {};
  const bandKey = String(flag.band || "").toLowerCase();
  const bandColor = BAND_COLORS[bandKey] || BLUE;
  const flagStack = [
    {
      columns: [
        { ...eyebrow(labels.sectionFlag, INK, [0, 1.5, 0, 0]), width: "auto" },
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
        vLineWidth: (index) => (index === 0 ? 2 : 0),
        vLineColor: () => bandColor,
        paddingLeft: () => 8,
        paddingRight: () => 8,
        paddingTop: () => 4,
        paddingBottom: () => 4
      },
      margin: [0, 6, 0, 0]
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
                    fontSize: 20,
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
          margin: [0, 2, 0, 0]
        }
      ],
      columnGap: 14,
      margin: [0, 6, 0, 0]
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
        paddingLeft: (index) => (index === 0 ? 0 : 8),
        paddingRight: () => 0,
        paddingTop: () => 1.5,
        paddingBottom: () => 1.5
      },
      margin: [0, 6, 0, 0]
    });
  }
  if (flag.routing?.length) {
    flagStack.push(eyebrow(labels.routingHeading, MUTED, [0, 8, 0, 2]));
    flagStack.push({
      ol: flag.routing.map((step) => ({
        text: [
          ...(routeTag(step)
            ? [
                {
                  text: `${routeTag(step)}  `,
                  fontSize: 7,
                  bold: true,
                  color: BLUE
                }
              ]
            : []),
          ...pdfText(step.text, evidenceIds)
        ],
        margin: [0, 0, 0, 2]
      }))
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
        paddingTop: () => 8,
        paddingBottom: () => 8
      },
      margin: [0, 0, 0, 4]
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
          margin: [0, 0, 0, 3]
        })),
        type: "square",
        markerColor: BLUE,
        margin: [0, 2, 0, 0]
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
              fontSize: 11.5,
              bold: true
            },
            ...(tile.detail
              ? [{ text: plain(tile.detail), style: "meta" }]
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
              ? [{ text: `${tags}   `, fontSize: 7, bold: true, color: BLUE }]
              : []),
            ...titledLine(action.title, action.detail, action.evidence)
          ],
          margin: [0, 0, 0, 3]
        };
      }),
      markerColor: BLUE
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
      margin: [0, 0, 0, 3]
    });
  }

  const cases = view.cases || { open: [], closed: [] };
  content.push(heading(labels.sectionCases));
  content.push(subheading(cases.openHeading, MUTED, [0, 0, 0, 2]));
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
      margin: [0, 2, 0, 2]
    });
  }
  if (contacts.roleNote) contactStack.push(note(contacts.roleNote));

  content.push(...contactStack);

  if (research.hasResearch) {
    content.push(heading(labels.sectionResearch));
    content.push(note(labels.researchDisclaimer, [0, 0, 0, 5]));
    if (research.findings?.length) {
      content.push(
        subheading(labels.researchCitedHeading, MUTED, [0, 0, 0, 3])
      );
      research.findings.forEach((item) => content.push(finding(item)));
    }
    if (research.additional?.length) {
      content.push(subheading(research.additionalHeading));
      research.additional.forEach((item) => content.push(finding(item)));
    }
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
                    [0, 1.5, 0, 0]
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
        [70, "*", "auto", "auto"]
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
    pageMargins: [PAGE_X, 36, PAGE_X, 36],
    background: (page, size) => ({
      canvas: [
        { type: "rect", x: 0, y: 0, w: size.width, h: 4, color: BLUE },
        {
          type: "line",
          x1: PAGE_X,
          y1: size.height - 30,
          x2: size.width - PAGE_X,
          y2: size.height - 30,
          lineWidth: 0.5,
          lineColor: RULE
        }
      ]
    }),
    defaultStyle: {
      font: "Roboto",
      fontSize: 8.5,
      lineHeight: 1.25,
      color: TEXT
    },
    styles: {
      meta: { fontSize: 7.5, color: MUTED }
    },
    header: (page) => {
      if (page <= 1) return null;
      return {
        columns: [
          {
            text: labels.pdfTitle.toUpperCase(),
            bold: true,
            characterSpacing: 0.8
          },
          { text: recordTitle, alignment: "right" }
        ],
        margin: [PAGE_X, 16, PAGE_X, 0],
        color: MUTED,
        fontSize: 6.5
      };
    },
    footer: (page, total) => ({
      columns: [
        { text: labels.pdfFooter, width: "*" },
        { text: `${page} / ${total}`, width: 45, alignment: "right" }
      ],
      fontSize: 7,
      color: MUTED,
      margin: [PAGE_X, 14, PAGE_X, 0]
    }),
    // Keep a heading on the same page as the content that follows it.
    pageBreakBefore: (node, followingNodesOrContainer) => {
      const followingNodes = Array.isArray(followingNodesOrContainer)
        ? followingNodesOrContainer
        : followingNodesOrContainer?.getFollowingNodesOnPage?.() || [];
      if (node.headlineLevel !== 1) {
        return false;
      }
      // Rows moved by dontBreakRows still report their old position on this page, so a
      // heading near the bottom moves on regardless of what appears to follow it.
      const position = node.startPosition || {};
      const spaceLeft =
        (1 - (position.verticalRatio ?? 0)) * (position.pageInnerHeight ?? 0);
      if (position.pageInnerHeight && spaceLeft < MIN_SPACE_AFTER_HEADING) {
        return true;
      }
      // Page header/footer nodes are reported as following nodes too, but sit above the heading.
      // Only drawn content counts: a table or list wrapper can start on this page while
      // its rows have already moved to the next.
      const top = position.top ?? 0;
      return followingNodes.every(
        (next) =>
          next.headlineLevel === HEADING_PART ||
          (next.text === undefined && !next.canvas && !next.image) ||
          (next.startPosition?.top ?? Infinity) <= top
      );
    },
    content
  };
}
