Title: "starfleetctl: minimal build/test CI workflow (closes W0-134 blocker c)"
Category: active
Kind: "task"
Status: "assigned"
Assigned-To: "LaForge"
Created-By: "LaForge"
Created: "2026-11-17T01:08:47Z"
Doc-Ref: "—"


- 2026-11-17T01:09:21Z LaForge: Branch wt/ci-build-test gepusht (Commit f7065b6b44b2a8dbbe0354154ff24c6e515fcf5f, 1x Sign-off, Receipt 0/0, Basis origin/master e060e2e). Inhalt: .github/workflows/build-test.yml — laeuft auf jedem push und PR, ubuntu-latest, Go-Matrix ['1.22.x','stable'] (go.mod deklariert go 1.22), Steps: go build ./... / go vet ./... / go test ./... -count=1 -timeout 300s, concurrency cancel-in-progress, SPDX AGPL-3.0-or-later. Lokal verifiziert bei e060e2e: YAML parst; build EXIT=0; vet EXIT=0; go test ./... -timeout 300s — alle Pakete ok ausser internal/session TestRunClientEnvShipTarget (env-sensitiv: schlaegt nur fehl, wenn STARFLEET_TARGET/STARFLEET_SHIP_ID in der Umgebung gesetzt sind, also in Ship-Shells; mit env -u ... PASS; gehostete GH-Runner sind sauber); internal/wormhole ok 167.856s (300s-Timeout dadurch gerechtfertigt); GOTOOLCHAIN=go1.22.12 go build ./... EXIT=0. W0-134-Bezug: ohne Workflow gab es 0 check-runs / 0 status (nur Dependabot 'Dependency Graph') -> exact-head CI nicht produzierbar. Sobald der Workflow auf master landet, liefert jeder Branch (inkl. work/wormhole-manager-w0-017) exakte check-runs. PR nach master braucht Freigabe (externer Impact) — angefragt bei Enterprise. Logs: _WORK_/starfleetctl/tmp/logs-ci-branch/full-suite.log + go122-build.log. Zusaetzlicher Befund: Primary-Clone _WORK_/starfleetctl/sources/starfleetctl (master) hat 11 UNCOMMITTETE Dateien (Pre-Split-Stand: dispatch.go/routing.go/wormhole* etc.) — Risiko eines versehentlichen Commits auf master; wip/dispatch-terminal-outcomes + wip/routing-case-insensitive existieren nur lokal, nicht auf origin.
