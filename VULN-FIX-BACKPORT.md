# Backport applicability: `wip/ext-handler-vulns` → release/25.0 and master

Checked each of the 20 fixes against `origin/release/25.0` (65998b1c4c) and
`origin/master` (b158f35a6d) by inspecting the actual code on each branch.

Legend: **APPLIES** = same bug present & unfixed (port it) · **FIXED** = already
fixed there · **N/A** = code absent or not vulnerable (different/safe code).

| # | Fix (commit) | release/25.0 | master |
|---|--------------|:---:|:---:|
| 1 | xtest stack OOB write (`b3c7f5f5c4`) | **APPLIES** | **APPLIES** |
| 2 | glx RenderLarge OOB read (`6575254bdf`) | **APPLIES** | **APPLIES** |
| 3 | glx CreateContextAttribsARB int overflow (`07e44c4d10`) | **APPLIES** | **APPLIES** |
| 4 | xfixes swap-before-validate (`4b5deb021d`) | N/A (not vuln) | FIXED |
| 5 | xipassivegrab double `*4` (`b7cb863f9f`) | **APPLIES** | **APPLIES** |
| 6 | xvmc NULL deref (`7b4e98c0a7`) | **APPLIES** | **APPLIES** |
| 7 | xichangecursor NULL deref (`9fcefaca33`) | **APPLIES** | **APPLIES** |
| 8 | queryst NULL deref on BadAccess (`87c2917231`) | **APPLIES** | **APPLIES** |
| 9 | xkmread indicator bounds (`a05b1cab2c`) | **APPLIES** | **APPLIES** |
| 10 | rrsdispatch wrong handler (`9cd282e492`) | **APPLIES** (live!) | N/A (refactored) |
| 11 | present missing SwapRestL (`4f33d0b422`) | **APPLIES** | **APPLIES** |
| 12 | getfctl padding leak (`425b9944aa`) | N/A (calloc) | **APPLIES** |
| 13 | rrprovider padding leak (`9fb389bcfb`) | N/A (calloc) | **APPLIES** |
| 14 | xvdisp padding leak (`b1e1d36e4f`) | N/A (`={0}`) | **APPLIES** |
| 15 | QueryColors padding leak (`3f5d0b9e84`) | N/A (calloc) | **APPLIES** |
| 16 | vidmode gamma ramp leak (`66770d6a64`) | N/A (calloc) | **APPLIES** |
| 17 | render QueryPictFormats/Filters leak (`a6d4f4047b`) | N/A (calloc) | **APPLIES** |
| 18 | rrscreen name-pad leak (`88c2f123d4`) | N/A (calloc) | **APPLIES** |
| 19 | Xi reply-buffer leaks ×4 (`46d179e304`) | N/A (calloc) | **APPLIES** |
| 20 | xkb GetMap pad leak (`d2478779db`) | N/A (calloc) | **APPLIES** |

**Totals:** release/25.0 → **10 apply**; master → **18 apply**.

## Key framing

- **The entire uninitialized-memory-disclosure class (#12–#20) is a 25.1+ regression.**
  On 25.0 those handlers build the reply in a `calloc`'d buffer (or a `{0}`-initialized
  stack struct, for xvdisp), so the padding is already zero — no leak. The leaks were
  *introduced* when the reply path was rewritten on top of the new non-zeroing
  `x_rpcbuf_reserve()` API (which doesn't exist on 25.0). **master inherited the same
  regression** → all 9 apply there.

- **Memory-safety / NULL / logic bugs (#1–#3, #5–#11) are older and shared.** They apply to
  both 25.0 and master, with two exceptions:
  - **#4 xfixes swap order**: 25.0 uses the classic split `SProc*` dispatch that swaps
    `nbytes` *before* validation (not vulnerable); master already fixed it via
    `X_REQUEST_FIELD_CARD16(nbytes)` before `REQUEST_FIXED_SIZE`. The bug is unique to the
    25.1 line (commit `8336ad8e6f` inlined the swap in the wrong order).
  - **#10 rrsdispatch wrong handler**: **live on 25.0** (`rrsdispatch.c` is compiled and
    `SProcRRDispatch` is registered) — a real broken-for-swapped-clients bug there. On 25.1
    the file is dead (not compiled), and on master it's gone (swapping handled inline in
    `rrdispatch.c`, correctly).

## Caveats / overlap with in-flight work

`origin/release/25.0` has many security hardening PR branches already in flight
(`origin/pr/release/25.0-*`), some in adjacent areas — e.g. `...readxkmgeometry`
(sibling of #9, different function), `...xipassivegrab-handling-of-keycodes-255`
(#5 area, different aspect), `...zero-out-structs-...-padding`, `...present-fix-missing-
byte-swaps-in-sproc-present-pixmap` (#11 area, the non-synced variant). Check for
overlap before porting; the fixes here are distinct functions/aspects, but coordinating
avoids duplicate or conflicting patches.

(All assessments are against the branch tips listed above; not yet ported or pushed.)
