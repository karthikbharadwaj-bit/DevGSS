import {
  resetLabels,
  setLabel
} from "../../../../../../test/jest-mocks/accountSummaryLabels";
import { positiveNumber } from "../aiAccountSummaryConfig";

function configuredModule(settings) {
  let config;
  // Salesforce label imports are resolved once per module load.
  jest.isolateModules(() => {
    config = require("../aiAccountSummaryConfig");
  });
  config.applyClientSettings(settings);
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

  it("falls back when cache settings are out of range or not numbers", () => {
    expect(
      configuredModule({
        CacheHours: "48",
        CacheMaxKB: "64KB"
      }).getCachePolicy()
    ).toEqual({
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

  it("shows three rows first and up to ten after View more by default", () => {
    expect(configuredModule().getListRowLimits()).toEqual({
      initialRows: 3,
      maxRows: 10
    });
  });

  it("uses configured row counts but never more than ten", () => {
    expect(
      configuredModule({
        ListRowsInitial: " 4 ",
        ListRowLimit: "25"
      }).getListRowLimits()
    ).toEqual({
      initialRows: 4,
      maxRows: 10
    });
  });

  it("never shows more rows first than after View more", () => {
    expect(
      configuredModule({
        ListRowsInitial: "8",
        ListRowLimit: "6"
      }).getListRowLimits()
    ).toEqual({
      initialRows: 6,
      maxRows: 6
    });
  });

  it("rotates through the six deployed loading lines in order", () => {
    const messages = configuredModule().getLoadingMessages();
    expect(messages).toHaveLength(6);
    expect(messages[0]).toBe(
      "Gathering account details, revenue, and licenses…"
    );
    expect(messages[5]).toBe("Almost there — assembling your account brief.");
  });

  it("uses the loading lines an admin configures", () => {
    setLabel("LoadingMessages", " Checking revenue… | Almost done. ");
    expect(configuredModule().getLoadingMessages()).toEqual([
      "Checking revenue…",
      "Almost done."
    ]);
  });

  it("falls back to the built-in loading lines when the label is blank", () => {
    setLabel("LoadingMessages", " | ");
    expect(configuredModule().getLoadingMessages()).toHaveLength(6);
  });

  it("falls back to the defaults for a zero, fraction or non-number", () => {
    ["0", "2.5", "five", ""].forEach((value) => {
      expect(
        configuredModule({
          ListRowsInitial: value,
          ListRowLimit: value
        }).getListRowLimits()
      ).toEqual({
        initialRows: 3,
        maxRows: 10
      });
    });
  });

  it("uses the defaults when the settings call returned nothing", () => {
    expect(configuredModule(null).getListRowLimits()).toEqual({
      initialRows: 3,
      maxRows: 10
    });
    expect(configuredModule("not settings").getCachePolicy()).toEqual({
      ttlMs: 3600000,
      maxBytes: 524288
    });
  });
});
