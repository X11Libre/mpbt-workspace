
## PR repair workflow (fix an open master PR — e.g. failing CI)

Distinct from backporting: here you *amend an existing, unmerged* master PR (typically to fix a
broken build) rather than cherry-picking a merged one onto a release line. Same isolation rule —
work in a dedicated agent clone, never the user's hand-edited sources tree.

1. **Get the real failure first — don't reason blind.** Easiest: `scripts/starfleetctl github pr job-logs <pr#>`
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

2. **Check out the PR branch in an isolated clone:** `scripts/starfleetctl github pr checkout <pr#>` → makes/refreshes
   `_WORK_/xserver-master/agent/repair/xserver`, checks out the PR's head branch, prints the
   clone dir.

   **`github pr checkout` handles both same-repo and fork PRs.** A fork PR has its head branch on the
   contributor's repo, so `origin/<headRef>` doesn't exist. github pr checkout auto-detects this
   (`isCrossRepository`), wires a dedicated `fork` remote mirroring origin's transport
   (SSH → reuses the praetor's key, no token), and checks out the branch tracking
   `fork/<headRef>`; `github pr amend-push` then pushes the amended commit back to that `fork` remote
   (it reads `branch.<head>.remote`, falling back to origin for same-repo PRs). Push-back needs the
   PR's *allow edits from praetors* (`maintainerCanModify: true`) — github pr checkout warns if false.
   (This was originally a bug: github pr checkout did `fetch origin <headRef>` unconditionally and failed
   on forks, and github pr amend-push hard-coded a push to origin; both fixed while rebasing #625, head
   `patch-1` on fork `BrightCat14/xyzserver`.)

   **Rebasing a long-stale PR may reveal it's obsolete, not conflicting.** #625 (Aug 2025, an
   integer-overflow guard before `calloc(1, rep.length << 2)` in `doListFontsAndAliases`) hit a
   conflict on rebase because master had ~2295 commits since and had *removed the vulnerable
   `calloc` entirely*, replacing the hand-managed buffer with the growable `x_rpcbuf_t` API
   (`x_rpcbuf_write_CARD8s` + `rpcbuf.error` → `BadAlloc`). Resolving toward master left an empty
   change (only a now-unused `#include <limits.h>`). When a rebase would produce a no-op, **don't
   force-push a hollow commit** to the contributor's branch — confirm with the praetor and close
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

4. **Amend + push:** `scripts/starfleetctl github pr amend-push <clone-dir> [files...]` folds the edits into the PR's
   single commit (`--amend --no-edit`, preserving message + `Signed-off-by`) and
   `--force-with-lease` back to the branch. CI re-triggers automatically on the new head.

(If a separate fixup commit is preferable to amending, commit + push by hand from the clone.)
