Title: "Model-proxy: add trace logging and log rotation"
Category: active
Kind: "task"
Status: "open"
Assigned-To: "—"
Created-By: "Laforge"
Created: "2026-09-29T18:41:58Z"
Doc-Ref: "—"

Add request/response logging and fallback traces in model-proxy. Implement time-based log rotation to prevent disk full.

- 2026-09-29T18:42:08Z Laforge: progress 10% (Claiming task and starting investigation - need to locate model-proxy code and understand current logging)

- 2026-09-29T18:57:02Z Laforge: progress 100% (Implemented trace logging and log rotation:

- Added rotatingWriter with daily rotation at midnight (time-based rotation)
- Proxy now uses rotating logger via MODEL_PROXY_LOG_FILE env (set by daemon)
- Added request/response trace logging in ServeHTTP (method, path, remote, status, latency)
- Fallback traces already present (provider saturation, retries)
- Removed daemon stdout/stderr redirection; proxy manages its own log file
- Verified working: logs show request traces and fallback traces

Log rotation is time-based (daily at midnight) via rotatingWriter.)
