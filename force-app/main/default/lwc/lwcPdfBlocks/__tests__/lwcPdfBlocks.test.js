import {
  HEADING_PART,
  keepHeadingWithContent,
  pdfText,
  plainText,
  safeLink
} from "c/lwcPdfBlocks";

describe("c-lwc-pdf-blocks", () => {
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
