---
slug: platform-specific-ifdef-cleanup-grab-bag-os-macros-concrete
title: "Platform-specific `#ifdef` cleanup — grab-bag OS macros → concrete feature flags"
category: active
status: "**In progress** — `CSRG_BASED` phase **merged**, `SVR4` phase 2 PRs open"
doc_ref: "**Merged:** #3209 / #3211 / #3212 (CSRG_BASED). **Open:** #3218 (`SVR4` socket headers), #3220 (dead `<sys/utsname.h>`), #3224 (dead `#define termio termios`); agent clones `_WORK_/xserver-master/agent/ifdef-cleanup/xserver` + `.../termio/xserver`"
migrated_from: 8cf8692b9f0057ffe44e793b35bcf7329da83d3f
---

Praetor idea 2026-07-01: replace vague "which-OS-family" macros with specific `HAVE_<feature>`/meson checks. All build-verified `-Dwerror` on Linux, base master. **CSRG_BASED — DONE (merged):** `os/connection.c`+`os/access.c` `<sys/param.h>`→`HAVE_SYS_PARAM_H` (#3209), `xf86Helper.c` dead `HAS_SETPRIORITY` deleted (#3211), `xf86Globals.c`+`xf86Privstr.h` consType→`CONFIG_BSD_CONSOLE` (#3212); bigfont one via merged #3201. **SVR4 — clean wins done (open PRs):** `<sys/filio.h>`/`<sys/sockio.h>`/`<sys/stropts.h>`→`HAVE_SYS_*_H` (#3218), dead `<sys/utsname.h>` in access.c removed — uname is behind `xhostname()` now (#3220). **Dead-code bonus:** the `#define termio termios` in `xf86_OSlib.h` (BSD block) removed — `termio` type unused treewide (#3224). **Deliberately left (NOT mislabels — the macro is used correctly, would need a restructure not a swap):** `include/xf86_OSlib.h` BSD/`__SVR4&&__sun` header blocks (structural per-OS-family header cascade, now minus the dead termio alias); `hw/xfree86/os-support/bus/xf86Sbus_priv.h` (niche SPARC SBUS fbio/openprom header selection); `os/backtrace.c` `__sun&&__SVR4`→`HAVE_PSTACK` (already a clean OS→named-capability map; pstack is Solaris-only); `os/Xtranssock.c:231` `SOCKLEN_T` typedef fallback (compat quirk, already partly `HAVE_SOCKLEN_T`-based). `SYSV`/`BSD44`/`SYSV386` don't occur. Inventory: `git grep -n 'CSRG_BASED|SVR4|__SVR4'`
