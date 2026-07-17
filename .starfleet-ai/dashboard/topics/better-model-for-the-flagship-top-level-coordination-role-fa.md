---
slug: better-model-for-the-flagship-top-level-coordination-role-fa
title: "Better model for the flagship/top-level coordination role (Enterprise) — faster interactive turnaround"
category: parked
noted_by: "praetor, 2026-07-06"
since: "2026-07-06"
migrated_from: 8cf8692b9f0057ffe44e793b35bcf7329da83d3f
---

Praetor wants to look for a model better suited to the flagship's job specifically: it only needs to coordinate/delegate (read the board, `tell`/`broadcast`, triage inbox directives, decide what to hand to which worker) — it does **not** do coding itself, so raw coding capability isn't the deciding factor there. Current setup uses whatever model the session was started with (no distinction between flagship and worker model choice today). Goal: pick a model/config for `run-flagship` that responds faster in back-and-forth interactive use, since coordination is latency-sensitive (the praetor is directly chatting with it) in a way batch worker sessions aren't. Nothing started — idea stage, explicitly "for later".
