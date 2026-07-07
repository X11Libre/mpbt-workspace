---
slug: genesis-setup-live-fleet-test-findings-2026-07-07
title: "Genesis-setup live fleet test (2026-07-07) — 3 findings on wip/starfleet-upstream"
category: parked
noted_by: "praetor request, live-tested by Enterprise + a real Claude session the praetor started in the test worktree"
since: "2026-07-07"
---

Praetor asked for a real (not synthetic-scratch-repo) test: stand up a fresh fleet from
`wip/starfleet-upstream` alone, in an isolated `scripts/worktree` (`wt/genesis-fleet-test`,
disposable), running the real `genesis-setup` end to end, then a real `claude` session launched
in that directory by the praetor asking it for fleet status. Three findings:

1. **FIXED, same session.** `starfleetctl dashboard`/`ws-commit`/`agents` (Go, `starfleetctl@bcb3932`)
   and the bash originals `scripts/dashboard`/`scripts/ws-commit` (`mtx/agent-config@daf657f`) all
   did `git pull --rebase --autostash origin "$(git rev-parse --abbrev-ref HEAD)"` before
   read/write — assumes the remote has a branch named identically to whatever's checked out
   locally. True for a normal checkout, **false for any `scripts/worktree` checkout** (creates
   local branches named `wt/<name>` tracking a differently-named remote branch by design) — exactly
   what the test worktree is. `dashboard show` failed there with "Konnte Remote-Referenz
   wt/genesis-fleet-test nicht finden" despite correct upstream tracking being configured. Fixed by
   dropping the explicit remote/branch args so git resolves the actual configured upstream instead;
   push calls untouched (those correctly need an explicit target name). This was previously-latent
   in the bash originals too (not a Go-port regression) — never surfaced because nobody had used
   `dashboard`/`ws-commit`/`agents` from an isolated worktree with a differently-named local branch
   before this test. **Not yet checked:** whether `xx-make-pr.sh`/`pr-amend-push` (bash + Go) have
   the same shape — deliberately not touched here, since those deal with PR branch names that can
   legitimately differ from a "source" branch by design, so each needs individual read-through
   before assuming the same fix applies, not a blind pattern replace.
2. **Open — launcher automation missing from `genesis-init`.** The genesis-generated setup has a
   fully working `starfleetctl agent-bus` (verified live: status/board/tell/inbox round-tripped
   correctly, own independent message numbering) but no `scripts/agent-run`,
   `agent-bus-boot-prompt`, `agent-bus-monitor-loop`, or `SessionStart`/`SessionEnd` hooks in
   `.claude/settings.json` — a `claude` session started there doesn't auto-register/auto-arm like a
   real "ship" does on `mtx/agent-config`. `genesis-init`'s current scope is the coordination
   primitives + file/dir scaffolding, not the ship-launcher ecosystem. Needs scoping: which of those
   pieces are generic enough to template into `genesis-init` too, vs. which stay
   mpbt-workspace/XLibre-specific tribal knowledge.
3. **Open — `genesis-init`'s embedded `DASHBOARD.md` template is stale.** It still says "Edit the
   theme file directly" instead of the CLI-only guidance from
   [[dashboard-access-fully-encapsulated-via-starfleetctl-no-direct]] (m0123) — the template wasn't
   updated when that policy landed on `mtx/agent-config`. Small, mechanical fix once picked up:
   update the embedded template string in `starfleetctl`'s `internal/genesis/templates/`.

Test artifacts still on disk, not yet cleaned up: `_WORK_/worktrees/mpbt-workspace/genesis-fleet-test`
(has a real `claude` session's transcript/context in it — praetor's call on when to remove) and
`_WORK_/worktrees/starfleetctl/fix-pull-tracking` (used for finding 1's fix, safe to remove anytime).
