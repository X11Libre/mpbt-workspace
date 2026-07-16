---
name: pr-repair
description: Repair an open (unmerged) master PR — typically a failing CI build or test. Use when asked to fix a PR's CI, diagnose why a PR's checks are red, or amend an open PR. Gets the real failure from job logs, fixes it in an isolated clone, verifies locally, and amends + force-pushes.
---

# Repair an open master PR (failing CI, etc.)

Amend an existing, **unmerged** master PR (distinct from backporting a merged one). Work in a
dedicated agent clone — never the user's hand-edited `sources/xlibre/xserver` tree. Run commands
from the workspace root (`/home/nekrad/src/xorg/mpbt-workspace`).

Full reference: **`reference.md`** in this skill's directory (full detail, moved out of AGENTS.md). This skill is the actionable checklist.

## 1. Get the REAL failure first — don't reason blind

```bash
.starfleet-ai/bin/starfleetctl github pr job-logs <pr#>            # all failing jobs + failure summary
.starfleet-ai/bin/starfleetctl github pr job-logs --job <id>       # one specific job
.starfleet-ai/bin/starfleetctl github pr job-logs <pr#> --all      # every job
```

(`gh run view --log` returns nothing on this repo; the script wraps the REST
`actions/jobs/<id>/logs` endpoint. Per-check annotations only say "exit code 1" — not the cause.)

Read the summary, then identify the failure class:

- **Build/link:** first `FAILED:` / `: error:` / `undefined reference` / `ninja: build stopped`.
- **Configure (meson):** an interpreter error, e.g.
  `Xext/dpms/meson.build:6:3: ERROR: Unknown variable "build_dpms".`
- **Test phase (NOT a build error!):** a `xserver-build-*` job runs `meson test` (XTS) *after* a
  successful build, so there is **no** `FAILED:`/compile-`error:` line. Grep the **tail** for
  `Summary of Failures`, `Fail:`, and `Caught signal` / `Segmentation fault`. A server crash
  during XTS is a real regression, not flakiness.

## 2. Check out the PR branch in an isolated clone

```bash
.starfleet-ai/bin/starfleetctl github pr checkout <pr#>            # -> _WORK_/xserver-master/agent/repair/xserver
```

Prints the clone dir; the PR's head branch is checked out and ready to edit.

## 3. Fix it, then VERIFY LOCALLY before pushing

Even a meson-only change warrants a real build. From a throwaway build dir:

```bash
meson setup <builddir> <clone>                       # success = build.ninja generated
ninja -C <builddir> hw/vfb/Xvfb hw/xnest/Xnest       # links full libxserver list
```

This catches both configure errors and latent compile/duplicate-symbol problems.

**Runtime crash (XTS segfault):** the full XTS suite won't run locally (needs `XTEST_DIR`/piglit;
`xvfb-piglit.sh` exits 77 = skip). But dix-level crashes are drivable directly: build
`hw/vfb/Xvfb`, start it on a spare display (`Xvfb :91 &`), run a small libX11 client that issues
the offending request, then assert the server is still up (`kill -0 $xvfb_pid`). Toggle the fix
in/out (rebuild each way) to prove cause *and* sufficiency.

## 4. Amend + push

```bash
.starfleet-ai/bin/starfleetctl github pr amend-push <clone-dir> [files...]
```

Folds edits into the PR's single commit (`--amend --no-edit`, preserves message +
`Signed-off-by`) and `--force-with-lease` back to the branch. CI re-triggers on the new head.

(If a separate fixup commit is preferable to amending, commit + push by hand from the clone.)
