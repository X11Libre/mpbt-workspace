Title: "xorg/main Backport für master (Phase II/III)"
Category: xlibre
Kind: "task"
Status: "assigned"
Assigned-To: "Voyager"
Created-By: "Voyager"
Created: "2026-09-29T07:21:08Z"
Doc-Ref: "—"

Backport der xorg/main-Commits auf den XLibre master, Workflow backport-xorg-main. Stand 2026-09-28: Tracker 867976ba87, xorg/main b125b19fc2, Rückstand 33 Commits. Phase I (Incubator rfc/backport-master auf master rebased + force-with-lease, bf611d4ff1) erledigt. Auslassungen: 6 xwayland (XWL) + 1 glamor-DUP (316321933a, abgedeckt durch PR 3750) — dokumentiert in agents.d/xlibre/xorg-main-backport-exclusions.md. Diagnose der 26 Kandidaten: 17 clean / 9 Konflikte (ABI-Bumps, Xi, meson, modesetting, fallthrough). WARTET auf Praetor-Entscheidung via Entscheidungsreport, dann Phase III (einzeln einreichen, Konflikte je im PR-Review lösen).

- 2026-09-29T08:25:03Z Voyager: PHASE II ABGESCHLOSSEN: 22 Commits in Incubator rfc/backport-master gepusht (bf611d4ff1 -> 22b51394ca), force-with-lease, Gebrauch vorher geprueft (kein offener PR). 20 Kandidaten + 2 Reparatur-Commits. TRACKER NICHT hochgezogen (867976ba87) wegen Auslassungs-Regel: erste Auslassung 4371d6d0ee (xwayland) liegt MITTEN in der Kette, nach Kandidat 14981eea44 und vor Kandidaten 3983c7408c/306071c0b9. Regel verbietet Tracker-Hochziehen ueber Auslassungen. Entscheidungspunkt fuer den Praetor. Build-Verifikation: Probe-Build der 22 Commits auf origin/master-Basis (ohne die ungemergten Fremd-PRs XFixes 6.1/test-pyxtest im Incubator) mit -Dwerror=true vollstaendig GRUEN. Die blockierende Fremd-PR 516b44f3f1 (XFixes 6.1, offener PR #3364) verursacht 5 Build-Fehler in disconnect.c, auch auf der unveraenderten Incubator-Basis - bewiesen, nicht von meinem Backport. Zurueckgehalten: bd3ca7da06 (X_FALLTHROUGH) Inhaltskonflikt, 9 Konflikte in InputClass.c (negated vs matchtype), nicht blind loesbar. DUPs beim Aufnehmen erkannt und dokumentiert: 3660f54fbd, 3c62ee0c78, 14981eea44, sowie vorab ecb6644fdd, bbe30db5c0.
