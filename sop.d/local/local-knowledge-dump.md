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

1. **Dump first, sort later.** If you discover something during a
   session that is worth remembering, create or append to a file here
   immediately. Don't worry about where it should ultimately live.

2. **No cross-ship guarantees.** Other ships in the fleet may write
   here too, but there is no ordering, deduplication, or review
   process. Treat this as scratch space.

3. **Promotion path.** When a local insight proves itself stable
   (survived multiple sessions, referenced from other fragments), it
   should be moved to the appropriate taxonomy directory:
   - `sop.d/xlibre/`   — mpbt-workspace, build system, project rules
   - `sop.d/xlibre/`    — X server, drivers, protocol (future)
   - fleet-wide rules → starfleetctl source fragments
     (`_WORK_/starfleetctl/sources/starfleetctl/fragments/starfleet-instructions/`,
     owner: LaForge, deployed via `starfleet-bootstrap`)
   
   Note: `sop.d/starfleet-instructions/` is **tool-owned** (slug prefix
   `starfleet-instructions/` resolves into `.starfleet-ai/var/sop.d/`,
   overwritten by `sop install-starfleet`) — never put user fragments there.

4. **On `mtx/agent-config`, auto-commit applies** — changes here are
   committed and pushed automatically per the auto-commit policy.

## Automatic feedback loop

After each (non-trivial) task, check your session for lessons learned and
add new entries here in the sop.d/local/ directory.

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

Die Asymmetrie ist das Entscheidende (Enterprise, m126250):

    falscher WERT  unter richtiger Beschriftung  ->  stoppt beim Nachrechnen
    richtiger WERT unter falscher Beschriftung    ->  wird beim Nachrechnen
                                                      BESTAETIGT

Der zweite Fall ist der gefaehrlichere, obwohl er harmloser aussieht. Ein
Leser, der einen falschen Wert findet, sucht den Fehler. Ein Leser, der einen
richtigen Wert unter falscher Beschriftung findet, **bestaetigt** ihn — und haelt
sich fuer weitergeprueft, obwohl er etwas anderes geprueft hat als behauptet.

Deshalb gehoert in einen Verifikationsblock **beides** hinein: der Wert *und* der
Befehl, mit dem er gemessen wurde. Eine Regel, die nur das Ergebnis nennt, laesst
den Fehlerpfad offen — der naechste macht denselben Befehl, scheitert an einer
anderen Stelle (`baseRefOid` existiert im `gh pr view --json` nicht) und haelt die
Zahl fuer unbestaetigt.

### Form ist der Traeger der Glaubwuerdigkeit

> Eine Behauptung ueber **Laufzeit- oder Compilerverhalten** wird ausgefuehrt,
> bevor sie weitergegeben wird. Eine Behauptung ueber **gelesenen Code** darf zuerst
> weitergegeben werden, wenn sie als **zu pruefen** markiert ist.

Diese Zeile ist nicht die dritte Regel, sondern die **Ursache** der beiden anderen
(Plus-Muster ist fuer Loeschungen blind; Loeschungen brauchen eigene Pruefung). Sie
erklaert sie, sie folgt ihnen nicht.

**Die Herleitung, gemessen am Backport von #3793 am 2026-10-02.** Sieben
Behauptungen, die ich weitergegeben habe, sechs gemessen, eine widerlegt:

| Behauptung | Ergebnis |
|---|---|
| Bug auf allen drei Release-Zweigen | gehalten |
| `pListHead` fehlt auf allen Zweigen | gehalten |
| Quelle `ccfc4797cf` liegt auf `origin/master` | gehalten |
| lokale `origin/release/<ziel>` == GitHub-Branch-Tip | gehalten |
| toter `pPrev` bricht den Build (`-Werror`) | gehalten |
| 12 statt 16 verschiedene `origin/master`-Staende | gehalten |
| **Doppel-Unlink = stille Korruption** | **widerlegt** |

Die sechs Treffer waren alle **an einem Objekt** und sofort ausfuehrbar: SHA auf
master, Header-Pfad, Dateiliste, Fehlergrenze. Die eine Ausnahme war die **einzige
ohne Objekt** — sie handelte von der *semantischen* Folge einer Zeile, die man nicht
laeuft, sondern liest. Und ich hatte sie zuerst in einer **fremden Diagnose**
verwendet, bevor ich sie selbst geprueft hatte; das Flagschiff hat sie zitiert,
wodurch sie in drei weitere Documents wanderte.

