Title: "Web: SPA missing Cache-Control header causes stale JS after deployments"
Category: active
Kind: task
Status: "open"
Created-By: "Laforge"
Created: "2026-09-26T15:34:19Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: task-web-spa-missing-cache-control-header-causes-stale-js-after-deployments

Bug: index.html served without Cache-Control header, causing browsers to cache stale JavaScript after deployments. Fix: add Cache-Control: no-cache header in serveIndex handler.
