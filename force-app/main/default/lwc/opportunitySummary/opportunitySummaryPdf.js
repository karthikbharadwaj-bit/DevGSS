// Modern SaaS Design Tokens
const COLORS = {
  primary: "#0176d3",
  primarySoft: "#eef4fb",
  textDark: "#0f172a",
  textMuted: "#64748b",
  surface: "#f8fafc",
  border: "#e2e8f0",
  win: "#059669",
  winSoft: "#ecfdf5",
  risk: "#ea580c",
  riskSoft: "#fff7ed",
  white: "#ffffff"
};

const PAGE_X = 40;
const EVIDENCE_ID = /^E\d+$/;
// Characters Windows/macOS reject in filenames, including control characters.
// eslint-disable-next-line no-control-regex
const UNSAFE_FILENAME_CHARS = /[<>:"/\\|?*\u0000-\u001f\u007f]/g;

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
  let bold = 0,
    italics = 0;

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
            ? {
                linkToDestination: `research-${id}`,
                color: COLORS.primary,
                bold: true
              }
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
  return value != null && Number.isFinite(date.getTime())
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
      .replace(UNSAFE_FILENAME_CHARS, "-")
      .replace(/[\u202a-\u202e\u2066-\u2069]/g, "")
      .replace(/\s+/g, " ")
      .replace(/[. ]+$/g, "")
      .slice(0, 90) || "Opportunity";
  return `Opportunity Summary - ${name} - ${timestamp(exportedAt).slice(0, 10)}.pdf`;
}

// --- Modern UI Components for PDF ---

function eyebrow(text, margin = [0, 0, 0, 4]) {
  return {
    text: plain(text).toUpperCase(),
    fontSize: 7.5,
    bold: true,
    color: COLORS.textMuted,
    characterSpacing: 1,
    margin
  };
}

function sectionHeader(title) {
  return {
    stack: [
      { text: plain(title), fontSize: 16, bold: true, color: COLORS.textDark }
    ],
    margin: [0, 24, 0, 12],
    headlineLevel: 1
  };
}

function modernCard(
  stackContent,
  bgColor = COLORS.white,
  borderColor = COLORS.border
) {
  return {
    table: {
      widths: ["*"],
      body: [[{ stack: stackContent }]]
    },
    layout: {
      defaultBorder: false,
      hLineWidth: () => 1,
      vLineWidth: () => 1,
      hLineColor: () => borderColor,
      vLineColor: () => borderColor,
      fillColor: () => bgColor,
      paddingLeft: () => 16,
      paddingRight: () => 16,
      paddingTop: () => 14,
      paddingBottom: () => 14
    },
    margin: [0, 0, 0, 12]
  };
}

