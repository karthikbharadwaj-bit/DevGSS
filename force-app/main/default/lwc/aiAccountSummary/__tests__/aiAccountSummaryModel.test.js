import { resetLabels } from "../../../../../../test/jest-mocks/accountSummaryLabels";
import { formatLabel, getUiLabels } from "../aiAccountSummaryConfig";
import {
  buildAccountViewModel,
  buildActions,
  buildCases,
  buildContacts,
  buildFlag,
  buildHeader,
  buildOpportunities,
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

  it("shows the five account executive tiles in handover order", () => {
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
    expect(tiles[3].detail).toBe("Critical · oldest 20 days · not escalated");
    expect(tiles[4].value).toBe("105 / 72");
  });

  it("counts escalated open cases on the open cases tile", () => {
    const tile = buildTiles(
      { tiles: [{ key: "open_cases", value: 3, escalated_count: 2 }] },
      labels,
      LOCALE
    ).find((item) => item.key === "open_cases");
    expect(tile.detail).toBe("2 escalated");
  });

  it("always shows all five tiles and marks the ones without a value", () => {
    const tiles = buildTiles(
      {
        tiles: [
          { key: "mrr", value: null },
          { key: "total_open_pipeline", value: 93250, currencyIsoCode: "USD" },
          { key: "open_cases", value: 0 }
        ]
      },
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
    [tiles[0], tiles[1], tiles[4]].forEach((tile) => {
      expect(tile.value).toBe("—");
      expect(tile.detail).toBe("No value in Salesforce");
      expect(tile.valueClass).toBe("tile-value tile-value_empty");
    });
    expect(tiles[3].value).toBe("0");
  });

  it("shows five empty tiles when the service sends no key metrics", () => {
    const tiles = buildTiles(undefined, labels, LOCALE);
    expect(tiles).toHaveLength(5);
    tiles.forEach((tile) => expect(tile.value).toBe("—"));
  });

  it("shows every header row and marks the empty ones", () => {
    const header = buildHeader(
      RESPONSE.account_summary.account_header,
      labels,
      LOCALE
    );
    expect(header.rows.map((row) => row.key)).toEqual([
      "account",
      "industry",
      "location",
      "type",
      "tier",
      "owner",
      "csm",
      "since",
      "rating",
      "source"
    ]);
    const keyToRow = new Map(header.rows.map((row) => [row.key, row]));
    ["rating", "source"].forEach((key) => {
      expect(keyToRow.get(key).value).toBe("—");
      expect(keyToRow.get(key).valueClass).toBe("value_empty");
    });
    expect(keyToRow.get("account").valueClass).toBe("");
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
    expect(depot.source).toBeUndefined();
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
    expect(view.tiles).toHaveLength(5);
    expect(view.header.rows).toEqual([]);
    expect(view.flag.hasScore).toBe(false);
    expect(view.research.hasResearch).toBe(false);
  });

  it("keeps the opportunities closing soonest, up to the row limit", () => {
    const rows = [
      "2026-12-01",
      "2026-03-01",
      null,
      "2026-11-01",
      "2026-01-15",
      "2027-02-01",
      "2026-06-30"
    ].map((closeDate, index) => ({
      id: `006-${index}`,
      name: `Deal ${index}`,
      close_date: closeDate
    }));
    const opportunities = buildOpportunities({ rows }, labels, LOCALE, 5);
    expect(opportunities.rows.map((row) => row.name)).toEqual([
      "Deal 4",
      "Deal 1",
      "Deal 6",
      "Deal 3",
      "Deal 0"
    ]);
    expect(opportunities.totalCount).toBe(7);
  });

  it("keeps the newest open and closed cases, up to the row limit", () => {
    const open = [1, 2, 3, 4].map((day) => ({
      id: `500-open-${day}`,
      subject: `Open ${day}`,
      created_date: `2026-09-0${day}T09:00:00.000Z`
    }));
    const recentlyClosed = [5, 9, 7].map((day) => ({
      id: `500-closed-${day}`,
      subject: `Closed ${day}`,
      closed_date: `2026-08-0${day}T09:00:00.000Z`
    }));
    const cases = buildCases(
      { open, recently_closed: recentlyClosed, recently_closed_count: 12 },
      labels,
      LOCALE,
      2
    );
    expect(cases.open.map((row) => row.subject)).toEqual(["Open 4", "Open 3"]);
    expect(cases.closed.map((row) => row.subject)).toEqual([
      "Closed 9",
      "Closed 7"
    ]);
    expect(cases.openHeading).toBe(formatLabel(labels.openCasesHeading, 4));
    expect(cases.openTotal).toBe(4);
    expect(cases.closedTotal).toBe(12);
  });
});
