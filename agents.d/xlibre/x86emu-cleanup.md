---
slug: xlibre/x86emu-cleanup
title: "x86emu incremental cleanup — safety reference"
---

# x86emu incremental cleanup — Safety Reference

**Vollständiger Inhalt: Skill `x86emu`** (`.claude/skills/x86emu/SKILL.md`).

Dieses Fragment ist nur noch ein Verweis-Stub — der Inhalt (NO_SYS_HEADERS/prim_x86_gcc.h
live-Marker, `__HAS_LONG_LONG__`-Landmine, Backport-Kandidat) wurde vollständig in den
`x86emu`-Skill migriert.

**Kurzregeln:** `NO_SYS_HEADERS` und `prim_x86_gcc.h` sind live — nie entfernen. Der
`__HAS_LONG_LONG__`-Switch ist ein **Correctness-Bugfix** (u64 vs. 16-Bit-Limb NICHT äquivalent),
kein Mechaanisches Cleanup — eigener Commit mit Fuzz-Harness als Evidenz.