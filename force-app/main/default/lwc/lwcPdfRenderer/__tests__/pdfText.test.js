import { toPdfDefinition, toPdfText } from "../pdfText";

describe("PDF text clean-up", () => {
  it("keeps a time and its AM or PM together with a no-break space the font can draw", () => {
    expect(toPdfText("Sep 16, 2026 7:38\u202FAM PDT")).toBe(
      "Sep 16, 2026 7:38\u00A0AM PDT"
    );
  });

  it("turns thin, hair and other Unicode spaces into ordinary spaces", () => {
    expect(toPdfText("7:38\u00A0AM\u2009PDT and 10:02\u00A0PM\u200APDT")).toBe(
      "7:38\u00A0AM PDT and 10:02\u00A0PM PDT"
    );
    expect(toPdfText("a\u2002b\u2007c\u205Fd\u3000e")).toBe("a b c d e");
  });

  it("drops invisible marks and spells out the arrow", () => {
    expect(toPdfText("\uFEFFQualify\u200B \u2192 Problem\u200E\u2060")).toBe(
      "Qualify -> Problem"
    );
  });

  it("leaves ordinary text, accents and other scripts unchanged", () => {
    const text = "Acme — München / Αθήνα / Москва, “quoted” … 2–3";
    expect(toPdfText(text)).toBe(text);
    expect(toPdfText(42)).toBe(42);
    expect(toPdfText(null)).toBeNull();
  });

  it("cleans every string in a definition, including content built by header and footer functions", () => {
    const image = { image: "data:image/png;base64,AAAA", width: 10 };
    const definition = {
      info: { title: "Deal\u202FBrief" },
      content: [
        "7:38\u202FAM",
        { text: ["at ", { text: "10:02\u202FPM\u2009PDT", bold: true }] },
        { table: { body: [["Stage\u2192Next"]] } },
        image
      ],
      footer: (page, count) => ({ text: `Page\u202F${page} of ${count}` }),
      pageMargins: [40, 40, 40, 40]
    };

    const cleaned = toPdfDefinition(definition);

    expect(cleaned.info.title).toBe("Deal\u00A0Brief");
    expect(cleaned.content[0]).toBe("7:38\u00A0AM");
    expect(cleaned.content[1].text[1]).toEqual({
      text: "10:02\u00A0PM PDT",
      bold: true
    });
    expect(cleaned.content[2].table.body[0][0]).toBe("Stage->Next");
    expect(cleaned.content[3]).toEqual(image);
    expect(cleaned.footer(2, 4)).toEqual({ text: "Page\u00A02 of 4" });
    expect(cleaned.pageMargins).toEqual([40, 40, 40, 40]);
    expect(definition.content[0]).toBe("7:38\u202FAM");
  });

  it("keeps the parameter count of wrapped functions so pdfmake still passes pageBreakBefore the following nodes", () => {
    const pageBreakBefore = (node, followingNodes) =>
      node.headlineLevel === 1 && followingNodes.length === 0;

    const cleaned = toPdfDefinition({ pageBreakBefore });

    expect(cleaned.pageBreakBefore).toHaveLength(2);
    expect(cleaned.pageBreakBefore({ headlineLevel: 1 }, [{ text: "x" }])).toBe(
      false
    );
  });
});
