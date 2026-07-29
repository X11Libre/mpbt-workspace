## go-x11proto and FlyingTux are their own mpbt solutions

Since 2026-07-02, sister projects that aren't part of the xserver source tree itself are cloned
and (optionally) built by mpbt as **standalone solutions**, each deliberately kept **separate from
the xserver build** (own workdir, own `build:` list). This is the "all agent work on that project
now happens under the mpbt-workspace, instead of an ad-hoc external checkout" migration. Two
projects currently use this pattern — **go-x11proto** and **FlyingTux** —
and they're the template for any future one:

- **Config:** `cf/<name>/{config.sh,solutions/default.yaml,packages/xlibre/<name>.yaml}`.
  `XLIBRE_RELEASE=<name>`, `WORKDIR=_WORK_/<name>`.
- **Clone lives at** `_WORK_/<name>/sources/xlibre/<name>` (gitignored, like all sources). It
  *replaces* the old external checkout, which was **moved** there (not re-cloned) so local
  branches/stashes/worktrees were preserved.
- **Wrappers:** `./run-fetch.<name>` (clone/fetch), `./run-build.<name>` (optional build),
  `./run-opencode.<name>`. Agents should `cd` into the clone above to work on it.
- Any other repo integrated into the fleet the same way follows this pattern: its own `cf/<name>/`
  + `run-*.<name>` wrappers, never folded into the xserver package set.

**go-x11proto** (the Go X11-protocol client lib + `xnamespace`/go-xts tools, `X11Libre/go-x11proto`):

- Clone *replaces* the old external `/home/nekrad/src/xorg/go-x11` checkout.
- **Tracks `staging`, not `master` (2026-07-06, praetor decision).** `staging` is go-x11proto's own
  equivalent of mpbt-workspace's `mtx/agent-config`: an accumulation branch for ongoing agent/dev
  work, freely committed to without a PR each time, **not** auto-merged into `master`. Promoting
  something from `staging` to `master` (a real PR — `make-pr.upstream-branch` below is still
  `master`) is a deliberate, separate, later decision. `demo/editor` (an xedit-style demo that had
  drifted onto `debian/maint-master` only) was ported to `master` first so `staging` starts from a
  clean base including it; first real `staging` payload was the `tk/widget` rich-text
  (Span/Highlighter) and `tk/term` (VT100/xterm terminal emulator) work built 2026-07-06.
- **Build:** the package uses `buildsystem: exec` with `commands: build: [make]` — go-x11proto is
  pure Go with a plain `Makefile` (no autotools/meson), so mpbt just runs `make` (which does the
  `go build`s). `make-pr.*` is configured on the clone (it's an `X11Libre` repo, so
  `.starfleet-ai/bin/starfleetctl github pr make` works from it, same as an xserver clone).

**FlyingTux** (the Python-based container/image-builder sister project, `metux/flyingtux` — a
**personal** GitHub repo, not `X11Libre`, so none of the xserver PR/backport/CI-repair conventions
apply to it):

- Clone *replaces* the old external `/home/nekrad/src/flyingtux` checkout, tracking its `master`
  branch (the current production/deployed code).
- **`master` vs the Go rewrite — deliberately tracks `master`.** There is a separate, already
  *complete but unmerged* full Go rewrite on branch `wip/golang-rewrite` (7 commits, in its own git
  **worktree** at `/home/nekrad/src/flyingtux-go` — see the DASHBOARD.md "FlyingTux" row for its
  status: `go build`/`go vet`/`go test` all clean, but not yet merged to `master` and not yet
  tested against real docker/X11). This migration intentionally mirrors go-x11proto's choice to
  track the repo's actual current default/production branch, **not** an unmerged rewrite — merging
  the Go rewrite is a separate, larger decision left to the praetor. `flyingtux-go` was **not**
  touched by this migration (still its own worktree, now pointed at the moved main worktree's
  `.git` after `git worktree repair`; see the gotcha below).
- **Worktree gotcha:** `/home/nekrad/src/flyingtux` (the `master` checkout) and
  `/home/nekrad/src/flyingtux-go` (`wip/golang-rewrite`) were **one repo as two linked git
  worktrees**, not two independent clones — `flyingtux-go/.git` is a file pointing at
  `flyingtux/.git/worktrees/flyingtux-go`. A plain `mv` of the main worktree breaks that absolute
  path. Fix: `mv` it anyway, then run `git worktree repair` **from inside the moved directory** —
  it detects and fixes the now-broken linked worktree's back-reference in both directions. Verified
  after the move: `flyingtux-go` still resolves, is still on `wip/golang-rewrite` at the same
  commit, clean working tree, all branches intact.
- **No real build step.** Plain Python, no `setup.py`/`pyproject.toml`, no compiled artifact — the
  package uses `buildsystem: exec` with **no `commands:` block at all**, which mpbt's exec builder
  treats as a documented no-op per stage (`core/workflow/exec.go`: `doExec` returns `nil`
  when the stage's command list is empty). `run-build.flyingtux` therefore just re-verifies the
  checkout and writes a source tarball; there's nothing to compile. (A `python -m compileall`
  smoke check was considered and rejected: the `master` tree has pre-existing Python-2-only syntax,
  e.g. `chmod(scriptname, 0755)` — an old-style octal literal — in
  `src/imagebuilder/flyingtux/app/deploy.py`, so a compile-all "build" would be red from day one for
  reasons unrelated to this migration. Not fixed here — out of scope, flagged as a Parkplatz item.)
- No `make-pr.*` config: FlyingTux isn't part of the xserver PR ecosystem and
  `.starfleet-ai/bin/starfleetctl github pr make`'s assumptions (X11Libre remotes, `[PR #NNNN]` conventions, reviewers)
  don't apply to a personal repo.

**starfleetctl** (the Go CLI consolidating the flock/race-prone fleet-coordination scripts —
`comms`, `github pr claim`, `ws-commit` — into one tool, `mpbt-hq/starfleetctl`) **used to** be a
sister mpbt solution like the two above, but **no longer is** (removed 2026-07-13). It now lives
solely under `.starfleet-ai/` and is managed by `./starfleet-bootstrap` — see the starfleetctl
skill and `agents.d/local/local-knowledge-dump.md`. Kept here for the still-relevant standing
constraint and a note on what was removed:

- **Removed 2026-07-13:** its mpbt solution (`cf/starfleetctl/`), the `./run-fetch.starfleetctl`
  / `./run-build.starfleetctl` wrappers, and the `_WORK_/starfleetctl/` clone. The workspace no
  longer keeps a second starfleetctl checkout; the source + built binary live at
  `.starfleet-ai/src/starfleetctl/` and `.starfleet-ai/bin/starfleetctl`. `.starfleet-ai/bin/starfleetctl`
  is now a thin wrapper that execs that binary.
- History: started life in-tree (branch `mtx/mpbtctl`), extracted to its own repo, then moved
  from `metux/starfleetctl` to `mpbt-hq/starfleetctl` (2026-07-06, praetor-authorized org
  transfer). Naming fits the workspace's Star-Trek ship-name/fleet theme.
- **Standing constraint: everything under the `mpbt-hq` GitHub org must stay independent of
  XLibre/xserver specifics.** This XLibre/mpbt-workspace usage is only the **first** major
  application of this tooling, not something it's allowed to be coupled to — a second, unrelated
  application ("sonicde") is already planned. No hardcoded `X11Libre/xserver` repo slug, no baked-in
  assumptions about xserver's release-line naming/layout, etc. — project-specific values stay
  configurable (env var/flag/config), never a literal in the Go code.
