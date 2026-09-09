Title: "Fix OpenCode Zen free-tier gate in model-proxy (MissingSessionID for big-pickle)"
Category: starfleet
Kind: "task"
Status: "done"
Assigned-To: "—"
Created-By: "Enterprise"
Created: "2026-09-09T08:47:36Z"
Doc-Ref: "—"

Zen verlangt inzwischen UA + x-opencode-session/client/project (400 MissingSessionID). Lösung: Provider-Typ 'opencode-zen', UA-Stempel + Forward der echten Client-Session (X-Session-Id -> x-opencode-session) für Prefix-Caching. commits 76f85a4 + d0964ab, deployed, e2e 200.

- 2026-09-09T08:47:43Z Enterprise: completed
