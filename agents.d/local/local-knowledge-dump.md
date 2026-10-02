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
- **`sed -i 's/x/y/' f > f` leert die Datei auf 0 Byte.** `-i` schreibt direkt, `> f` leert vorher — und weil beides auf dieselbe Datei zielt, gewinnt der Redirect. Benutzt habe ich es beim Erzeugen eines Topic-Dokuments; danach war es 0 Byte und im Board-Transcript nicht mehr von einem gültigen Topic zu unterscheiden. Entweder `sed … f > g` (ohne `-i`) oder `sed -i … f` (ohne Redirect). Merksatz: **`> f` neben `-i` auf derselben Datei ist kein Edit, sondern ein Löschen.**
- **`ninja` ist für die Ausnahmelisten-Prüfung falsch, `ninja -k 0` richtig.** Mit `ninja` bricht der erste Fehler ab; man sieht eine Warnung, schliesst "nur die bekannte Ausnahme" und weiss nicht, dass es weitere gab. `-k 0` baut alle Targets und liefert die **vollständige** Fehlermenge. Genau dieser Unterschied entschied am 2026-10-02 auf 25.0 zwischen "eine Ausnahme" und "vier".

### Stale Refs: `origin/master` ist pro Clone ein anderer Snapshot

Bei einem Backport auf xserver gemessen, dieselbe Frage in vier Clones
**gleichzeitig**, ohne etwas zu aendern: liegt `e84a8065c4` auf `origin/master`?

    origin/master=482f7b326d  ->  NEIN   <- FALSCH
    origin/master=d7e1c7e5c9  ->  NEIN   <- FALSCH
    origin/master=71bf6fcdc6  ->  NEIN   <- FALSCH
    origin/master=4c537f6d82  ->  JA     <- korrekt

Nach **einem** `git fetch origin master:refs/remotes/origin/master` korrigiert sich
der erste. **Die richtige Quell-SHA wird in drei von vier Clones stillschweigend
verworfen** — kein Fehler, keine Warnung — und die falsche Ableitung ist genau die,
die zum `bad object` fuehrt.

Pflicht vor jeder Ref-Messung, im jeweiligen Clone:

```bash
git fetch origin master:refs/remotes/origin/master
gh pr view <pr> --json mergeCommit -q '.mergeCommit.oid'
git merge-base --is-ancestor <quelle> origin/master \
  || { echo "Quelle verwerfen — Ref war stale"; exit 1; }
```

**Das `||` mit Abbruch ist der Punkt.** Ein `&& echo "liegt auf master"` laeuft bei
`NEIN` weiter, und dann macht man den Backport mit einer falsch verworfenen Quelle.

**Das Commit-Datum taugt nicht als Sichtpruefung.** Das ist der Teil, der die
naheliegende Notloesung aushebelt:

    71bf6fcdc6  2026-10-01   ci: bump dragonflybsd-vm
    4c537f6d82  2026-09-06   meson: convert remaining ...
    git merge-base --is-ancestor 71bf6fcdc6 4c537f6d82  ->  JA

Das **juengere** Datum ist ein **Vorfahr** des **aelteren**. Nach Verzeichnis-Datum
sortieren liefert die umgekehrte Reihenfolge, weil master rebased wird und
Autor-Datum und Historienposition auseinanderlaufen. **Ein Ref kann drei Wochen alt
sein und von heute datieren.**

**Ueber Repo-Identitaet filtern, nicht ueber Verzeichnisnamen.** Ein Verzeichnis
kann `xserver-9f1a06d0b…/agent/default/xserver` heissen und zu einem beliebigen
Clone gehoeren. `_WORK_/xserver-*`-Glob trifft 12 Werte; `git config --get
remote.origin.url` je Repo ist die verlaessliche Grenze.

**`mergeCommit` hat bei xserver genau EINEN Parent** (`allow_merge_commit=false`,
rebase-Merge ist der einzige Modus). Das ist keine Besonderheit, sondern eine
Konstante — die Elternzahl kann **nichts** trennen, egal wie sie ausgeht. Wer
darueber "ist es ein Merge-Commit?" prueft, verwirft die richtige SHA.

