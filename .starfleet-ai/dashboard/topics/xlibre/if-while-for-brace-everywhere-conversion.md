Title: "if/while/for brace-everywhere conversion (xserver coding style)"
Category: active
Status: "done"
Assigned-To: "—"
Doc-Ref: "PR #3258 (`os/Xtranssock.c` `set_sun_path()`, master, single commit, build-verified via `meson setup` + `ninja hw/vfb/Xvfb hw/xnest/Xnest`)"
Tags: "xlibre"

Praetor confirmed 2026-07-03: always brace `if`/`while`/`for`/`else` bodies, even single-statement, in **all new/touched
code from now on** (already the rule since PR #3199, now made permanent policy) — **and** convert existing unbraced
bodies successively, in small self-contained batches (one file or a handful of functions per PR, brace-only diffs, no
mixed changes). **First batch (Potemkin):** braced `set_sun_path()`'s 4 previously-unbraced `if`/`else if` bodies,
matching the file's already-dominant same-line brace style; scope deliberately kept to exactly this one function (the
candidate this row itself named earlier), not the whole file, to keep the diff trivially reviewable. Update this row
each time a further batch lands so the initiative doesn't stall silently.

## Progress

- [x] **Batch 1 (Potemkin):** `set_sun_path()` in `os/Xtranssock.c` — 5 unbraced if/else if bodies braced (PRs opened for 25.1 and 25.2 branches)
  - `if (!port || !*port || !path)`
  - `if (port[0] == '@')`
  - `else if (abstract)`
  - `if (*port == '/')`
  - `if ((ssize_t)(strlen(at) + strlen(upath) + strlen(port)) > maxlen)`

- [ ] Batch 2: Next function/file
- [ ] Batch 3: ...

- 2026-09-17T12:29:52Z Scotty: completed
