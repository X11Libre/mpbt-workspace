---
title: "Backport #3514 (Xnamespace NULL-Deref) auf 25.2/25.1/25.0 — 3 PRs offen, warten auf Merge"
category: active
kind: task
status: open
assigned-to: "—"
tags: "starfleet,xserver,backport,xnamespace"
---

## Auftrag (Praetor, 2026-10-07)

Master-PR #3514 (`Xext/namespace: fix startup allocation crashes and runtime virtual
root memory leak`, 2 Commits, gemergt als `e0160fdb7d` + `999015f6cd`) auf die
Release-Zweige zurückportieren.

## Klassifikation (gemessen)

`git merge-base --is-ancestor <c> xorg/main` → **nein** für beide Commits, also
**eigene** Commits → Workflow `backport-ours`. Vulnerability-Check pro Zweig:
`backport applies Xext/namespace/config.c 'failed allocating namespace'` →
**vulnerable** auf 25.2, 25.1, 25.0 (keine Treffer), master gefixt.

## Ergebnis: ein PR je Zweig

| PR | Ziel |
|---|---|
| GH-3856 | release/25.2 |
| GH-3857 | release/25.1 |
| GH-3858 | release/25.0 |

Übersicht am Original-PR #3514 als Task-Liste gepostt.

## Commit 2 bewusst NICHT mitgenommen (N-A, nicht „fehlend")

`999015f6cd` patcht `XnsDestroyNamespace()` — existiert **nur auf master**
(`git grep -l XnsDestroyNamespace origin/<br> -- 'Xext/namespace/*'` → nur auf
master: config.c, namespace.c, namespace.h). Release-Linien: config.c 210 Zeilen
vs. master 566, **kein Zerstörungspfad**, also kein Leak zu beheben.

## Konfliktloösung (identisch auf allen drei Zweigen)

Cherry-Pick konflikierte in `select_ns()` (Delete/Modify-artig, weil master dort
`XnsLookup()` + Helper hat, die Release-Linien einen manuellen Listen-Walk).
Übernommen: **nur die zwei Checks des Fix** (+7 Zeilen in config.c).
**Nicht** übernommen: die Kontextzeile `xorg_list_init(&newns->auth_tokens);`
(stammt aus `e16cc89236`, nicht auf den Releases, und dort unnötig —
`xorg_list_append()` ruft `__xorg_list_autoinit()` auf, `include/list.h`).

rerere war **global an** (`git config --global rerere.enabled` → true) — jeder
Cherry-Pick lief mit `-c rerere.enabled=false`, wie im Skill gefordert.

## Verifikation (je Zweig)

- `meson setup -Dwerror=true` + `ninja Xext/namespace/libxserver_namespace.a`,
  Base **und** gepatcht: 0 Fehler, identische Warn-/Fehlermenge
- Guard-String im Objekt: `strings …/config.c.o | grep -c 'failed allocating namespace'` → 2
- +166/−0, 7 eingefügte Zeilen in config.c, 0 Löschungen, doc byte-identisch zu `e0160fdb7d`
- 1 Commit über dem jeweiligen Tip, Original-`Signed-off-by` (Mason Green), `(cherry picked from …)` erhalten, kein `[PR #NNNN]`-Marker

## Offen

- [ ] GH-3856, GH-3857, GH-3858 vom Maintainer reviewen + manuell mergen
      (Release-Merges sind manuell; grüne CI + Label autorisieren keinen Merge)