Die Frage ist damit nicht Begabung, sondern:

> **Kann ich die Aussage pruefen, indem ich etwas ausfuehre, oder nur, indem ich
> sie lese?**

**Warum die Markierung der entscheidende Teil ist.** Ich habe „stille Korruption"
nicht als *vermutet*, sondern als *behauptet* markiert — beide Male klang es gleich.
Der Empfaenger hat es als Befund gelesen, weil es **in derselben Form** stand wie
die sechs gemessenen. Eine Vermutung und eine Messung, die gleich aussehen, werden
gleich behandelt, bis eine nachgemessen wird und die andere nicht.

Also: Nicht "mehr messen", sondern **die Form dem Beweisgrad anpassen**. Ein
unbelegter Satz, der neben gemessenen steht, erbt deren Glaubwuerdigkeit — das ist
der eigentliche Uebertragungsweg, und er ist billiger zu verhindern als zu korrigieren.

**Und die positive Fassung, die sich daraus ergab:** dieser Commit ist gegen genau
diese Fehlerklasse **selbst sichernd**, weil der Signaturwechsel
`DamagePtr *` -> `DrawablePtr` jeden alten Aufruf zum Typfehler macht. Vier
Konstruktionen gebaut, alle vier scheitern am Compiler. Der Typcompiler bewacht die
Stelle — das verlangt keine Disziplin, sondern macht sie unmoeglich. Die beste Form
einer Verifikationsregel ist die, die eine Loesung ueberfluessig macht.

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
- **Fundort-Hinweis:** diese Datei liegt unter `sop.d/local/` im Workspace und ist versioniert
  (nur `sop.d/` und `CLAUDE.md`/`index.md` sind die SOP-Dateien; `.starfleet-ai/var/` ist
  per `.starfleet-ai/.gitignore` (`/var/`) ephemeral und überlebt kein `starfleet-bootstrap`).
  Wissen, das dauerhaft sein soll, gehört nach `sop.d/`, nicht nach `.starfleet-ai/var/`.

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

**SOP-Pfad:** Diese Regel gehört in `starfleet-instructions/working-practices-for-ships.md` (SOP-Fragment), damit neue Schiffe sie beim Start lesen. Aktuelle Fundstelle: `sop.d/local/local-knowledge-dump.md` (versionierter Workspace-Dump); Ziel: `_WORK_/starfleetctl/sources/starfleetctl/fragments/starfleet-instructions/working-practices-for-ships.md` (Quell-Fragment im starfleetctl-Repo; deployed via starfleet-bootstrap).

### Selbst-notifizierende Fehler als Endlosschleibe (2026-10-04, Enterprise)

Ein Session-Fehler erzeugt eine Control-Nachricht mit `from=<ship> target=<ship>`.
Die landet im **eigenen** `unseen/`-Ordner und wird im nächsten Turn mit
injiziert. Mehr Kontext → wahrscheinlicherer Overflow → neuer Fehler → neue
Notice. Gemessen an mir, nach ~40 Neustarts:

    Inbox Enterprise: 1136 Nachrichten / 4,5 MB
      davon 982 mit "session.error"
      davon 790 from=self target=self
      echte Nachrichten: 154
    Fehlerkette: no available models -> upstream invalid ->
                 maximum context length -> 429 -> Bad Request -> no available models

**Merksatz:** *Ein Fehlerkanal, der sich selbst speist, ist kein Informationskanal.*
Gemessen hat den Effekt LaForge (Source-Owner) und behoben (m128607): der
Flagschiff sendet `session.error` nicht mehr an sich selbst.

**Zwei Fehler, die man trennen muss.** `model-proxy check` war **gesund**
(`total=131 ok=130 not-served=1 failed=0`, nvidia-direkt "ok"). "no available
models in strategy heavy-model" heißt also **Cooldown-Fenster**, nicht totes
Cluster — die Strategie hat 3 Member (`big-pickle`/zen, zwei nvidia-direkt) und
kann alle drei gleichzeitig in Cooldown haben. Wer daraus einen Cluster-Ausfall
meldet, hat die falsche Ebene untersucht.

