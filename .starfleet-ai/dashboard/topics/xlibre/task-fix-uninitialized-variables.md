Title: Fix uninitialized variables found by clang -Wconditional-uninitialized
Status: done
Created: 2026-09-02
Category: active
Tags: xserver, clang, static-analysis, code-quality
Ref: xlibre/uninitialized-variables-scan
Assigned-To: "Galactica"
Done-By: "Galactica"
---

## Fix uninitialized variables found by clang -Wconditional-uninitialized

Clang 19.1 `-Wconditional-uninitialized` found **44 warnings in 21 files** during a full clean build. GCC's `-Wuninitialized`/`-Wmaybe-uninitialized` shows nothing (less precise for conditional paths).

### Result (2026-09-05, Galactica)

All warnings fixed. Branch `wip/fix-uninitialized-vars`, commits:
- `d3d44ba6c6` — dix: prevent uninitialized reads reported by clang (31 files)
- `4d46cd0994` — meson: enable -Wconditional-uninitialized as error for clang

Phase 1: `-Wconditional-uninitialized` added to `meson.build` `test_wflags`.
Phase 2: All 44 plan warnings fixed, plus additional conditional-uninitialized
warnings that only surfaced in the real clang meson build (grabs, touch,
colormap, kdrive, Xtranssock, damage PanoramiX, glx DoGetDrawableAttributes,
exa src_off elsewhere, vblank msc sequence handler, xkb len, window log_grab_info).
Every site was reviewed: in genuine paths the variable is always set, but
clang cannot prune the control flow (switch/loop/helper); the conservative
default matches existing usage (NULL/0/-1/UINT64_MAX).
Phase 3: `-Werror=conditional-uninitialized` enabled so regressions break the build
(clang only; GCC filters it out via cc.has_argument).

### Verification

Full clean build:
```
CC=clang CFLAGS="-Wconditional-uninitialized -Werror=conditional-uninitialized" \
  meson setup _build-check && ninja -C _build-check
```
All 747 targets build, 0 warnings / 0 errors. (Two pre-existing
`-Wtypedef-redefinition` notes in glamor_egl_priv.h under clang remain; they are
C11-typedef notes unrelated to this task and not errors.)

### Files fixed (31)

Xext/composite/compalloc.c, Xext/damage/damageext.c, Xext/glx/glxcmds.c,
Xext/shm/shm.c, Xext/xkeyboard/xkb.c, Xext/xres/xres.c,
Xext/xselinux/xselinux_hooks.c, dix/colormap.c, dix/dixfonts.c, dix/events.c,
dix/getevents.c, dix/grabs.c, dix/touch.c, dix/window.c, exa/exa_render.c,
glamor/glamor.c, glamor/glamor_render.c, hw/kdrive/linux/mouse.c,
hw/kdrive/linux/ps2.c, hw/kdrive/src/kdrive.c, hw/xfree86/common/xf86Config.c,
hw/xfree86/common/xf86Cursor.c, hw/xfree86/common/xf86fbman.c,
hw/xfree86/dri/dri.c, hw/xfree86/drivers/video/modesetting/drmmode_display.c,
hw/xfree86/drivers/video/modesetting/vblank.c, meson.build, mi/miarc.c,
mi/miwideline.c, mi/miwindow.c, os/Xtranssock.c
