import {
  resetLabels,
  setLabel
} from "../../../../../../test/jest-mocks/opportunitySummaryLabels";
import {
  positiveNumber,
  parseResearchGroups
} from "../opportunitySummaryConfig";

function configuredModule() {
  let config;
  // Salesforce label imports are resolved once per module load.
  jest.isolateModules(() => {
    config = require("../opportunitySummaryConfig");
  });
  return config;
}

describe("Opportunity Summary label configuration", () => {
  beforeEach(resetLabels);
  afterEach(resetLabels);

  it("uses configured cache hours and storage size", () => {
    setLabel("CacheHours", " 2.5 ");
    setLabel("CacheMaxKB", "128");
    expect(configuredModule().getCachePolicy()).toEqual({
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
    setLabel("CacheHours", value);
    expect(configuredModule().getCachePolicy().ttlMs).toBe(3600000);
  });

  it.each(["0", "-1", "513", "2.5", "unlimited"])(
    "keeps the cache bounded for invalid storage size %p",
    (value) => {
      setLabel("CacheMaxKB", value);
      expect(configuredModule().getCachePolicy().maxBytes).toBe(524288);
    }
  );

  it("accepts boundaries and distinguishes whole numbers from fractions", () => {
    expect(positiveNumber("24", 1, 1 / 60, 24)).toBe(24);
    expect(positiveNumber("0.5", 1, 1 / 60, 24)).toBe(0.5);
    expect(positiveNumber("0.001", 1, 1 / 60, 24)).toBe(1);
    expect(positiveNumber("1", 512, 1, 512, true)).toBe(1);
  });

  it("adds and orders configured research kinds and excludes disabled groups", () => {
    setLabel(
      "ResearchGroups",
      JSON.stringify([
        { kind: "PRIORITY", label: "Priorities", order: 3 },
        { kind: "expansion", label: "Expansion", order: 1 },
        { kind: "leadership", label: "Leadership", active: false }
      ])
    );
    expect(configuredModule().getResearchGroups()).toEqual([
      { kind: "expansion", label: "Expansion" },
      { kind: "priority", label: "Priorities" }
    ]);
  });

  it.each([
    "not-json",
    "null",
    "{}",
    "[]",
    "[null]",
    '[{"kind":"priority","label":""}]',
    '[{"kind":"priority","label":"Priorities","active":"false"}]',
    '[{"kind":"priority","label":"Priorities","order":"1"}]',
    '[{"kind":"priority","label":"A"},{"kind":"PRIORITY","label":"B"}]',
    '[{"kind":"<script>","label":"Invalid"}]'
  ])(
    "uses the established research groups for malformed configuration %s",
    (value) => {
      expect(parseResearchGroups(value).map((group) => group.kind)).toEqual([
        "leadership",
        "priority"
      ]);
    }
  );
});
