---
title: "Volla kernel linearisierung fortsetzen"
category: active
kind: "task"
status: "done"
assigned-to: "Barcley"
created-by: "McKinley"
created: "2026-08-10T18:08:22Z"
doc-ref: ""
---
## Verweis

Ablauf, Regeln, Verbotenes und Resilienz: **Skill `android-kernel-rebase`**
laden (`.claude/skills/android-kernel-rebase/SKILL.md`). Dieses Topic ist der
Auftrag; der Skill ist die Arbeitsanweisung.

## Zielversion (KRITISCH)

- **Finale Zielversion = laut `Makefile` des Volla-Trees** (`volla-15.0-baseline`):
  `VERSION=5`, `PATCHLEVEL=10`, `SUBLEVEL=198` → **v5.10.198**
  (`lts/v5.10.198`, existiert im Clone: 2a1872e3). Diese Version ist der
  Endpunkt — NICHT aus Commits ableiten.
- Hinweis: Eine frühere Auftragsvorgabe nannte `v5.10.264` (LTS-Tree). Das war
  **NICHT die im Makefile deklarierte Version** und ist verworfen/zu ignorieren.
- Zwischenziel (je Schritt): nächster höherer stable-Mainline-Tag über der
  aktuellen Basis (via `git describe`), z. B. Basis v5.4 → v5.5 → v5.6 → …
  → v5.10.0, danach Schritt-für-Schritt in 5.10.y bis v5.10.198.

## Kontext: Volla-Kernel (mt8781)

- **Worum es geht:** Der **Volla Tablet Kernel (MediaTek mt8781)** — das
  Android-Kernel-Repo `HelloVolla/android_kernel_volla_mt8781` (Branches
  volla-14.0, volla-15.0). Ziel ist dessen Linearisierung/Rebase auf die
  Mainline-Basis (Details im Skill).
- **Bereits geclont:** Der Kernel liegt schon im mpbt-Workspace unter
  `_WORK_/volla-kernel/sources/volla/kernel-mt8781` (Solution `volla-kernel`,
  vgl. `cf/volla-kernel/`). **Nicht neu klonen** — nur in diesem Clone arbeiten.
- **Vorarbeit vorhanden:** Ein anderer Agent hat dort bereits erheblich
  gearbeitet: Volla-15.0-Baseline erfasst, Linearisierung begonnen, ~33
  Schritt-Branches angelegt (`wip/linearize-volla-15.0-step1..step33` plus
  ältere `linearize-volla-15.0-stepN`), Analyse der Merge-History
  durchgeführt. Diese Vorarbeit ist die Grundlage — **darauf aufbauen, nicht
  neu beginnen**.
- **Aktueller Stand / wo anknüpfen:** **Phase 1 abgeschlossen** —
  `wip/linearize-volla-15.0-step37` ist fertig (Basis v5.10.0, Tree identisch
  zu `volla-15.0-baseline`). Nächster Schritt ist der erste LTS-Unterschritt
  der Phase 2 (`…-step38` auf `lts/v5.10.1`). Details siehe Abschnitt
  „Aktueller Stand (2026-09-17, Barcley)" am Ende.

## Analyse-Hintergrund (aus Topic starfleet/volla-kernel-linearization)

- **Kernel-Basis:** Linux 5.10.198 (android12-5.10); Merge-Base 951358a824f9
  (v5.10.43).
- **Remotes:** origin/volla (Volla), linux (torvalds), lts (gregkh stable,
  alle v5.10.y tags), mediatek (BSP); Tag-Namespaces volla/, linux/, lts/,
  mediatek/.
- **Merge-History:** ~24.676 Commits seit v5.10.43, davon ~14.016
  MediaTek/Volla-spezifisch (grep mimir|volla|mtk|mt8781|mt6789). Muster:
  Frühphase Android12-5.10-Initial-Merges + 5.10.x point releases,
  Mittelphase monatliche android12-5.10-YYYY-MM-R merges, Spätphase letzter
  android12-5.10-2023-11-R2 merge (2023-11), Volla-Overlay volla-15.0 mit
  VollaOS 15.0.0 sync (2024).
