Title: "Backport PR #3277 (rootless OOM fix) auf 25.2/25.1/25.0"
Category: active
Kind: "task"
Status: "in-progress"
Assigned-To: "Defiant"
Created-By: "Praetor"
Created: "2026-08-07T14:55:00Z"
Doc-Ref: "Master PR #3277: https://github.com/X11Libre/xserver/pull/3277"

Backport des rootless-OOM-Fixes (dangling screen pixmap bei calloc-Failure) auf alle gepflegten Release-Lines.

## Durchgefuehrt (2026-08-07, Defiant)

- **Applicability**: alle 3 Branches vulnerable (alter Code: free() vor calloc()-Check, pixmap_data_size-Bump vor Fehlercheck identisch in miext/rootless/rootlessScreen.c).
- **Backport-PRs erstellt** (cherry-pick -x von d536dde7b42c, Commit "rootless: fix dangling screen pixmap on RootlessUpdateScreenPixmap() OOM"):
  - 25.2 → PR #3507 (release/25.2)
  - 25.1 → PR #3508 (release/25.1)
  - 25.0 → PR #3509 (release/25.0)
  - Assignee metux, Reviewer X11Libre/dev ueberall.
- **Cross-Link**: Backport-Dashboard-Tabelle an master PR #3277 gehaengt (alle 🔄 Open); Backlinks in allen 3 Backport-PRs.

## Hinweise

- PR #3507 lief im ersten Anlauf auf eine fremde uncommittete Loeschung (include/client.h) im shared `default`-Agent-Clone (xserver-25.2) — per `git checkout -- include/client.h` behoben, dann `github pr make` erneut.
- Bei 25.1/25.0 konnte das Tool die PR-URL direkt nach Erstellung nicht aufloesen (gh-Delay) — PRs existieren, per `gh pr view` verifiziert.

## Offen

- CI der 3 PRs abwarten (rootless baut nur mit hw/xquartz, meson-Lane prueft).
- Merge in release/* nur manuell durch den Praetor.
