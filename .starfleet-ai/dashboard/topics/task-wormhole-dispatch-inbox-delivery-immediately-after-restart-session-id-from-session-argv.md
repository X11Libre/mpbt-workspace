Title: "wormhole/dispatch: inbox delivery immediately after restart (session id from --session argv)"
Category: active
Kind: "task"
Status: "done"
Assigned-To: "—"
Created-By: "Voyager"
Created: "2026-11-13T18:37:27Z"
Doc-Ref: "—"

- 2026-11-13T18:37:39Z Voyager: Root cause (measured): nach Restart kennt das Plugin die Session-ID nicht bis zum ersten Chat-Hook -> inbox-poll sid=- / handoff-skip reason=no-unique-ship-session (78x fuer m21156/m21056). Launcher startet Schiffe bereits mit --session <id> (launch.go), also ist die ID ab Prozessstart autoritativ. Fix c96cb50: currentSessionID = sessionIdFromArgv(process.argv); Hooks ueberschreiben weiterhin (z.B. nach /clear). Plugin 2.5.12 deployed (bootstrap-dev, 53/53 Tests, esbuild+tsc ok). Verifikation der Laufzeitwirkung: nach naechstem Ship-Restart session-init source=argv in events.log. Hinweis: m21115 (wormhole) und m21131 (comms) nahmen denselben Pfad - keine Typ-Asymmetrie.

- 2026-11-13T18:37:41Z Voyager: completed

- 2026-11-13T18:57:01Z Voyager: Korrektur (Praetor-Hinweis): Session-IDs sind dynamisch -> KEINE Persistenz/Hardcoding. Datei-/argv-Seed (50aab07) revertiert. Eigentliche Ursache: das Plugin hat bei handoff-fail/exception currentSessionID geleert -> danach 78x handoff-skip reason=no-unique-ship-session bis zum naechsten Turn. Fix f0f2df6 (Plugin 2.5.14): ID bei Fehlschlag behalten, Retry damit; Rotation wird vom naechsten Hook uebernommen. Deployed f0f2df6.
