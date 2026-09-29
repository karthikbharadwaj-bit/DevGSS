import { resetLabels } from "../../../../../../test/jest-mocks/accountSummaryLabels";
import { getUiLabels } from "../aiAccountSummaryConfig";
import {
  buildAccountViewModel,
  buildActions,
  buildCases,
  buildFlag,
  buildTiles,
  formatDate,
  formatMoney
} from "../aiAccountSummaryModel";

const RESPONSE = require("./data/accountSummaryResponse.json");
const LOCALE = "en-US";

describe("Account Summary view model", () => {
  let labels;

  beforeEach(() => {
    resetLabels();
    labels = getUiLabels();
  });

  it("formats money with the ISO code and never a symbol", () => {
    expect(formatMoney(2910, "EUR", LOCALE)).toBe("EUR 2,910");
    expect(formatMoney(-26190, "EUR", LOCALE)).toBe("EUR -26,190");
    expect(formatMoney(null, "EUR", LOCALE)).toBe("");
  });

  it("formats ISO dates and year-month periods without shifting the day", () => {
    expect(formatDate("2026-02-27", LOCALE)).toBe("Feb 27, 2026");
    expect(formatDate("2026-06-09T23:30:00.000Z", LOCALE)).toBe("Jun 9, 2026");
    expect(formatDate("2026-05", LOCALE)).toBe("May 2026");
    expect(formatDate(null, LOCALE)).toBe("");
  });

  it("always builds five tiles in handover order and flags the amber tile", () => {
    const tiles = buildTiles(
      RESPONSE.account_summary.key_metrics,
      labels,
      LOCALE
    );
    expect(tiles.map((tile) => tile.key)).toEqual([
      "mrr",
      "mrr_trajectory",
      "total_open_pipeline",
      "open_cases",
      "licenses"
    ]);
    expect(tiles[0].value).toBe("EUR 2,910");
    expect(tiles[0].detail).toBe("EUR 34,920 annualized");
    expect(tiles[1].value).toBe("-25.2%");
    expect(tiles[1].valueClass).toContain("tile-value_negative");
    expect(tiles[3].tileClass).toBe("tile tile_amber");
    expect(tiles[4].value).toBe("105 / 72");
  });

  it("shows the not-recorded label for missing tiles and never zero", () => {
    const tiles = buildTiles({ tiles: [] }, labels, LOCALE);
    tiles.forEach((tile) => {
      expect(tile.value).toBe(labels.notRecorded);
      expect(tile.valueClass).toContain("tile-value_nil");
    });
  });

  it("keeps a real zero instead of hiding it", () => {
    const tiles = buildTiles(
      { tiles: [{ key: "open_cases", value: 0 }] },
      labels,
      LOCALE
    );
    expect(tiles[3].value).toBe("0");
  });

  it("uses the mixed-currency text when the pipeline has no single total", () => {
    const tiles = buildTiles(
      {
        tiles: [
          { key: "total_open_pipeline", value: null, currency_mixed: true }
        ]
      },
      labels,
      LOCALE
    );
    expect(tiles[2].value).toBe(labels.tilePipelineMixed);
  });

  it("builds the flag dial, override callout and weakest bars", () => {
    const flag = buildFlag(
      RESPONSE.account_summary.account_flag,
      labels,
      LOCALE
    );
    expect(flag.score).toBe("72");
    expect(flag.dialClass).toBe("dial-value dial-value_amber");
    expect(flag.hasOverride).toBe(true);
    expect(flag.overrideTitle).toBe("Amber — set by override");
    expect(flag.overrideExplanation).toContain("<strong>122 days</strong>");
    expect(flag.bars[0].barClass).toBe("bar bar_weak");
    expect(flag.bars[0].fillClass).toBe("bar-fill bar-fill_bad");
    expect(flag.bars[1].fillClass).toBe("bar-fill");
    expect(flag.amberFloor).toBe("Amber floor from Sep 27, 2026");
  });

  it("leaves the override callout out when no override set the band", () => {
    const flag = buildFlag(
      { score: 85, band: "Green", override_reason: null },
      labels,
      LOCALE
    );
    expect(flag.hasOverride).toBe(false);
    expect(flag.dialClass).toBe("dial-value dial-value_green");
  });

  it("maps action timing chips and widens an odd last card", () => {
    const actions = buildActions(
      RESPONSE.account_summary.recommended_actions,
      labels
    );
    expect(actions.map((action) => action.whenLabel)).toEqual([
      "Today",
      "This week",
      "Post-close"
    ]);
    expect(actions[0].chipClass).toBe("chip chip_red");
    expect(actions[2].laneLabel).toBe("Service");
    expect(actions[2].cardClass).toBe("action action_wide");
  });

  it("ranks every top-priority naming scheme as critical", () => {
    const cases = buildCases(
      {
        open: [
          { id: "1", priority: "P0" },
          { id: "2", priority: "1 – Critical" },
          { id: "3", priority: "Medium" }
        ]
      },
      labels,
      LOCALE
    );
    expect(cases.open.map((row) => row.priorityClass)).toEqual([
      "chip chip_red",
      "chip chip_red",
      "chip chip_grey"
    ]);
  });

  it("builds every section and drops unsafe research links", () => {
    const view = buildAccountViewModel(RESPONSE, labels, LOCALE);
    expect(view.asOfLabel).toBe("As of Jun 29, 2026");
    expect(view.header.narrative).toHaveLength(2);
    expect(
      view.header.rows.find((row) => row.key === "rating").valueClass
    ).toBe("nil");
    expect(view.opportunities.rows[0].url).toBe("/006TH0000000001AAA");
    expect(view.opportunities.rows[0].nextStepDisplay).toBe(
      "no Next Step recorded"
    );
    expect(view.cases.closedHeading).toBe("Recently closed · 7 in six months");
    expect(view.contacts.contacts[1].role).toBe("Signatory");
    expect(view.contacts.contacts[1].lastActivity).toBe(labels.notRecorded);
    expect(view.history[0].periodLabel).toBe("Open now");
    expect(view.history[1].events[0].chip).toBe("Won · EUR 2,100");
    expect(view.research.sources).toHaveLength(1);
    expect(view.research.sources[0].url).toBe("https://news.example/story");
  });

  it("tolerates a summary with every section missing", () => {
    const view = buildAccountViewModel({ account_summary: {} }, labels, LOCALE);
    expect(view.tiles).toHaveLength(5);
    expect(view.actions).toEqual([]);
    expect(view.flag.hasScore).toBe(false);
    expect(view.research.hasResearch).toBe(false);
  });
});
