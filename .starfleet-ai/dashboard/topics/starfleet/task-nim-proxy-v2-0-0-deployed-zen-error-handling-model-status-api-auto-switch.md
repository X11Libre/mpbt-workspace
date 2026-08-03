Title: "NIM-Proxy v2.0.0 deployed - ZEN error handling, Model-Status API, auto-switch"
Category: starfleet
Kind: task
Status: "open"
Created-By: "Enterprise"
Created: "2026-08-03T18:19:43Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: starfleet/task-nim-proxy-v2-0-0-deployed-zen-error-handling-model-status-api-auto-switch

Implementation complete: nim-proxy/main.go enhanced with ZEN error detection (zen-ratelimit, nim-overload), Model-Status API (/health, /models, /models/<name>), automatic model switch via HTTP 429 + SwitchModel in response body. Plugin simplified to v2.6.0: removed log-monitor, retry-poll, executeAction(switch-model). Bootstrap + timer restart + web restart done. Next: integrate proxy into opencode.json generator, support global user config, auto-use for new ships.
