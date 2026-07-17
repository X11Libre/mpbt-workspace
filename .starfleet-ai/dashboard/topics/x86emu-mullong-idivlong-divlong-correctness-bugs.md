---
slug: x86emu-mullong-idivlong-divlong-correctness-bugs
title: "x86emu `mul_long`/`idiv_long`/`div_long` correctness bugs"
category: parked
noted_by: "`X86EMU-CLEANUP.md`"
since: "2026 (fuzz run)"
migrated_from: 8cf8692b9f0057ffe44e793b35bcf7329da83d3f
---

Manual-path high-word carry bug in `mul_long`; u64-path overflow check wrong in `idiv_long`/`div_long`, `INT64_MIN / -1` SIGFPEs. Needs a dedicated, separately-reviewed correctness commit + the fuzz harness (`scratchpad/llcmp.c`, not checked in) as evidence
