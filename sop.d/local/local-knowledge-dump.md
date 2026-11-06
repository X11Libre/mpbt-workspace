---
slug: local/local-knowledge-dump
title: "Local knowledge dump — session discoveries"
order: 10
---

## Local knowledge dump

This directory (`sop.d/local/`) is a **local dumping ground** for
insights, discoveries, quirks, and conventions learned during agent
sessions — anything that doesn't yet belong in the structured
`project/`, `starfleet/`, or eventual `xlibre/` taxonomies.

### Rules

1. **Dump first, sort later.** If you discover something worth
   remembering, create or append to a file here immediately.
2. **No cross-ship guarantees.** Treat as scratch space — no ordering,
   deduplication, or review process.
3. **Promotion path.** Stable insights move to `sop.d/xlibre/` (mpbt
   workspace, build, project rules; X server/drivers/protocol) or
   starfleetctl source fragments (`_WORK_/starfleetctl/sources/
   starfleetctl/fragments/starfleet-instructions/`, owner LaForge).
   `sop.d/starfleet-instructions/` is tool-owned — never put user
   fragments there.
4. **Auto-commit on `mtx/agent-config`.** Changes here are committed
   and pushed automatically.

## Automatic feedback loop

After each non-trivial task, add lessons learned here.

## Standing lessons (aktive, wiederverwendbare)

### Git & Workflow

- **Bash backticks in `git commit -m` are command-substituted.** Use
  `git commit -F - <<'EOF'` (quoted heredoc) for messages with
  backticks/`$`.
- **`origin/master` advances mid-session.** Re-fetch and rebase onto
  CURRENT origin/master before integrating. Rebase conflicts may
  involve another ship's adjacent feature — keep BOTH lines.
- **add/add test-file conflicts:** resolve as UNION — take my file,
  append other side's content minus header/import block; keep import
  block ONCE. Run `gofmt -l` afterwards.
- **`cp` FROM `/tmp/opencode/...` is BLOCKED** even though allow-listed:
  `external_directory "**": deny` wins (last match wins). Write outputs
  to workspace-relative path.
- **`sed -i 's/x/y/' f > f` empties the file.** `-i` writes directly,
  `> f` truncates first — same target, redirect wins. Use `sed … f > g`
  or `sed -i … f`, never both on same file.
- **`ninja` is wrong for exception-list checks; `ninja -k 0` is right.**
  `ninja` stops at first error; `-k 0` builds all targets, yields
  complete error set.

### Stale Refs: `origin/master` ist pro Clone ein anderer Snapshot

`origin/master` differs per clone. **Always** `git fetch origin
master:refs/remotes/origin/master` before any ref measurement. Commit
date is NOT a visibility check — an older-dated commit can be an
ancestor of a newer-dated one (master rebased, author date ≠ history
position). Filter over repo identity (`git config --get
remote.origin.url`), not directory names. `mergeCommit` at xserver has
exactly ONE parent (`allow_merge_commit=false`) — parent count proves
nothing.

**Backport sequence:**

```bash
git fetch origin master:refs/remotes/origin/master
gh pr view <pr> --json mergeCommit -q '.mergeCommit.oid'
git merge-base --is-ancestor <quelle> origin/master || exit 1
git cherry-pick -x <quelle>      # OHNE -s
git log --format=%B -1 | grep -ci '^signed-off-by'   # muss 1 sein
git rev-list --count origin/release/<ziel>..HEAD     # muss 0 sein
```

### Eine Zahl in einer Regel traegt nie das Argument

`parents == 1` is a constant (proves nothing). "N verschiedene
`origin/master`-Staende" is a snapshot (ages fast). The number is not
the argument — the behavior is. A stale Ref marks the RIGHT as wrong.

### Regelkollision: `ws-commit -a` im geteilten Baum nimmt fremde Arbeit mit

Auto-commit on `mtx/agent-config` means ALL workspace changes. In the
shared workspace tree, `ws-commit -a` = `git add -u` + commit — i.e.
ALL other ships' changes, not just yours. **Im shared tree, always
commit with explicit paths, never `-a`.** `git add` first, then
`ws-commit -m "…" <paths>`. Check `git diff --cached --name-only`
before commit.

### Plausibel-statt-offensichtlich-falsch: die teuerste Fehlerklasse

**Ein Fehler, der plausibel klingt, ist nicht automatisch richtig.** Eine
Vermutung und eine Messung, die gleich aussehen, werden gleich behandelt
bis eine nachgemessen wird. **Form dem Beweisgrad anpassen:** Ein
unbelegter Satz neben gemessenen erbt deren Glaubwuerdigkeit.

