import { splitLabel } from "c/opportunitySummary";

describe("splitLabel", () => {
  it("splits on an eligible em dash", () => {
    expect(splitLabel("Now — Work with Shubham Prabhakar")).toEqual({
      label: "Now",
      text: "Work with Shubham Prabhakar",
      hasLabel: true
    });
  });

  it("uses only the first em dash", () => {
    expect(
      splitLabel("Next — Update the opportunity — after approval")
    ).toEqual({
      label: "Next",
      text: "Update the opportunity — after approval",
      hasLabel: true
    });
  });

  it("ignores an em dash after the label length limit", () => {
    const text = `${"Long prose ".repeat(5)}— remains prose`;

    expect(splitLabel(text)).toEqual({
      label: "",
      text,
      hasLabel: false
    });
  });

  it("preserves colon parsing", () => {
    expect(splitLabel("Owner: Eric Anderson")).toEqual({
      label: "Owner",
      text: "Eric Anderson",
      hasLabel: true
    });
  });
});
