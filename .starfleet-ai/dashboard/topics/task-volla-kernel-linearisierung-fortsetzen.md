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

1. Schrittweise Linearisierung fortsetzen: Basis ist der letzte Stand
   `wip/linearize-volla-15.0-step32`. Zweig von dort ab (`.step33…` usw.),
   jeweils die oberste Merge-Node auflösen. Nach jeder aufgelösten Merge-Node
   mit dem volla-tree vergleichen (keine Differenz mehr; im Worst Case einen
   Extra-Commit anhängen, der den Tree wieder ans Original angleicht). Dann
   nächste Branch und nächste Merge-Node — Schleife bis alles oberhalb des
   zuletzt (im Original enthaltenen) upstream/LTS-Tags linear ist.

2. Schrittweises Rebase auf aktuelle mainline releases: für jede release-base
   neue Branch abzweigen und rebasen, Konflikte auflösen, caret-Vergleich
   (Differenz vor/nach Rebase gleich). Von Release zu Release hocharbeiten.

Nach jedem Schritt Report + Bericht an McKinley.

## Aktueller Live-Stand (2026-09-04, von Enterprise festgehalten)

Es steht eine **aktive Rebase-Sitzung im mpbt-Worktree**
(`_WORK_/volla-kernel/sources/volla/kernel-mt8781`) an:
- Mitten in einem Rebase von `wip/linearize-volla-15.0-step32` (HEAD detached,
  Rebase läuft).
- Letzte Commits von heute 2026-09-04 (~16:12): z.B.
  `abe4df1a230c2` "drm/edid: Pass connector to AVI infoframe functions",
  davor phy/Marvell A3700 PHY/COMPHY "support".
- **Unaufgelöster Konflikt:** `UU drivers/gpu/drm/i915/display/intel_dp.c` —
  die Sitzung hängt gerade in der Konflikt-Auflösung.
- Schritt-Branches `linearize-volla-15.0-step1..step32` vorhanden.

Aufgabe des beauftragten Schiffs (Wurst): Diese laufende Rebase-Sitzung
**eigenständig zu Ende führen** — Schritt 33+ fortsetzen, Konflikte
(einschl. des offenen `intel_dp.c`) lösen, Tree-Abgleich, bis die
Linearisierung oberhalb des letzten enthaltenen upstream/LTS-Tags linear ist,
danach (je nach Stand) den Rebase auf aktuelle mainline releases gemäß
Punkt 2 weiterführen. Reports an McKinley und Enterprise.
