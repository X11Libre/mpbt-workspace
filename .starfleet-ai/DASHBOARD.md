# DASHBOARD.md

Cross-session "what's in flight / what got parked" index — lets parallel agents
(and the praetor) see at a glance what's actively being worked, and stops
half-started ideas from getting lost when a session ends.

**Not individual PRs** (GitHub already tracks those via `gh pr list`).

Two sections:
- **Active Topics** — anything with real state (a branch, a doc, an open decision).
- **Parked** — noticed-but-not-started, or started-then-set-aside.

Thin index — each row links to its own file under `dashboard/topics/`. Use
`starfleetctl dashboard topic <cmd>` to read/write/commit individual topics;
this index itself is regenerated with
`starfleetctl dashboard reindex` and should not normally be hand-edited.

**Maintenance rule** (see `CLAUDE.md` "Working practices"): when you start,
pause, or finish a topic, update its entry **in the same session**.
Ephemeral live-status (who's online right now) stays in
`starfleetctl agent-bus board` / `starfleetctl pr-claim list`.

## Active Topics

| Topic | Status | File |
|---|---|---|
| agent-bus: periodic heartbeat refresh (avoid false-dead ships past BUS_TTL) | Done, 2026-07-06 (Constellation), directive m0086 | [`dashboard/topics/agent-bus-periodic-heartbeat-refresh.md`](dashboard/topics/agent-bus-periodic-heartbeat-refresh.md) |
| Agent control plane ("1st officer" — one central contact for many workers) | Steps 1 and 2 done (ask/reply + notify watcher + permission-forward hook); tested | [`dashboard/topics/agent-control-plane.md`](dashboard/topics/agent-control-plane.md) |
| Bool → bool (stdbool.h) phase-out | Ongoing, opportunistic (no dedicated branch) | [`dashboard/topics/bool-bool-phase-out.md`](dashboard/topics/bool-bool-phase-out.md) |
| Convince other contributors to adopt mpbt-workspace | Idea stage — direction being discussed, nothing written yet | [`dashboard/topics/convince-other-contributors-to-adopt-mpbt-workspace.md`](dashboard/topics/convince-other-contributors-to-adopt-mpbt-workspace.md) |
| Dashboard access fully encapsulated via starfleetctl — no more direct file access by agents | CLI-only guidance landed 2026-07-07 (Constellation, m0123). Open questions resolved, enforcement deliberately deferred (convention-only for… | [`dashboard/topics/dashboard-access-fully-encapsulated-via-starfleetctl-no-direct.md`](dashboard/topics/dashboard-access-fully-encapsulated-via-starfleetctl-no-direct.md) |
| DESQview/X (X11R5 DOS server, Quarterdeck, early 90s) under QEMU — vintage interop test for go-x11proto/pyxtest | Phase 1 (proof-of-life networking) DONE 2026-07-06 — FreeDOS 1.4 boots from virtual HDD under qemu-system-i386, mTCP+NE2000 packet driver… | [`dashboard/topics/desqview-x-under-qemu-vintage-interop-test-for-go-x11proto-p.md`](dashboard/topics/desqview-x-under-qemu-vintage-interop-test-for-go-x11proto-p.md) |
| Driver repos — cross-repo PR/issue dashboard (xserver issue #3280) | Built + live, 2026-07-07 (Agamemnon) — needs periodic refresh | [`dashboard/topics/driver-repos-cross-repo-pr-issue-dashboard.md`](dashboard/topics/driver-repos-cross-repo-pr-issue-dashboard.md) |
| Extension request-handler vulnerability scan (wip/ext-handler-vulns) | 20 fixes committed on a local, unpushed branch off release/25.1; disclosure path not yet decided | [`dashboard/topics/extension-request-handler-vulnerability-scan.md`](dashboard/topics/extension-request-handler-vulnerability-scan.md) |
| Fleet auto-scaling — spawn ships on demand when queued parallel work exceeds idle capacity | Manual on-demand path built + tested (Pegasus). Unattended autospawn AUTHORIZED 2026-07-06 (praetor) — interim policy broadened same day:… | [`dashboard/topics/fleet-auto-scaling-spawn-ships-on-demand-when-queued-paralle.md`](dashboard/topics/fleet-auto-scaling-spawn-ships-on-demand-when-queued-paralle.md) |
| FlyingTux (sister project, separate repo) — rebuild on Go + restructure; adopt xnamespace for X11 app isolation now | ✅ PR #3103 merged 2026-07-03 (5f85319) — X-NAMESPACE wire protocol now on xserver-master. | [`dashboard/topics/flyingtux-rebuild-on-go-restructure-adopt-xnamespace-for-x11.md`](dashboard/topics/flyingtux-rebuild-on-go-restructure-adopt-xnamespace-for-x11.md) |
| go-x11proto library + tools + Debian packaging (separate repo/project) | v0.0.7 released on master | [`dashboard/topics/go-x11proto-library-tools-debian-packaging.md`](dashboard/topics/go-x11proto-library-tools-debian-packaging.md) |
| HDR (High Dynamic Range) display support | Analysis done, first prep extraction built and pushed | [`dashboard/topics/hdr-display-support.md`](dashboard/topics/hdr-display-support.md) |
| Hurd CI job (xserver-build-hurd) can hang with no timeout | Claimed by Potemkin, 2026-07-06 — adding timeout-minutes. | [`dashboard/topics/hurd-ci-job-can-hang-with-no-timeout.md`](dashboard/topics/hurd-ci-job-can-hang-with-no-timeout.md) |
| if/while/for brace-everywhere conversion (xserver coding style) | Claimed by Potemkin, 2026-07-06 — first batch open, CI running | [`dashboard/topics/if-while-for-brace-everywhere-conversion.md`](dashboard/topics/if-while-for-brace-everywhere-conversion.md) |
| Issue #3136 (veloren fullscreen crash) — two unrelated bugs | Bug1 workaround PR open (draft); Bug2 investigating + 2 side-leaks fixed | [`dashboard/topics/issue-3136-two-unrelated-bugs.md`](dashboard/topics/issue-3136-two-unrelated-bugs.md) |
| Long-term fleet architecture vision: bridge command frontend, multi-workspace federation, decentralized/isolated execution | Vision/direction from the praetor, 2026-07-06 — not a concrete task queue yet | [`dashboard/topics/long-term-fleet-architecture-vision-bridge-command-frontend.md`](dashboard/topics/long-term-fleet-architecture-vision-bridge-command-frontend.md) |
| NetBSD CI: scoped pkgsrc/X11-sets mirror on GitHub (insulate xserver-build-netbsd from ftp/cdn.netbsd.org flakes) | Built + PR opened, not merged | [`dashboard/topics/netbsd-ci-scoped-pkgsrc-x11-sets-mirror-on-github.md`](dashboard/topics/netbsd-ci-scoped-pkgsrc-x11-sets-mirror-on-github.md) |
| NVIDIA open DDX (replace closed X-side driver, keep proprietary libGL) | Planning + tooling; nothing run on real NVIDIA HW yet | [`dashboard/topics/nvidia-open-ddx.md`](dashboard/topics/nvidia-open-ddx.md) |
| opencode plugin: session.prompt() vs tui.appendPrompt() for agent-bus | Entwurf / in Diskussion | [`dashboard/topics/opencode-plugin-session-prompt-vs-appendprompt-agent-bus.md`](dashboard/topics/opencode-plugin-session-prompt-vs-appendprompt-agent-bus.md) |
| opencode: Telemetry-Hook via Plugin | open | [`dashboard/topics/opencode-telemetry-hook-via-plugin.md`](dashboard/topics/opencode-telemetry-hook-via-plugin.md) |
| Permission-confirmation telemetry — log Bash calls that would need an interactive prompt, mine for new starfleetctl/scripts/ wrapper candidates | Claimed by Potemkin, 2026-07-06 — built, tested live, shipped to shared .claude/settings.json | [`dashboard/topics/permission-confirmation-telemetry-log-bash-calls-that-would.md`](dashboard/topics/permission-confirmation-telemetry-log-bash-calls-that-would.md) |
| Platform-specific #ifdef cleanup — grab-bag OS macros → concrete feature flags | In progress | [`dashboard/topics/platform-specific-ifdef-cleanup-grab-bag-os-macros-concrete.md`](dashboard/topics/platform-specific-ifdef-cleanup-grab-bag-os-macros-concrete.md) |
| PR review backlog (/bot-review) | Ongoing, recurring — large backlog | [`dashboard/topics/pr-review-backlog.md`](dashboard/topics/pr-review-backlog.md) |
| Propose removing xf86bigfont extension entirely | Draft PR opened + rebased | [`dashboard/topics/propose-removing-xf86bigfont-extension-entirely.md`](dashboard/topics/propose-removing-xf86bigfont-extension-entirely.md) |
| Propose removing XFS (X Font Server client) support | Investigated, closed — no in-tree removal target exists. | [`dashboard/topics/propose-removing-xfs-support.md`](dashboard/topics/propose-removing-xfs-support.md) |
| README for the mpbt-hq/starfleetctl repo itself | see body | [`dashboard/topics/readme-for-the-mpbt-hq-starfleetctl-repo-itself.md`](dashboard/topics/readme-for-the-mpbt-hq-starfleetctl-repo-itself.md) |
| Request-handler conversion to X_REQUEST_()/X_REPLY_()/rpcbuf macros | Xinerama family DONE (2 PRs open); broader dix/Xext sweep pending praetor OK on scope/granularity | [`dashboard/topics/request-handler-conversion-to-xrequest-xreply-rpcbuf-macros.md`](dashboard/topics/request-handler-conversion-to-xrequest-xreply-rpcbuf-macros.md) |
| Split DASHBOARD.md into per-theme files (dashboard/themes/<slug>.md) + a thin generated index | Done, 2026-07-06 (Potemkin, directive m0073) — migrated, tooling built, live. | [`dashboard/topics/split-dashboard-md-into-per-theme-files-a-thin-generated-ind.md`](dashboard/topics/split-dashboard-md-into-per-theme-files-a-thin-generated-ind.md) |
| Starfleet ↔ Telegram integration — send & receive Telegram messages | Idea stage — just requested, nothing started | [`dashboard/topics/starfleet-telegram-integration-send-receive-telegram-message.md`](dashboard/topics/starfleet-telegram-integration-send-receive-telegram-message.md) |
| Prepare starfleet fleet-coordination tooling for master (wip/starfleet-upstream) | Branch + draft PR created 2026-07-06 (Enterprise, praetor request) — empty scaffold, content prep not started yet. | [`dashboard/topics/starfleet-upstream-master-prep.md`](dashboard/topics/starfleet-upstream-master-prep.md) |
| starfleetctl (renamed from mpbtctl): consolidate the flock/race-prone agent-scripts (agent-bus, pr-claim, ws-commit first) into one Go CLI | In progress 2026-07-03, assigned to Farragut, successive/incremental — agent-bus subcommand ported, parity-verified, now its own repo +… | [`dashboard/topics/starfleetctl-consolidate-the-flock-race-prone-agent-scripts.md`](dashboard/topics/starfleetctl-consolidate-the-flock-race-prone-agent-scripts.md) |
| starfleetctl: User-Dokumentation erstellen | offen | [`dashboard/topics/starfleetctl-user-docs.md`](dashboard/topics/starfleetctl-user-docs.md) |
| submit/ stale-branch cleanup | In progress — most already cleared | [`dashboard/topics/submit-stale-branch-cleanup.md`](dashboard/topics/submit-stale-branch-cleanup.md) |
| confirm-log-hook + confirm-log-report nach starfleetctl migrieren | offen | [`dashboard/topics/task-confirm-log-starfleetctl.md`](dashboard/topics/task-confirm-log-starfleetctl.md) |
| go-x11 terminal: extra OSC-Codes implementieren | done | [`dashboard/topics/task-go-x11-terminal-extra-osc-codes-implementieren.md`](dashboard/topics/task-go-x11-terminal-extra-osc-codes-implementieren.md) |
| go-x11 terminal: fully detachable (tmux-like) | done | [`dashboard/topics/task-go-x11-terminal-fully-detachable-tmux-like.md`](dashboard/topics/task-go-x11-terminal-fully-detachable-tmux-like.md) |
| starfleetctl: direkter Dashboard-Dateizugriff verbieten | open | [`dashboard/topics/task-starfleetctl-direkter-dashboard-dateizugriff-verbieten.md`](dashboard/topics/task-starfleetctl-direkter-dashboard-dateizugriff-verbieten.md) |
| starfleetctl: GitHub-Commands in Subcommands untergliedern | done | [`dashboard/topics/task-starfleetctl-github-commands-in-subcommands-untergliedern.md`](dashboard/topics/task-starfleetctl-github-commands-in-subcommands-untergliedern.md) |
| terminal-aa-detach: Race Condition bei attach/detach beheben | open | [`dashboard/topics/task-terminal-aa-detach-race-condition-bei-attach-detach-beheben.md`](dashboard/topics/task-terminal-aa-detach-race-condition-bei-attach-detach-beheben.md) |
| xx-make-pr.sh in starfleetctl einbauen | offen | [`dashboard/topics/task-xx-make-pr-starfleetctl.md`](dashboard/topics/task-xx-make-pr-starfleetctl.md) |
| Unnumbered idea (optional, "evtl." per praetor — not a commitment): | see body | [`dashboard/topics/unnumbered-idea.md`](dashboard/topics/unnumbered-idea.md) |
| Vendor libXfont2 in-tree (like os/Xtrans.c already is), then strip the dead fc/ backend | Idea stage — sized/scoped 2026-07-01, nothing written yet | [`dashboard/topics/vendor-libxfont2-in-tree-then-strip-the-dead-fc-backend.md`](dashboard/topics/vendor-libxfont2-in-tree-then-strip-the-dead-fc-backend.md) |
| Wire valgrind (memcheck) into CI, hunt memleaks/UAF/OOB | Done — PR open + fully green, awaiting praetor merge decision | [`dashboard/topics/wire-valgrind-into-ci-hunt-memleaks-uaf-oob.md`](dashboard/topics/wire-valgrind-into-ci-hunt-memleaks-uaf-oob.md) |
| x86emu INTR_BOOL_TO_U64/carry-macro cleanup | Paused mid-cleanup — found real semantic differences between the two code paths | [`dashboard/topics/x86emu-intrbooltou64-carry-macro-cleanup.md`](dashboard/topics/x86emu-intrbooltou64-carry-macro-cleanup.md) |
| xephyr-glamor / XTS CI hang, all-3-retries case | Investigated — looks like a one-off, not a new persistent regression | [`dashboard/topics/xephyr-glamor-xts-ci-hang-all-3-retries-case.md`](dashboard/topics/xephyr-glamor-xts-ci-hang-all-3-retries-case.md) |
| xf86-input-hurd native input driver (Mach device ports) | WIP, open | [`dashboard/topics/xf86-input-hurd-native-input-driver.md`](dashboard/topics/xf86-input-hurd-native-input-driver.md) |
| xf86bigfont resurrection & cleanup | Step 1 done — builds on all lanes again (#3202 merged: sysmacros + mingw fixes). #3205 merged: meson default-off restored + bigfont… | [`dashboard/topics/xf86bigfont-resurrection-cleanup.md`](dashboard/topics/xf86bigfont-resurrection-cleanup.md) |
| Xinerama/PanoramiX refactor — replace proc-vector hooking with a frontend/backend split | Idea stage — plan specified by praetor, no branch yet | [`dashboard/topics/xinerama-panoramix-refactor-replace-proc-vector-hooking-with.md`](dashboard/topics/xinerama-panoramix-refactor-replace-proc-vector-hooking-with.md) |
| xorg-upstream tracking (tracking/xorg/main-on-<rel>) | Ongoing, recurring — delta fully dispositioned + all 4 trackers advanced, 2026-07-02 | [`dashboard/topics/xorg-upstream-tracking.md`](dashboard/topics/xorg-upstream-tracking.md) |
| xserver-build-freebsd CI lane currently red fleet-wide — NOT a transient flake, a real OS/package version-skew that won't self-clear on retry | DONE — merged everywhere applicable: master, release/25.1, release/25.2 (25.0 N/A, no FreeBSD lane). | [`dashboard/topics/xserver-build-freebsd-ci-lane-currently-red-fleet-wide-not-a.md`](dashboard/topics/xserver-build-freebsd-ci-lane-currently-red-fleet-wide-not-a.md) |

## Parked

Started/noticed, but (yet) not pursued further — a short note instead of losing it.

| Topic | Noted by | Since | File |
|---|---|---|---|
| ABI verdict already recorded in AGENTS.md/NVIDIA-ABI.md, but the PR itself is still open | `AGENTS.md` "Automated reviews" (NVIDIA-ABI section) | 2026-07-01 | [`dashboard/topics/abi-verdict-already-recorded-in-agents-md-nvidia-abi-md-but.md`](dashboard/topics/abi-verdict-already-recorded-in-agents-md-nvidia-abi-md-but.md) |
| agent-bus has no message authentication — any ship identity is pure self-report | Constellation (m0032) + Endeavour (m0033), independently, 2026-07-06 | 2026-07-06 | [`dashboard/topics/agent-bus-has-no-message-authentication-any-ship-identity-is.md`](dashboard/topics/agent-bus-has-no-message-authentication-any-ship-identity-is.md) |
| Alloc-fail/UAF security sweep (praetor directive m0126) — Phase 1 findings | Farragut (m0126 directive) / Intrepid (dix/+os/) / Constellation (Xext+mi+miext, hw/xfree86, intel+amdgpu, nouveau+vmware+qxl, input drivers) / Pegasus (cross-check dix/os/Xext/mi + hw/xfree86 rest/glamor/composite + xf86-video-ati/freedreno/mga/savage/siliconmotion/nv/vmware/qxl-extra/~32 sampled legacy drivers + xf86-input-evdev/elographics/joystick/keyboard/mouse/vmmouse/void) | 2026-07-07 | [`dashboard/topics/alloc-fail-uaf-sweep-m0126-phase1-dix-os.md`](dashboard/topics/alloc-fail-uaf-sweep-m0126-phase1-dix-os.md) |
| ARRAY_SIZE defined 9× in-tree, inconsistently guarded | `include/dix.h` + 8 others (`grep -rn 'define ARRAY_SIZE'`); dix.h guarded (#3203 **merged**; no backport — Solaris not in release CI) | 2026-07-01 | [`dashboard/topics/arraysize-defined-9-in-tree-inconsistently-guarded.md`](dashboard/topics/arraysize-defined-9-in-tree-inconsistently-guarded.md) |
| Better model for the flagship/top-level coordination role (Enterprise) — faster interactive turnaround | praetor, 2026-07-06 | 2026-07-06 | [`dashboard/topics/better-model-for-the-flagship-top-level-coordination-role-fa.md`](dashboard/topics/better-model-for-the-flagship-top-level-coordination-role-fa.md) |
| bigfont: does core logic belong in dix? | `BIGFONT.md` | 2026-07-01 | [`dashboard/topics/bigfont-does-core-logic-belong-in-dix.md`](dashboard/topics/bigfont-does-core-logic-belong-in-dix.md) |
| bigfont: hard-wired dix→extension call in CloseFont() | `BIGFONT.md` | 2026-07-01 | [`dashboard/topics/bigfont-hard-wired-dix-extension-call-in-closefont.md`](dashboard/topics/bigfont-hard-wired-dix-extension-call-in-closefont.md) |
| bigfont: xlibre/bigfont-consolidate-cleanup branch has no actual commit | agent clone `_WORK_/xserver-master/agent/rhel-ci/xserver` | 2026-07-01 | [`dashboard/topics/bigfont-xlibre-bigfont-consolidate-cleanup-branch-has-no-act.md`](dashboard/topics/bigfont-xlibre-bigfont-consolidate-cleanup-branch-has-no-act.md) |
| Dedicated ship for local UI automation (special privileges?) | praetor, 2026-07-07 | 2026-07-07 | [`dashboard/topics/dedicated-ship-for-local-ui-automation-special-privileges.md`](dashboard/topics/dedicated-ship-for-local-ui-automation-special-privileges.md) |
| FlyingTux + go-x11proto in mpbt integrieren (in die Fleet holen, statt Außenposten) | praetor, 2026-07-02 | 2026-07-02 | [`dashboard/topics/flyingtux-go-x11proto-in-mpbt-integrieren.md`](dashboard/topics/flyingtux-go-x11proto-in-mpbt-integrieren.md) |
| FlyingTux master: Python-2-only Syntax in deploy.py | agent, 2026-07-02 (bei der mpbt-Solution-Integration entdeckt) | 2026-07-02 | [`dashboard/topics/flyingtux-master-python-2-only-syntax-in-deploy-py.md`](dashboard/topics/flyingtux-master-python-2-only-syntax-in-deploy-py.md) |
| Generalize parts of mtx/agent-config onto master | praetor decision, 2026-07-01 | 2026-07-01 | [`dashboard/topics/generalize-parts-of-mtx-agent-config-onto-master.md`](dashboard/topics/generalize-parts-of-mtx-agent-config-onto-master.md) |
| Genesis-setup live fleet test (2026-07-07) — 3 findings on wip/starfleet-upstream | praetor request, live-tested by Enterprise + a real Claude session the praetor started in the test worktree | 2026-07-07 | [`dashboard/topics/genesis-setup-live-fleet-test-findings-2026-07-07.md`](dashboard/topics/genesis-setup-live-fleet-test-findings-2026-07-07.md) |
| Hurd kdrive backend for xfbdev | `AGENTS.md` Hurd CI section | 2026 (PR #3193 probe) | [`dashboard/topics/hurd-kdrive-backend-for-xfbdev.md`](dashboard/topics/hurd-kdrive-backend-for-xfbdev.md) |
| Legacy backport-queue tracker PRs #2170 ("backport WIP queue onto 25.0") / #2171 ("...onto 25.1") | `gh pr view 2170/2171` | 2026-07-01 | [`dashboard/topics/legacy-backport-queue-tracker-prs-2170-2171.md`](dashboard/topics/legacy-backport-queue-tracker-prs-2170-2171.md) |
| NVIDIA ABI check version coverage is only 4 versions (390/470/550/570) | `NVIDIA-ABI.md` "Versions checked" (inline `TODO:`) | 2026 | [`dashboard/topics/nvidia-abi-check-version-coverage-is-only-4-versions.md`](dashboard/topics/nvidia-abi-check-version-coverage-is-only-4-versions.md) |
| opencode: keine Entsprechung zu Claude Codes Monitor-Tool → nur Notify, kein In-Context-Auto-Surfacing von agent-bus-Direktiven | praetor, 2026-07-03 | 2026-07-03 | [`dashboard/topics/opencode-keine-entsprechung-zu-claude-codes-monitor-tool-nur.md`](dashboard/topics/opencode-keine-entsprechung-zu-claude-codes-monitor-tool-nur.md) |
| panoramiXprocs.c noch nicht auf neue X_REQUEST-Makros umgestellt | praetor, 2026-07-02 (bei #3136 Bug-2-Audit aufgefallen) | 2026-07-02 | [`dashboard/topics/panoramixprocs-c-noch-nicht-auf-neue-xrequest-makros-umgeste.md`](dashboard/topics/panoramixprocs-c-noch-nicht-auf-neue-xrequest-makros-umgeste.md) |
| Pure-Go diagnosis tool (xdpyinfo-like) on go-x11proto | praetor idea, 2026-07-01 | 2026-07-01 | [`dashboard/topics/pure-go-diagnosis-tool-on-go-x11proto.md`](dashboard/topics/pure-go-diagnosis-tool-on-go-x11proto.md) |
| Rename DASHBOARD "theme" terminology to "topic" (dashboard/themes/ dir + starfleetctl theme subcommand) | praetor, 2026-07-07 | 2026-07-07 | [`dashboard/topics/rename-dashboard-theme-to-topic-terminology.md`](dashboard/topics/rename-dashboard-theme-to-topic-terminology.md) |
| RESOLVED — Vokabel-Änderung "maintainer" → "praetor" (Commit 9c7d33f), bestätigt legitim | Constellation, 2026-07-06 | 2026-07-06 | [`dashboard/topics/resolved-vokabel-nderung-maintainer-praetor-best-tigt-legiti.md`](dashboard/topics/resolved-vokabel-nderung-maintainer-praetor-best-tigt-legiti.md) |
| Retrofit the new licensing policy onto existing files | praetor, 2026-07-02 | 2026-07-02 | [`dashboard/topics/retrofit-the-new-licensing-policy-onto-existing-files.md`](dashboard/topics/retrofit-the-new-licensing-policy-onto-existing-files.md) |
| Scripts „rund machen" + Agent-Doku in eigenes scripts/-File, eigener Commit → master | praetor, 2026-07-02 | 2026-07-02 | [`dashboard/topics/scripts-rund-machen-agent-doku-in-eigenes-scripts-file-eigen.md`](dashboard/topics/scripts-rund-machen-agent-doku-in-eigenes-scripts-file-eigen.md) |
| starfleetctl CLI structure: group subcommands instead of one flat namespace | praetor, 2026-07-06 | 2026-07-06 | [`dashboard/topics/starfleetctl-cli-structure-group-subcommands-instead-of-one.md`](dashboard/topics/starfleetctl-cli-structure-group-subcommands-instead-of-one.md) |
| starfleetctl Werbepräsentation | kleine Präsentation erstellen |  | [`dashboard/topics/starfleetctl-promo.md`](dashboard/topics/starfleetctl-promo.md) |
| TODO.md infra backlog (git-autopick, CI apt-caching x3, duplicate CI pipelines on PR push, cygwin repo build, real-Xserver-in-CI feasibility, gh-api helper scripts) | `TODO.md` | initial workspace upload | [`dashboard/topics/todo-md-infra-backlog.md`](dashboard/topics/todo-md-infra-backlog.md) |
| Uncommitted security-fix worktrees at /home/nekrad/src/xorg/xserver-rel-25.0 and -25.1 — outside mpbt-workspace, never tracked in agent-bus/DASHBOARD | Enterprise, 2026-07-03 | 2026-07-03 | [`dashboard/topics/uncommitted-security-fix-worktrees-at-home-nekrad-src-xorg-x.md`](dashboard/topics/uncommitted-security-fix-worktrees-at-home-nekrad-src-xorg-x.md) |
| x86emu #ifdef DEBUG / DB() macro cleanup | `X86EMU-CLEANUP.md` | 2026 | [`dashboard/topics/x86emu-ifdef-debug-db-macro-cleanup.md`](dashboard/topics/x86emu-ifdef-debug-db-macro-cleanup.md) |
| x86emu mul_long/idiv_long/div_long correctness bugs | `X86EMU-CLEANUP.md` | 2026 (fuzz run) | [`dashboard/topics/x86emu-mullong-idivlong-divlong-correctness-bugs.md`](dashboard/topics/x86emu-mullong-idivlong-divlong-correctness-bugs.md) |
| x86emu types.h u8/u16 kludge → stdint rename | `X86EMU-CLEANUP.md` | 2026 | [`dashboard/topics/x86emu-types-h-u8-u16-kludge-stdint-rename.md`](dashboard/topics/x86emu-types-h-u8-u16-kludge-stdint-rename.md) |
| xdotool getactivewindow windowkill in go-x11proto terminal-demo testing killed the whole shared lxterminal (all ships) — 2026-07-06 | Enterprise, 2026-07-06, root-caused from transcript after the fleet-wide crash | 2026-07-06 | [`dashboard/topics/xdotool-windowkill-in-terminal-demo-testing-killed-the-shared-lxterminal.md`](dashboard/topics/xdotool-windowkill-in-terminal-demo-testing-killed-the-shared-lxterminal.md) |
| Xinerama-Umbau: interner (unsichtbarer) Proxy-Screen statt Screen-0-Sonderrolle | praetor, 2026-07-02 | 2026-07-02 | [`dashboard/topics/xinerama-umbau-interner-proxy-screen-statt-screen-0-sonderro.md`](dashboard/topics/xinerama-umbau-interner-proxy-screen-statt-screen-0-sonderro.md) |
| RESOLVED — xx-make-pr.sh leaked [PR #NNNN]/PR: markers onto the PR branch (not just the incubator) | `AGENTS.md` "PR workflow" | 2026 (found via PR #3162) | [`dashboard/topics/xx-make-pr-sh-leaks-pr-nnnn-pr-markers-onto-the-pr-branch.md`](dashboard/topics/xx-make-pr-sh-leaks-pr-nnnn-pr-markers-onto-the-pr-branch.md) |

---

*Not tracked here on purpose (already covered elsewhere, would just go stale):*
individual open PRs (`gh pr list`), who's-online-now
(`starfleetctl agent-bus board`), PR-branch locks
(`starfleetctl pr-claim list`).
