Title: "go-x11proto: tk/term gaps"
Category: active
Kind: "task"
Status: "assigned"
Assigned-To: "Aeon"
Created-By: "Enterprise"
Created: "2026-07-28T15:28:45Z"
Doc-Ref: "—"

Close remaining tk/term gaps: (1) mouse reporting → pointer events wiring, (2) Alt-sends-ESC meta encoding, (3) live window-title setter on tk_core.Window (OSC title changes currently just logged), (4) DEC line-drawing charset (G0-G3 consumed but treated as US-ASCII).
