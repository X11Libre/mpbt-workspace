---
slug: convince-other-contributors-to-adopt-mpbt-workspace
title: "Convince other contributors to adopt `mpbt-workspace`"
category: active
status: "Idea stage — direction being discussed, nothing written yet"
doc_ref: "this DASHBOARD.md entry (no doc yet)"
migrated_from: 8cf8692b9f0057ffe44e793b35bcf7329da83d3f
---

Goal (praetor, 2026-07-01): move contributors off "clone xserver standalone + manual meson" onto mpbt (multi-release-line builds, shared tooling). Checked 2026-07-01: **no existing docs anywhere** — `X11Libre/xserver` wiki (`Building-XLibre.md`) only describes the manual single-clone build, no mpbt mention in any of its 16 pages; `X11Libre/mpbt-workspace` wiki is enabled but has **zero pages** (wiki git repo doesn't exist yet); upstream `metux/mpbt` wiki likewise empty. Landing spot should probably be `Building-XLibre.md` (a pointer, not a rewrite), linking to real content. **Open question, not decided:** does that content live as a *wiki page* (which repo's wiki — xserver's, since that's what contributors already browse, or mpbt-workspace's?) or as a plain doc/README section **inside `mpbt-workspace` itself**, linked from the xserver README/wiki instead of duplicating another wiki? Related: the earlier `.vscode/tasks.json`-in-xserver discussion (a multi-root `.code-workspace` in mpbt-workspace only pays off once this migration is real)