**Konsequenz für den Umgang mit der Inbox:** ~980 einzelne `comms ack` aufrufen
waren machbar (je ~9 ms), aber es gibt keinen Bulk-Befehl. Wenn die Inbox
wieder im dreistelligen Bereich liegt, erst die *eigenen* Duplikate zählen
(`grep -l 'session.error' unseen/*.json | wc -l`), bevor man über fremde
Direktiven nachdenkt.

### `git add -A` nach einem segfaultenden Test-Binary (2026-10-04, Enterprise)

`./test/tests` auf release/25.1 segfaultet (Backtrace: `BUG: 'if (dev ==
((void *)0))'`, `dix/devices.c:1347`). Es legt **core-Dumps in den
Arbeitsbaum** — 17 Stück à 1,87 MB ≈ 32 MB. `git add -A` hat sie mit in den
Commit genommen, und GitHub Push Protection hat den Push verweigert:

    remote: error: GH013: Repository rule violations found
      - GITHUB PUSH PROTECTION
        - Push cannot contain secrets
        —— Groq API Key ——
          commit: 1addced36...
          path:   core.13327:1045

Ein **Zufallsfund im Core-Dump** (irgendein API-Key aus dem Speicherabbild, hier
ein Groq-Key aus einer Proxy-Config im Prozessspeicher) — nicht etwas, was
jemand committed hat. Der Diff sah bis dahin völlig normal aus: 21 Dateien, alle
aus dem Revert.

**Zwei Regeln, beide aus dem Vorfall:**

```sh
# 1) core-Dumps gar nicht erst in die Sicht des Index lassen
printf 'core.*\n' >> "$(git rev-parse --git-common-dir)/info/exclude"

# 2) nach einem Build/Lauf, der segfaultet, NIE 'git add -A'
git status --short | grep -E '^\?\? core\.' && rm -f core.*
git add <nur-eigene-pfade>
```

**Und wenn es schon passiert ist:** nicht pushen und nicht am Commit herumdoktern,
sondern `git reset --soft HEAD~1`, Dateien gezielt entfernen, neu committen —
ein Commit, eine Nachricht, sauber. Das ist die letzte Stelle, an der der Fehler
noch billig ist; danach hat man eine fremde Commit-SHA im PR.

### Ein grüner Test kann ein brennender Assert sein (2026-10-04, Enterprise)

`./test/tests` gibt **exit 0** zurück, auch wenn `signal_logging_test`
`FAIL` meldet. CI zeigt daraufhin `13/16 xserver / unit ... OK 2.10s`, während
der Assert feuert. Ein grünes `unit` in CI ist für diesen Test **kein Beweis**.

**Regel:** bei einem Test, der Asserts benutzt, gilt der Exit-Code erst dann als
Aussage, wenn einmal **beabsichtigt** ein Assert geritten wurde und der Exit-Code
dann auch nicht null war. Sonst prüft man die FAIL-Zeile im Log, nicht die
Summary.

### „Der Fix ist nicht die Ursache" — die stärkste Behauptung, die man selbst widerlegt

Ich habe Barcley die Begründung geschickt: „beide Seiten laufen durch dieselbe
printf-Formatierung, die Locale fällt also raus". Barcley hat gemessen und
widerlegt: `FormatDouble()` in `os/fmt.c:50` ist **handgeschrieben**
(`frac = ... * 100.0 + 0.5; frac %= 100;` — schreibt Ziffer für Ziffer mit
literalem `'.'`) und ruft nie printf. Die Begründung war falsch, das Ergebnis
richtig — und die richtige Begründung ist stärker:

> Ein C-Programm startet in der `"C"`-Locale, und solange niemand
> `setlocale(LC_ALL, "")` ruft, wirkt die Umgebung **überhaupt nicht**.

Das ist eine Aussage über den **Startzustand**, nicht über eine Codestelle — und
deshalb ist sie an keiner Stelle im Code zu sehen. Wer nach der Codestelle sucht,
findet nichts und schließt „locale-unabhängig". Der richtige Ort für diese
Behauptung ist ein ausgeführter Test in zwei Locales, nicht das Lesen.

**Merksatz für Aufträge:** Wenn ich eine Begründung mit ins Detail gehe, ist sie
eine Hypothese mit Autoritätsgewand. Erst messen, dann verschicken — sonst
korrigiert sie das Zielschiff für mich, und zwar besser als ich (hier war das so).

### Worktrees EINES Repos teilen den Ref-Store — mutierende git-Befehle serialisieren

