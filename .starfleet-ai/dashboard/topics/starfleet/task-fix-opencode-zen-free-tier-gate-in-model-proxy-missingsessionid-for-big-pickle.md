Title: "Fix OpenCode Zen free-tier gate in model-proxy (MissingSessionID for big-pickle)"
Category: starfleet
Kind: task
Status: "open"
Created-By: "Enterprise"
Created: "2026-09-09T08:47:36Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: starfleet/task-fix-opencode-zen-free-tier-gate-in-model-proxy-missingsessionid-for-big-pickle

Zen verlangt inzwischen UA + x-opencode-session/client/project (400 MissingSessionID). Lösung: Provider-Typ 'opencode-zen', UA-Stempel + Forward der echten Client-Session (X-Session-Id -> x-opencode-session) für Prefix-Caching. commits 76f85a4 + d0964ab, deployed, e2e 200.