export function buildPdfDocument(snapshot, labels) {
  const groups = snapshot.researchGroups || [];
  const evidenceIds = new Set(
    groups
      .flatMap((g) => g.findings)
      .map((f) => f.id)
      .filter((id) => EVIDENCE_ID.test(id))
  );

  const content = [];
  const recordTitle = plain(snapshot.recordName || snapshot.recordId);

  // 1. Header Area
  content.push(eyebrow(labels.pdfTitle, [0, 0, 0, 4]));
  content.push({
    text: recordTitle,
    fontSize: 26,
    bold: true,
    color: COLORS.textDark,
    lineHeight: 1.2,
    margin: [0, 0, 0, 6]
  });

  const recordLink = safeLink(snapshot.recordUrl);
  if (recordLink) {
    content.push({
      text: labels.pdfRecord,
      link: recordLink,
      color: COLORS.primary,
      fontSize: 10,
      margin: [0, 0, 0, 24]
    });
  }

  // 2. High-Level Metadata Grid (Score & Details side-by-side)
  const metaColumns = [];

  // Left side: Deal Score Block
  if (snapshot.scoreCard) {
    metaColumns.push({
      width: "45%",
      stack: [
        modernCard(
          [
            eyebrow(labels.pdfScore),
            {
              text: plain(snapshot.scoreCard.headline),
              fontSize: 20,
              bold: true,
              color: COLORS.textDark,
              margin: [0, 4, 0, 0]
            },
            ...(snapshot.scoreCard.notes || []).map((note) => ({
              text: pdfText(note.text, evidenceIds),
              fontSize: 9.5,
              color: COLORS.textMuted,
              margin: [0, 6, 0, 0]
            }))
          ],
          COLORS.primarySoft,
          COLORS.primarySoft
        )
      ]
    });
  }

  // Right side: Quick Facts
  metaColumns.push({
    width: "*",
    stack: [
      {
        table: {
          widths: ["auto", "*"],
          body: [
            [
              { text: labels.pdfStage, bold: true, color: COLORS.textMuted },
              {
                text: plain(snapshot.currentStage || "—"),
                color: COLORS.textDark
              }
            ],
            [
              { text: labels.pdfSnapshot, bold: true, color: COLORS.textMuted },
              { text: timestamp(snapshot.generatedAt), color: COLORS.textDark }
            ],
            [
              { text: labels.pdfExported, bold: true, color: COLORS.textMuted },
              { text: timestamp(snapshot.exportedAt), color: COLORS.textDark }
            ]
          ]
        },
        layout: "noBorders",
        margin: [16, 8, 0, 0],
        fontSize: 10,
        lineHeight: 1.5
      }
    ]
  });

  content.push({ columns: metaColumns, columnGap: 20, margin: [0, 0, 0, 24] });

  // Helper for bulleted lists
  const bulletList = (items, markerColor = COLORS.primary) => ({
    ul: items.map((item) => ({
      text: [
        ...(item.label
          ? [
              {
                text: `${plain(item.label)}: `,
                bold: true,
                color: COLORS.textDark
              }
            ]
          : []),
        ...pdfText(item.text, evidenceIds)
      ],
      margin: [0, 0, 0, 8]
    })),
    markerColor,
    margin: [12, 0, 0, 0]
  });

  // 3. Executive Summary
  if (snapshot.executiveFacts?.length) {
    content.push(sectionHeader(labels.pdfExecutive));
    content.push(bulletList(snapshot.executiveFacts));
  }

  // 4. Two-Column Dashboard for Win Factors and Risk Flags
  const splitColumns = [];
  if (snapshot.winFactors?.length) {
    splitColumns.push({
      width: "50%",
      stack: [
        {
          text: labels.pdfWin,
          fontSize: 13,
          bold: true,
          color: COLORS.win,
          margin: [0, 0, 0, 10]
        },
        modernCard(
          [bulletList(snapshot.winFactors, COLORS.win)],
          COLORS.winSoft,
          COLORS.winSoft
        )
      ]
    });
  }
  if (snapshot.riskFlags?.length) {
    splitColumns.push({
      width: "50%",
      stack: [
        {
          text: labels.pdfRisk,
          fontSize: 13,
          bold: true,
          color: COLORS.risk,
          margin: [0, 0, 0, 10]
        },
        modernCard(
          [bulletList(snapshot.riskFlags, COLORS.risk)],
          COLORS.riskSoft,
          COLORS.riskSoft
        )
      ]
    });
  }

  if (splitColumns.length) {
    content.push({
      margin: [0, 24, 0, 0],
      columns: splitColumns,
      columnGap: 16
    });
  }

  // 5. Timeline & Next Actions
  if (snapshot.nextActions?.length) {
    content.push(sectionHeader(labels.pdfActions));
    content.push({
      ol: snapshot.nextActions.map((a) => ({
        text: pdfText(a.text, evidenceIds),
        margin: [0, 0, 0, 8]
      })),
      markerColor: COLORS.primary,
      margin: [12, 0, 0, 0]
    });
  }

  if (snapshot.history?.length) {
    content.push(sectionHeader(labels.pdfHistory));
    content.push(bulletList(snapshot.history, COLORS.textMuted));
  }

  if (snapshot.closePlan?.length) {
    content.push(sectionHeader(labels.pdfPlan));
    content.push(bulletList(snapshot.closePlan));
  }

  (snapshot.extraSections || []).forEach((extra) => {
    if (!extra.items?.length) return;
    content.push(sectionHeader(extra.title));
    content.push(bulletList(extra.items));
  });

  // Deduplicated, safe source links. Labels that look like URLs (for example
  // grounding redirects with tokens) are never shown as link text.
  const sourceRuns = (sources) => {
    const seen = new Set();
    return (sources || []).flatMap((source) => {
      const link = safeLink(source.url);
      if (!link || seen.has(link)) return [];
      seen.add(link);
      const label = plain(source.label);
      const text =
        label && !/https?:\/\//i.test(label) ? label : labels.pdfSources;
      return [{ text, link, color: COLORS.primary }];
    });
  };

  const findingCard = (item, index, isSupplemental = false) => {
    const meta = [item.kindLabel, item.dateLabel, item.personLine]
      .filter(Boolean)
      .map(plain)
      .join("  ·  ");
    const links = sourceRuns(item.sources);
    const cardStack = [
      {
        text: [
          {
            text: `${isSupplemental ? index + 1 : item.id}  `,
            bold: true,
            color: COLORS.primary
          },
          ...pdfText(item.fact)
        ],
        color: COLORS.textDark,
        fontSize: 11,
        ...(isSupplemental || !EVIDENCE_ID.test(item.id)
          ? {}
          : { id: `research-${item.id}` })
      }
    ];
    if (meta)
      cardStack.push({
        text: meta,
        fontSize: 8.5,
        color: COLORS.textMuted,
        margin: [0, 6, 0, 2]
      });
    if (item.relevance)
      cardStack.push({
        text: [
          { text: `${labels.pdfRelevance}: `, bold: true },
          ...pdfText(item.relevance)
        ],
        margin: [0, 6, 0, 0]
      });
    if (item.suggestedAction)
      cardStack.push({
        text: [
          { text: `${labels.pdfAction}: `, bold: true },
          ...pdfText(item.suggestedAction)
        ],
        margin: [0, 6, 0, 0]
      });
    if (links.length) {
      cardStack.push({
        text: links.flatMap((run, i) => (i ? ["   ·   ", run] : [run])),
        fontSize: 9,
        margin: [0, 10, 0, 0]
      });
    }
    content.push(modernCard(cardStack, COLORS.white, COLORS.border));
  };
  const helperText = (text) => ({
    text: pdfText(text),
    fontSize: 9,
    color: COLORS.textMuted,
    margin: [0, -4, 0, 12]
  });

  // 6. AI Research & Compliance Section
  const supplemental = snapshot.supplementalUpdates || [];
  const otherSources = sourceRuns(snapshot.otherResearchSources);
  const searches = snapshot.searchQueries || [];
  if (
    groups.length ||
    snapshot.hasEnrichment ||
    supplemental.length ||
    otherSources.length ||
    searches.length
  ) {
    content.push({ text: "", pageBreak: "before" }); // Push research to clean new page

    // Core AI Disclaimer
    if (snapshot.hasEnrichment) {
      content.push(
        modernCard(
          [
            {
              text: "AI-Generated Content Disclaimer",
              bold: true,
              color: COLORS.textDark,
              fontSize: 10,
              margin: [0, 0, 0, 4]
            },
            {
              text: pdfText(labels.researchDisclaimer),
              fontSize: 9.5,
              color: COLORS.textMuted
            }
          ],
          COLORS.surface
        )
      );
    }

    // Google Search Suggestions Compliance Block[cite: 8]
    // Required to remain as-is if Grounding API is utilized.
    if (snapshot.hasSearchSuggestionsMarkup) {
      content.push(
        modernCard(
          [
            {
              text: "Google Search Suggestions",
              bold: true,
              color: COLORS.textDark,
              fontSize: 10,
              margin: [0, 0, 0, 4]
            },
            {
              text: plain(
                snapshot.searchSuggestionsLimitation ||
                  "Search suggestions are limited due to regional policy."
              ),
              fontSize: 9.5,
              color: COLORS.textMuted
            }
          ],
          COLORS.surface
        )
      );
    }

    if (groups.length) {
      content.push(sectionHeader(labels.pdfResearch));
      content.push(helperText(labels.researchHelper));
      groups.forEach((group) => {
        content.push({
          text: plain(group.label).toUpperCase(),
          fontSize: 10,
          bold: true,
          color: COLORS.primary,
          margin: [0, 16, 0, 10],
          headlineLevel: 1
        });
        group.findings.forEach((item, index) => findingCard(item, index));
      });
    }

    if (supplemental.length) {
      content.push(sectionHeader(labels.pdfSupplemental));
      content.push(helperText(labels.supplementalHelper));
      supplemental.forEach((item, index) => findingCard(item, index, true));
    }

    if (otherSources.length) {
      content.push(sectionHeader(labels.pdfSources));
      content.push({
        ul: otherSources.map((run) => ({ text: [run], margin: [0, 0, 0, 6] })),
        markerColor: COLORS.primary,
        margin: [12, 0, 0, 0]
      });
    }

    if (searches.length) {
      content.push(sectionHeader(labels.pdfSearches));
      content.push(bulletList(searches, COLORS.textMuted));
    }
  }

  return {
    info: {
      title: `${labels.pdfTitle} - ${recordTitle}`,
      creator: "Salesforce Opportunity Summary",
      creationDate: new Date(snapshot.exportedAt)
    },
    pageSize: "A4",
    pageMargins: [PAGE_X, 60, PAGE_X, 60],
    defaultStyle: {
      font: "Roboto",
      fontSize: 10.5,
      lineHeight: 1.45,
      color: COLORS.textDark
    },
    header: (page) => {
      if (page <= 1) return null;
      return {
        columns: [
          { text: labels.pdfTitle, bold: true },
          { text: recordTitle, alignment: "right" }
        ],
        margin: [PAGE_X, 24, PAGE_X, 0],
        color: COLORS.textMuted,
        fontSize: 8
      };
    },
    footer: (page, total) => ({
      columns: [
        {
          text: labels.pdfFooter || "Generated securely via Salesforce",
          width: "*"
        },
        { text: `Page ${page} of ${total}`, width: 60, alignment: "right" }
      ],
      fontSize: 8,
      color: COLORS.textMuted,
      margin: [PAGE_X, 24, PAGE_X, 0]
    }),
    // Keep a heading on the same page as the content that follows it.
    pageBreakBefore: (node, followingNodesOrContainer) => {
      const followingNodes = Array.isArray(followingNodesOrContainer)
        ? followingNodesOrContainer
        : followingNodesOrContainer?.getFollowingNodesOnPage?.() || [];
      return node.headlineLevel === 1 && followingNodes.length === 0;
    },
    content
  };
}
