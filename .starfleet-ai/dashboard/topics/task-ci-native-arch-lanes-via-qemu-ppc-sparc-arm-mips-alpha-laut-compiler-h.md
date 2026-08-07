Title: "CI: native Arch-Lanes via QEMU (ppc/sparc/arm/mips/alpha laut compiler.h)"
Category: active
Kind: "task"
Status: "in-progress"
Assigned-To: "Defiant"
Created-By: "Voyager"
Created: "2026-08-06T11:18:44Z"
Doc-Ref: "PR #3491: https://github.com/X11Libre/xserver/pull/3491"

Machbarkeit: nativ (nicht cross) in QEMU bauen. Architekturen, die include/compiler.h referenziert: __alpha__, __amd64__/__i386__/__ia64__, __sparc__, __arm32__, __mips__, __powerpc__ (x86-Bereich schon durch bestehende Lanes abgedeckt). Gewaehlter Ansatz: QEMU-User-Mode (qemu-user-static + binfmt_misc) mit fremdarchigem Debian-Rootfs, nativer Compile + optional Xvfb-Smoke-Test.

## Rebuild auf frischem origin/master (2026-08-07, Defiant)

**Entscheidung (m12822, Enterprise):** eieio-Fix und ioBase-void* werden NICHT in PR #3491 aufgenommen — Enterprise uebernimmt beide arch-korrekt in wip/compiler.h-cleanup (eieio-Fix als eigener PR nach dem Merge von PR #3505 ioBase-void*, der gerade durch CI laeuft). PR #3491 traegt ab jetzt nur die reine CI-Infra.

### Durchgefuehrt
- **Neuer Worktree-Branch `wt/ci-arch-lanes-rebased`** auf frischem origin/master (20d1a1c3d9 "compiler.h: consolidate alpha specific defines") — der alte Branch wt/ci-arch-lanes (a4c7c30379) basierte auf VOR-Restructure compiler.h und wurde verworfen (nur Dateien wiederverwendet).
- **Commit 1 `27d8a2e06c`**: ci: native build lanes for foreign CPU architectures via QEMU user-mode
  - `.github/scripts/qemu/run-qemu-build.sh` (final: debug-output, debian-ports keyring, libunwind-dev skip fuer alpha/sparc64) — NEUE Datei (existiert nicht auf master)
  - `.github/workflows/build-xserver.yml` +44 Zeilen qemu-user Matrix-Job (Datei existiert bereits auf master, Diff nur Zusatz)
- **PR-Branch force-pusht**: `pr/master-ci-native-build-lanes-for-foreign-cpu-architectures-via-qemu-user-mode_2026-08-06_13-50-15` 2ebe1e4c97 → 27d8a2e06c (vorher nur Initial-Commit, 2 Dateien, niemals CI-getestet). PR geclaimt (Defiant).
- **CI neu getriggert**: 10 pending inkl. alle 5 QEMU-Lanes.

### Erwartung
- **ppc64el-Lane bleibt ROT**, bis Enterprises eieio-PR auf master ist (master nutzt __builtin_ppc_eieio() noch unguarded in compiler.h + xlibre_membarrier.h). Enterprise meldet sich, dann finale Validierung.
- armhf/mipsel sollten gruen sein; alpha/sparc64 weiterhin debian-ports/unstable Dep-Luecken (separater Fix noetig).

### Alte Verifikation (Run 31167038878, alter Stand)
**ppc64el ✅, armhf ✅, mipsel ✅, alpha ❌, sparc64 ❌** — bewies die Machbarkeit; der neue Rebuild nutzt die aufgeraeumten compiler.h-Fixes nicht mehr.

### Offen / naechste Schritte
1. CI von PR #3491 beobachten (Timer calm-ape-96, alle 15m)
2. Nach Enterprises eieio-PR-Merge: ppc64el-Lane final validieren
3. alpha/sparc64: debian-ports Deps fixen (install-prereq.sh erweitern)
4. Dashboard-Status nach finalem Gruen auf "done" setzen
