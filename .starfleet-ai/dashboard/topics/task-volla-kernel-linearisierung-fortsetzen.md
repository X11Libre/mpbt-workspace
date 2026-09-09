---
title: "Volla kernel linearisierung fortsetzen"
category: active
kind: task
status: assigned
assigned-to: "Wurst"
created-by: "McKinley"
created: 2026-08-10T18:08:22Z
doc-ref: "—"
updated: 2026-09-09
noted-by: "Enterprise"
---

## Verweis

Ablauf, Regeln, Verbotenes und Resilienz: **Skill `android-kernel-rebase`**
laden (`.claude/skills/android-kernel-rebase/SKILL.md`). Dieses Topic ist der
Auftrag; der Skill ist die Arbeitsanweisung.

## Analyse-Hintergrund (aus Topic starfleet/volla-kernel-linearization)

- **Repo:** HelloVolla/android_kernel_volla_mt8781 (Branches volla-14.0,
  volla-15.0); Kernel-Basis Linux 5.10.198 (android12-5.10); Merge-Base
  951358a824f9 (v5.10.43).
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
  UPSTREAM/BACKPORT/FROMLIST → großteils schon in v5.10.264 enthalten;
  MediaTek-ALPS merget android12-5.10 regelmäßig → redundant. Echter
  Volla-Delta = MediaTek-Treiber + DTS + Config.
- **Referenz-Tags:** volla-15.0-baseline (Original-Volla HEAD), linearize-start,
  linearize-done-v1, lts/v5.10.264 (Ziel-Basis acccef89f184), 951358a824f9
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

2. Schrittweises Rebase auf die Mainline-ZWISCHENSTANDS-Basen
   (PRÄZISIERT 2026-09-04 durch Praetor). Ziel: final auf v5.10.264 (LTS-Tree).
   Das läuft SCHRITT FÜR SCHRITT, ein Mainline-Release nach dem anderen.
   Ablauf je Release:
   1. Rebase auf dem aktuellen Mainline-Tag abschließen.
   2. Tree-Abgleich mit dem Original-Volla-Tree (volla-15.0-baseline); ggf.
      Angleichs-Commit, damit beide Trees identisch sind.
   3. NEUEN Branch abzweigen (step-Nummer erhöhen).
   4. Auf den nächsten Mainline-Tag rebasen: 5.6.0 → 5.7.0 → … → 5.10.0,
      dann innerhalb 5.10.y weiter bis v5.10.264.
   WICHTIG: NICHT auf neuere Versionen als die aktuelle Basis hochgehen
   (kein Mainline 6.x) — nur linearisieren und auf dem jeweiligen Mainline-Tag
   basieren. Endzustand: Branch basierend auf dem v5.10.264-Tag (LTS),
   oberhalb dessen alles linear ist.

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

## Aktueller Live-Stand (2026-09-09)

- Rebase-Run stand auf `wip/linearize-volla-15.0-step33` (5.5.0-Basis).
- Vorheriger Agent hat bei NIM-Rate-Limit `git rebase --abort` ausgeführt,
  auf step33 zurückgesetzt und aufgegeben — das ist das FEHLVERHALTEN, das der
  Skill verhindert. Kein `.git/rebase-merge` mehr vorhanden; Backup-Branch
  `backup-rebase-progress` existiert.
- Schritt-Branches `linearize-volla-15.0-step1..step33` vorhanden.
- Makelfile-Ziel des Original-Trees (volla-15.0): 5.10.198; Endziel-LTS laut
  Praetor-Präzisierung: v5.10.264.