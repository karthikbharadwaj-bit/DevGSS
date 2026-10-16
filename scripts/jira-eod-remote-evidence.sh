#!/usr/bin/env bash
# Collect ticket-related commit and branch evidence from remote Git repositories.
# Remote operations are intentionally limited to ls-remote and fetch.
set -euo pipefail

REPOS_FILE=""
AUTHOR_EMAIL=""
KEYS_FILE=""
CACHE_DIR="${JIRA_EOD_CACHE_DIR:-$HOME/.cache/jira-eod/repositories}"
SINCE="${JIRA_EOD_GIT_SINCE:-180 days ago}"
FETCH_DEPTH="${JIRA_EOD_FETCH_DEPTH:-100}"

usage() {
  cat <<'EOF'
Usage: jira-eod-remote-evidence.sh --repos-file PATH --author-email EMAIL
                                   --keys-file PATH [options]

Options:
  --cache-dir PATH  Local bare-repository cache
  --since DATE      Git-compatible history boundary (default: 180 days ago)
  --fetch-depth N   Commits fetched per remote branch (default: 100)
EOF
}

die() {
  printf 'jira-eod remote evidence: %s\n' "$*" >&2
  exit 2
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repos-file) REPOS_FILE="${2:-}"; shift 2 ;;
    --author-email) AUTHOR_EMAIL="${2:-}"; shift 2 ;;
    --keys-file) KEYS_FILE="${2:-}"; shift 2 ;;
    --cache-dir) CACHE_DIR="${2:-}"; shift 2 ;;
    --since) SINCE="${2:-}"; shift 2 ;;
    --fetch-depth) FETCH_DEPTH="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

[ -n "$REPOS_FILE" ] || die '--repos-file is required'
[ -n "$AUTHOR_EMAIL" ] || die '--author-email is required'
[ -n "$KEYS_FILE" ] || die '--keys-file is required'
[ -f "$REPOS_FILE" ] || die "repository list not found: $REPOS_FILE"
[ -f "$KEYS_FILE" ] || die "ticket-key list not found: $KEYS_FILE"
case "$FETCH_DEPTH" in
  ''|*[!0-9]*) die '--fetch-depth must be a positive integer' ;;
  0) die '--fetch-depth must be a positive integer' ;;
esac

mkdir -p "$CACHE_DIR"
overall_status=0

printf '## Remote Git evidence\n\n'
printf 'Exact author filter: `%s`\n\n' "$AUTHOR_EMAIL"

