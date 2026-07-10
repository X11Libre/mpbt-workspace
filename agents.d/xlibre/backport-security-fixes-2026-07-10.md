---
slug: xlibre/backport-security-fixes-2026-07-10
title: "Backport xorg/main security fixes (CVE-2026-55999, CVE-2026-56000) — 2026-07-10"
order: 100
owner: "Excelsior"
---

## Summary

Backported three merged security fixes from upstream `xorg/main` (MR !2250) to all
maintained branches: `master`, `release/25.2`, `release/25.1`, `release/25.0`.

Each fix cherry-picked `-x` (preserves author + `Signed-off-by`), then submitted via
`scripts/xx-make-pr.sh` from the per-release agent clone — ensures correct PR title
format (`(branch) subject`), reviewer assignment (`X11Libre/dev`), and incubator
markup (`[PR #N] ` + `PR:` trailer).

## Fixes backported

| CVE / ID | Upstream commit | Component | Description |
|----------|----------------|-----------|-------------|
| **CVE-2026-55999** / ZDI-CAN-30498 | `fbf7bac22` | glamor | Reject fonts with per-glyph metrics exceeding `maxbounds` (heap OOB write via malicious PCF) |
| — | `e31efd3e1` | fb/mi/glamor | Reject glyphs with negative dimensions (OOB write in `while (height--)` loops) |
| **CVE-2026-56000** / ZDI-CAN-30561 | `2779affbd` | GLX | Free old context tag before allocating new one in `CommonMakeCurrent` (UAF via dangling pointer) |

## PRs created

All 12 PRs have `Signed-off-by: Enrico Weigelt, metux IT consult <info@metux.net>`.

### master (3 PRs — **all APPROVED**)
| PR | Title | Status |
|----|-------|--------|
| [#3292](https://github.com/X11Libre/xserver/pull/3292) | `(master) glamor: reject fonts with per-glyph metrics exceeding maxbounds` | ✅ **APPROVED** |
| [#3293](https://github.com/X11Libre/xserver/pull/3293) | `(master) fb/mi/glamor: reject glyphs with negative dimensions` | ✅ **APPROVED** |
| [#3294](https://github.com/X11Libre/xserver/pull/3294) | `(master) glx: free old context tag before allocating new one in CommonMakeCurrent` | ✅ **APPROVED** |

### release/25.2 (3 PRs)
| PR | Title | Status |
|----|-------|--------|
| [#3288](https://github.com/X11Libre/xserver/pull/3288) | `(release/25.2) glamor: reject fonts with per-glyph metrics exceeding maxbounds` | ⏳ Review requested |
| [#3289](https://github.com/X11Libre/xserver/pull/3289) | `(release/25.2) fb/mi/glamor: reject glyphs with negative dimensions` | ⏳ Review requested |
| [#3290](https://github.com/X11Libre/xserver/pull/3290) | `(release/25.2) glx: free old context tag before allocating new one in CommonMakeCurrent` | ⏳ Review requested |

### release/25.1 (3 PRs)
| PR | Title | Status |
|----|-------|--------|
| [#3304](https://github.com/X11Libre/xserver/pull/3304) | `(release/25.1) glamor: reject fonts with per-glyph metrics exceeding maxbounds` | ⏳ Review requested |
| [#3305](https://github.com/X11Libre/xserver/pull/3305) | `(release/25.1) fb/mi/glamor: reject glyphs with negative dimensions` | ⏳ Review requested |
| [#3306](https://github.com/X11Libre/xserver/pull/3306) | `(release/25.1) glx: free old context tag before allocating new one in CommonMakeCurrent` | ⏳ Review requested |

### release/25.0 (3 PRs)
| PR | Title | Status |
|----|-------|--------|
| [#3307](https://github.com/X11Libre/xserver/pull/3307) | `(release/25.0) glamor: reject fonts with per-glyph metrics exceeding maxbounds` | ⏳ Review requested |
| [#3308](https://github.com/X11Libre/xserver/pull/3308) | `(release/25.0) fb/mi/glamor: reject glyphs with negative dimensions` | ⏳ Review requested |
| [#3309](https://github.com/X11Libre/xserver/pull/3309) | `(release/25.0) glx: free old context tag before allocating new one in CommonMakeCurrent` | ⏳ Review requested |

## Duplicates closed

Closed 9 duplicate PRs created earlier via manual `gh pr create` (missing branch prefix,
no reviewers):
- #3291 (dup of #3288), #3295–#3303

## Notes

- The VULN-*.md files in workspace root document a **separate** audit (June 2026) of
  20 extension request-handler vulnerabilities on `release/25.1`. Those are distinct
  from the 3 upstream CVEs backported here. Fix branch `wip/ext-handler-vulns` no
  longer exists; would need to be recreated from the VULN scan reports if pursued.
- Do not merge release/* PRs until maintainer gives green light (green CI + review
  does not authorize merge per policy).

