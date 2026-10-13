import { splitLabelList } from "c/lwcLabelUtils";

const FALLBACK = ["First", "Second"];

describe("c-lwc-label-utils", () => {
  it("splits on | in order and trims each entry", () => {
    expect(splitLabelList(" One… | Two — done |Three ", FALLBACK)).toEqual([
      "One…",
      "Two — done",
      "Three"
    ]);
  });

  it("drops blank entries", () => {
    expect(splitLabelList("One||  | Two |", FALLBACK)).toEqual(["One", "Two"]);
  });

  it("keeps a single entry without separators", () => {
    expect(splitLabelList("Only one", FALLBACK)).toEqual(["Only one"]);
  });

  it("uses the fallback when nothing usable is left", () => {
    expect(splitLabelList(" | ", FALLBACK)).toEqual(FALLBACK);
    expect(splitLabelList("", FALLBACK)).toEqual(FALLBACK);
    expect(splitLabelList(undefined, FALLBACK)).toEqual(FALLBACK);
  });

  it("returns a copy of the fallback", () => {
    const result = splitLabelList(undefined, FALLBACK);
    result.push("Third");
    expect(FALLBACK).toEqual(["First", "Second"]);
  });
});
