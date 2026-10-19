/*
 * Building blocks both summary PDF builders share. Kept free of Salesforce imports so the Node
 * renderer tests can load the builders outside Lightning.
 */

// Room for a heading plus its first couple of lines.
const MIN_SPACE_AFTER_HEADING = 90;
const LINK_COLOR = "#0176d3";

/** Marks the parts inside a heading (title, rule, stage rail), which never count as content after it. */
export const HEADING_PART = 2;

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

/**
 * Turns the service's light HTML into pdfmake text runs. Only bold, italics and line breaks
 * survive; scripts, styles and comments are dropped. A known [E#] marker becomes a link to its
 * research finding.
 * @param {*} value text or HTML
 * @param {Set<string>} evidenceIds ids that have a research anchor in the document
 * @param {function(string): string} normalizeText applied to each decoded text run
 * @returns {Array<object>} pdfmake text runs, never empty
 */
export function pdfText(
  value,
  evidenceIds = new Set(),
  normalizeText = (text) => text
) {
  const source = String(value ?? "")
    .replace(/<(script|style|iframe|object|svg)\b[^>]*>[\s\S]*?<\/\1\s*>/gi, "")
    .replace(/<!--[\s\S]*?-->/g, "");
  const runs = [];
  let bold = 0;
  let italics = 0;

  const append = (text) => {
    normalizeText(decodeEntities(text))
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
                color: LINK_COLOR,
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

/**
 * The text of pdfText's runs without formatting, trimmed.
 * @param {*} value text or HTML
 * @param {function(string): string} normalizeText passed through to pdfText
 * @returns {string}
 */
export function plainText(value, normalizeText) {
  return pdfText(value, new Set(), normalizeText)
    .map((run) => run.text)
    .join("")
    .trim();
}

/**
 * An http(s) URL without credentials, or null. Relative URLs resolve against base when given.
 * @param {string} value
 * @param {string} [base]
 * @returns {string|null}
 */
export function safeLink(value, base) {
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

/**
 * pdfmake pageBreakBefore rule that keeps a heading (headlineLevel 1) on the same page as the
 * content after it. pdfmake only passes the following nodes when this declares two parameters.
 */
export function keepHeadingWithContent(node, followingNodesOrContainer) {
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
}
