---
slug: xorg-upstream-tracking
title: "xorg-upstream tracking (`tracking/xorg/main-on-<rel>`)"
category: active
status: "Ongoing, recurring — **delta fully dispositioned + all 4 trackers advanced, 2026-07-02**"
doc_ref: "`AGENTS.md` \"xorg upstream tracking\"; master PR #3217 (udev NULL-deref fix) + backports #3221 (25.2) / #3222 (25.1) / #3223 (25.0); master PR #3219 (xquartz GLX_ARB_create_context + deprecation silencing)"
migrated_from: 8cf8692b9f0057ffe44e793b35bcf7329da83d3f
---

2026-07-02: 3 new `xorg/main` commits found (all 4 trackers were at the same old tip). `9babe7e7f6` (config/udev: guard against NULL subsystem in fallback bus id — real SIGSEGV crash fix, `config_udev_get_fallback_bus_id()`) → master PR #3217; `config_udev_get_fallback_bus_id()` was byte-for-byte identical (unguarded) on `release/25.2`/`25.1`/`25.0` (checked via `show-branch-file`), so on praetor go-ahead it was also cherry-picked straight from the upstream SHA onto all three release incubators → **#3221/#3222/#3223 opened** (cross-linked to #3217's new "Backport dashboard" table; per policy these are **opened only, not merged** — release-line merges stay manual/praetor-only). `609e7d9421`+`31060c9506` (xquartz/GL: advertise `GLX_ARB_create_context`/profile + silence deprecation warnings, macOS-only, not backport-relevant) → bundled master PR #3219 (one real conflict in `hw/xquartz/GL/meson.build` — XLibre already dropped the stale `glx_inc` include in `dd4c8d4ecb`, resolved by keeping our `include_directories` and only taking the new `c_args`; not locally buildable, macOS CI lane will exercise it). All 4 PRs carry the `-x`-style `(cherry picked from commit ...)` provenance trailer per the workflow. All 4 trackers (master + 25.2/25.1/25.0) advanced to `9babe7e7f6`.
