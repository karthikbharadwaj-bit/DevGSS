#!/usr/bin/env bash
# End-of-day JIRA draft generator (headless / launchd).
# Pre-fetches JIRA via REST + local git evidence, then asks `claude -p` to draft
# per-ticket comments + a status digest. DRAFT-ONLY: never writes to JIRA.
#
# Secrets are read from an env file (default ~/.config/jira-eod/jira-eod.env):
#   JIRA_PAT=...                  # Jira Personal Access Token
#   CLAUDE_CODE_OAUTH_TOKEN=...   # from `claude setup-token`
#   JIRA_BASE_URL=https://jira.ringcentral.com   # optional
#   REPO_DIR=/Users/Karthik.Bharadwaj/SandBox/DevGSS  # optional
set -euo pipefail

ENV_FILE="${JIRA_EOD_ENV:-$HOME/.config/jira-eod/jira-eod.env}"
if [ -f "$ENV_FILE" ]; then set -a; . "$ENV_FILE"; set +a; fi

: "${JIRA_BASE_URL:=https://jira.ringcentral.com}"
: "${REPO_DIR:=$HOME/SandBox/DevGSS}"
: "${CLAUDE_BIN:=$HOME/.local/bin/claude}"
: "${OUT_DIR:=$REPO_DIR/drafts}"
: "${JIRA_PAT:?JIRA_PAT not set — add it to $ENV_FILE}"
: "${CLAUDE_CODE_OAUTH_TOKEN:?CLAUDE_CODE_OAUTH_TOKEN not set — run 'claude setup-token' and add it to $ENV_FILE}"

TODAY="$(date +%F)"            # local date == IST for this machine
mkdir -p "$OUT_DIR"
OUT_FILE="$OUT_DIR/jira-eod-$TODAY.md"
LOG="$OUT_DIR/jira-eod.log"
CTX="$(mktemp)"; trap 'rm -f "$CTX" "$CTX.body"' EXIT
log() { echo "[$(date '+%F %T')] $*" >> "$LOG"; }

AUTH=(-H "Authorization: Bearer $JIRA_PAT" -H "Content-Type: application/json")

log "=== run start ($TODAY) ==="

# 1) Active tickets assigned to me, not Done.
http=$(curl -sS "${AUTH[@]}" -X POST "$JIRA_BASE_URL/rest/api/2/search" \
  -d '{"jql":"assignee = currentUser() AND statusCategory != Done ORDER BY updated DESC","maxResults":50,"fields":["summary","status","issuetype","updated"]}' \
  -o "$CTX.body" -w '%{http_code}') || true
if [ "$http" != "200" ]; then
  echo "# JIRA EOD — $TODAY — BLOCKED" > "$OUT_FILE"
  echo -e "\nJIRA search returned HTTP $http. Likely the PAT is missing/expired — refresh it at\nhttps://jira.ringcentral.com/secure/ViewProfile.jspa?selectedTab=com.atlassian.pats.pats-plugin:jira-user-personal-access-tokens\nand update $ENV_FILE." >> "$OUT_FILE"
  log "BLOCKED: search HTTP $http"; exit 1
fi
search="$(cat "$CTX.body")"
keys=$(echo "$search" | jq -r '.issues[].key')

{
  echo "# JIRA context for $TODAY (IST)"
  echo
  echo "## Active tickets (assignee = me, statusCategory != Done)"
  echo "$search" | jq -r '.issues[]? | "- \(.key) [\(.fields.issuetype.name)] \(.fields.status.name) — \(.fields.summary)"'
  echo
} > "$CTX"

