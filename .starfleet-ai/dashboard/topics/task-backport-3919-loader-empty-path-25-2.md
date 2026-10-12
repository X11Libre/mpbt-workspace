---
Title: "Backport #3919 (loader empty module path) auf release/25.2"
Category: active
Kind: "task"
Status: "assigned"
Assigned-To: "XL-2"
Created-By: "XL-2"
Created: "2026-10-12T14:30:00Z"
Doc-Ref: "PR #3920"
---

Backport von master-PR #3919 (xfree86: loader: treat empty module path as not present,
mergeCommit 3c36e9029d) auf release/25.2.

Status:

- **PR #3920** (head `pr/release/25.2-xfree86-loader-treat-empty-module-path-as-not-present_2026-10-12_14-44-05`,
  base release/25.2 `df2af75853`, Commit `bfb0960c00`): von Defiant angelegt, per Praetor-Auftrag an
  XL-2 uebergeben (m2672/m2673). Kein zweiter PR.
- Commit: `cherry-pick -x 3c36e9029d`, 1x Signed-off-by (Original-Autor Enrico Weigelt),
  `(cherry picked from commit 3c36e9029d...)`-Trailer, 2 Dateien (loaderProcs.h +8, loadmod.c +5/-3).
- Applicability release/25.2: **vulnerable** (kein Empty-String-Guard in LoaderSetPath; spurious
  "Failed to store module search path" Log).
- Task-Branch `rfc/backport-25.2-loader-empty-path` @ad5d9c74d9 (lokal, Gegenstueck zum PR-Head).
- Cross-Links: #3919 Body mit Backport-Liste (GH-3920, GH-3922), #3920 Body mit "Backport of #3919".
- CI: laufen (30 checks), bisher gruen auf den Platform-Lanes.
- **Merge macht der Praetor** — kein Auto-Merge (Release-Regel).

Geschwister: 25.1 = XL-1 (#3922), 25.0 = N-A (1-arg LoaderSetPath, Code fehlt dort).