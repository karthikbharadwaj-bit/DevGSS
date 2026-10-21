import {
  HEADING_PART,
  callIconLegend,
  keepHeadingWithContent,
  pdfText,
  plainText,
  safeLink,
  withCallIcon
} from "c/lwcPdfBlocks";

describe("c-lwc-pdf-blocks", () => {
  it("leaves an item unchanged unless it came from a call", () => {
    const item = { text: "Budget confirmed", margin: [0, 0, 0, 8] };

    expect(withCallIcon(item, false)).toBe(item);
    expect(withCallIcon(item, undefined)).toBe(item);
  });

  it("puts the call icon beside a call-sourced item and keeps its spacing", () => {
    const node = withCallIcon(
      { text: "Budget confirmed", margin: [0, 0, 0, 8] },
      true
    );

    expect(node.margin).toEqual([0, 0, 0, 8]);
    expect(node.columns[0]).toEqual({ text: "Budget confirmed", width: "*" });
    expect(node.columns[1].svg).toContain("<path");
  });

  it("explains the call icon in a legend", () => {
    const legend = callIconLegend("From a recorded customer call");

    expect(legend.columns[0].svg).toContain("<path");
    expect(legend.columns[1].text).toBe("From a recorded customer call");
  });

  it("links only evidence markers that have a research anchor", () => {
    const runs = pdfText("<b>Win</b> [E1] [E9]", new Set(["E1"]));

    expect(runs[0]).toMatchObject({ text: "Win", bold: true });
    expect(runs.find((run) => run.text === "[E1]").linkToDestination).toBe(
      "research-E1"
    );
    expect(
      runs.find((run) => run.text === "[E9]").linkToDestination
    ).toBeUndefined();
  });

  it("applies the caller's text normalisation to decoded text", () => {
    const upper = (text) => text.toUpperCase();

    expect(plainText("a &amp; b", upper)).toBe("A & B");
  });

  it("resolves relative links against a base and rejects other schemes", () => {
    expect(safeLink("/001xx", "https://example.my.salesforce.com")).toBe(
      "https://example.my.salesforce.com/001xx"
    );
    expect(safeLink("/001xx")).toBeNull();
    expect(safeLink("ftp://example.com/file")).toBeNull();
    expect(safeLink("https://user:pass@example.com")).toBeNull();
  });

  it("declares two parameters so pdfmake passes the following nodes", () => {
    expect(keepHeadingWithContent).toHaveLength(2);
  });

  it("moves a heading on when only heading parts follow it on the page", () => {
    const heading = { headlineLevel: 1, startPosition: { top: 700 } };

    expect(
      keepHeadingWithContent(heading, [
        { headlineLevel: HEADING_PART, text: "Title" }
      ])
    ).toBe(true);
    expect(
      keepHeadingWithContent(heading, [
        { text: "Body", startPosition: { top: 720 } }
      ])
    ).toBe(false);
  });
});
