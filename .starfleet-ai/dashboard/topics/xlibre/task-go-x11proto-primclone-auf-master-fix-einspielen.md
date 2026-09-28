Title: "go-x11proto Primärclone aufräumen und termctl-Fix aktivieren"
Category: xlibre
Kind: "task"
Status: "in-progress"
Assigned-To: "Voyager"
Created-By: "Voyager"
Created: "2026-09-28T09:10:27Z"
Doc-Ref: "—"

Blockiert den termctl-NONBLOCK-Fix im deployed starfleet-Binary, damit der Screen-Poll-Thread-Leak endet. Der Primärclone _WORK_/go-x11proto/sources/xlibre/go-x11proto steht auf wip/xembed-tab-manager (1c4d950, unpushed, Enrico Weigelt) mit uncommitted M demo/tabbed/smoke.sh (+byteswappedclients, entspricht der Xephyr-Byte-Order-Regel) und einem fremden _WORK_/ (8,9M smoke-bin Artefakte, nicht in .gitignore, verstößt gegen die Temp-File-Regel). Beide Fixes d8fd27a + e2c8cbf sind auf origin/master (e2c8cbf), lokaler master ist 7f2a256 und 2 Commits hinter. Nötig: uncommitted Arbeit sichern, _WORK_ aus dem Quellbaum räumen, master per Fast-Forward auf origin/master, dann starfleetctl neu bauen und deployen (letzteres bei Enterprise). Koordination mit Enterprise, Laforge und Interpid, die denselben Source-Claim haben.

- 2026-09-28T09:12:40Z Voyager: began work

- 2026-09-28T09:14:22Z Voyager: a) smoke.sh committet (1b30aa0) mit +byteswappedclients-Begruendung, b) .gitignore um /_WORK_/ ergaenzt (db9dbf7) mit Verweis auf demo/tabbed/smoke.sh BUILD_DIR Zeile 16 und cat-Zeilen 54, _WORK_ 8,9M geloescht, c) Fast-Forward 7f2a256 -> e2c8cbf, beide O_NONBLOCK-Stellen im Arbeitsbaum (remote.go:87, control.go:214), Arbeitsverzeichnis sauber, kein _WORK_ im Quellbaum. XEmbed-Zweig vorher nach origin gepusht (1c4d950+1b30aa0+db9dbf7), sonst waere Enricos Arbeit beim Branch-Wechsel verloren gegangen. Verifikation: go test ./tk/term/termctl/ gruen (0.710s). NEGATIVKONTROLLE: Fix-Test-Datei auf alten Code 7f2a256 gelegt -> FAIL nach 2.001s mit 'write blocked for 2.001100305s, want < 500ms: the non-blocking open is not in effect'. Mit Fix PASS in 0.00s. Der Fix ist damit gegengeprueft, nicht nur behauptet.
