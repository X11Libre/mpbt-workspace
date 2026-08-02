Title: "starfleet: Future — Plugin-Enforcement im opencode-Plugin (starfleet-dispatch.ts): Tool-Gate + ehrliche Status-Korrektur"
Category: active
Kind: task
Status: open
Created-By: Defiant
Created: 2026-07-31T09:11:28Z
Assigned-To: —
Doc-Ref: "—"
Slug: plugin-task-enforcement-future

Zurueckgestellter Teil des Capture-first/Status-Board-Pakets (siehe starfleet/task-capture-first-status-board), bewusst erst spaeter umsetzen — das TypeScript-Plugin soll aus Fragilitaetsgruenden so klein wie moeglich bleiben und wird erstmal per Commands/Skills/Web adressiert.\n\nUmfang (wenn abgearbeitet):\n- tool.execute.before in starfleet-dispatch.ts: bei Write/Edit eine Task-Ack-Zustandspruefung pro Session; ohne Task-Ack laut warnen (TUI-Toast + synthetische System-Nachricht via promptAsync mit exaktem Folge-Befehl), NICHT blocken (Praetor-Entscheid: nur laut warnen).\n- Trivial-Hatch akzeptiert: comms status working --note '<was>' gilt als bewusste Trivial-Erklaerung.\n- Whitelist: starfleetctl-Calls, Read/Glob/Grep, Task-Status-Aufrufe nie blocken/warnen.\n- Bash-Gating: bewusst NICHT (nur Write/Edit).\n- Status-Korrektur: Plugin setzt working nicht mehr blind bei jedem Turn, sondern abgeleitet aus Task-Ack/Hatch.\n- Build-Test im Makefile fuer das Plugin-TS (siehe starfleet/makefile-plugin-ts-buildtest) mitnehmen.\n\nKoordination: nur 1 Schiff gleichzeitig am starfleet-source.
