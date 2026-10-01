Title: "Web: einzelne Sessions loeschen koennen (ueber opencode session delete)"
Category: active
Kind: "task"
Status: "assigned"
Assigned-To: "Laforge"
Created-By: "Voyager"
Created: "2026-10-01T13:13:36Z"
Doc-Ref: "—"

Vom Maintainer als eigenes Ticket gewünscht. Der sichere Weg existiert bereits — die
Aufgabe ist die Anbindung, nicht die Erfindung. Alle Angaben am Source nachgelesen.

WIE DIE SESSIONS GESPEICHERT SIND (relevant, weil es die Lösung einschränkt):
/api/sessions liest NICHT eine eigene DB. Es liest die opencode-DB
  /home/nekrad/.local/share/opencode/opencode.db
Pfad aufgelöst über 'opencode db path' (internal/ocsessions/ocsessions.go:98), gelesen
per CLI-Aufruf: exec.Command("sqlite3", "-readonly", "-json", db, sql) (Zeile 326).
Der Paketkommentar sagt ausdrücklich: "The DB is always opened read-only (sqlite3
-readonly) — SQLite's WAL mode lets a reader coexist with the live opencode writer
without blocking it."

=> KEIN Row-DELETE gegen die Live-DB. Das ist die entscheidende Einschränkung: die DB
   gehört opencode, wird von ihm live im WAL-Modus geschrieben, und ein direktes
   DELETE darauf droht mit Korruption und Datenverlust. Defiant hat am 2026-09-30 bereits
   darauf hingewiesen; dieser Hinweis ist bestätigt und nicht neu.

DER SANKTIONIERTE WEG EXISTIERT BEREITS:
  opencode session delete <sessionID>
Verifiziert: 'opencode session --help' listet list und delete; delete erwartet genau eine
Positionsangabe sessionID, sonst keine weiteren relevanten Flags.
Also NICHT sqlite3 DELETE absetzen, sondern dieses Kommando aufrufen. Damit bleibt die
Konsistenz der Live-DB Sache von opencode.

WAS ZU BAUEN IST:
1. Route /api/sessions/<id> erweitern. Aktuell: internal/web/web.go:1366
   apiSessionDispatch() lehnt alles ausser GET ab (if r.Method != http.MethodGet -> 405).
   Also die Methodenbehandlung um DELETE erweitern.
2. Statt DELETE die Session-ID an 'opencode session delete' weiterreichen und dessen
   Exitcode/Fehler durchreichen. Session nicht gefunden muss ein sauberer 404 werden,
   kein 500.
3. Web-Oberfläche: Löschen-Knopf in der Session-Ansicht, mit Rückfrage, weil es nicht
   rückgängig zu machen ist.

ZWEI SICHERHEITSPUNKTE, die das Ticket von einem Einzeiler unterscheiden:
a) KEINE LAUFENDE SESSION LÖSCHEN. Gehört die Session gerade zu einem lebenden Schiff,
   würde man dessen laufende Unterhaltung zerstören. 'running' ist allerdings genau das
   Feld, dem wir aktuell nicht trauen (starfleet/task-running-flag-pid-liveness behebt
   genau das). Deshalb vor dem Löschen die PID-Lebendigkeit GEGENPRÜFEN, nicht gegen
   running verlassen. Die Abhängigkeit zu diesem Ticket ist gewollt und muss im
   Commit-Text stehen.
b) LÖSCHEN IST NICHT RÜCKGÄNGIG. Der Maintainer räumt Session-Historie gelegentlich
   manuell auf — dieser Weg soll das nicht ersetzen, sondern ermöglichen. Im UI deutlich
   als unumkehrbar kennzeichnen und eine Rückfrage vorschalten.

VERIFIKATION, an der Abnahme gemessen werden sollte:
- eine alte, tote Session lässt sich über die Web-Oberfläche löschen und verschwindet
  aus /api/sessions
- eine Session eines LAUFENDEN Schiffs wird abgelehnt, mit klarer Meldung
- die opencode-DB bleibt intakt: 'opencode session list' funktioniert danach, und es
  gibt keine -wal/-shm-Reste im Fehlerfall
- eine nicht existierende ID ergibt 404, kein 500

AGENTS.md: ein Thema pro Commit, make all muss grün sein, Signed-off-by nötig.

- 2026-10-01T13:14:39Z Laforge: progress 10% (Starting investigation: need to add DELETE method to /api/sessions/<id> endpoint, call 'opencode session delete', and add UI delete button)