**Checker:** Kann ich die Aussage pruefen, indem ich etwas ausfuehre,
oder nur, indem ich sie lese?

### Zwei Fehlerklassen, die man nicht zusammenfassen darf

"Falsche SHA" (Branch-Tip statt Merge-Commit → `bad object`) und
"Falscher Sign-off" (SHA richtig, Option `-s` gesetzt → zwei Sign-offs)
sind zwei Fehler, kein Sammelbild. Pruefung die beide faengt:

- Commit-Message muss genau 1 `Signed-off-by` Trailer haben (nicht im PR-Body lesen!)
- `.mergeCommit` statt `.commits[0]` als Quelle

### Generierter Text, der wie gemessen aussieht

Erzeugtes Feld gegen den GEMASSENEN Wert pruefen, nicht gegen die
Voraeltung. Ahnlich benannte Felder (`local origin/master` vs `PR base`)
sind eine Ersetzungsfalle.

### Groessen, die man fuer eine Entscheidung braucht, ohne Verantwortung dafuer zu tragen

`parents == 1` ist primaer unbrauchbar (Konstante). `origin/master` ist
nur unbrauchbar, wenn man sie nicht selbst holt. **Schritt 1 macht
Schritt 6 erst sinnvoll.** Fremd-Commit-Pruefung ohne eigenen Fetch
misst gegen einen Zustand, den jemand anderes verantwortet — das ist eine
Voraussetzung, keine Schrittfolge.

### Beschriftung muss bezeichnen, was gemessen wurde

Ein Verifikationsblock dient zum Nachrechnen, nicht zum Vertrauen.
Beschriftung ist Teil des Beweises. Wert UND den Befehl, mit dem er
gemessen wurde, angeben. Falscher Wert unter richtiger Beschriftung
stoppt beim Nachrechnen; richtiger Wert unter falscher Beschriftung wird
 bestaetigt — das ist die gefaehrlichere Richtung.

### Form ist der Traeger der Glaubwuerdigkeit

Behauptung ueber Laufzeit-/Compilerverhalten wird ausgefuehrt bevor
weitergegeben. Behauptung ueber gelesenen Code darf zuerst
weitergegeben werden, wenn als "zu pruefen" markiert. Ein unbelegter
Satz neben gemessenen erbt deren Glaubwuerdigkeit.

### Board-Integrität: ein 0-Byte-Topic ist kein gültiges Topic

`sed -i … > f` auf derselben Datei leert sie auf 0 Byte. `topic write`
nimmt alles, was kein parsebarer Frontmatter ist, und das Board zeigt es
danach wie ein legitimes Topic.

### Dokumentierte Ausnahmelisten sind pro Branch, nicht global

`os/Xtranssock.c:631 -Werror=format-truncation` ist die einzige erlaubte
Vorbedingung bei `-Dwerror=true`. Auf 25.0 gibt es 4 weitere
Vorbedingungsfehler (glx/unpack.h, os/connection.c, os/xstrans.c) —
diese gehoeren in die PR-Beschreibung und ins Topic, nicht in eine
globale Regel.

### Vor jeder neuen Phase: Skills gegen die eigenen Erkenntnisse prüfen

Messen, welche Erkenntnis in keiner Datei steht. Querverweise zwischen
Skills pruefen. Tippfehler vor dem Commit suchen, nicht danach.

### starfleetctl deploy / daemons

- starfleetctl change: `make all` → commit+push → `./starfleet-bootstrap` → `timer worker restart` + `web restart` → HTTP 200 → dashboard topic `done` + comms report.
- Direct-binary deploy fallback: build in own clean worktree, `rm -f` + `cp` binary over `.starfleet-ai/src/starfleetctl/starfleetctl`, then `bootstrap --fix` + `sop reindex` + `web restart` + `timer worker restart`.
- **NEVER `pkill -f starfleetctl`.** Matches full cmdline → kills run wrapper of EVERY ship + timer worker + web daemon. Orphans opencode → broken terminal fleet-wide. Use `rm -f` old binary, then copy/deploy.
- Running ships keep OLD config/plugin in memory after redeploy — only new/restarted sessions load new version.
- Plugin-only changes: bump `PLUGIN_VERSION` for fleet rollout verification.
- Model-proxy pure-Go change: `make all` then `model-proxy restart` alone suffices.
- `web restart` replaces daemon even with missing/stale web.pid.