# 2) Per-ticket: relationships + comments (author/date) + local git evidence.
PARENTS=""
for k in $keys; do
  issue=$(curl -sS "${AUTH[@]}" "$JIRA_BASE_URL/rest/api/2/issue/$k?fields=summary,status,issuetype,issuelinks,comment,description") || continue
  PARENTS="$PARENTS $(echo "$issue" | jq -r '(.fields.issuelinks // [])[]? | (.inwardIssue // .outwardIssue) | select(.fields.issuetype.name=="Bug" or .fields.issuetype.name=="Story" or .fields.issuetype.name=="User Story") | .key' 2>/dev/null | tr "\n" " ")"
  {
    echo "## $k"
    echo "$issue" | jq -r '"Type: \(.fields.issuetype.name) | Status: \(.fields.status.name)\nSummary: \(.fields.summary)\nDescription: \((.fields.description // "") | gsub("\r?\n";" ") | .[0:800])"'
    echo "### Relationships"
    echo "$issue" | jq -r '
      (.fields.issuelinks // [])[]? |
      if .inwardIssue then "- \(.type.inward) \(.inwardIssue.key) [\(.inwardIssue.fields.issuetype.name)] \(.inwardIssue.fields.status.name)"
      else "- \(.type.outward) \(.outwardIssue.key) [\(.outwardIssue.fields.issuetype.name)] \(.outwardIssue.fields.status.name)" end'
    echo "### Comments (author | created | body excerpt)"
    echo "$issue" | jq -r '(.fields.comment.comments // [])[]? | "- \(.author.displayName) | \(.created) | \((.body // "") | gsub("\r?\n";" ") | .[0:1000])"'
    echo "### Committed work referencing $k"
    ( cd "$REPO_DIR" 2>/dev/null && { git log --all --oneline --grep="$k" | head -20; git branch -a --list "*$k*"; } ) || echo "(no repo/match)"
    echo
  } >> "$CTX"
done

# Parent dev tickets (Bug/Story) — fetch status + comments even though they're excluded from the
# active search (Resolved/Closed = Done), so Claude can apply the dev-ticket gate and spot a QA sign-off.
PARENTS=$(printf '%s\n' $PARENTS | grep -E '^[A-Z]+-[0-9]+$' | sort -u || true)
for pk in $PARENTS; do
  echo "$keys" | grep -qx "$pk" && continue
  pissue=$(curl -sS "${AUTH[@]}" "$JIRA_BASE_URL/rest/api/2/issue/$pk?fields=summary,status,issuetype,comment") || continue
  {
    echo "## $pk  (PARENT DEV TICKET — gate: children are not actionable until this is Closed)"
    echo "$pissue" | jq -r '"Type: \(.fields.issuetype.name) | Status: \(.fields.status.name)\nSummary: \(.fields.summary)"'
    echo "### Comments — look here for a QA/testing-team SIGN-OFF (author | created | body excerpt)"
    echo "$pissue" | jq -r '(.fields.comment.comments // [])[]? | "- \(.author.displayName) | \(.created) | \((.body // "") | gsub("\r?\n";" ") | .[0:1000])"'
    echo
  } >> "$CTX"
done

# Global working-tree snapshot (committed/recent + staged + uncommitted) so Claude can relate
# in-progress changes to tickets by file path / content (working-tree changes aren't tagged with a key).
{
  echo "## Local working tree (relate to the tickets above by file/path/content; NOT all changes are ticket-related)"
  ( cd "$REPO_DIR" 2>/dev/null && {
      echo "### Current branch"; git rev-parse --abbrev-ref HEAD
      echo "### git status (short)"; git status -s
      echo "### Recent commits (last 15, any ticket)"; git log --oneline -15
      echo "### Unstaged changes (stat)"; git diff --stat
      echo "### Staged changes (stat)"; git diff --staged --stat
      echo "### Unstaged diff (capped)"; git diff | head -200
      echo "### Staged diff (capped)"; git diff --staged | head -200
  } ) || echo "(no repo)"
  echo
} >> "$CTX"

# Append the team process reference so Claude can derive next steps.
PROC="$REPO_DIR/docs/jira-process.md"
if [ -f "$PROC" ]; then { echo "## RingCentral GCI process reference (use to derive Next steps)"; echo; cat "$PROC"; } >> "$CTX"; fi

# 3) Hand the context to Claude to draft (pure reasoning — no tools, no JIRA writes).
read -r -d '' PROMPT <<'EOF' || true
You are Karthik Bharadwaj's end-of-day JIRA assistant (RingCentral GCI team). Below is today's
pre-fetched JIRA context (active tickets, relationships, comments with author+date, and local git
evidence). Using ONLY that context, produce DRAFT comments for Karthik to review and post manually.
NEVER suggest auto-posting; this is draft-only.

Rules:
- Treat "today" as __TODAY__ (Asia/Calcutta).
- DEDUP BY MEANING: before drafting a ticket, compare your intended comment with Karthik's existing
  comments on that ticket (any date) shown in the context. Skip the ticket if (a) he already commented
  today, OR (b) today's comment would be substantively the same as a recent one (same status, no new
  info) -> instead output a single line "No new update since <date>'s comment". Only draft a fresh
  comment when there is genuinely NEW information.
