---
slug: important-quirks
title: "Important quirks"
order: 90
---

## Important quirks

- **Only `xserver-master` builds all drivers + xts + piglit.** The 25.0/25.1 solutions have nearly all drivers commented out — only xserver itself is built.
- **`xserver-master`** uses `-Dxorg-sdk=true` and `-Dxfbdev=true`; `xserver-25.1` has `-Dxfbdev=true` but not `-Dxorg-sdk`; `xserver-25.0` has neither.
- **Install prefix is ephemeral.** The `run-build.*` scripts remove `_WORK_/<release>/install` after building (though the actual install prefix configured in devuan.yaml is `{workdir}/target`).
- **pkg-config & aclocal paths** are set per-solution in `devuan.yaml` `env:` — they point into the install prefix.
- **Tags are namespaced per remote** (e.g., `refs/tags/origin/*`, `refs/tags/xorg/*`). Repos use `tagopt: --no-tags` to prevent tag clutter; tags are fetched manually.
- **Xserver meson flags** vary by release (see devuan.yaml `package-config:`), generally include `-Dxephyr=true`, `-Dxnest=true`, `-Dxvfb=true`, `-Dxorg=true`, `-Dxf86-input-inputtest=true`, `-Dtest_xephyr_gles=false`.
- **XLibre has removed server regeneration (no internal reset).** `dix/main.c` runs the init sequence **once**, calls `Dispatch()`, then tears down and `return 0` — there is no regeneration loop, `serverGeneration` does not appear in `main()`, and `-noreset` is explicitly *"removed in XLibre"* (`os/utils.c`). Consequence for review: the old XFree86 `if (xxxGeneration != serverGeneration) { … }` re-init guards are now **vestigial**, and process-lifetime statics used as once-only init flags are **safe** (no second generation to reset them for). This is why dropping such guards (PR #1455) is correct on master — but **NOT** automatically safe to backport to a release line that may still regenerate.
- **A static lib linked into two loadable modules → duplicate symbols with per-copy statics.** The Xorg (xfree86) DDX loads code as separate `dlopen`'d modules, and a `static_library` can end up compiled into more than one of them: `libxserver_glx` (containing `Xext/glx/glxext.c`) goes into **`extensions/libglx.so`** via `link_whole:` *and* into **`libglamoregl.so`** via `link_with:` — the latter transitively, because the `glamor` lib's `glamor_egl.c` referenced `xorgGlxCreateVendor()`, dragging `glxext.c.o` in to resolve it. Result: on Xorg, `xorgGlxServerInit`/`xorgGlxCreateVendor` exist at **two addresses, each with its own file-scope `static` storage** — so a `static`-once guard in such a function silently fails to work (each copy has its own flag), and gdb shows two same-named functions. A **monolithic** server (kdrive `Xfbdev`, which links the archive once into the executable) doesn't have this. Diagnose with `nm <module>.so | grep <sym>` on each module. #3174 fixed the glx instance by removing the cross-reference (`glamor_egl.c` no longer calls `xorgGlxCreateVendor`), so `glxext.c.o` is no longer pulled into `libglamoregl.so`. Same family as the latent double-compile of `dpms.c` (the #3022 repair): watch for a source/object appearing in two link targets that are both loaded at once.
