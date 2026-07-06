---
slug: starfleet-upstream-master-prep
title: "Prepare starfleet fleet-coordination tooling for master (wip/starfleet-upstream)"
category: active
status: "**Branch + draft PR created 2026-07-06 (Enterprise, praetor request) — empty scaffold, content prep not started yet.**"
doc_ref: "Branch `wip/starfleet-upstream` (based on `origin/master`, not `mtx/agent-config`); draft PR https://github.com/X11Libre/mpbt-workspace/pull/2; isolated worktree at `_WORK_/worktrees/mpbt-workspace/starfleet-upstream/`"
---

Praetor request, 2026-07-06: a dedicated wip/testing/draft branch, based on `master` (not `mtx/agent-config`), to prepare generalizing the starfleet fleet-coordination tooling (`agent-bus`, `pr-claim`, `ship-names`, `starfleetctl`, `DASHBOARD.md`, `AGENTS.md`, related `.claude/settings.json` wiring) onto `master`. Directly related to the earlier-flagged blocker that a genuinely fresh `git clone` of `master` has none of this — see the `starfleetctl` theme's Phase 3 notes and the (separate, still-parked) `generalize-parts-of-mtx-agent-config-onto-master` theme.

**Done so far (Enterprise):** created `wip/starfleet-upstream` off `origin/master` in an isolated worktree (never touched the shared `mtx/agent-config` checkout other ships were using), pushed, opened draft PR #2 with a scope-notes scaffold (`STARFLEET-UPSTREAM.md` in that branch) — explicitly **not ready for merge**, just tracking the prep effort.

**Standing constraint carried over from `AGENTS.md`'s branch-hygiene rule:** promoting anything from `mtx/*` to `master` is a deliberate, per-item maintainer decision — nothing here should land on `master` without that, regardless of how much prep work accumulates on this branch.

**Next:** scope which pieces are genuinely generic/portable vs. workspace-specific tribal knowledge (see `STARFLEET-UPSTREAM.md`'s open questions); not yet assigned to a ship.
