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

**2026-07-06 (praetor): explicit sequencing for this effort — two prerequisite steps before this branch gets real content, then a concrete end goal.**

1. **Prerequisite 1 — finish replacing all the *generic* (non-XLibre-specific) bash scripts with starfleetctl first.** That's the in-flight work: `agent-bus`, `dashboard`, `ws-commit`, `with-clone-lock`, `ship-names`, `pr-claim` need their bash originals fully retired, not just "cut over and preferred." Tracked elsewhere (the `starfleetctl` theme; directive `m0087` — Constellation, Monitor-loop bug, highest priority; `m0088` — Potemkin, `pr-checkout`/`backport-commit`/`ship-names`-caller switch). **Do not start porting content onto `wip/starfleet-upstream` before this is done** — there's no point drafting a master-side integration around bash scripts that are about to be deleted.
2. **Prerequisite 2 — port the minimal bootstrap mechanism onto this branch.** This is Farragut's in-flight "install-self"/Genesis-script work (directive `m0089`, `starfleetctl@15bd3f9` already landed on the `starfleetctl` side) — the piece where `starfleetctl` carries its own instructions and a generic `AGENTS.md` snippet just needs to know how to fetch/build it and pull the real instructions from there. That minimal bootstrap needs to actually exist *on* `wip/starfleet-upstream`, not just conceptually designed.
3. **End goal, once both are done:** it should be possible to **automatically stand up the entire fleet starting from a checkout of `wip/starfleet-upstream` alone** — no `mtx/agent-config` tribal knowledge required. A fresh clone of this branch + the minimal bootstrap + starfleetctl's self-contained instructions should be sufficient to fetch/build starfleetctl and re-derive everything needed to run the fleet, closing the exact gap Farragut's earlier Phase 3 finding flagged (fresh `master` clone has nothing to bootstrap with).

**Not yet assigned who does the actual content-porting** — that's still blocked on prerequisites 1 and 2 above landing first.
