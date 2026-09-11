---
name: x86emu
description: "x86emu incremental cleanup — safety reference for hw/xfree86/x86emu (SciTech realmode x86 emulator, int10/vbe backend). Use when working on wip/x86emu, cleaning up x86emu source, deciding whether a x86emu macro/symbol is live, or preparing a x86emu master-PR/backport."
---

# x86emu incremental cleanup — Safety Reference

Tracking doc for the tidy-up of `hw/xfree86/x86emu` (SciTech realmode x86
emulator, static lib for the int10/vbe backend — NOT part of the driver/NVIDIA
ABI, so header/struct churn is ABI-safe). Work on `wip/x86emu`; each step is
its own reviewable commit / master-PR candidate.

**Aktive Arbeit/Status:** siehe Dashboard-Topics
`xlibre/x86emu-*` (intrbooltou64, mullong-idivlong-divlong, ifdef-debug).
**Vollständiges Tracking:** siehe Git-History der Branch `wip/x86emu` + PRs
#3149/#3150/#3151 (dead-code cleanup, `__HAS_LONG_LONG__`+MUL/DIV/IDIV-Fix,
x87-FPU-Skeleton). Die ausführliche Fuzzer-Analyse liegt bei
`scratchpad/llfix.c`/`llcmp.c`.

## Confirmed live — do NOT remove

- **`NO_SYS_HEADERS`** — still defined by the int10 x86emu build
  (`hw/xfree86/int10/meson.build` adds `-DNO_SYS_HEADERS`). The
  `#ifndef NO_SYS_HEADERS #include <sys/...>` guards in types.h / x86emui.h /
  debug.c / sys.c are real.
- **`prim_x86_gcc.h`** — the live GCC inline-asm counterpart, included by
  prim_ops.c; its `__GNUC__`/`__i386__`/`__PIC__` conditionals are arch-relevant.

## ⚠️ Landmine — `__HAS_LONG_LONG__` (backport candidate, handle with care)

The MUL/DIV/IDIV fix (native u64/s64 arithmetic, correct #DE overflow detection)
is a genuine **correctness bugfix** and a **backport candidate** for the release
lines — applicability per branch still to be confirmed. **DON'T** treat the dead
`__HAS_LONG_LONG__` macro as a "mechanical cleanup": the manual 16-bit-limb
fallback and the u64 path are **NOT equivalent** (fuzzed over 20M inputs):

| routine            | result |
|--------------------|--------|
| `imul_long_direct` | equivalent (0 diffs) — safe either way |
| `mul_long`         | manual path has high-word carry bug; u64 path correct |
| `idiv_long`/`div_long` | both paths buggy (overflow→#DE check + `INT64_MIN/-1` SIGFPE) |

Switching the macro **changes emulator arithmetic semantics** — deserves its own
correctness commit(s) with the fuzz harness as evidence, not a cleanup.