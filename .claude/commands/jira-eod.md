---
description: Draft end-of-day JIRA comments + status digest for my owned tickets (review-only — never posts without approval)
argument-hint: "[optional: 'post <KEY> [KEY...]' or 'resolve <KEY>' after reviewing drafts]"
---

You are my end-of-day JIRA assistant. Run the full check below from this authenticated session and present DRAFTS for my review. **Never write to JIRA (no comments, no transitions) unless I explicitly tell you to in `$ARGUMENTS`.**

If `$ARGUMENTS` contains `post <KEYS>` or `resolve <KEY>`, skip drafting and instead execute exactly those write actions (and only those), confirming each before/after.

## 0. Auth
- Try a JIRA tool. If it returns "Not authenticated", ask me for my Jira Personal Access Token (create at https://jira.ringcentral.com/secure/ViewProfile.jspa?selectedTab=com.atlassian.pats.pats-plugin:jira-user-personal-access-tokens) and call `setup_auth` with `jira_pat`. **Never hardcode or echo the token.**

## 1. Find my active tickets
- JQL: `assignee = currentUser() AND statusCategory != Done ORDER BY updated DESC` (fall back to `assignee = "karthik.bharadwaj@ringcentral.com"`).

## 2. Map relationships FIRST (do not skip)
- For each ticket, fetch `issuelinks` / `parent` / `subtasks` and build the hierarchy. Do **not** treat the results as flat peers.
- A work item is normally a **parent** (Bug/Story = the real dev work) with **child *utility* tickets** that only track per-environment deployment + testing.
- QA testing children are usually owned by QA and won't appear in my assignee search — surface them for sequencing, don't draft on them.
- Also fetch the **parent dev ticket's status + comments** (it may be excluded from the active search if Resolved/Closed). Apply the dev-ticket gate from `docs/jira-process.md`: children are **not actionable until the parent dev ticket is `Closed`**. Read the parent's comments for a QA/testing-team **sign-off** — if present while the parent is only `Resolved`, recommend moving it to `Closed` and starting the GCI deploy; if absent, it's waiting on QA sign-off in the dev sandbox (nothing to do downstream).

## 2b. Cross-check local git — committed AND uncommitted (this session only — the cloud routine can't do this)
- **Committed:** `git log --oneline --all --grep=<KEY>` and branches matching `feature/GCI_<KEY>` (`git branch -a --list '*<KEY>*'`).
- **In-progress:** `git status -s`, `git diff --stat` / `git diff`, `git diff --staged --stat` / `git diff --staged`, and `git log --oneline -15`.
- Working-tree changes are **not** tagged with a key — decide by **file path / content** whether they relate to an active ticket. If related, **ground the parent's dev draft in the actual changes** (which files / what logic changed, committed or still uncommitted). If a change is unrelated (e.g. tooling/config), don't force a connection.
- Note local-only / un-pushed commits as in-progress, and whether the `feature/GCI_<KEY>` branch exists.
- Skip silently if not in a git repo or no matches.

## 2c. Load the process reference
- Read `docs/jira-process.md` (RingCentral GCI ticketing & deployment process). Use it to place each ticket in the lifecycle and to derive next steps in section 5b.

## 3. Check existing comments & dedup by meaning
- For each ticket I own, read my existing comments (all dates). **Skip drafting** if (a) I already commented **today (Asia/Calcutta)**, OR (b) today's intended comment would be **substantively the same** as a recent one (same status, no new info) — in that case say "No new update since \<date\>" instead of repeating. Only draft a fresh comment when there is genuinely **new** information (new progress, a new commit/diff, a status/gate change).

## 4. Draft per hierarchy position + phase
Follow the RingCentral GCI conventions:
- **Parent ticket** → the *substantive* update (progress, changes, doc/MR links, review + test status). By type:
  - Analysis: "Analysis in progress" → "Analysis done" + doc link → "done, picking up dev ticket" + re-share final doc.
  - Dev: "Dev in progress" + unit-test / env-setup / related docs.
  - Bug/big: progress + changes made + linked docs.
- **Child deployment tickets** → short **status-only** notes (e.g. "Deployed to GCI, awaiting QA acceptance").
- Respect the promotion sequence and gates:
  `Dev → review (1 dev + 1 scrum master) → mark parent Resolved → GCI deploy → GCI QA sign-off → CMR → BisUAT deploy → BisUAT QA/UAT sign-off → CMR → Prod deploy`.
  (CMR is required only for BisUAT and Prod, not GCI.)
- First-person, concise, professional. Where specifics are unknown, write a sensible template and mark gaps with `[FILL IN: ...]`. Reuse doc/MR links already present in the ticket's comments; search Google Drive if needed.

## 5. Status digest
Flag: tickets ready to mark **Resolved** (both reviews done but not yet resolved); branches not pushed (convention `feature/GCI_<KEY>`); reviews still pending; the deployment chain order and which env step is actionable now; QA-owned siblings for awareness.

## 5b. Next steps
For each ticket I own, give the single concrete **next action** per the lifecycle + promotion gates in `docs/jira-process.md` — e.g. "PBC-31873: book GCI merge slot (CET) and deploy; GCI needs no CMR; then get GCI QA acceptance and raise CMR for BisUAT." Keep it to one actionable line per ticket.

## 6. Present, don't post
Output per-ticket drafts grouped by key, then the digest, then the **Next steps**. End by asking which (if any) I want you to post and whether to transition any ticket — then wait for my go-ahead.
