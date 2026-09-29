import { resetLabels } from "../../../../../../test/jest-mocks/accountSummaryLabels";
import { formatLabel, getUiLabels } from "../aiAccountSummaryConfig";
import {
  buildAccountViewModel,
  buildActions,
  buildCases,
  buildContacts,
  buildFlag,
  buildHeader,
  buildTiles,
  extractEvidence,
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

  it("formats labels with several placeholders", () => {
    expect(formatLabel("{0} won of the last {1} closed", 4, 15)).toBe(
      "4 won of the last 15 closed"
    );
    expect(formatLabel("{0} and {2}", "a")).toBe("a and {2}");
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

  it("keeps the five service tiles in handover order when all have values", () => {
    const tiles = buildTiles(
      RESPONSE.account_summary.key_metrics,
      RESPONSE.derived_metrics,
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
    expect(tiles[1].value).toBe("-25.2%");
    expect(tiles[1].valueClass).toContain("tile-value_negative");
    expect(tiles[3].tileClass).toBe("tile tile_amber");
    expect(tiles[4].value).toBe("105 / 72");
  });

  it("replaces tiles without a value with computed metrics", () => {
    const tiles = buildTiles(
      {
        tiles: [
          { key: "mrr", value: null },
          { key: "total_open_pipeline", value: 93250, currencyIsoCode: "USD" },
          { key: "open_cases", value: 0 }
        ]
      },
      RESPONSE.derived_metrics,
      labels,
      LOCALE
    );
    expect(tiles.map((tile) => tile.key)).toEqual([
      "total_open_pipeline",
      "open_cases",
      "days_to_renewal",
      "days_since_meaningful_activity",
      "closed_won_total"
    ]);
    expect(tiles[1].value).toBe("0");
    expect(tiles[4].value).toBe("EUR 42,000");
    expect(tiles[4].detail).toBe("4 won of the last 15 closed");
    tiles.forEach((tile) => expect(tile.value).not.toBe(labels.notRecorded));
  });

  it("skips replacement metrics that have no source records", () => {
    const tiles = buildTiles(
      { tiles: [] },
      {
        days_to_renewal: null,
        closed_won_total: 0,
        closed_opportunity_sample_size: 0,
        next_step_missing_count: 0,
        open_opp_count: 0,
        lifetime_escalation_count: 0
      },
      labels,
      LOCALE
    );
    expect(tiles.map((tile) => tile.key)).toEqual([
      "lifetime_escalation_count"
    ]);
  });

  it("flags a renewal inside 30 days and a going-cold account", () => {
    const tiles = buildTiles(
      { tiles: [] },
      {
        days_to_renewal: 12,
        days_since_meaningful_activity: 95,
        going_cold: true
      },
      labels,
      LOCALE
    );
    expect(tiles[0].tileClass).toBe("tile tile_amber");
    expect(tiles[1].detail).toBe(labels.tileGoingCold);
  });

  it("drops header rows with no recorded value", () => {
    const header = buildHeader(
      RESPONSE.account_summary.account_header,
      labels,
      LOCALE
    );
    const keys = header.rows.map((row) => row.key);
    expect(keys).toContain("account");
    expect(keys).not.toContain("rating");
    expect(keys).not.toContain("source");
  });

  it("drops empty contact titles, roles and activity", () => {
    const contacts = buildContacts(
      RESPONSE.account_summary.key_contacts,
      labels
    );
    expect(contacts.contacts[1].title).toBe("");
    expect(contacts.contacts[1].lastActivity).toBe("");
    expect(contacts.contacts[0].role).toBe("");
  });

  it("lifts known evidence ids out of prose and leaves unknown ones", () => {
    const findingById = new Map([["E1", {}]]);
    expect(
      extractEvidence("Opened a depot [E1] and [E9].", findingById)
    ).toEqual({ text: "Opened a depot and [E9].", ids: ["E1"] });
    expect(extractEvidence("Public web [E1]", findingById)).toEqual({
      text: "Public web",
      ids: ["E1"]
    });
  });

  it("leaves out signals the service marks as not recorded in Salesforce", () => {
    const view = buildAccountViewModel(RESPONSE, labels, LOCALE);
    expect(view.risks.map((risk) => risk.title)).not.toContain(
      "Renewal timing unavailable"
    );
    const depot = view.growth.find(
      (item) => item.title === "New depot opening"
    );
    expect(depot.evidence.map((evidence) => evidence.id)).toEqual(["E1"]);
    expect(depot.source).toBe("Public web");
    expect(depot.detail).toBe("Public reporting notes a new depot.");
    expect(depot.evidence[0].ariaLabel).toBe(
      "View public research evidence E1"
    );
  });

  it("builds the flag dial, override callout and weakest bars", () => {
    const flag = buildFlag(
      RESPONSE.account_summary.account_flag,
      labels,
      LOCALE
    );
    expect(flag.score).toBe("72");
    expect(flag.dialClass).toBe("dial-value dial-value_amber");
    expect(flag.overrideTitle).toBe("Amber — set by override");
    expect(flag.overrideExplanation).toContain("<strong>122 days</strong>");
    expect(flag.bars[0].barClass).toBe("bar bar_weak");
    expect(flag.amberFloor).toBe("Amber floor from Sep 27, 2026");
  });

  it("maps action timing chips", () => {
    const actions = buildActions(
      RESPONSE.account_summary.recommended_actions,
      labels
    );
    expect(actions.map((action) => action.whenLabel)).toEqual([
      "Today",
      "This week",
      "Post-close"
    ]);
    expect(actions[2].laneLabel).toBe("Service");
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

  it("links cited findings to the publisher article when it was resolved", () => {
    const view = buildAccountViewModel(RESPONSE, labels, LOCALE);
    const [depot, cfo] = view.research.findings;
    expect(view.research.summary).toBe(
      "Public web research · 2 cited · 1 additional"
    );
    expect(depot.kind).toBe("Business event");
    expect(depot.sources).toEqual([
      {
        key: "finding-E1-source-1",
        url: "https://www.news.example/2026/05/depot",
        label: "www.news.example"
      }
    ]);
    expect(cfo.meta).toBe("Dana Reyes · CFO · Apr 1, 2026");
  });

  it("lists uncited findings as additional, without repeating cited ones", () => {
    const view = buildAccountViewModel(RESPONSE, labels, LOCALE);
    expect(view.research.hasAdditional).toBe(true);
    expect(view.research.additional.map((finding) => finding.id)).toEqual([
      "E3"
    ]);
    expect(view.research.additionalHeading).toBe("Additional findings · 1");
  });

  it("reads per-finding sources and falls back to the redirect link", () => {
    const view = buildAccountViewModel(RESPONSE, labels, LOCALE);
    expect(view.research.additional[0].sources).toEqual([
      {
        key: "finding-E3-source-0",
        url: "https://vertexaisearch.cloud.google.com/grounding-api-redirect/abc",
        label: "Markets"
      }
    ]);
  });

  it("shows the drawer when only additional findings exist", () => {
    const view = buildAccountViewModel(
      {
        account_summary: {},
        account_enrichment: {
          findings: [],
          supplemental_findings: [{ id: "E4", fact: "Opened an office." }]
        }
      },
      labels,
      LOCALE
    );
    expect(view.research.hasResearch).toBe(true);
    expect(view.research.hasCited).toBe(false);
  });

  it("writes the next step with its label and hides a missing one", () => {
    const view = buildAccountViewModel(RESPONSE, labels, LOCALE);
    expect(view.opportunities.rows[0].nextStep).toBe("");
    const withStep = buildAccountViewModel(
      {
        account_summary: {
          open_opportunities: { rows: [{ id: "006", next_step: "Call CFO" }] }
        }
      },
      labels,
      LOCALE
    );
    expect(withStep.opportunities.rows[0].nextStep).toBe("Next step: Call CFO");
  });

  it("tolerates a summary with every section missing", () => {
    const view = buildAccountViewModel({ account_summary: {} }, labels, LOCALE);
    expect(view.tiles).toEqual([]);
    expect(view.header.rows).toEqual([]);
    expect(view.flag.hasScore).toBe(false);
    expect(view.research.hasResearch).toBe(false);
  });
});
