---
Title: Fix uninitialized variables found by clang -Wconditional-uninitialized
Status: open
Created: 2026-09-02
Category: active
Tags: xserver, clang, static-analysis, code-quality
Ref: xlibre/uninitialized-variables-scan
---

## Fix uninitialized variables found by clang -Wconditional-uninitialized

Clang 19.1 `-Wconditional-uninitialized` found **44 warnings in 21 files** during a full clean build. GCC's `-Wuninitialized`/`-Wmaybe-uninitialized` shows nothing (less precise for conditional paths).

### Plan

#### Phase 1: Add the warning flag to meson.build

Add `-Wconditional-uninitialized` to the `test_wflags` list in `meson.build` (non-error first, so the build doesn't break while fixing).

#### Phase 2: Fix per-subsystem (highest priority first)

**1. hw/xfree86/drivers/video/modesetting/drmmode_display.c** — HIGH
- Line 2689: `blob_id` — initialize to `0` before the plane type switch
- Line 2696: `async_blob_id` — same
- These are used in `populate_format_modifiers()` for atomic modesetting plane format negotiation

**2. dix/dixfonts.c** — MEDIUM
- Line 680: `name`, `namelen` — `name` is set to `0` before FPE call; ensure `namelen` is also initialized
- Line 948: `numFonts` — initialize before use in alias save path
- Line 988: `pFontInfo` — initialize to `NULL`

**3. dix/events.c** — MEDIUM
- Line 4332: `mask`, `filter` — ensure `ConvertToXI3` always populates these, or initialize before the call

**4. dix/getevents.c** — MEDIUM
- Line 2027: `raw` — check allocation path; initialize to `NULL`

**5. dix/window.c** — MEDIUM
- Line 355: `mask` — initialize before `ForceEventDelivery`

**6. glamor/glamor.c + glamor_render.c** — MEDIUM
- glamor.c:515: `read_format`, `read_type`
- glamor_render.c:1356-1359: `source_x_off`, `source_y_off`, `mask_x_off`, `mask_y_off`

**7. Xext/** — LOW-MEDIUM
- composite/compalloc.c: `pLayerWin` (2 instances)
- damage/damageext.c: `pDrawable`
- shm/shm.c: `uid`, `gid`
- xkeyboard/xkb.c: `len`
- xres/xres.c: `ht`
- xselinux/xselinux_hooks.c: `offset`
- glx/glxcmds.c: `pDraw`

**8. mi/** — LOW
- miwindow.c: `pLayerWin` (4 instances)
- miarc.c: `iny`
- miwideline.c: `saveBottom`, `saveRight`

**9. exa/exa_render.c** — LOW
- `src_off_x`, `src_off_y`

**10. hw/xfree86/** remaining — LOW
- xf86Config.c: `Pointer`, `Keyboard`
- xf86Cursor.c: `px`, `py`
- xf86fbman.c: `offset`
- dri/dri.c: `err`
- modesetting/vblank.c: `msc`

#### Phase 3: Enable as -Werror

After all warnings are fixed, change `-Wconditional-uninitialized` to `-Werror=conditional-uninitialized` in meson.build so new regressions break the build.

### How to verify

```bash
cd _WORK_/xserver-master/sources/xlibre/xserver
CC=clang CFLAGS="-Wconditional-uninitialized -Werror=conditional-uninitialized" \
  meson setup _build-check && ninja -C _build-check
```

Must complete with 0 warnings/errors.
