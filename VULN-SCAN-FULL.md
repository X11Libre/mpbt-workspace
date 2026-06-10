# XLibre xserver — Full Vulnerability Scan Report (Extension Request Handlers)

**Target:** `sources/xlibre/xserver` @ `release/25.1` (commit `08e840dfb7`)
**Scope:** client-facing `Proc*` / `SProc*` request handlers across
Xext, Xi, render, randr, glx, dbe, record, xfixes, composite, present, dri3, xkb.
**Method:** 35 parallel finder agents enumerated handlers and traced length/count/swap
handling; every candidate was then independently re-verified by **2 adversarial reviewers**
who re-read the source and tried to refute it. 73 agents total, ~2.9M tokens.
**Result:** 19 candidates → **15 confirmed**, **4 rejected**.
**Date:** 2026-06-11

**Vulnerability classes:** (1) missing/incorrect length validation, (2) integer
overflow/truncation, (3) byte-swap bug, (4) OOB array indexing, (5) uninitialized-memory
disclosure, (6) NULL-deref / UAF / type confusion.

**Confirmation rule:** a candidate is "confirmed" if at least one reviewer rated it real and
it was not majority-refuted. Findings where the two reviewers disagreed are explicitly marked
**CONTESTED** below.

---

# CONFIRMED FINDINGS (15)

---

## H1 — Stack out-of-bounds write in `ProcXTestFakeInput`
- **File/line:** `Xext/xtest.c:260-317`
- **Function:** `ProcXTestFakeInput`
- **Class:** 4 (OOB array indexing) · **Severity:** HIGH · **Finder confidence:** medium
- **Verifier vote:** 2/2 real (both high confidence)

**Description.** For an XI extension event (`type >= EXTENSION_EVENT_BASE`) of
`XI_DeviceMotionNotify`, `firstValuator` is taken from the client-supplied
`deviceValuator.first_valuator` (a CARD8) and validated only with
`if (firstValuator > dev->valuator->numAxes)` (line 261) — note `>` permits
`firstValuator == numAxes`. The local array is `int valuators[MAX_VALUATORS]`
(`MAX_VALUATORS == 36`, `include/input.h:117`) and `numAxes` is capped at `MAX_VALUATORS`
(`dix/devices.c:1350-1354`), so `numAxes` can legitimately be 36. In the per-event loop
`base = firstValuator`, and the switch (lines 291-308) writes `valuators[base]` …
`valuators[base+5]` (`num_valuators` is a client CARD8, 1..6) **before** the range check
`if (firstValuator + numValuators > dev->valuator->numAxes)` at line 313 runs. Because the
validating comparison happens only after the writes, and `firstValuator` may equal 36, the
first iteration writes `valuators[36..41]` — 1 to 6 ints past the end of the 36-element stack
array. The written values (`dv->valuator0..valuator5`) are fully attacker-controlled INT32s.
The subsequent `BadValue` return does not undo the stack corruption.

```c
if (firstValuator > dev->valuator->numAxes) {   /* should be >= */
    client->errorValue = ev->u.u.type;
    return BadValue;
}
...
base = firstValuator;
for (n = 1; n < nev; n++) {
    deviceValuator *dv = (deviceValuator *) (ev + n);
    ...
    switch (dv->num_valuators) {
    case 6: valuators[base + 5] = dv->valuator5;   /* write before check */
    ...
    case 1: valuators[base] = dv->valuator0; break;
    }
    base += dv->num_valuators;
    numValuators += dv->num_valuators;
    if (firstValuator + numValuators > dev->valuator->numAxes) {  /* checked too late */
        client->errorValue = dv->num_valuators;
        return BadValue;
    }
}
```

**Attack vector.** `XTestFakeInput` whose first xEvent has
`type == EXTENSION_EVENT_BASE + DeviceValuator + XI_DeviceMotionNotify`, `deviceid` pointing
at an XI device with `valuator->numAxes == 36`, `first_valuator == 36`, and a following
`deviceValuator` with `num_valuators` in 1..6 and attacker-chosen `valuator0..valuator5`.

**Verifier reasoning.** Both confirmed against source: `valuators[MAX_VALUATORS]` at line 194,
`MAX_VALUATORS==36`; `InitValuatorClassDeviceStruct` caps `numAxes` at 36 but allows exactly 36.
`X_REQUEST_HEAD_NO_CHECK` performs no size check; `XTestSwapFakeInput` only byte-swaps without
range validation. `nev>=2` is enforced; request-length math guarantees `ev+1` is in-buffer.
The `dv->first_valuator == base` equality check (line 287) is satisfiable. Reachable, unguarded,
attacker-controlled stack OOB write. Precondition: an XI device with exactly 36 valuators
(realistic for tablets / multi-axis input).

**Fix.** Change `>` to `>=`; perform the `firstValuator + numValuators > numAxes` check
**before** the valuator writes.

---

