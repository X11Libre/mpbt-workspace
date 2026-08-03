Title: "Backport #3213 (glamor_egl: drop static glx link) → 25.2/25.1/25.0"
Category: active
Status: "PRs open"
Assigned-To: "Defiant"
Created-By: "Defiant"
Created: "2026-08-03"
Doc-Ref: "—"

Backport master PR #3213 (merge `6c75731752`) to all three release lines.
Master fixes duplicate GLX symbols in glx.so/glamoregl.so by dropping
`libxserver_glx` from `hw/xfree86/glamor_egl/meson.build` `link_with`.

## Backports (open)

| Branch | Backport PR | Status | Incubator commits |
|---|---|---|---|
| release/25.2 | #3471 | 🔄 open | `[PR #3471]` 19c47b75f7 / 1836571449 |
| release/25.1 | #3472 | 🔄 open | `[PR #3472]` 76dd964663 / 8f7675ae8d |
| release/25.0 | #3473 | 🔄 open | `[PR #3473]` 96d66ef06e / 6090fae840 |

## Tooling gap found

`backport commit` resolves only the PR's **tip** commit. PR #3213 was merged
with **two** commits (meson `link_with` fix + prerequisite `_X_EXPORT` header
commit `9b74a3a7f9a2`); the toolchain cherry-picked only the meson one. The
`_X_EXPORT` header exports had to be added manually per branch, then the PR
branches rebuilt (reset onto `origin/release/<rel>`, both commits, force-push).

## Per-branch adaptations

- **25.2**: clean cherry-pick of both commits (identical `Xext/glx/` layout).
- **25.1/25.0**: paths remapped `Xext/glx/` → `glx/`. `glx/glxutil.h` on these
  branches no longer includes `glxserver.h`, so it gained an explicit
  `#include <X11/Xfuncproto.h>` (same pattern master used in
  `extension_string.h`).

## CI status

- 25.1: all xserver-build lanes green (ubuntu 6m15s/6m50s).
- 25.0: xserver-build-ubuntu green (7m21s).
- 25.2: arch/cygwin/macos green; ubuntu/others queued on GH runners (2026-08-03).

## Next steps

- Verify remaining 25.2 CI lanes.
- Merges into `release/*` are **manual by praetor** — do not auto-merge.
