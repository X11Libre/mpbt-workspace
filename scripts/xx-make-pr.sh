#!/usr/bin/env bash
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
#DEFAULT_MODE="incubator"        # default mode: incubator | rebase
DEFAULT_MODE="rebase"
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
  --rebase            Use rebase mode (markers added to PR branch, then incubator rebased).
  --branch <name>     Explicitly set PR branch name instead of auto-generating it.

Arguments:
  One or more commit SHAs (not necessarily consecutive) to include in the PR.

EOF
  exit 1
fi

### PARSE OPTIONS
MODE="$DEFAULT_MODE"
BRANCH_NAME=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --rebase)
      MODE="rebase"
      shift
      ;;
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

echo "Mode: $MODE"
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
if [[ "$MODE" == "incubator" ]]; then
  # Rewrite incubator branch directly
  git checkout "$INCUBATOR_BRANCH"
  for c in "${COMMITS[@]}"; do
    git rebase -i --autosquash --keep-empty --exec "git log --format=%B -1 HEAD | sed \"1s/^/[PR #$PR_NUMBER] /\" | git commit --amend -F - --trailer \"PR: $PR_URL\""
  done
else
  # Rebase incubator onto PR branch (markers first in PR branch)
  git checkout "$BRANCH_NAME"
  git rebase "$UPSTREAM_REF" --exec "git log --format=%B -1 HEAD | sed \"1s/^/[PR #$PR_NUMBER] /\" | git commit --amend -F - --trailer \"PR: $PR_URL\""
  git checkout "$INCUBATOR_BRANCH"
  git rebase "$BRANCH_NAME"
fi

### RESTORE
git checkout "$INCUBATOR_BRANCH"
git branch -D "$BRANCH_NAME"

echo "Done. PR created: $PR_URL"
