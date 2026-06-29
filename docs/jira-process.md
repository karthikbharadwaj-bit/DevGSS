# RingCentral GCI — JIRA Ticketing & Deployment Process

## 1. Ticket types → how they're split
| Ticket type | How tickets are split |
|---|---|
| **Bug** | One ticket covers deployment + testing. |
| **User Story** | Separate tickets per environment — one deployment + one testing — for each of GCI and BisUAT. |
| **Task** | One individual ticket for dev/testing. |

## 2. Issue hierarchy — check this first
A work item is usually a **parent ticket** (the real dev work) with **child utility tickets** that only track per-environment deployment and testing. Always map the parent/child links before you act or comment — don't treat them as flat peers.

```
Parent (Bug / Story)  ── the dev work, reviews, analysis        ← YOURS
├─ GCI Deployment        (Task)     ← yours
├─ GCI Testing           (QA Task)  ← QA's
├─ BisUAT Deployment     (Task)     ← yours
├─ BisUAT Testing        (QA Task)  ← QA's
└─ Production Deployment (Task)     ← yours
```
QA testing children won't show up in your `assignee = me` view — they're QA-owned. Track them for sequencing, don't comment on them.

## 3. The full lifecycle (in order)
**Phase 1 — Dev (in the DevGSS dev sandbox)**
1. Dev + unit testing — complete locally.
2. Push to feature branch → `feature/GCI_<TicketNumber>`.
3. Code review — 2 levels: 1× fellow developer + 1× scrum master.
4. Mark the parent (dev) ticket **Resolved** — only after both reviews pass.
5. **QA sign-off in the dev sandbox** — QA tests the change in DevGSS and posts a **sign-off comment on the dev ticket**. Required *before* any GCI deployment.
6. **Move the dev ticket → `Closed`** once the QA sign-off comment is present.

⛔ **Dev-ticket gate (read this carefully):** the deployment & testing child tickets are **NOT actionable until the parent dev ticket is `Closed`**. While the dev ticket is anything below Closed (e.g. `Resolved`), there is **nothing to do** on the GCI/BisUAT/Prod tickets. The only actionable move is: read the dev ticket's comments for the QA/testing-team **sign-off** →
- **Sign-off present** (and dev ticket still `Resolved`) → recommend moving the dev ticket to `Closed` and starting the **GCI deployment** ticket.
- **No sign-off yet** → the dev ticket is waiting on QA sign-off in the dev sandbox; still nothing to do downstream.

**Phase 2 — GCI** (only after the dev ticket is `Closed`)
7. Deploy to GCI (book the merge slot in CET; deploy team confirms when done).
8. GCI testing / QA sign-off — GCI "acceptance" (daily QA automation build must pass) before you can promote.
9. Create CMR for the BisUAT deployment.

**Phase 3 — BisUAT**
10. Deploy to BisUAT.
11. BisUAT QA sign-off / business UAT.
12. Create CMR for the Production deployment.

**Phase 4 — Production**
13. Prod deployment → go-live.

🔑 **Promotion gate (repeats per env):** Deploy → QA sign-off → CMR → deploy to next env. **CMR is required only for BisUAT and Prod** (higher environments) — GCI needs no CMR.

## 4. Comments — golden rule
Write a comment on every ticket you own, matching its place in the hierarchy and phase.
- **Parent ticket** → the substantive daily update (progress, changes, doc links, review/test status).
- **Child deployment tickets** → short status-only notes (e.g. "Deployed to GCI, awaiting QA acceptance").
- By type:
  - **Analysis:** "Analysis in progress" → "Analysis done" + doc link → "done, picking up dev ticket" + re-share final doc.
  - **Dev:** "Dev in progress" + unit-test / env-setup / related docs.
  - **Big ticket:** progress + changes made + linked docs.

## 5. Quick "if X → do Y" cheat sheet
- **Starting analysis?** → Create analysis doc, comment daily, link it.
- **Analysis done?** → "Done + picking up dev ticket" + re-link final doc.
- **Starting dev?** → Set parent to In Progress, comment progress + link docs.
- **Dev + unit tests done?** → Push to `feature/GCI_<ticket#>`.
- **Branch pushed?** → Get dev review + scrum master review.
- **Both reviews done?** → Mark parent **Resolved** → QA tests in the dev sandbox.
- **Dev ticket Resolved but not Closed?** → Check its comments for a QA sign-off. None → waiting on QA (nothing to do on deployment tickets). Present → move dev ticket to **Closed**, then start the **GCI deployment** ticket.
- **Dev ticket not Closed?** → Deployment/testing children have **nothing to do** yet (gated on the dev ticket being Closed).
- **Deployed to GCI?** → QA/unit test in GCI → get GCI acceptance → CMR → deploy to BisUAT.
- **BisUAT signed off?** → CMR → Prod deployment → go-live.
- **Any ticket you own?** → Leave a comment reflecting hierarchy position + current phase.
