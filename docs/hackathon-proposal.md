# Hackathon Proposal — "Spec2Build"
### An agentic pipeline that turns a business requirement into a working Salesforce change

> *Working title — alternatives: "Req2Release", "BRD-to-Build", "AutoDeliver". Pick whichever lands best.*

---

## TL;DR (the elevator pitch)
Today a developer reads a business requirement, hunts through documents to understand it, then hand-writes code across many parts of Salesforce, tests it, and updates the tracking ticket. **Spec2Build does that end-to-end with a team of AI agents.** You hand it the requirement; it researches the supporting documents, plans the work, makes the changes across every Salesforce layer, tests them, and writes the ticket update — leaving a developer to *review and approve* instead of *build from scratch*.

**The goal isn't the JIRA comment. The goal is building the actual functionality from nothing but the business/functional requirement.**

---

## 1. The problem (in plain terms)
A "Salesforce change" is rarely one thing. A single business ask — say *"send a survey when a support case is closed"* — usually touches **several different building blocks**:
- **Screens** users see (built with technologies called LWC, Aura, or Visualforce),
- **Back-end logic** that runs automatically (called Apex code and triggers),
- **No-code automation** (called Flows),
- **Data structure** (objects, fields, rules).

Think of it like renovating a house: one request ("add a bathroom") needs a plumber, an electrician, a carpenter, and a tiler — each a specialist. Today, **one developer plays all those roles**, and before they can even start they have to:
1. Decode the business requirement,
2. Dig through Confluence/Drive for the functional & technical documents,
3. Understand the existing code,
4. Build across every layer,
5. Write tests,
6. Keep the JIRA ticket updated through a multi-stage process.

This is slow, inconsistent between developers, and a steep learning curve for anyone new.

## 2. The idea
**A coordinated team of AI agents that takes a requirement and produces a review-ready Salesforce implementation.** Instead of one giant AI trying to do everything, we use **specialists** — exactly like a real engineering team — each owning one layer, coordinated by a lead agent.

## 3. How it works (the pipeline)

```
   ┌─────────────────────────────────────────────────────────────────────┐
   │  INPUT: an Epic / Story / Bug  →  the business / functional ask        │
   └─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
   ① RESEARCH AGENT  ── searches Confluence + Google Drive for the
      functional & technical docs tied to the requirement, reads the
      existing Salesforce codebase, and builds a clear "what needs to change" brief.
                                  │
                                  ▼
   ② PLANNER / ORCHESTRATOR  ── turns the brief into a concrete work plan
      and splits it across the right specialists.
                                  │
        ┌──────────────┬─────────┴───────────┬───────────────┐
        ▼              ▼                     ▼               ▼
   ③ UI AGENT     APEX AGENT          AUTOMATION AGENT   DATA/CONFIG AGENT
     (LWC/Aura/    (classes,           (Flows, validation  (objects, fields,
      Visualforce)  triggers, tests)    rules)             permissions)
        └──────────────┴─────────┬───────────┴───────────────┘
                                  ▼
   ④ TEST AGENT  ── writes/updates unit tests, checks coverage.
                                  │
                                  ▼
   ⑤ REVIEW AGENT  ── reads ALL the changes together, checks them against the
      original requirement AND the team's coding conventions; flags gaps.
                                  │
                                  ▼
   ⑥ REPORTER AGENT  ── prepares the JIRA comment + status update following the
      team's real process (hierarchy, gates, next steps).
                                  │
                                  ▼
   ┌─────────────────────────────────────────────────────────────────────┐
   │  OUTPUT: a review-ready change (feature branch / PR) + tests          │
   │          + a drafted JIRA update — a human approves & deploys.        │
   └─────────────────────────────────────────────────────────────────────┘
```

## 4. The agent team (who does what)
| Agent | Role (plain language) |
|---|---|
| **Research** | The analyst — finds and reads every relevant doc (Confluence/Drive) + existing code, and explains what the change really requires. |
| **Planner / Orchestrator** | The tech lead — turns the brief into a plan and assigns work to the right specialists. |
| **UI Agent** | Builds the screens users interact with (LWC / Aura / Visualforce). |
| **Apex Agent** | Writes the back-end logic and automated triggers, plus their tests. |
| **Automation Agent** | Builds the no-code automation (Flows, rules). |
| **Data/Config Agent** | Sets up the data structure (objects, fields, permissions). |
| **Test Agent** | Ensures everything is covered by automated tests (Salesforce requires this). |
| **Review Agent** | The reviewer — reads all changes together, checks them against the requirement and the team's coding standards, and flags anything missing or risky. |
| **Reporter Agent** | Documents the work back into JIRA following the team's process. |

