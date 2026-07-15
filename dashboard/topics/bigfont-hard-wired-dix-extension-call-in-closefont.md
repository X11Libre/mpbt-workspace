---
slug: bigfont-hard-wired-dix-extension-call-in-closefont
title: "bigfont: hard-wired dix→extension call in `CloseFont()`"
category: parked
noted_by: "`BIGFONT.md`"
since: "2026-07-01"
migrated_from: 8cf8692b9f0057ffe44e793b35bcf7329da83d3f
---

`dix/dixfonts.c:539` directly calls `XF86BigfontFreeFontShm` under `#ifdef XF86BIGFONT`. Consider decoupling (per-font free-callback / registration) so dix doesn't hard-reference the extension