### Comms / Dashboard

- Broadcasts are fan-out per ship (`msgs/<ship>/unseen/`, Target=<recipient>). `msgs/all/` is gone. Self-targeted copy of own broadcast is expected.
- `comms migrate-broadcasts` converts legacy `Target=="all"` to per-ship copies. Run in same deploy as broadcast-model change.
- **`dashboard topic update <slug> --status done` is BROKEN** (ignores `--status`, clobbers fields). Never use it; always `dashboard topic write <slug> <file>` (full file incl. frontmatter) + `dashboard topic commit`.
- Dashboard commit helpers take a `push bool`, NOT `noPush bool`. Passing `noPush` silently INVERTS semantics — pass `!noPush`.

### opencode permission model

- opencode reads per-model metadata from `models` map in opencode.json, NOT from `/v1/models`.
- Model-capability field is `tool_call`, NOT `tools`.
- Workspace file tools must be `"**": "allow"` for ALL launch types. `external_directory` handles outside paths.
- `.starfleet-ai/` inside workspace gated by workspace `** allow` rules, NOT `external_directory`.
- Go map-literal key collision: `map[string]string{workspacePattern: "allow", "**": defaultRule}` with `workspacePattern = "**"` compiles but second entry overwrites first. Check generated JSON for duplicate keys.

### Model-proxy / upstreams

- `curl /v1/models` from proxy regularly TIMES OUT while refreshing catalogs from overloaded upstreams — looks like crash, is just slowness. `/v1/health` (404 fast) + `ss -ltnp` + `model-proxy status` confirm liveness.

### CI (xserver)

→ migriert in Skill `ci-platform`. GH-Actions-Cache branch-scoped/evictable, `gh run rerun --failed` cannot repair cache eviction (full rerun needed), delete-old-runs wipes history.

### Session / Ship lifecycle

- A ship that crashed/exited BEFORE `session stop` leaves a zombie heartbeat. `session stop <id>` on already-dead ship is no-op teardown leaving heartbeat + files.
- Sanctioned dead-ship completion: `STARFLEET_SHIP_ID=<id> ./.starfleet-ai/bin/starfleetctl comms clear` then `rm` leftover `var/ships/<id>.{log,pipe,stop-requested,opencode.json}`.
- Timer worker picks up new system verbs only after bootstrap redeploys binary AND `timer worker restart`.

### starfleetctl CLI gotchas

- `task capture --title "…"` — flag is `--title`, not positional. `reports submit` (plural).
- `starfleetctl run` hardcodes launchType "terminal" — correct by design. For background use `session ship-run --launch-type background`.
- `task progress <slug> <0-100> <note>` does log-append + comms status working coupling.

### Allow-listed ≠ erlaubt — /tmp bleibt verboten (Praetor, 2026-10-08)

`/tmp/opencode/*` in opencode permission list is a TOOL allowlist entry, NOT a project permission. Workspace rule (`xlibre/architecture`) stands: never `/tmp` or other temp outside workspace; own ones under `_WORK_/`.

### Comms / Dashboard (Heredoc)

`comms tell <ship> -F - <<EOF` is NOT syntax — no `-F` flag; `-F`/`-` sent as literal text, stdin heredoc ignored. Multi-line bodies ALWAYS with `comms tell <ship> --stdin <<'EOF' ... EOF` (or `--attach <f>`). Same for `broadcast --stdin`.

### Agents arbeiten praktisch NIE in main-Worktrees (Praetor 2026-10-01)

Agents work exclusively in own Clone/Worktree/PR-Clone. In mpbt-managed primary Clone nothing is written — no `add`, `commit`, `checkout`, `rebase`. Guard before every mutating Git command: `git rev-parse --show-toplevel` must match intended Clone/Worktree.

### `tmp-pr` als Branchname blockiert `make-pr` — Git-Ref-Kollision

Branch exakt namens `tmp-pr` blocks `refs/heads/tmp-pr/*`. Delete branches exactly named `tmp-pr` or `tmp-starfleet`, locally and on origin. `wt/*` branches are "managed by worktree", NOT disposable — check `worktree list` AND `gh pr list` before deleting.

### starfleetctl-Source gehört in der Hoheit von Laforge (Praetor 2026-10-01)

All work on starfleetctl source — exclusively LaForge. Other ships may read, build, measure. Write/add/commit/push/bootstrap belongs to LaForge or is delegated to him. LaForge runs on meta-model `nim-primary`, not pinned to a concrete Nemotron ID.

