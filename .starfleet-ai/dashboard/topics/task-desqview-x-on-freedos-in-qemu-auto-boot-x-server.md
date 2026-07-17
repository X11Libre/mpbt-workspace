---
slug: task-desqview-x-on-freedos-in-qemu-auto-boot-x-server
title: "DESQview/X on FreeDOS in QEMU - Auto-boot X server"
category: active
kind: task
status: open
created-by: Yamato
created: 2026-07-16T17:40:54Z
assigned-to: —
doc_ref: "—"
---

Install DESQview/X on FreeDOS QEMU VM, create automated image that boots directly into X server.

**Current State:**
- FreeDOS boots successfully (FDCONFIG.SYS → FDAUTO.BAT)
- DESQview/X installed (9 floppies processed)
- Original SERVER.COM (256-byte stub) + SERVER.EXE (42KB PKLITE v1.13) intact
- SERVER.EXE decompressed to 67,572 bytes (/tmp/SERVER_UNP.PATCHED)
- DESQCHK.COM TSR created - hooks INT 21h/2Bh (DESQview check), configurable AL=0/1
- CWSDPMI.EXE available in FreeDOS packages (C:\FREEDOS\BIN\CWSDPMI.EXE)

**Working Config (/tmp/freedos_clean.qcow2):**
- FDCONFIG.SYS: SHELL=C:\FreeDOS\BIN\COMMAND.COM /P=C:\FDAUTO.BAT
- FDAUTO.BAT: runs CWSDPMI.EXE → DESQCHK.COM → SERVER.COM /AbortIfNoQemm:N
- DESQCHK.COM patched to return AL=0 (not DESQview) → server takes non-DESQview path
- Server type in DVX.CFG: EGA

**Achievements:**
✅ FreeDOS boots, DESQview/X installed
✅ SERVER.EXE PKLITE decompressed + analyzed
✅ DESQCHK.COM TSR working (INT 21h/2Bh hook)
✅ CWSDPMI loads as DPMI host

**Blocker:**
Server runs but crashes with divide-by-zero errors at 10C4 and spurious interrupts.
CWSDPMI's DPMI is insufficient - server needs full VCPI/VCPI environment.
QEMM386 fails in QEMU (no protected mode, no VCPI).

**Next Steps:**
1. Try DOSBox-X (better DPMI/VCPI) - needs sudo to install
2. Try HDPMI32 instead of CWSDPMI
3. Patch divide-by-zero in server at runtime address 10C4
4. Try different server type in DVX.CFG

**Key Files:**
- /tmp/freedos_clean.raw / .qcow2 - latest working image
- /tmp/DESQCHK.COM - TSR hook (source in /tmp/DESQCHK.COM)
- /tmp/SERVER_UNP.PATCHED - decompressed server (67,572 bytes)
- /tmp/SERVER_UNP_PATCHED.EXE - MZ EXE with original CS:IP
- /tmp/freedos_patched.raw - clean base image (Jul 14)

**To Resume:**
1. Kill any qemu-system: kill $(pgrep qemu-system)
2. Boot: nohup qemu-system-i386 -hda /tmp/freedos_clean.qcow2 -m 16 -serial file:/tmp/serial.log -monitor tcp:127.0.0.1:4445,server,nowait -vnc :1 &
3. Test different approaches from blocker list above
