# Workspace Auto-Assign and Auto-Spawn of Ships

Defines the behavior of the flagship (Enterprise) for automatic task assignment and creation of worker ships in the workspace.

## When to use

Use this skill when you need to understand or enforce the auto-assign and auto-spawn process for tasks flagged with `--assign auto` (or via Web‑GUI "Ship: auto").

## How it works

### Auto‑Assign behavior

When a task is captured with `--assign auto`:

1. The task is delegated to the **flagship (Enterprise)**  
   (`created-by: <Console>`, `assigned-to: Enterprise`).
2. The flagship checks the comms board for **free workers**  
   (`comms board` → status `idle`, not `stale`).
3. If a free worker exists → `task assign <slug> <worker>` + comms tell the worker.
4. If **no** free worker exists → **auto‑spawn** a new worker ship.

### Auto‑Spawn rules

**When to spawn:**
- No free worker on the board (all workers are `working` or `stale`).
- The task has urgency (optional: `--priority` in future).

**How to spawn:**
```bash
starfleetctl session ship-run --name <auto-assigned> --model nvidia/nemotron-3-ultra-550b-a55b
starfleetctl task assign <slug> <new-ship>
```

**Default models for auto‑spawn:**
- `nvidia/nemotron-3-ultra-550b-a55b` (Nemotron Ultra) – standard.
- `nvidia/nemotron-3-nano-30b-a3b` (Nemotron Nano, fast) – for light tasks (if specified in the task).

## Correct procedure & examples

Ships receive tasks **not** via bare arguments after `--`, but through:

1. **Task capture** (`starfleetctl task capture` or Web‑GUI "Neue Aufgabe").
2. **Task assignment** (`task assign <slug> <ship>` or `--assign` at capture)  
   – Auto‑assign (`__auto__`) always routes to the flagship.
3. The ship polls its comms inbox (automatically via plugin) and executes the directive.
4. **Result via comms back** (`comms tell <sender> <reply>`).

### Web‑GUI (new task + ship spawn)

1. Tasks → "Neue Aufgabe" → title/description.
2. Ship: leave blank or `auto` → "Erfassen" (task delegated to flagship).
3. Fleet → "Neues Schiff" → **choose model** (mandatory!) → "Starten".
4. Flagship delegates the task to the new ship via comms.

### CLI

```bash
# Capture task and delegate directly (via flagship)
starfleetctl task capture "Titel" --desc "Beschreibung" --assign auto

# Or: start ship first (with --model!), then assign task
starfleetctl session ship-run --name Voyager --model nvidia/nemotron-3-ultra-550b-a55b
starfleetctl task assign <slug> Voyager
```

**Important: always specify `--model`**

```bash
# Correct
starfleetctl session ship-run --name Voyager --model nvidia/nemotron-3-ultra-550b-a55b

# Wrong (crash!)
starfleetctl session ship-run --name Voyager --model nvidia/nemotron-3-ultra-550b-a55b -- "mach das und das"
```

## Task delegation via comms (worker workflow)

Flagship tells worker:
```bash
starfleetctl comms tell <worker> "Task: <slug> — <Titel>. Details im Dashboard. Bitte bearbeiten und Ergebnis via comms tell Enterprise zurückmelden."
```

Worker:
1. `comms ack <msg-id>`
2. Read task from dashboard (`starfleetctl dashboard topic show <slug>`)
3. Perform work
4. `comms tell Enterprise "Task <slug> erledigt: <Zusammenfassung>"`
5. `task update <slug> --status done` (optional; flagship also does this)
6. **`starfleetctl report submit --title "Task <slug> abgeschlossen" --body "<Zusammenfassung>" --taskref <slug>`** – submit report

## Checklist for flagship (Enterprise)

For an auto‑assign task:
- [ ] Check board: `comms board` → free workers (`idle`, not `stale`)?
- [ ] If yes: `task assign <slug> <worker>` + comms tell worker
- [ ] If no: `session ship-run --model nvidia/nemotron-3-ultra-550b-a55b` → note name → `task assign <slug> <new-ship>` → comms tell new ship
- [ ] Set task status in dashboard to `in-progress`
- [ ] On completion: task → `done`, worker → `idle` (via comms status)
- [ ] **After completion:** `report submit --title "Task <slug> abgeschlossen" --body "<Zusammenfassung>" --taskref <slug>` + comms to McKinley

## Checklist for ship spawns (general)

- [ ] Specify `--model` explicitly (CLI) / choose from dropdown (Web‑GUI)
- [ ] No arguments after `--`
- [ ] Assign task separately via dashboard/comms
- [ ] In Web‑GUI: model field is mandatory (UI should enforce)

## Token‑saving hint

The default model Nemotron Ultra (`nvidia/nemotron-3-ultra-550b-a55b`) is powerful but token‑intensive. For light tasks (contact lookup, simple code changes, status checks) you can specify `--model nvidia/nemotron-3-nano-30b-a3b` (Nemotron Nano) in the task to save quota.

## Reference

This skill is based on lessons learned from `local/ship-spawn-and-auto-assign` and the implementation in `starfleetctl` (commit f84d312: Auto‑Assign always routes to the flagship).

