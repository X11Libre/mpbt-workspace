# AGENTS.md

## What this is

MPBT workspace that orchestrates building the XLibre X server and ~54 drivers across the release lines (`xserver-master`, `xserver-25.2`, `xserver-25.1`, `xserver-25.0`, and one more clone per future major release). Each release line gets its own git clones, build dirs, and install prefix under `_WORK_/<release>/` (gitignored).

## Working practices (standing instructions for agents)

These apply to **every** session — they keep knowledge and tooling from decaying as sessions are
cleared:

- **Record lessons learned in this file as you go.** Whenever you discover something non-obvious —
  a failure mode and how it presents, a gotcha in a workflow/script, a fact that took real digging
  to establish — append it to the relevant section of `AGENTS.md` (and the topic docs like
  `NVIDIA-ABI.md`) **within the session**, not at the end. Session context is wiped on `/clear`;
  only what's written here survives. Prefer a concise durable note over re-deriving it next time.
- **Keep `DASHBOARD.md` current — it's the cross-session "what's in flight / what got parked"
  index.** `agent-bus`/`pr-claim` are TTL'd live-status (minutes/hours); nothing durable tracked
  *themes* until now, so half-started ideas got lost between sessions. When you start, pause, or
  finish a theme (an initiative spanning more than one PR, or a decision still pending), update its
  row **in the same session** — same rationale as the lessons-learned rule above.