- Map the hierarchy FIRST. A work item is normally a PARENT (Bug/Story = real dev work) with CHILD
  utility tickets that only track per-environment deployment + testing. Do not treat tickets as flat peers.
- DEV-TICKET GATE (see the process reference): a deployment/testing CHILD is only actionable once its
  PARENT dev ticket is "Closed". If the parent dev ticket is below Closed (e.g. Resolved), the children
  have NOTHING to do — do not draft GCI/BisUAT/Prod actions. Read the PARENT DEV TICKET's comments: if a
  QA/testing-team sign-off is present and the parent is only Resolved, recommend moving the parent to
  Closed and starting the GCI deploy; if no sign-off, the parent is waiting on QA sign-off in the dev sandbox.
- RELATE CODE TO TICKETS: the context has per-ticket commit matches AND a "Local working tree" snapshot
  (recent commits, staged, and uncommitted changes). Working-tree changes are NOT tagged with a key --
  decide by file path / content whether they relate to an active ticket. If related, ground the PARENT
  ticket's draft in the actual changes (which files / what logic changed, committed or still uncommitted).
  If a change is unrelated to any active ticket (e.g. tooling/config), do NOT force a connection.
- PARENT ticket -> substantive update (progress, changes, doc/MR links, review+test status), grounded
  in the related commits/diffs above.
- CHILD deployment tickets -> short STATUS-ONLY notes (e.g. "Deployed to GCI, awaiting QA acceptance").
  Do NOT write "Dev in progress" on a deployment ticket.
- Promotion gates: Dev -> review (1 dev + 1 scrum master) -> mark parent Resolved -> GCI deploy ->
  GCI QA sign-off -> CMR -> BisUAT deploy -> BisUAT QA/UAT -> CMR -> Prod deploy. CMR only for BisUAT/Prod.
- A "RingCentral GCI process reference" is appended at the end of the context — use it to place each
  ticket in the lifecycle and to derive concrete next actions.
- First-person, concise. Mark unknowns with [FILL IN: ...].
- Output, in order: (1) per-ticket DRAFT comments grouped by key; (2) a short status digest
  (ready-to-resolve, chain order, QA-owned siblings); (3) a "Next steps" section — for each ticket I
  own, the single concrete next action per the lifecycle + promotion gates (e.g. "PBC-31873: book GCI
  merge slot in CET and deploy; GCI needs no CMR; then get GCI QA acceptance and raise CMR for BisUAT").
  Do NOT flag missing branches/reviews on child deployment tickets.
EOF
PROMPT="${PROMPT//__TODAY__/$TODAY}"

log "calling claude (context $(wc -c < "$CTX") bytes, tickets: $(echo "$keys" | grep -c . || true))"
if ( cd "$HOME" && CLAUDE_CODE_OAUTH_TOKEN="$CLAUDE_CODE_OAUTH_TOKEN" "$CLAUDE_BIN" -p "$PROMPT

=== TODAY'S JIRA + GIT CONTEXT ===
$(cat "$CTX")" --permission-mode dontAsk --output-format text ) > "$OUT_FILE" 2>>"$LOG"; then
  log "OK -> $OUT_FILE"
else
  rc=$?; echo "(claude exited $rc — see $LOG)" >> "$OUT_FILE"; log "claude FAILED rc=$rc"; exit $rc
fi