while IFS= read -r remote_url || [ -n "$remote_url" ]; do
  case "$remote_url" in
    ''|'#'*) continue ;;
  esac

  repo_label="${remote_url%.git}"
  repo_label="${repo_label#https://}"
  repo_label="${repo_label#http://}"
  repo_label="${repo_label#ssh://}"
  repo_hash="$(printf 'targeted-v3-depth100:%s' "$remote_url" | shasum -a 256 | awk '{print substr($1,1,16)}')"
  repo_cache="$CACHE_DIR/$repo_hash.git"

  printf '### %s\n\n' "$repo_label"

  remote_refs_file="$(mktemp)"
  matching_branch_refs_file="$(mktemp)"
  fetch_branches_file="$(mktemp)"

  if ! GIT_TERMINAL_PROMPT=0 git ls-remote --symref "$remote_url" \
      HEAD 'refs/heads/*' > "$remote_refs_file"; then
    printf -- '- ERROR: read-only branch listing failed; commit evidence is incomplete.\n\n'
    rm -f "$remote_refs_file" "$matching_branch_refs_file" "$fetch_branches_file"
    overall_status=1
    continue
  fi

  default_branch="$(awk '/^ref:/ {sub("refs/heads/", "", $2); print $2; exit}' \
    "$remote_refs_file")"
  if [ -z "$default_branch" ]; then
    if awk '$2 == "refs/heads/main" {found=1} END {exit !found}' "$remote_refs_file"; then
      default_branch=main
    elif awk '$2 == "refs/heads/master" {found=1} END {exit !found}' "$remote_refs_file"; then
      default_branch=master
    else
      default_branch="$(awk '$2 ~ /^refs\/heads\// {sub("refs/heads/", "", $2); print $2; exit}' \
        "$remote_refs_file")"
    fi
  fi

  awk 'NR == FNR {
         if ($0 != "") keys[++key_count] = tolower($0)
         next
       }
       $2 ~ /^refs\/heads\// {
         branch = $2
         sub("refs/heads/", "", branch)
         for (i = 1; i <= key_count; i++) {
           if (index(tolower(branch), keys[i]) > 0) {
             print branch
             break
           }
         }
       }' "$KEYS_FILE" "$remote_refs_file" > "$matching_branch_refs_file"

  {
    [ -n "$default_branch" ] && printf '%s\n' "$default_branch"
    cat "$matching_branch_refs_file"
  } | LC_ALL=C sort -u > "$fetch_branches_file"

  fetch_specs=()
  search_refs=()
  while IFS= read -r branch_name || [ -n "$branch_name" ]; do
    [ -n "$branch_name" ] || continue
    fetch_specs[${#fetch_specs[@]}]="+refs/heads/$branch_name:refs/remotes/origin/$branch_name"
    search_refs[${#search_refs[@]}]="refs/remotes/origin/$branch_name"
  done < "$fetch_branches_file"

  if [ "${#fetch_specs[@]}" -eq 0 ]; then
    printf -- '- ERROR: the remote has no readable branches.\n\n'
    rm -f "$remote_refs_file" "$matching_branch_refs_file" "$fetch_branches_file"
    overall_status=1
    continue
  fi

  if [ ! -d "$repo_cache" ]; then
    git init -q --bare "$repo_cache"
    git -C "$repo_cache" remote add origin "$remote_url"
  fi

  if ! GIT_TERMINAL_PROMPT=0 git -C "$repo_cache" fetch --quiet --force --prune \
      --no-tags --filter=blob:none --depth="$FETCH_DEPTH" origin \
      "${fetch_specs[@]}"; then
    printf -- '- ERROR: read-only fetch failed; commit evidence is incomplete.\n\n'
    rm -f "$remote_refs_file" "$matching_branch_refs_file" "$fetch_branches_file"
    overall_status=1
    continue
  fi

  repo_has_matches=0
  while IFS= read -r ticket_key || [ -n "$ticket_key" ]; do
    [ -n "$ticket_key" ] || continue
    matches_file="$(mktemp)"
    branches_file="$(mktemp)"

    git -C "$repo_cache" log "${search_refs[@]}" --since="$SINCE" \
      --regexp-ignore-case --fixed-strings --grep="$ticket_key" \
      --format='%H%x09%ae%x09%aI%x09%s' 2>/dev/null |
      awk -F '\t' -v email="$AUTHOR_EMAIL" \
        'tolower($2) == tolower(email) { print }' > "$matches_file"

    awk -v key="$ticket_key" \
      'index(tolower($0), tolower(key)) > 0 { print "origin/" $0 }' \
      "$matching_branch_refs_file" > "$branches_file"

    while IFS= read -r branch_name || [ -n "$branch_name" ]; do
      [ -n "$branch_name" ] || continue
      if [ -n "$default_branch" ] && [ "$branch_name" != "origin/$default_branch" ]; then
        git -C "$repo_cache" log "origin/$default_branch..$branch_name" \
          --since="$SINCE" --format='%H%x09%ae%x09%aI%x09%s' 2>/dev/null |
          awk -F '\t' -v email="$AUTHOR_EMAIL" \
            'tolower($2) == tolower(email) { print }' >> "$matches_file"
      fi
    done < "$branches_file"

    deduped_file="$(mktemp)"
    awk -F '\t' '!seen[$1]++' "$matches_file" > "$deduped_file"
    if [ -s "$branches_file" ] || [ -s "$deduped_file" ]; then
      repo_has_matches=1
      printf '#### %s\n\n' "$ticket_key"
      while IFS= read -r branch_name || [ -n "$branch_name" ]; do
        [ -n "$branch_name" ] && printf -- '- Branch: `%s`\n' "$branch_name"
      done < "$branches_file"
      while IFS=$'\t' read -r commit_sha commit_email commit_date commit_subject ||
          [ -n "${commit_sha:-}" ]; do
        [ -n "${commit_sha:-}" ] || continue
        printf -- '- Commit `%s` | %s | %s\n' \
          "${commit_sha:0:12}" "$commit_date" "$commit_subject"
      done < "$deduped_file"
      printf '\n'
    fi

    rm -f "$matches_file" "$branches_file" "$deduped_file"
  done < "$KEYS_FILE"

  if [ "$repo_has_matches" -eq 0 ]; then
    printf -- '- No matching commits or remote branch names in the configured window.\n\n'
  fi
  rm -f "$remote_refs_file" "$matching_branch_refs_file" "$fetch_branches_file"
done < "$REPOS_FILE"

exit "$overall_status"