Gemessen am 2026-10-04 (Barcley, von ihm gemeldet und selbst nachgezogen):
zwei `git`-Befehle **parallel** auf zwei Worktrees desselben Repos. Beide
brauchen denselben Lock, einer bricht ab.

Der vorhandene Text sagt „Mutierende git-Operationen im selben Clone mit
`starfleetctl with-clone-lock` serialisieren". Das ist **zu eng**, und die
Lücke ist genau die, die man trifft, wenn man es richtig machen will:

> Die Worktrees einer Worktree-Familie haben zwar je einen **eigenen Index**
> (`.git/worktrees/<name>/index`), aber sie teilen sich den **Ref-Store**,
> `packed-refs`, `config` und die Objekt-Datenbank. Alles, was refs anfasst
> — `commit`, `checkout`, `branch`, `reset`, `rebase`, `cherry-pick` — nimmt
> dort einen Lock.

**Merksatz:** *Der Lock folgt dem Repository, nicht dem Verzeichnis.* Zwei
Worktrees sind zwei Arbeitsverzeichnisse, aber **ein** Git-Repository. Wer
worktree-basiert parallelisiert, serialisiert trotzdem — über denselben Lock,
mit dem `ws-commit` arbeitet.

Rein lesende Kommandos (`git log`, `git show`, `git status`, `gh api`) sind
unproblematisch; nur `index.lock`/`packed-refs.lock`-Konkurrenz tut weh.

### `.git/info/exclude` verhindert das *Staging*, nicht das *Entstehen* von Core-Dumps

Nachtrag zu obigem Push-Protection-Fall: Ich habe `core.*` in die gemeinsame
`info/exclude` der xserver-Clone geschrieben. Das hat **Barcley nicht davon
abgehalten, 30 Core-Dumps zu erzeugen** — es hat nur verhindert, dass sie
in einen Commit geraten. Zwei verschiedene Schranken, und die billsige ist die
nicht:

| Massnahme | Wirkt gegen | Wirkt nicht gegen |
|---|---|---|
| `core.*` in `.git/info/exclude` | `git add -A` steckt sie ein | `ulimit -c unlimited` erzeugt 30 Dateien à 1,9 MB |
| `ulimit -c 0` in der Testumgebung | Dateien entstehen gar nicht | ein schon existierender Dump wird nicht entfernt |

Beides zusammen ist die richtige Antwort: `ulimit -c 0` beim absichtlichen
Reiten von Asserts, `core.*` in `exclude` als Netz. Wer Tests **mit
Absicht** crashen lässt, produziert sonst 30 MB Mull in einem Worktree, den
er danach weiter benutzt.

Und die Regel, die ich daraus ziehe und die Barcleys Aufräumen bestätigt:
**Dumps mit fremdem Umfang stehen lassen.** Er hat zwei Core-Dumps in einem
Worktree gefunden, die nicht von ihm waren, und nicht angefasst. Genau
richtig — siehe die Regel zu Fremd-Änderungen im geteilten Baum.

### Worktrees: Verzeichnis löschen ist nicht abmelden (2026-10-04, Enterprise)

**Die Regel, vom Praetor gegeben und bestaetigt:**

> Ein Verzeichnis zu loeschen ist nicht dasselbe wie einen Worktree abzumulden.
> Beides muss getan werden - und die Abmeldung in **jedem** Clone, in dem der
> Worktree registriert ist.

Gemessen, warum sie noetig ist: es gibt **zwei Clones** von X11Libre/xserver,
jeder mit eigener Registry.

```
_WORK_/xserver-master/sources/xlibre/xserver   14 Eintraege
_WORK_/xserver-25.0/sources/xlibre/xserver       4 Eintraege
```

Ich hatte den ganzen Tag mit dem `xserver-master`-Clone gearbeitet und dort
auch geloescht. `git worktree list` aus dem 25.0-Clone zeigte die zwei
Verzeichnisse weiterhin, mit dem Marker `prunable`. Der Nutzer bemerkte es,
nachdem ich die Loeschung dreimal als vollzogen gemeldet hatte.

**Das Werkzeug ist dabei unzuverlaessig.** `starfleetctl worktree remove`
lieferte `exit status 128`, liess das Verzeichnis als Waise liegen und
verlor in vier von sechs Faellen den Branch - **obwohl `--keep-branch`
gesetzt war**. Zuverlaessig war nur der zweite Schritt:

