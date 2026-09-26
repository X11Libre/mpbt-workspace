Title: "Web: payload links in comms messages not clickable"
Category: active
Kind: "task"
Status: "done"
Assigned-To: "—"
Created-By: "Laforge"
Created: "2026-09-26T14:04:46Z"
Doc-Ref: "—"

Bug: payload links in comms messages show raw references instead of clickable links to view the actual payload in the web UI

- 2026-09-26T14:06:02Z Laforge: progress 10% (Claiming task and starting investigation - found two bugs from Enterprise's analysis: 1) index.html missing ? in download URL, 2) web.go apiStoreFile handler ignores download param)

- 2026-09-26T14:09:05Z Laforge: progress 100% (Fixed both bugs: 1) index.html downloadAttachment function now uses ?download=1 instead of &download=1, 2) web.go apiStoreFile handler now checks for download=1 query parameter and sets Content-Disposition: attachment accordingly)

- 2026-09-26T14:30:47Z Laforge: progress 100% (Fixed both bugs and verified: 1) index.html downloadAttachment uses ?download=1, 2) web.go apiStoreFile handler respects download=1 query param with proper Content-Disposition header. Built, deployed, and tested - curl shows Content-Disposition: attachment; filename=m123577__payload.txt when download=1 is present)

- 2026-09-26T15:34:48Z Laforge: progress 100% (Fixed both bugs and verified: 1) index.html downloadAttachment uses ?download=1, 2) web.go apiStoreFile handler respects download=1 query param with proper Content-Disposition header. 3) Added Cache-Control: no-cache to serveIndex to prevent stale JS caching. Built, deployed, and tested - both fixes working.)