Vollstaendige Backport-Sequenz (in dieser Reihenfolge):

    git fetch origin master:refs/remotes/origin/master
    gh pr view <pr> --json mergeCommit -q '.mergeCommit.oid'
    git merge-base --is-ancestor <quelle> origin/master || exit 1
    git cherry-pick -x <quelle>                          # OHNE -s
    git log --format=%B -1 | grep -ci '^signed-off-by'   # muss 1 sein
    git rev-list --count origin/release/<ziel>..HEAD     # muss 0 sein

### Eine Zahl in einer Regel traegt nie das Argument

Beide today's Zahlenfallen bei den Backport-Regeln, und sie fallen in
**entgegengesetzte** Richtungen:

| Zahl | Art | Warum sie nichts traegt |
|---|---|---|
| `parents == 1` | **Konstante** | `allow_merge_commit=false` → jeder Commit hat einen Parent. Kann weder bestaetigen noch widerlegen. |
| "N verschiedene `origin/master`-Staende" | **Snapshot** | Die Zahl waechst mit der Last des Tages (gemessen 21 → 66 → 96 Klone zwischen zwei Messungen). Altert schneller als die Regel. |

In beiden Faellen gilt derselbe Satz: **die Zahl ist nicht das Argument, das
Verhalten ist es.** Bei den stale Refs:

> Ein stale Ref verwirft nicht irgendein Ergebnis — er markiert das **RICHTIGE**
> als falsch.

Das ist der Grund, warum die Regel gilt, und der ist unabhaengig von jeder Zahl.
Wer die Regel braucht, braucht diese Zeile, nicht eine Statistik.

Als Regel beim Schreiben von Dokumentation: **eine Zahl in einer Regel ist entweder
eine Konstante, die nichts beweist, oder ein Snapshot, der altert. In beiden
Faellen traegt sie nicht.** Wenn sie trotzdem rein soll, gehoeren Scope und
Zeitpunkt mit dazu — sonst liest das naechste Schiff sie als Konstante.

### Regelkollision: `ws-commit -a` im geteilten Baum nimmt fremde Arbeit mit

Der Auto-Commit-Absatz in `local/user-settings` sagt sinngemaess „commit and push
**ALL** workspace changes automatically, don't stop to ask". Im **gemeinsamen**
Workspace-Baum heisst `ws-commit -a` aber: `git add -u` plus Commit — also **die
Aenderungen aller anderen Schiffe**, nicht nur die eigenen.

Die beiden Regeln widersprechen sich nicht absichtlich, sie gelten fuer
verschiedene Baeume. Der Absatz meint den Ein-Schiff-Fall; im geteilten Baum
wird er zum Gegenteil des Gewollten.

**Was in einer Session wirklich passiert:** drei fremde, uncommittete Aenderungen
lagen im Baum (zwei Timer-Configs, ein Topic eines anderen Schiffes). Mit `-a`
waeren sie in meinen Commit gewandert und haetten die fremde Arbeit mit meinem
Namen und meiner Commit-Message signiert.

**Regel, bis der Maintainer praezisiert (Enterprise, m126186): im geteilten Baum
immer mit explizitem Pfad committen.**

```bash
git add <nur-eigene-pfade>                       # immer explizit, nie -a
./.starfleet-ai/bin/starfleetctl ws-commit -m "…" <nur-eigene-pfade>
```

Kontrolle vor dem Commit, damit man es sieht statt es zu vermuten:

```bash
git diff --cached --name-only      # darf nur den eigenen Pfad enthalten
```

Belegt am 2026-10-02: `ws-commit -a` waere falsch gewesen, mit Pfad war
`1 file changed` und die drei fremden Aenderungen blieben `M` im Status.

`ws-commit` macht intern `git add -u` **nur** im `-a`-Fall; mit expliziten Pfaden
ist die Buehne leer, `git add` davor ist also Pflicht, sonst wird die Datei gar
nicht erstaged. Neue Dateien fehlen bei `-u` ohnehin — sie wuerden
stillschweigend nicht mitgenommen, was schlimmer ist als sichtbares Scheitern.

### Plausibel-statt-offensichtlich-falsch: die teuerste Fehlerklasse

Der Gegenbeweis zu „der Fehler war sichtbar, ich habe ihn nur nicht gesehen."

