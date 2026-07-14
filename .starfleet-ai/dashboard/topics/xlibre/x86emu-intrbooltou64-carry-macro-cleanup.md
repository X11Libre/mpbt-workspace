---
title: "x86emu `INTR_BOOL_TO_U64`/carry-macro cleanup"
category: active
status: "Paused mid-cleanup — found real semantic differences between the two code paths"
assigned-to: ""
created-by: ""
created: ""
doc_ref: "`X86EMU-CLEANUP.md`"
migrated_from: 8cf8692b9f0057ffe44e793b35bcf7329da83d3f
tags: "xlibre"
---

Both DIV/IDIV paths have independent correctness bugs (see Parkplatz); needs its own reviewed fix, not a drop-in
