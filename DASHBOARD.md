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

## Parkplatz

Angefangen/aufgefallen, aber (noch) nicht weiterverfolgt — kurze Notiz statt Verlust.

| Thema | Notiert | Seit | Notiz |
|---|---|---|---|
| x86emu `mul_long`/`idiv_long`/`div_long` correctness bugs | `X86EMU-CLEANUP.md` | 2026 (fuzz run) | Manual-path high-word carry bug in `mul_long`; u64-path overflow check wrong in `idiv_long`/`div_long`, `INT64_MIN / -1` SIGFPEs. Needs a dedicated, separately-reviewed correctness commit + the fuzz harness (`scratchpad/llcmp.c`, not checked in) as evidence |
| x86emu `types.h` u8/u16 kludge → stdint rename | `X86EMU-CLEANUP.md` | 2026 | Treewide mechanical rename, own large pass |
| x86emu `#ifdef DEBUG` / `DB()` macro cleanup | `X86EMU-CLEANUP.md` | 2026 | Low priority |
| Hurd kdrive backend for `xfbdev` | `AGENTS.md` Hurd CI section | 2026 (PR #3193 probe) | The one *real* open Hurd port gap (DRI/glamor are fundamentally blocked by no DRM kernel iface, not worth chasing) |
| `TODO.md` infra backlog (git-autopick, CI apt-caching x3, duplicate CI pipelines on PR push, cygwin repo build, real-Xserver-in-CI feasibility, gh-api helper scripts) | `TODO.md` | initial workspace upload | Never triaged since import — re-check which are still relevant before acting on any |

---

*Not tracked here on purpose (already covered elsewhere, would just go stale):* individual open
PRs (`gh pr list --repo X11Libre/xserver`), who's-online-now (`scripts/agent-bus board`), PR-branch
locks (`scripts/pr-claim --list`), per-PR backport-dashboard tables (each master PR's own
description).
