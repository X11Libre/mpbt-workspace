Title: "DESQview/X on FreeDOS in QEMU - Auto-boot X server"
Category: active
Kind: "task"
Status: "offen"
Created-By: "Yamato"
Created: "2025-07-16T19:42:00Z"
Assigned-To: "—"
Doc-Ref: ""
Tags: "desqview"
Slug: task-desqview-x-on-freedos-in-qemu-auto-boot-x-server

Install DESQview/X on FreeDOS QEMU VM, create automated image that boots directly into X server.

## Current State
- FreeDOS boots successfully (FDCONFIG.SYS -> FDAUTO.BAT)
- DESQview/X installed (9 floppies processed)
- Original SERVER.COM (256-byte stub) + SERVER.EXE (42KB PKLITE v1.13) intact
- SERVER.EXE decompressed to 67,572 bytes (/tmp/SERVER_UNP.PATCHED)
- DESQCHK.COM TSR created - hooks INT 21h/2Bh (DESQview check), configurable AL=0/1
- CWSDPMI.EXE available in FreeDOS packages (C:\FREEDOS\BIN\CWSDPMI.EXE)

## Working Config (/tmp/freedos_clean.qcow2)
- FDCONFIG.SYS: SHELL=C:\FreeDOS\BIN\COMMAND.COM /P=C:\FDAUTO.BAT
- FDAUTO.BAT: runs CWSDPMI.EXE -p -s- -> DESQCHK.COM -> SERVER.COM /AbortIfNoQemm:N
- DESQCHK.COM patched to return AL=0 (not DESQview) -> server takes non-DESQview path
- Server type in DVX.CFG: EGA

## Achievements
+ FreeDOS boots, DESQview/X installed
+ SERVER.EXE PKLITE decompressed + analyzed
+ DESQCHK.COM TSR working (INT 21h/2Bh hook)
+ CWSDPMI loads as DPMI host

## Blocker
Server runs but crashes with divide-by-zero errors at 10C4 and spurious interrupts (FFE? 2D25).
CWSDPMI's DPMI is insufficient - server needs full VCPI/VCPI environment.
QEMM386 fails in QEMU (no protected mode, no VCPI).

## Web Research Findings
1. **CWSDPMI limitations** - CWSDPMI is a 32-bit only DPMI server, doesn't support 16-bit DPMI apps. Known to not
provide full VCPI services needed by some apps. CWSDPMI r7 docs: "If you are using an EMM provider for UMBs, CWSDPMI
will need to use VCPI. VCPI memory prevents usage of 4MB pages." But QEMM386 (EMM provider) fails in QEMU - never enters
protected mode, no VCPI.

2. **HX DPMI / HDPMI32 recommended** - Multiple sources (DOSBox-X issue #3844, FreeDOS mailing lists) confirm HX DPMI /
HDPMI32 works where CWSDPMI fails. HX DPMI is a full DPMI host that can provide VCPI services. CWSDPMI "does not support
16-bit DPMI applications, or DPMI applications requiring a built in extender." The DESQview/X server likely needs more
complete DPMI/VCPI.

3. **HDPMI32 available in FreeDOS** - FreeDOS PACKAGES includes HDPMI32 (in FREEDOS/PACKAGES). Should be installable via
FDNPKG or manually copied. **BUT: HDPMI32 not found in current FreeDOS image - only CWSDPMI is installed.**

4. **CWSDPMI -p persistent mode** - Running CWSDPMI -p makes it persistent TSR (can load in UMBs with LH). Tested with
-p -s- (no swap). Still crashes.

5. **QEMU TCG divide-by-zero bug** - Known QEMU TCG bug (commit 975af797f1e) causes crashes with floating-point
exceptions. The divide-by-zero at 10C4 may be related to TCG x87 handling. Workaround: use -enable-kvm if available, or
DOSBox-X.

6. **DOSBox-X provides better DPMI/VCPI** - DOSBox-X has built-in DPMI/VCPI support that works better than QEMU's raw
TCG. But needs sudo to install (not available).

## Crash Analysis (Latest - 2025-07-17)
- Crash: divide-by-zero at runtime address 077F:10C4
- Disassembly at 0x10C4: push word ptr es:[bx+4] etc. - not a DIV instruction
- DIV found at 0x1ACD: idiv cx but not at crash site
- Spurious interrupts: "FFE? 2D25" repeated
- Zero-divide at 10C4 repeated multiple times
- Stack: 6149 6149 0169 repeated
- CWSDPMI -p -s- tested, still crashes

## HDPMI32 Status
- Not found in current FreeDOS image packages
- Only CWSDPMI is available in FREEDOS/BIN
- PACKAGES LST doesn't show HDPMI32

## Next Steps
1. Try DOSBox-X (better DPMI/VCPI) - needs sudo to install
2. Find HDPMI32 from external source / FDNPKG
3. Try CWSDPMI with different parameters (-x to disable DPMI 1.0 extensions)
4. Patch divide-by-zero in server at runtime address 10C4
5. Try different server type in DVX.CFG (MONO, etc.)
6. Try QEMU with -enable-kvm if available

## Key Files
- /tmp/freedos_clean.raw / .qcow2 - latest working image (CWSDPMI -p -s-)
- /tmp/DESQCHK.COM - TSR hook (AL=0)
- /tmp/SERVER_UNP.PATCHED - decompressed server (67,572 bytes)
- /tmp/SERVER_UNP_PATCHED.EXE - MZ EXE with original CS:IP
- /tmp/freedos_patched.raw - clean base image (Jul 14)

## To Resume
1. Kill any qemu-system: kill $(pgrep qemu-system)
2. Boot: nohup qemu-system-i386 -hda /tmp/freedos_clean.qcow2 -m 16 -serial file:/tmp/serial.log -monitor
tcp:127.0.0.1:4445,server,nowait -vnc :1 &
3. Try: DOSBox-X (sudo), HDPMI32 external, CWSDPMI -x, patch divide-by-zero, different server type
