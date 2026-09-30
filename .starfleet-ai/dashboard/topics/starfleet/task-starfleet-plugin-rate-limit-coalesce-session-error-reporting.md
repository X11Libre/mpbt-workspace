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

- 2026-09-30T09:27:44Z Laforge: progress 100% (Implemented rate-limiting/coalescing for session.error reporting:

1. Added sessionErrorBuffer to collect unique error messages
2. Added sessionErrorTimer with 5-minute cooldown (SESSION_ERROR_COOLDOWN_MS = 5 min)
3. On session.error: buffer unique errors, reset timer, and after 5 minutes of no new errors, send a single aggregated error-handle report with count and details
4. Fixed missing .v on hasSwitchedToFallback in executeAction call
4. Updated PLUGIN_VERSION to 2.5.4
5. Built and deployed via starfleet-bootstrap (esbuild bundle check OK)

Verified: plugin builds and passes esbuild bundle check. Ready for production.)
