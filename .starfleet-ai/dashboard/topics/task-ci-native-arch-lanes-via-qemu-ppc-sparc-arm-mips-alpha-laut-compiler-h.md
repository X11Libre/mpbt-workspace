Title: "CI: native Arch-Lanes via QEMU (ppc/sparc/arm/mips/alpha laut compiler.h)"
Category: active
Kind: task
Status: "assigned"
Created-By: "Voyager"
Created: "2026-08-06T11:18:44Z"
Assigned-To: "Voyager"
Doc-Ref: "—"
Slug: task-ci-native-arch-lanes-via-qemu-ppc-sparc-arm-mips-alpha-laut-compiler-h

Machbarkeit: nativ (nicht cross) in QEMU bauen. Architekturen, die include/compiler.h referenziert: __alpha__, __amd64__/__i386__/__ia64__, __sparc__, __arm32__, __mips__, __powerpc__ (x86-Bereich schon durch bestehende Lanes abgedeckt). Gewaehlter Ansatz: QEMU-User-Mode (qemu-user-static + binfmt_misc) mit fremdarchigem Debian/Ubuntu-Rootfs, nativer Compile + Xvfb-Smoke-Test. Arbeit in separatem Worktree auf Basis von origin/master. Erste Arch-Lane ppc64el als Pilot, dann sparc64/armhf/mipsel/alpha.
