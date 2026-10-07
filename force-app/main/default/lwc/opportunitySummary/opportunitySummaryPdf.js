const INK = "#16325c";
const BLUE = "#0176d3";
const MUTED = "#526581";
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

// Parse only text and a small emphasis vocabulary. Never insert response markup
// into the DOM or accept renderer instructions, images, attachments or HTML URLs.
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
            ? { linkToDestination: `research-${id}`, color: BLUE }
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

export function buildPdfDocument(snapshot, labels) {
  const groups = snapshot.researchGroups || [];
  const evidenceIds = new Set(
    groups
      .flatMap((group) => group.findings)
      .map((finding) => finding.id)
      .filter((id) => EVIDENCE_ID.test(id))
  );
  const content = [];
  const heading = (title) =>
    content.push({ text: plain(title), style: "section", headlineLevel: 1 });
  const paragraph = (text, extra = {}) => ({
    text: pdfText(text, evidenceIds),
    margin: [0, 0, 0, 7],
    ...extra
  });
  const summaryLine = (item) => ({
    text: [
      ...(item.label ? [{ text: `${plain(item.label)}: `, bold: true }] : []),
      ...pdfText(item.text, evidenceIds)
    ],
    margin: [0, 0, 0, 7]
  });
  const section = (title, items, numbered = false) => {
    if (!items?.length) return;
    heading(title);
    content.push({
      [numbered ? "ol" : "ul"]: items.map(summaryLine),
      margin: [0, 0, 0, 5]
    });
  };
  const sourceLinks = (sources) => {
    const seen = new Set();
    return (sources || []).flatMap((source) => {
      const link = safeLink(source.url);
      if (!link || seen.has(link)) return [];
      seen.add(link);
      const label = plain(source.label);
      // Even malformed labels must not expose long grounding redirect tokens.
      const text =
        label && !/https?:\/\//i.test(label) ? label : labels.pdfSources;
      return [
        {
          text,
          link,
          color: BLUE,
          decoration: "underline",
          fontSize: 9,
          margin: [0, 0, 0, 4]
        }
      ];
    });
  };
  const finding = (item, index, isSupplemental = false) => {
    const meta = [item.kindLabel, item.dateLabel, item.personLine]
      .filter(Boolean)
      .map(plain)
      .join(" · ");
    content.push({
      text: [
        {
          text: `${isSupplemental ? index + 1 : item.id}. `,
          bold: true,
          color: BLUE
        },
        ...pdfText(item.fact)
      ],
      ...(isSupplemental || !EVIDENCE_ID.test(item.id)
        ? {}
        : { id: `research-${item.id}` }),
      margin: [0, 8, 0, 5]
    });
    if (meta) content.push(paragraph(meta, { style: "meta" }));
    if (item.relevance)
      content.push(paragraph(`${labels.pdfRelevance}: ${item.relevance}`));
    if (item.suggestedAction)
      content.push(paragraph(`${labels.pdfAction}: ${item.suggestedAction}`));
    content.push(...sourceLinks(item.sources));
  };

  content.push({ text: labels.pdfTitle, style: "title" });
  content.push({
    text: plain(snapshot.recordName || snapshot.recordId),
    style: "subtitle"
  });
  const recordLink = safeLink(snapshot.recordUrl);
  if (recordLink)
    content.push({
      text: labels.pdfRecord,
      link: recordLink,
      color: BLUE,
      fontSize: 9,
      margin: [0, 0, 0, 10]
    });
  content.push({
    text: `${labels.pdfSnapshot}: ${timestamp(snapshot.generatedAt)}\n${labels.pdfExported}: ${timestamp(snapshot.exportedAt)}`,
    style: "meta",
    margin: [0, 0, 0, 14]
  });
  if (snapshot.currentStage)
    content.push(paragraph(`${labels.pdfStage}: ${snapshot.currentStage}`));
  if (snapshot.scoreCard) {
    heading(labels.pdfScore);
    const score = snapshot.scoreCard;
    content.push({
      text: plain(score.headline),
      fontSize: 22,
      bold: true,
      color: BLUE,
      margin: [0, 0, 0, 8]
    });
    (score.notes || []).forEach((note) => content.push(paragraph(note.text)));
  }
  section(labels.pdfExecutive, snapshot.executiveFacts);
  section(labels.pdfHistory, snapshot.history);
  section(labels.pdfWin, snapshot.winFactors);
  section(labels.pdfRisk, snapshot.riskFlags);
  section(labels.pdfActions, snapshot.nextActions, true);
  section(labels.pdfPlan, snapshot.closePlan);
  (snapshot.extraSections || []).forEach((extra) =>
    section(extra.title, extra.items)
  );

  if (snapshot.hasEnrichment) {
    content.push({
      table: {
        widths: ["*"],
        body: [
          [
            {
              text: labels.researchDisclaimer,
              fillColor: "#eef5ff",
              color: INK,
              margin: [10, 9, 10, 9],
              fontSize: 10
            }
          ]
        ]
      },
      layout: "noBorders",
      margin: [0, 16, 0, 10]
    });
  }
  if (groups.length) {
    heading(labels.pdfResearch);
    content.push(paragraph(labels.researchHelper, { style: "meta" }));
    groups.forEach((group) => {
      content.push({
        text: plain(group.label),
        style: "group",
        headlineLevel: 1
      });
      group.findings.forEach((item, index) => finding(item, index));
    });
  }
  if (snapshot.supplementalUpdates?.length) {
    heading(labels.pdfSupplemental);
    content.push(paragraph(labels.supplementalHelper, { style: "meta" }));
    snapshot.supplementalUpdates.forEach((item, index) =>
      finding(item, index, true)
    );
  }
  const otherSources = sourceLinks(snapshot.otherResearchSources);
  if (otherSources.length) {
    heading(labels.pdfSources);
    content.push(...otherSources);
  }
  if (snapshot.searchQueries?.length) {
    section(labels.pdfSearches, snapshot.searchQueries);
  }

  return {
    info: {
      title: `${labels.pdfTitle} - ${plain(snapshot.recordName || snapshot.recordId)}`,
      creator: "Salesforce Opportunity Summary",
      creationDate: new Date(snapshot.exportedAt)
    },
    pageSize: "A4",
    pageMargins: [42, 46, 42, 52],
    defaultStyle: {
      font: "Roboto",
      fontSize: 10,
      lineHeight: 1.25,
      color: "#243247"
    },
    styles: {
      title: { fontSize: 24, bold: true, color: INK, margin: [0, 0, 0, 6] },
      subtitle: { fontSize: 14, color: MUTED, margin: [0, 0, 0, 6] },
      section: { fontSize: 14, bold: true, color: INK, margin: [0, 14, 0, 8] },
      group: { fontSize: 11, bold: true, color: INK, margin: [0, 10, 0, 4] },
      meta: { fontSize: 9, color: MUTED }
    },
    header: (page) => {
      if (page <= 1) return null;
      return {
        text: labels.pdfTitle,
        margin: [42, 20, 42, 0],
        color: MUTED,
        fontSize: 8
      };
    },
    footer: (page, total) => ({
      columns: [
        { text: labels.pdfFooter, width: "*" },
        { text: `${page} / ${total}`, width: 45, alignment: "right" }
      ],
      fontSize: 8,
      color: MUTED,
      margin: [42, 16, 42, 0]
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
