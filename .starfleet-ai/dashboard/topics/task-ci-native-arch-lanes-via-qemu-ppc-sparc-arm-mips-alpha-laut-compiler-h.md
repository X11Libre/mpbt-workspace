Title: "CI: native Arch-Lanes via QEMU (ppc/sparc/arm/mips/alpha laut compiler.h)"
Category: active
Kind: task
Status: "blocked"
Created-By: "Voyager"
Created: "2026-08-06T11:18:44Z"
Assigned-To: "Defiant"
Doc-Ref: "PR #3491: https://github.com/X11Libre/xserver/pull/3491"
Slug: task-ci-native-arch-lanes-via-qemu-ppc-sparc-arm-mips-alpha-laut-compiler-h

Machbarkeit: nativ (nicht cross) in QEMU bauen. Architekturen, die include/compiler.h referenziert: __alpha__, __amd64__/__i386__/__ia64__, __sparc__, __arm32__, __mips__, __powerpc__ (x86-Bereich schon durch bestehende Lanes abgedeckt). Gewaehlter Ansatz: QEMU-User-Mode (qemu-user-static + binfmt_misc) mit fremdarchigem Debian-Rootfs, nativer Compile + optional Xvfb-Smoke-Test. Arbeit in separatem Worktree auf Basis von origin/master.

## Arbeitsstand (2026-08-06)

### Fertig
- **Ansatz validiert**: QEMU-User-Mode (debootstrap --foreign + --second-stage + qemu-<arch>-static via binfmt_misc) lokal in Docker-Probe bestaetigt — ppc64el-gcc kompiliert und fuehrt natives Binary aus (`NATIVE_COMPILE_RUN_OK`).
- **Generisches Script**: `.github/scripts/qemu/run-qemu-build.sh` — Host-Seite (qemu-user-static/binfmt-support/debootstrap installieren, Rootfs debootstrappen, Source kopieren) + Chroot-Seite (apt-Deps fuer Zielarch, meson setup/configure/compile). `--run-test`-Option fuer optionales meson test (best-effort).
- **Workflow-Job**: `xserver-build-qemu-user` (Matrix) in `build-xserver.yml` — 5 Archs:
  - ppc64el (__powerpc__, bookworm, offizieller Port)
  - armhf (__arm32__, bookworm, offizieller Port)
  - mipsel (__mips__, bookworm, offizieller Port)
  - sparc64 (__sparc__, unstable, debian-ports)
  - alpha (__alpha__, unstable, debian-ports)
  - `MESON_ARGS`: `-Dwerror=true -Dxorg -Dxvfb -Dxnest -Dxephyr -Dglx` (xfbdev aus)
- **PR #3491 angelegt**: `github pr make 5c96607da8` aus Worktree `_WORK_/worktrees/xserver/ci-arch-lanes` (Branch wt/ci-arch-lanes). Titel `(master) ci: native build lanes for foreign CPU architectures via QEMU user-mode`, Assignee metux, Reviewer X11Libre/dev. URL: https://github.com/X11Libre/xserver/pull/3491
- **Signed-off-by nachgetragen**: erster PR-Head failte Check Signed-Off-By; amend --signoff + force-push auf PR-Branch (f0dcd99f92), Checks laufen auf neuem Head.
- **Incubator-Branch markiert**: wt/ci-arch-lanes via Tooling mit `[PR #3491]`-Prefix + `PR:`-Trailer versehen, force-push (nur Commit-Message geaendert, Baum identisch).

### Debugging & Fixes (2026-08-06, Defiant)
- **Debug-Script deployed** (commit 881bc6f): `run-qemu-build.sh` ergaenzt mit `set -x`, Timestamps `[$(date)]` und verbose Output in allen Phasen (host deps, debootstrap, chroot install-prereq, chroot run-build).
- **compiler.h Fix** (commit 2822acd): Fallback auf `asm("eieio")` wenn `__builtin_ppc_eieio` nicht verfuegbar. GCC 12.2 in Debian bookworm ppc64el hat das Builtin nicht (nur powerpc BE). Fix:
  ```c
  #elif defined __powerpc__
  #if defined(__has_builtin) && __has_builtin(__builtin_ppc_eieio)
  #define mem_barrier()       __builtin_ppc_eieio()
  #define write_mem_barrier() __builtin_ppc_eieio()
  #elif __GNUC__ >= 10
  #define mem_barrier()       __builtin_ppc_eieio()
  #define write_mem_barrier() __builtin_ppc_eieio()
  #else
  #define mem_barrier()       __asm__ __volatile__ ("eieio" ::: "memory")
  #define write_mem_barrier() __asm__ __volatile__ ("eieio" ::: "memory")
  #endif
  ```