## H2 — OOB read in GLX `RenderLarge` first-request path
- **File/line:** `glx/glxcmds.c:2084-2120`; sinks in `glx/indirect_reqsize.c:542-610`, `glx/rensize.c:86-118,437-466`
- **Function:** `__glXDisp_RenderLarge` → `__glXTexImage3DReqSize` / `__glXTexSubImage3DReqSize` / `__glXMap2dReqSize` / `__glXSeparableFilter2DReqSize`
- **Class:** 1 (missing length validation) · **Severity:** HIGH · **Finder confidence:** high
- **Verifier vote:** 2/2 real (both high confidence)

**Description.** `__glXDisp_Render` checks `if (cmdlen < entry.bytes) return BadLength;`
(`glxcmds.c:1991`) **before** invoking the per-command variable-size function, guaranteeing
the whole fixed header the ReqSize function reads is inside the request. The `RenderLarge`
first-request path is missing this check: it only verifies `dataBytes < __GLX_RENDER_LARGE_HDR_SIZE`
(8 bytes, line 2084) and then immediately calls
`(*entry.varsize)(pc + 8, swapped, left - 8)` at line 2111. `entry.bytes` is only consulted
afterward in the equality check at line 2120 — too late. The image-based ReqSize functions
read fixed-offset header fields without ever using their `reqlen` argument as a bound
(`__glXTexImage3DReqSize` reads `*(CARD32*)(pc+76)`, `__glXTexSubImage3DReqSize` reads pc+80,
`__glXMap2dReqSize` reads pc+32..40, `__glXSeparableFilter2DReqSize` dereferences a full
convolution-filter header). With `dataBytes==8` the body is empty yet the handler reads up to
~80 bytes past the buffer. Swapped variant byte-swaps after the OOB read. Result: OOB read of
adjacent heap/stack whose value influences the returned size and downstream control flow —
crash / size-influence primitive reachable by any GLX client.

```c
if (dataBytes < __GLX_RENDER_LARGE_HDR_SIZE)
    return BadLength;
hdr = (__GLXrenderLargeHeader *) pc;
...
if (entry.varsize) {
    extra = (*entry.varsize)(pc + __GLX_RENDER_LARGE_HDR_SIZE,
                             client->swapped, left - __GLX_RENDER_LARGE_HDR_SIZE);
}
/* entry.bytes only checked here, AFTER varsize already read OOB */
if (cmdlen != safe_pad(safe_add(entry.bytes + 4, extra)))
    return BadLength;
```

**Attack vector.** `GLXRenderLarge` (opcode 2), first packet, `requestNumber=1`, a variable-size
sub-opcode (TexImage3D 4114, TexSubImage3D 4115, Map2d 145, SeparableFilter2D 4109), `dataBytes=8`,
`req->length` set so `(req->length<<2) == pad(dataBytes)+sizeof(xGLXRenderLargeReq)`. Works swapped
and non-swapped.

**Verifier reasoning.** Confirmed the decisive asymmetry: the non-large path guards both
`left < cmdlen` and `cmdlen < entry.bytes` before `varsize`; `RenderLarge` omits the
`entry.bytes` guard. The ReqSize handlers ignore `reqlen`. Reachability requires
`__glXForceCurrent` to succeed (a valid context tag), obtainable by any GLX client creating a
context. Disclosure is indirect (value feeds a size computation rather than returned verbatim).

**Fix.** Add the `left-8 >= entry.bytes` (or `cmdlen >= entry.bytes`) check before invoking
`varsize`, mirroring `__glXDisp_Render`. See also L1.

---

## H3 — Integer overflow → huge OOB read in `__glXDisp_CreateContextAttribsARB`
- **File/line:** `glx/createcontext.c:118-176`
- **Function:** `__glXDisp_CreateContextAttribsARB`
- **Class:** 2 (integer overflow) · **Severity:** HIGH · **Finder confidence:** high
- **Verifier vote:** 2/2 real (both high confidence)

**Description.** `expected_size = (sizeof(xGLXCreateContextAttribsARBReq) + (req->numAttribs * 8)) / 4`
in 32-bit unsigned arithmetic. `numAttribs` is an attacker-controlled CARD32 read directly from
the request. The multiply is **not** done with the `safe_mul`/`safe_add` helpers used elsewhere
in GLX. With `numAttribs = 0x20000000`, `numAttribs * 8 = 0x100000000` wraps to 0, so
`expected_size = 28/4 = 7`. The only length guard is `if (req->length != expected_size) return BadLength;`.
A 28-byte (`length=7`) request with `numAttribs=0x20000000` passes; then
`for (i = 0; i < req->numAttribs; i++)` reads `attribs[i*2]` / `attribs[2*i+1]` for ~0x20000000
iterations, walking far past the 28-byte buffer. OOB read → crash (DoS), with weaker infoleak
potential (read values feed `client->errorValue` and branch decisions). The swapped dispatch
returns `BadRequest`, so only native-byte-order clients reach this — trivially satisfied.

```c
const unsigned expected_size = (sizeof(xGLXCreateContextAttribsARBReq)
                                + (req->numAttribs * 8)) / 4;
if (req->length != expected_size)
    return BadLength;
...
if (req->numAttribs) {
    attribs = (int32_t *) (req + 1);
    for (int i = 0; i < req->numAttribs; i++) {
        switch (attribs[i * 2]) {
```

