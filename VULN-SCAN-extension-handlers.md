# XLibre xserver — Extension Request-Handler Vulnerability Scan

**Target:** `sources/xlibre/xserver` @ `release/25.1` (08e840dfb7)
**Scope:** client-facing `Proc*`/`SProc*` request handlers in Xext, Xi, render, randr,
glx, dbe, record, xfixes, composite, present, dri3, xkb.
**Method:** 35 parallel finder agents → each candidate independently re-verified by 2
adversarial reviewers reading the actual source. 19 candidates raised, **15 survived**,
4 rejected.
**Date:** 2026-06-11

> Several findings are XLibre-introduced regressions (git history cited in-line):
> the xfixes swap-ordering bugs, the `x_rpcbuf` non-zeroing info-leaks, the randr
> mis-dispatch, and the present swap omission. These are *not* present in upstream X.Org.

---

## HIGH — memory corruption / OOB (both reviewers confirmed)

### H1. Stack OOB write in `ProcXTestFakeInput` — `Xext/xtest.c:260-317`
Off-by-one in the valuator bound check: `if (firstValuator > dev->valuator->numAxes)`
uses `>` not `>=`, so `firstValuator == numAxes` (legitimately up to `MAX_VALUATORS`=36)
passes. The per-event switch writes `valuators[base..base+5]` (attacker INT32s) **before**
the real range check at line 313. With a 36-axis XI device and `first_valuator=36`, the
first iteration writes `valuators[36..41]` — up to 6 ints past the 36-element stack array.
- **Vector:** `XTestFakeInput` with an XI `DeviceMotionNotify` event, `deviceid` → 36-axis device.
- **Fix:** change `>` to `>=`; move the `firstValuator + numValuators > numAxes` check before the writes.

### H2. OOB read in GLX `RenderLarge` first-request path — `glx/glxcmds.c:2084-2120`
The non-large `__glXDisp_Render` guards `cmdlen < entry.bytes` *before* calling
`entry.varsize`. The `RenderLarge` first-request branch omits this guard — it only checks
`dataBytes >= 8` then calls the variable-size handler, which reads fixed header offsets up
to ~80 bytes past an 8-byte body (`entry.bytes` is only checked afterwards, too late).
- **Vector:** `GLXRenderLarge` with `dataBytes=8` and a sub-op like TexImage3D/TexSubImage3D/Map2d/SeparableFilter2D. Works swapped and unswapped.
- **Fix:** add the `cmdlen >= entry.bytes` (or `left-8 >= entry.bytes`) check before invoking `varsize`, mirroring `__glXDisp_Render`.

### H3. Integer overflow → huge OOB read in `__glXDisp_CreateContextAttribsARB` — `glx/createcontext.c:118-176`
`expected_size = (sizeof(req) + req->numAttribs * 8) / 4` in 32-bit unsigned math, no
`safe_mul`. `numAttribs = 0x20000000` wraps the product to 0, so a minimal 28-byte request
passes `req->length != expected_size`, then `for (i=0; i<req->numAttribs; i++)` walks ~2^29
attribute pairs far past the buffer.
- **Note:** sibling GLX handlers all clamp `numAttribs > (UINT32_MAX>>3)`; this one is the omission. Native-endian path only (swapped returns BadRequest).
- **Fix:** add the `numAttribs > (UINT32_MAX>>3)` clamp / use `safe_mul`+`safe_add`.

### H4. `ProcXFixesSetCursorName` — swap-after-validate OOB read — `xfixes/cursor.c:413-422`
`REQUEST_FIXED_SIZE(..., stuff->nbytes)` validates the **pre-swap** (wire-order) `nbytes`,
but `swaps(&stuff->nbytes)` runs afterward and `MakeAtom(tchar, stuff->nbytes, …)` uses the
**post-swap** value. A swapped client picks a wire `nbytes` that passes the length check
while the swapped value is large → `MakeAtom` reads/fingerprints/`strndup`s hundreds of
bytes past the request buffer (heap disclosure into the atom table, retrievable via
`GetCursorName`).
- **Regression:** commit `8336ad8e6f` ("inline request swapping") moved the swap after the check.
- **Fix:** swap `nbytes` **before** `REQUEST_FIXED_SIZE`.

