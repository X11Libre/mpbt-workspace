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

**2026-07-07 (Enterprise): `genesis-setup` added — a fresh checkout of this
branch alone now bootstraps the entire fleet stack.** Rather than manually
porting `AGENTS.md`/`agents.d/`/`DASHBOARD.md`/`.claude/settings.json` content
piecemeal, this branch now carries the single `genesis-setup` script (copied
verbatim from `mpbt-hq/starfleetctl`, itself already parity-tested against a
truly empty repo — see that repo's `starfleetctl` theme, directive m0089's
follow-on entries). Running `./genesis-setup` clones+builds `starfleetctl` and
hands off to its `genesis-init` subcommand, which writes everything needed
from embedded, project-agnostic templates and never overwrites an existing
file. **Verified end-to-end against this branch's actual content** (not just
a synthetic empty repo): a scratch snapshot of this branch + `./genesis-setup`
produced a checkout where `starfleetctl bootstrap` reports all 6 checks green
(`_WORK_` tree, `scripts/ship-names.txt`, `.claude/settings.json` allowlist,
`AGENTS.md`+`agents.d/index.md`, `DASHBOARD.md`, the starfleetctl
self-fragment) — all generic/templated content, none of `mtx/agent-config`'s
XLibre-specific `agents.d/` fragments or DASHBOARD themes, by design (this
branch intentionally does NOT carry that content — see Scope below). This was
prerequisite 2 for the `mtx/agent-config` fleet-tooling generalization effort
(prerequisite 1, retiring the remaining bash-only `agent-bus`
`monitor-loop`/`fleet-watch` originals, completed the same day — see the
`starfleetctl`/`m0047` themes on `mtx/agent-config`). **Still not merged into
`master`, still a draft** — this only means a **direct clone of this branch**
now self-bootstraps; promoting any of it onto `master` remains the separate,
explicit maintainer decision this file's "Why this exists" section already
calls out.

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