**Attack vector.** `X_GLXCreateContextAttribsARB` from a native-endian client; `length=7`,
`numAttribs=0x20000000`.

**Verifier reasoning.** Confirmed `sz=28`, no `safe_mul`/`safe_add` (`grep -c safe_ createcontext.c`
== 0). The VND dispatch stub only does `REQUEST_AT_LEAST_SIZE` (28 bytes); no layer bounds
`numAttribs`. Sibling handlers in `glxcmds.c`/`glxcmdsswap.c` all guard
`numAttribs > (UINT32_MAX >> 3)` — this one is the omission. OS layer delivers exactly 28 bytes,
making the OOB read guaranteed. The loop runs before any `isDirect`/`enableIndirectGLX` gate.

**Fix.** Add `if (req->numAttribs > (UINT32_MAX >> 3)) return BadLength;` and/or use
`safe_mul`+`safe_add`, matching the sibling handlers.

---

## H4 — `ProcXFixesSetCursorName`: REQUEST_FIXED_SIZE validates pre-swap `nbytes`, MakeAtom uses post-swap (OOB read)
- **File/line:** `xfixes/cursor.c:413-422`
- **Function:** `ProcXFixesSetCursorName`
- **Class:** 3 (byte-swap bug) · **Severity:** HIGH · **Finder confidence:** high
- **Verifier vote:** 2/2 real (both high confidence)

**Description.** `nbytes` is a CARD16 trailing-length field.
`REQUEST_FIXED_SIZE(xXFixesSetCursorNameReq, stuff->nbytes)` at line 413 validates the request
length against `nbytes`, but for a byte-swapped client `stuff->nbytes` is still in **wire**
order there — `swaps(&stuff->nbytes)` only happens afterward at line 417.
`MakeAtom(tchar, stuff->nbytes, TRUE)` at line 422 reads the **post-swap** (host-order) value.
The value validated and the value consumed differ for swapped clients, so the length check
does not bound the `MakeAtom` read. An attacker on a swapped connection picks the raw `nbytes`
word and request length so `REQUEST_FIXED_SIZE` passes (e.g. raw `nbytes=1`, `req_len=4` words)
while the swapped value is large (e.g. `0x0100 = 256`). `MakeAtom` then fingerprints / `strncmp` /
`strndup`s 256 bytes from `&stuff[1]`, reading ~252 bytes past the 16-byte request buffer →
heap disclosure into the atom table (retrievable via `GetCursorName`) or crash.

```c
REQUEST_FIXED_SIZE(xXFixesSetCursorNameReq, stuff->nbytes);
if (client->swapped) {
    swapl(&stuff->cursor);
    swaps(&stuff->nbytes);
}
VERIFY_CURSOR(pCursor, stuff->cursor, client, DixSetAttrAccess);
tchar = (char *) &stuff[1];
atom = MakeAtom(tchar, stuff->nbytes, TRUE);
```

**Attack vector.** `X_XFixesSetCursorName` from a byte-swapped client; `nbytes` crafted so its
wire value passes `REQUEST_FIXED_SIZE` but its swapped value greatly exceeds the trailing data.

