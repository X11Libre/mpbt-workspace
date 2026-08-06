Title: ""
Category: active
Status: "assigned"
Assigned-To: "Defiant"
Created-By: ""
Created: ""
Doc-Ref: ""

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

### Offen / naechste Schritte
- CI auf den 5 QEMU-Lanes abwarten; die debian-ports-Lanes (sparc64/alpha) koennten erste Dep-Luecken zeigen — ggf. Dep-Liste anpassen.
- Enterprise-Synergie: PR #3490 (powerpc sys/mman.h) wird durch ppc64el-Lane potenziell validiert.
- Entscheiden: Lanes auch als Release-Gate in den `release:`-Job `needs:` aufnehmen (bewusst noch NICHT eingebunden).
- Nach Gruen: bot-review (Banner + Label), Lessons in lokales Wissens-Dump schreiben, ggf. Skill ci-platform aktualisieren.
