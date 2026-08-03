---
slug: starfleet/opencode-permission-configs-split
title: "opencode: separate permission configs for foreground vs. background ships"
status: "in_progress"
created-by: "Enterprise"
---

## Problem

Background-Ships (STARFLEET_LAUNCH_TYPE=auto/background) hängen in opencode Permission-Dialogen fest, weil sie nicht interaktiv antworten können. Aktuelle `.opencode/opencode.json` hat nur Bash-Permissions, keine File-Tool-Permissions → jeder File-Zugriff im Workspace fragt nach.

Foreground-Ships (Terminal) sollen aber weiterhin für sensible Aktionen gefragt werden.

## Lösung

Zwei Konfigurationen, auto-generiert beim Ship-Start:

1. **`.opencode/opencode.auto.json`** (Background/Auto-Ships):
   - Workspace (`/home/nekrad/src/xorg/mpbt-workspace/**`) → `allow` für **alle** Tools (read/write/edit/glob/grep/task/bash)
   - Externe Pfade → `ask` / `deny`
   - Keine interaktiven Prompts

2. **`.opencode/opencode.terminal.json`** (Foreground/Terminal-Ships):
   - Workspace → `ask` für write/edit, `allow` für read/glob/grep
   - Externe Pfade → `ask` / `deny`
   - Sensible Aktionen (git push, deploy, rm -rf, etc.) → `ask`

3. **Start-Wrapper** (`scripts/opencode-launch` oder in `launch.go`):
   - Erkenne Launch-Type (`STARFLEET_LAUNCH_TYPE` / `STARFLEET_SHIP_ID` + Board-Status)
   - Kopiere passende Config nach `.opencode/opencode.json` vor `exec opencode`
   - Configs werden beim `starfleet-bootstrap` aus Templates generiert

## Template-Struktur

```
.opencode/
├── templates/
│   ├── opencode.auto.json.tmpl      # breit allow
│   └── opencode.terminal.json.tmpl  # selektiv ask
├── opencode.json                    # aktiv (vom Wrapper gesetzt)
└── opencode.jsonc                   # optional: shared base
```

## Umsetzungsschritte

1. Templates anlegen (`.opencode/templates/`)
2. Wrapper-Script `scripts/opencode-launch` bauen (erkennt Launch-Type, setzt Config)
3. In `internal/session/launch.go` / `run_cmd.go` Wrapper statt direktem `exec opencode` nutzen
4. `starfleet-bootstrap` regenerated Templates bei Config-Änderungen
5. Test: Background-Ship via Web starten → keine Permission-Asks im Workspace

## Offene Fragen

- Sollen Foreground-Ships *wirklich* für Workspace-Writes fragen? (Meine Empfehlung: nein — Workspace ist trusted, nur externe Pfade fragen. Wenn ja: Template anpassen.)
- Wie geht man mit Plugin-Configs um? (Plugin selbst hat eigene Permissions — meist ok.)
- opencode reloadet Config bei Änderung? (Nein — muss VOR Start gesetzt sein.)

## Referenz

- Stargazer-Hänger (Typo-Pfad `/home/nekred/...`) zeigt das Problem: Background-Ship kann Ask nicht beantworten → tot.