### H5. `ProcXFixesChangeCursorByName` — same swap-after-validate OOB read — `xfixes/cursor.c:670-680`
Identical defect to H4 (`MakeAtom(..., FALSE)` still does the OOB fingerprint + `strncmp`).
Fix together with H4.

---

## HIGH — contested (1 of 2 reviewers refuted; flagged for your judgement)

### H6. OOB write via unchecked indicator index in `ReadXkmIndicators` — `xkb/xkmread.c:647-652`
`wire.indicator` (CARD8, 0–255) indexes `indicators[wire.indicator-1]` and
`maps[wire.indicator-1]` (both 32-element arrays) with **no** `1 <= indicator <= 32` check.
`0` → index -1; `33..255` → far OOB writes of attacker-shaped data.
- **Why contested:** the `.xkm` stream parsed here is the **output of the server's own trusted
  `xkbcomp`**, not client wire bytes — the client only supplies component *names*. So this is
  defense-in-depth unless `xkbcomp`/the output dir is compromised. **But** sibling readers
  (`ReadXkmKeycodes`, `ReadXkmKeyTypes`) *do* bounds-check, and recent commit `5d7e34fc9e`
  fixed the same class in `ReadXkmGeometry`. Worth hardening regardless.
- **Fix:** reject `indicator < 1 || indicator > XkbNumIndicators`.

---

## MEDIUM — NULL-deref DoS (both reviewers confirmed)

### M1. `ProcXvMCGetDRInfo` NULL deref — `Xext/xvmc.c:609-619`
Unlike its 3 sibling handlers, it never NULL-checks `pScreenPriv = XVMC_GET_PRIVATE(pScreen)`
before `strlen(pScreenPriv->clientDriverName)`. A local client targeting a valid Xv port on
a screen that never ran `XvMCScreenInit` (multi-GPU/multi-screen) crashes the server.
- **Fix:** `if (!pScreenPriv) return BadMatch;` as the siblings do.

### M2. `ProcXIChangeCursor` NULL deref on `win == None` — `Xi/xichangecursor.c:81-100`
`pWin` stays NULL when `stuff->win == None`, then `pWin == pWin->drawable.pScreen->root`
(or `ChangeWindowDeviceCursor(NULL,…)`) dereferences NULL. Any client with a valid
master-pointer deviceid (e.g. VCP id 2) crashes the server.
- **Fix:** reject `win == None` (or handle it) before the deref.

### M3. `ProcXQueryDeviceState` NULL deref on `BadAccess` — `Xi/queryst.c:76-84`
Handler intentionally continues when `dixLookupDevice` returns `BadAccess`, but current
`dixLookupDevice` leaves `*pDev = NULL` on non-Success, so `dev->valuator` derefs NULL.
- **Precondition:** an active XACE/SELinux policy that returns `BadAccess` for the client's
  `DixReadAccess` (stock servers return Success → not triggered).
- **Fix:** `if (rc == BadAccess) dev = NULL;`-aware guard, or `if (!dev) return …;` before use.

---

## MEDIUM / LOW — lower-impact & contested

### L1 (med, contested 1/2). GLX `ReqSize` handlers ignore `reqlen` — `glx/indirect_reqsize.c:542-610`
The auto-generated size functions never use their `reqlen` bound for fixed-header reads.
Only exploitable via H2 (no independent defense). Reviewer split on whether it stands as a
standalone finding; fix is the same defense-in-depth: honor `reqlen`. Closing H2 is the priority.

