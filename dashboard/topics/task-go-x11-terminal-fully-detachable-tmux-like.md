---
slug: task-go-x11-terminal-fully-detachable-tmux-like
title: "go-x11 terminal: fully detachable (tmux-like)"
category: active
kind: task
status: erledigt
created-by: Yamato
created: 2026-07-15T15:03:23Z
assigned-to: Yamato
doc_ref: "—"
---

Das go-x11 terminal soll fully detachable sein: - Kann detached gestartet werden (ähnlich wie tmux new-session -d) - Später beliebig attach/detached werden (ähnlich wie tmux attach/detach) - Unterschied zu tmux: Alles in einem Prozess, der die X11 connection selbst öffnet - Kein externer server nötig, der die sessions verwaltet - Session-Überleben wenn X11 connection abbricht und später wieder hergestellt wird

**Status: Bereits implementiert** in `demo/terminal-aa-detach/` (go-x11proto Repo).

Die Implementierung unterstützt:
- `--detached` Flag zum gestarteten im detached mode
- Control-Pipe via `TERM_CTRL_FD` Environment-Variable
- Signal-basierte Steuerung (SIGUSR1=detach, SIGUSR2=attach)
- Shell läuft weiter im PTY wenn detached
- Reattach an verschiedene X11 Displays möglich
- Alles in einem einzelnen Prozess (kein externer Server nötig)
