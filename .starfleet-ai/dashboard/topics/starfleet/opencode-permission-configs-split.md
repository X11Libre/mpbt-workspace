---
slug: starfleet/opencode-permission-configs-split
title: "opencode: separate permission configs for foreground vs. background ships"
status: "in_progress"
created-by: "Enterprise"
---

## Problem

Background-Ships (STARFLEET_LAUNCH_TYPE=auto/background) hängen in opencode Permission-Dialogen fest, weil sie nicht interaktiv antworten können. Aktuelle `.opencode/opencode.json` hat nur Bash-Permissions, keine File-Tool-Permissions → jeder File-Zugriff im Workspace fragt nach.

Foreground-Ships (Terminal) sollen aber weiterhin für sensible Aktionen gefragt werden.

## Lösung: OPENCODE_CONFIG Environment Variable

opencode liest `OPENCODE_CONFIG=/pfad/zu/config.json` (getestet: funktioniert). Kein Kopieren nötig.

### Zwei Config-Dateien:

1. **`.opencode/opencode.auto.json`** (Background/Auto-Ships):
   ```json
   {
     "permission": {
       "read": { "/home/nekrad/src/xorg/mpbt-workspace/**": "allow", "**": "deny" },
       "write": { "/home/nekrad/src/xorg/mpbt-workspace/**": "allow", "**": "deny" },
       "edit": { "/home/nekrad/src/xorg/mpbt-workspace/**": "allow", "**": "deny" },
       "glob": { "/home/nekrad/src/xorg/mpbt-workspace/**": "allow", "**": "deny" },
       "grep": { "/home/nekrad/src/xorg/mpbt-workspace/**": "allow", "**": "deny" },
       "task": { "/home/nekrad/src/xorg/mpbt-workspace/**": "allow", "**": "deny" },
       "bash": { ".starfleet-ai/bin/starfleetctl *": "allow", "starfleetctl *": "allow", "**": "deny" }
     }
   }
   ```
   - Workspace **allow** für alle Tools → Background nie gefragt
   - Extern **deny** → stillschweigend blockiert (kein Ask)

2. **`.opencode/opencode.terminal.json`** (Foreground/Terminal-Ships):
   ```json
   {
     "permission": {
       "read": { "/home/nekrad/src/xorg/mpbt-workspace/**": "allow", "**": "ask" },
       "write": { "/home/nekrad/src/xorg/mpbt-workspace/**": "allow", "**": "ask" },
       "edit": { "/home/nekrad/src/xorg/mpbt-workspace/**": "allow", "**": "ask" },
       "glob": { "/home/nekrad/src/xorg/mpbt-workspace/**": "allow", "**": "ask" },
       "grep": { "/home/nekrad/src/xorg/mpbt-workspace/**": "allow", "**": "ask" },
       "task": { "/home/nekrad/src/xorg/mpbt-workspace/**": "allow", "**": "ask" },
       "bash": { ".starfleet-ai/bin/starfleetctl *": "allow", "starfleetctl *": "allow", "**": "ask" }
     }
   }
   ```
   - Workspace **allow** → Foreground nie gefragt (allow = nie fragen)
   - Extern **ask** → Foreground wird gefragt (sicher)

### Integration in starfleetctl

In `internal/session/launch.go` und `run_cmd.go`:
```go
// Background (auto/background launch type)
os.Setenv("OPENCODE_CONFIG", filepath.Join(root, ".opencode", "opencode.auto.json"))

// Foreground (terminal launch type)  
os.Setenv("OPENCODE_CONFIG", filepath.Join(root, ".opencode", "opencode.terminal.json"))
```

Dann normales `exec opencode` — opencode liest die Config via ENV.

### Template-Regeneration

`starfleet-bootstrap` erzeugt die beiden Configs aus Templates (`.opencode/templates/`) bei jedem Deploy.

## Offene Fragen

- Sollen Foreground-Ships für Workspace-Writes wirklich `ask` sein? (Empfehlung: `allow` — Workspace ist trusted, nur externe Pfade `ask`/`deny`. Wenn `allow`: beide Configs fast identisch, nur extern `deny` vs `ask`.)
- Plugin-Configs: Plugin nutzt eigene Permissions — meist ok.
- opencode reloadet Config zur Laufzeit? Nein — muss VOR Start gesetzt sein (ENV ist ideal).

## Referenz

- Stargazer-Hänger (Typo-Pfad `/home/nekred/...`) zeigt das Problem: Background-Ship kann Ask nicht beantworten → tot.
- `OPENCODE_CONFIG` funktioniert (getestet); `--config` Flag nicht.
