Title: "opencode data.directory unter .starfleet-ai/var/ pro Ship?"
Category: analysis
Kind: task
Status: "assigned"
Created-By: "Defiant"
Created: "2026-08-04T11:53:34Z"
Assigned-To: "__auto__"
Doc-Ref: "—"
Slug: analysis/task-opencode-data-directory-unter-starfleet-ai-var-pro-ship

Analyse: ob opencode config 'data.directory' auf workspace-intern .starfleet-ai/var/opencode/<ship-id>/ gelegt werden kann (gitignore'd). Vorteile: pro-Schiff-Isolation, einfachere Session-Analyse/Restarts, DB-Pruning pro Ship, kein globaler ~/.local/share/opencode Wust. Prüfen: opencode unterstützt data.directory config key, Pfad relativ zu CWD oder absolut? Per-Ship-Config generiert launch.go bereits (generateOpencodeConfig) — natürlicher Einhängepunkt. Konflikte mit parallelen Ships? Locking? Migration bestehender Sessions?
