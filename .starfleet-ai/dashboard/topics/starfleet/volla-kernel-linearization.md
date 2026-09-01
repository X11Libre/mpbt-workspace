---
Title: Volla Kernel Linearization Analysis & Progress
Status: In Progress
Category: starfleet
Created: 2026-08-09
Updated: 2026-08-09
Assigned-To: Barcley
Noted-By: McKinley
---

## Volla Tablet Kernel (mt8781) - Linearization auf v5.10.264 LTS

### Ausgangslage
- **Volla Repo**: HelloVolla/android_kernel_volla_mt8781 (Branches: volla-14.0, volla-15.0)
- **Kernel-Basis**: Linux 5.10.198 (android12-5.10, Android 12 GKI Basis)
- **Ziel**: Linearisierung auf **v5.10.264** (aktueller LTS von gregkh)
- **Merge-Base**: 951358a824f9 (Linux 5.10.43)

### Repo-Struktur (4 Remotes in mpbt)
1. **origin** - Volla/HelloVolla (volla-14.0, volla-15.0)
2. **linux** - Torvalds mainline (master)
3. **lts** - gregkh stable/linux.git (alle v5.10.y tags + branches)
4. **mediatek** - mediatek/linux.git (MediaTek BSP, for-next/master/v6.x-next)

### Analyse der Merge-History
```
Gesamt-Commits seit v5.10.43: ~24.676 (inkl. Merges)
Davon Non-Merge: ~18.510
Davon MediaTek/Volla-spezifisch: ~14.016 (grep mimir|volla|mtk|mt8781|mt6789)
```

### Merge-Pattern (chronologisch)
- **Frühphase** (2021): Android12-5.10 initial merges + 5.10.x point releases
- **Mittelphase** (2022-2023): Monatliche android12-5.10-YYYY-MM R merges + f2fs stable merges
- **Spätphase** (2023-11): Letzter android12-5.10-2023-11 R2 merge
- **Volla-Overlay** (2024-01): volla-15.0 branch mit VollaOS 15.0.0 sync

### Letzte Merge-Kette (Top-down) - ANALYSIERTE MERGES
```
416e6ea75947 (2024-10) [ALPS06206369]
  ├── e37e67995d93 (alps-mp-s0.mp1) ← 29 non-merge commits von android12-5.10 side
  └── de7ca5e75239 (android12-5.10) ← 29 Commits (UPSTREAM/BACKPORT/FROMLIST + ABI updates)

af75b823261d (2023-09) [ALPS06165713]
  ├── cc0ab9a19233 (alps-mp-s0.mp1)
  └── 6c3417436a6f (android12-5.10) ← 16 Commits (UPSTREAM + vendor hooks + GKI symbols)

1b48b46a7284 (2023-08) [ALPS06137371]
  ├── 1f12c642e160 (alps-mp-s0.mp1)
  └── 94fbab9d6c82 (android12-5.10) ← 32 Commits (UPSTREAM + GKI symbols i.MX/xiaomi)

... (weitere 20+ ALPS merges zurück bis 5.10.3)
```

### Volla-spezifische Dateien (Delta 951358a824f9 → volla-15.0-baseline)
**Kernbereiche:**
- `arch/arm64/boot/dts/mediatek/` - **ALLE dtb/dts für mt6789/tb8781/M100*/M101*** (~200+ files)
- `arch/arm64/configs/mimir.config` - Kernel config
- `drivers/gpu/mediatek/` - **GPU GED driver** (~80+ files)
- `drivers/misc/mediatek/` - DWS, connectivity, met modules
- `Documentation/devicetree/bindings/mediatek/` - DT bindings
- `Documentation/devicetree/bindings/soc/mediatek/` - dvfsrc, pwrap, scpsys
- `drivers/staging/android/ion/` - Android ion (partially)

### ERKENNTNISSE
1. **Android-Common (android12-5.10)** Commits sind meist UPSTREAM/BACKPORT/FROMLIST → **bereits in v5.10.264 enthalten**
2. **MediaTek BSP (ALPS)** merget android12-5.10 regelmäßig → **redundant**
3. **Echter Volla-Delta** = MediaTek-spezifische Treiber + DTS + Config
4. **Rebase-Ansatz gescheitert** wegen Konflikte in gemeinsamen Android-Common Bereichen

### NEUER ANSATZ (per McKinley): File-level Cherry-pick
Statt History-rebase: **Nur Volla-spezifische Dateien als Patches extrahieren** und auf v5.10.264 anwenden.

**Ziel-Dateien (manuell gepflegte Liste):**
```
arch/arm64/boot/dts/mediatek/          ← DTS (Board: tb8781p1, M100*, M101*)
arch/arm64/configs/mimir.config        ← Config
drivers/gpu/mediatek/                  ← GED GPU driver
drivers/misc/mediatek/                 ← DWS, connectivity, met
Documentation/devicetree/bindings/mediatek/
Documentation/devicetree/bindings/soc/mediatek/
```

### Aktueller Status
- Branch `linearize-volla-15.0` auf `lts/v5.10.264` zurückgesetzt
- Tag `volla-15.0-baseline` = ursprünglicher Volla 15.0 HEAD
- Tag `linearize-start` = Start Linearisation
- Liste Volla-spezifischer Commits: `/tmp/volla-mediatek-specific.txt` (14.016)

### Nächste Schritte
1. **Patches extrahieren**: `git diff 951358a824f9..volla-15.0-baseline -- <dateien>` für jede Ziel-Gruppe
2. **Patches bereinigen**: Android-Common Teile (Makefile clang, GKI, abi_gki) entfernen
3. **Auf v5.10.264 anwenden**: `git am` oder `patch -p1`
4. **Validieren**: `git diff HEAD volla-15.0-baseline -- <dateien>` → sollte leer sein

### Tags für Referenz
- `volla-15.0-baseline` - Original Volla 15.0 HEAD
- `linearize-start` - Start Linearisation
- `lts/v5.10.264` - Ziel-Basis (acccef89f184)
- `951358a824f9` - Merge-base (v5.10.43)