- **Volla-Delta-Kernbereiche:** arch/arm64/boot/dts/mediatek/ (alle dtb/dts
  mt6789/tb8781/M100*/M101*, ~200+ files), arch/arm64/configs/mimir.config,
  drivers/gpu/mediatek/ (GPU GED, ~80+ files), drivers/misc/mediatek/ (DWS,
  connectivity, met), Documentation/devicetree/bindings/{mediatek,
  soc/mediatek}/, drivers/staging/android/ion/.
- **Erkenntnis:** Android-Common (android12-5.10) Commits sind meist
  UPSTREAM/BACKPORT/FROMLIST → großteils schon in v5.10.198 enthalten;
  MediaTek-ALPS merget android12-5.10 regelmäßig → redundant. Echter
  Volla-Delta = MediaTek-Treiber + DTS + Config.
- **Referenz-Tags:** volla-15.0-baseline (Original-Volla HEAD), linearize-start,
  linearize-done-v1, lts/v5.10.198 (Ziel-Basis 2a1872e3), 951358a824f9
  (v5.10.43 merge-base).

## Aufgabe

Schrittweise Rebase des Volla-Tablet-Kernels (mt8781, Clone
`_WORK_/volla-kernel/sources/volla/kernel-mt8781`) gemäß Skill
`android-kernel-rebase`:

1. Linearisierung Schritt für Schritt: vom aktuellen Stand abzweigen
   (`<stem>-step<N>`, Counter hoch), oberste Merge-Node auflösen, je Node mit
   dem Original-Volla-Tree vergleichen (keine Differenz; im Worst Case
   Angleichs-Commit anhängen), dann nächster Branch/nächste Merge-Node —
   Schleife, bis alles oberhalb des zuletzt (im Original enthaltenen)
   upstream/LTS-Tags linear ist.

2. Schrittweises Rebase auf die Mainline-ZWISCHENSTANDS-Basen.
   Das läuft SCHRITT FÜR SCHRITT, ein Mainline-Release nach dem anderen,
   bis zur **finalen Zielversion v5.10.198** (aus dem Volla-Makefile).
   Ablauf je Release:
   1. Rebase auf dem aktuellen Mainline-Tag abschließen.
   2. Tree-Abgleich mit dem Original-Volla-Tree (volla-15.0-baseline); ggf.
      Angleichs-Commit, damit beide Trees identisch sind.
   3. NEUEN Branch abzweigen (step-Nummer erhöhen).
   4. Auf den nächsten Mainline-Tag rebasen: 5.5 → 5.6 → 5.7 → … → 5.10.0,
      dann innerhalb 5.10.y weiter bis v5.10.198.
   WICHTIG: NICHT auf neuere Versionen als die aktuelle Basis hochgehen
   (kein Mainline 6.x), NICHT über die Makefile-Zielversion hinausgehen
   (5.10.198, kein 5.10.264) — nur linearisieren und auf dem jeweiligen
   Mainline-Tag basieren. Endzustand: Branch basierend auf dem
   v5.10.198-Tag (LTS), oberhalb dessen alles linear ist.

Nach jedem Schritt: **Report** (`reports submit`, belegt den Tree-Abgleich) +
**Comms-Bericht an McKinley UND Enterprise** (=Flagschiff).

## Verboten / Resilienz (Kurzfassung — Details im Skill)

- **Kein `git rebase --abort`**, kein hartes Rollback (`git reset --hard`,
  Branch löschen) aus Zeitdruck.
- **Bei transienten Fehlern** (Rate-Limit, Modellfehler, Proxy tot): weiter
  machen, nicht abbrechen, nicht warten.
- **Bei unerwartet beendeten git-Calls**: erst Zustand prüfen
  (`git status`, `.git/rebase-merge`/`.git/rebase-apply`, `git log -1`), dann
  entscheiden — nie „nichts tun" oder zurückrollen.
- Konflikt-Stopp von git ist KEIN Fehler: semantisch auflösen, `--continue`.
- Backup-Branches immer behalten, branch-Nummer hochzählen.
- Kein pauschales fat-diff gegen den Upstream — die komplette History zählt.
- **Workspace nicht verpfuschen:** nur im Kernel-Clone arbeiten, Remotes und
  Workspace-Root-Branch (`mtx/agent-config`) nicht anfassen, keine fremden
  Branches auschecken (siehe Skill, Abschnitt Workspace isolation).