## 5. Why a *team* of agents, not one big AI
- **Specialization beats generalization** — a focused agent with the right context produces better, more reliable code for its layer.
- **Parallelism** — layers are built at the same time, like a real team, so it's faster.
- **Safety through separation** — the agent that *writes* code is not the one that *reviews* it; an independent review agent catches mistakes (adversarial check).
- **Easier to extend** — adding a new capability = adding a new specialist, without touching the others.

## 6. Guardrails — humans stay in control
This is an **accelerator, not an auto-deployer.** The pipeline respects the team's existing process:
- Output is a **feature branch / PR for review** (naming: `feature/GCI_<TicketNumber>`), never a silent push to production.
- The team's real gates still apply: **2-level code review (dev + scrum master) → QA sign-off → environment promotion (GCI → BisUAT → Prod) with CMRs.**
- The agents **enforce the team's own coding conventions** (the repo already encodes these as authoritative Apex rules) and only *draft* JIRA comments for a human to post.

The AI does the heavy lifting; people approve every gate.

## 7. What's already proven (de-risking the idea)
The **last mile of this pipeline already works.** We have built and tested agents that:
- Connect to **JIRA** (read tickets, map parent/child hierarchy, read comments),
- Pull supporting docs from **Confluence / Google Drive**,
- Read **local git history** to know what actually changed,
- Understand the **team's real delivery process** (deployment vs testing tickets, QA sign-off gate, GCI→BisUAT→Prod promotion), and
- **Draft accurate, process-aware JIRA updates** — including "what to do next" — with a human reviewing before posting.

So the *requirement-gathering, context-research, and reporting* stages are demonstrated. The hackathon extends the same proven foundation **forward into code generation.**

## 8. Building blocks (tech)
- **AI:** Claude (Anthropic) agents, orchestrated as a multi-agent workflow.
- **Connectors:** JIRA, Confluence, Google Drive (for requirements + docs), git (for code history).
- **Salesforce:** metadata/source format + the org's deployment pipeline (GCI/BisUAT/Prod).
- **Conventions:** the team's existing coding-standard rules, fed to the agents so output matches house style.

## 9. Hackathon scope
**MVP (what we demo):** Take one real Story → Research agent gathers its Confluence/Drive docs → Planner produces a plan → 1–2 specialist agents make the changes on a feature branch → Test agent adds tests → Review agent validates → Reporter drafts the JIRA update. Show a working, review-ready change produced from just the requirement.

**Stretch:** more specialist agents (full layer coverage), automatic test-run feedback loop, and a one-click "open PR + post JIRA draft."

## 10. Impact
- **Speed:** hours/days of build-and-document collapsed into a review-and-approve step.
- **Consistency:** every change follows the same conventions and process.
- **Onboarding:** new joiners become productive faster — the pipeline encodes tribal knowledge.
- **Focus:** developers spend time on judgment and review, not boilerplate.

## 11. Risks & mitigations
| Risk | Mitigation |
|---|---|
| AI-generated code could be wrong | Independent review agent + mandatory human code review + tests before any deploy |
| Missing/ambiguous requirements | Research agent surfaces gaps and asks, rather than guessing |
| Touching the wrong components | Plan is reviewed; changes are isolated to a feature branch |
| Over-automation risk | Humans approve every existing gate; nothing auto-deploys |

## 12. Success metrics (suggested)
- % of a requirement implemented without manual coding,
- Time from requirement → review-ready change,
- Review pass rate / rework needed,
- Test coverage on generated code.

## 13. Future vision
A standing "AI delivery teammate" for the team: hand it the backlog, it produces review-ready changes and keeps JIRA current — humans steer, review, and approve.

---

## Open questions / things for YOU to add
1. **Autonomy level:** confirm we present this as *draft PR for human review* (recommended), not auto-deploy.
2. **Hackathon framing:** internal RingCentral hackathon? Any theme (AI productivity, etc.) to lean into?
3. **Name:** pick/replace the working title.
4. **Team & credits:** who's on the entry?
5. **Demo target:** which real Story/Bug do we use for the live demo?
6. **The "few things" you mentioned:** drop them in and I'll weave them in cleanly.
