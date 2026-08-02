Title: "Federation: Multi-Fleet-Netzwerk (TCP-Transport, Peering, Dashboard-Föderation)"
Category: parked
Noted-By: ""
Since: "2026-07-21"
Tags: "starfleet, infra, federation"

Netzwerkfunktionalität für starfleetctl: mehrere Fleets (separate Workspaces oder Maschinen) können zusammenarbeiten.
Betrifft Messaging und Dashboard.

## Ausgangslage

| Komponente | Status | Federtauglich? |
|---|---|---|
| `bridged` (Unix-Socket-Server) | Fertig, nicht in Produktion | **Ja** — Framing ist transport-agnostisch,
TCP-Extension explizit vorgesehen |
| Web-Server (`0.0.0.0:8080`) | Aktiv | **Ja** — REST API bereits network-accessible |
| `dispatch.go` (JSON-RPC) | Fertig | **Ja** — stdin/stdout, aber `dispatch()` ist transport-agnostisch |
| `flock` (advisory lock) | Funktioniert nur lokal | **Nein** — muss für Netzwerk ersetzt werden |
| comms (TSV-Files) | Lokal | **Teilweise** — Lesen geht, Schreiben braucht Lock-Alternative |

**Kernprinzip:** Federation ist Message-Passing zwischen autonomen Bussen, kein geteilter State. Jeder Fleet behält
seinen eigenen `comms` mit eigenem `flock`.

## Phase 1: TCP-Transport für `bridged` (Fundament)

**Ziel:** `bridged` akzeptiert TCP-Verbindungen neben Unix-Sockets.

**Änderungen:**
- `internal/bridged/server.go`: `ListenAndServe` erweitert um TCP-Listener
- `internal/bridged/client.go`: `Call` erweitert um TCP-Dial (neben Unix)
- `internal/bridged/protocol.go`: Keine Änderung nötig (Framing ist bereits transport-agnostisch)
- Auth: Shared-Secret/Token statt `SO_PEERCRED` (das geht nur über Unix-Sockets)

**Architektur:**
```
Fleet A (Host A)                    Fleet B (Host B)
┌──────────────────┐                ┌──────────────────┐
│ bridged daemon   │◄── TCP+Token ──►│ bridged daemon   │
│ :9090            │                │ :9090            │
│ (Unix + TCP)     │                │ (Unix + TCP)     │
└──────────────────┘                └──────────────────┘
```

**Config-Erweiterung (`conf/bridged.yaml`):**
```yaml
bridged:
  unix_socket: ".starfleet-ai/var/bridged.sock"
  tcp_listen: "0.0.0.0:9090"        # neu
  auth_token: "secret-from-env"     # neu, aus $BRIDGED_AUTH_TOKEN
  allowed_peers: []                 # neu, leer = erlaube alle mit gültigem Token
```

**Dateien:**
- `internal/bridged/server.go` — TCP-Listener-Logik
- `internal/bridged/client.go` — TCP-Client
- `internal/bridged/auth.go` — Token-Validierung (neu)
- `conf/bridged.yaml` — Konfiguration

## Phase 2: Federation-Peering

**Ziel:** Fleets kennen gegenseitig ihre Peers und können Nachrichten weiterleiten.

**Konfiguration (`conf/federation.yaml`):**
```yaml
federation:
  enabled: true
  fleet_id: "alpha"                  # eindeutiger Fleet-Name
  peers:
    - id: "beta"
      address: "hostB:9090"
      token: "shared-secret"
    - id: "gamma"
      address: "10.0.0.5:9090"
      token: "other-secret"
```

**Neue Befehle:**
```
starfleetctl federation status          # Peers anzeigen
starfleetctl federation ping <peer>     # Peer erreichbar?
starfleetctl federation tell <fleet> <ship> <text>   # cross-fleet message
starfleetctl federation broadcast <fleet> <text>     # cross-fleet broadcast
```

**Message-Routing:**
1. Ship A sendet `tell B/Scout "status"` → lokaler comms
2. Federation-Router erkennt: "B" ist kein lokaler Ship → an Peer "beta" weiterleiten
3. Peer "beta" empfängt, injiziert in lokalen comms als `tell Scout "status"`
4. Reply über denselben Weg zurück

**Dateien:**
- `internal/federation/router.go` — Message-Routing (neu)
- `internal/federation/peer.go` — Peer-Verbindung (neu)
- `internal/federation/config.go` — Config-Loading (neu)
- `cmd/starfleetctl/federation.go` — CLI-Befehle (neu)

## Phase 3: Dashboard-Föderation

**Ziel:** Web-Dashboard zeigt aggregierten Board-Status aller Fleets.

**Änderungen:**
- `internal/web/web.go`: Neue Endpoints:
  - `GET /api/federation/peers` — Peer-Status
  - `GET /api/federation/board` — Aggregierter Board-Status aller Fleets
  - `GET /api/federation/tasks` — Tasks aller Fleets
- `internal/web/index.html`: Neuer Tab "Federation" mit:
  - Peer-Liste (online/offline/latenz)
  - Aggregierter Board-View (alle Ships, aller Fleets)
  - Cross-fleet Message-Composer

## Phase 4: Cross-Fleet Task-Assignment (optional)

**Ziel:** Tasks können Ships in anderen Fleets zugewiesen werden.

Tasks als Messages übertragen (nicht als Git-Commits):
1. `starfleetctl task capture --federation beta --title "Fix bug"` → sendet Task-Definition als Message an Peer beta
2. Peer beta empfängt, erstellt lokalen Task, weist lokalen Ship zu
3. Status-Updates als federeated Messages zurück

## Priorisierung

| Phase | Aufwand | Nutzen | Abhängigkeiten |
|---|---|---|---|
| **1: TCP-Transport** | ~2-3 Tage | Grundlage für alles | Keine |
| **2: Federation-Peering** | ~3-4 Tage | Cross-fleet Messaging | Phase 1 |
| **3: Dashboard** | ~2 Tage | Visuelle Übersicht | Phase 1 |
| **4: Cross-Fleet Tasks** | ~4-5 Tage | Koordination über Fleets | Phase 2 |

**Gesamt:** ~11-14 Tage.

## Was nicht gebraucht wird

- **Kein MCP** — das Bridged-Protokoll ist bereits ausreichend
- **Keine Änderung am comms** — Federation leitet Messages weiter, der lokale Bus bleibt wie er ist
- **Kein distributed lock** — Jeder Fleet hat seinen eigenen Bus mit eigenem flock
- **Kein etcd/Redis** — Zu komplex für den aktuellen Use Case

## Referenzen

- Bestehende Vision: `dashboard/topics/long-term-fleet-architecture-vision-bridge-command-frontend.md`
- Bridged-Paket: `internal/bridged/` (explizit als "first concrete step" dokumentiert)
- Web-Server: `internal/web/` (bereits `0.0.0.0:8080`)
