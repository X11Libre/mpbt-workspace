#!/usr/bin/env bash
#
# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright © 2026 Enrico Weigelt, metux IT consult
#
set -euo pipefail

# Submit a PR out of one or more given commits from within current branch
# (incubator branch), mark the PR ID in the commit messages and finally
# rebase the current branch onto the submission branch.
#
# When finished, the submitted commits are marked with the PR ID and
# placed at the bottom of the incubator branch.
#
# Configuration is taken from the current repo's .git/config
#
# workflow:
# 1. create temporary submission branch
# 2. cherry pick the given commits
# 3. push it to github and create PR
# 4. rewrite submission branch and mark PR ID in the commit messages
# 5. rebase the incubator branch onto the submission branch
# 6. drop the temporary submission branch
#

### CONFIGURATION
UPSTREAM_REMOTE="$(git config make-pr.upstream-remote || true)"
UPSTREAM_BRANCH="$(git config make-pr.upstream-branch || true)"
UPSTREAM_REF="$UPSTREAM_REMOTE/$UPSTREAM_BRANCH"
REVIEWERS="$(git config make-pr.reviewers || true)"

die() {
    echo "$0: $*" >&2
    exit 1
}

# Retry a command through transient failures (e.g. sporadic gh API 401 "Bad
# credentials" / 5xx). Retry chatter goes to stderr so stdout stays clean for
# command substitution.
gh_retry() {
    local tries=0 max=5
    until "$@"; do
        tries=$((tries + 1))
        [ "$tries" -ge "$max" ] && return 1
        echo "$0: command failed (attempt $tries/$max), retrying in $((tries * 2))s: $*" >&2
        sleep $((tries * 2))
    done
}

# Create the PR, tolerating transient gh failures. The branch is already pushed
# before this runs, so a single transient failure must NOT lose the work:
# retry, and if a PR already exists for the branch (prior attempt / re-run),
# treat that as success.
create_pr() {
    local tries=0 max=5
    while true; do
        gh pr create "$@" && return 0
        if gh pr view "$BRANCH_NAME" --json url >/dev/null 2>&1; then
            echo "$0: a PR already exists for $BRANCH_NAME, continuing." >&2
            return 0
        fi
        tries=$((tries + 1))
        [ "$tries" -ge "$max" ] && return 1
        echo "$0: 'gh pr create' failed (attempt $tries/$max), retrying in $((tries * 3))s..." >&2
        sleep $((tries * 3))
    done
}

[ "$UPSTREAM_REMOTE" ] || die "missing git config entry: make-pr.upstream-remote"
[ "$UPSTREAM_BRANCH" ] || die "missing git config entry: make-pr.upstream-branch"
[ "$REVIEWERS"       ] || die "missing git config entry: make-pr.reviewers"

### HELP
if [[ $# -lt 1 ]]; then
  cat <<EOF
Usage: $(basename "$0") [options] <commit> [<commit> ...]

Options:
  --branch <name>     Explicitly set PR branch name instead of auto-generating it.

Arguments:
  One or more commit SHAs (not necessarily consecutive) to include in the PR.

EOF
  exit 1
fi

### PARSE OPTIONS
BRANCH_NAME=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --branch)
      BRANCH_NAME="$2"
      shift 2
      ;;
    *)
      COMMITS+=("$1")
      shift
      ;;
  esac
done

