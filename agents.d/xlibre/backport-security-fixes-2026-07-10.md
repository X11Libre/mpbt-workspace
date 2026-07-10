---
slug: xlibre/backport-security-fixes-2026-07-10
title: "Backport of 3 security fixes from xorg/main to all branches (2026-07-10)"
order: 900
owner: "Excelsior"
---

## Backport Status: 3 Security Fixes from xorg/main

Three security fixes from xorg/main (merged as part of MR !2250) have been backported to all XLibre branches:

### Source Commits (xorg/main)
- `fbf7bac22` — glamor: reject fonts with per-glyph metrics exceeding maxbounds (CVE-2026-55999/ZDI-CAN-30498)
- `e31efd3e1` — fb/mi/glamor: reject glyphs with negative dimensions
- `2779affbd` — glx: free old context tag before allocating new one in CommonMakeCurrent (CVE-2026-56000/ZDI-CAN-30561)

### Created PRs (all via `xx-make-pr.sh` with Signed-off-by)

| Branch | Fix | PR | Status |
|--------|-----|-----|--------|
| master | glamor maxbounds | #3292 | ✅ **APPROVED** |
| master | fb/mi/glamor negative glyphs | #3293 | ✅ **APPROVED** |
| master | glx context tag UAF | #3294 | ✅ **APPROVED** |
| release/25.2 | glamor maxbounds | #3288 | ⏳ Review requested (X11Libre/dev) |
| release/25.2 | fb/mi/glamor negative glyphs | #3289 | ⏳ Review requested (X11Libre/dev) |
| release/25.2 | glx context tag UAF | #3290 | ⏳ Review requested (X11Libre/dev) |
| release/25.1 | glamor maxbounds | #3304 | ⏳ Review requested (X11Libre/dev) |
| release/25.1 | fb/mi/glamor negative glyphs | #3305 | ⏳ Review requested (X11Libre/dev) |
| release/25.1 | glx context tag UAF | #3306 | ⏳ Review requested (X11Libre/dev) |
| release/25.0 | glamor maxbounds | #3307 | ⏳ Review requested (X11Libre/dev) |
| release/25.0 | fb/mi/glamor negative glyphs | #3308 | ⏳ Review requested (X11Libre/dev) |
| release/25.0 | glx context tag UAF | #3309 | ⏳ Review requested (X11Libre/dev) |

### Notes
- All PRs created via `backport-commit` → `xx-make-pr.sh` from isolated agent clones
- All commits preserve original author + message + `(cherry picked from commit <sha>)`
- All commits have `Signed-off-by: Enrico Weigelt, metux IT consult <info@metux.net>`
- PR titles include target branch prefix: `(master)` or `(release/25.x)`
- X11Libre/dev team reviewers assigned on all release branch PRs
- Duplicate PRs (#3291, #3295-#3303) closed

### Next Steps
1. Merge approved master PRs (#3292, #3293, #3294)
2. Wait for review on release branch PRs (9 total)
3. Maintainers manually merge release PRs per policy (CI green + review ≠ auto-merge)
