import { focusFirstIn, focusLastIn } from "c/lwcModalFocus";

function node(tag, attributes = {}, children = []) {
  const element = document.createElement(tag);
  Object.entries(attributes).forEach(([name, value]) =>
    element.setAttribute(name, value)
  );
  element.append(...children);
  return element;
}

function dialogWith(children) {
  const dialog = node("section", { tabindex: "-1" }, children);
  document.body.appendChild(dialog);
  return dialog;
}

function fence() {
  return node("span", { "data-focus-fence": "", tabindex: "0" });
}

describe("c-lwc-modal-focus", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("focuses the first and last controls, skipping the fences", () => {
    const first = node("button", {}, ["First"]);
    const last = node("button", {}, ["Last"]);
    const dialog = dialogWith([
      fence(),
      first,
      node("a", { href: "#x" }, ["Link"]),
      last,
      fence()
    ]);

    focusFirstIn(dialog);
    expect(document.activeElement).toBe(first);
    focusLastIn(dialog);
    expect(document.activeElement).toBe(last);
  });

  it("skips disabled controls and ones inside closed details", () => {
    const first = node("button", {}, ["First"]);
    const summary = node("summary", {}, ["More"]);
    const hiddenLink = node("a", { href: "#hidden" }, ["Hidden link"]);
    const details = node("details", {}, [summary, hiddenLink]);
    const dialog = dialogWith([
      node("button", { disabled: "" }, ["Disabled"]),
      first,
      details
    ]);

    focusFirstIn(dialog);
    expect(document.activeElement).toBe(first);
    focusLastIn(dialog);
    expect(document.activeElement).toBe(summary);

    details.open = true;
    focusLastIn(dialog);
    expect(document.activeElement).toBe(hiddenLink);
  });

  it("focuses the dialog itself when it has no controls", () => {
    const dialog = dialogWith([node("p", {}, ["Text only"])]);

    focusFirstIn(dialog);
    expect(document.activeElement).toBe(dialog);
    focusLastIn(dialog);
    expect(document.activeElement).toBe(dialog);
  });

  it("does nothing without a dialog", () => {
    expect(() => focusFirstIn(null)).not.toThrow();
    expect(() => focusLastIn(undefined)).not.toThrow();
  });
});
