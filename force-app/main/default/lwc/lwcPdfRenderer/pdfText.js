/*
 * The Roboto bundled with pdfmake has no glyph for the narrow no-break space (which date and time
 * formatters put before AM and PM), for some other Unicode spaces or for invisible marks, so pdfmake
 * draws a box for them. It does have the thin and hair spaces, but draws them so narrow that the
 * words on either side touch. Browsers render all of these, so only the PDF needs this.
 */
const PDF_TEXT_REPLACEMENTS = [
  [/\u202F/g, "\u00A0"],
  [/[\u2000-\u200A\u205F\u3000]/g, " "],
  [/[\u200B-\u200F\u2060\uFEFF]/g, ""],
  [/\u2192/g, "->"]
];

export function toPdfText(value) {
  if (typeof value !== "string") return value;
  return PDF_TEXT_REPLACEMENTS.reduce(
    (text, [pattern, replacement]) => text.replace(pattern, replacement),
    value
  );
}

function isPlainObject(value) {
  if (value === null || typeof value !== "object") return false;
  const prototype = Object.getPrototypeOf(value);
  return prototype === Object.prototype || prototype === null;
}

/*
 * Returns a copy of a pdfmake document definition with every string passed through toPdfText.
 * Functions such as header and footer are wrapped so the content they build is cleaned as well.
 * pdfmake only passes pageBreakBefore the nodes that follow a heading when that function declares
 * more than one parameter, so each wrapper keeps the parameter count of the function it wraps.
 */
export function toPdfDefinition(node) {
  if (typeof node === "string") return toPdfText(node);
  if (Array.isArray(node)) return node.map(toPdfDefinition);
  if (typeof node === "function") {
    const wrapper = (...args) => toPdfDefinition(node(...args));
    return Object.defineProperty(wrapper, "length", { value: node.length });
  }
  if (!isPlainObject(node)) return node;
  return Object.fromEntries(
    Object.entries(node).map(([key, value]) => [key, toPdfDefinition(value)])
  );
}
