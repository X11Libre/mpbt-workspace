---
Title: Scan for uninitialized variables in xserver source
Status: in-progress
Created: 2026-09-02
Assigned-To: Defiant
Category: active
---

## Scan for uninitialized variables in xserver source

Tool: Clang 19.1 `-Wconditional-uninitialized` (GCC's `-Wuninitialized`/`-Wmaybe-uninitialized` shows nothing — already active in meson.build but not as -Werror)

### Method
- Full clean build with `CC=clang CFLAGS="-Wconditional-uninitialized -Wsometimes-uninitialized -Wuninitialized -Werror=uninitialized"`
- GCC 14.2 with same flags: 0 warnings (GCC less precise here)
- Clang `-Wconditional-uninitialized`: **44 warnings in 21 files**

### Results by subsystem

#### dix/ (core server) — 10 warnings, HIGHEST PRIORITY

| File | Line | Variable | Risk |
|------|------|----------|------|
| dixfonts.c | 680 | `name`, `namelen` | Medium — set to 0 before FPE call, used if `!c->haveSaved`; FPE may not set it on `Successful` |
| dixfonts.c | 948 | `numFonts` | Low — only used in `else` branch after alias resolution |
| dixfonts.c | 988 | `pFontInfo` | Low — used after `err == Successful` check |
| grabs.c | 158 | `mask` | Low — debug print only (ErrorF), but could crash if xi2mask loop is empty |
| getevents.c | 2027 | `raw` | Medium — `raw` used in `set_raw_valuators` if `need_rawevent` true; depends on earlier alloc path |
| events.c | 4332 | `mask`, `filter` | Medium — used in `TryClientEvents` if `rc == Success` and no access hook denies; conversion may not set them |
| touch.c | 586 | `ptrtype` | Low — only in debug/error path |
| colormap.c | 900 | `nump` | Low — only in error handling |
| window.c | 355 | `mask` | Medium — `mask` used in `ForceEventDelivery` if `rc == Success` |

#### hw/xfree86/ (DDX + modesetting) — 8 warnings

| File | Line | Variable | Risk |
|------|------|----------|------|
| drmmode_display.c | 2689 | `blob_id` | **HIGH** — used in `populate_format_modifiers` for plane format setup; only set inside switch-case that may not execute |
| drmmode_display.c | 2696 | `async_blob_id` | **HIGH** — same pattern |
| vblank.c | 594 | `msc` | Medium — used in vblank handler comparison; may cause missed events |
| xf86Config.c | 1185,1281 | `Pointer`, `Keyboard` | Low — config parsing, fails gracefully |
| xf86Cursor.c | 236,251 | `px`, `py` | Low — cursor positioning, only if cursor moved |
| xf86fbman.c | 793 | `offset` | Low — framebuffer manager |
| dri.c | 226 | `err` | Low — DRI extension |

#### Xext/ (extensions) — 8 warnings

| File | Line | Variable | Risk |
|------|------|----------|------|
| composite/compalloc.c | 231,316 | `pLayerWin` | Medium — composite layer window |
| damage/damageext.c | 620 | `pDrawable` | Medium — damage reporting |
| shm/shm.c | 297,312 | `uid`, `gid` | Low — SHM extension, only if `shmctl` fails |
| xkeyboard/xkb.c | 5710 | `len` | Low — XKB extension |
| xres/xres.c | 670 | `ht` | Low — resource reporting |
| xselinux/xselinux_hooks.c | 243 | `offset` | Low — SELinux hooks |
| glx/glxcmds.c | 1833 | `pDraw` | Medium — GLX drawable |

#### mi/ (machine-independent) — 7 warnings

| File | Line | Variable | Risk |
|------|------|----------|------|
| miwindow.c | 289,457,669,725 | `pLayerWin` | Medium — 4 instances, all layer window lookup |
| miarc.c | 422 | `iny` | Low — arc rendering |
| miwideline.c | 2187,2188 | `saveBottom`, `saveRight` | Low — line rendering |

#### glamor/ (GL acceleration) — 6 warnings

| File | Line | Variable | Risk |
|------|------|----------|------|
| glamor.c | 515 | `read_format`, `read_type` | Medium — Pixmap readback |
| glamor_render.c | 1356-1359 | `source_x_off`, `source_y_off`, `mask_x_off`, `mask_y_off` | Medium — composite rendering offsets |

#### exa/ — 2 warnings

| File | Line | Variable | Risk |
|------|------|----------|------|
| exa_render.c | 759,760 | `src_off_x`, `src_off_y` | Low — EXA render acceleration |

### Most critical findings

1. **drmmode_display.c blob_id/async_blob_id** — If the plane type switch doesn't hit the `DRMMODE_PLANE_TYPE_PRIMARY` case, `blob_id` and `async_blob_id` are used uninitialized in `populate_format_modifiers()`. This is in the modesetting driver's atomic modesetting path — could cause wrong format negotiation or crash.

2. **dixfonts.c name/namelen** — `name` is set to `0` (NULL) before the FPE call. If the FPE returns `Successful` but doesn't populate `name`, `xfont2_add_font_names_name` gets NULL. Low probability but core font path.

3. **events.c mask/filter** — If `ConvertToXI3` succeeds but doesn't populate `mask`/`filter`, `TryClientEvents` gets garbage. Core event delivery path.

4. **glamor_render.c composite offsets** — 4 uninitialized offset variables in the render compositing path. Could cause wrong rendering coordinates.

### Recommended next steps

- Add `-Wconditional-uninitialized` to the meson.build warning flags (non-error initially)
- Fix the modesetting `blob_id`/`async_blob_id` case (initialize to 0)
- Fix `dixfonts.c` name initialization
- Review `events.c` mask/filter conversion path
- Consider adding `-Werror=conditional-uninitialized` after all warnings are fixed
