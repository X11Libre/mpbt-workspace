Title: "x86emu `INTR_BOOL_TO_U64`/carry-macro cleanup"
Category: active
Status: "Paused mid-cleanup — found real semantic differences between the two code paths"
Created-By: ""
Created: ""
Assigned-To: ""
Doc-Ref: "`X86EMU-CLEANUP.md`"
Migrated-From: 8cf8692b9f0057ffe44e793b35bcf7329da83d3f
Tags: "xlibre"
Slug: x86emu-intrbooltou64-carry-macro-cleanup

Both DIV/IDIV paths have independent correctness bugs (see Parkplatz); needs its own reviewed fix, not a drop-in
