---
slug: xf86bigfont-resurrection-cleanup
title: "`xf86bigfont` resurrection & cleanup"
category: active
status: "Step 1 **done** — builds on all lanes again (#3202 **merged**: sysmacros + mingw fixes). #3205 **merged**: meson default-**off** restored + bigfont enabled only on the CI lanes (praetor: \"meson defaults nicht anfassen\"). #3206 backports both compile fixes to **release/25.2** (25.1/25.0 = older bigfont.c, N/A). #3201 (pagesize/CSRG cleanup) **merged** (rebased, all bigfont lanes green)."
doc_ref: "`BIGFONT.md`; PRs #3202 + #3205 (merged: CI builds bigfont on all lanes, default off), #3203 (dix ARRAY_SIZE guard, merged), #3201 (pagesize/CSRG, **merged**); branch `xlibre/bigfont-consolidate-cleanup` (ResetProc drop, no commit yet)"
migrated_from: 8cf8692b9f0057ffe44e793b35bcf7329da83d3f
---

Root causes: `sys/sysmacros.h` (5 BSD/macOS), `dix.h` `ARRAY_SIZE` redef (solaris), `geteuid`/`getegid`+unused-var (mingw). BSD/macOS compile-break → backport candidate. Later ideas in Parkplatz. **Competing proposal in flight, see next row:** praetor also wants a draft PR to remove `xf86bigfont` entirely — the two are deliberately parallel options to put before the community, not a contradiction to resolve here
