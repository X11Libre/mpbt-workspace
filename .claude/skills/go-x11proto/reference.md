## go-x11proto, FlyingTux and starfleetctl are their own mpbt solutions

Since 2026-07-02, sister projects that aren't part of the xserver source tree itself are cloned
and (optionally) built by mpbt as **standalone solutions**, each deliberately kept **separate from
the xserver build** (own workdir, own `build:` list). This is the "all agent work on that project
now happens under the mpbt-workspace, instead of an ad-hoc external checkout" migration. Three
projects have been done this way so far — **go-x11proto**, **FlyingTux**, and **starfleetctl** —
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
  `scripts/xx-make-pr.sh` works from it, same as an xserver clone).

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
  `scripts/xx-make-pr.sh`'s assumptions (X11Libre remotes, `[PR #NNNN]` conventions, reviewers)
  don't apply to a personal repo.

**starfleetctl** (the Go CLI consolidating the flock/race-prone fleet-coordination scripts —
`agent-bus`, `pr-claim`, `ws-commit` — into one tool, `mpbt-hq/starfleetctl` — a private repo under
the `mpbt-hq` GitHub org, same non-X11Libre caveat as FlyingTux):

- Unlike go-x11proto/FlyingTux, there was no pre-existing external checkout to move — the code
  started life directly inside mpbt-workspace (branch `mtx/mpbtctl`, see the DASHBOARD.md
  `starfleetctl` row for the full history) and was extracted into its own repo once the praetor
  decided it should follow this same sister-project pattern rather than live in-tree or be folded
  into the `mpbt`/`mpbt-builder` Go repo itself (a third option that was considered and rejected —
  keeping it separate means it can be extracted/reused independently of the build orchestrator).
- **Build:** `buildsystem: exec` with `commands: build: [make]`, same shape as go-x11proto — plain
  Go, a `Makefile` that just runs `go build -o starfleetctl ./cmd/starfleetctl`. The built binary
  lands in the source checkout itself; no install step yet.
- No `make-pr.*` config, for the same reason as FlyingTux (not an X11Libre repo).
- **2026-07-06: moved from the personal `metux/starfleetctl` to `mpbt-hq/starfleetctl`** (Phase 5
  of the starfleetctl roadmap, see the DASHBOARD.md row — praetor-authorized org transfer, done
  via `gh api --method POST repos/metux/starfleetctl/transfer -f new_owner=mpbt-hq`). Still private,
  same `master` branch/history, just a different owner. Updated in the same pass: the local clone's
  `origin` remote, `cf/starfleetctl/solutions/default.yaml`'s `xlibre_git:` base URL, and the
  comments in `cf/starfleetctl/config.sh`/`.bin/starfleetctl` that named the old path. GitHub
  transparently redirects the old `metux/starfleetctl` URL, but every reference here now points at
  the canonical new one directly.
- Naming: picked to fit the workspace's existing Star-Trek ship-name/fleet theme (agent-bus board,
  `scripts/ship-names`, the `Enterprise` flagship) rather than the more generic original `mpbtctl`.
- **Gotcha: `./run-fetch.starfleetctl` does NOT fast-forward the local checkout to new upstream
  commits — it only updates the `origin/master` remote-tracking ref, leaving the checked-out
  `master` branch exactly where it was.** `./run-build.starfleetctl` then builds whatever is
  currently checked out, so it can silently build **stale** code even right after a fetch (`git
  branch -vv` will show e.g. `[origin/master: 2 hinterher]` — 2 commits behind — despite the fetch
  having just run). Hit 2026-07-06 (Farragut, Phase 3): built the new `bootstrap` subcommand,
  pushed, ran `./bootstrap` again expecting the new subcommand to be there — `run-build.starfleetctl`
  built the pre-push commit instead. Fix: `git -C _WORK_/starfleetctl/sources/xlibre/starfleetctl
  merge --ff-only origin/master` before rebuilding (safe — this clone should never have local
  commits of its own to lose, per the same reasoning `mk-agent-clone`-style isolation exists
  elsewhere in this workspace). Unconfirmed whether this is generic mpbt fetch behavior (likely
  applies to go-x11proto/FlyingTux too) or specific to how the `starfleetctl` solution's `ref:
  origin/master` is configured — not root-caused, just documented as a known gotcha to check for
  when "I just pushed but the built binary doesn't have my change" comes up.
- **Standing constraint: everything under the `mpbt-hq` GitHub org must stay independent of
  XLibre/xserver specifics.** This XLibre/mpbt-workspace usage is only the **first** major
  application of this tooling, not something it's allowed to be coupled to — a second, unrelated
  application ("sonicde") is already planned. No hardcoded `X11Libre/xserver` repo slug, no baked-in
  assumptions about xserver's release-line naming/layout, etc. — project-specific values stay
  configurable (env var/flag/config), never a literal in the Go code.
