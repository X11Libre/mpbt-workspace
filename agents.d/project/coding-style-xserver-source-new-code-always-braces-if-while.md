---
title: "Coding style (xserver source) — new code always braces if/while/for bodies"
order: 190
---

## Coding style (xserver source) — new code always braces if/while/for bodies

**Standing policy, confirmed 2026-07-03: always wrap `if`/`while`/`for`/`else` bodies in `{ }`,
even a single-statement body.** Two tracks, both active:

1. **All new/touched code, from now on, unconditionally.** Any agent adding or editing an
   `if`/`while`/`for`/`else` body — regardless of how it got there (a bugfix, a backport, a
   one-line tweak inside a function that already has unbraced bodies elsewhere) — must brace it.
   This was already the rule since 2026-07-01 (PR #3199: `os/Xtranssock.c`'s new
   `unix_socket_is_live()` and the `hostx.c` NULL-check fix were both corrected from unbraced to
   braced per this rule) — reconfirmed 2026-07-03 as permanent project policy, not a one-off.
2. **Successive conversion of existing unbraced bodies, in small digestible chunks.** The
   existing tree is inconsistent (plenty of unbraced single-statement bodies, e.g.
   `os/Xtranssock.c`'s `set_sun_path()`: `if (!port || !*port || !path)` on one line, a
   tab-indented `return -1;` on the next, no braces). This is **not** a mass-reformat — don't
   touch the whole tree in one commit/PR. Instead, treat it as an ongoing background initiative:
   when picking up unrelated work in a file that has unbraced bodies nearby, or in a dedicated
   session with spare capacity, convert a **small, self-contained batch** (e.g. one file, or a
   handful of related functions) into its own PR, purely mechanical (brace-only, no other
   changes mixed in, so the diff is trivially reviewable). Track progress as the
   "if/while/for brace-everywhere conversion" theme in `DASHBOARD.md` (Aktive Themen) rather than
   letting each batch's PR be the only record — update that row each session a batch lands so
   the initiative doesn't silently stall between sessions.

Indentation inside a body — braced or not — still follows whatever the surrounding function already
uses; in older files like `Xtranssock.c` that's a single **tab** per nesting level (mixed with
4-space alignment for wrapped continuation lines), not 4 spaces. Match the immediate surrounding
code, don't impose a new indent style along with the new braces.

Brace *placement* (`if (...) {` same line vs. `if (...)\n{` own line) is genuinely mixed
throughout the tree with no single dominant convention even within one file — match whichever
style the immediately surrounding code already uses; either is acceptable for new code.

This note lives here for now; consider promoting xserver-specific coding-style rules (this one and
any future ones) to a dedicated document inside the xserver tree itself (e.g. `CODING_STYLE.md`)
once there are enough of them to warrant it, rather than growing an unbounded style section in this
workspace-level file.
