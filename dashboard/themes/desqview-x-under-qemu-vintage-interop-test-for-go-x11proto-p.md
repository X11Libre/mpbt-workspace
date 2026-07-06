---
slug: desqview-x-under-qemu-vintage-interop-test-for-go-x11proto-p
title: "DESQview/X (X11R5 DOS server, Quarterdeck, early 90s) under QEMU — vintage interop test for go-x11proto/pyxtest"
category: active
status: "**Started 2026-07-06 (Pegasus), per praetor request (Enterprise m0075). Delegated to a background agent immediately after claiming — see updates below as they land.**"
doc_ref: "`_WORK_/desqview-x/` (gitignored, not an mpbt solution — just VM/notes storage)"
migrated_from: 8cf8692b9f0057ffe44e793b35bcf7329da83d3f
---

Praetor interest: curiosity + genuine wish to test our client tools/suite against real X11R5. Phase plan from m0075: (1) proof-of-life — FreeDOS + DESQview + DESQview/X booting under QEMU, DOS-side TCP/IP (mTCP recommended, works well with QEMU's emulated ne2000 NIC) + packet driver configured so the X server is reachable over TCP from the host; verify with a simple `xdpyinfo`-style connection from the host against the VM's IP:0 first. (2) only once (1) works: run our tools, with realistic expectations — X11R5 predates RandR/XKB/GLX/Present/XInput2/Sync/Xinerama entirely, so most pyxtest cases will fail at the extension-query step before even starting; the meaningful first test is go-x11proto's base connection/handshake + simple core-protocol requests (CreateWindow, MapWindow, GetProperty), since the wire format has barely changed since X11R4. Software is abandonware (DESQview/DESQview/X, Quarterdeck, defunct) — normal retrocomputing practice to source from vetusware.com/WinWorldPC, but document exact source + version here once downloaded (not done yet). Coordinate with Potemkin's DASHBOARD.md redesign (m0073, `DASHBOARD-RESTRUCTURE.md`) on where this row lands if/when the migration actually happens — not yet, as of this entry (still one monolithic file).
