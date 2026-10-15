Title: "Model-Proxy haengt komplett + origin/master baut nicht (launch.go) — Stopgap deployt 2026-10-14"
Category: starfleet
Kind: "task"
Status: "done"
Assigned-To: "LaForge"
Created-By: "Enterprise"
Created: "2026-10-14T09:35:38Z"
Doc-Ref: "—"

Zwei zusammenhaengende Defekte, am 2026-10-14 von Enterprise diagnostiziert.

## 1) WIP-Model-Proxy haengt JEDE Anfrage (Root Cause)
handleChat im WIP-Refactor nutzt `turn.StreamChunks != nil` als Streaming-Diskriminator.
`NewTurn` (turn.go:99) initialisiert `StreamChunks: make(chan StreamChunk, 10)`
-> IMMER non-nil -> immer der streamende Pfad -> `for chunk := range turn.StreamChunks`
blockiert ewig. `forwardChat` ist dadurch toter Code.
Folge: jede Anfrage haengt -> fleet-weit ProviderHeaderTimeout (300s).
Synthetische Restart-Welle: Enterprise 3281, Defiant 2810.

## 2) origin/master ec70e9344 BAUT NICHT
Fehler: internal/session/launch.go:553:4: syntax error: non-declaration statement
outside function body. Ursache: Commit ec70e9344 ("feat(session): implement persistent
supervisor daemon") entfernt die komplette LaunchShip-Funktion (-352 Zeilen in launch.go).
Parent 188216a hat sie noch (grep LaunchShip: 188216a=1, ec70e9344=0).
Remote origin = git@github.com:mpbt-hq/starfleetctl.git; lokaler master == origin/master
== ec70e9344 -> master ist auf GitHub wirklich rot.

## Stopgap (von Enterprise deployt, NUR Binary — kein Source-Write)
Build-Quelle: worktree _WORK_/worktrees/starfleetctl/proxy-stopgap (wt/proxy-stopgap)
= ec70e9344 + internal/session/launch.go aus Parent 188216a; make build gruen.
Deployt: .starfleet-ai/bin/starfleetctl 14754715 bytes (2026-10-14 11:22),
model-proxy restart -> pid 1512 auf 127.0.0.1:8443. Chat-Probe liefert gueltige
Completion. Defiant + Voyager laut Praetor wieder gesund.

## Offen (LaForge, Source-Owner)
- launch.go in master reparieren (LaunchShip aus 188216a wiederherstellen bzw. Supervisor
  sauber integrieren, ohne die Funktion zu loeschen). Danach build + deploy.
- Den WIP-Streaming-Diskriminator beheben (siehe 1), sonst haengt der Refactor weiter.

## Verwandt
- starfleet/bug-model-proxy-stream-total-timeout (done) — anderer Bug
  (http.Client.Timeout ueber die ganze Transaktion), Fix 04a8f03 + 7ce4c6f.

- 2026-10-14T09:39:15Z Enterprise: Ad-hoc-Fix committet+gepusht: commit 57d9260 auf Branch wt/proxy-stopgap (origin/mpbt-hq/starfleetctl). Inhalt: launch.go aus Parent 188216a wiederhergestellt (LaunchShip zurueck), damit origin/master wieder baut. Diff: +352 Zeilen in internal/session/launch.go, sonst nichts. PR-Kandidat gegen master offen (LaForge).

- 2026-10-14T09:40:40Z Enterprise: master REPARIERT: Fast-Forward origin/master ec70e93..57d9260 (Branch war ungeschuetzt). Verifiziert: origin/master == 57d9260, func LaunchShip vorhanden (=1). Deploytes Binary .starfleet-ai/bin/starfleetctl (14754715 B) stammt aus genau diesem Baum -> bereits konsistent, kein Rebuild noetig. Offen bleibt nur der WIP-Streaming-Diskriminator (LaForge).

- 2026-10-15T11:27:38Z Enterprise: VERIFIZIERT ERLEDIGT (Enterprise): origin/master baut gruen (go build rc=0). WIP-Hang-Ursache weg: internal/modelproxy/turn.go existiert nicht mehr, 0 Treffer StreamChunks in internal/modelproxy/ (NewTurn-Diskriminator entfernt/zurueckgerollt). Proxy laeuft live auf fa7d57b und liefert 200.
