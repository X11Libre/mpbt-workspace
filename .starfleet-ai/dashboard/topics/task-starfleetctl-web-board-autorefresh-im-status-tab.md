Title: "starfleetctl web: Board-Autorefresh im Status-Tab"
Category: active
Kind: "task"
Status: "done"
Assigned-To: "Scotty"
Created-By: "Enterprise"
Created: "2026-09-09T15:24:32Z"
Doc-Ref: "—"

Feature: Das Web-Dashboard (internal/web/index.html) laedt die Schiffsliste (/api/board) aktuell nur bei Tab-/Event-Wechsel (refresh() in index.html um Z.883/890/2492). Gewuenscht: zyklischer Autorefresh des Board im Status-Tab, z.B. setInterval alle ~30s, damit Live-Fortschritt (ship-note, progress) automatisch sichtbar wird.

Hintergrund/Kontext:
- Live-Fortschritt wird ueber die Ship-Note gefuehrt (comms status --note "rebase X von Y commits"), wird im Board bereits gerendert (CLI-NOTE-Spalte, Web index.html ca. Z.1233).
- progress-Feld (Prozent) existiert ebenfalls (records.go, apiBoard in web.go), Browser-Balken zeigt nur Werte >0 an.
- Board-Rendering: loadBoard() in index.html ca. Z.1191-1237.

Anforderungen:
1. Status-Tab-Board periodisch neu laden (30s-Intervall), ohne das komplette page refresh bzw. Terminal-Streams (loadScreen-Intervall) zu stoeren.
2. Sauber: nur den aktiven Status-Tab pollen, Intervall bei Tab-Wechsel beenden (keine Leaks).
3. Kein Funktionsbruch bestehender Tabs/refresh()-Logik.
4. Vorhandenen textuellen Fortschritt (ship-note) unveraendert weiter anzeigen; keine API-Aenderung noetig (BoardEntryJSON liefert note + progress bereits).

Umsetzungsort: .starfleet-ai/src/starfleetctl/internal/web/index.html (+ falls noetig web.go).
Ablauf: make all (Tests gruen), sauberer Commit mit sign-off (Enrico Weigelt, metux IT consult), ./starfleet-bootstrap deploy, web restart + timer worker restart, HTTP 200-Check. Dashboard-Topic auf done setzen und ggf. Report/Comms an McKinley + Enterprise.

- 2026-09-09T17:02:55Z Scotty: completed
