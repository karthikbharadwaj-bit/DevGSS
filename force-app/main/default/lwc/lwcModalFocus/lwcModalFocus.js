const FOCUSABLE_SELECTOR = [
  "a[href]",
  "button:not([disabled])",
  "input:not([disabled])",
  "select:not([disabled])",
  "textarea:not([disabled])",
  "summary",
  '[tabindex]:not([tabindex="-1"])'
].join(",");
const FENCE_ATTRIBUTE = "data-focus-fence";

/* A control inside a closed <details> cannot take focus; the details' own summary can. */
function isReachable(element) {
  for (let node = element.parentElement; node; node = node.parentElement) {
    const isOwnSummary =
      element.tagName === "SUMMARY" && element.parentElement === node;
    if (node.tagName === "DETAILS" && !node.open && !isOwnSummary) {
      return false;
    }
  }
  return true;
}

function focusableElements(dialog) {
  return [...dialog.querySelectorAll(FOCUSABLE_SELECTOR)].filter(
    (element) => !element.hasAttribute(FENCE_ATTRIBUTE) && isReachable(element)
  );
}

/**
 * Focuses the first control in a custom modal dialog, or the dialog itself when it has none.
 * Call when the dialog opens, and from the fence after its last control so Tab wraps.
 */
export function focusFirstIn(dialog) {
  if (!dialog) {
    return;
  }
  const [first] = focusableElements(dialog);
  (first || dialog).focus();
}

/**
 * Focuses the last control in a custom modal dialog. Call from the fence before its first
 * control so Shift+Tab wraps.
 */
export function focusLastIn(dialog) {
  if (!dialog) {
    return;
  }
  const elements = focusableElements(dialog);
  (elements[elements.length - 1] || dialog).focus();
}
