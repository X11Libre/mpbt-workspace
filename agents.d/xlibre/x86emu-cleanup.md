---
slug: xlibre/x86emu-cleanup
title: "x86emu incremental cleanup"
---

# x86emu incremental cleanup

Tracking doc for the step-by-step tidy-up of `hw/xfree86/x86emu` (the old
SciTech realmode x86 emulator, built only as a static lib for the int10/vbe
backend — **not** part of the driver/NVIDIA ABI, so header/struct churn here is
ABI-safe). Work happens on the `wip/x86emu` branch; each step is its own
reviewable commit / master-PR candidate.

## Done (on wip/x86emu)

- **drop unused `validate.c`** — standalone dev harness with its own `main()`,
  never in `meson.build`, referenced by nothing.
- **drop dead C++ build support from headers** — the `extern "C"` linkage guards
  in decode.h/fpu.h/prim_ops.h/regs.h/x86emui.h/x86emu.h, plus the C++ branches of
  `_INLINE` (always `static` in C) and `X86EMU_UNUSED` (always `(v)` in C). Never
  built as C++.
- **drop dead Watcom-specific code** — deleted `prim_asm.h` (its entire body was
  `#ifdef __WATCOMC__` `#pragma aux` inline asm; nothing includes it once
  validate.c is gone), and removed the `#ifdef PACK`/`#ifdef END_PACK`
  `#pragma PACK` struct-packing blocks (PACK/END_PACK never defined).
- **drop vestigial `X86API`/`X86APIP`** DOS calling-convention macros (empty /
  `*`) — expanded in place in x86emu.h/x86emui.h/sys.c.
- **fix 32-bit MUL/DIV/IDIV + drop `__HAS_LONG_LONG__`** (see landmine below —
  it turned out to be a real bugfix, **backport candidate**). Removed the macro
  everywhere; mul_long/div_long/idiv_long now use native 64-bit arithmetic with
  correct #DE overflow detection; rdtsc uses a 64-bit counter. Validated against
  a 128-bit x86 reference over 60M inputs (0 mismatches); harness kept at
  `scratchpad/llfix.c` (and `llcmp.c` = the original both-paths divergence
  survey).
- **drop never-built x87 FPU emulation skeleton** — the `#ifdef
  X86EMU_FPU_PRESENT` branches in fpu.c (x87 opcodes 0xD8-0xDF) called ~96
  `x86emu_fpu_*()` routines defined nowhere in the tree (would not even link if
  enabled) and X86EMU_FPU_PRESENT has no build option; only the decode+skip
  stubs ever ran. Dropped the dead branches (behavior unchanged) and the dead
  `#ifdef X86_FPU_SUPPORT` register-file block in fpu_regs.h (kept the live
  DECODE_PRINTINSTR* debug macros). 541 lines removed.

## Submitted as master PRs

- **#3149** — x86emu: dead-code cleanup (validate.c, C++, Watcom, X86API).
- **#3150** — x86emu: drop `__HAS_LONG_LONG__` and fix 32-bit MUL/DIV/IDIV.
  The MUL/DIV/IDIV commit is the **backport candidate**.
- **#3151** — x86emu: drop never-built x87 FPU emulation skeleton. Lightly
  overlaps #3149 in fpu_regs.h (both remove the Watcom PACK pragmas there), so
  it should merge after #3149 or take a trivial rebase.

## Confirmed live — do NOT remove

- **`NO_SYS_HEADERS`** — still defined by the int10 x86emu build
  (`hw/xfree86/int10/meson.build` adds `-DNO_SYS_HEADERS`). The
  `#ifndef NO_SYS_HEADERS #include <sys/...>` guards in types.h / x86emui.h /
  debug.c / sys.c are real.
- **`prim_x86_gcc.h`** — the live GCC inline-asm counterpart, included by
  prim_ops.c; its `__GNUC__`/`__i386__`/`__PIC__` conditionals are arch-relevant.

## ✅ RESOLVED (was a landmine) — `__HAS_LONG_LONG__`

> Done in commits *"fix 32-bit MUL/DIV/IDIV using native 64-bit arithmetic"* and
> *"use a 64-bit RDTSC counter"*. The mul/div/idiv part is a genuine correctness
> fix (wrong EDX from MUL; broken DIV/IDIV overflow detection) and is a
> **backport candidate** for the maintained release lines — applicability per
> branch still to be confirmed. The analysis that established this is kept below.

### Why it was NOT a mechanical cleanup

`__HAS_LONG_LONG__` is never defined in this build, so the **manual 16-bit-limb
fallback** branches are what currently compile/run; the native `u64`/`s64`
branches are dead. It is tempting to "just delete the dead macro and keep the
u64 path" (u64 is always available via stdint), but the two paths are **not
equivalent** — verified by fuzzing both branches against each other over 20M
random + edge inputs (`scratchpad/llcmp.c`):

| routine            | result |
|--------------------|--------|
| `imul_long_direct` | equivalent (0 diffs) — safe either way |
| `mul_long`         | manual path has a **high-word carry bug** (e.g. `0xffffffff * 0x7fffffff` → EDX `7ffefffe`, should be `7ffffffe`); u64 path is correct |
| `idiv_long`        | paths diverge in ~13.5M/20M cases; manual path broadly wrong; **u64 path also buggy** — `abs(div)` truncates the s64 quotient to `int` so the overflow→#DE check is wrong, and `INT64_MIN / -1` SIGFPEs before the check |
| `div_long`         | paths diverge in ~6.9M/20M cases (same shape) |

So switching this macro **changes emulator arithmetic semantics and, for MUL,
is a real bugfix** — while the DIV/IDIV paths need genuine correctness work on
*both* sides (the post-division overflow check is wrong in the u64 path too).
This deserves its own dedicated, separately-reviewed correctness commit(s) with
the fuzz harness as evidence — **not** a "drop dead macro" cleanup. Left
untouched for now. (Real-hardware reference: 32-bit MUL/IMUL write the full
64-bit product to EDX:EAX; DIV/IDIV raise #DE when the quotient doesn't fit 32
bits or on divide-by-zero.)

## Candidate next steps (not yet done)

- **`types.h` u8/u16 kludge** — the `#define u8 x86emuu8` … rename dance + then
  `typedef uint8_t u8`; could move fully onto stdint types, but that's a treewide
  rename across all the .c — do as its own large mechanical pass.
- **`#ifdef DEBUG` (45×) + `DB()` macro** — functional debug instrumentation,
  low priority.
- **`ops.c`** (~12.4k lines) splitting — large diff, no functional gain; likely
  leave.
