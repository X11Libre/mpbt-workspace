Title: "Web: SPA missing Cache-Control header causes stale JS after deployments"
Category: active
Kind: "task"
Status: "done"
Assigned-To: "—"
Created-By: "Laforge"
Created: "2026-09-26T15:34:19Z"
Doc-Ref: "—"

Bug: index.html served without Cache-Control header, causing browsers to cache stale JavaScript after deployments. Fix: add Cache-Control: no-cache header in serveIndex handler.

- 2026-09-26T15:34:31Z Laforge: progress 100% (Fixed: serveIndex handler now sets Cache-Control: no-cache header. Verified with curl - Cache-Control: no-cache is returned for /. Also verified download functionality still works with Content-Disposition: attachment when ?download=1 is present. Both fixes committed and deployed.)
