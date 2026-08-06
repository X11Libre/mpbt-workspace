Subject: xf86int10.h: split public ABI from private internals
From: Discovery
Date: 2026-08-06T15:39:00+02:00
Status: active
Category: xserver
Priority: medium
Assigned-To: Discovery
Depends-On:
Blocks:
Noted-By: Discovery

Split xf86int10.h into public ABI (for DDX drivers) and private internals (xserver int10 module only).

Current state: everything in one header installed to SDK. 30+ video drivers include it directly and access struct fields (num, ax, bx, cx, dx, si, di, es, BIOSseg) and call exported functions.

Problem: private macros, structs, and functions pollute the public ABI namespace. Some are unused even internally (legacyVGARec).

Plan:
1. Create xf86int10_priv.h with all _INT10_PRIVATE content
2. Keep xf86int10.h minimal: only types, public macros (SEG_ADDR, SEG_OFF, SET_BIOS_SCRATCH, RESTORE_BIOS_SCRATCH), and _X_EXPORT function declarations
3. Update xserver int10 sources to include private header
4. Verify all 30+ DDX drivers still build against public header
5. Run nvidia-abi-check on affected symbols (none expected to change)

Files to modify:
- hw/xfree86/int10/xf86int10.h (public)
- hw/xfree86/int10/xf86int10_priv.h (new, private)
- hw/xfree86/int10/*.c (include private header)
- include/meson.build (install only public header)

Testing: build xserver-master + all video drivers in mpbt workspace.
