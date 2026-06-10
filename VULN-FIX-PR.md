# PR prep: extension request-handler security fixes

Branch: `wip/ext-handler-vulns` (based on `release/25.1`) — **not pushed**.
20 commits, 22 files. All changed files compile against the configured meson build.

> ⚠️ These are unfixed security vulnerabilities. Decide on a disclosure path before
> opening a public PR (a public PR discloses them). Several also affect upstream X.Org
> (xtest, the NULL derefs, the GLX issues) and may warrant coordinated disclosure.

---

## When ready — push & open PR

```sh
cd sources/xlibre/xserver

# Option A: push topic branch to origin (X11Libre/xserver), PR against release/25.1
git push -u origin wip/ext-handler-vulns
gh pr create --repo X11Libre/xserver \
  --base release/25.1 --head wip/ext-handler-vulns \
  --title "Fix security issues in extension request handlers" \
  --body-file ../../../VULN-FIX-PR.md      # (or paste the body below)

# Option B: push to a fork first (replace <fork-remote>)
# git remote add fork git@github.com:<you>/xserver.git
# git push -u fork wip/ext-handler-vulns
# gh pr create --repo X11Libre/xserver --base release/25.1 \
#   --head <you>:wip/ext-handler-vulns ...
```

---

## Suggested PR body

This series fixes a set of vulnerabilities in client-facing extension request
handlers, found by an audit of the `Proc*`/`SProc*` dispatch surface. Each fix is a
separate commit. All changed files build.

### Memory corruption / OOB

- **Xext/xtest** — stack OOB write in `ProcXTestFakeInput`: the valuator range was
  checked *after* the values were written into `valuators[MAX_VALUATORS]`, and the
  initial bound used `>` instead of `>=`. A client with a 36-axis XI device could write
  attacker-controlled INT32s past the stack array.
- **glx** — OOB read in `__glXDisp_RenderLarge`: the variable-size handler was invoked
  without checking that the fixed command header is present in the first request
  (the non-large path already checks `cmdlen < entry.bytes`).
- **glx** — integer overflow in `CreateContextAttribsARB`: `numAttribs * 8` could wrap,
  defeating the length check and driving an OOB read; added the `UINT32_MAX >> 3` clamp
  the sibling handlers use.
- **xfixes** — `SetCursorName`/`ChangeCursorByName` validated `nbytes` before swapping
  it, so a swapped client could make `MakeAtom()` read past the request (heap disclosure
  into the atom table). Swap before `REQUEST_FIXED_SIZE`.

### NULL-deref DoS

- **Xext/xvmc** — `ProcXvMCGetDRInfo` dereferenced a NULL per-screen private for ports on
  non-XvMC screens.
- **Xi** — `ProcXIChangeCursor` dereferenced NULL when `win == None`.
- **Xi** — `ProcXQueryDeviceState` dereferenced NULL `dev` on the XACE/SELinux `BadAccess`
  path.

### Uninitialized-memory disclosure (CWE-457/200)

The `x_rpcbuf_reserve()` reply buffers were not zeroed, so struct padding / alignment
tails leaked uninitialized heap to clients. Fixed by using `x_rpcbuf_reserve0()` (or
zeroing the pad) in: `ProcXGetFeedbackControl`, `ProcRRGetProviderInfo`,
`ProcXvListImageFormats`, `ProcQueryColors`, `ProcRenderQueryPictFormats`/`QueryFilters`,
`rrGetScreenResources`/`rrGetMultiScreenResources`, `ProcXListInputDevices`,
`ProcXIQueryPointer`, `ProcXIQueryDevice`, `ProcXQueryDeviceState`, the XkbGetMap reply
builders, and `ProcVidModeGetGammaRamp`.

### Hardening / functional

- **xkb** — bounds-check the indicator index in `ReadXkmIndicators` (matches sibling
  readers; the parsed `.xkm` is trusted xkbcomp output, so hardening).
- **Xi** — `ProcXIPassiveGrabDevice` scaled the mask length by 4 twice (1-byte over-read).
- **randr** — `SProcRRGetOutputInfo` dispatched to the wrong handler (note: `rrsdispatch.c`
  is not currently compiled — cleanup).
- **present** — `sproc_present_pixmap_synced` did not byte-swap the trailing notify list.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
