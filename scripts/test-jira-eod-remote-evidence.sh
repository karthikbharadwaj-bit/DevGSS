#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COLLECTOR="$SCRIPT_DIR/jira-eod-remote-evidence.sh"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

REMOTE="$TEST_DIR/remote.git"
WORK="$TEST_DIR/work"
git init -q --bare "$REMOTE"
git init -q "$WORK"
git -C "$WORK" remote add origin "$REMOTE"

printf 'base\n' > "$WORK/file.txt"
git -C "$WORK" add file.txt
GIT_AUTHOR_NAME='Karthik Bharadwaj' \
GIT_AUTHOR_EMAIL='karthik.bharadwaj@ringcentral.com' \
GIT_COMMITTER_NAME='Karthik Bharadwaj' \
GIT_COMMITTER_EMAIL='karthik.bharadwaj@ringcentral.com' \
  git -C "$WORK" commit -q -m 'PBC-123 implement remote evidence'
MATCHING_SHA="$(git -C "$WORK" rev-parse HEAD)"
git -C "$WORK" branch -M main
git -C "$WORK" push -q -u origin main

git -C "$WORK" checkout -q -b feature/PBC-456-follow-up
printf 'follow-up\n' >> "$WORK/file.txt"
git -C "$WORK" add file.txt
GIT_AUTHOR_NAME='Karthik Bharadwaj' \
GIT_AUTHOR_EMAIL='karthik.bharadwaj@ringcentral.com' \
GIT_COMMITTER_NAME='Karthik Bharadwaj' \
GIT_COMMITTER_EMAIL='karthik.bharadwaj@ringcentral.com' \
  git -C "$WORK" commit -q -m 'Implement follow-up without a ticket key'
BRANCH_SHA="$(git -C "$WORK" rev-parse HEAD)"
git -C "$WORK" push -q -u origin feature/PBC-456-follow-up

git -C "$WORK" checkout -q main
printf 'someone else\n' >> "$WORK/file.txt"
git -C "$WORK" add file.txt
GIT_AUTHOR_NAME='Someone Else' \
GIT_AUTHOR_EMAIL='someone.else@ringcentral.com' \
GIT_COMMITTER_NAME='Someone Else' \
GIT_COMMITTER_EMAIL='someone.else@ringcentral.com' \
  git -C "$WORK" commit -q -m 'PBC-123 unrelated author'
OTHER_SHA="$(git -C "$WORK" rev-parse HEAD)"
git -C "$WORK" push -q origin main

printf 'file://%s\n' "$REMOTE" > "$TEST_DIR/repos.txt"
printf 'PBC-123\nPBC-456\n' > "$TEST_DIR/keys.txt"

OUTPUT="$TEST_DIR/output.md"
"$COLLECTOR" \
  --repos-file "$TEST_DIR/repos.txt" \
  --author-email 'karthik.bharadwaj@ringcentral.com' \
  --keys-file "$TEST_DIR/keys.txt" \
  --cache-dir "$TEST_DIR/cache" \
  --since '10 years ago' > "$OUTPUT"

grep -Fq "${MATCHING_SHA:0:12}" "$OUTPUT" ||
  fail 'ticket-key commit by the configured author was not included'
grep -Fq "${BRANCH_SHA:0:12}" "$OUTPUT" ||
  fail 'commit on a ticket-named branch was not included'
if grep -Fq "${OTHER_SHA:0:12}" "$OUTPUT"; then
  fail 'commit by another author was included'
fi

if rg -n '(^|[;&|[:space:]])git[[:space:]]+([^#\n]*[[:space:]])?push([[:space:]]|$)' "$COLLECTOR" >/dev/null; then
  fail 'collector contains a git push path'
fi

printf 'PASS: remote evidence is read-only and filters commits by exact author email\n'
