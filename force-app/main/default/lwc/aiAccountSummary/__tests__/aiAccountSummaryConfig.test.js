import {
  resetLabels,
  setLabel
} from "../../../../../../test/jest-mocks/accountSummaryLabels";
import { positiveNumber } from "../aiAccountSummaryConfig";

function configuredModule() {
  let config;
  // Salesforce label imports are resolved once per module load.
  jest.isolateModules(() => {
    config = require("../aiAccountSummaryConfig");
  });
  return config;
}

describe("Account Summary cache configuration", () => {
  beforeEach(resetLabels);
  afterEach(resetLabels);

  it("uses the deployed defaults of one hour and 512 KiB", () => {
    expect(configuredModule().getCachePolicy()).toEqual({
      ttlMs: 3600000,
      maxBytes: 524288
    });
  });

  it("uses configured cache hours and storage size", () => {
    setLabel("CacheHours", " 2.5 ");
    setLabel("CacheMaxKB", "128");
    expect(configuredModule().getCachePolicy()).toEqual({
      ttlMs: 9000000,
      maxBytes: 131072
    });
  });

  it("falls back when cache labels are out of range or not numbers", () => {
    setLabel("CacheHours", "48");
    setLabel("CacheMaxKB", "64KB");
    expect(configuredModule().getCachePolicy()).toEqual({
      ttlMs: 3600000,
      maxBytes: 524288
    });
  });

  it("rejects units, separators and fractional sizes", () => {
    expect(positiveNumber("1,5", 1, 0, 24)).toBe(1);
    expect(positiveNumber("true", 1, 0, 24)).toBe(1);
    expect(positiveNumber("12.5", 512, 1, 512, true)).toBe(512);
    expect(positiveNumber(" 0.5 ", 1, 1 / 60, 24)).toBe(0.5);
  });
});
