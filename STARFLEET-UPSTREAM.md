# Starfleet upstreaming — draft/WIP

This branch is a staging area for preparing the "starfleet" fleet-coordination
tooling (agent-bus, pr-claim, ship-names, the `starfleetctl` Go CLI, DASHBOARD.md,
AGENTS.md, and related `.claude/settings.json` wiring) for eventual generalization
onto `master`, as opposed to living only on the maintainer's personal staging
branch `mtx/agent-config`.

## Why this exists

Today, `master` (this repo's actual default branch — what a plain `git clone`
checks out) has none of this: no `AGENTS.md`, no `DASHBOARD.md`, no `scripts/agent-bus`,
no `starfleetctl` wiring, no fleet-related hooks in `.claude/settings.json`. All
of it lives exclusively on `mtx/agent-config`. This was flagged as a real
structural blocker for fully-automatic bootstrap-from-a-fresh-clone (see
`dashboard/themes/` on `mtx/agent-config` for the "starfleetctl" theme's
Phase 3 notes).

Per `AGENTS.md`'s own "Licensing policy" / branch-hygiene conventions, promoting
anything from `mtx/*` onto `master` is **"a deliberate, separate, later decision
the praetor makes per item — don't propose or perform that promotion unprompted."**
This branch is where that preparation work happens *before* any such decision is
finalized — a draft, not a fait accompli.

## Status

**Just created, empty scaffold.** No content has been ported here yet. This PR
tracks the *preparation* effort; nothing here should be merged into `master`
without an explicit maintainer review and go-ahead per item, same as any other
`mtx/*` → `master` promotion.

## Scope (to be refined)

- Which pieces are genuinely generic/portable (candidates: `scripts/agent-bus`,
  `scripts/ship-names`, `scripts/with-clone-lock`, `scripts/ws-commit`,
  `scripts/pr-claim`, the `starfleetctl` Go CLI wiring) vs. which are
  workspace-specific tribal knowledge that should stay on `mtx/agent-config`.
- Whether `master` needs the full fleet stack, or just enough of a pointer/README
  so a fresh clone knows to `git checkout mtx/agent-config` for the rest.
- How this interacts with the ongoing `mpbt-hq`/`starfleetctl` self-contained-
  instructions work (starfleetctl increasingly carries its own `AGENTS.md`
  fragment — see the `starfleetctl` theme, directive m0089/m0097).