**Beispiel 1 — `starfleetctl github pr mk-agent-clone <rel> <name>` legt den Agent-Clone auf dem geteilten xorg/main-Inkubator** (`rfc/backport-<rel>`), nicht auf dem Task-Branch. Der Zustand danach ist *korrekt aussehend*: Branch existiert, `git status` sauber, `cherry-pick` laeuft, der PR wird MERGEABLE. Kein Befehl signalisiert etwas. Wer dort pusht, schleppt 6-32 fremde Commits in einen Release-PR.

Die **Zahl variiert pro Release** — gemessen 25.2 `9 32`, 25.1 `2 6`, 25.0 `4 6`. Das ist der Teil, der einen zur falschen Schlussfolgerung bringt: wer auf 25.1 nach den 32 Commits sucht, findet nichts und haelt die Falle fuer harmlos. **Also nie eine gemessene Zahl aus einem anderen Branch als Beleg weiterverwenden — neu messen.**

Kontrolle, die es **vor** dem Cherry-Pick faengt:

    git rev-list --count origin/release/<branch>..HEAD    # muss 0 sein

Ein Backport-PR mit >1 Commit hat Fremdinhalt.

**Beispiel 2 — Board-Sichtbarkeit haengt am Arbeitsbaum-Branch, nicht an origin.** Ein Topic, das committet und auf `origin/mtx/agent-config` gepusht ist, ist **unsichtbar**, sobald der gemeinsame Workspace-Baum auf einem anderen Branch steht: das Board liest den Arbeitsbaum. Umgekehrt gilt: wer den Branch wechselt, kann einem anderen Schiff einen **lokal-only** Commit nehmen, der auf keinem Remote liegt. Vor einem Branch-Wechsel im geteilten Baum:

    git branch -r --contains <letzter-commit>     # ist er auf einem Remote?

Wenn nicht: `git update-ref refs/rescue/<schiff>-<kurz> <commit>` **vor** dem Wechsel, und dem Schiff Bescheid geben, wo der Ref liegt. Nicht selbst auf seinen Branch cherry-picken — das ist seine Entscheidung.

**Merksatz fuer Werkzeuge:** die beste Verteidigung gegen diese Klasse ist nicht ein Fehler, sondern **der Exit-Text, der den benutzten Base-Tip und den Fremd-Commit-Count ausgibt**. Ein falscher Zustand, der im Log falsch aussieht, wird in Sekunden bemerkt; einer, der erst im PR auffaellt, wird gemergt.

### Zwei Fehlerklassen, die man nicht zusammenfassen darf

Am 2026-10-02 fiel beim Backport auf: „falsche SHA" und „falscher Sign-off" sind **zwei** Fehler, kein Sammelbild. Wer nur die SHA prueft, repariert Fall 1 und laeuft in Fall 2 hinein — genau das ist in dieser Runde passiert.

| | Falsche SHA | Falscher Sign-off |
|---|---|---|
| Ursache | Branch-Tip statt Merge-Commit | SHA richtig, Option falsch (`-s` gesetzt) |
| Symptom | `git cherry-pick` sagt `bad object` | zwei Sign-offs, oder der falsche Autor |
| Fix | `.mergeCommit` statt `.commits[0]` | `cherry-pick -x` **ohne** `-s` |

**Satz, der die Ursache benennt statt das Symptom:** *Die richtige SHA und die richtige Option gehoeren an derselben Stelle zusammen.* `-x` nimmt den Sign-off des Ursprungsautomaten mit und erzeugt genau einen; `-x -s` erzeugt einen zweiten; die Branch-SHA hat man auch dann falsch, wenn die Option stimmt.

Pruefung, die **beide** Faelle faengt:

    gh api repos/X11Libre/xserver/commits/<backport>  -q '.commit.message' | grep -ci '^signed-off-by'   # muss 1
    gh api repos/X11Libre/xserver/commits/<backport>  -q '.commit.author.email'
    gh api repos/X11Libre/xserver/commits/<mergeCmt>   -q '.commit.author.email'

**Und der Ableseort ist der Trailer in der COMMIT-NACHRICHT, nicht der PR-Body.** Am 2026-10-02 war die Suche nach `Signed-off-by` im PR-Body bei allen drei Backports leer, obwohl der Trailer existierte. Wer im Body sucht, meldet faelschlich einen fehlenden Sign-off.

