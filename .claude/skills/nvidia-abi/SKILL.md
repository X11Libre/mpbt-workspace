---
name: nvidia-abi
description: "NVIDIA driver ABI — living record of empirical findings. Use when reviewing NVIDIA-related changes, running ABI checks (nvidia-abi-check), classifying exported symbols, or deciding whether a change breaks proprietary nvidia blobs. Covers link-import + runtime-lookup detection, confirmed do-not-break rules, and the GL/GLX protocol surface."
---

# NVIDIA driver ABI — empirical findings

Review NVIDIA-related changes against the proprietary blob's actual dependency surface.
The blobs **cannot be recompiled** — ABI breakage stays in the field permanently.

Full reference: **`reference.md`** in this skill's directory. This skill is the actionable checklist.

## Quick checks

1. **Classify changed symbols:** `scripts/nvidia-abi-check SYM ...` (checks both link-import via `nm` + runtime lookup via string scan)
2. **Raw import dump:** `scripts/nvidia-undefined-symbols | sort -u` (link-import only — misses runtime lookups, prefer `nvidia-abi-check`)
3. **Fetch blobs:** `scripts/fetch-nvidia-drivers [version ...]` or `scripts/fetch-all-nvidia-drivers`

## Key rules

- **Two ways the blob reaches a symbol:** link-import (`nm -D`) AND runtime lookup (`dlsym()`/`LoaderSymbol()`). Check BOTH — plain `nm` misses the runtime half (#2070).
- **Struct layout:** never reorder/insert/remove fields. Before any extension, trace allocation ownership and all public construction paths. A tail append is only safe if the core owns and sizes every allocation and old out-of-tree consumers only read existing fields; the core must never write the new tail into storage that an old external driver may have allocated or embedded. If driver-side allocation cannot be ruled out, do not extend the struct; use an opaque/private sidecar or accessor instead.
  If a tail extension is justified, put an explicit ABI-boundary comment immediately
  before the first private tail member, stating that everything below is server-private
  and not part of the driver ABI (for example: `/* ABI boundary: fields below are
  server-private, not part of the driver ABI. */`). The comment is documentation only;
  it does not make an unsafe allocation/layout change compatible or replace the proof.
- **Allocation audit:** distinguish (a) core-allocated objects returned to a DDX from (b) DDX-allocated/embedded objects passed into the core. Search in-tree call sites, public constructors, and lifetime/free paths, but do not treat an in-tree-only search as proof about proprietary blobs. NVIDIA binary symbol/string scans do not reveal allocation sizes or struct ownership; state that limitation explicitly.
- **Runtime-lookup-only symbols** (e.g. `xf86CursorScreenKeyRec`, `monitorResolution`, `PictureScreenPrivateKey`) must stay `_X_EXPORT`.
- **Version coverage:** currently 390.157, 470.256.02, 550.142, 570.133.07.

## In PR review (bot-review rule 3)

Run `nvidia-abi-check` on unexported/changed symbols. A hit in either column means "keep it".
