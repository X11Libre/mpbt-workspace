Title: "web : funk: sortierung"
Category: active
Kind: "task"
Status: "done"
Assigned-To: "Stargazer"
Created-By: "McKinley"
Created: "2026-08-02T19:47:20Z"
Doc-Ref: "—"

Starfleet web frontend: funk tab: zeitlich sortieren, neueste zuerst
Fixed 2026-08-03 (starfleetctl 160a946): loadTalk() reversed the API's
newest-first result, so the Funk tab showed the oldest message on top.
Removed the reverse — newest message is now on top. Deployed via bootstrap +
web/timer restart, verified live (newest-first ordering).