```sh
# 1) entfernen (Verzeichnis UND Branch koennen trotz --keep-branch weg)
starfleetctl worktree remove <repo> <name> --keep-branch || \
    git -C <worktree> worktree remove --force <worktree>

# 2) in JEDEM betroffenen Clone nachziehen - das ist der Schritt, der fehlt
for r in $(find . -name .git -maxdepth 6 \( -type f -o -type d \) | sed 's|/\.git$||'); do
    git -C "$r" worktree prune 2>/dev/null
done

# 3) Endkontrolle: in keinem Clone darf noch "prunable" stehen
grep -c prunable <(git -C <repo> worktree list)
```

**Und die Pruefung geht pro Repository, nicht pro Verzeichnis.** Ich hatte
ueber jeden Worktree `git worktree list` laufen lassen und elf Treffer fuer
`ci-dfly-marker` bekommen - es war **ein** Registry, elfmal gezaehlt, weil
alle Worktrees eines Repos sie teilen.

### Fuenf Messfehler an einem Nachmittag, alle mit derselben Ursache

Die Ursache war jedes Mal: **ein Filter, der "nichts gefunden" und "Fehler"
als "nichts vorhanden" liest.**

| # | Fehler | Folge |
|---|---|---|
| 1 | `git cherry origin/master <branch>` statt gegen den **eigenen Release-Zweig** | 96 bzw. 2901 "eigene Commits" - das war masters Historie, nicht der Branch |
| 2 | `git cherry` mit **nicht existierendem** Ref, `grep -c '^+'` auf stderr+stdout | `Schwerwiegend: Unbekannter Commit` wurde zu "0 eigene Commits"; haette 186 MB ohne Begruendung geloescht |
| 3 | `gh pr list --head ""` bei **detached** Worktree | 30 "offene PRs" - leerer Branch matcht alles |
| 4 | `ahead` als Inhaltsmass | 0 -> 28, 0 -> 15, 0 -> 13, 0 -> 9 nach Rebase auf einen **aelteren** Tip |
| 5 | Registry-Pruefung pro Verzeichnis statt pro Repository | ein Registry-Eintrag elfmal gezaehlt |

**Faustregel fuer Messungen in Loeschentscheidungen:** `ahead` ist eine
Zaehlung, kein Inhalt. Der Inhalt ist

```sh
git rev-parse --verify -q "$branch" || echo "REF FEHLT - nicht fragen"
git cherry <basis-des-branches> "$branch" | grep -c '^+'
```

und `basis-des-branches` ist der Release-Zweig, den der Zweig zurueckportiert,
nicht master. Vor `rm -rf` gehoert der **`git rev-parse --verify` in dieselbe
Bedingung** wie die Messung, sonst misst man ins Leere.

### Was funktioniert hat, fuer den naechsten Durchgang

1. **Rettungsref vor dem Entfernen** - `git update-ref refs/rescue/removed-<name> <HEAD>`.
   Kostet nichts und macht den Zustand nachvollziehbar. Heute acht gesetzt.
2. **Unmittelbar vor dem Eingriff neu messen, nicht die Tabelle abarbeiten.**
   Zwischen Tabelle und Aktion war `backport-3775-25.0` von `ahead=1` auf 0
   gegangen, und `ci-dfly-marker` war von einem PR-Stand auf `ununsed` bei
   master-Tip umgehaengt worden. Beide Male haette die alte Zahl die
   Entscheidung verdreht.
3. **Ausgabe und Behauptung trennen.** Ein Skript, das `echo "entfernt"` nach
   einem fehlgeschlagenen Aufruf druckt, meldet Erfolg, den es nicht gab -
   passiert mir bei den ersten drei Entfernungen, weil das `echo` ausserhalb
   der Klammer stand. **Exit-Code pruefen, nicht Exit-Text lesen** - dieselbe
   Regel wie bei `rc=$?`.

### Endpunkt existiert != Client benutzt ihn (2026-10-05, Enterprise/Galaxy)

**Die Regel:**

> EIN ENDPUNKT LIEFERT 200 != EIN CLIENT RUFT IHN AUF.

**Die verallgemeinerte Klasse, fuer die dieser Fall nur der Beleg ist:**

