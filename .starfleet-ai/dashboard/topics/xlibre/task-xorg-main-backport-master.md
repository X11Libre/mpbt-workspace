Title: "xorg/main Backport für master (Phase II/III)"
Category: xlibre
Kind: task
Status: "assigned"
Created-By: "Voyager"
Created: "2026-09-29T07:21:08Z"
Assigned-To: "Voyager"
Doc-Ref: "—"
Slug: xlibre/task-xorg-main-backport-master

Backport der xorg/main-Commits auf den XLibre master, Workflow backport-xorg-main. Stand 2026-09-28: Tracker 867976ba87, xorg/main b125b19fc2, Rückstand 33 Commits. Phase I (Incubator rfc/backport-master auf master rebased + force-with-lease, bf611d4ff1) erledigt. Auslassungen: 6 xwayland (XWL) + 1 glamor-DUP (316321933a, abgedeckt durch PR 3750) — dokumentiert in agents.d/xlibre/xorg-main-backport-exclusions.md. Diagnose der 26 Kandidaten: 17 clean / 9 Konflikte (ABI-Bumps, Xi, meson, modesetting, fallthrough). WARTET auf Praetor-Entscheidung via Entscheidungsreport, dann Phase III (einzeln einreichen, Konflikte je im PR-Review lösen).