- **Notice something worth a look while doing unrelated work → add it to `DASHBOARD.md`'s
  Parkplatz immediately, don't just mention it in the response and move on.** A suspicious code
  path, a possible follow-up cleanup, an untriaged idea, a "this looks wrong but is out of scope
  right now" — the moment you'd otherwise say it in passing and keep going, add a Parkplatz row
  instead (one line: thema, where it was noticed — file/PR/commit, today's date, short why). This
  is the main way `DASHBOARD.md` stays populated: most finds happen as a side effect of other work,
  not during a dedicated triage pass. Don't add
  individual PRs or ephemeral status there; it links out to the detail doc/branch/PR instead of
  duplicating GitHub or `agent-bus`.
- **You may commit + push directly, without asking, on the maintainer's `mtx/*` workspace
  branches — any file, not just `AGENTS.md`.** Standing grant from the maintainer (broadened
  2026-07-02; originally scoped to `AGENTS.md` only): on `mtx/agent-config` (and other `mtx/*`
  branches), commit and push straight away whenever it's warranted — lessons/notes in `AGENTS.md`,
  `DASHBOARD.md` updates, new/changed `scripts/*`, config tweaks, whatever the session produced.
  Use `scripts/ws-commit -m <msg> <path...>` so it goes through the `with-clone-lock` mutex. No
  confirmation needed on those branches. (Other branches — anything not `mtx/*` — still follow the
  normal "ask before committing" rule.)
  **What `mtx/*` is for:** it's the maintainer's **personal staging branch** — freely accumulate
  lessons/docs/tooling there without asking each time. It is **not** auto-merged into `master`.
  Generalizing something onto `master` (so other users/contributors benefit, not just the
  maintainer) is a deliberate, separate, later decision the maintainer makes per item — don't
  propose or perform that promotion unprompted.
- **Project knowledge lives in this repo, not in per-user agent memory.** Lessons, CI gotchas,
  failure modes, workflow quirks and PR-repair findings go into `AGENTS.md` or a topic doc
  (`NVIDIA-ABI.md`, `CI-GOXTS-XEPHYR.md`, …) — version-controlled and shared with the whole team
  and with headless/CI runs. A machine-local per-user agent memory store (e.g. Claude Code's
  `~/.claude/.../memory/`) is private and invisible to teammates, so it must **not** hold project
  facts; reserve it for genuinely user-specific, cross-project preferences. And **never** create a
  `memory/` directory inside a source clone — it sits untracked in the upstream tree where a stray
  `git add -A` could commit it.
- **Turn repeated commands into scripts, then authorize them.** If you find yourself running the
  same multi-step command (especially GitHub/`gh` access like fetching CI job logs, querying
  checks, editing PR bodies), factor it into a generic `scripts/<name>` (match the existing style:
  `set -euo pipefail`, `REPO="${REPO:-X11Libre/xserver}"`, a `--help` banner, sane defaults) and
  add allow rules so it runs without a confirmation prompt. Add **both** forms —
  `Bash(scripts/<name>)` (no-arg invocations) **and** `Bash(scripts/<name> *)` (with parameters);
  the ` *` wildcard does *not* cover the bare call, so a no-arg run would still prompt without it.
  Invoke scripts as `scripts/<name>` (the relative form every rule matches), not by absolute path.
  Put the rules in the **checked-in `.claude/settings.json`** (committed, team-wide, durable) —
  *not* `.claude/settings.local.json`, which is gitignored and continuously rewritten by the
  harness's permission tracker, so hand edits there get clobbered. All of `scripts/*` is already
  authorized this way. Document the new script in the Key
  commands table. This is why `pr-job-logs`, `pr-checkout`, `pr-amend-push`, `show-branch-file`,
  `backport-applies`, etc. exist and are pre-authorized in `.claude/settings.json`.
- **C booleans: use `bool` (`<stdbool.h>`), not Xlib's `Bool`.** The legacy `Bool`/`TRUE`/`FALSE`
  typedef is being **phased out**. For any **newly introduced** boolean (variable, struct field,
  return type), use C99 `bool`/`true`/`false` and `#include <stdbool.h>`. Don't do sweeping
  `Bool`→`bool` churn in unrelated code, but prefer `bool` in new/rewritten code and when a change
  already touches the declaration. (First applied: the `shmSupported` flag in the `xf86bigfont`
  pagesize cleanup, PR #3201.)
- **Bash cwd persists silently across tool calls — after `cd`-ing into a nested clone under
  `_WORK_/` for one investigation, every later command in that session (including unrelated ones
  like `apt-get source`, `stat`, `git status`) keeps running there until you explicitly `cd` back
  or use absolute paths.** Bit twice in one session (2026-07-01): (1) it made an unrelated `git
  status`/`stat` on `mpbt-workspace/DASHBOARD.md` fail and look like file corruption, when the real
  cause was just running from inside an xserver agent clone; (2) `apt-get source libfontenc1` /
  `libxfont2` — run for read-only upstream-source investigation, not meant to touch any repo — each
  download into whatever the *current* cwd happens to be, once **inside the xserver clone itself**
  (leaving stray `libfontenc-1.1.8/`, `.dsc`, `.orig.tar.gz` etc. as untracked files in a shared
  clone) and once in the `mpbt-workspace` root. **Always `cd` into the scratchpad dir (or pass an
  absolute output path) before any ad-hoc source/package fetch for investigation** — never rely on
  "wherever cwd currently is" for a command whose output isn't meant to land in a repo.
- **Opening URLs (e.g. PR links) in the maintainer's browser.** In an **interactive local session**
  the Bash tool shares the maintainer's desktop session (`DISPLAY` set, dbus reachable), so you can
  open a link in their running browser with a plain local command — handy for handing over a PR to
  review. Do it **only on explicit request** (it's a visible side-effect on their desktop), and
  never in headless/CI runs (no display). The exact browser command is a per-user setting (don't
  hard-code a browser here — `xdg-open` follows the user's system default, which may not be the
  browser they actually use).

## Key commands

| command | purpose |
|---------|---------|
| `./install-mpbt` | `go install github.com/metux/mpbt/cmd/mpbt-builder@latest` |
| `./run-flagship [--detach]` | start a Claude Code **flagship** session (`AGENT_ID=Enterprise`, no `XLIBRE_RELEASE`); `--detach` launches it in a named tmux session via `agent-run` so it survives terminal close |
| `scripts/ship-names assign [flagship]` \| `release <name>` \| `list` \| `gc` | **Star Trek ship name registry** — each agent instance gets a unique ship name as its `AGENT_ID`. `assign` picks the next unused name (50 names, flock-serialized); `assign flagship` reserves `Enterprise` for the control/flagship session; `release` frees a name; `gc` reaps reservations with no live agent-bus heartbeat. Names shown in the shell prompt (PS1), Claude Code status line (⚓), and tmux session title. `Enterprise` is the reserved flagship — never auto-assigned to worker sessions |
| `./run-ship [--release <rel>] [--name <id>]` | start a plain Claude Code session with an auto-assigned, board-visible `AGENT_ID` (`<rel>-$$` or `ws-$$`); `--release` sources that project's `cf/<rel>/config.sh` first (accepts the same short/full/non-xserver forms as `run-opencode.*`). The explicit-launcher counterpart to `scripts/agent-bus-auto-id.sh` (which does the same thing implicitly, via `~/.bashrc`, for a plain `claude` started from a shell already inside the workspace tree) |
| `scripts/agent-bus-boot-prompt` | prints the default initial prompt `run-ship`/`run-flagship`/`agent-run --client claude` feed to a freshly-launched session when no explicit initial prompt/args were given — forces the session's first turn immediately at launch (instead of waiting for a human to type) so the `agent-bus-monitor-hint` SessionStart context actually gets acted on (arming the Monitor) right away. Branches on `$AGENT_ID`: for the flagship (`Enterprise`) it instructs arming **both** `agent-bus-monitor-loop` and `agent-bus-fleet-watch`; any other identity gets just the inbox watch |
| `scripts/agent-bus-monitor-loop` | the `Monitor`-tool `command` that watches this session's own agent-bus inbox and prints one line per new/unacked directive; identical invocation every session (reads `$AGENT_ID` from the environment, no session-specific args), so it's pre-authorized via a bare `"Monitor"` allow entry in `.claude/settings.json` — arming it needs no confirmation prompt |
| `scripts/agent-bus-fleet-watch` | sibling `Monitor`-tool `command` for a control/flagship session: watches `_WORK_/agent-bus/status/` and prints one line whenever a ship's heartbeat *epoch* changes — "New ship online: …" for a never-seen `AGENT_ID`, "Ship update: …" for a restart of a known one (seeds its known-set from the board at arm time, so only later changes are reported) — also covered by the bare `"Monitor"` allow. Auto-armed alongside `agent-bus-monitor-loop` for `AGENT_ID=Enterprise` sessions via `agent-bus-boot-prompt`/`agent-bus-monitor-hint` |
| `./run-fetch.xserver-<release>` | clone/fetch all sources for a release line |
| `./run-build.xserver-<release>` | full build of all packages in order, then **deletes** `_WORK_/<release>/install` |
| `./run-opencode.xserver-<release>` | start opencode session for a release line (sets `XLIBRE_RELEASE`) |
| `scripts/xx-make-pr.sh [--rebase|--branch <name>] <commits...>` | create PR from commits on the incubator branch |
| `scripts/mk-agent-clone <release> [name]` | create/refresh an agent-owned clone for backport work (object-shared, isolated from your clone) |
| `scripts/worktree add <repo> [name] [--from <ref>\|--branch <existing>]` \| `list [repo]` \| `remove <repo> <name> [--force] [--keep-branch]` \| `prune [repo]` | generic **worktree** helper for temporary/per-session/per-task isolation of **any** existing repo (not just xserver release lines — use `mk-agent-clone` for those, see why in its header). `add` defaults to a fresh throwaway branch `wt/<name>` off `origin/HEAD` (or the repo's current branch); `--branch <existing>` checks out an existing branch instead (git's normal one-worktree-per-branch guard still applies). All worktrees live under **this** workspace's `_WORK_/worktrees/<reponame>/<name>/` regardless of which repo they're for — one well-known, already-gitignored location. `remove` deletes the throwaway `wt/<name>` branch too, unless `--keep-branch` or it was checked out via `--branch`. Pre-authorized in `.claude/settings.json` |
| `scripts/backport-commit <release> <commit-ish\|PR#> [name]` | **one-shot backport**: refresh agent clone → `cherry-pick -x` → `xx-make-pr.sh`; opens the PR vs `release/<release>` |
| `scripts/show-branch-file <ref> <path> [symbol]` | print a repo file (or symbol region) at any ref via the GitHub API — for backport applicability checks; auto-handles the `Xext/<ext>/` ↔ `<ext>/` reorg |
| `scripts/backport-applies <master-path> <grep-ERE> [release ...]` | run the applicability grep across all release lines at once (wraps `show-branch-file`) — classify each branch vulnerable / already-fixed / N-A in one command |
| `scripts/pr-set-body <pr#> <body-file>` | set a PR body via REST API (works around the broken `gh pr edit`); for backport cross-linking |
| `scripts/pr-view <pr#> [json-fields]` | print PR metadata via `gh pr view --json <fields>` as one canonical, allowlistable command (default fields `number,title,state`) — exists so agents don't chain it after an unrelated `echo`/`export` (breaks `Bash(gh *)` prefix matching, see the AGENT_ID-export gotcha below); also covers the backport workflow's step-0 "already backported?" body check |
| `scripts/pr-append-body <pr#> <text-file>` | fetch a PR's current body, append the given text, write it back via `pr-set-body` — for backport-dashboard tables / back-links without manual fetch-then-set |
| `scripts/pr-comment <pr#> <body-file> [--bot-review]` | post a PR comment; `--bot-review` prepends the exact mandated bot-disclosure banner (see "Automated reviews") so the wording can't drift |
| `scripts/pr-label <pr#> add\|remove\|set-review <label...>` | add/remove PR labels via REST API (same `gh pr edit` workaround as `pr-set-body`); `set-review passed\|changes-requested` swaps the two `bot-review-*` outcome labels in one call |
| `scripts/pr-request-reviewers <pr#> <login...>` | request PR reviewers via REST API — wraps the HW-domain-routing recipe from "Automated reviews" |
| `scripts/pr-ci <pr#\|URL>` \| `--json` | **quick CI status of a PR** — one canonical command (give it a PR number *or* full PR URL, nothing else) so agents don't hand-assemble `gh pr checks`/`gh pr view --json statusCheckRollup` combos. Classifies every check **by conclusion, not count** (fail-fast means a big red number is usually a few `FAILURE` + many collateral `CANCELLED`): prints header + bucket counts (pass/FAIL/cancelled/pending/skip), lists the real failures + pending checks, a one-line verdict, and a known-flake hint (BSD/Solaris VM, xephyr-glamor timeout, go-xts) when the reds match. For the failure *logs*, use `pr-job-logs`. Pre-authorized in `.claude/settings.json` |
| `scripts/pr-job-logs <pr#>` \| `--job <id>` \| `<pr#> --all` | **fetch raw CI job logs + failure summary** for a PR's failing jobs (or one job by id). Wraps the reliable `repos/<repo>/actions/jobs/<id>/logs` endpoint (since `gh run view --log` returns nothing here) and greps the real cause across **build/link** (`FAILED:`, `: error:`, `undefined reference`), **configure** (meson `ERROR:`, `Dependency "x" not found`), **dep-install** (Gentoo `emerge`/`!!!`, Alpine `apk`, Debian `E:`, Arch, Fedora), and **test-phase** (`Summary of Failures`, `Fail: N`, `Caught signal`/segfault) failures; falls back to the log tail when no marker matches. Writes to `$OUTDIR` (default `mktemp -d`) |
| `scripts/pr-checkout <pr#> [name]` | **repair an open master PR**: isolated agent clone + check out the PR's head branch, ready to edit (prints the clone dir) — pairs with `pr-amend-push` |
| `scripts/pr-amend-push <clone-dir> [files...]` | fold edits into the PR's commit (`--amend --no-edit`, keeps message + `Signed-off-by`) and `--force-with-lease` back to the PR branch |
| `scripts/pr-claim <pr#> ["what"]` \| `--list` \| `--release <pr#>` \| `--steal <pr#>` | **advisory cross-agent PR lock + work log** so multiple agents don't collide on the same PR (each has its own clone, but they share one GitHub PR branch). Claim a PR before mutating it; `--list` is the shared "who's working on what" log. Keyed by PR#, `flock`-serialized, stale after `$CLAIM_TTL` (1h). Set a unique `$AGENT_ID` per agent. See Concurrency |
| `scripts/agent-bus status <state> ["note"]` \| `board` \| `inbox` \| `ack <id>` \| `tell <agent> <text>` \| `broadcast <text>` | **cross-session control plane** (status heartbeats + directives) so one control agent ("1st officer") can see and steer many independent sessions without terminal-hopping. Workers `status`/`inbox`/`ack`; the controller reads `board` and posts `tell`/`broadcast`. File-based + `flock`-serialized under `_WORK_/agent-bus/` (gitignored), heartbeats stale after `$BUS_TTL` (15m). Set a unique `$AGENT_ID`; `$XLIBRE_RELEASE` is the default project column; `$AGENT_HANDLE` (set by `agent-run`) is the board's ATTACH column. Sibling of `pr-claim` (that = PR-branch ownership; this = who's-doing-what + steering). See Concurrency |
| `scripts/agent-run <release> [--client claude\|opencode\|shell] [--name <id>] [-- <args>]` \| `--list` \| `--stop <id>` | **launch a session DETACHED in a named tmux session** so it survives terminal close / SSH disconnect and any number of controllers can attach. Works for any CLI (not just Claude). Registers the tmux session as the agent-bus `$AGENT_HANDLE` so it shows on the `board`. Needs `tmux`. See "Detaching sessions" in Concurrency |
| `scripts/agent-attach <id\|session\|partial>` \| `--read-only` \| `--independent` \| `--list` | **connect a controller to a detached agent** (tmux multi-attach — many controllers, same live session). `--read-only` = watch-only; `--independent` = own window size (grouped session). Resolves `<id>` against the board / tmux session names. Detach with `Ctrl-b d` (agent keeps running) |
| `scripts/fetch-nvidia-drivers [version ...]` | download proprietary NVIDIA `.run` installers and extract the X-server modules (no install) for ABI checks |
| `scripts/list-nvidia-versions [--per-branch]` | enumerate NVIDIA driver versions on the mirror (all, or latest-per-branch) |
| `scripts/fetch-all-nvidia-drivers [--every]` | fetch+extract many versions (default: latest of each branch; `--every` = all 500+), pruning `.run`s |
| `scripts/nvidia-abi-check SYM ...` | classify symbols against extracted blobs: link-import (`nm`) ∪ runtime lookup (string) |
| `scripts/nvidia-undefined-symbols [version ...]` | raw dump of imported (UND) symbols (subset of nvidia-abi-check; prefer the latter) |
| `scripts/json validate <file>...` \| `pretty [file]` \| `get <expr> [file]` | JSON helper so agents stop reaching for ad-hoc `python3 -c "import json…"` one-liners (each triggers a fresh auth prompt, since arbitrary `python3 -c` can't be safely wildcard-allowlisted). Reads a file arg or stdin (`gh api … \| scripts/json get …`). `validate` = parse + non-zero exit on bad JSON; `get` evals a Python expr against the parsed doc (bound to `data`). Pre-authorized in `.claude/settings.json` |
| `scripts/with-clone-lock <cmd...>` | run a mutating command holding an exclusive per-working-tree lock (see Concurrency) |
| `scripts/ws-commit -m <msg> <path...>` | atomically commit (+push) to **this** workspace repo under the `with-clone-lock` mutex — the safe way for agents to mutate the shared workspace checkout (`-a` = all tracked, `--no-push` = commit only). Use this instead of raw `git commit` here, so concurrent agent sessions don't race the index/HEAD (which produced bundled "1" commits) |
| `scripts/dashboard pull \| show \| write <file\|-> \| commit -m <msg> [--no-push]` | dedicated read/write/commit/push cycle for `DASHBOARD.md` specifically, since it's one of the most contended files in this repo (many concurrent sessions update it — see the "modified by another session" notes agents keep hitting). `pull`/`show` sync via `git pull --rebase --autostash` under `with-clone-lock` first (so you're editing fresh content, not a stale local copy); `write` replaces the file's content for scripted/non-interactive updates (does not commit); `commit` wraps `ws-commit -m <msg> DASHBOARD.md`. Interactive use: `dashboard pull` → edit with Read/Edit as usual → `dashboard commit -m "..."`. Pre-authorized in `.claude/settings.json` |
| `scripts/show-pr-conflict` | list all open PRs with merge conflicts |
| `scripts/cancel-stale-ci [--cancel] [--branch N] [--workflow N]` | cancel still-running CI runs whose branch moved on since they started (compares each run's head SHA to the branch's current tip; dry-run by default, `--cancel`/`-y` to act). Paginates all active runs; caches branch-tip lookups |
| `scripts/prune-stale-ci [--delete] [--keep-gone] [-v] [--branch N] [--workflow N]` | **delete** completed/outdated workflow runs whose branch moved on (head SHA ≠ current tip) **or whose branch was deleted** (clean 404). Dry-run by default (per-branch summary), `--delete` to act — **irreversible**. "Branch moved" deletes only when the tip is positively resolved and differs; gone-branch runs are deleted too unless `--keep-gone`; aborts on any non-404 tip-lookup error. Sibling of `cancel-stale-ci` (that one cancels *running* stale runs; this deletes *finished* ones) |
| `cf/xserver-master/packages/xlibre/update-generic.sh` | re-generate symlinks from the driver template for all generic drivers |

## Skills (`.claude/skills/`)

Checked-in Claude Code skills wrap the recurring multi-step workflows below as on-demand
slash commands / auto-triggered procedures. They're the *actionable checklist*; the prose
sections here remain the full reference. Keep them in sync when a workflow changes.

| skill | invoke | wraps |
|-------|--------|-------|
| `backport` | `/backport` | **Backport workflow** — applicability check → `backport-commit` → cross-link |
| `pr-repair` | `/pr-repair` | **PR repair workflow** — `pr-job-logs` → `pr-checkout` → local verify → `pr-amend-push` |
| `bot-review` | `/bot-review` | **Automated reviews** — bot banner, backport-worthiness, NVIDIA-ABI check, label (named `bot-review` to avoid the built-in `/review`) |

## Architecture

- **`cf/_common/packages/xlibre/`** — shared package YAML definitions (the source of truth)
- **`cf/<release>/packages/xlibre/`** — per-release overrides; most driver files are **symlinks** back to `_common/`
- **`cf/<release>/solutions/devuan.yaml`** — the solution file: build order, env vars, meson-extra-args
- **`cf/<release>/config.sh`** — sets `XLIBRE_RELEASE`, `PATH`, `MPBT`, `SOLUTION`, `WORKDIR`

Build order and which packages to build is defined in each solution's `build:` list.

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
  the Go rewrite is a separate, larger decision left to the maintainer. `flyingtux-go` was **not**
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
  treats as a documented no-op per stage (`core/workflow/build/exec.go`: `doExec` returns `nil`
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
`agent-bus`, `pr-claim`, `ws-commit` — into one tool, `metux/starfleetctl` — a **personal** GitHub
repo, private, same non-X11Libre caveat as FlyingTux):

- Unlike go-x11proto/FlyingTux, there was no pre-existing external checkout to move — the code
  started life directly inside mpbt-workspace (branch `mtx/mpbtctl`, see the DASHBOARD.md
  `starfleetctl` row for the full history) and was extracted into its own repo once the maintainer
  decided it should follow this same sister-project pattern rather than live in-tree or be folded
  into the `mpbt`/`mpbt-builder` Go repo itself (a third option that was considered and rejected —
  keeping it separate means it can be extracted/reused independently of the build orchestrator).
- **Build:** `buildsystem: exec` with `commands: build: [make]`, same shape as go-x11proto — plain
  Go, a `Makefile` that just runs `go build -o starfleetctl ./cmd/starfleetctl`. The built binary
  lands in the source checkout itself; no install step yet.
- No `make-pr.*` config, for the same reason as FlyingTux (personal repo, not X11Libre).
- Naming: picked to fit the workspace's existing Star-Trek ship-name/fleet theme (agent-bus board,
  `scripts/ship-names`, the `Enterprise` flagship) rather than the more generic original `mpbtctl`.

## Template/symlink system

Most ~54 drivers are autotools-based and use the same build pattern.
Instead of repeating YAML 54 times:

- **Template:** `cf/_common/packages/xlibre/generic-driver-autotools.tmpl.yaml`
- **Symlinks:** each per-release driver `.yaml` is a symlink to the template
- **Special cases:** `xserver` uses meson; `elographics` and `wacom` have their own YAML
- **Regeneration:** `cf/xserver-master/packages/xlibre/update-generic.sh` creates all symlinks

Only xserver uses meson. Solution files set `meson-extra-args` per-package.

## Important quirks

- **Only `xserver-master` builds all drivers + xts + piglit.** The 25.0/25.1 solutions have nearly all drivers commented out — only xserver itself is built.
- **`xserver-master`** uses `-Dxorg-sdk=true` and `-Dxfbdev=true`; `xserver-25.1` has `-Dxfbdev=true` but not `-Dxorg-sdk`; `xserver-25.0` has neither.
- **Install prefix is ephemeral.** The `run-build.*` scripts remove `_WORK_/<release>/install` after building (though the actual install prefix configured in devuan.yaml is `{workdir}/target`).
- **pkg-config & aclocal paths** are set per-solution in `devuan.yaml` `env:` — they point into the install prefix.
- **Tags are namespaced per remote** (e.g., `refs/tags/origin/*`, `refs/tags/xorg/*`). Repos use `tagopt: --no-tags` to prevent tag clutter; tags are fetched manually.
- **Xserver meson flags** vary by release (see devuan.yaml `package-config:`), generally include `-Dxephyr=true`, `-Dxnest=true`, `-Dxvfb=true`, `-Dxorg=true`, `-Dxf86-input-inputtest=true`, `-Dtest_xephyr_gles=false`.
- **XLibre has removed server regeneration (no internal reset).** `dix/main.c` runs the init sequence **once**, calls `Dispatch()`, then tears down and `return 0` — there is no regeneration loop, `serverGeneration` does not appear in `main()`, and `-noreset` is explicitly *"removed in XLibre"* (`os/utils.c`). Consequence for review: the old XFree86 `if (xxxGeneration != serverGeneration) { … }` re-init guards are now **vestigial**, and process-lifetime statics used as once-only init flags are **safe** (no second generation to reset them for). This is why dropping such guards (PR #1455) is correct on master — but **NOT** automatically safe to backport to a release line that may still regenerate.
- **A static lib linked into two loadable modules → duplicate symbols with per-copy statics.** The Xorg (xfree86) DDX loads code as separate `dlopen`'d modules, and a `static_library` can end up compiled into more than one of them: `libxserver_glx` (containing `Xext/glx/glxext.c`) goes into **`extensions/libglx.so`** via `link_whole:` *and* into **`libglamoregl.so`** via `link_with:` — the latter transitively, because the `glamor` lib's `glamor_egl.c` referenced `xorgGlxCreateVendor()`, dragging `glxext.c.o` in to resolve it. Result: on Xorg, `xorgGlxServerInit`/`xorgGlxCreateVendor` exist at **two addresses, each with its own file-scope `static` storage** — so a `static`-once guard in such a function silently fails to work (each copy has its own flag), and gdb shows two same-named functions. A **monolithic** server (kdrive `Xfbdev`, which links the archive once into the executable) doesn't have this. Diagnose with `nm <module>.so | grep <sym>` on each module. #3174 fixed the glx instance by removing the cross-reference (`glamor_egl.c` no longer calls `xorgGlxCreateVendor`), so `glxext.c.o` is no longer pulled into `libglamoregl.so`. Same family as the latent double-compile of `dpms.c` (the #3022 repair): watch for a source/object appearing in two link targets that are both loaded at once.

## CI platform lanes — Docker images + VM builds

The `Build X servers` workflow (`.github/workflows/build-xserver.yml`) fans out one
job per platform. Two non-obvious mechanisms:

- **Content-addressed deps images (build-if-missing).** The gentoo and ubuntu base
  images are built by in-pipeline jobs (`gentoo-deps-image`, `ubuntu-deps-image`)
  whose **image tag is a sha256 of the image's build inputs** (Dockerfile + the
  install scripts + `conf.sh`/`util.sh`); the job does a `docker manifest inspect`
  and **only builds when that exact tag is missing**, else reuses (a few-second
  check vs a ~15–22 min rebuild). `:latest` is moved only by master. The per-commit
  SDK (`build-sdk-image`) builds `FROM` the content-hashed ubuntu base via the SDK
  Dockerfile's `ARG BASE` + a `--build-arg BASE=…/xserver-ubuntu-build:<hash>`, so a
  WIP branch's SDK is built on exactly the deps that branch defines (no staleness).
  This replaced the standalone `gentoo-image.yml`/`ubuntu-deps-image.yml`/
  `sdk-image.yml` (PR #3180), which rebuilt per-branch and let WIP branches consume a
  stale master `:latest`. **Gotcha:** `ubuntu-deps-image`/`build-sdk-image`/
  `drivers-build-ubuntu` are **abi-gated** (`if: abi_changed || tag`), so a
  workflow-only PR **skips** them — the ubuntu/SDK chain is exercised only on a real
  ABI-changing commit (gentoo is *not* abi-gated and always runs).

- **GNU/Hurd has no vmactions VM — it's a hand-rolled QEMU boot** (`xserver-build-hurd`
  → `.github/scripts/hurd/run-vm-build.sh`, PR #3179). Hard-won boot recipe:
  - The amd64 Hurd image uses **rumpdisk** for SATA, so the disk MUST be attached via
    **`-M q35` + an `ich9-ahci` AHCI controller** (`-device ich9-ahci` + `ide-hd
    bus=ahci.0`). The default i440fx IDE disk yields an `ext2fs` I/O error and never
    boots.
  - **gnumach boots single-CPU only** — no `-smp`.
  - GRUB + gnumach log to **VGA only**; patch `grub.cfg` to add a **serial console**
    (`serial`/`terminal_*` + `console=com0` on the multiboot line) so the boot is
    visible under `-nographic` (otherwise it looks like a silent hang).
  - **`/dev/kvm` exists on GH runners but isn't accessible to the runner user** —
    `sudo chmod 666 /dev/kvm` (fall back to `-accel tcg` if unavailable).
  - **VM boot flakes transiently** → retry the boot up to 3×.
  - In-VM (`run-xserver-build.sh`): the toolchain install (git/meson/ninja/pkg-config)
    is **fatal**, the X protocol libs are **best-effort**. The lane now **fatally
    builds every server that compiles on Hurd** in one meson run —
    `-Dxvfb -Dxnest -Dxorg -Dxephyr -Dglx` — with `dri*`/`glamor`/`xfbdev`/`udev`/
    `logind` off (PR #3193). ~12–13 min total.
  - **What builds on Hurd today (final: PR #3179 added the lane, #3193 made it
    build all five servers).** The gaps below were surfaced one at a time by
    disabling the previous blocker; the review of #3193 (stefan11111) then
    established that glx + Xephyr build too:
    | server / flag | result |
    |---|---|
    | Xvfb, Xnest | ✅ build |
    | `-Dxorg` (xfree86) | ✅ builds — `Linking target hw/xfree86/Xorg` (unaccelerated) |
    | `-Dxephyr` | ✅ builds — but needs `libxcb-xv0-dev` (else meson setup errors `Dependency "xcb-xv" not found`); it runs as an X client over XCB, not the kdrive linux VT/input path |
    | `-Dglx` | ✅ builds **without libdrm** (software/indirect GLX) |
    | `-Ddri1/2/3` | ❌ `hw/xfree86/dri/dri.c` → libdrm's `<drm.h>` pulls a nonexistent `mach/x86_64/ioccom.h` — Hurd has no DRM kernel interface |
    | `-Dglamor` | ❌ `glamor/glamor_egl.c` → `DRM_FORMAT_MOD_INVALID` undeclared + needs GBM (GBM needs DRM) — confirmed non-buildable on Hurd |
    | `-Dxfbdev` (kdrive fbdev) | ❌ builds `hw/kdrive/linux/linux.c` → needs Linux VTs `<linux/vt.h>` — would need a dedicated **Hurd kdrive backend** |

    Takeaways: the **xfree86 Xorg server + Xephyr + GLX build cleanly on GNU/Hurd**
    (unaccelerated). The remaining blockers are **fundamental, not port bugs**: DRI
    and glamor need a DRM kernel interface Hurd lacks. The one **real** open port
    task is a **Hurd kdrive backend** for `xfbdev` (the Linux-VT dependency). Note
    `libdrm-dev` *does* exist on Hurd (`debian-ports`, `2.4.107+hurd`) — installing
    it isn't the DRI blocker; the missing Mach ioctl header is.

- **RHEL/AlmaLinux lane** (`xserver-build-rhel`, PR #3172). Matrix `rhelver: ['9','10']` on
  `almalinux:9`/`:10` containers — AlmaLinux is an ABI-identical RHEL rebuild and stands in for
  RHEL because the real UBI images can't enable **CRB** without an entitlement on public runners.
  `install-pkg.sh` enables **EPEL + CRB** (most X `-devel` packages live in CRB), then `dnf`-installs
  the deps. Two gotchas hit while adding it:
  - **`xorg-x11-font-utils` does not exist on RHEL 9/10** (dropped, not in EPEL/CRB) — and it is
    **not** a build dep (`meson.build` uses `dependency('fontutil', required: false)` with a
    `$datadir/fonts/X11` fallback). Don't list it; it just aborts `dnf`.
  - **RHEL 10's gcc 14 raised `-Werror=format-truncation`** in `os/Xtranssock.c` `set_sun_path()` —
    a false positive (a manual length pre-check already prevented truncation, but GCC couldn't
    connect it to the `snprintf` bound). Fixed at source by checking the `snprintf` return value
    instead (#3176, `set_sun_path`), so the lane runs **`-Dwerror=true`** like the other Linux jobs.

- **`-Dwerror=true` status per lane** (probe June 2026). Lanes build clean under werror and have it
  **on**: `ubuntu*`, `rhel` (after #3176), and — after **#3196** — **`solaris`/`gentoo`/`openbsd`**.
  That PR fixed the two real warnings the probe surfaced and flipped those three lanes:
  - **`gentoo`** — `test/bigreq/request-length.c` ignored `write()`'s return (`-Werror=unused-result`);
    now checked. (Its *old* `werror=false` reason, format-truncation in `set_sun_path`, was already
    gone — fixed by #3176.)
  - **`openbsd`** — `os/client.c` declared the `/proc` vars `path`/`totsize`/`fd` on OpenBSD too,
    where the `kvm_getprocs` branch doesn't use them (clang `-Wunused-variable`); fixed by excluding
    `__OpenBSD__` from the declaration guard.
  - **`solaris`** — was already clean; just flipped.
- **`alpine` is the one lane that stays `-Dwerror=false`, and it's *not* our bug to fix.** On musl,
  libbsd's `<bsd/sys/cdefs.h>` pulls the system `<sys/cdefs.h>`, which emits a `#warning`
  (*"usage of non-standard #include <sys/cdefs.h> is deprecated"*) that `-Werror` (`-Werror=cpp`)
  turns fatal in **every** TU that uses libbsd (miinitext, gtf, present, vblank, …). It's a
  musl/libbsd toolchain quirk, unfixable in-tree without suppressing the whole `cpp` warning class —
  so the lane stays werror-off, documented inline in `build-xserver.yml`.

- **NetBSD lane has a scoped GitHub-hosted dependency mirror (to dodge ftp/cdn.netbsd.org flakes).**
  `xserver-build-netbsd` used to install its deps straight from the official NetBSD mirrors, which
  flake intermittently (`pkg_add: ... Undefined error: 0`, all 3 internal retries exhausted — the
  same BSD/Solaris VM-flake class as the vmactions jobs; hit on **PR #3225**, 2026-07-03, reddening
  an Ubuntu-only diff). Fix (**PR #3243**, opened not merged): a **scoped** mirror of *just* what
  this job needs — the pkgin dependency closure of the build's package list + the 5 X11 OS-release
  binary sets, ≈230 MB (vs ~65 GB full pkgsrc) — hosted as assets of a **stable GitHub Release
  `netbsd-pkgsrc-mirror`** in `X11Libre/xserver`. `install-pkg.sh` now tries the mirror **first**
  and falls back to the official mirrors (soft fallback, not a hard cutover). The package list +
  release/arch + all URLs live in one shared **`.github/scripts/netbsd/mirror-conf.sh`** sourced by
  both `install-pkg.sh` and the sync. **To refresh/poke the mirror:** run the weekly
  **`.github/workflows/netbsd-pkg-mirror.yml`** (`Refresh NetBSD pkg mirror`, also
  `workflow_dispatch`) — it boots the *same* `vmactions/netbsd-vm` image the build lane uses, drives
  the real `pkgin -d install` (download-only, cache = `/var/db/pkgin/cache`) to get the
  authoritative closure (no hand-rolled resolver), builds a **trimmed `pkg_summary.gz`** (a strict
  *subset* of the official summary, so `FILE_SIZE`/metadata stay byte-consistent — pkgin verifies
  size, there's no checksum field), and `gh release upload --clobber`s + prunes stale assets
  (`publish-mirror.sh`). **Gotchas / assumptions:** (1) the mirror release must be populated by one
  `workflow_dispatch` run before the mirror-first path finds anything (until then the lane just uses
  the official fallback); (2) the closure matches the build only because sync-VM-image ==
  build-VM-image (both `netbsd-vm@v1.2.3` release `10.1`); (3) unverified without a live VM: whether
  pkgin's libfetch follows GitHub's 302 release-asset redirect for `pkg_summary.gz`/`.tgz` (the
  fallback exists precisely to cover this if it doesn't); (4) `<rel>/All` 302-redirects to a dated
  quarterly (`10.0_2026Q1/All`) that moves over time — the sync follows it with `curl -L`, never
  hardcode the date. Debugging the awk trim: reading the keep-list must happen under the default
  `RS="\n"` *before* switching to paragraph mode `RS=""`, else the whole keep-list slurps into one
  key and nothing matches.

## PR workflow (`scripts/xx-make-pr.sh`)

Requires git config entries (these are automatically added by the run-fetch* scripts):

```ini
[make-pr]
    upstream-remote = origin
    upstream-branch = master   # or release/25.1, release/25.0
    reviewers = X11Libre/dev
```

The script cherry-picks commits onto a temp branch based on `$upstream_remote/$upstream_branch`, pushes, creates a PR (via `gh`), then rewrites commit messages with `[PR #NNNN]` prefix and `PR:` trailer, and rebases the incubator branch.

**Commit-message trailer convention — `Signed-off-by` only, NEVER `Co-Authored-By`.** Commits in
all these repos (xserver and the drivers) carry a `Signed-off-by:` trailer (kernel/X.org style)
and nothing else. Do **not** append a `Co-Authored-By:` line (e.g. an AI co-author) — the
maintainer does not want it in the history. This overrides any agent/harness default that says to
add one. Use `git commit -s` (or write the `Signed-off-by` explicitly) and stop there.

**The `[PR #NNNN]` prefix + `PR:` trailer belong ONLY on the incubator branch (`rfc/backport-*`) — never on the PR branch or the merged upstream commit.** The PR is pushed *before* the PR number exists, so the pushed/merged commit must keep its clean original message. Leak seen on master: PR #3162 merged 4 commits all prefixed `[PR #3162]`. Root cause — `xx-make-pr.sh` `DEFAULT_MODE="rebase"`: rebase mode runs the `[PR #N]` `sed` + `PR:` `--exec` rewrite against the **PR branch** `$BRANCH_NAME` (the head that gets merged), not just the incubator (the in-script comment even says *"markers added to PR branch"*). The clean `incubator` mode rewrites only the incubator, but it uses `git rebase -i` (interactive), which is unsupported in this environment — which is why the default was flipped to the contaminating `rebase` mode. **Until the script is fixed (apply the marker `--exec` to the *incubator* rebase only, leave `$BRANCH_NAME` untouched, and make that path non-interactive via `GIT_SEQUENCE_EDITOR=true`/no `-i`): before merging any `xx-make-pr.sh` PR, verify the PR head's subject line is clean (no `[PR #…]`).** A second leak vector: re-running `xx-make-pr.sh` on an incubator commit that is *already* prefixed re-cherry-picks the prefix onto the fresh PR branch — always submit the clean commit. (Already-merged prefixed commits are left as-is; no master history rewrite.)

**Always pass `xx-make-pr.sh` an explicit commit SHA — never the symbolic `HEAD`.** The script first
`git checkout`s a fresh `tmp-pr/…` branch off `origin/<upstream-branch>`, *then* resolves the commit
argument to cherry-pick. A literal `HEAD` therefore re-resolves to the just-checked-out temp branch's
tip (= current `origin/master`), so it cherry-picks master's own tip onto itself — which conflicts /
empties and bails with `Cherry-pick of HEAD failed`, leaving a half-done `tmp-pr/…` branch and a
`CHERRY_PICK_HEAD` in progress. Recover with `git cherry-pick --abort`, `git checkout <your-branch>`,
`git branch -D tmp-pr/…`, then re-run with the real SHA (`git rev-parse HEAD` first if unsure). (Hit
2026-07-01 creating the CSRG_BASED-cleanup PR #3211 — passing `HEAD` grabbed the freshly-merged
go-x11proto-bump commit instead.)

**Cherry-pick conflict recovery (master moved under you).** The script `git fetch`es then cherry-picks
onto a *fresh* `origin/<upstream-branch>` tip. If upstream advanced and touched the same region as
your commit, the cherry-pick conflicts and the script bails, leaving a half-done `tmp-pr/…` branch.
**Do not** try to fix it by rebasing the whole incubator (`rfc/backport-*`) onto the new tip — the
incubator carries unrelated pending commits that bring their own conflicts. Instead reproduce just
the final steps by hand: `git checkout -b <pr-branch> origin/<upstream-branch>`, `git cherry-pick
<sha>`, resolve the one conflict, build-verify, `git push origin <pr-branch>`, then `gh pr create
-B <upstream-branch> -H <pr-branch> --reviewer "$(git config make-pr.reviewers)"`. (Seen creating
#3130: master had just re-parenthesized the same `include/list.h` macro the commit edited.)

## xorg upstream tracking (what's new on `xorg/main`)

We follow the upstream X.org server (`xorg` remote → `xorg/main`; note `xorg/master` is
**closed/superseded**, ignore it). XLibre is a long-diverged fork (thousands of commits each side),
so a plain `origin/master..xorg/main` patch-id diff is **useless** — it reports hundreds of false
"missing" commits (already fixed differently, reverts of *our* changes, fork divergence).

**Use the tracking branches instead.** For master and **every** release line there is a marker
branch **`tracking/xorg/main-on-<rel>`** (`…-on-master`, `…-on-25.2`, `…-on-25.1`, `…-on-25.0`) that
points *into* `xorg/main` history at the **last upstream commit already evaluated** for that line.
The only set to consider is therefore:

```bash
git -C <clone> fetch xorg
git -C <clone> log --reverse --no-merges --oneline <tracking-branch>..xorg/main   # the genuinely-new commits
```

Workflow per new commit: classify (already-in-tree / N-A / take it), and for the relevant ones open
a master PR (cherry-pick `-x` to preserve provenance + author, add your `Signed-off-by`; for an
upstream subsystem we dropped — e.g. **Xwayland was removed**, commit `c8b81fdbc5` — it's N-A).
Once the whole delta is dispositioned, **advance the tracker** to the `xorg/main` tip (a fast-forward
along `xorg/main`, no force): `git push origin <xorg/main-sha>:refs/heads/tracking/xorg/main-on-<rel>`.

- **Every existing release line MUST have its own tracker.** When a new release line is branched
  (e.g. `release/25.3`), create `tracking/xorg/main-on-25.3` at the same upstream point as the
  others (or the current synced tip): `git push origin <sha>:refs/heads/tracking/xorg/main-on-25.3`.
  (Audit: `git branch -r | grep -E 'origin/(release/|tracking/xorg/main-on-)'` — every `release/<rel>`
  needs a matching `tracking/xorg/main-on-<rel>`.) The `25.2` tracker was once missing and had to be
  added this way.
- Advancing a **release** tracker encodes the decision "nothing in this delta needs backporting to
  that line" — only do it once that's actually true (a release-relevant security/critical fix in the
  delta must be backported first; see the Backport workflow below).

## Backport workflow (master PR → release branches)

> **NEVER auto-merge into `release/*` branches.** Merges into any release line
> (`release/25.2`, `release/25.1`, `release/25.0`, …) happen **only manually, by the maintainer**.
> A green CI run and a clean bot-review are **not** sufficient to merge a release PR — agents open
> and cross-link the PR and then **stop**. Fixes for existing releases must always be reviewed
> independently and manually (applicability + correctness, confirmed per branch), regardless of CI
> status. (Auto-merge is only ever acceptable on `master` PRs — and even there only when the user
> explicitly asks for it.)

Backporting a merged **master** PR means applying its changes to every applicable release
line, each worked in **its own clone**. Agents must use a dedicated agent-owned clone created
with `scripts/mk-agent-clone <release>` (see Concurrency / isolation) — not the user's
hand-edited `_WORK_/xserver-<release>/sources/xlibre/xserver` tree. Switch to the matching
release; don't try to do it all from one clone.

Each release clone has a dedicated incubator branch and a matching `make-pr.upstream-branch`:

| Clone | Incubator branch | `make-pr.upstream-branch` |
|-------|------------------|---------------------------|
| `xserver-25.2` | `rfc/backport-25.2` | `release/25.2` |
| `xserver-25.1` | `rfc/backport-25.1` | `release/25.1` |
| `xserver-25.0` | `rfc/backport-25.0` | `release/25.0` |

(Each future major release adds its own clone + `rfc/backport-<release>` branch.)

Procedure, per applicable release:

0. **Check whether it's already been backported before doing anything else:**
   `gh pr view <master-pr#> --repo X11Libre/xserver --json body -q .body` — if a "Backport
   dashboard" table is already present, another (possibly now-finished/invisible-on-the-board)
   session already did this PR; read the linked backport PR numbers instead of re-running the
   workflow. Skipping this step produces byte-identical duplicate PRs and duplicate cherry-picked
   commits in the shared `rfc/backport-<release>` incubator. (Hit 2026-07-03: `agent-bus board`
   only shows *currently running* agents — a session that finished before a suspend/reboot leaves
   no trace there, so the board being "empty of workers" does NOT mean a PR hasn't already been
   backported. Recovered cleanly because `backport-commit`'s incubator rebase never got pushed —
   the divergence was caught locally — but always check first regardless.)
1. **Check applicability** by inspecting the actual code on that branch — the fix may already
   be present, or the buggy code may not exist / not be vulnerable there. (See
   `VULN-FIX-BACKPORT.md` for an example applicability matrix.) Use
   `scripts/show-branch-file <release-branch> <master-path> '<symbol>'` to read the relevant
   function on each release branch straight from GitHub (it auto-resolves the
   `Xext/<ext>/` ↔ `<ext>/` directory reorg between newer and older releases). If it's already
   contained or N/A, **don't open a PR** — just record that in the dashboard.
2. **Apply + submit in one shot** with `scripts/backport-commit <release> <commit-ish|PR#>`. It
   refreshes the isolated agent clone (`mk-agent-clone`), `cherry-pick -x`'s the commit onto
   `rfc/backport-<release>` (keeping the original message + `Signed-off-by` and appending the
   `(cherry picked from commit <sha>)` line), then runs `xx-make-pr.sh` to push the PR against
   `release/<release>` and mark the incubator with a `[PR #NNNN]` prefix + `PR:` trailer.
   Passing a PR number resolves its merge commit automatically. If the cherry-pick fails only
   because the file moved (the `Xext/<ext>/` ↔ `<ext>/` reorg between master and the older
   releases), it auto-remaps the diff's paths and applies it, reconstructing the same commit —
   so cross-reorg backports are one-shot too. Only a genuine **content** conflict bails; then
   you do a manual/adapted backport in the agent clone and `scripts/xx-make-pr.sh <sha>` from
   inside it.

   (The underlying `mk-agent-clone` + `cherry-pick -x` + `xx-make-pr.sh` steps can still be run
   by hand if you need finer control — `backport-commit` just chains them.)

**Cross-linking (required):**

- The **original master PR** gets a "Backport dashboard" table appended to its description —
  one row per target branch with its backport PR (or `—`) and status
  (`✅ Merged` / `🔄 Open` / `✅ Already contained`).
- Each **backport PR** links back to the original master PR.
- `gh pr edit` currently fails on the xserver repo with a GraphQL *"Projects classic
  deprecation"* error, so edit PR bodies via the REST API. Use
  `scripts/pr-set-body <pr#> <body-file>` (wraps
  `gh api --method PATCH repos/X11Libre/xserver/pulls/<n> -F body=@<file>`) — write the new body
  to a file first, then apply it.

## PR repair workflow (fix an open master PR — e.g. failing CI)

Distinct from backporting: here you *amend an existing, unmerged* master PR (typically to fix a
broken build) rather than cherry-picking a merged one onto a release line. Same isolation rule —
work in a dedicated agent clone, never the user's hand-edited sources tree.

1. **Get the real failure first — don't reason blind.** Easiest: `scripts/pr-job-logs <pr#>`
   downloads every failing job's raw log and prints a failure summary in one shot (use
   `--job <id>` for a specific job, `--all` for every job). Under the hood: `gh pr checks <pr#>`
   shows which jobs failed, but `gh run view --log` / `--log-failed` frequently return **nothing**
   on this repo, so the log must come from the REST API
   (`gh api repos/X11Libre/xserver/actions/jobs/<job-id>/logs > log.txt`) — which is exactly what
   the script wraps. Then grep it. For a
   meson **configure** failure the real line is an interpreter error (e.g.
   `Xext/dpms/meson.build:6:3: ERROR: Unknown variable "build_dpms".`); for a build failure it's
   the first `FAILED:` / `error:` / `ninja: build stopped`. The per-check
   `gh api repos/<repo>/check-runs/<id>/annotations` only gives `Process completed with exit
   code 1` — not the cause.

   **A `xserver-build-*` job can fail in its *test* phase, not the build.** These jobs run
   `meson test` (the XTS suite: `xvfb / XTS`, `xephyr-glamor / XTS`) *after* a successful build,
   so there is **no** `FAILED:`/compile-`error:` line — grepping for those comes up empty. Instead
   the log *ends* with a meson test summary (`Ok: N` / `Fail: N`) and `Process completed with exit
   code 2`, and the failing XTS test prints `Caught signal 11 (Segmentation fault) … at address
   0x0` with an **address-only** backtrace (no symbols). So also grep the tail for
   `Summary of Failures`, `Fail:`, and `Caught signal` / `Segmentation fault` — a server crash
   during XTS is a real PR regression, not flakiness (this was the #1639 saveset NULL-deref).

   **The go-xts (go-x11proto) Xephyr test has its own failure modes** — a display-number race
   that hangs until timeout, and byte-order / `+byteswappedclients` requirements. See
   **`CI-GOXTS-XEPHYR.md`** before debugging a hung or LE-only `run-xts-go-xephyr.sh` (from the
   #3122 repair).

   **A flaky/red CI run can't always be re-run — refresh by rebasing.** `gh run rerun <id>
   [--failed]` fails with *"run … cannot be rerun; its workflow file may be broken"* when the run
   is **older than ~30 days** (GitHub's rerun window), regardless of the actual failure. Many
   long-open PRs fail CI only on **infrastructure flakes** — most commonly `FAILED: failed cloning
   https://github.com/X11Libre/mirror.fdo.libxcb-util` / `HTTP 502` from the source mirror, or a
   single XTS `Fail:` — not a code defect. When the run is too old to rerun, the way to get a fresh
   green run is to **rebase the PR branch onto current `origin/master` and `push --force-with-lease`**
   (a new head SHA re-triggers CI). For single-commit PRs only a few commits behind this is
   usually clean; build-verify (`ninja … hw/vfb/Xvfb hw/xnest/Xnest`) before pushing since the
   rebase may expose a new in-tree user of a symbol the PR unexports. A genuine content conflict
   means a manual rebase is needed instead. (Done in bulk June 2026 for the stale unexport/cleanup
   PRs #1051/#1388/#1450/#1467/#1469/#1481.)

   **Classify a red rollup by *conclusion*, not by count — `CANCELLED` ≠ `FAILURE`.** The CI matrix
   is **fail-fast**: one real `FAILURE` cancels all the still-running siblings, so
   `statusCheckRollup` can show e.g. "106 failing" that is really **2 `FAILURE` + 104 `CANCELLED`**.
   The `CANCELLED` jobs are collateral, not the cause — only the `FAILURE`/`TIMED_OUT` ones point at
   the real problem (filter on `.conclusion`). Don't read a big red number as a wide breakage.

   **BSD/Solaris CI jobs flake at the VM level, independent of the code.** The `vmactions`-based
   jobs (`xserver-build-{dragonflybsd,solaris,netbsd,openbsd,freebsd}`) routinely fail with the VM
   never booting — `boot failed, let's shutdown vm, and retry once more` ×3 — or other provisioning
   noise, with no build output. Heuristic: **the same platform job red across several *unrelated*
   PRs ⇒ it's the job, not the PR** (a trivial unexport/typing cleanup can't selectively break only
   Solaris while every Ubuntu/macOS/etc. job is green). These are fresh-run flakes, so a single
   `gh run rerun <run-id> --failed` usually clears them. Add to the known-flake set alongside the
   `libxcb-util`/HTTP-502 mirror clone.

   **Two more known flakes in the `xserver-build-*` *test* phase (both `Fail: 0`, so not real):**
   - **`xserver:xephyr-glamor / XTS  TIMEOUT 1200s … killed by signal 15`** — a loaded-runner
     timeout, *not* a code failure. Tell it apart from a real XTS failure by the summary showing
     `Timeout: 1` / `Fail: 0` (vs a genuine `Fail: N` / `Caught signal 11`). The *same* suite often
     passes in ~137s in a parallel run on the same head, which proves it's infra. Note GitHub
     sometimes schedules **two parallel "Build X servers" runs on one head**; one can flake (XTS
     timeout) while the other is fully green, and `statusCheckRollup` surfaces the failing one —
     check whether a sibling run of the same SHA already passed before assuming breakage.
   - **`go-xts` `panic: send on closed channel`** (e.g. `TestXSettingsWatch`) — a race in the
     **go-x11proto client** (`proto/core/conn.go`: `eventCh`/`errorCh` closed by `Close()` while
     `readLoop` was still sending). **Fixed in go-x11proto v0.0.4.** The xserver CI pins that
     dependency in **`.github/scripts/conf.sh`** (`PKG_GOXPROTO_REF`) and
     **`.github/workflows/build-xserver.yml`** (`GOXPROTO_REF`) — `install-prereq.sh` consumes the
     var, so bump only those two literals to raise it (PR #3156 bumped v0.0.3→v0.0.4).

   **Re-trigger trick when the run is too new/old to rerun *and* master hasn't moved.** Rebasing
   only re-triggers if it produces a new head SHA; when the PR is already on the current tip (or
   stacked and you must keep the base), force a fresh SHA with an empty
   `git commit --amend --no-edit --date=now` then `push --force-with-lease`. Same content, new SHA,
   CI re-runs. (Used to clear the XTS-timeout flake on #1455 and #696.)

   **Stacked PRs when one depends on an unmerged fix.** If PR-B is only correct once PR-A's fix
   lands (and a controlled run *proves* it — e.g. #1455 failed `xvinfo`/`XvBadPort` without #3154's
   one-liner, passed with it), base PR-B's branch on PR-A's branch (it then carries A's commit until
   A merges) and note the merge order in a comment. **After PR-A merges**, rebase PR-B onto
   `origin/master`: git drops the now-duplicate commit by patch-id (`Warnung: zuvor angewendeten
   Commit … übersprungen`), leaving PR-B's own commit alone. The two changes must touch **disjoint**
   regions for the textual rebase to stay clean either way.

2. **Check out the PR branch in an isolated clone:** `scripts/pr-checkout <pr#>` → makes/refreshes
   `_WORK_/xserver-master/agent/repair/xserver`, checks out the PR's head branch, prints the
   clone dir.

   **`pr-checkout` handles both same-repo and fork PRs.** A fork PR has its head branch on the
   contributor's repo, so `origin/<headRef>` doesn't exist. pr-checkout auto-detects this
   (`isCrossRepository`), wires a dedicated `fork` remote mirroring origin's transport
   (SSH → reuses the maintainer's key, no token), and checks out the branch tracking
   `fork/<headRef>`; `pr-amend-push` then pushes the amended commit back to that `fork` remote
   (it reads `branch.<head>.remote`, falling back to origin for same-repo PRs). Push-back needs the
   PR's *allow edits from maintainers* (`maintainerCanModify: true`) — pr-checkout warns if false.
   (This was originally a bug: pr-checkout did `fetch origin <headRef>` unconditionally and failed
   on forks, and pr-amend-push hard-coded a push to origin; both fixed while rebasing #625, head
   `patch-1` on fork `BrightCat14/xyzserver`.)

   **Rebasing a long-stale PR may reveal it's obsolete, not conflicting.** #625 (Aug 2025, an
   integer-overflow guard before `calloc(1, rep.length << 2)` in `doListFontsAndAliases`) hit a
   conflict on rebase because master had ~2295 commits since and had *removed the vulnerable
   `calloc` entirely*, replacing the hand-managed buffer with the growable `x_rpcbuf_t` API
   (`x_rpcbuf_write_CARD8s` + `rpcbuf.error` → `BadAlloc`). Resolving toward master left an empty
   change (only a now-unused `#include <limits.h>`). When a rebase would produce a no-op, **don't
   force-push a hollow commit** to the contributor's branch — confirm with the maintainer and close
   the PR with a bot-bannered comment explaining it's already addressed upstream (cite the function
   + the commit/mechanism that removed the old code).

   **Check supersession *before* rebasing with `git cherry`.** `git cherry -v origin/master <branch>`
   marks each of the branch's commits `-` (patch-id already on master → a rebase silently drops it)
   or `+` (genuinely new). All-`-` ⇒ the PR is fully merged/superseded — close it, don't rebase.
   The subtle case: a commit can be `+` yet still effectively obsolete — git only drops a commit as
   empty when its patch is *identical* to one on master; if master reached the same end state via
   *different* commits, the rebase **conflicts** instead, and a correct resolution collapses to a
   no-op (or worse, re-introduces a regression the master version already fixed). #1063 (`dix: use
   xorg_list saveSet list`, June 2026) was exactly this: `git cherry` said `+`, but master already
   had the conversion *plus* the `if (client)` NULL-guard the PR dropped — so the only non-cosmetic
   delta the PR carried was *removing* that guard. Closed as superseded. (Contrast the genuine
   cross-reorg/rebase case like wip/x86emu, where `git cherry` correctly `-`-dropped the 5 merged
   `[PR #…]` commits and cleanly replayed only the 2 still-open ones.)

3. **Fix it in that clone**, then **verify locally before pushing** — a meson-only change still
   warrants a real build. From a throwaway build dir: `meson setup <builddir> <clone>` (success =
   `build.ninja` generated → configure error gone), then link a server or two to catch
   compile/duplicate-symbol problems: `ninja -C <builddir> hw/vfb/Xvfb hw/xnest/Xnest` (those
   pull in the full `libxserver` link list). This caught both the configure error *and* a latent
   double-compile of `dpms.c` in the #3022 repair.

   **For a runtime crash (XTS segfault), reproduce it locally with a tiny client — the full XTS
   suite won't run locally** (it needs `XTEST_DIR` / piglit; `test/scripts/xvfb-piglit.sh` just
   exits 77 = skip). But a dix-level crash is usually drivable directly: build `hw/vfb/Xvfb`, start
   it on a spare display (`Xvfb :91 &`), and run a small `libX11` client that issues the offending
   request, then assert the server is still up (`kill -0 $xvfb_pid`). For #1639 a ~30-line client
   (client A creates a window, client B `XAddToSaveSet`s it, B disconnects → `HandleSaveSet` +
   `DeleteWindowFromAnySaveSet`) reproduced the exact `Segmentation fault at address 0x0` on the
   unfixed build and stayed alive on the fixed one. Toggling the one-line fix in/out (rebuild
   `Xvfb` each way) cleanly proves cause *and* sufficiency — far tighter than waiting on CI.

4. **Amend + push:** `scripts/pr-amend-push <clone-dir> [files...]` folds the edits into the PR's
   single commit (`--amend --no-edit`, preserving message + `Signed-off-by`) and
   `--force-with-lease` back to the branch. CI re-triggers automatically on the new head.

(If a separate fixup commit is preferable to amending, commit + push by hand from the clone.)

## Automated reviews

When an agent reviews a PR, **always post the review outcome as a comment on that PR to track the
result there** — including on the maintainer's **own** PRs (the bot banner makes the origin clear,
so self-authored PRs are reviewed and recorded the same way). The `gh` CLI is authenticated as
**@metux**, so every comment appears under the maintainer's name. Four rules apply.

> **A passing review never authorizes an auto-merge into a `release/*` branch.** Merges into
> release lines are manual-only (maintainer); see the box at the top of the Backport workflow.
> Reviewing/labeling a release PR is fine — merging it from an agent is not. Auto-merge is only
> ever acceptable on a `master` PR, and only when the user explicitly requests it.

**Route hardware-touching PRs to the HW domain experts before merge.** Changes to the
**modesetting** driver, **kdrive**, **xfbdev**, or the **xfree86 DDX bus/output/primary-device**
paths should get a human review from **@cepelinas9000** and **@stefan11111** — the two contributors
deepest into the HW side. **@stefan11111** is the **kdrive** expert and wrote **xfbdev**. For such a
PR, request both as reviewers (`scripts/pr-request-reviewers <pr#> cepelinas9000 stefan11111`)
and **do not auto-merge on a green
bot-review + CI alone** — wait for an `APPROVED` review from one of them. (Seen on #3181,
`xfree86: prefer boot_display over boot_vga`, a primary-device-selection behaviour change.)

**Re-reviewing a `bot-review-changes-requested` PR: independently verify the prior finding — it can
be wrong.** When re-visiting a PR that already carries a changes-requested label, don't trust the
earlier verdict; re-derive it from the *current* code. Two distinct outcomes both require flipping
to `bot-review-passed`: (a) the author pushed a fix (compare the prior finding against the current
head), or (b) **the prior finding was itself wrong** — a hallucinated/over-stated blocker. #3153
(`Fbdev arg parsing`, June 2026) was case (b): the prior review modelled the *old* CLI option
ordering and flagged a bug against semantics the patch *intentionally inverts*; the author's
"it's hallucinating" pushback was correct, confirmed by simulating the patched `ddxProcessArgument`
under the new ordering. When a finding hinges on a behavioral model, re-run that model against the
actual patched code before keeping the red label. (Also seen: #3027 over-framed an honest hardening
log line as a "CRITICAL vulnerability" — pass the code, recommend retitling.)

**1. Disclose that it's a bot.** Prepend this exact banner (then a blank line) to *every* comment
posted in the user's name — PR-level comments, review summaries, and inline review comments alike:

```markdown
> 🤖 **Automated review** — generated by Claude Code on behalf of @metux. Not a human review.

<comment body>
```

`scripts/pr-comment <pr#> <body-file> --bot-review` prepends this exact banner for you — prefer
it over hand-copying the banner text into every comment.

**2. Assess backport-worthiness.** As part of the review, decide whether the change is a
**security vulnerability** or **critical bugfix** that should reach the maintained release lines
(25.2 / 25.1 / 25.0). Backport-worthy: client-triggerable memory disclosure / OOB read-write /
NULL deref / use-after-free, auth or access-control bypass, crashes & DoS, data corruption, and
regressions from an earlier release. **Not** backport-worthy: refactors, cleanups, style, new
features, build-system churn (unless it breaks a release build).

If it is backport-worthy, **flag it in the review and name the likely target branches** — do
**not** open backport PRs automatically. Add a note like:

```markdown
**Backport candidate** (security / critical fix): likely applies to `release/25.2`,
`release/25.1`, `release/25.0`. Applicability must be confirmed per branch (code may differ,
already be fixed, or not be present) — see the Backport workflow section. Maintainer decides
whether to proceed.
```

Leave the decision to ramp the actual backports (via `mk-agent-clone` + `xx-make-pr.sh`) to the
maintainer.

**3. Check for driver-ABI breakage.** The **proprietary nvidia driver is a binary blob that
cannot be recompiled** — and *even old nvidia versions must keep working*. So the goal is to
**preserve** the binary ABI, not to version a break: we cannot just bump a number and expect
users to get a new blob. Treat anything that could change the binary ABI with great caution.

**Scope — whose drivers actually constrain us.** Only two consumer sets matter for an ABI/API
change: (1) the **current driver releases the xlibre project itself ships/builds** (the ~53
in-tree-built `xf86-*` drivers — what CI's `drivers-build-ubuntu` matrix covers), which must keep
building/working; and (2) the **proprietary nvidia blob**, which must keep loading (see this
section). Arbitrary *completely external* drivers — out-of-tree, third-party, niche/BSD, anything
outside the xlibre project and not nvidia — **do not constrain us** and are not a reason to hold
back a change. Consequence for **macros/`#define`s** specifically: since nvidia is a binary blob
(macros are compile-time, invisible to it) and the only source consumers we care about are those
~53 driver releases, a header macro that none of them reference *by name* (grep the driver trees —
see the servermd.h analysis) can be renamed/namespaced/removed **freely**, with no deprecation
alias needed for hypothetical external users. (This does **not** relax the rules below for
`_X_EXPORT`'ed symbols and public struct layout — those still bind because of nvidia.)

What actually matters (ignore the rest):

- **Public data structure layout.** Any change to a struct a driver can see — `ScrnInfoRec`,
  `ScreenRec`, `DeviceIntRec`, `InputInfoRec`, pixmap/GC/window/privates structs, etc. — that
  adds, removes, reorders, or retypes a field, or changes its size/alignment/offsets. The blob
  was compiled against the old layout and reads fields at fixed offsets; any shift corrupts it.
- **`_X_EXPORT`'ed entry points.** Removing, renaming, or changing the signature/calling
  convention/semantics of any symbol marked `_X_EXPORT` (the visibility macro for symbols
  exported to drivers/modules). The blob resolves these at load and calls them with the old
  contract.

What is **NOT** the thing to check: the `ABI_*_VERSION` macros in `include/xf86Module.h`
(`ABI_VIDEODRV_VERSION` etc.). Those are an old XFree86 relic and are not practically relied upon
here — do not treat a missing/changed version bump as the signal, and do not suggest bumping one
as a "fix." The real signal is a diff to a public struct or an `_X_EXPORT`'ed declaration.

In the review, call out the specific struct or exported entry point touched and the **explicit
nvidia impact** (e.g. "adds a field in the middle of `ScrnInfoRec` → shifts all following offsets
→ installed nvidia blob reads garbage / crashes"). Advisory — the maintainer decides — but any
change to this surface must be surfaced prominently, since the constraint is to keep even old
blobs loading.

**Verify export-removal against real blobs.** Reasoning about "would nvidia call this?" is
error-prone — confirm against actual installed drivers. Fetch them with
`scripts/fetch-nvidia-drivers` (extracts `nvidia_drv.so` / `libglxserver_nvidia.so` / `libglx.so`,
no install), then check candidate symbols with **`scripts/nvidia-abi-check`**:

```sh
scripts/fetch-nvidia-drivers                         # legacy 390/470 + recent 550/570
scripts/nvidia-abi-check UnexportedSym1 UnexportedSym2 ...   # or pipe names on stdin
```

**Check both reference paths — this is the key subtlety.** A driver reaches a server symbol either
by (1) **link-time import** (undefined dynamic symbol, seen by `nm -D`) OR (2) **runtime lookup by
name** via `dlsym()` / the X server's `LoaderSymbol()`, where the name is only a *string literal*
in the blob and is invisible to `nm`. `nvidia-abi-check` scans **both** (imports ∪ string
literals); a plain `nm -D` / `scripts/nvidia-undefined-symbols` dump misses the runtime-lookup
half. The nvidia blob really does both — `nvidia_drv.so` imports `LoaderSymbol`, and e.g. the 390
driver resolves ~15 `xf86*` symbols by string only. (Residual blind spot: a name built by string
concatenation at runtime won't appear as a literal.)

Default version set spans legacy→current precisely because *old* blobs must keep loading. This
check already corrected three static verdicts: **#1786** (deletes 6 `miOverlay*` symbols imported
by *all* tested blobs — breaks them), **#2070** (unexports `xf86CursorScreenKeyRec`, resolved by
*runtime lookup* in all — missed by `nm` alone), and **#808** (tempered: no tested blob references
XvMC — safe).

**`NVIDIA-ABI.md`** is the living record of what nvidia actually consumes — the runtime-lookup-only
symbols (the easy-to-miss ones), confirmed do-not-break rules, and what's confirmed unused. Consult
it before judging an ABI change, and append new findings there (humans and agents both maintain it).

**Related NVIDIA docs/tooling (open-driver effort):** **`NVIDIA-OPEN-DDX.md`** — plan to replace the
closed X-side driver with an open one on NVIDIA's userspace EGL (GBM/EGLStream), keeping the
unmodified proprietary client `libGL` (see its "Current status" for where the project stands).
**`nvglx-re/`** — tooling to reverse-engineer the private NV-GLX wire protocol the open driver must
reimplement. NVIDIA driver-inspection scripts: `scripts/nvidia-*` (see the Key commands table).

**4. Label the PR with the review verdict.** After posting the review comment, tag the PR with
exactly one outcome label so results are filterable on GitHub:

- **`bot-review-passed`** (green) — no blocking findings (clean, or only minor/advisory notes).
- **`bot-review-changes-requested`** (red) — at least one blocking finding (a real bug, a
  regression, a security/ABI break the maintainer should act on before merge).

If a later revision fixes the blocking finding (e.g. an amend + force-push), swap the label to
`bot-review-passed` and update the review comment to match. Apply labels via
`scripts/pr-label <pr#> set-review passed|changes-requested`, **not** `gh pr edit` — the latter
currently fails on this repo with the *"Projects classic deprecation"* GraphQL error (same
breakage as `pr-set-body` works around).

## Concurrency / isolation (multiple sessions + manual work)

**The unit of isolation is the clone (working tree + index), not the repo.** All safety rules
follow from that.

- **Safe by construction:** different release clones (`_WORK_/xserver-<rel>/…`) are separate
  working trees, so a session in one release and work in another cannot clobber each other's
  files/index/HEAD. They share only the GitHub remote, and pushes go to distinct
  `rfc/backport-<rel>` branches. **Parallelize across releases freely.**
- **The hazard:** two actors (two sessions, or a session + manual edits) mutating the **same**
  clone at once. Git has no native working-tree lock — concurrent `checkout` / `add` / `commit`
  / `rebase` will silently corrupt each other's state.
- **`scripts/xx-make-pr.sh` needs exclusive access to its clone for its whole runtime.** It
  fetches, creates/renames/deletes branches, switches branches, and **rewrites the incubator
  branch history**. Never run anything else in that clone while it runs.

### Two agents on the same PR — claim it first (`scripts/pr-claim`)

Separate clones isolate *files*, but every clone pushes to the **same GitHub PR branch**. So two
agents repairing the **same PR** in two clones is still a conflict: their `pr-amend-push`
force-pushes clobber each other (last writer wins, the other's fix is silently lost) and they post
duplicate review comments. Clone isolation does **not** cover this; PR-branch ownership does.

**Protocol — before you start mutating a PR (repair, amend, backport-to-a-PR):**

```bash
export AGENT_ID=<short-unique-name>      # e.g. repair-3132 — distinguishes concurrent agents
scripts/pr-claim <pr#> "what you're doing"   # exit 3 => another agent holds it: pick another / coordinate
# ... pr-checkout / edit / pr-amend-push ...
scripts/pr-claim --release <pr#>         # when done (or --release-all at session end)
```

- `scripts/pr-claim --list` is the **shared work log** — "which agent is on which PR right now."
- Advisory, like `with-clone-lock`: it only guards actors that also call it. `pr-checkout` does a
  soft `--who` check and **warns** (doesn't block) if the PR is already claimed.
- Claims are keyed by PR#, `flock`-serialized, stored gitignored under `_WORK_/agent-claims/`
  (with an `events.log` audit trail), and go **stale after `$CLAIM_TTL`** (default 1h) so an agent
  that exited without releasing doesn't wedge the PR — a stale claim is auto-reclaimed (logged);
  use `--steal <pr#>` to take over a still-fresh claim from an agent you know is gone.
- **Read-only review needs no claim** — only mutation (pushing to the branch) does.
- Pushing to **distinct** branches never conflicts, so across *different* PRs / release lines you
  still parallelize freely; the claim is only about the shared branch of one PR.

### Central control plane — one agent monitors/steers the others (`scripts/agent-bus`)

`pr-claim` coordinates *ownership of one PR branch*; `agent-bus` is the broader **control
plane** so a single control agent (a "1st officer") — or a future dashboard / voice UI / MCP bus —
can see what every independent session is doing and steer it, instead of switching between many
terminals. Same model as everything else here: no process talks to another directly; all parties
read/write the same gitignored files (`_WORK_/agent-bus/`, `flock`-serialized), so it works across
**totally independent** `claude` (or human) sessions, not just spawned subagents. Pull-based and
advisory — workers must poll their `inbox`; nothing forces a session to act.

- **Worker session** (one per release line / task): set a unique `$AGENT_ID`, then
  `agent-bus status <state> ["note"]` to report/refresh a heartbeat (states are free text:
  `working|building|reviewing|blocked|idle|done`); `$XLIBRE_RELEASE` auto-fills the project column.
  Check `agent-bus inbox` for directives addressed to you or to all, and `agent-bus ack <id>` when
  handled. `agent-bus clear` on exit.
- **Control agent** (`AGENT_ID=Enterprise` — the flagship): `agent-bus board` (the default no-arg
  command) is the whole-fleet view — every agent, project, state, heartbeat age, unacked-inbox
  count, note, `[STALE]` past `$BUS_TTL` (15m). Steer with `agent-bus tell <agent> <text…>` (one
  agent) or `agent-bus broadcast <text…>` (all); `agent-bus msgs` shows directives + ack counts,
  `agent-bus events` the audit trail, `agent-bus prune` reaps stale heartbeats + fully-acked old
  directives.

**Heartbeats are auto-reported — both session types register on the `board` without a manual call:**
- **Claude Code** via checked-in `.claude/settings.json` hooks: `SessionStart`
  (`agent-bus status idle "session started"`) and `SessionEnd` (`agent-bus clear`), invoked as
  `"$CLAUDE_PROJECT_DIR"/scripts/agent-bus …` (cwd-independent, `… || true` so they never block a
  session). `SessionStart` also launches **`scripts/agent-bus-watch`** (detached) and `SessionEnd`
  stops it (`--stop`): a local, LLM-free poller that **notifies** (append to
  `_WORK_/agent-bus/notify/<agent>.log` + best-effort `notify-send`) when a new directive for this
  agent (or `all`) arrives. Notify-only for now — it does not act on/ack directives; it runs only
  while a client session is open, so it costs nothing (no API) until mail actually lands.
- **opencode** via the `run-opencode.xserver-*` wrappers: each exports a per-session
  `AGENT_ID=${XLIBRE_RELEASE#xserver-}-$$` (release + PID, unless already set) and runs
  `agent-bus status idle "opencode session"` just before `exec opencode`. opencode does **not** fire
  Claude Code's hooks, so there's no auto-`clear` on exit (`exec` also rules out a cleanup `trap`) —
  the heartbeat is reaped by the `$BUS_TTL` staleness (15m) / `agent-bus prune`.

Agents still call `agent-bus status <state>` to report *what* they're doing as it changes; the
auto-heartbeat only registers presence. **Caveat:** the Claude Code hook inherits the session's env
and identity falls back to `user@host` when `$AGENT_ID` is unset — so for a plain `claude` session
(not launched via a wrapper) **export a unique `$AGENT_ID`** (and `$XLIBRE_RELEASE` for the project
column) first, or all same-host sessions collapse to one board row and a `SessionEnd` in any one
clears it for all. (The `run-opencode.*` wrappers already set both.)

**Don't prefix `export AGENT_ID=... &&` in front of `scripts/agent-bus`/`scripts/pr-claim` calls
when `$AGENT_ID` is already in the session's environment** (true for every launcher/hook-started
session in this workspace — the whole point of the ship-name/auto-id machinery above). Doing it
anyway is harmless functionally but breaks the `Bash(scripts/agent-bus *)`/`Bash(scripts/pr-claim
*)` allowlist entries, which match on the command line's literal *prefix*: `export AGENT_ID=Foo &&
scripts/agent-bus board` does not start with `scripts/agent-bus`, so it prompts for confirmation
even though a bare `scripts/agent-bus board` would not have. Only export/override `$AGENT_ID`
inline when you deliberately need a *different* identity than the session's own for one call.

**The same prefix-matching gotcha bites *any* chained command, not just `export AGENT_ID=...
&&`.** Allowlist entries like `Bash(gh)`/`Bash(gh *)` only match when the command line *itself*
starts with `gh` — `echo "AGENT_ID=$AGENT_ID"; gh pr view <n> --json ... -q '{...}'` starts with
`echo`, so it prompts for confirmation even though `gh` alone is allowlisted (hit on Pegasus,
2026-07-03, checking identity + PR #3226 status in one shot). Split unrelated diagnostics
(`echo`/`export`/a status print) and the allowlisted command into **separate Bash tool calls**
instead of chaining with `;`/`&&`/`|`. For the specific "print PR metadata" case, use
`scripts/pr-view <pr#> [fields]` (one canonical allowlisted command) rather than hand-rolling
`gh pr view --json ...`.

**Ship names for fleet identity (2026-07-03).** Every agent instance — whether a plain `claude`
session, an `agent-run`-launched tmux session, or the flagship `run-flagship` — gets a unique **Star
Trek ship name** as its `AGENT_ID`. `Enterprise` is reserved for the flagship/control session; worker
sessions are assigned the next free name from `scripts/ship-names.txt` (50 ships, Federation /
Klingon / Romulan / Cardassian / Bajoran) via `scripts/ship-names assign`. Names are visible:
- **Shell prompt:** `agent-bus-auto-id.sh` prefixes `(Defiant) ` to `$PS1` on first entry.
- **Claude Code status line:** `⚓ Defiant` rendered by the `statusLine` hook in `.claude/settings.json`.
- **tmux:** session is named `mpbt-Defiant`, visible in `tmux ls` and on the `agent-bus board`.
- **Agent bus board:** ship name IS the `AGENT_ID` column — reads like a fleet roster.
Names are released automatically: by `EXIT` trap / zsh `zshexit` in `agent-bus-auto-id.sh`, by
`agent-run --stop`, and by the Claude Code `SessionEnd` hook. Stale reservations can be cleared
with `scripts/ship-names gc`.

**Fixed for plain `claude` sessions via a dotfile-sourced auto-ID script (2026-07-02, updated 2026-07-03):**
`scripts/agent-bus-auto-id.sh` auto-assigns a ship name as `AGENT_ID` whenever an
interactive shell's `$PWD` is inside this workspace tree and `$AGENT_ID` isn't already set (so it
composes with the `run-opencode.*` wrappers and `run-flagship` rather than overriding them). It must be **sourced from
the user's `~/.bashrc`/`~/.zshrc`** (one line: `[ -f
/home/nekrad/src/xorg/mpbt-workspace/scripts/agent-bus-auto-id.sh ] && . <that path>`), *not* wired
as a Claude Code hook — checked against the hooks JSON schema: `SessionStart`/`SessionEnd` hooks run
as one-shot child processes and have no output field that injects env vars back into the
interactive session's shell (only `systemMessage`/`decision`/`hookSpecificOutput.additionalContext`
etc). `$AGENT_ID` must already be in the environment *before* `claude` starts so it propagates via
ordinary process-env inheritance into both the existing `SessionStart`/`SessionEnd` hook commands
and every Bash-tool-backed shell of that session — no `settings.json` change was needed once the
env var is populated upstream of the client process.

**Cross-repo agents can join this board too, by the maintainer's direction.** `agent-bus`/
`DASHBOARD.md` aren't limited to sessions rooted in this checkout — an agent working in a
*sibling* repo the maintainer also maintains (e.g. **`go-x11proto`** — the Go X11-protocol client
library the `go-xts` CI suite is built on, see "go-x11proto pin sites" above) can register on this
same board when told to, with its `$XLIBRE_RELEASE`/project column simply naming that other repo.
(As of 2026-07-02 go-x11proto is itself an mpbt solution — see "go-x11proto is its own mpbt
solution" below — so its clone now lives *inside* `_WORK_/go-x11proto/sources/xlibre/go-x11proto`,
not at the old external `/home/nekrad/src/xorg/go-x11` path.) Treat such an
entry as legitimate coordination, not stray noise — the maintainer explicitly wires up
cross-project agents this way when their work affects xserver CI (e.g. a go-x11proto version bump
needed here). Same rule applies to `DASHBOARD.md`: a cross-repo theme is fine there if it has a
concrete effect on this workspace's build/CI/tests.

**Auto-surfacing directives via `Monitor` (Claude Code only, 2026-07-03).** `agent-bus-watch` is
notify-only — it tells a human via desktop popup, but a live session doesn't see the directive
unless it happens to run `agent-bus inbox` itself. Claude Code's **`Monitor` tool** closes that gap
*without* crossing into unsupervised auto-execution: it's a background poll loop whose stdout lines
land as real events *inside* the session's own conversation (the same mechanism used to watch a
background build or a CI run), so a new `tell`/`broadcast` appears to the assistant like any other
observed event — the assistant still reasons about it and goes through the normal tool-permission
flow for whatever it decides to do. That's a meaningfully smaller blast radius than the alternative
that was considered and rejected (`tmux send-keys` injection into an `agent-run` pane) — no raw
keystroke injection bypassing confirmations, and it works uniformly for both foreground and
`agent-run`/tmux-launched sessions since it's a session-level tool, not tied to the tmux backend.

**Command: `scripts/agent-bus-monitor-loop`** (2026-07-03, replacing an earlier inline heredoc —
see below for why). Call `Monitor` with `command: "scripts/agent-bus-monitor-loop"`,
`persistent: true`. The script reads `$AGENT_ID` from the environment (already exported by every
launcher/hook in this workspace) and keeps its dedup state under
`_WORK_/agent-bus/monitor-seen/<AGENT_ID>` — so, unlike the old approach, **the invocation is the
exact same string for every session**. That matters for permissions: `.claude/settings.json` now
carries a bare `"Monitor"` allow entry, so this call needs **no confirmation prompt** at all,
in any session. (The bare-tool-name form — no `(...)` — allows every invocation of that tool
regardless of arguments, same as a bare `"Read"` entry; be aware this is a blanket grant, not
scoped to this one script, consistent with the other standing `scripts/*` grants already in this
file for this same trust boundary.) The script's first loop pass already scans all existing
messages, so arming it also serves as the one-time backlog check — no separate `agent-bus inbox`
call needed.

**Unconditional as of 2026-07-03** (was initially a discretionary nudge — changed after observing
several fleet sessions sitting idle with an unarmed inbox and unacked directives):
`scripts/agent-bus-monitor-hint` runs as a third `SessionStart` hook command and emits a
`hookSpecificOutput.additionalContext` instructing the assistant to arm this **as its very first
action, every session, no judgment call** — not "if it'll stick around." First real-world
validation (2026-07-03, the `Enterprise`/control session): arming the Monitor immediately surfaced
a 3-message backlog including an "ASAP" backport request (`m0011`) that had been sitting unclaimed
with no live session polling for it — concretely proving the gap this closes. Turned out already
superseded (PR #3226's backports were already open before the directive was even read) — a
reminder that `agent-bus` mail can go stale exactly like the board itself; ack with an explanation
instead of blindly acting when that happens.

**Why the command moved out of an inline heredoc into `scripts/agent-bus-monitor-loop`.** The
original approach had the hint dictate a self-contained bash snippet embedding `$AGENT_ID` and a
session-scratchpad path directly in the `Monitor` call's `command` argument. That worked, but every
session produced a *different* command string (different agent, different scratchpad path), so it
could never be permission-allowlisted — every arming, plus the `agent-bus inbox`/`agent-bus status
idle` calls the old hint also asked for, prompted for confirmation individually (reported
2026-07-03: "funktioniert schonmal - emittiert allerdings noch eine menge kommandos, die extra
bestätigt werden müssen"). Moving the loop into a script with no session-specific parameters (env
var instead of an interpolated literal, a fixed workspace-relative seen-dir instead of the
scratchpad) turned it into one static, allowlistable invocation — and made the explicit inbox-check
step redundant, since the script's own first pass covers it.

**Hard limit: a hook can't invoke a tool — this only fires on the session's first turn.** A `claude`
process that has been launched (heartbeat posted, shows up on `agent-bus board` as `idle`/"session
started") but has not yet received any input has had **no turn** yet, and `Monitor` can only be
called by the assistant during a turn — so its inbox stays genuinely unwatched until the first
message arrives. This is why a broadcast could sit un-acked at freshly-started ships
(`Discovery`/`Excelsior`/`Voyager`, seen 2026-07-03) even with the hint wired up: they simply hadn't
taken a turn yet, not that the hint failed.

**Closed the remaining gap by having the launcher supply that first message itself
(`scripts/agent-bus-boot-prompt`, 2026-07-03).** A session still can't self-trigger a tool call with
zero interaction — but the *launcher* isn't a session, it's a plain shell script that controls what
gets fed to `claude` as its initial argument, and `claude [prompt]` (no `-p`) starts interactively
with that prompt already submitted as the first turn. So `run-ship`, `run-flagship`, and
`agent-run --client claude` now each check: if the caller gave no explicit initial prompt/args, feed
`scripts/agent-bus-boot-prompt`'s text (arm the Monitor via `scripts/agent-bus-monitor-loop`, then
wait) as the initial `claude` argument instead of leaving it empty. This forces the first turn —
and with it the Monitor-arming — at launch time, with nobody needing to type anything.
Skipped whenever the caller *does* pass their own initial args/prompt (respects explicit intent,
never overrides it). `run-flagship --detach` composes cleanly: it fills `EXTRA` with the boot prompt
itself before delegating to `agent-run`, so `agent-run`'s own empty-check no-ops instead of
double-injecting. The prompt text itself shrank once the Monitor call became the *only* required
first action (see above) — arming `scripts/agent-bus-monitor-loop` and then waiting, no more
separate inbox-check/status-report steps spelled out (status is already handled by the existing
`SessionStart` heartbeat hook, which runs outside the permission system entirely since it's not a
model-invoked tool call).

**Flagship also needs the fleet-membership watch, not just its own inbox (2026-07-03).** The
`agent-bus-fleet-watch` script (see Key commands) existed but wasn't wired into the auto-arm path
above — a freshly (re)launched `Enterprise` session only armed `agent-bus-monitor-loop`, so a ship
restarting (e.g. Potemkin) produced no in-context notification even though the control session was
supposed to be watching the whole board. Fixed by making `agent-bus-boot-prompt` and
`agent-bus-monitor-hint` both branch on `$AGENT_ID`: for `Enterprise` they now instruct arming
**both** Monitors (`agent-bus-monitor-loop` + `agent-bus-fleet-watch`); every other identity still
gets just the inbox watch, since fleet membership is only the flagship's concern. One wrinkle in
`agent-run`: at the point it calls `agent-bus-boot-prompt` internally (for a bare `agent-run
<release> --client claude --name Enterprise`, i.e. not via `run-flagship`), `AGENT_ID` is still only
a local shell variable, not yet exported into the environment (that happens later, in the string
built for the inner tmux command) — so the branch would silently miss it. Fixed by passing it
explicitly: `AGENT_ID="$AGENT_ID" "$ROOT/scripts/agent-bus-boot-prompt"`, mirroring the same
inline-env-var pattern the script already uses for the actual `exec` line.

**Gap: opencode has no equivalent.** `Monitor` is a Claude Code harness tool; opencode sessions have
no comparable in-context event mechanism, so they're stuck on notify-only (desktop popup) for now.
Parked in `DASHBOARD.md` as a follow-up (give opencode *some* notify capability, even if not full
in-context surfacing).

**Roadmap:** the file layout is deliberately the data layer a richer controller can sit on
unchanged. Two steps exist now — `scripts/agent-bus-watch` (desktop notify, per-session via the
hooks above) and the `Monitor`-based in-context surfacing above. Still open: a TUI dashboard tailing
`status/` + `msgs/`, true auto-*execution* of directives (something other than the assistant's own
judgment triggers the action — not attempted; the `Monitor` approach deliberately keeps a human-grade
reasoning step in between), an opencode-side notify story, and an **MCP server in HTTP/SSE mode**
(runs as a daemon, serves many independent sessions at once, needs no Claude key, carries its own
creds for any external access) acting as a push message-bus instead of file polling. Start with the
files; promote to MCP when polling latency or multi-host reach demands it.

### Detaching sessions + multi-controller access (`agent-run` / `agent-attach`, tmux)

Goal: run agents detached from any terminal, and let an **arbitrary number of controller clients each
reach every running agent** — fully self-hosted, no cloud, any CLI. The backend is **tmux**: the
tmux server is a daemon, so a session survives terminal close / SSH disconnect, and multiple
`tmux attach` to one session = multiple controllers driving the *same* live agent.

- **Launch detached:** `scripts/agent-run <release> [--client claude|opencode|shell] [--name <id>] [-- <args>]`.
  Starts the client in a `tmux` session named `mpbt-<AGENT_ID>`, exports `AGENT_ID` + `XLIBRE_RELEASE`
  + `AGENT_HANDLE` (= the tmux session) into it, and writes an initial heartbeat — so it appears on
  `agent-bus board` with its ATTACH handle immediately. `--list` shows running sessions + board;
  `--stop <id>` kills one.
- **Attach a controller:** `scripts/agent-attach <id>` (resolves `<id>` via the board / tmux names).
  Run it from any terminal on the host (or over SSH) — as many as you like, concurrently.
  `--read-only` watches without typing; `--independent` gives that controller its own window size
  (a grouped session) instead of the shared-size default. `Ctrl-b d` detaches; the agent keeps running.
- **Reach from another machine:** SSH into the host and run `agent-attach` there — tmux needs no
  network service of its own. (For N remote controllers that's N SSH logins to the one host where
  the agents run.)

**Prereqs / caveats:**
- **`tmux` must be installed** (`sudo apt install tmux`) — `agent-run`/`agent-attach` refuse with a
  hint otherwise. It is the only added dependency.
- Survives terminal close + SSH disconnect out of the box. To also survive a full **logout**
  reliably, enable lingering once: `loginctl enable-linger "$USER"`. It does **not** survive reboot
  (agents are in-flight conversations — just relaunch).
- `agent-attach` execs `tmux attach`, which needs a real TTY — it's a human/controller command, not
  something the agent tool itself runs (it errors when stdout isn't a terminal).
- **Why not Claude Code's native Remote Control / agent-view?** Remote Control routes through
  Anthropic's cloud (no self-hosted bridge) and only covers Claude Code sessions, not opencode — so
  it fails the "self-hosted + every client" requirement. The background agent-view supervisor is
  also Claude-only and same-host. tmux is the CLI-agnostic, self-hostable, multi-attach equivalent.

**Preferred: agents work in their own dedicated clones.** Agents/automation must NOT do backport
work in the user's hand-edited `sources/xlibre/xserver` clone. Instead create an agent-owned clone:

```bash
scripts/mk-agent-clone <release> [name]   # e.g. scripts/mk-agent-clone 25.2
# -> _WORK_/xserver-<rel>/agent/<name>/xserver   (gitignored)
```

- **Full isolation, cheap.** origin = GitHub, but the object store is borrowed from the user's
  clone via git **alternates** (`--reference`), so the new `.git` is a few hundred KB, not a full
  copy. Refs, index, HEAD and config are independent.
- **Reproduces the mpbt repo config.** mpbt configures the source clones with settings
  `xx-make-pr.sh` and the remotes depend on (the `make-pr.*` keys, plus `remote.origin` tagopt /
  namespaced tag refspec and the `xorg` upstream remote). `mk-agent-clone` copies the entire
  `make-pr.*` and `remote.*` config sections verbatim from the reference clone — so it tracks any
  future keys automatically rather than hard-coding a subset. Re-running it is idempotent and
  repairs config drift.
- **This is why a clone, not a worktree:** `xx-make-pr.sh` *rewrites* the `rfc/backport-<rel>`
  branch history. A worktree shares the ref store, so that rewrite would mutate the user's branch.
  A separate clone shares only objects, so it can't. The agent clone tracks
  `origin/rfc/backport-<rel>` (the shared incubator) and pushes PRs to the real GitHub remote.
- **Multiple parallel agents:** give each its own `name` (`mk-agent-clone 25.2 alice`).
- **Object-sharing caveat:** the agent clone borrows objects from the user's clone, so do **not**
  run `git gc --prune` / aggressive `git repack` in the user's `sources/…` clone while agent
  clones reference it — that can prune objects the agent clone needs. To detach a clone from the
  shared store, run `git repack -a -d && rm .git/objects/info/alternates` (or clone with
  `--dissociate`) — costs disk but removes the coupling.

**Fallbacks when not using a dedicated clone:**

- **Per-task git worktrees** — own working dir + index + HEAD, shares the object store. Git
  refuses to check out the same branch in two worktrees (a useful guard). But note the ref-store
  caveat above: don't run history-rewriting tools like `xx-make-pr.sh` from a worktree of a clone
  someone else uses. (Claude Code can spawn agents with `isolation: "worktree"`.) **`scripts/worktree
  add <repo> [name]`** wraps the create/list/remove/prune lifecycle for exactly this case, for
  any repo — see the Key commands table — and is pre-authorized so it needs no confirmation.
- **`scripts/with-clone-lock`** — advisory per-working-tree `flock`; wrap mutating commands so
  cooperating actors serialize instead of colliding:
  ```bash
  scripts/with-clone-lock scripts/xx-make-pr.sh <commit-sha>
  scripts/with-clone-lock                       # subshell; lock held until exit
  ```
  Keyed to the per-worktree git dir (separate worktrees/clones run in parallel; same tree
  serializes). Auto-releases on process exit. **Advisory only** — guards against actors that also
  use the wrapper, not raw edits. Records holder in `<gitdir>/mpbt-clone.lock`; `LOCK_WAIT`
  (seconds, default 600) sets the timeout.

**Rule of thumb:** agents → own clone via `mk-agent-clone`; parallelize freely *across* releases;
*within* a release use a per-agent clone name (or worktree / `with-clone-lock`). Always run
`xx-make-pr.sh` from an isolated tree.

## submit/* branch hygiene — is a branch already in master?

The `submit/*` branches are old staging branches that diverge from current `master` by
**thousands of commits** (one checked had a merge-base ~5000 commits back) **and** straddle the
`Xext/<ext>/` directory reorg. That breaks every single-method "is it merged?" test — each has a
blind spot:

- **`git cherry` / patch-id** ("forward patch present in master history"): blind to **reverts** —
  a later `Revert "…"` in master leaves the forward patch in history, so a reverted-and-thus-*absent*
  change still reads as "contained" (seen on `glamor-unexport`).
- **`git merge-tree --write-tree` vs master tree**: a clean `CONTAINED` (merged tree == master tree)
  or `DIFFERS` (clean merge, tree changes ⇒ genuinely **not** contained, e.g. a revert) is reliable,
  but on these stale branches the 3-way merge **CONFLICTs** purely from the file-move reorg — a
  false negative for branches that *are* fully merged (e.g. `dix-cleanup`, 55 commits all in master).
- **Test-rebase onto master** (`git rebase --empty=drop`): inherits the patch-id revert blind spot
  (drops the commit as "already applied"); `--reapply-cherry-picks` over-corrects and CONFLICTs on
  staleness. `git apply -R` of the cumulative diff is too strict (surrounding-context drift).

**Working recipe** (used June 2026 to clear 79 of ~150 submit branches):
1. **Reliable-positive delete set** = `merge-tree` CONTAINED (bulletproof), *plus* patch-id-clean
   branches (`git cherry` 0 `+` lines) **minus** anything flagged by either (a) `merge-tree`
   `DIFFERS` or (b) a **fuzzy** revert-message scan (master's revert subject often carries a
   `(!NNNN)` prefix, so match the branch's commit subject as a *substring* of `Revert "…"`
   subjects — exact match misses them). Always `gh pr list` first; deleting a branch with an open
   PR closes it.
2. **"Hochziehen" (pull pending branches up onto master):** a full rebase replays the
   already-merged commits too, which is what mostly conflicts — instead cherry-pick **only the
   genuinely-missing commits** (forward patch-id not in master) onto `origin/master`. Even so,
   expect most to still **conflict on real content** (the new commits touch heavily-reorged
   subsystems) — those need manual, build-verified rebasing and must **not** be auto-pushed.
   Only force-push the ones that rebase/cherry-pick **cleanly**.

Do all of this in a **separate detached worktree** (`git worktree add --detach … origin/master`),
never the user's checkout — and note the user may be switching branches / rebasing in the same
clone concurrently (their reflog churn is theirs, not yours). The throwaway analysis scripts live
in the session scratchpad (`classify.sh`, `cherrypick-missing.sh`); promote to `scripts/` only if
this becomes recurring.

**Incremental "zipper" rebase for deeply-stale branches.** `~/.bin/git-zipper-rebase.sh`
(`git zipper-rebase <target>`) rebases a branch onto `<target>` **one upstream commit at a time**
(`git rebase --onto TARGET~N …` for N=X-1…0), so conflicts come in small per-commit bites instead of
one giant merge — useful for the `submit/*` branches whose merge-base is thousands of commits back.
Caveat: for a branch ~4000 commits behind master that's ~4000 sequential `git rebase` invocations
(measured ~2.4/s → tens of minutes per branch), and each conflict stops the run (resolve →
`git zipper-rebase --continue`). Its default target is `origin/main`; pass `origin/master`
explicitly. The harness's 120s foreground Bash timeout can interrupt a long run mid-step and leave a
stale `$GIT_DIR/rebase-zipper.lock` + one-step-behind state file — reconcile the state to HEAD and
resume. Many "stale but contained" branches simply empty out (every commit becomes redundant); a few
reveal a genuinely-new commit hiding under merged ones (this is how `bugfix-xnest-colordepth` and
`recv-fds` were recovered from the "abandon" pile).

## X-server reply wire format — rpcbuf padding is done by the OS layer, not the handler

A recurring false-alarm trap when auditing reply handlers that build their payload with the
`x_rpcbuf_t` API (the post-migration style: `X_SEND_REPLY_WITH_RPCBUF` / `__write_reply_hdr_and_rpcbuf`
in `dix/request_priv.h`):

- The reply length is set to `header_units + x_rpcbuf_wsize_units(rpcbuf)`, where `wsize_units =
  (wpos+3)/4` **rounds up**. `WriteRpcbufToClient` then calls `dixWriteToClient(client, wpos, …)`.
- **`dixWriteToClient` (os/io.c) zero-pads *every* write up to a 4-byte unit** (`padBytes =
  padding_for_int32(count)` + `memset`; both the small-write/`FlushClient` path and the large
  `memcpy_and_flush` path). This is the classic "WriteToClient long-word-aligns things" behavior.
- **Therefore writing variable-length trailing data with the non-padding writers
  (`x_rpcbuf_write_CARD8s`, `x_rpcbuf_write_CARD16s`) is NOT a short-reply bug** — the bytes-on-wire
  always equal the declared `reply->length`. Do **not** report "final wpos isn't a multiple of 4" as
  a defect; it's padded by the OS output layer. (A June 2026 audit of ~45 such call-sites across 7
  extensions produced ~13 "bugs" that were all this false positive — the agents hadn't traced into
  `dixWriteToClient`.)

**The only real reply-corruption class here is *inter-element* misalignment**: when a reply writes
several variable-length elements back-to-back and a **per-element field declares the *padded* length
while the element itself is written *unpadded***. OS padding only pads the *end* of the whole buffer,
not the gaps *between* elements, so element N+1 is then read at the wrong offset. Two confirmed
instances:

- **`ProcXDGAQueryModes`** — each mode entry is `xXDGAModeInfo` (with `name_size = (size+3)&~3`,
  padded) followed by the name written `size` bytes (unpadded). Fixed in **PR #3173** by switching to
  `x_rpcbuf_write_string_0t_pad()` (pads each name). The sibling single-string handlers
  (`ProcXDGAOpenFramebuffer`, `xf86dri`, `appledri`, GetProperty, ListExtensions/Fonts, etc.) are
  **safe** — single trailing blob, OS-padded.
- **`x_rpcbuf_write_counted_string_pad(NULL)`** wrote *zero* bytes, but a counted string is a fixed
  wire element (CARD16 length + bytes + pad); an empty one is 4 bytes. Fixed in **PR #3195** to emit
  the empty counted string for NULL.

**Verification method that worked when the web spec was unreachable** (x.org PDF 403,
gitlab.freedesktop.org Anubis-blocked, the one-page HTML lacks Appendix D): use the **in-tree
round-trip contract** as the authority — the server's own *reader* for the same wire format
(`_GetCountedString` in `Xext/xkeyboard/xkb.c` unconditionally consumes a CARD16 length, advancing
`XkbPaddedSize(len+2)` → 4 bytes for an empty string) plus the *sizer* (`XkbSizeCountedString(NULL)
== 4`) define the contract precisely. Reader + sizer + writer must agree.

## Coding style (xserver source) — new code always braces if/while/for bodies

**Standing policy, confirmed 2026-07-03: always wrap `if`/`while`/`for`/`else` bodies in `{ }`,
even a single-statement body.** Two tracks, both active:

1. **All new/touched code, from now on, unconditionally.** Any agent adding or editing an
   `if`/`while`/`for`/`else` body — regardless of how it got there (a bugfix, a backport, a
   one-line tweak inside a function that already has unbraced bodies elsewhere) — must brace it.
   This was already the rule since 2026-07-01 (PR #3199: `os/Xtranssock.c`'s new
   `unix_socket_is_live()` and the `hostx.c` NULL-check fix were both corrected from unbraced to
   braced per this rule) — reconfirmed 2026-07-03 as permanent project policy, not a one-off.
2. **Successive conversion of existing unbraced bodies, in small digestible chunks.** The
   existing tree is inconsistent (plenty of unbraced single-statement bodies, e.g.
   `os/Xtranssock.c`'s `set_sun_path()`: `if (!port || !*port || !path)` on one line, a
   tab-indented `return -1;` on the next, no braces). This is **not** a mass-reformat — don't
   touch the whole tree in one commit/PR. Instead, treat it as an ongoing background initiative:
   when picking up unrelated work in a file that has unbraced bodies nearby, or in a dedicated
   session with spare capacity, convert a **small, self-contained batch** (e.g. one file, or a
   handful of related functions) into its own PR, purely mechanical (brace-only, no other
   changes mixed in, so the diff is trivially reviewable). Track progress as the
   "if/while/for brace-everywhere conversion" theme in `DASHBOARD.md` (Aktive Themen) rather than
   letting each batch's PR be the only record — update that row each session a batch lands so
   the initiative doesn't silently stall between sessions.

Indentation inside a body — braced or not — still follows whatever the surrounding function already
uses; in older files like `Xtranssock.c` that's a single **tab** per nesting level (mixed with
4-space alignment for wrapped continuation lines), not 4 spaces. Match the immediate surrounding
code, don't impose a new indent style along with the new braces.

Brace *placement* (`if (...) {` same line vs. `if (...)\n{` own line) is genuinely mixed
throughout the tree with no single dominant convention even within one file — match whichever
style the immediately surrounding code already uses; either is acceptable for new code.

This note lives here for now; consider promoting xserver-specific coding-style rules (this one and
any future ones) to a dedicated document inside the xserver tree itself (e.g. `CODING_STYLE.md`)
once there are enough of them to warrant it, rather than growing an unbounded style section in this
workspace-level file.

## Licensing policy

Two different scopes — don't conflate them:

- **New files that end up linked into the xserver binary itself (or a driver)** — anything that
  ships as part of the actual X server/driver deliverable — are, from now on, licensed
  **X11 OR MIT OR AGPL-3.0-or-later** (multi-licensed; the recipient picks whichever of the three
  suits them). Maintainer decision, 2026-07-02. The X11/MIT option keeps `X11Libre/xserver`'s own
  convention (`COPYING`: *"copyright holders of new code should use this license statement where
  possible"*) and keeps proprietary consumers (the NVIDIA blob, see the NVIDIA-ABI section)
  unaffected, since they can just use that grant; AGPL-3.0-or-later is offered as an *additional*
  choice, not a replacement — this is why the AGPL-vs-NVIDIA-friendliness tension flagged earlier
  the same day doesn't apply once it's multi-licensed rather than AGPL-only. Applies only to a
  genuinely **new** file wholly authored by the maintainer (or an agent on their behalf) — editing
  an existing file that already carries the plain X11/MIT grant does **not** relicense that file;
  the new triple-license only attaches to brand-new files.
- **New files that are NOT part of the final delivery** — helper scripts, CI workflow/config, dev
  tooling, build orchestration — wherever they live (mpbt-workspace's own `scripts/*`, but equally
  a newly-authored file under e.g. `.github/scripts/` inside an xserver/driver clone) — are, from
  now on, **AGPL-3.0-or-later only**. mpbt-workspace's own tooling was already fully relicensed
  this way, 2026-07-02 (see `LICENSE` + the `SPDX-License-Identifier: AGPL-3.0-or-later` +
  copyright header pattern used throughout `scripts/*` — copy that pattern for any new script
  anywhere, xserver-repo helper scripts included).

**Not retroactive yet — explicitly deferred, do not act on this without a fresh go-ahead:**
applying either license to *existing* files. Maintainer's stated plan (2026-07-02): eventually
retrofit files that were written **solely** by the maintainer (never touching code originally
authored by someone else — e.g. any of the upstream X.Org/XFree86 contributors listed in
`X11Libre/xserver`'s `COPYING`). This is recorded here purely as a **TODO** — don't relicense any
existing file proactively; wait for an explicit instruction each time.

## opencode session setup

To work with this workspace via opencode, the user needs to:

1. Install opencode (`npm i -g opencode-ai` or their distro's package)
2. Run `opencode providers` to add an API provider credential (stored globally in
   `~/.local/share/opencode/auth.json`, no project-level config needed)
3. Start a session: `./run-opencode.xserver-<release>`

The `run-opencode.*` scripts source `cf/<release>/config.sh` and export
`XLIBRE_RELEASE` so subagents know which solution and workdir to use.

## No CI, no tests, no lint, no formatter

None of these exist in this repo. The X Test Suite (xts) is a build target, not a test runner.

## File layout reminder

- `.gitignore` only ignores `/_WORK_/`
- One git branch: `master` (the `wip1` branch this once mentioned no longer exists — checked
  `git branch -a` + `gh api repos/X11Libre/mpbt-workspace/branches`, 2026-07-01; agents work off
  their own `mtx/*`/task branches instead)
- Remote: `git@github.com:X11Libre/mpbt-workspace.git`
- **License:** `LICENSE` (AGPL-3.0-or-later, canonical FSF text) covers this workspace's own
  tooling — see the "Licensing policy" section above for the full scope (this repo vs.
  xserver/driver clones) and the current new-files-only, not-yet-retroactive status.
