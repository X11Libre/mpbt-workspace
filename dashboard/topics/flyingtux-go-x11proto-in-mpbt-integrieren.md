---
slug: flyingtux-go-x11proto-in-mpbt-integrieren
title: "**FlyingTux + go-x11proto in mpbt integrieren** (in die Fleet holen, statt Außenposten)"
category: parked
noted_by: "praetor, 2026-07-02"
since: "2026-07-02"
migrated_from: 8cf8692b9f0057ffe44e793b35bcf7329da83d3f
---

Ziel: die beiden Schwester-Projekte **vollständig in die mpbt-Fleet** aufnehmen, statt sie nur als externe Repos „von außen" mitzubauen — damit die Arbeit daran denselben orchestrierten Build/CI/Tooling-Rahmen bekommt wie die xserver-Release-Linien. **FlyingTux** (`/home/nekrad/src/flyingtux`, eigenes Repo — siehe Aktive-Themen-Zeile) und **go-x11proto** (`/home/nekrad/src/xorg/go-x11`, `X11Libre/go-x11proto` — siehe dessen Zeile) je **ggf. als komplett eigene mpbt-Solution** (analog `cf/<release>/solutions/…`), mit eigenen packages/config, statt Ad-hoc-Builds. **✅ go-x11proto DONE (2026-07-02):** eigene Solution `cf/go-x11proto/` (config + `solutions/default.yaml` + `packages/xlibre/go-x11proto.yaml`) + Wrapper `run-{fetch,build,opencode}.go-x11proto`, **separat vom xserver-Build**. Clone **verschoben** (nicht neu geklont — erhält 6 Stashes + lokale Branches) nach `_WORK_/go-x11proto/sources/xlibre/go-x11proto`; `run-fetch` (fetch + `make-pr.*`-config, non-destruktiv) und `run-build` (`buildsystem: exec` → `make` → `go build`) grün getestet. Doku: AGENTS.md „go-x11proto and FlyingTux are their own mpbt solutions". **✅ FlyingTux DONE

(2026-07-02):** eigene Solution `cf/flyingtux/` (config + `solutions/default.yaml` +
`packages/xlibre/flyingtux.yaml`) + Wrapper `run-{fetch,build,opencode}.flyingtux`, **separat vom
xserver-Build**. **Branch-Entscheidung:** getrackt wird `master` (die aktuell produktive
Python-Codebasis), **nicht** der fertige, aber noch unmerged Go-Rewrite auf
`wip/golang-rewrite`/`/home/nekrad/src/flyingtux-go` (analog zur go-x11proto-Entscheidung, den
tatsächlichen Produktiv-Branch zu tracken) — Merge des Rewrites bleibt eine separate
Praetor-Entscheidung, hier nicht angefasst. **Worktree-Falle gefunden+gelöst:**
`/home/nekrad/src/flyingtux` (`master`) und `/home/nekrad/src/flyingtux-go`
(`wip/golang-rewrite`) waren **ein Repo als zwei verlinkte git-worktrees**, kein zweites
unabhängiges Klon — ein simples `mv` des Hauptworktrees hätte den Rücklink von `flyingtux-go`
gebrochen. Gelöst mit `mv` + `git worktree repair` aus dem verschobenen Verzeichnis heraus;
`flyingtux-go` danach verifiziert unangetastet (gleicher Commit, sauberer Baum, alle Branches
intakt) nach `_WORK_/flyingtux/sources/xlibre/flyingtux` verschoben (nicht neu geklont — kein
Stash vorhanden, sauberer Baum vor dem Move). Kein Build-Schritt nötig (reines Python, kein
Compile-Artefakt) — `buildsystem: exec` ganz ohne `commands:`-Block ist laut mpbt-Quellcode
(`core/workflow/build/exec.go`) ein dokumentierter No-op pro Stage; `run-build` schreibt nur einen
Source-Tarball. Ein `python -m compileall`-Smoketest wurde erwogen und verworfen: der `master`-Baum
enthält alte Python-2-Syntax (`chmod(scriptname, 0755)` in
`src/imagebuilder/flyingtux/app/deploy.py`), die einen Compile-Smoketest von Anfang an rot machen
würde — nicht Teil dieser Migration, siehe Parkplatz. Kein `make-pr.*`-Config (persönliches
`metux/flyingtux`-Repo, nicht `X11Libre` — die xserver-PR-Konventionen greifen hier nicht).
`run-fetch`/`run-build` beide grün getestet. |
