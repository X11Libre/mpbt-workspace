---
slug: propose-removing-xf86bigfont-extension-entirely
title: "Propose removing `xf86bigfont` extension entirely"
category: active
status: "**Draft PR opened + rebased** (conflicts resolved after the cleanup PRs merged), awaiting community discussion"
doc_ref: "PR #3208 (draft), branch `xlibre/remove-xf86bigfont`"
migrated_from: 8cf8692b9f0057ffe44e793b35bcf7329da83d3f
---

Praetor request, 2026-07-01. Runs **in parallel** with the resurrection/cleanup effort above (same extension, opposite direction) — intentional, lets the community weigh "fix the bit-rot" vs "just drop it" with a concrete PR to react to, not just discussion in the abstract. Removed the whole `Xext/xf86bigfont/` dir, its meson option/wiring, the `mi/miinitext.c` init hook, both direct dix call-sites (`dix/dixfonts.c` `CloseFont()`, `os/utils.c` `AbortServer()`), the reserved extension-opcode slot, protocol-version constants, and other stray refs (full sweep, see PR body). Build-verified: `meson setup` configures clean, `ninja hw/vfb/Xvfb hw/xnest/Xnest hw/xfree86/Xorg` links. Note: PR #3202 (enable-by-default) is **already merged** into master, so this removal supersedes/reverts its effect as part of the same diff; #3201/#3205/#3206/consolidate-cleanup become moot if this direction is chosen — left untouched per instructions, not a decision made here
