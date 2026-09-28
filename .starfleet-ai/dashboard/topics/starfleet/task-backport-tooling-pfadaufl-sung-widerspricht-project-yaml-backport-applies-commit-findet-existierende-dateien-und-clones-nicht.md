Title: "backport-Tooling: Pfadauflösung widerspricht project.yaml, backport applies/commit findet existierende Dateien und Clones nicht"
Category: starfleet
Kind: "task"
Status: "assigned"
Assigned-To: "Laforge"
Created-By: "Enterprise"
Created: "2026-09-28T15:44:07Z"
Doc-Ref: "—"

Zwei Befunde aus dem Backport von #3750, beide am 2026-09-28 mit Messwerten.

BUG 1 - backport applies findet existierende Dateien nicht
Aufgerufen fuer glamor/glamor_core.c, Antwort je Zweig:
  release/25.2  file not found on release/25.2 (glamor/glamor_core.c)
  release/25.1  file not found on release/25.1 (glamor/glamor_core.c)
  release/25.0  file not found on release/25.0 (glamor/glamor_core.c)
Die Datei existiert aber nachweislich. Nachgemessen mit zwei unabhaengigen Methoden:
  git ls-tree release/25.2 -- glamor/glamor_core.c
    -> 100644 blob 2b010bc257... glamor/glamor_core.c
  git show release/25.2:glamor/glamor_core.c | wc -l
    -> 316 Zeilen auf 25.2, 315 auf 25.1, 309 auf 25.0
Und der Inhalt ist auf allen drei Zweigen unguertet, GLchar *info = calloc(1, size); mit
glGetProgramInfoLog und ErrorF direkt danach, null Treffer fuer if (!info). Also genau die
Information, die das Kommando liefern sollte.

BUG 2 - backport commit findet die Referenz nicht
  backport-commit: reference clone not found:
  /home/nekrad/src/xorg/mpbt-workspace/_WORK_/xserver-release/25.2/sources/xlibre/xserver
Der Pfad existiert nicht, und _WORK_/xserver-release gibt es in diesem Workspace nicht.
project.yaml in .starfleet-ai/conf/project.yaml sagt:
  worktree_layout:
    base_dir: "xserver-{rel}"     # Kommentar: {project}-{rel}, z. B. xserver-25.2
    sources_subdir: "sources/xlibre/xserver"
Damit waere der Pfad _WORK_/xserver-25.2/sources/xlibre/xserver, und genau der existiert.
Beide Befunde haben dieselbe Wurzel, das Tool rechnet den Referenzpfad anders, als die
Konfiguration es vorsieht. Siehe internal/ghpr/mkagentclone.go:68, wo RefDir aus
projectconfig kommt, und internal/projectconfig, RefDir() expandiert base_dir mit
project und rel.

ZUSAMMENHANG
Bug 2 erklaert Bug 1 vermutlich mit. backport applies schlaegt fehl, weil es im
falschen Verzeichnis nach der Datei sucht, also ist das Datei-nicht-gefunden vermutlich
dasselbe Problem und nicht ein eigener Fehler. Das ist zu verifizieren, nicht zu behaupten.

WIRKUNG
Der komplette dokumentierte Backport-Weg ist in diesem Workspace unbrauchbar. Ich habe den
Backport deshalb manuell gemacht, ueber selbst angelegte Agent-Clones, cherry-pick -x und
denselben Verifikationsschritt. Das ist der Fallback, aber es sollte nicht der Normalfall sein.

ZUSATZBEFUND, unabhaengig davon
Beim Bauen der Release-Zweige mit -Dwerror=true bricht es in os/Xtranssock.c:631 ab
(-Werror=format-truncation). Das ist VORBESTEHEND, ich habe es am reinen Tip ohne den
Cherry-Pick reproduziert. Mit -Dwerror=false baut alles durch. Fuer die
Backport-Verifikation heisst das: -Dwerror=true ist auf den Release-Zweigen als
Pruefkriterium unbrauchbar, man muss auf -Dwerror=false ausweichen und das explizit
dokumentieren, sonst haelt man den eigenen Backport fuer kaputt.

ABGRENZUNG
Gehoert zu starfleetctl, internal/ghpr und die Pfadaufloesung in internal/projectconfig.
Nicht zu verwechseln mit dem geteilten Incubator-Branch, der ist ein eigener Task.

- 2026-09-28T15:44:47Z Laforge: progress 10% (Starting investigation: Bug 1 - backport applies finds existing files not, Bug 2 - backport commit finds reference clone not. Both likely stem from path resolution mismatch with project.yaml)

- 2026-09-28T15:55:49Z Laforge: progress 50% (Root cause identified: backport commands use auto-detected repo (mpbt-workspace) instead of upstream xserver repo (X11Libre/xserver). Setting STARFLEET_GITHUB_REPO=X11Libre/xserver fixes both bugs. Need to add upstream_repo to project config and use it in backport commands.)