### API-Felder sind kein Beweis — `running`/`state` in `/api/sessions` und `/api/ships` lügen

`running` is set at spawn and never updated. Sessions ended for days are still reported as running. **Ein Flag ist keine Aussage über Liveness.** Sortieren nach einer Größe ist keine Aussage über Alter. Jede Diagnose vor dem Melden gegen `ps`/`/proc` prüfen.

### Empfehlungen vor dem Weitergeben verifizieren (Praetor 2026-10-01)

Every recommendation affecting more than one ship must be tested once on a concrete example before sharing. For commits: `git log -1 --format=%B <commit>`, for builds: build once and read output, for branch patterns: `git rev-list --count <base>..HEAD`.

### Selbst-notifizierende Fehler als Endlosschleife (2026-10-04)

Session error → Control-Nachricht mit `from=<ship> target=<ship>` → landet im eigenen `unseen/` → injiziert im nächsten Turn. Mehr Kontext → wahrscheinlicherer Overflow → neuer Fehler → neue Notice. Ein Fehlerkanal, der sich selbst speist, ist kein Informationskanal.

### `git add -A` nach einem segfaultenden Test-Binary (2026-10-04)

Core-Dumps land in Arbeitsbaum. `git add -A` nimmt sie mit → Push Protection verweigert (z.B. Groq API Key im Core-Dump). Regeln:

```sh
printf 'core.*\n' >> "$(git rev-parse --git-common-dir)/info/exclude"
git status --short | grep -E '^\?\? core\.' && rm -f core.*
git add <nur-eigene-pfade>
```

### Ein grüner Test kann ein brennender Assert sein (2026-10-04)

`./test/tests` gibt exit 0 zurück, auch wenn `signal_logging_test` FAIL meldet. Bei einem Test mit Asserts gilt der Exit-Code erst dann als Aussage, wenn einmal beabsichtigt ein Assert geritten wurde und der Exit-Code dann nicht null war.

### Worktrees EINES Repos teilen den Ref-Store — mutierende git-Befehle serialisieren

Worktrees haben eigenen Index, teilen aber Ref-Store, `packed-refs`, `config`, Objekt-Datenbank. Alles, was refs anfasst, nimmt dort einen Lock. **Der Lock folgt dem Repository, nicht dem Verzeichnis.** Rein lesende Kommandos (`git log`, `git show`, `git status`, `gh api`) sind unproblematisch.

### `.git/info/exclude` verhindert das *Staging*, nicht das *Entstehen* von Core-Dumps

`core.*` in `exclude` verhindert `git add -A` einsacken, nicht `ulimit -c unlimited` Erzeugung. Beides zusammen: `ulimit -c 0` beim absichtlichen Reiten von Asserts, `core.*` in `exclude` als Netz.

### Worktrees: Verzeichnis löschen ist nicht abmelden (2026-10-04)

Ein Verzeichnis zu löschen ist nicht dasselbe wie einen Worktree abzumelden. Beides muss getan werden — und die Abmeldung in JEDEM Clone, in dem der Worktree registriert ist. `starfleetctl worktree remove` unzuverlässig (exit 128, verliert Branch trotz `--keep-branch`). Zuverlässig: `git worktree remove --force` + `git worktree prune` in jedem betroffenen Clone.

### Fuenf Messfehler an einem Nachmittag, alle mit derselben Ursache

Filter liest "nichts gefunden" und "Fehler" als "nichts vorhanden". Faustregel: `ahead` ist eine Zaehlung, kein Inhalt. Inhalt ist `git rev-parse --verify -q "$branch"` + `git cherry <basis> "$branch" | grep -c '^+'`. Basis ist der Release-Zweig, nicht master. `git rev-parse --verify` in dieselbe Bedingung wie die Messung.

### Endpunkt existiert != Client benutzt ihn (2026-10-05)

`curl /api/ships` → 200 beweist Verfuegbarkeit, nie Nutzung. Referenzen im Artefakt zaehlen, das sie verwendet (`grep -oE '/api/[A-Za-z0-9_-]+' shell.html | sort -u`).

### Web-Frontend escAttr-Vorfall (2026-10-08) — KORRIGIERT

HTTP 200 beweist kein lauffaehiges JS. Fixes: escAttr entities zurueckgesetzt (`5f0bdfc`), linkifyURLs arbeitet auf rohem Text (`a781d43`). Prufung: `scripts/web-frontend-check.sh [base-url]` (3 Schichten: HTTP / Source-Parse / Browser-E2E).

