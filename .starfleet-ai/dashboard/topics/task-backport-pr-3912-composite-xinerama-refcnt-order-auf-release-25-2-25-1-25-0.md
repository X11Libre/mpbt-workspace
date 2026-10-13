Title: "Backport PR #3912 composite/Xinerama refcnt-order auf release/25.2, 25.1, 25.0"
Category: active
Kind: task
Status: "assigned"
Created-By: "Enterprise"
Created: "2026-10-13T08:01:08Z"
Assigned-To: "Enterprise"
Doc-Ref: "—"
Slug: task-backport-pr-3912-composite-xinerama-refcnt-order-auf-release-25-2-25-1-25-0

Manueller Backport von X11Libre/xserver PR #3912 (PR-Head 6240f655, ungemergt): Xext/composite/compext.c — pixmap-Referenz VOR AddResource nehmen (Xinerama-Pfad); sonst droppt dixDestroyPixmap() bei AddResource-Fehler die Window-Referenz (UAF). Alle drei Releases als verwundbar gemessen (refcnt nach AddResource). Quelle = PR-Head-Commit (Tooling unterstuetzt unmerged noch nicht, Task dafuer an LaForge). Branches: rfc/backport-25.{2,1,0}-composite-xinerama-refcnt. Build -Dwerror=true je Zweig. Cross-Link an #3912. Kein Merge (Release-Merge = Maintainer).