**Verifier reasoning.** `ProcXFixesDispatch` is registered as both the proc and sproc vector
(`xfixes.c:226`) — there is no separate SProc that pre-swaps `nbytes`. `client->req_len` is
host-order (`os/io.c get_req_len` swaps it) while body `nbytes` is not, so `REQUEST_FIXED_SIZE`
compares host-order `req_len` against wire-order `nbytes`. Exploit arithmetic verified
(`sz=12`; wire `01 00` → value 1 passes, swapped → 256). `MakeAtom` (`dix/atom.c:76`) reads
`len` bytes unconditionally. **Regression:** commit `8336ad8e6f` ("xfixes: inline request
swapping") removed `SProcXFixesSetCursorName` (which swapped before `Proc`) and inlined the
swap after `REQUEST_FIXED_SIZE`, inverting the safe order. Upstream X.Org swaps via
`X_REQUEST_FIELD_CARD16(nbytes)` before the check.

**Fix.** Swap `nbytes` **before** `REQUEST_FIXED_SIZE` (fix together with H5).

---

## H5 — `ProcXFixesChangeCursorByName`: same swap-after-validate OOB read
- **File/line:** `xfixes/cursor.c:670-680`
- **Function:** `ProcXFixesChangeCursorByName`
- **Class:** 3 (byte-swap bug) · **Severity:** HIGH · **Finder confidence:** high
- **Verifier vote:** 2/2 real (both high confidence)

**Description.** Same defect as H4. `REQUEST_FIXED_SIZE(xXFixesChangeCursorByNameReq, stuff->nbytes)`
at line 670 runs before `swaps(&stuff->nbytes)` at line 674; `MakeAtom(tchar, stuff->nbytes, FALSE)`
at line 680 uses the post-swap value. Although `makeit=FALSE` (no `strndup`), `MakeAtom` still
computes a fingerprint over `(len+1)/2` byte pairs and does `strncmp` over `len` bytes →
OOB read / crash, and may match an existing atom based on leaked memory.

```c
REQUEST_FIXED_SIZE(xXFixesChangeCursorByNameReq, stuff->nbytes);
if (client->swapped) {
    swapl(&stuff->source);
    swaps(&stuff->nbytes);
}
VERIFY_CURSOR(pSource, stuff->source, client, ...);
tchar = (char *) &stuff[1];
name = MakeAtom(tchar, stuff->nbytes, FALSE);
```

**Attack vector.** `X_XFixesChangeCursorByName` from a byte-swapped client with `nbytes` crafted
as in H4 (one reviewer used wire `nbytes=0x00FF`/`req_len=67` → swapped `0xFF00=65280`, ~65 KB
over-read).

**Verifier reasoning.** Same dispatch/swap analysis as H4; both reviewers confirmed, could not
refute. `makeit=FALSE` avoids only `strndup`, not the OOB fingerprint/`strncmp` reads.

**Fix.** Swap `nbytes` before `REQUEST_FIXED_SIZE`.

---

## H6 — Out-of-bounds write via unchecked indicator index in `ReadXkmIndicators`  ⚠️ CONTESTED
- **File/line:** `xkb/xkmread.c:647-652`
- **Function:** `ReadXkmIndicators`
- **Class:** 4 (OOB array indexing) · **Severity:** HIGH (if reachable) · **Finder confidence:** high
- **Verifier vote:** 1/2 real (one high-confidence refute, one high-confidence confirm) — **CONTESTED**

**Description.** `wire.indicator` is a raw CARD8 (0–255) read from the `.xkm` stream, used
without any range check as the index `wire.indicator - 1` into `xkb->names->indicators[]` and
`xkb->indicators->maps[]`, both fixed `XkbNumIndicators` (=32) arrays. No check that
`1 <= wire.indicator <= 32`. `indicator==0` → index -1 (negative-index write); `33..255` →
write far past the arrays. The code writes an Atom into `indicators[idx]` and a full
`XkbIndicatorMapRec` of attacker-controlled fields into `maps[idx]`.

```c
nLEDs = XkmGetCARD8(file, &nRead);
...
while (nLEDs-- > 0) {
    ...
    if ((tmp = fread(&wire, SIZEOF(xkmIndicatorMapDesc), 1, file)) < 1) { ... }
    if (xkb->names) {
        xkb->names->indicators[wire.indicator - 1] = name;   /* no bounds check */
        ...
    }
    map = &xkb->indicators->maps[wire.indicator - 1];        /* no bounds check */
    map->flags = wire.flags; ... map->ctrls = wire.ctrls;
```

**Why contested.**
- **Refuting reviewer (is_real=false, high conf):** the `.xkm` parsed here is **not**
  client-supplied. The trust boundary is the `xkbcomp` invocation: `ProcXkbGetKbdByName`
  accepts only XKB component *names* (strings) → `XkbDDXCompileKeymapByNames` → `RunXkbComp`
  pipes a keymap to the server's own trusted `xkbcomp`, which writes the binary `.xkm` to a
  fixed server-controlled path; only that server-generated file is read by `XkmReadFile` →
  `ReadXkmIndicators`. `xkbcomp` emits in-range indices. No X request delivers raw `.xkm` bytes
  or an attacker-chosen path. Code is byte-identical to upstream X.Org and has never been a
  remote CVE. ⇒ defense-in-depth only.
- **Confirming reviewer (is_real=true, high conf):** the field is a raw CARD8, read via `fread`
  with no validation; sibling readers (`ReadXkmKeycodes`, `ReadXkmKeyTypes`) **do** bounds-check
  their indices, and recent commit `5d7e34fc9e` explicitly fixed the same OOB class in
  `ReadXkmGeometry` in this very file. `ReadXkmIndicators` remains unguarded.

**Assessment.** Genuine code defect; not remotely reachable with attacker-controlled data on a
stock server. Recommend hardening regardless (cheap, matches sibling code and the recent
`ReadXkmGeometry` fix).

**Fix.** Reject `wire.indicator < 1 || wire.indicator > XkbNumIndicators`.

---

## M1 — NULL-pointer dereference in `ProcXvMCGetDRInfo`
- **File/line:** `Xext/xvmc.c:609-619`
- **Function:** `ProcXvMCGetDRInfo`
- **Class:** 6 (NULL deref) · **Severity:** MEDIUM · **Finder confidence:** high
- **Verifier vote:** 2/2 real (both high confidence)

**Description.** The handler validates the Xv port, fetches
`pScreenPriv = XVMC_GET_PRIVATE(pScreen)`, but — unlike every other port-taking XvMC handler
(`ProcXvMCListSurfaceTypes:137`, `ProcXvMCCreateContext:199`, `ProcXvMCListSubpictureTypes:510`) —
never checks `pScreenPriv` for NULL before `strlen(pScreenPriv->clientDriverName)` /
`strlen(pScreenPriv->busID)` and reading `pScreenPriv->major/minor/patchLevel`.
`XVMC_GET_PRIVATE` returns NULL for any screen on which `XvMCScreenInit()` was never called.
The extension's private key is registered globally once **any** screen initializes XvMC, but a
screen whose driver did not register XvMC still has a NULL private. A local client
(`client->local` enforced at `ProcXvMCDispatch:649`) owning a valid Xv port on such a screen
issues `XvMCGetDRInfo` → NULL deref → crash.

```c
VALIDATE_XV_PORT(stuff->port, pPort, DixReadAccess);
pScreen = pPort->pAdaptor->pScreen;
pScreenPriv = XVMC_GET_PRIVATE(pScreen);
int nameLen = strlen(pScreenPriv->clientDriverName) + 1;  /* NULL deref */
int busIDLen = strlen(pScreenPriv->busID) + 1;
```

**Attack vector.** Local client sends `XvMCGetDRInfo` with `port` = a valid `XvRTPort` whose
adaptor's screen never ran `XvMCScreenInit` (multi-GPU/multi-screen where only one screen has XvMC).

**Verifier reasoning.** `XVMC_GET_PRIVATE` is `dixLookupPrivate`; `XvMCScreenInit` sets the
private only on the specific screen that calls it but flips `XvMCInUse`/registers the key
globally. The three siblings all guard `pScreenPriv`; `GetDRInfo` is the sole unguarded
port-taking path. `VALIDATE_XV_PORT` does no XvMC filtering.

**Fix.** `if (!pScreenPriv) return BadMatch;` (as siblings do).

---

## M2 — NULL-pointer dereference in `ProcXIChangeCursor` when `win == None`
- **File/line:** `Xi/xichangecursor.c:81-100`
- **Function:** `ProcXIChangeCursor`
- **Class:** 6 (NULL deref) · **Severity:** MEDIUM · **Finder confidence:** high
- **Verifier vote:** 2/2 real (both high confidence)

**Description.** `pWin` is initialized NULL (line 70) and only looked up when `stuff->win != None`
(lines 81-85). If the client sends `win == None`, `pWin` stays NULL. The code then
unconditionally dereferences it: when `cursor == None`, `pWin == pWin->drawable.pScreen->root`
(line 88) derefs NULL and crashes. (When `cursor != None`, NULL `pWin` is passed to
`ChangeWindowDeviceCursor()`, which calls `MakeWindowOptional(pWin)` and derefs
`pWin->drawable.pScreen` → also crashes.) The only prior validation is that the deviceid
resolves to a master pointer.

```c
WindowPtr pWin = NULL;
...
    if (stuff->win != None) {
        rc = dixLookupWindow(&pWin, stuff->win, client, DixSetAttrAccess);
        if (rc != Success)
            return rc;
    }
    if (stuff->cursor == None) {
        if (pWin == pWin->drawable.pScreen->root)   /* pWin may be NULL */
            pCursor = rootCursor;
```

**Attack vector.** `X_XIChangeCursor` (XInput2 opcode 42): `deviceid` = a master pointer
(e.g. 2 = VCP), `win = None`, `cursor = None`.

**Verifier reasoning.** `REQUEST_SIZE_MATCH` validates only length, not the `win` value. Dispatch
is a direct case in `ProcXIDispatch` (`extinit.c:292`) with no privilege gate; any client with a
valid master-pointer deviceid reaches it. Long-standing logic (line 88 dates to 2010) but
reachable from the unprivileged request path. DoS only — no corruption/escalation.

**Fix.** Reject (or handle) `win == None` before the dereference.

---

## M3 — NULL-pointer dereference in `ProcXQueryDeviceState` on `BadAccess` path
- **File/line:** `Xi/queryst.c:76-84`
- **Function:** `ProcXQueryDeviceState`
- **Class:** 6 (NULL deref) · **Severity:** MEDIUM (conditional) · **Finder confidence:** high
- **Verifier vote:** 2/2 real (both high confidence)

**Description.** The handler does `if (rc != Success && rc != BadAccess) return rc;`,
intentionally continuing on `BadAccess` to emit blanked-out class headers (later copies are
guarded by `if (rc != BadAccess)`). However, current `dixLookupDevice()` sets `*pDev = NULL` on
entry and only assigns `*pDev = dev` on `Success` (`dix/devices.c:1250,1263-1266`). So when
`rc == BadAccess`, `dev` is NULL and the next statement `v = dev->valuator;` derefs NULL → crash.

```c
rc = dixLookupDevice(&dev, stuff->deviceid, client, DixReadAccess);
    if (rc != Success && rc != BadAccess)
        return rc;
    v = dev->valuator;   /* dev == NULL when rc == BadAccess */
    if (v != NULL && v->motionHintWindow != NULL)
        MaybeStopDeviceHint(dev, client);
```

**Attack vector.** `X_QueryDeviceState` on a server where an XACE/SELinux hook returns
`BadAccess` for the client's `DixReadAccess` to that device
(`Xext/xselinux_hooks.c:110` returns `BadAccess` on EACCES). A client can deny itself access via
policy and crash the server.

**Verifier reasoning.** Full chain confirmed: `SELinuxDevice` is registered on
`DeviceAccessCallback`, returns `BadAccess`, propagated through `dixCallDeviceAccessCallback`
inside `dixLookupDevice`. Sibling `ProcQueryPointer` is **not** vulnerable (it gets the device
via `PickPointer()` independently). Likely a latent regression: the `BadAccess`-continue logic
(commit `c1c7feec90`, 2009) predates the current `dixLookupDevice` NULL-on-non-Success semantics.
**Precondition:** active XACE/SELinux policy returning `BadAccess` (stock servers return Success).

**Fix.** Guard `dev` for NULL after the lookup before dereferencing (e.g. treat `BadAccess` with
NULL `dev` explicitly).

---

## L1 — GLX `ReqSize` handlers ignore their `reqlen` argument  ⚠️ CONTESTED
- **File/line:** `glx/indirect_reqsize.c:542-576, 578-610` (pattern repeated)
- **Function:** `__glXTexImage3DReqSize` / `__glXTexSubImage3DReqSize` and peers
- **Class:** 1 (missing length validation) · **Severity:** MEDIUM · **Finder confidence:** high
- **Verifier vote:** 1/2 real — **CONTESTED**

**Description.** These auto-generated size functions take a `reqlen` parameter (bytes available
after the render header) but never compare it against the fixed offsets they dereference. They
are safe only because the non-large `__glXDisp_Render` dispatcher pre-checks
`cmdlen >= entry.bytes`; they provide no independent defense — which is what makes the
`RenderLarge` gap (H2) exploitable. Contrast `__glXDrawArraysReqSize` (`rensize.c:381`), which
does validate `reqlen`.

```c
int
__glXTexImage3DReqSize(const GLbyte * pc, Bool swap, int reqlen)
{
    GLint row_length = *(GLint *) (pc + 4);
    ...
    GLenum type = *(GLenum *) (pc + 72);
    if (*(CARD32 *) (pc + 76))   /* read at offset 76 regardless of reqlen */
        return 0;
    return __glXImageSize(...);
}
```

**Why contested.** One reviewer: real as a class-1 hardening item whose realization depends on
H2 (which holds). Other reviewer: as a **standalone** finding it does not stand — through the
path these handlers are actually reached (`Render`), the `entry.bytes` check already bounds the
reads; the only real OOB is H2 (separately tracked). Both agree the fix is the same.

**Fix.** Honor `reqlen` for the fixed-header reads (defense-in-depth). Closing H2 is the priority.

---

## L2 — Bounded 1-byte OOB read in `ProcXIPassiveGrabDevice` (double `*4` scaling)  ⚠️ CONTESTED
- **File/line:** `Xi/xipassivegrab.c:136-138`
- **Function:** `ProcXIPassiveGrabDevice`
- **Class:** 1 · **Severity:** LOW · **Finder confidence:** medium
- **Verifier vote:** 1/2 real — **CONTESTED**

**Description.** `mask_len = min(xi2mask_mask_size(mask)=5, stuff->mask_len*4)` — already in
bytes and capped to 5. It is then passed to `xi2mask_set_one_mask` as `mask_len * 4`, applying
the `*4` a **second** time. With `stuff->mask_len == 1`, the source region holds 4 bytes,
`mask_len` becomes `min(5,4)=4`, passed size becomes 16, and the inner `memcpy` copies
`min(5,16)=5` bytes — 1 byte past the 4-byte source. With `num_modifiers==0`, that byte is past
the validated request buffer. Sibling `ProcXIGrabDevice` (`xigrabdev.c:101-104`) does it
correctly (passes `mask_len`, with a `/* FIXME: I think the old code was broken here */` comment).

```c
mask_len = min(xi2mask_mask_size(mask.xi2mask), stuff->mask_len * 4);
xi2mask_set_one_mask(mask.xi2mask, stuff->deviceid,
                     (unsigned char *) &stuff[1], mask_len * 4);
```

**Why contested.** Refuting reviewer: the read lands in the persistent ≥16 KB connection input
buffer's slack (not unmapped memory → no crash), and the byte is stored into the grab mask, not
echoed to the client (no infoleak) → negligible real impact, a correctness bug not a security
vuln. Confirming reviewer: the over-read is real and unguarded, severity correctly LOW.

**Fix.** Pass `mask_len` (not `mask_len * 4`), mirroring `ProcXIGrabDevice`.

---

## L3 — Uninitialized heap padding disclosed in `ProcXGetFeedbackControl` reply
- **File/line:** `Xi/getfctl.c:300` (reserve); writers at `71-98, 106-125, 221-239`
- **Function:** `ProcXGetFeedbackControl` / `CopySwapKbdFeedback` / `CopySwapPtrFeedback` / `CopySwapBellFeedback`
- **Class:** 5 (uninitialized-memory disclosure) · **Severity:** LOW (downgraded from medium) · **Finder confidence:** high
- **Verifier vote:** 2/2 real (both high confidence)

**Description.** The reply payload is obtained with `x_rpcbuf_reserve(&rpcbuf, total_length)`,
which is `realloc`-backed and does **not** zero (the zeroing variant `x_rpcbuf_reserve0` is not
used). The `CopySwap*` helpers populate each feedback state field-by-field and skip the internal
padding inside several wire structs: `xKbdFeedbackState` has `BYTE pad` (never written),
`xPtrFeedbackState` has `CARD8 pad1, pad2`, `xBellFeedbackState` has `BYTE pad1, pad2, pad3`.
Each helper advances `*buf += sizeof(...)`, so 1–3 uninitialized heap bytes per feedback are sent
to the client, repeatable.

```c
char *buf = x_rpcbuf_reserve(&rpcbuf, total_length);  /* not zeroed: realloc-backed */
...
*buf += sizeof(xKbdFeedbackState);  /* internal pad bytes never written */
```

**Attack vector.** `X_GetFeedbackControl` on any device with kbd/ptr/bell feedback (normally present).

**Verifier reasoning.** **Regression:** commit `6413bd61d7` replaced `calloc(1, total_length)`
with the non-zeroing `x_rpcbuf_reserve`; prior commits `55544ff85f`/`87df8bcc19`
("Zero out structs to avoid leaking information via padding") had specifically introduced the
zeroing. String/integer/LED feedback structs have no internal pad and don't leak. Downgraded to
LOW: only 1–3 fixed intra-struct pad bytes from a small fresh allocation.

**Fix.** Use `x_rpcbuf_reserve0`, or `memset` the pad bytes.

---

## L4 — Uninitialized heap padding disclosed after provider name in `ProcRRGetProviderInfo` reply
- **File/line:** `randr/rrprovider.c:159-234`
- **Function:** `ProcRRGetProviderInfo`
- **Class:** 5 · **Severity:** LOW · **Finder confidence:** medium
- **Verifier vote:** 2/2 real (both high confidence)

**Description.** The reply "extra" buffer is `x_rpcbuf_reserve()` (non-zeroing realloc).
`extraLen = reply.length<<2` includes `bytes_to_int32(nameLength)`, which rounds `nameLength`
**up** to a 4-byte multiple, reserving padding after the name. The code writes
crtcs/outputs/providers/prov_cap, then `memcpy(name, provider->name, reply.nameLength)`
(line 224) copying exactly `nameLength` bytes and never zeroing the up-to-3 trailing pad bytes.
The full `extraLen` (including pad) is transmitted. Any provider whose name length isn't a
multiple of 4 (e.g. `"modesetting"` = 11) leaks 1–3 bytes of adjacent heap per reply.

```c
extraLen = reply.length << 2;
    if (extraLen) {
        extra = x_rpcbuf_reserve(&rpcbuf, extraLen); /* NOT zeroed */
...
    name = (char *)(prov_cap + reply.nAssociatedProviders);
...
    memcpy(name, provider->name, reply.nameLength); /* leaves padding tail uninitialized */
```

**Attack vector.** `RRGetProviderInfo` for any provider whose name length isn't a multiple of 4.

**Verifier reasoning.** Confirmed `x_rpcbuf_reserve` → `x_rpcbuf_makeroom` uses `realloc` with no
`memset`; `WriteRpcbufToClient` writes the full `wpos`. The library's own
`__x_rpcbuf_write_bin_pad` memsets pad, but this handler bypasses it with manual reserve+memcpy.
Upstream builds the reply in a zeroed buffer.

**Fix.** Zero the name padding tail, or use `x_rpcbuf_reserve0`.

---

## L5 — `SProcRRGetOutputInfo` calls the wrong Proc handler (functional regression, fails closed)
- **File/line:** `randr/rrsdispatch.c:124-133`
- **Function:** `SProcRRGetOutputInfo`
- **Class:** 3 (swap-path dispatch error) · **Severity:** LOW · **Finder confidence:** high
- **Verifier vote:** 1/2 "real-as-functional-bug" — both agree **no memory-safety impact**

**Description.** The swapped handler for `X_RRGetOutputInfo` validates as
`xRRGetOutputInfoReq` (sz=12) and swaps `output`/`configTimestamp`, but then calls
`ProcRRGetScreenResources(client)` instead of `ProcRRGetOutputInfo(client)`.
`ProcRRGetScreenResources` begins with `REQUEST_SIZE_MATCH(xRRGetScreenResourcesReq)` (sz=8), so
a well-formed GetOutputInfo request (`req_len==3`) fails (`3 != 2`) → `BadLength`. Consequence:
`RRGetOutputInfo` is broken for byte-swapped clients (denial of functionality); **no**
memory-safety impact (only already-validated in-bounds fields are swapped; the mis-dispatched
handler fails closed before touching any client length/count).

```c
REQUEST_SIZE_MATCH(xRRGetOutputInfoReq);
    swapl(&stuff->output);
    swapl(&stuff->configTimestamp);
    return ProcRRGetScreenResources(client);   /* should be ProcRRGetOutputInfo */
```

**Fix.** Call `ProcRRGetOutputInfo(client)`.

---

## L6 — `sproc_present_pixmap_synced` does not byte-swap the trailing notify list (missing `SwapRestL`)
- **File/line:** `present/present_request.c:408-436` (finder cited `present_scmd.c`; actual file is `present_request.c`)
- **Function:** `sproc_present_pixmap_synced`
- **Class:** 3 (byte-swap bug) · **Severity:** LOW · **Finder confidence:** high
- **Verifier vote:** 1/2 "real-as-functional-bug" — both agree **no memory-safety impact**

**Description.** The swapped handler for `X_PresentPixmapSynced` swaps every fixed-header field
but, unlike `sproc_present_pixmap` (which calls `SwapRestL(stuff)`), never swaps the
variable-length trailing `LISTofPRESENTNOTIFY`. `present_create_notifies` then reads
`x_notifies[i].window`/`.serial` raw, so a byte-swapped client's XIDs are processed unswapped →
`dixLookupWindow` with byte-reversed XIDs (wrong/None window). **No** memory-safety issue:
`nnotifies` is bounded by `req_len` (exact-divisibility check → BadLength), all accesses stay
in-buffer, `dixLookupWindow` safely rejects invalid XIDs.

```c
    swapll(&stuff->target_msc);
    swapll(&stuff->divisor);
    swapll(&stuff->remainder);
    return proc_present_pixmap_synced(client);
    /* NOTE: no SwapRestL(stuff) here, unlike sproc_present_pixmap */
```

**Fix.** Add `SwapRestL(stuff)` as in `sproc_present_pixmap`.

---

# REJECTED FINDINGS (4) — recorded so they aren't re-flagged

### R1 — `ProcXISelectEvents` reads `mask_len` header before confirming it's in-request
- **File/line:** `Xi/xiselectev.c:161-165` · **Unit:** Xi/select
- **Why rejected:** The 4-byte over-read of `evmask->mask_len` lands inside the persistent
  multi-KB connection input buffer (`os/io.c oci->buffer`, ≥BUFSIZE, only grown), not unmapped
  memory → no fault. The value is consumed only by
  `len += sizeof(xXIEventMask) + mask_len*4; if (bytes_to_int32(len) > req_len) return BadLength;`
  — with `req_len==3` this returns BadLength on the first iteration regardless of the garbage
  value, before any dereference of mask bits and before any reply. `mask_len` is uint16 so
  `mask_len*4` can't overflow. Nothing leaked, no fault.

### R2 — `convolutionFilterValidateParams` doesn't reject negative kernel dimensions
- **File/line:** `render/filter.c:260-284` · **Unit:** render/objects
- **Why rejected:** The validated width/height are discarded by callers (local ints used only
  for accept/reject; the picture struct has no filter w/h fields). Pixman independently
  re-derives kernel dims from `params[0]/params[1]`, and its convolution fetcher loops
  `for(i=0;i<cwidth;++i) for(j=0;j<cheight;++j)` — with negative dims the loop guards are false,
  bodies never execute, no coefficient is indexed. `nparams` is genuine (dispatch derives it
  from request length validated by `REQUEST_AT_LEAST_EXTRA_SIZE`). No OOB sink exists.

### R3 — Self-referential read of size output param in `dri3_fd_from_pixmap`
- **File/line:** `dri3/dri3_screen.c:150` · **Unit:** dri3
- **Why rejected:** Caller `proc_dri3_buffer_from_pixmap` brace-initializes the reply struct, so
  `reply.size` is deterministically 0; the self-referential `*size = size[0]` reads back that 0,
  not uninitialized/leaked memory. `REQUEST_SIZE_MATCH` guards length; the only client input
  (pixmap XID) is validated via `dixLookupResourceByType` with `DixWriteAccess`. Logic oddity,
  not exploitable.

### R4 — Unchecked color index forms `base_color`/`label_color` pointers in `ReadXkmGeometry`
- **File/line:** `xkb/xkmread.c:1087-1088` · **Unit:** xkb/alloc-parse
- **Why rejected:** The OOB pointer is never dereferenced on any client-reachable path. The
  `XkbGetGeometry` reply (`xkb.c:4919`) uses the macro `XkbGeomColorIndex(g,c)=(int)((c)-&(g)->colors[0])`
  — pure pointer subtraction recovering the original index, no memory access. The color reply
  serializer iterates only `geom->colors[0..num_colors)`. The only code that dereferences
  `base_color->spec` (`xkbout.c:849`) is the text-dump path feeding `xkbcomp`, not a client
  reply. The network-facing `XkbSetGeometry` **does** bounds-check the indices. (Same trusted-
  `.xkm` boundary as H6.)

---

# Remediation priority

1. **H1–H5** — memory corruption / heap disclosure, remotely reachable. H1 (OOB **write**) and
   H4/H5 (heap disclosure to client) are the most serious.
2. **M1–M3** — NULL-deref DoS.
3. **L3 / L4** — info-leak (small), then **L1 / L2 / L5 / L6** — hardening / functional.
4. **H6** — decide whether to harden the trusted-`.xkm` parser (recommended; cheap, matches
   sibling code and the recent `ReadXkmGeometry` fix `5d7e34fc9e`).

**Cross-cutting note.** The `x_rpcbuf` refactor (`6413bd61d7`) re-introduced padding-leak bugs
that earlier `calloc` commits had fixed (L3, L4). Audit **all** reply handlers that build via
`x_rpcbuf_reserve` (vs `x_rpcbuf_reserve0`) for the same pattern beyond this scope.
