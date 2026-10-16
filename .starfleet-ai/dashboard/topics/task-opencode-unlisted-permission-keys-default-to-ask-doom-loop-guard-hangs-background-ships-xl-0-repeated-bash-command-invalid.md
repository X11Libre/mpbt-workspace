Title: "opencode: unlisted permission keys default to 'ask' → doom_loop guard hangs background ships (XL-0: repeated 'bash.command' invalid)"
Category: active
Kind: task
Status: "assigned"
Created-By: "Enterprise"
Created: "2026-10-16T10:33:16Z"
Assigned-To: "LaForge"
Doc-Ref: "—"
Slug: task-opencode-unlisted-permission-keys-default-to-ask-doom-loop-guard-hangs-background-ships-xl-0-repeated-bash-command-invalid

Beobachtet 2026-10-16: XL-0 (background ship, run=aed54503, pid 21363) hing >30 min an opencodes doom_loop-Permission-Prompt. Kette: Modell emittierte 3x Toolname 'bash.command' (mit Punkt, existiert nicht) → opencode speicherte 'invalid'-Tool-Results ('Model tried to call unavailable tool bash.command') → nach wiederholten Fehlern feuert opencodes doom_loop-Guard (opencode.log 2026-10-16T10:00:24.067Z run=aed54503: permission=doom_loop pattern=invalid action.action=ask) → Prompt 'Continue after repeated failures' → Background-Schiff, kein Mensch → dauerhaft blockiert. Nebenbefund: termctl-run startete mit --session ses_ebf5240ed (stellar-planet, 15.10.), opencode legte trotzdem NEU die Session ses_ebbd8ddb4 (gentle-garden) an. Root cause: generierte Ship-Config setzt permission.question=deny, aber NICHT permission.doom_loop (und nicht todowrite). opencode PermissionConfig kennt read/edit/glob/grep/list/bash/task/external_directory/todowrite/question/webfetch/websearch/lsp/doom_loop/skill; nicht gelistete Keys fallen auf opencode-Default 'ask' → jeder Prompt kann ein headless Schiff aufhängen. Vorschlag (LaForge-Domain): im Ship-Config-Generator fuer background/auto alle nicht-workspace Prompt-Permissions fail-fast setzen (doom_loop=deny; uebrige 'ask'-Default-Keys pruefen), bzw. Default explizit dokumentieren; zusaetzlich pruefen ob todowrite explizit gesetzt werden soll. Evidenz: opencode.db session ses_ebbd8ddb4ffeIrhSuFOf0vIL2a (3 invalid parts, input.tool='bash.command'); opencode.log 10:00:24 run=aed54503.
