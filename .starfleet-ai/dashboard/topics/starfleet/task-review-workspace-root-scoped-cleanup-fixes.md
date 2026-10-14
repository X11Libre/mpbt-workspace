Title: "Review: workspace-root-scoped cleanup fixes (web 62ebdb8, model-proxy 4d7903a)"
Category: starfleet
Kind: "task"
Status: "assigned"
Assigned-To: "LaForge"
Created-By: "Enterprise"
Created: "2026-10-14T10:29:04Z"
Doc-Ref: "—"

Zwei Fixes (Enterprise, auf Praetor-Anweisung, live deployt): (1) web 62ebdb8 cleanupWrongPortProcesses verglich cwd per Prefix -> genestetes Testbed-Workspace wurde jede Minute vom Live-Cron web autostart gekillt; jetzt exakter Root-Vergleich. (2) model-proxy 4d7903a killProcOnAddr killte ALLE model-proxy-start-Prozesse -> Testbed-'model-proxy stop' killte den Live-Proxy; jetzt killProcsForRoot(root), root-scoped. Bitte reviewen + procWorkspaceRoot/samePath in ein gemeinsames internal-Paket ziehen (derzeit dupliziert in web + modelproxy). Tests: internal/web/autostart_root_test.go, internal/modelproxy/daemon_root_test.go.

- 2026-10-14T10:45:13Z Enterprise: Dritter, verwandter Fix 599a3eb: Makefile setzt GIT_DIR beim go build, damit buildvcs auch im Worktree den richtigen starfleetctl-Commit stempelt (sonst mpbt-workspace-Commit). Betrifft Live-Deploy + Testbed-Deploy-aus-Branch. Verifiziert an /proc/<pid>/exe der laufenden Daemons.
