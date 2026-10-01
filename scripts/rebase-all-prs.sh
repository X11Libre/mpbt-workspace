#!/bin/bash
# rebase-all-prs.sh
# Rebase all open PRs onto the latest version of their target branches using GitHub API first.
# Usage: ./rebase-all-prs.sh [--dry-run]
# WARNING: Run only when CI is not blocked (e.g., overnight).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
    echo "=== DRY RUN MODE ==="
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# Ensure we're in the workspace root
cd "${WORKSPACE_ROOT}"

# Check gh is available
if ! command -v gh &> /dev/null; then
    log_error "gh CLI not found. Please install GitHub CLI."
    exit 1
fi

# Check gh auth
if ! gh auth status &> /dev/null; then
    log_error "gh not authenticated. Run 'gh auth login'."
    exit 1
fi

# Get all open PRs from the xserver repo
log_info "Fetching open PRs from X11Libre/xserver..."
PRS=$(gh pr list --repo X11Libre/xserver --state open --json number,headRefName,baseRefName,title,author,mergeable --limit 100)

if [[ -z "${PRS}" || "${PRS}" == "[]" ]]; then
    log_info "No open PRs found."
    exit 0
fi

# Parse PRs
echo "${PRS}" | jq -c '.[]' | while IFS= read -r pr; do
    number=$(echo "${pr}" | jq -r '.number')
    head_branch=$(echo "${pr}" | jq -r '.headRefName')
    base_branch=$(echo "${pr}" | jq -r '.baseRefName')
    title=$(echo "${pr}" | jq -r '.title')
    author=$(echo "${pr}" | jq -r '.author.login')
    mergeable=$(echo "${pr}" | jq -r '.mergeable')

    log_info "Processing PR #${number}: ${title}"
    log_info "  Head: ${head_branch} -> Base: ${base_branch}"
    log_info "  Author: ${author}"
    log_info "  Mergeable: ${mergeable}"

    # Validate base branch is one we expect
    case "${base_branch}" in
        master|release/25.0|release/25.1|release/25.2)
            log_info "  Target branch '${base_branch}' is a known release branch."
            ;;
        *)
            log_warn "  Target branch '${base_branch}' is not a standard release branch. Proceeding anyway."
            ;;
    esac

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "  [DRY RUN] Would update PR #${number} (${head_branch} -> ${base_branch}) via GitHub API"
        continue
    fi

    # Try GitHub update-branch API first for ALL PRs
    log_info "  Attempting GitHub update-branch API for PR #${number}..."
    if gh api --method PUT "repos/X11Libre/xserver/pulls/${number}/update-branch" --silent 2>/dev/null; then
        log_info "  ✓ PR #${number} updated successfully via GitHub API."
        continue
    else
        log_warn "  GitHub update-branch API failed for PR #${number} (likely conflicts). Falling back to local rebase."
    fi

    # Fallback: local rebase for internal PRs only
    if git ls-remote --exit-code --heads origin "${head_branch}" >/dev/null 2>&1; then
        log_info "  Head branch '${head_branch}' exists on remote (internal PR). Attempting local rebase..."

        # Create a temporary worktree for this PR
        WORKTREE_PATH="${WORKSPACE_ROOT}/_WORK_/worktrees/xserver/pr-rebase-${number}"
        if [[ -d "${WORKTREE_PATH}" ]]; then
            log_warn "  Worktree ${WORKTREE_PATH} already exists. Removing..."
            git worktree remove --force "${WORKTREE_PATH}" 2>/dev/null || true
        fi

        log_info "  Creating worktree at ${WORKTREE_PATH}..."
        if ! git worktree add "${WORKTREE_PATH}" -b "pr-rebase-${number}" "origin/${head_branch}" 2>/dev/null; then
            log_error "  Failed to create worktree for PR #${number}. Skipping."
            continue
        fi

        cd "${WORKTREE_PATH}"

        # Fetch latest base branch
        log_info "  Fetching latest origin/${base_branch}..."
        git fetch origin "${base_branch}" --quiet

        # Rebase onto latest base branch
        log_info "  Rebasing onto origin/${base_branch}..."
        if git rebase "origin/${base_branch}"; then
            log_info "  Rebase successful. Pushing with force..."
            if git push origin "HEAD:${head_branch}" --force-with-lease; then
                log_info "  ✓ PR #${number} rebased and pushed successfully."
            else
                log_error "  Failed to push rebased branch for PR #${number}."
            fi
        else
            log_error "  Rebase failed for PR #${number}. Manual intervention required."
            log_error "  Worktree left at: ${WORKTREE_PATH}"
        fi

        # Return to workspace root
        cd "${WORKSPACE_ROOT}"

        # Clean up worktree (keep it for inspection if rebase failed)
        if git worktree list | grep -q "${WORKTREE_PATH}"; then
            log_info "  Worktree left at ${WORKTREE_PATH} for inspection."
        fi
    else
        log_error "  Head branch '${head_branch}' not found on origin remote (external PR with conflicts). Cannot rebase locally. Manual intervention required."
    fi

done

log_info "All PRs processed."
EOF