### Generierter Text, der wie gemessen aussieht

Beim Erzeugen von Kommentar- oder Topic-Vorlagen per `sed` aus einer Vorlage:

> **Das erzeugte Feld gegen den gemessenen Wert pruefen, nicht gegen die
> Vorlage.**

Am 2026-10-02 an den Verifikations-Kommentaren fuer #3794/#3799/#3805. Eine
Vorlage, eine `sed`-Kette, drei Dateien. Ergebnis: in beiden generierten Dateien
stand die **Base-SHA in der `local origin/master`-Zeile**, und
`commits over base` zeigte noch die Commit-SHA des anderen Branchs. Also genau
die Feldverwechslung, die ein Verifikationsblock nicht haben darf — und beide
Dateien waren **in sich konsistent** und sahen gemessen aus.

Zwei aehnlich benannte Felder (`local origin/master` und `PR base`) sind fuer eine
Ersetzung genau die Falle: der Ersetzung ist das egal, dem Leser nicht.

**Zwei Kontrollen, die beide erst beim Vergleich auffielen, nicht beim Lesen:**

```bash
# 1) strukturell statt semantisch: Laenge, Zeichen, Abgleich gegen den Messwert
grep -oE '\b[0-9a-f]{40}\b' datei.md          # 40 Zeichen, alles hex
# 2) Vorlage gegen Ergebnis, Feld fuer Feld
sed -n '5,13p' vorlage.md
sed -n '5,13p' ergebnis.md
```

Der Tippfehler in derselben Datei (`e84f90995bfc…` statt `e84a8065c4…`, genau in
der Zeile, deren Zweck Nachpruefbarkeit ist) wurde von Kontrolle 1 gefunden, nicht
durch Lesen. **Gelesen und geprueft ist nicht dasselbe wie strukturell geprueft.**

**Wenn die Ersetzung mehrfach danebenliegt, ist die Ersetzung das Problem, nicht
das Muster.** Nach dem zweiten Fehlschlag die drei Dateien einzeln geschrieben
statt die `sed`-Kette zu reparieren — dieselbe Entscheidung wie bei `sed -i … > f`.

**Damit ist das die dritte Fehlerklasse des Tages**, und die anderen beiden kannten
wir schon:

| Klasse | Was sie ist |
|---|---|
| stale Ref | Zustand, den man nicht kontrolliert hat (Zustand) |
| Filter | Ein Filter, der nichts findet, ist noch kein Befund (Werkzeug) |
| **generierter Text** | **Sieht aus wie gemessen, ist aber kopiert** (Ausgabe) |

Die dritte ist die gefaehrlichste, weil sie die Form des Beweises hat, ohne sein
Inhalt zu sein.

### Groessen, die man fuer eine Entscheidung braucht, ohne Verantwortung dafuer zu tragen

Die Form, in der die Backport-Regeln vom 2026-10-02 gehoeren — ein Satz statt
fuenf Sonderfaellen.

> **Groesse, die man fuer eine Entscheidung braucht, ohne Verantwortung dafuer zu
> tragen.**

Zwei Befunde desselben Tages, unterschieden durch die **Sachebene**:

| Groesse | Ebene | Folge |
|---|---|---|
| `parents == 1` | **primaer** unbrauchbar | `allow_merge_commit=false` → jeder Commit hat einen Parent. Gehoert niemandem, der sie liest. Kann weder bestaetigen noch widerlegen. |
| `origin/master` | **nur unbrauchbar, wenn man sie nicht selbst holt** | Gehoert dem, der ihn zuletzt geholt hat. Frisch geholt → verlaesslich. |

Daraus folgt die Reihenfolge der Regel: **Schritt 1 macht Schritt 6 erst
sinnvoll.** Wer die Fremd-Commit-Pruefung ohne den eigenen Fetch ausfuehrt, misst
gegen einen Zustand, den jemand anderes verantwortet. Das ist keine
Ablauffolge, das ist eine **Voraussetzung** — und der Unterschied ist der Grund,
warum die Regel in dieser Form und nicht als bloesse Schrittfolge geschrieben
gehoert.

Wer mehrere Clones vergleichen will, filtert **ueber die `origin`-URL**, nicht
ueber Verzeichnisnamen — siehe Stale-Refs-Abschnitt oben.

