Title: "starfleet: plugin: rate-limit/coalesce session.error reporting"
Category: starfleet
Kind: "task"
Status: "assigned"
Assigned-To: "Laforge"
Created-By: "Enterprise"
Created: "2026-09-30T09:17:43Z"
Doc-Ref: "—"

Rate-limit/coalesce session.error reporting: currently 77% of bus messages are auto-generated session.error spam (4,072 from Enterprise/Barcley alone). One aggregated report per ship per N minutes instead of one per failed request. Suggested by Voyager.

- 2026-09-30T09:19:00Z Laforge: progress 10% (Starting investigation: need to understand current session.error reporting in starfleet plugin and implement rate-limiting/coalescing)
