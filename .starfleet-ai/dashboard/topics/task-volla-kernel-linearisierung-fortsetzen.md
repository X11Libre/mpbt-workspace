---
Title: volla kernel linearisierung fortsetzen
Category: active
Kind: task
Status: assigned
Assigned-To: Wurst
Created-By: McKinley
Created: 2026-08-10T18:08:22Z
Doc-Ref: "—"
Updated: 2026-09-04
Noted-By: Enterprise
---

## Aufgabe

1. Jetzt nochmal schrittweise Linearisierung: mein Stand ist
   `linearize-volla-15.0`. Zweig von dort ab (`.stepN…` usw.), jeweils die
   oberste Merge-Node auflösen. Nach jeder aufgelösten Merge-Node mit dem
   volla-tree vergleichen (keine Differenz mehr; im Worst Case einen
   Extra-Commit anhängen, der den Tree wieder ans Original angleicht). Dann
   nächste Branch und nächste Merge-Node — Schleife bis alles oberhalb des
   zuletzt (im Original enthaltenen) upstream/LTS-Tags linear ist.

2. Schrittweises Rebase auf die mainline ZWISCHENSTANDS-basen (PRÄZISIERT
   2026-09-04 durch Praetor): Ziel ist final auf v5.10.264 (LTS-Tree) zu
   rebasen. Das läuft SCHRITT FÜR SCHRITT, ein mainline-Release nach dem
   anderen. Aktueller Stand IST 5.5.0 (d5226fa6dbae0) — das ist der korrekte
   aktuelle Zwischenschritt. Ablauf je Release:
   1. Rebase auf dem aktuellen mainline-Tag abschließen.
   2. Tree-Abgleich mit dem Original-Volla-Tree (volla-15.0-baseline); ggf.
      Angleichs-Commit, damit beide Trees identisch sind.
   3. NEUEN Branch abzweigen (step-Nummer erhöhen).
   4. Auf den nächsten mainline-Tag rebasen: 5.6.0 → 5.7.0 → … → 5.10.0,
      dann innerhalb 5.10.y weiter bis v5.10.264.
   WICHTIG: NICHT auf neuere Versionen als die aktuelle Basis hochgehen
   (kein mainline 6.x) — nur linearisieren und auf dem jeweiligen mainline-Tag
   basieren. Endzustand: Branch basierend auf dem v5.10.264-Tag (LTS),
   oberhalb dessen linear.

Nach jedem Schritt Report + Bericht an McKinley.

## Aktueller Live-Stand (2026-09-04, von Enterprise festgehalten)

Es steht eine **aktive Rebase-Sitzung im mpbt-Worktree**
(`_WORK_/volla-kernel/sources/volla/kernel-mt8781`) an:
- Mitten in einem Rebase von `wip/linearize-volla-15.0-step32` (HEAD detached,
  Rebase läuft auf 5.5.0-Basis d5226fa6dbae0).
- Letzte Commits von heute 2026-09-04 (~16:12): z.B.
  `abe4df1a230c2` "drm/edid: Pass connector to AVI infoframe functions",
  davor phy/Marvell A3700 PHY/COMPHY "support".
- Konflikt `UU drivers/gpu/drm/i915/display/intel_dp.c` (Artefakt der
  5.5.0-Basis — wird als Teil des 5.5.0-Schritts gelöst, der Base ist
  korrekt).
- Schritt-Branches `linearize-volla-15.0-step1..step32` vorhanden.

Aufgabe des beauftragten Schiffs (Wurst): Die laufende Rebase-Sitzung gemäß
der präzisierten Schrittfolge (Punkt 2) **eigenständig zu Ende führen** —
5.5.0 abschließen, dann Release für Release (5.6.0 … 5.10.0 … 5.10.264)
hocharbeiten, je Release Tree-Abgleich + Angleichs-Commit + neuen Branch.
Reports an McKinley und Enterprise.