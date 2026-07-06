---
slug: licensing-policy
title: "Licensing policy"
order: 200
---

## Licensing policy

Two different scopes — don't conflate them:

- **New files that end up linked into the xserver binary itself (or a driver)** — anything that
  ships as part of the actual X server/driver deliverable — are, from now on, licensed
  **X11 OR MIT OR AGPL-3.0-or-later** (multi-licensed; the recipient picks whichever of the three
  suits them). Praetor decision, 2026-07-02. The X11/MIT option keeps `X11Libre/xserver`'s own
  convention (`COPYING`: *"copyright holders of new code should use this license statement where
  possible"*) and keeps proprietary consumers (the NVIDIA blob, see the NVIDIA-ABI section)
  unaffected, since they can just use that grant; AGPL-3.0-or-later is offered as an *additional*
  choice, not a replacement — this is why the AGPL-vs-NVIDIA-friendliness tension flagged earlier
  the same day doesn't apply once it's multi-licensed rather than AGPL-only. Applies only to a
  genuinely **new** file wholly authored by the praetor (or an agent on their behalf) — editing
  an existing file that already carries the plain X11/MIT grant does **not** relicense that file;
  the new triple-license only attaches to brand-new files.
- **New files that are NOT part of the final delivery** — helper scripts, CI workflow/config, dev
  tooling, build orchestration — wherever they live (mpbt-workspace's own `scripts/*`, but equally
  a newly-authored file under e.g. `.github/scripts/` inside an xserver/driver clone) — are, from
  now on, **AGPL-3.0-or-later only**. mpbt-workspace's own tooling was already fully relicensed
  this way, 2026-07-02 (see `LICENSE` + the `SPDX-License-Identifier: AGPL-3.0-or-later` +
  copyright header pattern used throughout `scripts/*` — copy that pattern for any new script
  anywhere, xserver-repo helper scripts included).

**Not retroactive yet — explicitly deferred, do not act on this without a fresh go-ahead:**
applying either license to *existing* files. Praetor's stated plan (2026-07-02): eventually
retrofit files that were written **solely** by the praetor (never touching code originally
authored by someone else — e.g. any of the upstream X.Org/XFree86 contributors listed in
`X11Libre/xserver`'s `COPYING`). This is recorded here purely as a **TODO** — don't relicense any
existing file proactively; wait for an explicit instruction each time.
