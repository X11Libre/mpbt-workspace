Subject: xf86int10.h: split public ABI from private internals
From: Discovery
Date: 2026-08-06T15:39:00+02:00
Status: done
Category: xserver
Priority: medium
Assigned-To: Discovery
Depends-On:
Blocks:
Noted-By: Discovery

Split xf86int10.h into public ABI (for DDX drivers) and private internals (xserver int10 module only).

Changes made:
1. Created hw/xfree86/int10/xf86int10_priv.h with all private content:
   - legacyVGARec / legacyVGAPtr typedef
   - All private macros (SYS_SIZE, V_BIOS, SEG_ADR, X86_*_MASK, MEM_*, etc.)
   - All private function declarations (MapCurrentInt10, xf86Int10ExecSetup, Int10Current, etc.)
2. Reduced include/xf86int10.h to public ABI only:
   - SEG_ADDR, SEG_OFF, SET_BIOS_SCRATCH, RESTORE_BIOS_SCRATCH macros
   - xf86Int10InfoRec / xf86Int10InfoPtr (full struct - used by 30+ drivers)
   - int10MemRec / int10MemPtr
   - Public _X_EXPORT functions: xf86InitInt10, xf86ExtendedInitInt10, xf86FreeInt10, xf86Int10AllocPages, xf86Int10FreePages, xf86int10Addr, xf86ExecX86int10
3. Updated all internal .c files to include xf86int10_priv.h instead of defining _INT10_PRIVATE
4. Updated os-support/linux/int10/linux.c and vm86/linux_vm86.c to include private header
5. Private header NOT installed to SDK (only public xf86int10.h is installed)

Verified:
- xserver builds with int10=x86emu (default)
- Public header compiles standalone (tested with minimal test program)
- Private header not installed to SDK
- No remaining _INT10_PRIVATE defines in codebase

Files modified:
- include/xf86int10.h (public ABI only)
- hw/xfree86/int10/xf86int10_priv.h (new, complete private definitions)
- hw/xfree86/int10/*.c (generic.c, helper_exec.c, helper_mem.c, stub.c, xf86int10.c, xf86x86emu.c)
- hw/xfree86/os-support/linux/int10/linux.c
- hw/xfree86/os-support/linux/int10/vm86/linux_vm86.c
