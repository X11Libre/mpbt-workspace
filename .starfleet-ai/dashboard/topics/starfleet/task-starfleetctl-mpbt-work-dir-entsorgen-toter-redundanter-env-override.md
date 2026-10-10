Title: "starfleetctl: MPBT_WORK_DIR entsorgen (toter/redundanter Env-Override)"
Category: starfleet
Kind: task
Status: "assigned"
Created-By: "Enterprise"
Created: "2026-10-10T11:34:04Z"
Assigned-To: "LaForge"
Doc-Ref: "—"
Slug: starfleet/task-starfleetctl-mpbt-work-dir-entsorgen-toter-redundanter-env-override

Auftrag Praetor (2026-10-10). MPBT_WORK_DIR aus starfleetctl entfernen.

MESSUNG (master 40f5403, nur Lesen):
- Einziger Leser: config.WorkDir() (internal/config/config.go:298) -> 'if d := os.Getenv("MPBT_WORK_DIR"); d != "" { return d }'; Default = <root>/.starfleet-ai/var.
- Gesetzt wird es NIRGENDS (0 Treffer in scripts/, conf/, run-*, Cron, .opencode/).
- Redundant: MPBT_WORKSPACE_ROOT relokiert bereits das ganze .starfleet-ai/ (inkl. var/); fuer den Bus-Pfad gibt es zusaetzlich STARFLEET_BUS_DIR.

UMSETZUNG:
- Env-Override in WorkDir() entfernen; WorkDir(root) liefert fest filepath.Join(root, ".starfleet-ai", "var").
- Keine Aufrufer anpassen noetig (nur Default-Pfad). grep -rn MPBT_WORK_DIR muss danach 0 Treffer (auch Tests/Kommentare).
- make all gruen.

NICHT mit anfassen: MPBT_WORKSPACE_ROOT bleibt (load-bearing: Parent->Child-Spawn termctl-run + Cron cwd). Optionale Refactors NUR als separate Task, falls gewuenscht: (a) Cron-Wrapper cdn statt export, (b) cmd.Dir=root beim Ship-Spawn.
Ergaenzung Praetor: MPBT_WORKSPACE_ROOT NICHT entfernen (Testbed-Hebel).
