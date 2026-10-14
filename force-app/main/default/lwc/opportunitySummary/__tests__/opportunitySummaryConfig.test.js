import {
  resetLabels,
  setLabel
} from "../../../../../../test/jest-mocks/opportunitySummaryLabels";
import { positiveNumber } from "../opportunitySummaryConfig";

function configuredModule(settings) {
  let config;
  // Salesforce label imports are resolved once per module load.
  jest.isolateModules(() => {
    config = require("../opportunitySummaryConfig");
  });
  config.applyClientSettings(settings);
  return config;
}

describe("Opportunity Summary configuration", () => {
  beforeEach(resetLabels);
  afterEach(resetLabels);

  it("uses configured cache hours and storage size", () => {
    expect(
      configuredModule({
        CacheHours: " 2.5 ",
        CacheMaxKB: "128"
      }).getCachePolicy()
    ).toEqual({
      ttlMs: 9000000,
      maxBytes: 131072
    });
  });

  it.each([
    "",
    " ",
    "-1",
    "0",
    "NaN",
    "Infinity",
    "1 hour",
    "1,5",
    "25",
    "1e2",
    null,
    true
  ])("falls back for invalid cache hours %p", (value) => {
    expect(configuredModule({ CacheHours: value }).getCachePolicy().ttlMs).toBe(
      3600000
    );
  });

  it.each(["0", "-1", "513", "2.5", "unlimited"])(
    "keeps the cache bounded for invalid storage size %p",
    (value) => {
      expect(
        configuredModule({ CacheMaxKB: value }).getCachePolicy().maxBytes
      ).toBe(524288);
    }
  );

  it("accepts boundaries and distinguishes whole numbers from fractions", () => {
    expect(positiveNumber("24", 1, 1 / 60, 24)).toBe(24);
    expect(positiveNumber("0.5", 1, 1 / 60, 24)).toBe(0.5);
    expect(positiveNumber("0.001", 1, 1 / 60, 24)).toBe(1);
    expect(positiveNumber("1", 512, 1, 512, true)).toBe(1);
  });

  it("rotates through the eight deployed loading lines in order", () => {
    const messages = configuredModule().getLoadingMessages();
    expect(messages).toHaveLength(8);
    expect(messages[0]).toBe(
      "Gathering opportunity details and stage history…"
    );
    expect(messages[7]).toBe(
      "Almost there — assembling your decision-ready summary."
    );
  });

  it("uses the loading lines an admin configures", () => {
    setLabel("LoadingMessages", " Checking the deal… | Almost done. ");
    expect(configuredModule().getLoadingMessages()).toEqual([
      "Checking the deal…",
      "Almost done."
    ]);
  });

  it("falls back to the built-in loading lines when the label is blank", () => {
    setLabel("LoadingMessages", "");
    expect(configuredModule().getLoadingMessages()).toHaveLength(8);
  });

  it("uses the deployed cache defaults when no settings arrived", () => {
    expect(configuredModule(null).getCachePolicy()).toEqual({
      ttlMs: 3600000,
      maxBytes: 524288
    });
  });

  it("shows leadership then priority research under the heading labels", () => {
    setLabel("ResearchLeadership", "Leaders");
    setLabel("ResearchPriority", "Priorities");
    expect(configuredModule().getResearchGroups()).toEqual([
      { kind: "leadership", label: "Leaders" },
      { kind: "priority", label: "Priorities" }
    ]);
  });

  it("returns copies so callers cannot change the research groups", () => {
    const config = configuredModule();
    config.getResearchGroups()[0].label = "Changed";
    expect(config.getResearchGroups()[0].label).toBe("Current Leadership");
  });
});
