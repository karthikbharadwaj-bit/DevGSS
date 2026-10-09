// Design tokens: one accent, neutrals, and two semantic tints for win/risk.
const INK = "#16325c";
const TEXT = "#2b3a4f";
const BLUE = "#0176d3";
const MUTED = "#5c6f88";
const RULE = "#d8dee6";
const PANEL = "#f4f7fb";
const WIN = "#2e844a";
const RISK = "#a35200";
const PAGE_X = 48;
const CONTENT_WIDTH = 499; // A4 width (595) minus margins (48 * 2)
const EVIDENCE_ID = /^E\d+$/;

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

function safeLink(value) {
  try {
    const url = new URL(value);
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
    plain(recordName || recordId || "Opportunity")
      .normalize("NFKC")
      // eslint-disable-next-line no-control-regex
      .replace(/[<>:"/\\|?*\u0000-\u001f\u007f]/g, "-")
      .replace(/[\u202a-\u202e\u2066-\u2069]/g, "")
      .replace(/\s+/g, " ")
      .replace(/[. ]+$/g, "")
      .slice(0, 90) || "Opportunity";
  return `Opportunity Summary - ${name} - ${timestamp(exportedAt).slice(0, 10)}.pdf`;
}

// Cleaner callout box with softer padding and slightly thicker accent line
function accentBox(stack, { color = BLUE, fill, margin = [0, 0, 0, 14] } = {}) {
  return {
    table: {
      widths: ["*"],
      body: [[{ stack, ...(fill ? { fillColor: fill } : {}) }]]
    },
    layout: {
      hLineWidth: () => 0,
      vLineWidth: (index) => (index === 0 ? 3 : 0),
      vLineColor: () => color,
      paddingLeft: () => 14,
      paddingRight: () => 14,
      paddingTop: () => 12,
      paddingBottom: () => 12
    },
    margin
  };
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

export function buildPdfDocument(snapshot, labels) {
  const groups = snapshot.researchGroups || [];
  const evidenceIds = new Set(
    groups
      .flatMap((group) => group.findings)
      .map((finding) => finding.id)
      .filter((id) => EVIDENCE_ID.test(id))
  );
  const recordTitle = plain(snapshot.recordName || snapshot.recordId);
  const content = [];

  // Modernized heading: bold text with a clean bottom rule instead of a side box
  const heading = (title, color = INK) =>
    content.push({
      stack: [
        { text: plain(title), fontSize: 13.5, bold: true, color },
        {
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

  const helper = (text) =>
    content.push({
      text: pdfText(text),
      style: "meta",
      margin: [0, -4, 0, 12]
    });

  const summaryLine = (item) => ({
    text: [
      ...(item.label
        ? [{ text: `${plain(item.label)}: `, bold: true, color: INK }]
        : []),
      ...pdfText(item.text, evidenceIds)
    ],
    margin: [0, 0, 0, 8] // Increased to separate dense bullet points
  });

  const chipLine = (chips) => ({
    text: chips.flatMap((chip, i) => [
      ...(i ? ["   ·   "] : []),
      { text: `${plain(chip.label)}: `, bold: true, color: INK },
      plain(chip.value)
    ]),
    style: "meta",
    margin: [0, -4, 0, 10]
  });

  const section = (
    title,
    items,
    { numbered = false, color = BLUE, chips = [] } = {}
  ) => {
    if (!items?.length) return;
    heading(title, color === BLUE ? INK : color);
    if (chips.length) content.push(chipLine(chips));
    content.push({
      [numbered ? "ol" : "ul"]: items.map(summaryLine),
      ...(numbered ? {} : { type: "square" }),
      markerColor: color,
      margin: [6, 0, 0, 6]
    });
  };

  const sourceRuns = (sources) => {
    const seen = new Set();
    return (sources || []).flatMap((source) => {
      const link = safeLink(source.url);
      if (!link || seen.has(link)) return [];
      seen.add(link);
      const label = plain(source.label);
      const text =
        label && !/https?:\/\//i.test(label) ? label : labels.pdfSources;
      return [{ text, link, color: BLUE }];
    });
  };

  const labelled = (label, text) => ({
    text: [
      { text: `${label}: `, bold: true, color: INK, fontSize: 9.5 },
      ...pdfText(text)
    ],
    margin: [0, 6, 0, 0]
  });

  const finding = (item, index, isSupplemental = false) => {
    const meta = [item.kindLabel, item.dateLabel, item.personLine]
      .filter(Boolean)
      .map(plain)
      .join("  ·  ");
    const links = sourceRuns(item.sources);

    const stack = [
      {
        text: [
          {
            text: `${isSupplemental ? index + 1 : item.id}  `,
            bold: true,
            color: BLUE
          },
          ...pdfText(item.fact)
        ],
        color: INK,
        fontSize: 10.5,
        ...(isSupplemental || !EVIDENCE_ID.test(item.id)
          ? {}
          : { id: `research-${item.id}` })
      }
    ];

    if (meta) stack.push({ text: meta, style: "meta", margin: [0, 4, 0, 2] });
    if (item.relevance)
      stack.push(labelled(labels.pdfRelevance, item.relevance));
    if (item.suggestedAction)
      stack.push(labelled(labels.pdfAction, item.suggestedAction));
    if (links.length) {
      stack.push({
        text: links.flatMap((run, i) => (i ? ["   ·   ", run] : [run])),
        fontSize: 8.5,
        color: MUTED,
        margin: [0, 8, 0, 0]
      });
    }
    content.push(accentBox(stack, { color: RULE, margin: [0, 0, 0, 12] }));
  };

  // Title block
  content.push(eyebrow(labels.pdfTitle, BLUE, [0, 0, 0, 8]));
  content.push({
    text: recordTitle,
    fontSize: 24,
    bold: true,
    color: INK,
    lineHeight: 1.15,
    margin: [0, 0, 0, 6]
  });

  const recordLink = safeLink(snapshot.recordUrl);
  if (recordLink) {
    content.push({
      text: labels.pdfRecord,
      link: recordLink,
      color: BLUE,
      fontSize: 9.5,
      margin: [0, 0, 0, 18]
    });
  }

  const facts = [
    ...(snapshot.currentStage
      ? [[labels.pdfStage, plain(snapshot.currentStage)]]
      : []),
    [labels.pdfSnapshot, timestamp(snapshot.generatedAt)],
    [labels.pdfExported, timestamp(snapshot.exportedAt)]
  ];

  // Modern, borderless snapshot facts grid
  content.push({
    table: {
      widths: facts.map(() => "*"),
      body: [
        facts.map(([label, value]) => ({
          stack: [
            eyebrow(label),
            { text: value, color: INK, fontSize: 10.5, bold: true }
          ]
        }))
      ]
    },
    layout: {
      defaultBorder: false,
      fillColor: () => PANEL,
      paddingLeft: () => 14,
      paddingRight: () => 14,
      paddingTop: () => 12,
      paddingBottom: () => 12
    },
    margin: [0, 0, 0, 8]
  });

  if (snapshot.scoreCard) {
    const score = snapshot.scoreCard;
    content.push(
      accentBox(
        [
          eyebrow(labels.pdfScore, BLUE),
          {
            text: plain(score.headline),
            fontSize: 24,
            bold: true,
            color: INK,
            margin: [0, 0, 0, 6]
          },
          ...(score.notes || []).map((note) => ({
            text: pdfText(note.text, evidenceIds),
            margin: [0, 4, 0, 0]
          }))
        ],
        { fill: PANEL, margin: [0, 16, 0, 0] }
      )
    );
  }

  section(labels.pdfExecutive, snapshot.executiveFacts, {
    chips: snapshot.salesforceChips || []
  });
  section(labels.pdfHistory, snapshot.history);
  section(labels.pdfWin, snapshot.winFactors, { color: WIN });
  section(labels.pdfRisk, snapshot.riskFlags, { color: RISK });
  section(labels.pdfActions, snapshot.nextActions, { numbered: true });
  section(labels.pdfPlan, snapshot.closePlan);
  section(labels.pdfPostClose, snapshot.postCloseActions);
  (snapshot.extraSections || []).forEach((extra) =>
    section(extra.title, extra.items)
  );

  if (snapshot.hasEnrichment) {
    content.push(
      accentBox(
        [
          {
            text: pdfText(labels.researchDisclaimer),
            fontSize: 9.5,
            color: INK
          }
        ],
        { fill: PANEL, margin: [0, 24, 0, 0] }
      )
    );
  }

  if (groups.length) {
    heading(labels.pdfResearch);
    helper(labels.researchHelper);
    groups.forEach((group) => {
      content.push({
        ...eyebrow(group.label, MUTED, [0, 12, 0, 8]),
        headlineLevel: 1
      });
      group.findings.forEach((item, index) => finding(item, index));
    });
  }

  if (snapshot.supplementalUpdates?.length) {
    heading(labels.pdfSupplemental);
    helper(labels.supplementalHelper);
    snapshot.supplementalUpdates.forEach((item, index) =>
      finding(item, index, true)
    );
  }

  const otherSources = sourceRuns(snapshot.otherResearchSources);
  if (otherSources.length) {
    heading(labels.pdfSources);
    content.push({
      ul: otherSources.map((run) => ({ text: [run], margin: [0, 0, 0, 6] })),
      type: "square",
      markerColor: RULE,
      fontSize: 9.5
    });
  }

  if (snapshot.searchQueries?.length) {
    heading(labels.pdfSearches);
    content.push({
      ul: snapshot.searchQueries.map((query) => ({
        text: pdfText(query.text),
        margin: [0, 0, 0, 5]
      })),
      type: "square",
      markerColor: RULE,
      fontSize: 9.5,
      color: MUTED
    });
  }

  return {
    info: {
      title: `${labels.pdfTitle} - ${recordTitle}`,
      creator: "Salesforce Opportunity Summary",
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
        text: labels.pdfTitle,
        margin: [PAGE_X, 24, PAGE_X, 0],
        color: MUTED,
        fontSize: 7.5,
        bold: true,
        characterSpacing: 1.2
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
    pageBreakBefore: (node, followingNodesOrContainer) => {
      const followingNodes = Array.isArray(followingNodesOrContainer)
        ? followingNodesOrContainer
        : followingNodesOrContainer?.getFollowingNodesOnPage?.() || [];
      return node.headlineLevel === 1 && followingNodes.length === 0;
    },
    content
  };
}
