XLibre MPBT workspace
======================

This is an [MPBT](https://github.com/metux/mpbt) workspace for building
[XLibre](https://github.com/X11Libre/) Xserver and ~54 drivers across
three release lines.

Warning: it's still an early work-in-progress.

Prerequisites
-------------

* [Go](https://go.dev) — to install `mpbt-builder`
* [GitHub CLI (`gh`)](https://cli.github.com/) — for the PR workflow
* [opencode](https://opencode.ai) — for AI-assisted development (install via `npm i -g opencode-ai` or your package manager)
* Meson, autotools, pkg-config, and usual Xorg build dependencies

### opencode setup

1. Install opencode (see https://opencode.ai/guide/installation)
2. Set up an API provider — either via the CLI:

       opencode providers

   or via the `/connect` command inside opencode's web UI (follows a link to
   obtain a token). Both store the credential globally in
   `~/.local/share/opencode/auth.json` — no project-level config needed.
3. Start a session:

       ./run-opencode.xserver-master

   The `run-opencode.*` scripts source the per-release config and set
   `XLIBRE_RELEASE` automatically.

### Shell integration (ship names)

Each interactive shell in the workspace gets a unique Star Trek ship name
(`STARFLEET_SHIP_ID`) used by the comms for session identity. Setup:

1. Add to `~/.bashrc` (or `~/.zshrc`):

       .starfleet-ai/bin/starfleetctl ship-names shell-env >/dev/null 2>&1 && \
         eval "$(.starfleet-ai/bin/starfleetctl ship-names shell-env 2>/dev/null)"

   Always use the workspace-local copy (`.starfleet-ai/bin/starfleetctl`),
   never a global install or symlink.

This sets `STARFLEET_SHIP_ID`, prepends the ship name to `PS1`, and installs
an `EXIT` trap to release the name when the shell exits. If
`STARFLEET_SHIP_ID` is already set (e.g. by a wrapper script), the existing
value is preserved.

Quick start
-----------

    ./install-mpbt                  # install mpbt-builder
    ./run-fetch.xserver-master      # clone/fetch all sources for master
    ./run-build.xserver-master      # build everything under master

Scripts reference
-----------------

| Script | Purpose |
|--------|---------|
| `install-mpbt` | `go install`s the `mpbt-builder` binary |
| `run-fetch.xserver-<release>` | Clone or fetch all sources for a release line |
| `run-build.xserver-<release>` | Build all packages (in solution order), then **delete** the install prefix |
| `run-opencode.xserver-<release>` | Start an opencode session for a release line (sets `XLIBRE_RELEASE`) |
| `starfleetctl github pr make` | Cherry-pick commits from incubator, push, create a PR, and rewrite commit messages with PR markers |
| `scripts/show-pr-conflict` | List all open PRs with merge conflicts (uses `gh`) |

Release lines
-------------

Since we have multiple release lines (25.0.x, 25.1.x, ...), this workspace
keeps them fully separate. Each release line has its own solution, git clone
set, and install prefix under `_WORK_/<release>/`.

| Solution | Xserver branch | Drivers built |
|----------|---------------|--------------|
| `xserver-master` | `master` | All ~54 drivers + xts + piglit |
| `xserver-25.1` | `release/25.1` | Only xserver (drivers commented out) |
| `xserver-25.0` | `release/25.0` | Only xserver (drivers commented out) |

Directory layout
----------------

    .
    ├── install-mpbt               installs mpbt-builder
    ├── run-fetch.xserver-*        fetch sources per release line
    ├── run-build.xserver-*        build per release line
    ├── run-opencode.xserver-*     opencode session per release line
    ├── cf/                        configuration (the "brain")
    │   ├── _common/               shared source of truth
    │   │   └── packages/xlibre/   package YAML defs + driver template
    │   ├── xserver-master/
    │   │   ├── config.sh          env vars for this release
    │   │   ├── packages/          symlinks + per-release overrides
    │   │   └── solutions/devuan.yaml  build order, flags, env
    │   ├── xserver-25.0/          same structure (all packages symlinked)
    │   └── xserver-25.1/          same structure (all packages symlinked)
    ├── scripts/
    │   └── show-pr-conflict       list conflicting PRs
    └── _WORK_/                    build artifacts (gitignored)
        └── <release>/             clones, build dirs, install prefix

Architecture: configuration system
-----------------------------------

### Package definitions

Three categories under `cf/<release>/packages/`:

* **`os-installed/`** — system packages (already on host), `type: system`
* **`3rdparty/`** — bundled dependencies MPBT builds (libdrm, piglit, etc.)
* **`xlibre/`** — the X server, drivers, and XTS; the main build targets

### Template/symlink system

Most drivers are **autotools-based** and share an identical build pattern.
Rather than repeating the same YAML 50+ times, there is a single template:

    cf/_common/packages/xlibre/generic-driver-autotools.tmpl.yaml

Each per-release driver `.yaml` is a **symlink** to this template.

Two drivers (elographics, wacom) are "common" drivers with their
own dedicated YAML in `_common/`, also symlinked per-release.

The symlinks are managed by `cf/xserver-master/packages/xlibre/update-generic.sh`.
After adding a new driver to that script, re-run it to create fresh symlinks.

Per-release overrides (like `xserver.yaml` and `xts.yaml`) are
real files, not symlinks — they live directly in each release's
`packages/xlibre/` directory.

### Solution files (`devuan.yaml`)

Each release has a solution file at `cf/<release>/solutions/devuan.yaml`
that controls:

* **`build:`** — build order (list of packages to build)
* **`package-config:`** — per-package meson flags and refs
* **`package-defaults:`** — shared vars (git URL, branch name per release)
* **`env:`** — `PKG_CONFIG_PATH`, `ACLOCAL_PATH` (pointing into install prefix)
* **`package-mapping:`** — resolves `provides:` names to actual packages

Cross-release differences
--------------------------

| | master | 25.1 | 25.0 |
|---|---|---|---|
| xserver branch | `master` | `release/25.1` | `release/25.0` |
| Drivers built | all ~54 | none (commented out) | none (commented out) |
| xts/piglit | yes | no | no |
| `-Dxfbdev=true` | yes | yes | no |
| `-Dxorg-sdk=true` | yes | no | no |
| `update-generic.sh` | has its own copy | N/A (all symlinked) | N/A (all symlinked) |

PR workflow
----------

    # git config entries (set automatically by run-fetch.*):
     [make-pr]
         upstream-remote = origin
         upstream-branch = master
         reviewers = X11Libre/dev

    # Create a PR from commits on the incubator branch:
    starfleetctl github pr make <commit> [<commit> ...]
    starfleetctl github pr make --branch my-pr-branch <commit> [<commit> ...]

The command:
1. Creates a temporary branch from the upstream ref
2. Cherry-picks the given commits, pushes, and creates a PR via `gh`
3. On the incubator branch only, rewrites the submitted commits' messages
   with a `[PR #NNNN]` prefix and `PR:` trailer (the pushed/merged PR branch
   itself is never touched again after the push, so its commits stay clean)

### Branch names: three namespaces belong to the tooling

Three prefixes are **owned by the tooling**. Don't hand-create branches that look
like ones it generates — the two collide in git's ref namespace, and the resulting
error does not name the real cause.

| Namespace | Created by | Notes |
|---|---|---|
| `wt/<name>` | `starfleetctl worktree add <repo> <name>` | Branch **and** path come from the command; `remove`/`prune` clean both up |
| `pr/<upstream>-<slug>_<timestamp>` | `starfleetctl github pr make` | The submitted PR branch |
| `tmp-pr/<upstream>-<slug>_<timestamp>` | `starfleetctl github pr make` | The staging branch for the cherry-picks, renamed to `pr/…` before the push |

That third row is the trap. The staging branch is `tmp-` + the PR branch name
(`internal/ghpr/xxmakepr.go:98,109`), so it is normally `tmp-pr/master-…` — fine. But a
branch named **exactly** `tmp-pr` occupies `refs/heads/tmp-pr`, and git then refuses to
create any ref underneath it:

    $ git branch tmp-pr
    $ git checkout -b tmp-pr/master-foo_x
    fatal: cannot lock ref 'refs/heads/tmp-pr/master-foo_x': 'refs/heads/tmp-pr' exists

That reads like a Git problem but is a directory-vs-file conflict in the ref namespace.
It kills every subsequent `tmp-pr/*` branch, and `pr make` aborts without explaining why.

**So:** never create `tmp-pr` yourself, and if it turns up, delete it
(`git branch -D tmp-pr`; also on origin). `tmp-` is reserved for the PR tooling. Use `wip/`
for your own staging branches.

Note that `tmp-pr-1` does *not* block anything — different ref name. It is almost always
the leftover of an aborted run: `pr make` cleans up on **none** of its six error paths,
deliberately, so a failed cherry-pick can be finished by hand. Check before a run:

    git branch --list 'tmp-*'

Anything else is yours to name: `rfc/*` incubator branches, `fix/*`, `submit/*`, `wip/*`.

**And work in your own clone.** The mpbt-managed source clones
(`_WORK_/<solution>/sources/**`) are shared — other agents read and build there. Write
nothing there; no `add`, no `commit`, no branch switch. Use `starfleetctl worktree add`,
`starfleetctl github pr checkout`, or your own clone. Before any write in a clone:

    git rev-parse --show-toplevel   # must be under _WORK_/worktrees, _WORK_/<solution>/agent, or a PR clone

Notes
-----

* **Install prefix is ephemeral.** `run-build.*` removes `_WORK_/<release>/install` after building. pkg-config and aclocal paths point into this prefix.
* **Tags are namespaced per remote.** Each repo is configured with
  `tagopt: --no-tags`, and tags are fetched into separate namespaces
  (`refs/tags/origin/*`, `refs/tags/xorg/*`).
* **No CI, tests, lint, or formatter.** The X Test Suite (xts) is a build
  target, not a test runner.
* **git branches.** Two branches on the remote: `master` and `wip1` (incubator).
* **`_WORK_/`** is gitignored. Only the `.gitignore` at the root is used.
