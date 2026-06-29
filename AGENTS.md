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

## Key commands

| command | purpose |
|---------|---------|
| `./install-mpbt` | `go install github.com/metux/mpbt/cmd/mpbt-builder@latest` |
| `./run-fetch.xserver-<release>` | clone/fetch all sources for a release line |
| `./run-build.xserver-<release>` | full build of all packages in order, then **deletes** `_WORK_/<release>/install` |
| `./run-opencode.xserver-<release>` | start opencode session for a release line (sets `XLIBRE_RELEASE`) |
| `scripts/xx-make-pr.sh [--rebase|--branch <name>] <commits...>` | create PR from commits on the incubator branch |
| `scripts/mk-agent-clone <release> [name]` | create/refresh an agent-owned clone for backport work (object-shared, isolated from your clone) |
| `scripts/backport-commit <release> <commit-ish\|PR#> [name]` | **one-shot backport**: refresh agent clone → `cherry-pick -x` → `xx-make-pr.sh`; opens the PR vs `release/<release>` |
| `scripts/show-branch-file <ref> <path> [symbol]` | print a repo file (or symbol region) at any ref via the GitHub API — for backport applicability checks; auto-handles the `Xext/<ext>/` ↔ `<ext>/` reorg |
| `scripts/backport-applies <master-path> <grep-ERE> [release ...]` | run the applicability grep across all release lines at once (wraps `show-branch-file`) — classify each branch vulnerable / already-fixed / N-A in one command |
| `scripts/pr-set-body <pr#> <body-file>` | set a PR body via REST API (works around the broken `gh pr edit`); for backport cross-linking |
| `scripts/pr-job-logs <pr#>` \| `--job <id>` \| `<pr#> --all` | **fetch raw CI job logs + failure summary** for a PR's failing jobs (or one job by id). Wraps the reliable `repos/<repo>/actions/jobs/<id>/logs` endpoint (since `gh run view --log` returns nothing here) and greps the real cause across **build/link** (`FAILED:`, `: error:`, `undefined reference`), **configure** (meson `ERROR:`, `Dependency "x" not found`), **dep-install** (Gentoo `emerge`/`!!!`, Alpine `apk`, Debian `E:`, Arch, Fedora), and **test-phase** (`Summary of Failures`, `Fail: N`, `Caught signal`/segfault) failures; falls back to the log tail when no marker matches. Writes to `$OUTDIR` (default `mktemp -d`) |
| `scripts/pr-checkout <pr#> [name]` | **repair an open master PR**: isolated agent clone + check out the PR's head branch, ready to edit (prints the clone dir) — pairs with `pr-amend-push` |
| `scripts/pr-amend-push <clone-dir> [files...]` | fold edits into the PR's commit (`--amend --no-edit`, keeps message + `Signed-off-by`) and `--force-with-lease` back to the PR branch |
| `scripts/pr-claim <pr#> ["what"]` \| `--list` \| `--release <pr#>` \| `--steal <pr#>` | **advisory cross-agent PR lock + work log** so multiple agents don't collide on the same PR (each has its own clone, but they share one GitHub PR branch). Claim a PR before mutating it; `--list` is the shared "who's working on what" log. Keyed by PR#, `flock`-serialized, stale after `$CLAIM_TTL` (1h). Set a unique `$AGENT_ID` per agent. See Concurrency |
| `scripts/agent-bus status <state> ["note"]` \| `board` \| `inbox` \| `ack <id>` \| `tell <agent> <text>` \| `broadcast <text>` | **cross-session control plane** (status heartbeats + directives) so one control agent ("1st officer") can see and steer many independent sessions without terminal-hopping. Workers `status`/`inbox`/`ack`; the controller reads `board` and posts `tell`/`broadcast`. File-based + `flock`-serialized under `_WORK_/agent-bus/` (gitignored), heartbeats stale after `$BUS_TTL` (15m). Set a unique `$AGENT_ID`; `$XLIBRE_RELEASE` is the default project column. Sibling of `pr-claim` (that = PR-branch ownership; this = who's-doing-what + steering). See Concurrency |
| `scripts/fetch-nvidia-drivers [version ...]` | download proprietary NVIDIA `.run` installers and extract the X-server modules (no install) for ABI checks |
| `scripts/list-nvidia-versions [--per-branch]` | enumerate NVIDIA driver versions on the mirror (all, or latest-per-branch) |
| `scripts/fetch-all-nvidia-drivers [--every]` | fetch+extract many versions (default: latest of each branch; `--every` = all 500+), pruning `.run`s |
| `scripts/nvidia-abi-check SYM ...` | classify symbols against extracted blobs: link-import (`nm`) ∪ runtime lookup (string) |
| `scripts/nvidia-undefined-symbols [version ...]` | raw dump of imported (UND) symbols (subset of nvidia-abi-check; prefer the latter) |
| `scripts/with-clone-lock <cmd...>` | run a mutating command holding an exclusive per-working-tree lock (see Concurrency) |
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

## PR workflow (`scripts/xx-make-pr.sh`)

Requires git config entries (these are automatically added by the run-fetch* scripts):

```ini
[make-pr]
    upstream-remote = origin
    upstream-branch = master   # or release/25.1, release/25.0
    reviewers = X11Libre/dev
```

The script cherry-picks commits onto a temp branch based on `$upstream_remote/$upstream_branch`, pushes, creates a PR (via `gh`), then rewrites commit messages with `[PR #NNNN]` prefix and `PR:` trailer, and rebases the incubator branch.

**The `[PR #NNNN]` prefix + `PR:` trailer belong ONLY on the incubator branch (`rfc/backport-*`) — never on the PR branch or the merged upstream commit.** The PR is pushed *before* the PR number exists, so the pushed/merged commit must keep its clean original message. Leak seen on master: PR #3162 merged 4 commits all prefixed `[PR #3162]`. Root cause — `xx-make-pr.sh` `DEFAULT_MODE="rebase"`: rebase mode runs the `[PR #N]` `sed` + `PR:` `--exec` rewrite against the **PR branch** `$BRANCH_NAME` (the head that gets merged), not just the incubator (the in-script comment even says *"markers added to PR branch"*). The clean `incubator` mode rewrites only the incubator, but it uses `git rebase -i` (interactive), which is unsupported in this environment — which is why the default was flipped to the contaminating `rebase` mode. **Until the script is fixed (apply the marker `--exec` to the *incubator* rebase only, leave `$BRANCH_NAME` untouched, and make that path non-interactive via `GIT_SEQUENCE_EDITOR=true`/no `-i`): before merging any `xx-make-pr.sh` PR, verify the PR head's subject line is clean (no `[PR #…]`).** A second leak vector: re-running `xx-make-pr.sh` on an incubator commit that is *already* prefixed re-cherry-picks the prefix onto the fresh PR branch — always submit the clean commit. (Already-merged prefixed commits are left as-is; no master history rewrite.)

**Cherry-pick conflict recovery (master moved under you).** The script `git fetch`es then cherry-picks
onto a *fresh* `origin/<upstream-branch>` tip. If upstream advanced and touched the same region as
your commit, the cherry-pick conflicts and the script bails, leaving a half-done `tmp-pr/…` branch.
**Do not** try to fix it by rebasing the whole incubator (`rfc/backport-*`) onto the new tip — the
incubator carries unrelated pending commits that bring their own conflicts. Instead reproduce just
the final steps by hand: `git checkout -b <pr-branch> origin/<upstream-branch>`, `git cherry-pick
<sha>`, resolve the one conflict, build-verify, `git push origin <pr-branch>`, then `gh pr create
-B <upstream-branch> -H <pr-branch> --reviewer "$(git config make-pr.reviewers)"`. (Seen creating
#3130: master had just re-parenthesized the same `include/list.h` macro the commit edited.)

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
`bot-review-passed` and update the review comment to match. Apply labels via the REST API, **not**
`gh pr edit` — the latter currently fails on this repo with the *"Projects classic deprecation"*
GraphQL error (same breakage as `pr-set-body` works around):

```sh
gh api --method POST repos/X11Libre/xserver/issues/<pr#>/labels -f 'labels[]=bot-review-passed'
```

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
- **Control agent** (`AGENT_ID=control` by convention): `agent-bus board` (the default no-arg
  command) is the whole-fleet view — every agent, project, state, heartbeat age, unacked-inbox
  count, note, `[STALE]` past `$BUS_TTL` (15m). Steer with `agent-bus tell <agent> <text…>` (one
  agent) or `agent-bus broadcast <text…>` (all); `agent-bus msgs` shows directives + ack counts,
  `agent-bus events` the audit trail, `agent-bus prune` reaps stale heartbeats + fully-acked old
  directives.

**Heartbeats are auto-reported — both session types register on the `board` without a manual call:**
- **Claude Code** via checked-in `.claude/settings.json` hooks: `SessionStart`
  (`agent-bus status idle "session started"`) and `SessionEnd` (`agent-bus clear`), invoked as
  `"$CLAUDE_PROJECT_DIR"/scripts/agent-bus …` (cwd-independent, `… || true` so they never block a
  session).
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

**Roadmap (not built yet):** the file layout is deliberately the data layer a richer controller can
sit on unchanged — a `watch`/TUI dashboard tailing `status/` + `msgs/`, or an **MCP server in
HTTP/SSE mode** (runs as a daemon, serves many independent sessions at once, needs no Claude key,
carries its own creds for any external access) acting as a push message-bus instead of file polling.
Start with the files; promote to MCP when polling latency or multi-host reach demands it.

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
  someone else uses. (Claude Code can spawn agents with `isolation: "worktree"`.)
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
- Two git branches: `master` and `wip1`
- Remote: `git@github.com:X11Libre/mpbt-workspace.git`
