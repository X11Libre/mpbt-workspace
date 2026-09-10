Title: "Volla kernel linearisierung fortsetzen"
Category: active
Kind: "task"
Status: "in-progress"
Assigned-To: "Barcley"
Created-By: "McKinley"
Created: "2026-08-10T18:08:22Z"
Doc-Ref: ""

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
- **Aktueller Stand / wo anknüpfen:** Rebase-Run steht auf
  `wip/linearize-volla-15.0-step33` (Basis 5.4). Ein früherer Agent hat bei
  NIM-Rate-Limit irrtümlich `git rebase --abort` ausgeführt (⟶ FEHLVERHALTEN,
  im Skill verankert); kein `.git/rebase-merge` mehr aktiv. Backup-Branch
  `backup-rebase-progress` vorhanden. Barcley hat inzwischen `step34` abgezweigt
  und rebased auf `linux/v5.5` (aktiver Rebase). Die Arbeit ist an genau der
  Stelle fortzusetzen, an der sie unterbrochen wurde.

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

## Aktueller Stand / Wiederaufnahme (2026-09-10, Enterprise)

**Barcley hing am 2026-09-10 in einer Modell-Repetitions-Loop** (Modell
`nemotron-3-super-120b`, lahmte ~10h) und wurde von Enterprise mit
`nemotron-3-ultra-550b-a55b` neu gestartet. Exakter Fortsetzungszustand:

- **Aktiver Rebase** auf `wip/linearize-volla-15.0-step34`
  (`.git/rebase-merge` vorhanden) — **NICHT zurückrollen**, nur fortsetzen.
- **Fortschritt:** `msgnum`/`end` = **303 / 86186** Commits rebased.
- **HEAD:** `b304ec2a88759 net: aquantia: adding fields and device features
  for vlan offload`
- **Angehalen an:** `969593e39d67e net/mlx5: Support querying max VFs from
  device` — **Conflict** in
  - `drivers/net/ethernet/aquantia/atlantic/aq_nic.c`
  - `drivers/net/ethernet/aquantia/atlantic/hw_atl/hw_atl_b0.c`
- **Conflict-Auflösung war bereits gestaged** (VLAN-offload fields, ~2730
  Diff-Zeilen). Nächstes Kommando: semantische Prüfung des gestagten Stands,
  `git add` falls nötig, dann `git rebase --continue`.
- **Voll-Snapshot 2026-09-10** der Rebase-Metadaten unter
  `_WORK_/volla-kernel/rebase-snapshot-2026-09-10/` (`git-rebase-todo`,
  `done`, `aquantia-staged.diff`) — dient als Referenz/Backup.
