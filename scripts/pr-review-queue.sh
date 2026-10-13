#!/usr/bin/env bash
#
# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright © 2026 Enrico Weigelt, metux IT consult
#
# Drain the XLibre xserver "bot-review-wanted" review queue.
#
# `bot-review-wanted` is a QUEUE marker, not a status: it means "not yet
# reviewed". A PR is done when it carries a verdict label (bot-review-passed /
# bot-review-changes-requested) and NO bot-review-wanted. This helper wraps the
# repetitive gh/starfleetctl calls so a queue pass does not have to re-invent
# them; the review rules themselves live in the `bot-review` skill, the queue
# workflow in the `pr-review-queue` skill.
#
# Usage:
#   pr-review-queue.sh list
#       Show the queue split into "already reviewed" (verdict label set, only
#       the marker is left) and "needs review".
#   pr-review-queue.sh done   <pr#> passed|changes-requested
#       Apply the verdict label and remove bot-review-wanted (no comment post).
#   pr-review-queue.sh review <pr#> <comment-file> passed|changes-requested
#       Post the review comment (with the bot banner), apply the verdict label
#       and remove bot-review-wanted — the full "review done" step.
#
# Env: REPO=owner/name (default X11Libre/xserver), SCTL=/path/to/starfleetctl
# Exit: 0 ok, 1 usage/command error.

set -uo pipefail

REPO="${REPO:-X11Libre/xserver}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCTL="${SCTL:-$HERE/../.starfleet-ai/bin/starfleetctl}"

die() { echo "pr-review-queue: $*" >&2; exit 1; }

# hv: jq def — true iff the PR carries a verdict label (review already done)
JQ_HV='def hv: ([.labels[].name] | any(. == "bot-review-passed" or . == "bot-review-changes-requested"));'

cmd_list() {
    local all total
    all="$(gh pr list --repo "$REPO" --state open --label bot-review-wanted \
        --json number,title,baseRefName,author,labels)" || die "gh pr list failed"
    total="$(jq 'length' <<<"$all")"

    echo "== bot-review-wanted queue — $REPO ($total open PRs) =="

    echo
    echo "-- already reviewed: verdict label set, only the marker is left (use: done <pr#>) --"
    jq -r "$JQ_HV"' .[] | select(hv) | "  #\(.number)\t\(.baseRefName)\t\(.title)"' <<<"$all"

    echo
    echo "-- needs review (use: review <pr#> <file> <verdict>) --"
    jq -r "$JQ_HV"' .[] | select(hv | not) | "  #\(.number)\t\(.baseRefName)\t\(.author.login)\t\(.title)"' <<<"$all"
}

cmd_done() {
    local pr="${1:-}" verdict="${2:-}"
    [ -n "$pr" ] || die "usage: done <pr#> passed|changes-requested"
    case "$verdict" in
        passed|changes-requested) ;;
        *) die "verdict must be passed|changes-requested";;
    esac
    "$SCTL" github pr label "$pr" set-review "$verdict" || die "set-review failed for #$pr"
    "$SCTL" github pr label "$pr" remove bot-review-wanted || die "remove bot-review-wanted failed for #$pr"
    echo "pr-review-queue: #$pr -> $verdict ; bot-review-wanted removed"
}

cmd_review() {
    local pr="${1:-}" body="${2:-}" verdict="${3:-}"
    [ -n "$pr" ] && [ -n "$body" ] && [ -n "$verdict" ] \
        || die "usage: review <pr#> <comment-file> passed|changes-requested"
    [ -f "$body" ] || die "no such comment file: $body"
    "$SCTL" github pr comment "$pr" "$body" --bot-review || die "comment post failed"
    cmd_done "$pr" "$verdict"
}

main() {
    local cmd="${1:-}"; shift || true
    case "$cmd" in
        list)   cmd_list ;;
        done)   cmd_done "$@" ;;
        review) cmd_review "$@" ;;
        ""|-h|--help)
            sed -n '3,30p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
            ;;
        *) die "unknown command: $cmd (want: list|done|review)" ;;
    esac
}

main "$@"
