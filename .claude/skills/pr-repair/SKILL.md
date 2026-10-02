---
name: pr-repair
description: Repair an open (unmerged) master PR — typically a failing CI build or test. Use when asked to fix a PR's CI, diagnose why a PR's checks are red, or amend an open PR. Gets the real failure from job logs, fixes it in an isolated clone, verifies locally, and amends + force-pushes.
---

# Repair an open master PR (failing CI, etc.)

Amend an existing, **unmerged** master PR (distinct from backporting a merged one). Work in a
dedicated agent clone — never the user's hand-edited `sources/xlibre/xserver` tree. Run commands
from the workspace root (`/home/nekrad/src/xorg/mpbt-workspace`).

Full reference: **`reference.md`** in this skill's directory (full detail, moved out of AGENTS.md). This skill is the actionable checklist.

## 1. Get the REAL failure first — don't reason blind

```bash
.starfleet-ai/bin/starfleetctl github pr job-logs <pr#>            # all failing jobs + failure summary
.starfleet-ai/bin/starfleetctl github pr job-logs --job <id>       # one specific job
.starfleet-ai/bin/starfleetctl github pr job-logs <pr#> --all      # every job
```

### `job-logs` kann kaputt sein — am Befehl vorbei

Am 2026-10-02 gab `job-logs` für **alle** Jobs `API error: exit status 1`. Der REST-Weg
funktioniert und ist derselbe, den das Werkzeug nehmen sollte:

```bash
gh api repos/<owner>/<repo>/actions/jobs/<job-id>/logs > <datei>
gh api repos/<owner>/<repo>/actions/runs/<run-id>/jobs?per_page=100 \
  -q '.jobs[] | select(.conclusion=="failure") | .id'
```

`gh run view --log` liefert auf manchen Repos nichts — deshalb der REST-Endpunkt.

### „Fehlt das Feld" heißt nicht „fehlt der Inhalt"

Zweimal am selben Tag, mit demselben Ergebnis: Das Werkzeug meldete eine
**Abwesenheit**, und die war **falsch**.

| Werkzeug meldete | Tatsächlich |
|---|---|
| `gh pr view --json baseRefOid` → leer | Feld existiert dort nicht |
| `job-logs` → `API error` | Logs existieren, der Weg ist kaputt |

**Gegenprobe vor jeder Schlussfolgerung aus „nicht gefunden":**

```bash
gh api repos/<o>/<r>/git/ref/heads/<branch> -q '.object.sha'     # Branch-Tip
gh api repos/<o>/<r>/contents/<pfad>?ref=<ref> -q '.size'        # existiert die Datei
```

Und die Umkehrung, die genauso teuer war: **ein Filter, der etwas findet und trotzdem
scheitert, redet auch nicht.** Ein leeres `body_html` bedeutet nicht, dass es die
Funktion nicht gibt — es bedeutet, dass dieser API-Weg sie nicht liefert. Was *nicht*
beantwortbar war, habe ich als „nicht vorhanden" gemeldet und darauf eine Regel
geschrieben.

### Wenn ein Deploy „nichts tut": Build und Deploy getrennt prüfen

Am 2026-10-02 war ein deploytes Binary **kein Executable**, sondern ein **Go-Paketarchiv**
(148 KB, `!<arch>`, `__.PKGDEF`) — und wurde vom Shell als Skript ausgeführt, mit
`Syntaxfehler beim unerwarteten Symbol »newline«`. Die gesamte Flotten-Koordination
war damit ausgefallen.

**Erst das Source-Artefakt prüfen, nicht nur das deployte:**

```bash
file <source-baum>/<tool>          # ist es ueberhaupt ein ELF?
ls -la <source-baum>/<tool>        # Groesse mit dem deployten vergleichen
```

War hier beides gleich kaputt → **der Build lief schief, nicht der Deploy**. Ein
`go build -o <name>` gegen ein **Nicht-main-Paket** legt genau so ein Archiv an. Ein
funktionierendes Binary war **Faktor ~100 größer** (149 KB → 14,7 MB).

**Und die Reihenfolge der Prüfung, weil ich sie zweimal verkehrt hatte:**
1. Was **meldet** das Werkzeug? (der Befund)
2. Was ist das **Artefakt**, aus dem es gebaut wurde? (`file`, Größe)
3. Was ist das **laufende** Binary? (`file`, Verhalten, nicht der Source-Diff)

Eine Aussage über die **Wirkung** braucht Schritt 3. Ein Source-Diff sagt, was
**beabsichtigt** war — nicht, was **läuft**. Ein Test gegen das laufende Binary kostet
eine Sekunde; der Source-Diff hat hier vier Fehlversuche gekostet.

(`gh run view --log` returns nothing on this repo; the script wraps the REST
`actions/jobs/<id>/logs` endpoint. Per-check annotations only say "exit code 1" — not the cause.)

Read the summary, then identify the failure class:

- **Build/link:** first `FAILED:` / `: error:` / `undefined reference` / `ninja: build stopped`.
- **Configure (meson):** an interpreter error, e.g.
  `Xext/dpms/meson.build:6:3: ERROR: Unknown variable "build_dpms".`
- **Test phase (NOT a build error!):** a `xserver-build-*` job runs `meson test` (XTS) *after* a
  successful build, so there is **no** `FAILED:`/compile-`error:` line. Grep the **tail** for
  `Summary of Failures`, `Fail:`, and `Caught signal` / `Segmentation fault`. A server crash
  during XTS is a real regression, not flakiness.

## 2. Check out the PR branch in an isolated clone

```bash
.starfleet-ai/bin/starfleetctl github pr checkout <pr#>            # -> _WORK_/xserver-master/agent/repair/xserver
```

Prints the clone dir; the PR's head branch is checked out and ready to edit.

## 3. Fix it, then VERIFY LOCALLY before pushing

Even a meson-only change warrants a real build. From a throwaway build dir:

```bash
meson setup <builddir> <clone>                       # success = build.ninja generated
ninja -C <builddir> hw/vfb/Xvfb hw/xnest/Xnest       # links full libxserver list
```

This catches both configure errors and latent compile/duplicate-symbol problems.

**Runtime crash (XTS segfault):** the full XTS suite won't run locally (needs `XTEST_DIR`/piglit;
`xvfb-piglit.sh` exits 77 = skip). But dix-level crashes are drivable directly: build
`hw/vfb/Xvfb`, start it on a spare display (`Xvfb :91 &`), run a small libX11 client that issues
the offending request, then assert the server is still up (`kill -0 $xvfb_pid`). Toggle the fix
in/out (rebuild each way) to prove cause *and* sufficiency.

## 4. Amend + push

```bash
.starfleet-ai/bin/starfleetctl github pr amend-push <clone-dir> [files...]
```

Folds edits into the PR's single commit (`--amend --no-edit`, preserves message +
`Signed-off-by`) and `--force-with-lease` back to the branch. CI re-triggers on the new head.

(If a separate fixup commit is preferable to amending, commit + push by hand from the clone.)