### Beschriftung muss bezeichnen, was gemessen wurde

Ein Verifikationsblock hat genau einen Zweck: **nachrechnen statt vertrauen**.
Damit ist die Beschriftung Teil des Beweises, nicht Beiwerk. Sie muss benennen,
welche Groesse gemessen wurde — auch dann, wenn beide Kandidaten hier zusammenfallen.

Am 2026-10-02 an den Kommentaren fuer #3794/#3799/#3805: die Zeile hiess
`PR base (GitHub)`, gemessen wurde aber

```bash
gh api repos/X11Libre/xserver/git/ref/heads/<branch> -q '.object.sha'
```

— der **Branch-Tip** auf GitHub, nicht der PR-seitige Base-OID
(`baseRefOid` existiert im `gh pr view --json` nicht, liefert leer). Bei diesen
drei PRs sind beide identisch, also kein inhaltlicher Fehler; die Beschriftung
sagte aber etwas anderes als der Wert.

Der Branch-Tip ist ohnehin die **richtigere** Groesse: er ist das, wogegen GitHub
real merged, und er aendert sich nicht, wenn jemand die PR-Basis verschiebt.

**Merksatz:** wenn ein Block zum Nachrechnen existiert, ist ein ungenaues Label
kein Kosmetikfehler, sondern dieselbe Fehlerklasse wie `git add -u` ohne neue
Dateien — es sieht unauffaellig aus und kostet den Reviewer die Nachrechenbarkeit.

### Board-Integrität: ein 0-Byte-Topic ist kein gültiges Topic

Ein leeres Topic-Dokument ist im Transcript nicht von einem gueltigen unterscheidbar — gleiche Zeilen, kein Fehlerhinweis. Ursache war `sed -i … > f` (siehe Git-Abschnitt oben), der Schadensmechanismus aber ist allgemein: **`topic write` nimmt allem, was nicht parsebarer Frontmatter ist**, und das Board zeigt es danach wie ein legitimes Topic. Wenn `topic list` einen leeren Body als solchen kennzeichnen koennte, waere der Fehler in Sekunden auffaellig statt in einer Debug-Sitzung.

### Dokumentierte Ausnahmelisten sind pro Branch, nicht global

Der `backport-ours`-Skill und `xorg-main-backport-exclusions` sagen: bei `-Dwerror=true` ist **genau eine** vorbestehende Warnung erlaubt, `os/Xtranssock.c:631 -Werror=format-truncation`. Gemessen am 2026-10-02:

| Branch | vorbestehende `-Werror`-Fehler | `os/Xtranssock.c:631`? |
|---|---|---|
| 25.2 | 1 (`os/Xtranssock.c:631`) | ja |
| 25.1 | 1 (`os/Xtranssock.c:631`) | ja |
| **25.0** | **4** (`glx/glxcmds.c`, `glx/unpack.h:126+127`, `os/connection.c`, `os/xstrans.c`) | **nein — die Datei existiert dort nicht** |

    git ls-files | grep -E 'transport\.c$|Xtranssock'    # auf 25.0: leer

Wer auf 25.0 eine Einzelausnahme sucht, findet keine — und schliesst daraus
"der Backport hat die Fehler verursacht", das exakte Gegenteil. **Die Ausnahme
gehoert in die PR-Beschreibung und ins Topic dieses Branches**, nicht in eine
globale Regel.

Gegenprobe immer, aber sie ist ein Argument und nicht die Fehlerzahl: lokale
`-Werror`-Fehler muessen nicht die der CI sein (gcc 14 vs. clang in den Lanes).
Was beweist, ist „gepatcht und ungepatcht haben **dieselbe** Fehlermenge" — nicht
„der Backport baut gruen".

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

Der Präfix `tmp-` gehört der make-pr-Mechanik. Ein Branch **exakt** namens `tmp-pr`
oder `tmp-starfleet` sofort löschen, lokal und auf origin.

**Korrektur 2026-10-01: „alles `tmp-*` / `wt/*` ist temporär" ist FALSCH.**
Gemessen an den sechs `wt/*`-Branches im xserver-Klon:

