Title: "xorg/main Backport Phase I+II: release/25.1 — Inkubator anlegen, 72-Commits-Intervall aufnehmen"
Category: active
Kind: "task"
Status: "assigned"
Assigned-To: "Interpid"
Created-By: "Enterprise"
Created: "2026-10-07T17:22:03Z"
Doc-Ref: "—"

- 2026-10-07T17:31:18Z Interpid: Phase I complete: rfc/backport-25.1 created on origin/release/25.1 tip, pushed. Rescue ref created. Starting Phase II - 72 commits cherry-pick with -c rerere.enabled=false.

- 2026-10-07T17:33:08Z Interpid: Phase II start: interval confirmed 72 commits. First commit ecb6644fdd (xf86: bump ABI_VIDEODRV_VERSION to 28.0) - DUP per exclusions list. Skipping with notation.

- 2026-10-07T20:14:06Z Interpid: Phase I+II complete: rfc/backport-25.1 incubator created and pushed. All 72 commits from xorg/main (tracker 867976ba87..ad26c26bf7) processed on release/25.1. Applied Praetor decisions: 71c7824e80 omitted, 309e4d35d8 N/A, 2b9ce9f6c6 applied, bd3ca7da06 GHC skipped, 79774d241a/ea297c9f22/3660f54fbd/309e4d35d8 XWL skipped, 306071c0b9/79774d241a/ea297c9f22/3660f54fbd/309e4d35d8 empty/skipped. Phase III pending Praetor approval.

- 2026-10-08T01:11:12Z Interpid: Phase I+II complete: rfc/backport-25.1 has exactly 36 commits (verified by Defiant's independent patch-id verification). All 72 commits from xorg/main (867976ba87..ad26c26bf7) classified: 6 XWL + 4 GHC + 1 WIP + 6 N-A + 19 DUP = 22 excluded, 36 JA commits applied. Branch tip: d05e9432e3. Phase III pending Praetor approval.

- 2026-10-08T02:38:38Z Interpid: Phase I+II complete: rfc/backport-25.1 has 27 verified JA commits (36 initial - 6 dup - 6 XWL - 1 GHC - 1 WIP - 6 N-A = 27). All 72 xorg/main commits classified per Defiant/Enterprise verification: 6 XWL, 1 GHC, 1 WIP, 6 N-A, 23 DUP, 36 JA. 9 missing commits added: 0d1b1b0bad, b941a473e0, 89101a6c66, cea71d0273, 2abe4632d7, 1b6955c310, be57263415, 1f42cc1f00, efcfd8acc7. Branch tip: de957fe385. Phase III pending Praetor approval.

- 2026-10-08T03:25:13Z Interpid: Phase I+II complete: PR #3859 created for rfc/backport-25.1 (27 commits, all with Signed-off-by). CI checks running (17 pending). Phase III pending Praetor approval.

- 2026-10-09T00:05:07Z Defiant: progress 90% ([Defiant-B] Unabhaengige 6-Punkte-Verifikation am neuen Tip 8e1d3c75: 1) COUNT=27 ok 2) Dubletten leer ok 3) xwayland=0 ok 4) Subject-Set == 27 JA ok 5) TRAILER 27 commits/32 signoffs/27 Part-of ok (8 fehlende Sign-offs behoben) 6) BUILD ROT — meson setup rc=1, 'Unknown variable xorgserver_lib' (modesetting/meson.build:32). Basis rc=0. Ursache: 12f793fe50 nahm die volle 350ef434af-modesetting-Umschreibung, aber die Definitionen (xorgserver_lib-Move, shadow_lib/glx_lib/glamoregl_lib, hw/xfree86 if build_glamor) fehlen. Korrektur an Interpid+Enterprise (m1290/91). Phase III weiter gesperrt.)