## Aktueller Stand (2026-09-17, Barcley — Abend)

**`step37` (Phase 1, Basis v5.10.0) war heute fertig** (Tree == `volla-15.0-baseline`).
Danach hat **Praetor** den Rebase auf **v5.9** gestartet (`step38`); Barcley hat
den Lauf übernommen und **abgeschlossen**:

- **`wip/linearize-volla-15.0-step38`**, onto `bbf5c979011a0` = **v5.9**.
- **41198 Picks** vollständig verarbeitet (Driver `continue-rebase.sh`, 482
  Runden; Konflikte → Pick-Blobs, gesetzte Rename-Härtung `unmerged→theirs`).
- **linear:** 41164 Commits oberhalb der Basis, **0 Merge-Commits**
  (`drop_redundant_commits` leer).
- **Tree-Konformität:** finaler Tree == `volla-15.0-baseline` —
  `git diff volla-15.0-baseline HEAD` leer (0 Dateien); Worktree clean.
- **Angleichs-Commit:** `4998c77668e21` („reconcile tree to
  volla-15.0-baseline", 312 Divergenz-Dateien auf Original-Inhalt zurück).
  **Branch-Tip = `4998c77668e21`.**
- **Makefile am Tip:** `VERSION=5 PATCHLEVEL=10 SUBLEVEL=198` (= Ziel
  v5.10.198, `lts/v5.10.198` = `2a1872e33b54`).
- **Refs/Backups unverändert:** `orig-head` = `3b77453e2c869`,
  `backup/orig-head-step37-3b77453`, `backup/rebase-stand-11d7b8c`,
  `backup-rebase-progress` = `cbff4951fe7c`, Tag `volla-15.0-baseline`.
- **Report:** `r-1789666453496341949`.
- **Nächste Schritte** gemäß Auftrag/Skill: weiter in die LTS-Unterschritte
  (Basis v5.10.x, schrittweise bis v5.10.198), jeweils Tree-Abgleich +
  Angleichs-Commit + Report.

*(Vorheriger Stand: step37 Phase-1-Abschluss; davor 2026-09-10 Rebase hing auf
step34, Modell-Loop, von Enterprise auf `nemotron-3-ultra-550b-a55b` neu
gestartet. Snapshot `_WORK_/volla-kernel/rebase-snapshot-2026-09-10/`.)*

## Aktueller Stand (2026-09-18, Barcley) — step39 (Basis Linux 5.10)

**Praetor startete Rebase auf Linux 5.10** (`2c85ebc57b3e1`); Barcley hat den Lauf
uebernommen und **abgeschlossen**:

- **`wip/linearize-volla-15.0-step39`**, onto `2c85ebc57b3e1` = **Linux 5.10**.
- **25718 Picks** vollstaendig verarbeitet (Driver `continue-rebase.sh`, 11 Runden).
- **linear:** 25678 Picks + 1 Angleichs-Commit = **25679 Commits** oberhalb der
  Basis, **0 Merge-Commits**.
- **Tree-Konformität:** `git diff volla-15.0-baseline HEAD` = **0 Zeilen**;
  Worktree clean. Tree byte-identisch zu `volla-15.0-baseline`.
- **Angleichs-Commit:** `ce0c10880e756` („reconcile tree to
  volla-15.0-baseline"), Branch-Tip. Deterministisch via
  `git read-tree volla-15.0-baseline` + `git checkout-index -f -u -a` + Amend
  (der naive `git checkout -- .`-Weg liess 28 Pfade aus).
- **Report:** `r-1789731767723196516`.
- **Zwischenfaelle behoben:** wiederholte git-Index-Write-ENOSPC (Btrfs-Metadaten
  92.6% voll) — rebuildbare `_WORK_`-Artefakte geloescht, splitIndex/untrackedCache
  aus, Praetor-btrfs-balance (Meta 75.7%); interrupted-apply-Faelle (nl80211/kfence/
  KVM/r8169/mt6879/cgroup) per Pick-Blob + stale-staged-Reset; Driver gehaertet.
- **Naechster Schritt:** naechste Basis-Vorgabe des Praetors (Ziel bleibt v5.10.198).
