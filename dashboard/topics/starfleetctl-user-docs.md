---
slug: starfleetctl-user-docs
title: "starfleetctl: User-Dokumentation erstellen"
category: active
status: offen
doc_ref: "—"
---

## starfleetctl: User-Dokumentation erstellen

### Ziel

Eine brauchbare User-Dokumentation für starfleetctl erstellen — als `.md`-Datei
im Repo, im README verlinkt, damit man sie über GitHub schnell finden kann.

### Scope

- Installationsanleitung (Go-Toolchain, `go install`, oder gebaut aus dem Repo)
- Kurzreferenz aller Subcommands mit Beispielen
- Deployment-Modell (genesis → bootstrap)
- Konzept-Erläuterung (Ships, agent-bus, pr-claim, dashboard)
- Troubleshooting / häufige Fehlerquellen

### Format / Ablage

- `docs/USER.md` (oder `README` im Unterverzeichnis) im starfleetctl-Repo
- Link aus dem Haupt-README.md via `## Documentation` Sektion
- GitHub rendert `.md` direkt — kein extra Tooling nötig

### Offene Fragen

- Umfang: vollständig oder schrittweise (erst Quickstart, dann erweitern)?
- Soll `starfleetctl --help`-Output als Basis dienen oder komplett neu geschrieben?
- Sprache: englisch (Projekt-Sprache) oder bilingual?

### Referenzen

- Aktuelles README: `.starfleet-ai/src/starfleetctl/README.md`
- Subcommands: `.starfleet-ai/src/starfleetctl/cmd/starfleetctl/`
- Dashboard-Thema: `dashboard/themes/readme-for-the-mpbt-hq-starfleetctl-repo-itself.md` (offen)
