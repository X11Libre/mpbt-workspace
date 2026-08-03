Title: "opencode: separate permission configs for foreground vs. background ships"
Category: active
Status: "assigned"
Assigned-To: "Stargazer"
Created-By: "Enterprise"
Created: ""
Doc-Ref: ""

## Problem

Background-Ships (STARFLEET_LAUNCH_TYPE=auto/background) hängen in opencode Permission-Dialogen fest, weil sie nicht interaktiv antworten können. Aktuelle `.opencode/opencode.json` hat nur Bash-Permissions, keine File-Tool-Permissions → jeder File-Zugriff im Workspace fragt nach.

Foreground-Ships (Terminal) sollen aber weiterhin für sensible Aktionen gefragt werden.

## Lösung: OPENCODE_CONFIG Environment Variable

opencode liest `OPENCODE_CONFIG=/pfad/zu/config.json` (getestet: funktioniert). Kein Kopieren nötig.

### Zwei Config-Dateien:

Zwei opencode-configs werden vom deployment (oder evtl. besser sogar beim launch) automatisch generiert.

1. `.starfleet-ai/var/opencode/opencode.autonomous.json` (autonome schiffe im background - gitignore'd)

   --> erlaubt nur Zugriffe auf starfleetctl und alles innerhalb der aktuelle workspace (den pfad nicht hardcoden!)
   --> aber alles wo gefragt würde stattdessen hartes deny (nicht mehr fragen)

2. `.starfleet-ai/var/opencode/opencode.terminal.json` (Foreground/Terminal-Ships - gitignored'd):

   --> die config wie sie jetzt ist

### Integration in starfleetctl

In `internal/session/launch.go` und `run_cmd.go`:
```go
// Background (auto/background launch type)
os.Setenv("OPENCODE_CONFIG", filepath.Join(root, <pathname>))```

Dann normales `exec opencode` — opencode liest die Config via ENV.

## Referenz

- Stargazer-Hänger (Typo-Pfad `/home/nekred/...`) zeigt das Problem: Background-Ship kann Ask nicht beantworten → tot.
- `OPENCODE_CONFIG` funktioniert (getestet); `--config` Flag nicht.