### `.starfleet-ai/var/` ist ephemeral — die termctl-FIFOs leben dort

Nach `.starfleet-ai`-Wipe waren Terminals aller Schiffe unerreichbar. FIFO extern neu anzulegen hilft NICHT (anderer Inode; Server haelt seinen Inode). Reparatur nur per Session-Neustart. `var/` wie fluechtiges Laufzeitverzeichnis behandeln — nicht loeschen, nicht "aufraeumen". Restore aus Git deckt nur versionierte Teile (`conf/`, `dashboard/topics/`, SOPs).

### Modell-Liste im Formular leer = `/api/models` 503 = conf/model-proxy.yaml weg — KORRIGIERT

Fehlende Konfiguration, kein Frontend-Fehler. Nach Restore von `conf/` sofort wieder 200 — ohne Deploy, ohne Restart (Handler liest pro Request).

### Skill VOR dem ersten Versuch laden, nicht nach dem Fehlschlag (2026-10-08)

Vor einer roten CI-Lane den `ci-platform`-Skill laden. Kosten des Ladens Sekunden; Kosten des Fehlversuchs ein Run-Turn plus Korrekturmeldung.

### Geschlossener PR ist nicht verloren (2026-10-08)

Close-Grund lesen bevor man nachholt. Cherry-Pick misst zwei Baumhoehen: Patch UND Voraussetzung. `git log --grep` beweist nur dass Patch fehlt, nicht dass er fehlen darf.

### Der Messumfang muss mit der Aussage mitreisen (2026-10-08)

Geltungsbereich einer gemessenen Ursache ist genau die Menge der Objekte, die man gemessen hat. Gemessene Objekte nennen, dann Unterscheidungsregel, dann explizit was NICHT gemessen wurde.

### Modell-Proxy niemals direkt killen oder stoppen (gelernt 2026-10-08)

Stets `./.starfleet-ai/bin/starfleetctl model-proxy restart|stop|start` verwenden. Nie `kill`, `pkill`, `systemctl`.

### NIEMALS `pkill -f starfleetctl` (Incident 2026-10-13)

Ersetzt jedes "kill zum Entsperren". `pkill -f` matcht volle Kommandozeile → trifft Wrapper aller Schiffe. Vor dem Kopieren `rm -f` altes Binary.

### Ein lokaler Test-FAIL ist kein Regressions-Beweis (2026-10-12)

A/B misst zwei Baumhoehen in EINER Umgebung; CI misst die Umgebung mit. Erst die Kombination trennt Code-Regression von Umgebungsartefakt.

### `http.Client.Timeout` deckt die GANZE Transaktion inkl. Body-Read (2026-10-12)

Streams bekommen `http.Client` ohne `Timeout`. Lebensdauer regeln `Transport`-Timeouts + `r.Context()`/Idle-Watchdog auf der Leseseite. Keepalive als `case <-keepaliveC:` in den einen Loop, der `w` besitzt.

### YAML-Änderungen: immer Syntax-Check (2026-10-13)

`python3 -c "import yaml; yaml.safe_load(open('<datei>'))"`. GH-Actions `if:` in `${{ }}` wrappen statt nacktem `!cancelled()`.

### Remote-Checks im xserver-Clone laufen lassen, nicht im Workspace-Root (2026-10-13)

Workspace-Root hat eigenes `.git` mit `origin = github.com:X11Libre/mpbt-workspace.git`. Remote-Refs immer aus dem xserver-Clone abfragen.

### `comms clear --help` löscht den EIGENEN Heartbeat (2026-10-15)

`comms clear` kennt kein `--help`. Sofort-Reparatur: `comms touch`. Fremder toter Schiffs-Heartbeat: `STARFLEET_SHIP_ID=<name> ... comms clear`.

### x-opencode-request: Zen-Grammatik (2026-10-15)

Zen akzeptiert `x-opencode-request` nur wenn Wert `^msg_[0-9a-f]{12}[0-9A-Za-z]{14}$` erfuellt. Realer opencode-Client sendet den Header gar nicht. Falscher Weiterreicht erzeugt 403 selbst.

### Model-Proxy Fallback Fixes (2026-10-15)

5xx Fallback, Streaming Fallback, Response Header Timeout per Provider gefixt (Commits `fe386a5`, `a2510d0`, `18e56f7`, `a408f59`). Deploy: `./starfleet-bootstrap` + `model-proxy restart`.
