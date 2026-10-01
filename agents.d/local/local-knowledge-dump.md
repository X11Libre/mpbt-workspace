---
slug: local/local-knowledge-dump
title: "Local knowledge dump — session discoveries"
order: 10
---

## Local knowledge dump

This directory (`agents.d/local/`) is a **local dumping ground** for
insights, discoveries, quirks, and conventions learned during agent
sessions — anything that doesn't yet belong in the structured
`project/`, `starfleet/`, or eventual `xlibre/` taxonomies.

### Rules

1. **Dump first, sort later.** If you discover something during a
   session that is worth remembering, create or append to a file here
   immediately. Don't worry about where it should ultimately live.

2. **No cross-ship guarantees.** Other ships in the fleet may write
   here too, but there is no ordering, deduplication, or review
   process. Treat this as scratch space.

3. **Promotion path.** When a local insight proves itself stable
   (survived multiple sessions, referenced from other fragments), it
   should be moved to the appropriate taxonomy directory:
   - `agents.d/starfleet-instructions/` — fleet coordination, comms, workflow
   - `agents.d/xlibre/`   — mpbt-workspace, build system, project rules
   - `agents.d/xlibre/`    — X server, drivers, protocol (future)

4. **On `mtx/agent-config`, auto-commit applies** — changes here are
   committed and pushed automatically per the auto-commit policy.

## Automatic feedback loop

After each (non-trivial) task, check your session for lessons learned and
add new entries here in the agents.d/local/ directory.

If you needed extra code (scripts, etc) for driving existing starfleet commands
(eg. github functions), analyze whether starfleetctl could use new commands
or options, so we need less extra scripting around it in the future, and create
dashboard tasks in the starfleet section.

## Standing lessons (aktive, wiederverwendbare)

### Git & Workflow
- **Bash backticks in `git commit -m` get command-substituted.** Always use `git commit -F - <<'EOF'` (quoted heredoc) for commit messages containing backticks/`$`.
- **`origin/master` can advance WHILE you work even mid-session.** Always re-fetch and rebase onto the CURRENT origin/master right before integrating; don't trust a ref read earlier in the session. Rebase conflicts then often involve another ship's adjacent feature — resolve by keeping BOTH lines.
- **add/add test-file conflicts:** resolve as a UNION — take my file, append the other side's content minus its header/import block; keep the import block ONCE. Run `gofmt -l` afterwards (unions leave duplicate blank lines).
- **`cp` FROM `/tmp/opencode/...` is BLOCKED** even though `/tmp/opencode/*` is allow-listed: the later `external_directory "**": deny` rule wins (last match wins). Write outputs into a workspace-relative path instead.

### Vor jeder neuen Phase: Skills gegen die eigenen Erkenntnisse prüfen

Am Ende eines langen Arbeitsstrangs (hier nach dem xorg/main-Backport) die
gesammelten Erkenntnisse gegen die Skills halten, **bevor** die nächste Phase
beginnt. Nicht nur lesen — messen, welche Erkenntnis in keiner Datei steht.
Am 2026-09-28 waren vier von acht geprüften Stichpunkten **nirgends**
dokumentiert (Patch-ID-Automatik, `[PR #NNNN]`-Marker beim Übernehmen,
`cherry-pick` legt immer auf HEAD, `checkout --detach` auf einen Punkt außerhalb
des Ziels zerlegt die Kette).

Zusätzlich: **Querverweise zwischen Skills prüfen.** `backport-ours` verwies
auf einen Abschnitt, den es im referenzierten Router gar nicht gab. Ein toter
Verweis entsteht beim Editieren einer Datei, ohne die andere zu prüfen, und
fällt nur auf, wenn man bewusst in beide Richtungen sucht.

