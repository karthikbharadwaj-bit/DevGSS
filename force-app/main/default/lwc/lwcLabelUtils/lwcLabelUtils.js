const LIST_SEPARATOR = "|";

/**
 * Splits a label that holds several entries separated by "|", in display order.
 * Blank entries are dropped; the fallback is used when no entry is left.
 */
export function splitLabelList(raw, fallback) {
  if (typeof raw !== "string") {
    return [...fallback];
  }
  const entries = raw
    .split(LIST_SEPARATOR)
    .map((entry) => entry.trim())
    .filter(Boolean);
  return entries.length ? entries : [...fallback];
}
