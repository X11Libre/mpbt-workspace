Title: "dashboard access in planning mode"
Status: done
Created-By: Enterprise
Created: 2026-07-31T12:12:00Z
Slug: plan-mode-dashboard-access

Möchte daß agents im plan mode auch schon zugriff auf das
dashboard bekommen - lesend und schreibend.

## Umsetzung (2026-07-31, Enterprise)

`.opencode/opencode.json`: `agent.plan.permission.bash` erlaubt explizit
`starfleetctl dashboard*` und `.starfleet-ai/bin/starfleetctl dashboard*`
(lesend UND schreibend via CLI). Plan-Mode bleibt ansonsten beim opencode-
Default (edit denied, bash default allow) — die expliziten Allow-Regeln sind
als Absicherung gegen künftige Default-Änderungen gedacht.

Hinweis: Config wird nicht hot-reloaded — wirkt nach opencode-Neustart.