Und: **Tippfehler vor dem Commit suchen, nicht danach.** In einem Commit-Text
landete zweimal ein fremdes Zeichen, im Skill-Text einmal ein verunglücktes
Wort („geregasten"). Beides per `grep` nach dem Schreiben und noch einmal vor
`ws-commit` auffindbar.

### starfleetctl deploy / daemons
- **Deploying a starfleetctl change:** build (`make all`) → commit+push (`master`) → `./starfleet-bootstrap` → `timer worker restart` + `web restart` → HTTP 200 → dashboard topic `done` + comms report.
- **Direct-binary deploy fallback** when `./starfleet-bootstrap` can't run cleanly: build in your OWN clean worktree at the rebased master, `rm -f` + `cp` the binary over `.starfleet-ai/src/starfleetctl/starfleetctl` (rm avoids text-file-busy), then `bootstrap --fix` + `sop reindex` with the NEW binary, then `web restart` + `timer worker restart` (both daemons keep OLD binary until restarted). Flag the dirty SRC tree to its owner.
- **Running ships keep OLD config/plugin in memory** after redeploy — only new/restarted sessions load the new version. Bootstrap + daemon restarts is NOT enough.
- **Plugin-only changes:** bump `PLUGIN_VERSION` so the fleet can verify rollout via dashboard/heartbeat.
- **Model-proxy pure-Go change deploy:** `make all` in the src tree then `model-proxy restart` alone is sufficient (restart re-execs the freshly built binary; no full bootstrap needed). The daemon never re-execs on its own.
- **`web restart` replaces the daemon even when web.pid is missing/stale** (kills `web start` procs via `/proc` cmdline). Verify end-to-end by corrupting web.pid (`echo 99999 > .starfleet-ai/var/web.pid && web restart` → fresh pid + HTTP 200).

### Comms / Dashboard
- **Broadcasts are fan-out per ship** (`msgs/<ship>/unseen/`, Target=<recipient>) — `msgs/all/` is gone. A self-targeted copy of your own broadcast is expected, not an error.
- **`comms migrate-broadcasts`** converts legacy `Target=="all"` records to per-ship copies; run it in the same deploy as a broadcast-model change. A ship that already acked is skipped (verify with `ls msgs/<ship>/unseen/<id>.json`).
- **`dashboard topic update <slug> --status done` is BROKEN** (parked `starfleet/bug-dashboard-topic-update-clobbers-fields`): ignores `--status` AND clobbers fields. Never use it; always `dashboard topic write <slug> <file>` (full file incl. frontmatter) + `dashboard topic commit`.
- **Sanctioned repair of a topic whose frontmatter is gone:** `dashboard topic write <slug> <file>` (full file incl. frontmatter) + `dashboard topic commit <slug> -m "..."` — never hand-edit topic files. Restore values from `git show <original-create-commit>:<path>`.
- **Dashboard commit helpers take a `push bool`, NOT `noPush bool`.** Passing `noPush` straight in silently INVERTS semantics (code does a pull+push). Always pass `!noPush`.

### opencode permission model
- **opencode reads per-model metadata from the `models` map in opencode.json, NOT from `/v1/models`.** Inject enriched metadata into the generated ship config, not the `/models` response.
- **The model-capability field is `tool_call`, NOT `tools`.** A top-level `tools` key means something else (global tool toggles).
- **opencode's permissive defaults are the baseline** — don't override with stricter per-launch-type rules unless there's a concrete bug. Workspace file tools must be `"**": "allow"` for ALL launch types (paths relative to worktree); `external_directory` handles outside paths.
- **`.starfleet-ai/` access** inside the workspace is gated by the workspace `** allow` rules, NOT `external_directory` (that only fires OUTSIDE the project working directory).
- **Go map-literal key collision pitfall:** `map[string]string{workspacePattern: "allow", "**": defaultRule}` with `workspacePattern = "**"` compiles fine (variable key, not a literal) but the second entry silently overwrites the first. Always double-check generated JSON for duplicate keys.
- **`session ship-run --name X -- <extra>` now hard-blocks extra args after `--`.** Use `starfleetctl run --name X --exec -- <args>` for config-generation checks.

### Model-proxy / upstreams
- **Zen free-tier gate needs UA + `x-opencode-session` + `x-opencode-client` + `x-opencode-project`** (as of 2026-09-09 for `big-pickle`). GitHub issue #42074 ("UA is what matters") is outdated — re-verify against the live gateway when upstream changes.
- **opencode sends its real session id to ANY openai-compatible base URL** as `X-Session-Id` + `X-Session-Affinity`. The proxy must MAP that → upstream `x-opencode-session` (Zen shards prefix cache on session id; a random id per request burns tokens). Synthesis only as fallback (health probes).
- **Streaming retries:** retry only on transport errors / 408/429/5xx before any data is sent; never append `[DONE]` mid-stream; if the stream dies without `[DONE]`, emit a structured `error` event (stream_interrupted) + `[DONE]` so clients don't hang.
- **`curl /v1/models` from the proxy regularly TIMES OUT** while it refreshes catalogs from overloaded upstreams — looks like a crash but is just slowness. `/v1/health` (404 fast) + `ss -ltnp` + `model-proxy status` confirm liveness.

### CI (xserver)
→ migriert in Skill `ci-platform` (Sektion "GH Actions cache & workflow-run gotchas"): GH-Actions-Cache branch-scoped/evictable, `gh run rerun --failed` kann Cache-Eviction NICHT reparieren (voller rerun nötig), delete-old-runs wipes history, Master-red+PR-green pattern.
→ Backport-Tooling-Gap (Multi-Commit-PR, TIP-only) migriert in Skill `backport` (Sektion Gotchas).

### Session / Ship lifecycle
- **A ship that crashed/exited BEFORE `session stop` arrives leaves a zombie heartbeat** on the board. `session stop <id>` on an already-dead ship is a no-op teardown that leaves heartbeat + files.
- **Sanctioned dead-ship completion:** `STARFLEET_SHIP_ID=<id> ./.starfleet-ai/bin/starfleetctl comms clear` (drops heartbeat; vanishes from `comms board`), then `rm` the leftover `var/ships/<id>.{log,pipe,stop-requested,opencode.json}`. All under the workspace.
- **Timer worker picks up new system verbs only after** bootstrap redeploys the binary AND `timer worker restart`.

### starfleetctl CLI gotchas
- **`task capture --title "…"` — the flag is `--title`, not a positional.** `reports submit` (plural), not `report submit`.
- **`starfleetctl run` hardcodes launchType "terminal"** — correct by design. For background use `session ship-run --launch-type background`.
- **`task progress <slug> <0-100> <note>`** already does log-append + comms status working coupling.
- **Web-based tasks detail:** full-text view does markdown rendering via `mdHtml()`.

### (Historie — erledigte Bugs, Referenz nur bei Bedarf)
- Frühere Bugs (default-model-fallback, web-PATH, permission-ask-hang, broadcast-ack, loadAllTopics, stale go/bin shadowing) sind BEHOBEN und durch andere Fragmente/working-practices abgedeckt. Details in Git-History/Commit-Messages.

## starfleet web von außen (Handy) unerreichbar — KORRIGIERT 2026-09-28
- **Die alte Fassung dieser Notiz war falsch und ist widerlegt.** Sie vermutete Docker
  iptables-Chains und userland-proxy als Ursache. Für den Fall vom 2026-09-28 gemessen:
  `dockerd` läuft nicht, `docker0` ist DOWN, es gibt **nicht einmal ein `iptables`-Binary**, und
  der Web bindet `0.0.0.0:8080` mit `Recv-Q 0`; `curl` auf `127.0.0.1` **und** auf die eigene
  LAN-IP antwortet in unter einer Millisekunde.
- **Die Falle, in die ich selbst getappt bin:** daraus „kein iptables-Binary, also keine
  Firewall" zu schließen. **Diese Schlussfolgerung ist ungültig.** ConnMan und nftables
  installieren Regeln **über Netlink**, nicht über die Binaries; die Binaries braucht man nur
  zum Ansehen. Auf diesem Host läuft `/usr/sbin/connmand` (PID 2454) und verwaltet das WLAN
  (`connmanctl technologies` → `/net/connman/technology/wifi`); `nmcli` schweigt, weil
  NetworkManager hier gar nicht das Netz verwaltet. Verbindliche Lehre: **ein fehlendes
  `iptables`-/`nft`-Binary ist KEIN Nachweis für eine fehlende Firewall.**
- **Reihenfolge, die sich bewährt hat: erst Host, dann Docker, dann Firewall, erst ganz zuletzt
  WLAN-Infrastruktur.** Jede Stufe einzeln messen, und nie aus dem Fehlen von X auf das Fehlen
  von Y schließen.
- **Was gemessen wurde:** Client-Isolation ist **aus** — der Host erreicht andere WLAN-Clients
  (`192.168.1.196` Port 80 offen, `192.168.1.189` ARP REACHABLE). Das schließt die
  *WLAN*-Isolation aus, sagt aber nichts über die Firewall des Hosts, weil das die andere
  Richtung ist. Drei ARP-`FAILED`: `.171` (~11 600 historische Probes, sehr wahrscheinlich das
  Handy in einer früheren Sitzung), `.248`, `.82`. Aktiver Dienst `o2-WLAN17`, Gateway
  `192.168.1.1`, Host `192.168.1.132/24`. Gespeicherte Netze `o2-WLAN17`,
  `FRITZ!Box 7530 OC`, `HOME IH`, `FRITZ!Box 5530 II`, `buero` — alle mit derselben
  BSSID-Präfix `wifi_d43b04a08868_`, also dieselbe Hardware.
- **Offen, und in dieser Reihenfolge zu klären:**
  1. **Auf welchem SSID ist das Handy?** Der Rechner hängt an `o2-WLAN17`. Ist das Handy auf
     `buero`, `HOME IH` oder im Mobilfunk, sind beide in verschiedenen Segmenten und
     `192.168.1.132` ist vom Handy aus prinzipiell unerreichbar — unabhängig von Lease und
     Firewall. Billigste Frage, ersetzt die beiden anderen.
  2. **Was hat ConnMan installiert?** `allow_host_access` steht nicht im aktiven Profil
     (20 Schlüssel), läuft also auf Default; der Default erlaubt Zugriff, was gegen die
     Firewall-These spricht, aber ConnMan baut Zonen bei Interface-Rebuild neu. Nur der Blick
     entscheidet: `sudo nft list ruleset`, `sudo cat /proc/net/ip_tables_names`,
     `sudo connmanctl technologies` — rein lesend, braucht das sudo-Passwort des Praetors.
- **Detail bleibt gültig:** Docker-Bridges/Routen (172.17/16, 172.18/16, 172.66/16) bleiben auch
  nach Daemon-Stopp im Kernel (linkdown).
- **Fundort-Hinweis:** diese Datei liegt unter `agents.d/` im Workspace und ist versioniert; die
  gleichnamige Kopie unter `.starfleet-ai/var/agents.d/` ist **ephemeral** (`.starfleet-ai/.gitignore`
  enthält `/var/`) und überlebt kein `starfleet-bootstrap`. Wissen, das dauerhaft sein soll,
  gehört hierher, nicht dorthin.

### Comms / Dashboard
- **`comms tell <ship> -F - <<EOF` ist KEINE Syntax** — es gibt kein `-F`-Flag; `-F`/`-` werden als literaltext versendet, stdin heredoc wird ignoriert (`comms msgs --json` zeigt dann `text: "-F -"`). Mehrzeilige Bodies IMMER mit `comms tell <ship> --stdin <<'EOF' ... EOF` (oder `--attach <f>`). Gleiches für `broadcast --stdin`.

## Agents arbeiten praktisch NIE in main-Worktrees (Praetor 2026-10-01)

Nach einem Incident am 2026-10-01, bei dem im geteilten Clone
`_WORK_/xserver-master/sources/xlibre/xserver` 33 Dateien staged und der Working Tree
auf `origin/master` lag, während HEAD der Inkubator `rfc/backport-master` war.

**Die Regel:** Agents arbeiten ausschließlich in einem eigenen Clone/Worktree/PR-Clone.
Im mpbt-managed Hauptclone wird **nichts** geschrieben — kein `add`, kein `commit`, kein
`checkout`, kein Rebase. Nur lesen und bauen.

**Warum das schlimmer ist als ein Branch-Fehler:** der Zustand ist nicht durch
sichtbaren Müll erkennbar. HEAD sah korrekt aus, der Branch auch, `git status` zeigte
"nur" staged Änderungen. Wer blind committet, committet `master`-Content auf den
Inkubator-Branch und hebt 38 Backports auf — und der Fehler sieht bis dahin harmlos aus.

**Die bestehende Regel deckt das nicht ab.** `starfleet-sessions` sagt nur: *"branch
switching / rebase / amend / force-push prep happen only in your own worktree"*. `git add`
und `git commit` sind nicht genannt. Das ist die Lücke, die das Incident ausgenutzt hat.
Regel-Erweiterung an Laforge zuruekgemeldet (starfleetctl-Repo, generiertes Fragment).

**Prüf-Satz vor jeder Git-Schreiboperation in einem Clone:**
`git rev-parse --show-toplevel` — steht dort nicht ein Pfad unter
`_WORK_/worktrees/`, `_WORK_/<solution>/agent/`, oder `github pr checkout`, dann **Halt**.

**Und wenn man es trotzdem getan hat:** nicht committen, nicht resetten. Erst den
Besitzer fragen, ob der Zustand zuordenbar ist, und den Inkubator-Branch gegen `origin`
prüfen, bevor irgendetwas überschrieben wird.

## `tmp-pr` als Branchname blockiert `make-pr` — Git-Ref-Kollision

`xx-make-pr` legt erst `tmp-` + branchName an, also `tmp-pr/master-<slug>_<zeitstempel>`
(`internal/ghpr/xxmakepr.go:98,109`). Existiert ein Branch **exakt** namens `tmp-pr`, ist
`refs/heads/tmp-pr` belegt und Git kann **keinen** Ref darunter anlegen:

```console
$ git branch tmp-pr
$ git checkout -b tmp-pr/master-foo_x
fatal: cannot lock ref 'refs/heads/tmp-pr/master-foo_x': 'refs/heads/tmp-pr' exists
```

Nachgemessen, nicht vermutet. Die Fehlermeldung nennt den Auslöser nicht, sie sieht nach
einem Git-Problem aus — ist aber ein Namensraumproblem.

Der Präfix `tmp-` gehört der make-pr-Mechanik. Eigene Staging-Branches brauchen einen
anderen Präfix (`wip/`). Ein auftauchendes `tmp-pr` sofort löschen, lokal und auf origin.

**`tmp-pr-1` blockiert nicht**, ist aber fast immer die Spur eines abgebrochenen Laufs:
`xx-make-pr` räumt auf **keinem** seiner sechs Fehlerpfade auf (kein `defer`, kein
`branch -D`). Vor einem make-pr-Lauf also `git branch --list 'tmp-*'` prüfen.
Am 2026-10-01 lag `tmp-pr-1` in mehreren Clones und im Worktree `xorg-main-master`
ausgecheckt — was zwischen zwei Schiffen kollidierte.

**Merksatz für Fehlermeldungen:** "cannot lock ref" plus `exists` ist fast immer ein
D/F-Konflikt in den Refs, kein Platten- oder Rechteproblem. Erst die Ref-Namespace
prüfen, dann `fsck`, dann Permissions.
