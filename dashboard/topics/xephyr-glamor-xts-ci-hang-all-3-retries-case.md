---
slug: xephyr-glamor-xts-ci-hang-all-3-retries-case
title: "`xephyr-glamor / XTS` CI hang, all-3-retries case"
category: active
status: "**Investigated — looks like a one-off, not a new persistent regression**"
doc_ref: "PR #3203 job `xserver-build-ubuntu-debug` run 28522256520; PR #3204 (NULL-deref fix, see below)"
migrated_from: 8cf8692b9f0057ffe44e793b35bcf7329da83d3f
---

2026-07-01: `xserver:xephyr-glamor / XTS` hit the full `1200s` `TIMEOUT` on all 3 retries (~64min) on PR #3203 (unrelated `ARRAY_SIZE` guard). Checked ~60 recent `build-xserver.yml` runs: this is the **only** one showing "all 3 retries exhausted" — not widespread. Root mechanism confirmed: `test/meson.build`'s `timeout: 1200` on the `XTS` test is the *only* timeout in play — the piglit invocation (`xephyr-glamor-piglit.sh` → `run-piglit.sh`) passes no per-test `-t` flag, so a single wedged XTS subtest blocks silently for the full 1200s with zero progress output (meson buffers all test stdout until completion/kill) — **which specific subtest wedged could not be identified** from available CI logs. Plausibly related-but-distinct from the crash (not hang) that motivated PR #3204's `hostx.c` NULL-deref fix — two other same-day runs hit an actual `Xephyr … Segmentation fault` in `go-xts` (not the piglit `XTS` test) under `-glamor +byteswappedclients`, i.e. same general "Xephyr+glamor concurrent-load fragility" area, different code path/symptom. No suspicious recent glamor/kdrive/piglit-wrapper commit or runner/mesa version bump found. **Follow-up worth doing but not yet started:** give piglit an actual per-test timeout (`-t`) so a future wedge fails fast with a subtest name instead of blocking the whole suite for 1200s blind