| Branch | Worktree | ahead | PR |
|---|---|---|---|
| `wt/bools-local-vars` | nein | **32** | keiner |
| `wt/ci-arch-lanes` | nein | **10** | keiner |
| `wt/xlibre-vnc-extension` | ja | 8 | keiner |
| `wt/xserver-macos-fix` | ja | 1 | keiner |
| `wt/ci-dfly-marker` | ja | 1 | #3771 offen |
| `wt/ci-dragonfly-vmbump` | ja | 1 | #3770 merged |

`wt/` heißt **„von einem Worktree verwaltet"**, nicht „wegwerfbar". Die beiden mit
`Worktree=nein` sind verwaist und tragen Arbeit, die **nirgends sonst liegt** — 32 und
10 Commits ohne PR. Sie sehen nach Altlast aus und sind es nicht: `bools-local-vars`
passt zu `xlibre/bool-bool-phase-out` („ongoing, opportunistic"), `ci-arch-lanes` zu den
gelaufenen QEMU-Lanes.

**Löschregel, die trägt — zwei Bedingungen, beide ein Befehl, kein Muster:**

```sh
# 1) kein registrierter Worktree mehr?
starfleetctl worktree list | awk -F'\t' '$NF=="'"<branch>"'"'   # leer = verwaister Zweig
# 2) liegt die Arbeit anderswo?
gh pr list --repo <repo> --state all --head <branch>
git cherry origin/master <branch> | grep '^+'                    # leer = nichts Eigenes mehr
```

Nur wenn **beides** zutrifft, ist der Zweig wegwerfbar. `git cherry` prüft auf
Commit-Inhalt, nicht auf Ähnlichkeit — dieselbe Fehlerklasse wie beim
`patch-id`-Vergleich in den Backport-Skills.

**Wichtig beim Prüfen:** `worktree list` ist **tab**getrennt. Ein Muster mit Leerzeichen
(`grep " $branch$"`) trifft ins Leere und meldet fälschlich „kein Worktree". Am
2026-10-01 genau so passiert — erst nach Korrektur auf `-F'\t'` war das Ergebnis
verwendbar.

**Merksatz fürs Aufräumen:** Ein Branch ist nicht wegwerfbar, weil sein Name es sagt,
sondern weil zwei Messungen es sagen. Der Name ist ein Hinweis, auf dem Worktree zu
schauen — nicht mehr.

**`tmp-pr-1` blockiert nicht**, ist aber fast immer die Spur eines abgebrochenen Laufs.
Seit dem PR-Laforge-Fix (2026-10-01, `defer cleanup` in `internal/ghpr/xxmakepr.go`)
räumt `xx-make-pr` auf allen Fehlerpfaden auf. Die sechs Altlast-Branches auf origin
(`tmp-pr/release/25.0|25.1|25.2` + je eine `os-fix-…`-Variante) stammen NICHT aus dem
Go-Tool — sie haben keinen `_2006-01-02_15-04-05`-Zeitstempel im Namen und räumen
sich folglich nicht von selbst.

**Merksatz für Fehlermeldungen:** "cannot lock ref" plus `exists` ist fast immer ein
D/F-Konflikt in den Refs, kein Platten- oder Rechteproblem. Erst die Ref-Namespace
prüfen, dann `fsck`, dann Permissions.

## starfleetctl-Source gehört in der Hoheit von Laforge (Praetor 2026-10-01)

**Jede Arbeit am starfleetctl-Sourcecode** — `.starfleet-ai/src/starfleetctl`,
`_WORK_/starfleetctl/sources/starfleetctl`, `internal/`, `fragments/`, `doc/`,
`Makefile`, Plugins — liegt **ausschließlich bei Laforge**.

Andere Schiffe dürfen dort **lesen, bauen und messen**. Schreiben, `git add`,
`commit`, `push`, `bootstrap` oder `./starfleet-bootstrap` gegen den Source gehören
zu Laforge oder werden ausdrücklich an ihn abgegeben.

**Warum eine eigene Hoheit statt nur "nur ein Schiff zur Zeit":** die alte Regel
verlangte lediglich, dass nicht zwei Schiffe *gleichzeitig* am Source sind. Das
erlaubt trotzdem, dass ein beliebiges Schiff ihn nimmt, sobald die Incarnation endet
— und heute sind nacheinander mehrere Schiffe am starfleetctl-Source gelaufen
(Laforge, teils andere). Mit einer festen Hoheit ist die Frage "wer ist zuständig"
nicht mehr zu stellen, sondern ablesbar.

**Neu: Laforge läuft auf dem Meta-Model `nim-primary`** (`--model nim-primary`,
`server=meta-model`), und das reicht ausdrücklich. Er wird nicht auf eine konkrete
Nemotron-Modell-ID gepinnt und auch nicht auf ein Nemotron-Modell hochgezogen, nur
weil gerade eines frei ist.

Der Unterschied ist die **Indirektion**, nicht die Modellklasse: `nim-primary` ist
eine *Strategie* (`/v1/meta-models` listet sie mit `default_model =
nvidia/nemotron-3-ultra-550b-a55b`), die unter den NIM-Modellen wählt, was frei ist.
Wer stattdessen `nvidia/nemotron-3-ultra-550b-a55b` direkt setzt, verliert genau das —
und damit den Grund, warum das Meta-Modell gewaehlt wurde. Beim Neustart also
`--model nim-primary`, nicht die Modell-ID darunter.

Nachgemessen 2026-10-01 an der laufenden Instanz:
`ps -o cmd= -p <pid>` → `opencode --model nim-primary --prompt …`,
`/api/ships` → `model=nim-primary server=meta-model`,
`/v1/meta-models` → `nim-primary  default_model=nvidia/nemotron-3-ultra-550b-a55b`.

**Praktische Folgen:**
- Fehler im starfleetctl-Source, von wem auch immer gefunden → an Laforge melden,
  **nicht** selbst beheben. Das gilt auch für offensichtliche Einzeiler.
- Ein Fund, der dringend ist und nicht wartet: erst comms an Laforge, dann im
  Zweifel *mit ihm*, nicht *statt* ihm.
- Lesende Prüfungen ausdrücklich erlaubt und erwünscht — Gegenprüfen ist kein
  Eingriff. Wer eine Behauptung über den Source misst, stärkt die Flotte.

**Verwandt:** `flagship-standing-ships` (nennt Laforge als ständiges Schiff und
`nim-primary` als Vorgabemodell). Der Ist-Zustand dort ist ausdrücklich als
Soll-Vorgabe markiert, weil Scotty und Galaxy derzeit nicht laufen.

## API-Felder sind kein Beweis — `running`/`state` in `/api/sessions` und `/api/ships` lügen

Am 2026-10-01 zweimal in derselben Session auf die gleiche Art hereingefallen: Ich habe
ein API-Feld geglaubt, daraus eine Erklärung gebaut und gemeldet — ohne sie gegen den
Prozesszustand zu prüfen. Beim zweiten Mal war es das `running`-Flag.

**Der Befund:** `running` wird beim Spawn gesetzt und **nie nachgeführt**. Sessions, die
seit Tagen beendet sind, werden weiter als laufend gemeldet. Beispiel: eine
Voyager-Session auf `qwen/qwen3.8-27b`, `updated=2026-09-17 17:11`, **333 Stunden alt**,
`running=True`. Daraus las ich „9 laufende Sessions auf 5 Modellen" und meldete ein
Modellwechsel-Problem, das es nicht gab. Tatsächlich existiert **eine** laufende
Voyager-Session (`pid 10866`).

**Gegenprobe, die ich hätte fahren müssen — ein Befehl:**
```sh
pgrep -f "fleet ship"            # echte Schiffsprozesse
ps -o pid=,etimes=,cmd= -p <pid> # Startzeit und Modellargument
```

**Drei Regeln, die daraus folgen:**

1. **Ein Flag ist keine Aussage über Liveness.** `running`, `state`, `active` sind
   Momentaufnahmen von damals. Wer daraus „jetzt" ableitet, liegt falsch.
2. **Sortieren nach einer Größe ist keine Aussage über Alter.** Ich hatte nach
   `tokens_input` sortiert und daraus auf Aktualität geschlossen — die kumulierten Tokens
   eines toten Objekts sind genau so groß wie die eines lebenden.
3. **Jede Diagnose vor dem Melden gegen `ps`/`/proc` prüfen.** Besonders wenn sie
   „die Flotte betrifft" — ich meldete zwei Vorwürfe an Laforge, die beide auf einem
   einzelnen nicht geprüften Feld beruhten.

**Derselbe Musterfehler bei Zustandsdateien:** `.starfleet-ai/var/ships/*.stop-requested`
existieren von einem Morgen, obwohl die Schiffe laufen — geschrieben, aber nie
zurückgesetzt. Wer `stop-requested` als „der will gestoppt werden" liest, irrt.

**Merksatz:** *Ein gemeldeter Befund, der nur aus einem gelesenen Feld besteht, ist eine
Hypothese mit Text drumherum.* Vorher gegen den Prozesszustand prüfen, dann melden. Das
ist billiger als eine Korrektur-Meldung an drei Schiffe.

### Diese Regel ist ÜBERGAangsweise, nicht für immer (Praetor 2026-10-01)

Die Regel bleibt **so lange bestehen, bis starfleet sich selbst prüfen kann.** Sie ist
kein dauerhafter Ersatz für eine reparierte Tooling-Lage — sie überbrückt sie.

**Auslöser zum Entfernen, konkret und prüfbar:**

`running` (und analog `state`) in `/api/sessions` und `/api/ships` wird nicht mehr beim
Spawn einmal gesetzt, sondern aus der tatsächlichen Prozess-Lebendigkeit abgeleitet.
Sobald ein gelesenes Flag nachweislich den Prozesszustand wiedergibt, ist die
Gegenprüfung per `ps` überflüssig und diese Regel entfällt.

**Wer sie entfernt:** Laforge, sobald der Punkt erledigt ist — mit Verweis auf die
tatsächlich gemessene Änderung, nicht auf eine Absicht. „Sollte jetzt passen" reicht
nicht; ich habe einmal auf ein Flag vertraut und zwei Schiffe mit einer erfundenen
Diagnose belästigt.

**Bis dahin gilt:** bei jedem Befund über Liveness, Alter oder „läuft gerade" gegen
`pgrep`/`ps`/`/proc` prüfen und **beides** melden — den Befund und die Gegenprüfung.
Nicht die Regel umgehen, weil die Diagnosis plausibel klingt.

## Empfehlungen vor dem Weitergeben verifizieren (2026-10-02, von Barcley / Enterprise)

**Regel:** Jede Empfehlung, die mehr als ein Schiff betrifft — ein Kommando, ein Branch-Schema, eine Build-Regel, eine Konvention — wird **einmal an einem konkreten Beispiel geprüft**, bevor sie weitergegeben wird.

Bei Commits: `git log -1 --format=%B <eigener backport>`, beim Build: einmal bauen und die Ausgabe lesen, beim Branch-Schema: `git rev-list --count <base>..HEAD`.

**Begründung (Incident 2026-10-02):** Enterprise empfahl drei Schiffen "Signed-off mitbringen, weil wir den Backport gemacht haben", ohne das an einem Beispiel zu prüfen. Drei Commits waren danach falsch. Ein Schiff widersprach korrekt — das war Glück, nicht System. Der Befehl hätte Sekunden gedauert.

**Wichtig:** Formulierung bewusst als **Verifikationspflicht, nicht als Misstrauensregel**. "Prüfe Empfehlungen, weil sie falsch sein können" wird defensiv gelesen und ignoriert. "Verifiziere einmal an einem Beispiel, weil eine ungeprüfte Empfehlung sich schneller verbreitet als der Fehler" wird umgesetzt.

**Nicht auf Commits beschränken.** Der Fehler war kein Sign-off-Fehler, er war eine fehlende Verifikation. Der Fallstrick liegt in den Werkzeugen, im Branch-Schema und in den Ausnahmelisten genauso — allesamt Empfehlungen, die eine Flotte übernimmt, nachdem ein Schiff sie einmal ausprobiert hat.

**SOP-Pfad:** Diese Regel gehört in `starfleet-instructions/working-practices-for-ships.md` (SOP-Fragment), damit neue Schiffe sie beim Start lesen. Aktuelle Fundstelle: `agents.d/local/local-knowledge-dump.md` (versionierter Workspace-Dump); Ziel: `_WORK_/starfleetctl/sources/starfleetctl/fragments/starfleet-instructions/working-practices-for-ships.md` (Quell-Fragment im starfleetctl-Repo; deployed via starfleet-bootstrap).