if [[ ${#COMMITS[@]} -eq 0 ]]; then
  echo "Error: At least one commit must be specified." >&2
  exit 1
fi

### SAVE CURRENT BRANCH
INCUBATOR_BRANCH=$(git rev-parse --abbrev-ref HEAD)

### DETERMINE BRANCH NAME
if [[ -z "$BRANCH_NAME" ]]; then
  FIRST_SUBJECT=$(git log -1 --pretty=%s "${COMMITS[0]}")
  BRANCH_NAME=$(echo "$FIRST_SUBJECT" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-')
  BRANCH_NAME="pr/${UPSTREAM_BRANCH}-${BRANCH_NAME}_$(date +%Y-%m-%d_%H-%M-%S)"
fi

TMP_BRANCH="tmp-${BRANCH_NAME}"

echo "Incubator: $INCUBATOR_BRANCH"
echo "New PR branch: $BRANCH_NAME"
echo "Commits: ${COMMITS[*]}"

### CREATE TEMP BRANCH FOR PR
git fetch origin
git checkout -b "$TMP_BRANCH" "$UPSTREAM_REF"

# Cherry-pick commits
for c in "${COMMITS[@]}"; do
  if ! git cherry-pick "$c"; then
    echo "Cherry-pick of $c failed. Please resolve manually!" >&2
    exit 1
  fi
done

# Rename to final branch
git branch -M "$BRANCH_NAME"

# Strip any incubator-only "[PR #N] " subject prefix that may have come in via
# cherry-picking an already-marked incubator commit. The pushed (and therefore
# merged) commits must stay clean — the prefix belongs only on the incubator and
# is (re)added there further below. The "PR:" trailer is kept as provenance.
git rebase "$UPSTREAM_REF" --exec 'git log -1 --format=%B | sed "1s/^\[PR #[0-9]*\] //" | git commit --amend -F -'

# Push it to github
git push "$UPSTREAM_REMOTE" "$BRANCH_NAME"

### CREATE PR
if [[ ${#COMMITS[@]} -eq 1 ]]; then
  TITLE="($UPSTREAM_BRANCH) $(git log -1 --pretty=format:"%s")"
  create_pr -a "@me" --fill --title "$TITLE" -B "$UPSTREAM_BRANCH" -H "$BRANCH_NAME" --reviewer "$REVIEWERS" \
    || die "gh pr create failed after retries. Branch '$BRANCH_NAME' is already pushed — create the PR manually: gh pr create -B $UPSTREAM_BRANCH -H $BRANCH_NAME --reviewer $REVIEWERS"
else
  TMP_FILE=$(mktemp)
  echo "# Pull Request description (edit below, lines starting with # are ignored)" > "$TMP_FILE"
  echo "" >> "$TMP_FILE"
  git log --format='%h %s' "${COMMITS[@]}" >> "$TMP_FILE"
  ${EDITOR:-vi} "$TMP_FILE"
  create_pr -a "@me" --title "($UPSTREAM_BRANCH) PR: ${COMMITS[*]}" --body-file "$TMP_FILE" -B "$UPSTREAM_BRANCH" -H "$BRANCH_NAME" --reviewer "$REVIEWERS" \
    || die "gh pr create failed after retries. Branch '$BRANCH_NAME' is already pushed — create the PR manually: gh pr create -B $UPSTREAM_BRANCH -H $BRANCH_NAME --reviewer $REVIEWERS"
  rm -f "$TMP_FILE"
fi

PR_URL=$(gh_retry gh pr view --json url -q .url "$BRANCH_NAME")
[ -n "$PR_URL" ] || die "could not resolve PR URL for '$BRANCH_NAME' (gh pr view failed). The PR may exist; check: gh pr view $BRANCH_NAME"
PR_NUMBER=$(echo "$PR_URL" | grep -o '[0-9]*$')

### HANDLE MARKERS
# Mark only the incubator's own copies of the submitted commits with the
# "[PR #N] " subject prefix + "PR: <url>" trailer. $BRANCH_NAME was already
# pushed above to create the PR and must never be rewritten again — doing so
# here previously leaked the marker onto the merged upstream commit (seen on
# PR #3162, all 4 commits merged with a "[PR #3162] " subject prefix).
git checkout "$INCUBATOR_BRANCH"

# Explicit base for the rebase below, instead of relying on the incubator
# branch having an @{upstream} configured (git rebase -i with no argument
# needs one).
MARK_BASE=$(git merge-base "$UPSTREAM_REF" "$INCUBATOR_BRANCH")

MARK_EXEC="git log --format=%B -1 HEAD | sed \"1s/^/[PR #$PR_NUMBER] /\" | git commit --amend -F - --trailer \"PR: $PR_URL\""

# A GIT_SEQUENCE_EDITOR that appends "exec $MARK_EXEC" after the todo "pick"
# line for each submitted commit and leaves every other line untouched —
# scripting exactly what a human doing `rebase -i` by hand would type, so the
# rebase runs non-interactively. (The previous "incubator" mode did this via
# a bare `rebase -i`, which needs an interactive editor and is unsupported in
# an agent/CI environment — that's why the default was flipped to the
# leak-prone "rebase" mode in the first place.)
SEQ_EDITOR=$(mktemp)
cat >"$SEQ_EDITOR" <<'EDITOR_EOF'
#!/usr/bin/env bash
set -euo pipefail
todo="$1"
tmp=$(mktemp)
while IFS= read -r line; do
  echo "$line" >>"$tmp"
  case "$line" in
    pick\ *)
      sha=$(echo "$line" | awk '{print $2}')
      while IFS= read -r target; do
        [ -z "$target" ] && continue
        case "$target" in
          "$sha"*) echo "exec $MARK_EXEC" >>"$tmp" ;;
        esac
      done <<<"$MARK_SHAS"
      ;;
  esac
done <"$todo"
mv "$tmp" "$todo"
EDITOR_EOF
chmod +x "$SEQ_EDITOR"

MARK_SHAS=""
for c in "${COMMITS[@]}"; do
  MARK_SHAS+="$(git rev-parse "$c")"$'\n'
done
export MARK_EXEC MARK_SHAS

GIT_SEQUENCE_EDITOR="$SEQ_EDITOR" git rebase -i --autosquash --keep-empty "$MARK_BASE"
rm -f "$SEQ_EDITOR"

### RESTORE
git branch -D "$BRANCH_NAME"

echo "Done. PR created: $PR_URL"
