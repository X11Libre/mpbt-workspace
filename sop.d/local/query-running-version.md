---
slug: local/query-running-version
title: "Laufende Version abfragen (git-Commit der laufenden Daemons)"
order: 210
---

## Laufende Version abfragen (welcher git-Commit läuft gerade?)

Für eine **laufende** Daemon-Instanz lässt sich der exakte Commit aus dem
**laufenden Binary** lesen — auch wenn die Datei auf Platte inzwischen ersetzt
wurde (`/proc/<pid>/exe` zeigt auf den ursprünglichen Inode, nicht auf den
aktuellen Dateiinhalt des Pfads):

```sh
go version -m /proc/<pid>/exe | grep vcs.revision
```

Das funktioniert für jeden laufenden Prozess (model-proxy, web, timer worker),
ohne Mitarbeit des Prozesses. Ein `starfleetctl version`-Subcommand wäre dafür
**nicht** geeignet: es würde nur das *aktuell deployte* Binary zeigen, nicht die
noch laufenden (alten) Daemons.

### Falle im Build (buildvcs + Worktree)

Go's `buildvcs` erkennt nur ein `.git`-**Verzeichnis**, **nicht** die
`.git`-**Datei** eines verlinkten Worktrees. Wird in einem Worktree gebaut, der
unter einem anderen git-Repo liegt (unser Fall: `_WORK_/worktrees/starfleetctl/…`
unter `mpbt-workspace`), läuft `buildvcs` bis zum **äußeren** Repo hoch und
stempelt den **falschen** Commit ein (den mpbt-workspace-Commit statt des
starfleetctl-Commits).

**Fix** (seit `599a3eb`, in der Makefile): `GIT_DIR=$(git rev-parse
--absolute-git-dir)` beim `go build` mitgeben. Damit stempelt der Build in Clone
**und** Worktree den richtigen Commit.

**Hinweis:** `vcs.modified=true` erscheint bei In-Tree-Worktree-Builds, weil die
gebaute Binärdatei selbst untracked ist — `vcs.revision` ist trotzdem korrekt.
