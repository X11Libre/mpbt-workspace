# DASHBOARD.md

Living index of **themes/initiatives** — not individual PRs (GitHub already tracks those; don't
duplicate `gh pr list` here). Purpose: let parallel agents (and the praetor) see at a glance
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

Thin index — each row links to its own file under `dashboard/themes/`. Edit the theme
file directly (Read/Edit as always); this index itself is regenerated with
`scripts/starfleetctl dashboard reindex` and should not normally be hand-edited.

| Thema | Status | Datei |
|---|---|---|
| agent-bus: periodic heartbeat refresh (avoid false-dead ships past BUS_TTL) | Done, 2026-07-06 (Constellation), directive m0086 | [`dashboard/themes/agent-bus-periodic-heartbeat-refresh.md`](dashboard/themes/agent-bus-periodic-heartbeat-refresh.md) |
| Agent control plane ("1st officer" — one central contact for many workers) | Steps 1 and 2 done (ask/reply + notify watcher + permission-forward hook); tested | [`dashboard/themes/agent-control-plane.md`](dashboard/themes/agent-control-plane.md) |
| Bool → bool (stdbool.h) phase-out | Ongoing, opportunistic (no dedicated branch) | [`dashboard/themes/bool-bool-phase-out.md`](dashboard/themes/bool-bool-phase-out.md) |
| Convince other contributors to adopt mpbt-workspace | Idea stage — direction being discussed, nothing written yet | [`dashboard/themes/convince-other-contributors-to-adopt-mpbt-workspace.md`](dashboard/themes/convince-other-contributors-to-adopt-mpbt-workspace.md) |
| DESQview/X (X11R5 DOS server, Quarterdeck, early 90s) under QEMU — vintage interop test for go-x11proto/pyxtest | Phase 1 (proof-of-life networking) DONE 2026-07-06 — FreeDOS 1.4 boots from virtual HDD under qemu-system-i386, mTCP+NE2000 packet driver… | [`dashboard/themes/desqview-x-under-qemu-vintage-interop-test-for-go-x11proto-p.md`](dashboard/themes/desqview-x-under-qemu-vintage-interop-test-for-go-x11proto-p.md) |
| Extension request-handler vulnerability scan (wip/ext-handler-vulns) | 20 fixes committed on a local, unpushed branch off release/25.1; disclosure path not yet decided | [`dashboard/themes/extension-request-handler-vulnerability-scan.md`](dashboard/themes/extension-request-handler-vulnerability-scan.md) |
| Fleet auto-scaling — spawn ships on demand when queued parallel work exceeds idle capacity | Manual on-demand path built + tested (Pegasus). Unattended autospawn AUTHORIZED 2026-07-06 (praetor) — interim policy: Enterprise may… | [`dashboard/themes/fleet-auto-scaling-spawn-ships-on-demand-when-queued-paralle.md`](dashboard/themes/fleet-auto-scaling-spawn-ships-on-demand-when-queued-paralle.md) |
| FlyingTux (sister project, separate repo) — rebuild on Go + restructure; adopt xnamespace for X11 app isolation now | ✅ PR #3103 merged 2026-07-03 (5f85319) — X-NAMESPACE wire protocol now on xserver-master. | [`dashboard/themes/flyingtux-rebuild-on-go-restructure-adopt-xnamespace-for-x11.md`](dashboard/themes/flyingtux-rebuild-on-go-restructure-adopt-xnamespace-for-x11.md) |
| go-x11proto library + tools + Debian packaging (separate repo/project) | **v0.0.7 released on `master`**; new `staging` branch created 2026-07-06 (mtx/agent-config equivalent) carrying the `tk/widget` rich-text layer + `tk/term` terminal emulator, both pushed | [`dashboard/themes/go-x11proto-library-tools-debian-packaging.md`](dashboard/themes/go-x11proto-library-tools-debian-packaging.md) |
| HDR (High Dynamic Range) display support | Analysis done, first prep extraction built and pushed | [`dashboard/themes/hdr-display-support.md`](dashboard/themes/hdr-display-support.md) |
| if/while/for brace-everywhere conversion (xserver coding style) | Claimed by Potemkin, 2026-07-06 — first batch open, CI running | [`dashboard/themes/if-while-for-brace-everywhere-conversion.md`](dashboard/themes/if-while-for-brace-everywhere-conversion.md) |
| Issue #3136 (veloren fullscreen crash) — two unrelated bugs | Bug1 workaround PR open (draft); Bug2 investigating + 2 side-leaks fixed | [`dashboard/themes/issue-3136-two-unrelated-bugs.md`](dashboard/themes/issue-3136-two-unrelated-bugs.md) |
| Long-term fleet architecture vision: bridge command frontend, multi-workspace federation, decentralized/isolated execution | Vision/direction from the praetor, 2026-07-06 — not a concrete task queue yet | [`dashboard/themes/long-term-fleet-architecture-vision-bridge-command-frontend.md`](dashboard/themes/long-term-fleet-architecture-vision-bridge-command-frontend.md) |
| m0047 (Enterprise, 2026-07-06) — check whether the agent-bus "ecosystem" scripts still left on bash after the core cutover (agent-bus-watch, agent-bus-monitor-loop, agent-bus-fleet-watch, agent-bus-boot-prompt, agent-bus-monitor-hint, agent-bus-auto-id.sh, the SessionStart/SessionEnd hooks) can now move to Go too. Investigated by Farragut, 2026-07-06 — result: mostly NO, with one real, unresolved blocker found. | see body | [`dashboard/themes/m0047-check-whether-the-agent-bus-ecosystem-scripts-still-le.md`](dashboard/themes/m0047-check-whether-the-agent-bus-ecosystem-scripts-still-le.md) |
| NetBSD CI: scoped pkgsrc/X11-sets mirror on GitHub (insulate xserver-build-netbsd from ftp/cdn.netbsd.org flakes) | Built + PR opened, not merged | [`dashboard/themes/netbsd-ci-scoped-pkgsrc-x11-sets-mirror-on-github.md`](dashboard/themes/netbsd-ci-scoped-pkgsrc-x11-sets-mirror-on-github.md) |
| NVIDIA open DDX (replace closed X-side driver, keep proprietary libGL) | Planning + tooling; nothing run on real NVIDIA HW yet | [`dashboard/themes/nvidia-open-ddx.md`](dashboard/themes/nvidia-open-ddx.md) |
| Permission-confirmation telemetry — log Bash calls that would need an interactive prompt, mine for new starfleetctl/scripts/ wrapper candidates | Claimed by Potemkin, 2026-07-06 — built, tested live, shipped to shared .claude/settings.json | [`dashboard/themes/permission-confirmation-telemetry-log-bash-calls-that-would.md`](dashboard/themes/permission-confirmation-telemetry-log-bash-calls-that-would.md) |
| Platform-specific #ifdef cleanup — grab-bag OS macros → concrete feature flags | In progress | [`dashboard/themes/platform-specific-ifdef-cleanup-grab-bag-os-macros-concrete.md`](dashboard/themes/platform-specific-ifdef-cleanup-grab-bag-os-macros-concrete.md) |
| PR review backlog (/bot-review) | Ongoing, recurring — large backlog | [`dashboard/themes/pr-review-backlog.md`](dashboard/themes/pr-review-backlog.md) |
| Propose removing xf86bigfont extension entirely | Draft PR opened + rebased | [`dashboard/themes/propose-removing-xf86bigfont-extension-entirely.md`](dashboard/themes/propose-removing-xf86bigfont-extension-entirely.md) |
| Propose removing XFS (X Font Server client) support | Investigated, closed — no in-tree removal target exists. | [`dashboard/themes/propose-removing-xfs-support.md`](dashboard/themes/propose-removing-xfs-support.md) |
| README for the mpbt-hq/starfleetctl repo itself | see body | [`dashboard/themes/readme-for-the-mpbt-hq-starfleetctl-repo-itself.md`](dashboard/themes/readme-for-the-mpbt-hq-starfleetctl-repo-itself.md) |
| Request-handler conversion to X_REQUEST_()/X_REPLY_()/rpcbuf macros | Xinerama family DONE (2 PRs open); broader dix/Xext sweep pending praetor OK on scope/granularity | [`dashboard/themes/request-handler-conversion-to-xrequest-xreply-rpcbuf-macros.md`](dashboard/themes/request-handler-conversion-to-xrequest-xreply-rpcbuf-macros.md) |
| Split DASHBOARD.md into per-theme files (dashboard/themes/<slug>.md) + a thin generated index | Done, 2026-07-06 (Potemkin, directive m0073) — migrated, tooling built, live. | [`dashboard/themes/split-dashboard-md-into-per-theme-files-a-thin-generated-ind.md`](dashboard/themes/split-dashboard-md-into-per-theme-files-a-thin-generated-ind.md) |
| Starfleet ↔ Telegram integration — send & receive Telegram messages | Idea stage — just requested, nothing started | [`dashboard/themes/starfleet-telegram-integration-send-receive-telegram-message.md`](dashboard/themes/starfleet-telegram-integration-send-receive-telegram-message.md) |
| starfleetctl (renamed from mpbtctl): consolidate the flock/race-prone agent-scripts (agent-bus, pr-claim, ws-commit first) into one Go CLI | In progress 2026-07-03, assigned to Farragut, successive/incremental — agent-bus subcommand ported, parity-verified, now its own repo +… | [`dashboard/themes/starfleetctl-consolidate-the-flock-race-prone-agent-scripts.md`](dashboard/themes/starfleetctl-consolidate-the-flock-race-prone-agent-scripts.md) |
| submit/ stale-branch cleanup | In progress — most already cleared | [`dashboard/themes/submit-stale-branch-cleanup.md`](dashboard/themes/submit-stale-branch-cleanup.md) |
| Unnumbered idea (optional, "evtl." per praetor — not a commitment): | see body | [`dashboard/themes/unnumbered-idea.md`](dashboard/themes/unnumbered-idea.md) |
| Vendor libXfont2 in-tree (like os/Xtrans.c already is), then strip the dead fc/ backend | Idea stage — sized/scoped 2026-07-01, nothing written yet | [`dashboard/themes/vendor-libxfont2-in-tree-then-strip-the-dead-fc-backend.md`](dashboard/themes/vendor-libxfont2-in-tree-then-strip-the-dead-fc-backend.md) |
| Wire valgrind (memcheck) into CI, hunt memleaks/UAF/OOB | Done — PR open + fully green, awaiting praetor merge decision | [`dashboard/themes/wire-valgrind-into-ci-hunt-memleaks-uaf-oob.md`](dashboard/themes/wire-valgrind-into-ci-hunt-memleaks-uaf-oob.md) |
| x86emu INTR_BOOL_TO_U64/carry-macro cleanup | Paused mid-cleanup — found real semantic differences between the two code paths | [`dashboard/themes/x86emu-intrbooltou64-carry-macro-cleanup.md`](dashboard/themes/x86emu-intrbooltou64-carry-macro-cleanup.md) |
| xephyr-glamor / XTS CI hang, all-3-retries case | Investigated — looks like a one-off, not a new persistent regression | [`dashboard/themes/xephyr-glamor-xts-ci-hang-all-3-retries-case.md`](dashboard/themes/xephyr-glamor-xts-ci-hang-all-3-retries-case.md) |
| xf86-input-hurd native input driver (Mach device ports) | WIP, open | [`dashboard/themes/xf86-input-hurd-native-input-driver.md`](dashboard/themes/xf86-input-hurd-native-input-driver.md) |
| xf86bigfont resurrection & cleanup | Step 1 done — builds on all lanes again (#3202 merged: sysmacros + mingw fixes). #3205 merged: meson default-off restored + bigfont… | [`dashboard/themes/xf86bigfont-resurrection-cleanup.md`](dashboard/themes/xf86bigfont-resurrection-cleanup.md) |
| Xinerama/PanoramiX refactor — replace proc-vector hooking with a frontend/backend split | Idea stage — plan specified by praetor, no branch yet | [`dashboard/themes/xinerama-panoramix-refactor-replace-proc-vector-hooking-with.md`](dashboard/themes/xinerama-panoramix-refactor-replace-proc-vector-hooking-with.md) |
| xorg-upstream tracking (tracking/xorg/main-on-<rel>) | Ongoing, recurring — delta fully dispositioned + all 4 trackers advanced, 2026-07-02 | [`dashboard/themes/xorg-upstream-tracking.md`](dashboard/themes/xorg-upstream-tracking.md) |
| xserver-build-freebsd CI lane currently red fleet-wide — NOT a transient flake, a real OS/package version-skew that won't self-clear on retry | Master merged; backported to release/25.1+25.2 (25.0 N/A, no FreeBSD lane); PRs open, awaiting praetor's manual release-line merge. | [`dashboard/themes/xserver-build-freebsd-ci-lane-currently-red-fleet-wide-not-a.md`](dashboard/themes/xserver-build-freebsd-ci-lane-currently-red-fleet-wide-not-a.md) |

## Parkplatz

Angefangen/aufgefallen, aber (noch) nicht weiterverfolgt — kurze Notiz statt Verlust.

| Thema | Notiert | Seit | Datei |
|---|---|---|---|
| ABI verdict already recorded in AGENTS.md/NVIDIA-ABI.md, but the PR itself is still open | `AGENTS.md` "Automated reviews" (NVIDIA-ABI section) | 2026-07-01 | [`dashboard/themes/abi-verdict-already-recorded-in-agents-md-nvidia-abi-md-but.md`](dashboard/themes/abi-verdict-already-recorded-in-agents-md-nvidia-abi-md-but.md) |
| agent-bus has no message authentication — any ship identity is pure self-report | Constellation (m0032) + Endeavour (m0033), independently, 2026-07-06 | 2026-07-06 | [`dashboard/themes/agent-bus-has-no-message-authentication-any-ship-identity-is.md`](dashboard/themes/agent-bus-has-no-message-authentication-any-ship-identity-is.md) |
| ARRAY_SIZE defined 9× in-tree, inconsistently guarded | `include/dix.h` + 8 others (`grep -rn 'define ARRAY_SIZE'`); dix.h guarded (#3203 **merged**; no backport — Solaris not in release CI) | 2026-07-01 | [`dashboard/themes/arraysize-defined-9-in-tree-inconsistently-guarded.md`](dashboard/themes/arraysize-defined-9-in-tree-inconsistently-guarded.md) |
| Better model for the flagship/top-level coordination role (Enterprise) — faster interactive turnaround | praetor, 2026-07-06 | 2026-07-06 | [`dashboard/themes/better-model-for-the-flagship-top-level-coordination-role-fa.md`](dashboard/themes/better-model-for-the-flagship-top-level-coordination-role-fa.md) |
| bigfont: does core logic belong in dix? | `BIGFONT.md` | 2026-07-01 | [`dashboard/themes/bigfont-does-core-logic-belong-in-dix.md`](dashboard/themes/bigfont-does-core-logic-belong-in-dix.md) |
| bigfont: hard-wired dix→extension call in CloseFont() | `BIGFONT.md` | 2026-07-01 | [`dashboard/themes/bigfont-hard-wired-dix-extension-call-in-closefont.md`](dashboard/themes/bigfont-hard-wired-dix-extension-call-in-closefont.md) |
| bigfont: xlibre/bigfont-consolidate-cleanup branch has no actual commit | agent clone `_WORK_/xserver-master/agent/rhel-ci/xserver` | 2026-07-01 | [`dashboard/themes/bigfont-xlibre-bigfont-consolidate-cleanup-branch-has-no-act.md`](dashboard/themes/bigfont-xlibre-bigfont-consolidate-cleanup-branch-has-no-act.md) |
| FlyingTux + go-x11proto in mpbt integrieren (in die Fleet holen, statt Außenposten) | praetor, 2026-07-02 | 2026-07-02 | [`dashboard/themes/flyingtux-go-x11proto-in-mpbt-integrieren.md`](dashboard/themes/flyingtux-go-x11proto-in-mpbt-integrieren.md) |
| FlyingTux master: Python-2-only Syntax in deploy.py | agent, 2026-07-02 (bei der mpbt-Solution-Integration entdeckt) | 2026-07-02 | [`dashboard/themes/flyingtux-master-python-2-only-syntax-in-deploy-py.md`](dashboard/themes/flyingtux-master-python-2-only-syntax-in-deploy-py.md) |
| Generalize parts of mtx/agent-config onto master | praetor decision, 2026-07-01 | 2026-07-01 | [`dashboard/themes/generalize-parts-of-mtx-agent-config-onto-master.md`](dashboard/themes/generalize-parts-of-mtx-agent-config-onto-master.md) |
| Hurd CI job (xserver-build-hurd) can hang with no timeout | run 28600347199 / job 84806756748 (PR #3231), cancelled by praetor after ~33m; `.github/scripts/hurd/run-vm-build.sh` (QEMU), see `AGENTS.md` "Hurd CI" | 2026-07-02 | [`dashboard/themes/hurd-ci-job-can-hang-with-no-timeout.md`](dashboard/themes/hurd-ci-job-can-hang-with-no-timeout.md) |
| Hurd kdrive backend for xfbdev | `AGENTS.md` Hurd CI section | 2026 (PR #3193 probe) | [`dashboard/themes/hurd-kdrive-backend-for-xfbdev.md`](dashboard/themes/hurd-kdrive-backend-for-xfbdev.md) |
| Legacy backport-queue tracker PRs #2170 ("backport WIP queue onto 25.0") / #2171 ("...onto 25.1") | `gh pr view 2170/2171` | 2026-07-01 | [`dashboard/themes/legacy-backport-queue-tracker-prs-2170-2171.md`](dashboard/themes/legacy-backport-queue-tracker-prs-2170-2171.md) |
| NVIDIA ABI check version coverage is only 4 versions (390/470/550/570) | `NVIDIA-ABI.md` "Versions checked" (inline `TODO:`) | 2026 | [`dashboard/themes/nvidia-abi-check-version-coverage-is-only-4-versions.md`](dashboard/themes/nvidia-abi-check-version-coverage-is-only-4-versions.md) |
| opencode: keine Entsprechung zu Claude Codes Monitor-Tool → nur Notify, kein In-Context-Auto-Surfacing von agent-bus-Direktiven | praetor, 2026-07-03 | 2026-07-03 | [`dashboard/themes/opencode-keine-entsprechung-zu-claude-codes-monitor-tool-nur.md`](dashboard/themes/opencode-keine-entsprechung-zu-claude-codes-monitor-tool-nur.md) |
| panoramiXprocs.c noch nicht auf neue X_REQUEST-Makros umgestellt | praetor, 2026-07-02 (bei #3136 Bug-2-Audit aufgefallen) | 2026-07-02 | [`dashboard/themes/panoramixprocs-c-noch-nicht-auf-neue-xrequest-makros-umgeste.md`](dashboard/themes/panoramixprocs-c-noch-nicht-auf-neue-xrequest-makros-umgeste.md) |
| Pure-Go diagnosis tool (xdpyinfo-like) on go-x11proto | praetor idea, 2026-07-01 | 2026-07-01 | [`dashboard/themes/pure-go-diagnosis-tool-on-go-x11proto.md`](dashboard/themes/pure-go-diagnosis-tool-on-go-x11proto.md) |
| RESOLVED — Vokabel-Änderung "maintainer" → "praetor" (Commit 9c7d33f), bestätigt legitim | Constellation, 2026-07-06 | 2026-07-06 | [`dashboard/themes/resolved-vokabel-nderung-maintainer-praetor-best-tigt-legiti.md`](dashboard/themes/resolved-vokabel-nderung-maintainer-praetor-best-tigt-legiti.md) |
| Retrofit the new licensing policy onto existing files | praetor, 2026-07-02 | 2026-07-02 | [`dashboard/themes/retrofit-the-new-licensing-policy-onto-existing-files.md`](dashboard/themes/retrofit-the-new-licensing-policy-onto-existing-files.md) |
| Scripts „rund machen" + Agent-Doku in eigenes scripts/-File, eigener Commit → master | praetor, 2026-07-02 | 2026-07-02 | [`dashboard/themes/scripts-rund-machen-agent-doku-in-eigenes-scripts-file-eigen.md`](dashboard/themes/scripts-rund-machen-agent-doku-in-eigenes-scripts-file-eigen.md) |
| starfleetctl CLI structure: group subcommands instead of one flat namespace | praetor, 2026-07-06 | 2026-07-06 | [`dashboard/themes/starfleetctl-cli-structure-group-subcommands-instead-of-one.md`](dashboard/themes/starfleetctl-cli-structure-group-subcommands-instead-of-one.md) |
| TODO.md infra backlog (git-autopick, CI apt-caching x3, duplicate CI pipelines on PR push, cygwin repo build, real-Xserver-in-CI feasibility, gh-api helper scripts) | `TODO.md` | initial workspace upload | [`dashboard/themes/todo-md-infra-backlog.md`](dashboard/themes/todo-md-infra-backlog.md) |
| Uncommitted security-fix worktrees at /home/nekrad/src/xorg/xserver-rel-25.0 and -25.1 — outside mpbt-workspace, never tracked in agent-bus/DASHBOARD | Enterprise, 2026-07-03 | 2026-07-03 | [`dashboard/themes/uncommitted-security-fix-worktrees-at-home-nekrad-src-xorg-x.md`](dashboard/themes/uncommitted-security-fix-worktrees-at-home-nekrad-src-xorg-x.md) |
| x86emu #ifdef DEBUG / DB() macro cleanup | `X86EMU-CLEANUP.md` | 2026 | [`dashboard/themes/x86emu-ifdef-debug-db-macro-cleanup.md`](dashboard/themes/x86emu-ifdef-debug-db-macro-cleanup.md) |
| x86emu mul_long/idiv_long/div_long correctness bugs | `X86EMU-CLEANUP.md` | 2026 (fuzz run) | [`dashboard/themes/x86emu-mullong-idivlong-divlong-correctness-bugs.md`](dashboard/themes/x86emu-mullong-idivlong-divlong-correctness-bugs.md) |
| x86emu types.h u8/u16 kludge → stdint rename | `X86EMU-CLEANUP.md` | 2026 | [`dashboard/themes/x86emu-types-h-u8-u16-kludge-stdint-rename.md`](dashboard/themes/x86emu-types-h-u8-u16-kludge-stdint-rename.md) |
| Xinerama-Umbau: interner (unsichtbarer) Proxy-Screen statt Screen-0-Sonderrolle | praetor, 2026-07-02 | 2026-07-02 | [`dashboard/themes/xinerama-umbau-interner-proxy-screen-statt-screen-0-sonderro.md`](dashboard/themes/xinerama-umbau-interner-proxy-screen-statt-screen-0-sonderro.md) |
| xx-make-pr.sh leaks [PR #NNNN]/PR: markers onto the PR branch (not just the incubator) | `AGENTS.md` "PR workflow" | 2026 (found via PR #3162) | [`dashboard/themes/xx-make-pr-sh-leaks-pr-nnnn-pr-markers-onto-the-pr-branch.md`](dashboard/themes/xx-make-pr-sh-leaks-pr-nnnn-pr-markers-onto-the-pr-branch.md) |

---

*Not tracked here on purpose (already covered elsewhere, would just go stale):* individual open
PRs (`gh pr list --repo X11Libre/xserver`), who's-online-now (`scripts/agent-bus board`), PR-branch
locks (`scripts/pr-claim --list`), per-PR backport-dashboard tables (each master PR's own
description).