### L2 (low, contested 1/2). 1-byte OOB read in `ProcXIPassiveGrabDevice` — `Xi/xipassivegrab.c:136-138`
Double `*4` scaling (`mask_len` is already bytes, passed again as `mask_len*4`). With
`mask_len==1, num_modifiers==0`, copies 5 bytes from a 4-byte region — 1 byte over-read.
Lands in connection-buffer slack (no crash), not echoed to client (no leak). Sibling
`ProcXIGrabDevice` does it correctly (passes `mask_len`). Cosmetic but worth aligning.

### L3 (low). Uninitialized heap padding leak in `ProcXGetFeedbackControl` — `Xi/getfctl.c:300`
`x_rpcbuf_reserve` (non-zeroing realloc) replaced a previous `calloc`; the CopySwap* helpers
skip the internal pad bytes of `xKbdFeedbackState`(1)/`xPtrFeedbackState`(2)/`xBellFeedbackState`(3),
which are sent verbatim → 1–3 leaked heap bytes per feedback, repeatable.
- **Regression:** commit `6413bd61d7`. **Fix:** use `x_rpcbuf_reserve0`, or memset the pads.

### L4 (low). Uninitialized heap padding leak in `ProcRRGetProviderInfo` — `randr/rrprovider.c:159-234`
Same non-zeroing `x_rpcbuf_reserve`; `memcpy(name, provider->name, nameLength)` leaves the
1–3 trailing alignment pad bytes after the name uninitialized and sent to the client (e.g.
`"modesetting"` = 11 bytes).
- **Fix:** zero the name padding tail, or use `x_rpcbuf_reserve0`.

### L5 (low, functional). `SProcRRGetOutputInfo` calls wrong Proc — `randr/rrsdispatch.c:124-133`
Calls `ProcRRGetScreenResources` instead of `ProcRRGetOutputInfo`. **Fails closed**
(BadLength) — no memory-safety impact, but `RRGetOutputInfo` is broken for byte-swapped
clients. **Fix:** call the correct handler.

### L6 (low, functional). `sproc_present_pixmap_synced` missing `SwapRestL` — `present/present_request.c:408-436`
Unlike `sproc_present_pixmap`, it doesn't byte-swap the trailing `LISTofPRESENTNOTIFY`, so
swapped clients' notify XIDs are processed un-swapped. Bounded by `req_len` + `dixLookupWindow`
→ no OOB, functional bug only. **Fix:** add `SwapRestL(stuff)`.

---

## Rejected after verification (recorded so they aren't re-flagged)

- **`ProcXISelectEvents` mask_len pre-check read** (`Xi/xiselectev.c:161`) — over-read stays in
  the multi-KB connection buffer and the value only feeds a `> req_len` check that returns
  BadLength on the triggering case; nothing leaked, no fault.
- **`convolutionFilterValidateParams` negative kernel dims** (`render/filter.c:260`) — validated
  w/h are discarded; pixman re-derives dims and its loops `for(i<cwidth)` no-op on negatives,
  so no OOB sink exists.
- **`dri3_fd_from_pixmap` self-referential size read** (`dri3/dri3_screen.c:150`) — caller
  brace-initializes the reply, so `*size = size[0]` reads a deterministic 0, not leaked memory.
- **`ReadXkmGeometry` unchecked color index** (`xkb/xkmread.c:1087`) — the OOB pointer is only
  ever used in `XkbGeomColorIndex` pointer-subtraction (no deref); the client-facing
  `XkbSetGeometry` path *does* bounds-check.

---

## Suggested remediation order
1. **H1–H5** (memory corruption / OOB read of heap, remotely reachable). H4/H5 and H1 are the most serious (OOB **write** / heap disclosure to client).
2. **M1–M3** (NULL-deref DoS).
3. **L3/L4** (info-leak), then **L1/L2/L5/L6** (hardening / functional).
4. **H6** — decide whether to harden the trusted-`.xkm` parser (recommended; cheap and matches sibling code).