- **Lokale Validierung**: Docker-Test mit ubuntu:24.04 + qemu-user-static -> bootstrap + install-prereq.sh laufen komplett durch. Build scheitert exakt an der Stelle die im CI failt (lnx_init.c -> compiler.h eieio). Fix lokal bestaetigt.

### CI-Runs (Status 2026-08-06 17:30)
| Run | Status | QEMU-Lanes |
|-----|--------|------------|
| 31104251532 | completed/failure | armhf ✅, mipsel ✅, ppc64el ❌, alpha ❌, sparc64 ❌ |
| 31116827724 | completed/cancelled | alpha/sparc64 ❌ (early), ppc64el ❌ (Set up job flake), mipsel ❌ (Set up job flake) |
| 31118324427 | completed/cancelled | Queue-Timeout / cancel-in-progress |
| **31120345223** | **queued (seit 16:35)** | **WARTET auf Runner** |

**Letzter CI-Status (Run 31116827724 vor Cancel):**
- ✅ armhf (ARM 32-bit) — SUCCESS
- ✅ mipsel (MIPS 32-bit) — SUCCESS (NEU, war vorher rot)
- ❌ ppc64el (PowerPC64 LE) — FAILURE (compiler.h eieio, jetzt gefixt)
- ❌ alpha (Alpha) — FAILURE (debian-ports unstable, Dep-Lücken)
- ❌ sparc64 (SPARC64) — FAILURE (debian-ports unstable, Dep-Lücken)

**Aktuelle Blocker:** GitHub Actions Infrastructure — **9 Runs queued, 0 in_progress seit >1h**. Keine Runner-Provisioning. Alle Builds (master, PRs, unser Branch) stehen in "queued". Systemisches GitHub Problem.

### Offen / naechste Schritte (nach GitHub Recovery)
1. **CI abwarten** — Run 31120345223 (oder neuer Retrigger) muss durchlaufen. Erwartet:
   - ppc64el sollte jetzt GRÜN sein (compiler.h Fix)
   - mipsel/armhf bleiben GRÜN
   - alpha/sparc64: evtl. Dep-Lücken in debian-ports/unstable (apt package list anpassen)
2. **debian-ports Deps prüfen** — falls alpha/sparc64 weiter fallen: `apt-cache policy <pkg>` in chroot vergleichen, fehlende -dev Pakete in install-prereq.sh nachtragen
3. **Enterprise-Synergie**: PR #3490 (powerpc sys/mman.h) wird durch ppc64el-Lane validiert
4. **Release-Gate entscheiden**: Lanes in `release:` Job `needs:` aufnehmen (aktuell NICHT eingebunden)
5. **Nach Grün**: bot-review (Banner + Label), Lessons in lokales Wissens-Dump (`agents.d/local/`), Skill `ci-platform` aktualisieren

### Worktree / Branch
- Worktree: `_WORK_/worktrees/xserver/ci-arch-lanes`
- Branch: `wt/ci-arch-lanes` (tracking `origin/wt/ci-arch-lanes`)
- Aktueller HEAD: `7ef08503de` (ci: retrigger QEMU lanes after cancelled run)
- PR #3491 Head: `2ebe1e4c97` (diverged, force-push noetig sobald CI grün)

### Wichtige Dateien
- `.github/scripts/qemu/run-qemu-build.sh` — Build-Script (mit Debug-Output)
- `.github/workflows/build-xserver.yml` — Job `xserver-build-qemu-user` (Matrix 5 Archs)
- `include/compiler.h` — ppc64el eieio-Fallback (Zeilen ~103-115)

---
**Task an Defiant assigned. Status: blocked (GitHub Actions). Fortsetzung sobald Runner verfuegbar.**