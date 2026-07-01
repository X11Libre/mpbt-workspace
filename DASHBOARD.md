# DASHBOARD.md

Living index of **themes/initiatives** — not individual PRs (GitHub already tracks those; don't
duplicate `gh pr list` here). Purpose: let parallel agents (and the maintainer) see at a glance
what's actively being worked, and stop half-started ideas from getting lost when a session ends.

Two sections:

- **Aktive Themen** — anything with real state (a branch, a doc, an open decision) that isn't
  finished yet. One row per theme, link to its detail doc/branch/PR.
- **Parkplatz** — noticed-but-not-started, or started-then-set-aside. Short note + date, so it can
  be picked up later instead of re-discovered from scratch.

**Maintenance rule** (see `AGENTS.md` "Working practices"): when you start, pause, or finish a
theme, update this file in the same session — don't rely on memory or chat history surviving.
Ephemeral live-status (who's online right now) stays in `agent-bus`/`pr-claim`; this file is for
the theme itself, so it stays useful after those TTLs expire.

---

## Aktive Themen

| Thema | Status | Doc / Branch / PR | Notiz |
|---|---|---|---|
| NVIDIA open DDX (replace closed X-side driver, keep proprietary `libGL`) | Planning + tooling; nothing run on real NVIDIA HW yet | `NVIDIA-OPEN-DDX.md`, RE tooling in `nvglx-re/` | Next action needs an NVIDIA box, driver ≥ ~550 (Tier A) |
| x86emu `INTR_BOOL_TO_U64`/carry-macro cleanup | Paused mid-cleanup — found real semantic differences between the two code paths | `X86EMU-CLEANUP.md` | Both DIV/IDIV paths have independent correctness bugs (see Parkplatz); needs its own reviewed fix, not a drop-in |
| Extension request-handler vulnerability scan (`wip/ext-handler-vulns`) | 20 fixes committed on a **local, unpushed** branch off `release/25.1`; disclosure path not yet decided | `VULN-SCAN-FULL.md` / `VULN-SCAN-extension-handlers.md` (findings), `VULN-FIX-PR.md` (push/PR recipe), `VULN-FIX-BACKPORT.md` (per-branch applicability: 10 apply to 25.0, 18 to master) | Public PR = public disclosure — needs a maintainer call before pushing |
| `xf86-input-hurd` native input driver (Mach device ports) | WIP, open | PR #3194 | — |
| `submit/*` stale-branch cleanup | In progress — most already cleared | 6 `submit/*` branches remain (was ~150; 79 cleared as of the June 2026 pass, see `AGENTS.md` "submit/* branch hygiene") | Remaining ones likely need the zipper-rebase or manual conflict resolution (the easy patch-id/merge-tree wins are done) |
| xorg-upstream tracking (`tracking/xorg/main-on-<rel>`) | Ongoing, recurring | `AGENTS.md` "xorg upstream tracking" | Check `git log <tracker>..xorg/main` per release periodically; advance tracker once a delta is fully dispositioned |
| Bool → bool (stdbool.h) phase-out | Ongoing, opportunistic (no dedicated branch) | `AGENTS.md` C-booleans note | Apply only in new/rewritten code touching a declaration — not a standalone sweep |
| PR review backlog (`/bot-review`) | Ongoing, recurring — large backlog | `gh pr list --repo X11Libre/xserver --state open` | 2026-07-01 snapshot: **84 of 140** open PRs carry no `bot-review-*` label yet (32 of those are drafts). No dedicated tracking doc — this row *is* the tracker; re-check the count periodically rather than listing PRs individually |
| `xf86bigfont` resurrection & cleanup | Step 1 (make it build everywhere) in progress — CI default-on surfaced bit-rot on 7 non-Linux lanes | `BIGFONT.md`; PRs #3202 (enable-in-CI), #3201 (pagesize/CSRG), branch `xlibre/bigfont-consolidate-cleanup` (ResetProc drop, pending) | Root causes: `sys/sysmacros.h` (5 BSD/macOS), `dix.h` `ARRAY_SIZE` redef (solaris), `geteuid`/`getegid`+unused-var (mingw). BSD/macOS compile-break → backport candidate. Later ideas in Parkplatz |

## Parkplatz

Angefangen/aufgefallen, aber (noch) nicht weiterverfolgt — kurze Notiz statt Verlust.

| Thema | Notiert | Seit | Notiz |
|---|---|---|---|
| x86emu `mul_long`/`idiv_long`/`div_long` correctness bugs | `X86EMU-CLEANUP.md` | 2026 (fuzz run) | Manual-path high-word carry bug in `mul_long`; u64-path overflow check wrong in `idiv_long`/`div_long`, `INT64_MIN / -1` SIGFPEs. Needs a dedicated, separately-reviewed correctness commit + the fuzz harness (`scratchpad/llcmp.c`, not checked in) as evidence |
| x86emu `types.h` u8/u16 kludge → stdint rename | `X86EMU-CLEANUP.md` | 2026 | Treewide mechanical rename, own large pass |
| x86emu `#ifdef DEBUG` / `DB()` macro cleanup | `X86EMU-CLEANUP.md` | 2026 | Low priority |
| Hurd kdrive backend for `xfbdev` | `AGENTS.md` Hurd CI section | 2026 (PR #3193 probe) | The one *real* open Hurd port gap (DRI/glamor are fundamentally blocked by no DRM kernel iface, not worth chasing) |
| `TODO.md` infra backlog (git-autopick, CI apt-caching x3, duplicate CI pipelines on PR push, cygwin repo build, real-Xserver-in-CI feasibility, gh-api helper scripts) | `TODO.md` | initial workspace upload | Never triaged since import — re-check which are still relevant before acting on any |
| `xx-make-pr.sh` leaks `[PR #NNNN]`/`PR:` markers onto the **PR branch** (not just the incubator) | `AGENTS.md` "PR workflow" | 2026 (found via PR #3162) | Root cause: `DEFAULT_MODE="rebase"` applies the marker rewrite to `$BRANCH_NAME` too, because the clean `incubator`-only mode needs interactive `git rebase -i` (unsupported here). Fix: scope the marker `--exec` to the incubator rebase only, make that path non-interactive (`GIT_SEQUENCE_EDITOR=true`, no `-i`). Until fixed, every `xx-make-pr.sh`-created PR needs a manual clean-subject check before merge |
| Legacy backport-queue tracker PRs `#2170` ("backport WIP queue onto 25.0") / `#2171` ("...onto 25.1") | `gh pr view 2170/2171` | 2026-07-01 | Old-style catch-all PRs, each just a checklist of ~25 sub-PR numbers (#2196–#2816 range) — predate the `tracking/xorg/main-on-<rel>` workflow. Check with maintainer whether these are superseded/closeable now that the tracker-branch workflow covers the same job |
| ABI verdict already recorded in `AGENTS.md`/`NVIDIA-ABI.md`, but the PR itself is still open | `AGENTS.md` "Automated reviews" (NVIDIA-ABI section) | 2026-07-01 | PR #1786 (`Draft: drop MI overlay code` — verdict: breaks all tested blobs, deletes 6 `miOverlay*` symbols), #2070 (`unexport xf86CursorScreenKeyRec` — verdict: resolved by runtime lookup in all blobs, unsafe), #808 (`RFC: drop XvMC` — verdict: safe, no tested blob references it) all still sit open on GitHub with no label/close action taken on the verdict |
| NVIDIA ABI check version coverage is only 4 versions (390/470/550/570) | `NVIDIA-ABI.md` "Versions checked" (inline `TODO:`) | 2026 | Widen via `scripts/fetch-all-nvidia-drivers --per-branch` (77 branches) for exhaustive coverage before relying on "no tested blob references it" as a strong safety verdict |
| bigfont: hard-wired dix→extension call in `CloseFont()` | `BIGFONT.md` | 2026-07-01 | `dix/dixfonts.c:539` directly calls `XF86BigfontFreeFontShm` under `#ifdef XF86BIGFONT`. Consider decoupling (per-font free-callback / registration) so dix doesn't hard-reference the extension |
| bigfont: does core logic belong in dix? | `BIGFONT.md` | 2026-07-01 | The shm/font-metrics-sharing machinery is arguably dix-level; the extension could shrink to the pure protocol/wire interface. Bigger redesign, after the build resurrection |

---

*Not tracked here on purpose (already covered elsewhere, would just go stale):* individual open
PRs (`gh pr list --repo X11Libre/xserver`), who's-online-now (`scripts/agent-bus board`), PR-branch
locks (`scripts/pr-claim --list`), per-PR backport-dashboard tables (each master PR's own
description).
