Title: "service autostart config + model-proxy OPENCODE_API_KEY"
Category: active
Kind: "task"
Status: "done"
Assigned-To: "Enterprise"
Created-By: "Enterprise"
Created: "2026-09-07T12:17:47Z"
Doc-Ref: "—"

Empfindlich: (a) Services (web, model-proxy, timer) sollen beim Flagship-Start ueber ein config-yaml (services.yaml, autostart-Liste) hochkommen - Default on-demand, ohne lokalen Cron. (b) Bug: model-proxy-Daemon hat kein OPENCODE_API_KEY im Env (kein zen-provider in opencode config) -> zen-auth fails 'free tier only'. Backfill aus ~/.profile ergaenzen.

- 2026-09-07T12:47:47Z Enterprise: completed