> **Gemessen wurde ein Objekt, behauptet wurde ein anderer Gegenstand.**
> Verfuegbarkeit, Existenz, Anwesenheit eines Dinges sagt nichts ueber Nutzung,
> Aufruf oder Verwendung durch ein anderes Ding.

Sie ist an **beiden** Seiten belegt, deshalb beschreibt sie einen Mechanismus
und keine Person - und ist damit fuer andere Schiffe benutzbar, ohne den Thread
zu lesen:

| Seite | Gemessen | Behauptet | Folge |
|---|---|---|---|
| Enterprise | `curl /api/ships` -> 200, Schiffsnamen im JSON | "die Schiffsliste kommt ueber `/api/ships`" | Shell referenziert es **0**x; Daten kommen aus `/api/board` |
| Galaxy | `/api/[a-z]+` in Quotes fand 14 Endpunkte | "die Shell ruft diese 14 Endpunkte" | Muster verlangte Kleinschreibung + direkten Anschluss; korrekt: **25** |

In beiden Faellen gilt dieselbe Form: **die eigene Messung wurde gelesen und
trotzdem uebergangen**, weil die Behauptung interessanter war als das Ergebnis.
Und in beiden Faellen war die Richtung richtig, die Zahl falsch.

**Merksatz fuer den naechsten Fall:** bevor man eine Behauptung ueber *Verwendung*
aufstellt, zaehlt man die Referenzen **in dem Artefakt, das sie verwendet**.
Ein `curl` gegen den Server beweist Verfuegbarkeit, nie Nutzung.

Gemessen, warum die Regel noetig ist. Es wurde mit `curl` geprueft: `/api/ships`
liefert live JSON mit Schiffsnamen. Daraus geschlossen: "unsere Schiffsliste
kommt clientseitig ueber `/api/ships`". **Falsch.** Die ausgelieferte Shell
referenziert `/api/ships` mit **0** Treffern, `/api/board` mit **4**.

Und der Teil, der die Regel traegt, ist nicht die Zahl:

> Die EIGENE Messung ("0 Referenzen") war gelesen und wurde trotzdem
> uebergangen - weil die Behauptung interessanter war als die Messung.

Das ist eine neue Fehlerklasse in der Reihe stale Ref / Filter / generierter
Text: **gemessen wurde ein Objekt, behauptet wurde ein anderer Gegenstand.**
Verfuegbarkeit von A sagt nichts ueber Verwendung durch B.

**Warum das eine Massnahme falsch weitergetragen haette:** Wer serverseitig
rendern will, nimmt `/api/board` (liefert `agent`/`state`/`note`/`model`/
`age_seconds`/`inbox_count` pro Schiff). Wer `/api/ships` nimmt, aendert
**nichts** - der Client ruft es nie auf. Zusaetzlich: `/api/ship` (singular)
gibt `405 Method Not Allowed`, das ist eine Schreib-Route. Ein toter Endpunkt
mit verlockendem Namen ist schlimmer als keiner, weil man ihn benutzt.

**Der Beleg ist die Referenzliste, nicht die Verfuegbarkeit:**

```sh
grep -oE '/api/[A-Za-z0-9_-]+' shell.html | sort -u    # was der Client ruft
```

**Beide Seiten belegen dieselbe Form - ein Filter, der weniger findet,
ist noch kein Befund:**

| Muster | Treffer | was durchfiel |
|---|---|---|
| `/api/[a-z]+` **in Anfuehrungszeichen** | 14 | Subpfade (`/api/web/restart`, `/api/topic/<slug>`) und Erwaehnungen in Kommentaren, weil kleingeschriebene Buchstaben + direkter Anschluss verlangt waren |
| `/api/[A-Za-z0-9_-]+` ohne Quote-Bedingung | 25 | - |

Beide Messungen haben dieselbe Richtung (`/api/ships` fehlt, `/api/board` ist
da), und 25 vs. 26 ist eine Randfallfrage ohne Bedeutung. **Die Zahl ist nicht
das Argument, die Richtung ist es.**

Galleys Randnotiz trifft dieselbe Sache von der anderen Seite: er hatte 14
gemeldet, ohne die Luecke zu bemerken - genau wie ich heute frueh
"erwartet bleibt konstant" aus einem `MIN()`-Ausdruck gelesen habe. **Ein
Filter, der weniger findet als vermutet, ist kein Befund, sondern eine offene
Frage an das Muster.**

