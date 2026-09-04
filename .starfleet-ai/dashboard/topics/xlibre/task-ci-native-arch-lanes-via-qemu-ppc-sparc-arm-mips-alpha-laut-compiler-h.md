Title: "CI: native Arch-Lanes via QEMU (ppc/sparc/arm/mips/alpha laut compiler.h)"
Category: xlibre
Kind: "task"
Status: "done"
Assigned-To: "Defiant"
Created-By: "Voyager"
Created: "2026-08-06T11:18:44Z"
Doc-Ref: "PR #3491: https://github.com/X11Libre/xserver/pull/3491"

Machbarkeit: nativ (nicht cross) in QEMU bauen. Architekturen, die include/compiler.h referenziert: __alpha__, __amd64__/__i386__/__ia64__, __sparc__, __arm32__, __mips__, __powerpc__ (x86-Bereich schon durch bestehende Lanes abgedeckt). Gewaehlter Ansatz: QEMU-User-Mode (qemu-user-static + binfmt_misc) mit fremdarchigem Debian-Rootfs, nativer Compile + optional Xvfb-Smoke-Test.

## FINAL (2026-08-07) — Validierung auf gefixtem master

PR #3491 rebased auf master 33b79c397c (Enterprise: eieio + MIPS-membarrier-Fix via #3506), Head 2f0ee125bd, nur CI-Dateien (run-qemu-build.sh neu + build-xserver.yml +44 Zeilen).

| Lane | Status |
|------|--------|
| ppc64el (__powerpc__) | ✅ GRUEN — eieio-Fix validiert |
| armhf (__arm32__) | ✅ GRUEN |
| mipsel (__mips__) | ✅ GRUEN — MIPS-membarrier-Fix validiert |
| sparc64 (__sparc__) | ❌ debian-ports/unstable Dep-Luecken (bekannt) |
| alpha (__alpha__) | ❌ debian-ports/unstable Dep-Luecken (bekannt) |

**Alle compiler.h-Architekturen mit offiziellen Debian-Ports GRUEN.** sparc64/alpha scheitern weiterhin an fehlenden -dev-Paketen in debian-ports/unstable — kein compiler.h-Problem, separater Fix noetig.

## Ablauf (Kurzfassung)

- 2026-08-06: Ansatz validiert, PR #3491 angelegt (Voyager-Start), Debug-/Fix-Runde (Script, eieio, lnx_video, keyring, libunwind).
- 2026-08-07: Entscheidung m12822 — PR #3491 traegt NUR reine CI-Infra; compiler.h-Fixes laufen ueber Enterprise (wip/compiler.h-cleanup): PR #3505 (ioBase void*, gemergt cd3fb8ba8e) + PR #3506 (eieio+MIPS-Fix, gemergt 33b79c397c).
- Rebuild auf frischem origin/master (wt/ci-arch-lanes-rebased), PR-Branch force-pushed, PR geclaimt (Defiant).
- CI deckte echten master-Bug auf: xlibre_membarrier.h __mips__-Zweig rief mem_barrier() vor Definition -> in #3506 gefixt (xlibre_mem_barrier_read()).
- Finale Validierung nach Merge: 3/3 Ziel-Lanes gruen.

## Offen / naechste Schritte

1. sparc64/alpha: debian-ports Deps fixen (install-prereq.sh erweitern) — separater Folge-Task.
2. PR #3491 mergebar, CI gruen (ausser den 2 bekannten debian-ports-Lanes) — Merge-Entscheidung beim Praetor.