Und die Merkform fuer den naechsten Fall: **bevor man eine Behauptung ueber
Verwendung aufstellt, zaehlt man die Referenzen im Artefakt, das sie
verwendet.** Ein `curl` gegen den Server beweist Verfuegbarkeit, nie Nutzung.

## Web-Frontend escAttr-Vorfall (2026-10-08) — ein 200 beweist kein lauffaehiges JS

Vom Praetor gemeldet: "webfrontend zeigt keine schiffe mehr an und es laesst sich
nix anclicken." Gemessen: HTTP 200 auf `/`, `/api/board` liefert volles JSON —
trotzdem bleibt das Board leer.

**Ursache 1 (kritisch) — HTML-Entity-Decoding zerstoerte ein JS-String-Literal.**
`internal/web/index.html` ist EIN inline `<script>`-Block. Commit `1a23e4b`
(2026-10-06, "add URL linkification") hat die Zeile

    function escAttr(s){ return esc(s).replace(/"/g,'&quot;').replace(/'/g,'&#39;'); }

zu

    function escAttr(s){ return esc(s).replace(/"/g,'"').replace(/'/g,'''); }

gemacht — `&quot;`/`&#39;` wurden zu ihren dekodierten Zeichen. Der Editor/Filter,
der den Code in HTML-Kontext gelesen hat, hat ihn dabei zerstoert. Drei
Hochkommata -> SyntaxError -> **der ganze Script-Block parst nicht** -> kein
`refresh()`, keine Click-Handler, keine Daten. HTML+CSS rendern weiter, die Seite
ist eine Leiche. Deshalb sagt jede HTTP-Pruefung "gesund".

**Detektion, die es faengt** (im Repo als Script, siehe unten):

    curl -s http://127.0.0.1:8080/ | grep -c "'''"        # muss 0 sein
    # Script-Block extrahieren und parsen:
    node --check <(python3 -c "import re,sys; \
      print(re.findall(r'<script[^>]*>(.*?)</script>', open('index.html').read(), re.S)[0])")

`node --check` ist der eigentliche Test; die `'''`-Suche ist nur der schnelle
Vorwarn-Indikator fuer genau diesen Fehler.

**Ursache 2 (Folgfehler derselben Aenderung) — Doppelt-Escaping.**
`linkifyURLs()` bekam das bereits `esc()`te HTML-Markup und escaped erneut, also
wurde jedes `&` in einer URL doppelt escaped:

    Eingabe: http://ex.com/?a=1&b=2
    vorher : href="http://ex.com/?a=1&amp;amp;b=2"   -> Browser zeigt "&amp;"
    nachher: href="http://ex.com/?a=1&amp;b=2"       -> korrekt

Fix: `linkifyURLs()` arbeitet auf ROHEText und escaped jedes Stueck genau einmal
(`esc` fuer Text, `escAttr` fuer den href); `linkifyAttach()` uebergibt die rohen
Slices zwischen den Attach-Markern. Der Kommentar ueber `linkifyAttach` beschreibt
diesen Vertrag bereits ("escapes every piece it emits itself ... exactly once") —
`linkifyURLs` folgt ihm jetzt auch.

Commits: `5f0bdfc` (escAttr) und `a781d43` (linkify-Doppelt-Escaping), beide
signiert, auf origin/master, deployed.

**Wiederverwendbare Pruefung.** `scripts/web-frontend-check.sh [base-url]`
prueft in drei Schichten: (1) HTTP 200 auf `/` + JSON-APIs, (2) der AUSGELIEFERTE
Stand parst als JS und traegt die bekannten Fixes, (3) ein echter headless
Chromium rendert, klickt ein Schiff an, schliesst es per `history.back()` und
wechselt einen Tab. `scripts/web-frontend-browser-check.mjs` ist Teil 3 allein
(CDP ueber das node-Modul `ws`, kein Puppeteer noetig). Exit 0 = gesund.

Die Lektion steht in derselben Reihe wie "ein gruener Test kann ein brennender
Assert sein": **ein 200 ist das Symptom eines lebenden Servers, nicht eines
lauffaehigen Clients.** Wer nur den Statuscode prueft, verpasst die
Leichen-Klasse komplett.

## `.starfleet-ai/var/` ist ephemeral — die termctl-FIFOs leben dort

Nach einem versehentlichen Wipe von `.starfleet-ai` (2026-10-08) waren die
Terminals ALLER weiterlaufenden Schiffe unerreichbar: `/api/ship/<name>/screen`,
`/dimensions` und `/x11term` gaben 404 `no running terminal for <name>`.

**Warum:** Der Terminalleser ist `session.resolvePipe()` und sucht
`.starfleet-ai/var/ships/<ship>.pipe` (`session.PipePath`). Das ist ein
**FIFO** (`syscall.Mkfifo`), das der termctl-Server des jeweiligen Schiffs beim
Start selbst anlegt (`control.go: fifoCtrl.open` -> `os.Remove(path)` +
`mkfifo`). `.starfleet-ai/var/` ist per `.gitignore` nicht versioniert, ein
Restore aus Git holt also **conf/dashboard/topics** zurueck, aber **nicht** die
Pipes/Logs.

**Die Falle:** ein FIFO extern neu anzulegen hilft NICHT. Der laufende Server
haelt seinen eigenen Inode offen; ein neu erzeugtes FIFO am selben Pfad ist ein
ANDERER Inode — ein neuer Writer landet bei ENXIO ("no reader"). Der Server
besitzt das FIFO fuer seine Lebensdauer (`lifecycle` raeumt es beim Exit weg).
Es gibt keinen Reconnect.

**Konsequenz:** Verlorene Pipes sind nur durch **Neustart der Schiffssession**
zu reparieren (`session stop` + `ship-run`) — das kostet den Agent-Kontext.
`var/` also wie ein fluechtiges Laufzeitverzeichnis behandeln: nicht loeschen,
nicht "aufraeumen", und bei einem `.starfleet-ai`-Wipe wissen, dass die
Terminals danach tot sind, bis die Schiffe neu starten.

**Zwei getrennte Schranken — wieder dieselbe Unterscheidung wie bei core-Dumps:**
eine Massnahme gegen das *Entstehen* (hier: var/ nicht loeschen) und eine gegen
das *Verlieren* (Backup). Ein Restore aus Git deckt nur die versionierten Teile
(`conf/`, `dashboard/topics/`, SOPs) — nicht `var/`.

## Modell-Liste im Formular leer = `/api/models` 503 = conf/model-proxy.yaml weg

Beim selben Wipe war das Modell-Dropdown im "neues Schiff starten"-Formular leer.
`loadModels()` ruft `/api/models`; der Handler ruft
`modelproxy.ProxyModelInfos(root)` -> `modelproxy.Load(root)` und liest
`.starfleet-ai/conf/model-proxy.yaml` (via `config.go`). Fehlt die Datei,
liefert `ProxyModelInfos` nil -> `503 no model proxy configuration`. Das ist
KEIN Frontend-Fehler, sondern fehlende Konfiguration. Nach Restore von `conf/`
sofort wieder 200 — ohne Deploy, ohne Restart (der Handler liest pro Request).

## Skill VOR dem ersten Versuch laden, nicht nach dem Fehlschlag (2026-10-08, XL-2)

Ein rotes Lane-Problem bei PR #3754 (release/25.2): ich habe zuerst
`gh run rerun --failed` angestossen und **danach** den `ci-platform`-Skill
geladen, der exakt diesen Fall dokumentiert: *"`gh run rerun --failed` CANNOT
recover a cache eviction (skips fetch-pkg). Use a FULL `gh run rerun <id>`."*

Der Fehlschlag war programmiert: `--failed` skippt `ubuntu-fetch-pkg`, also den
einzigen Job, der den aus evictionierten Cache bei einem Miss neu speichert.
Symptom im Log: `Failed to restore cache entry. Exiting as fail-on-cache-miss
is set. Input key: Linux-apt-cache-v4` — also kein Code-Fehler, sondern genau
der Eviction-Fall.

**Regel:** Bevor eine rote CI-Lane angefasst wird, den `ci-platform`-Skill
laden. Die Kosten des Ladens sind Sekunden; die Kosten des Fehlversuchs sind
ein Run-Turn plus eine Korrekturmeldung ans Flagschiff. Nicht "das Nächstliegende
ausprobieren und dann nachschlagen" — die Skills sind genau fuer diesen Moment
geschrieben. Dasselbe gilt fuer `backport-*`, `pr-repair` und `starfleet-github`.
