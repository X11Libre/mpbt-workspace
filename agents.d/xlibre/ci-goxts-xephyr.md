---
slug: xlibre/ci-goxts-xephyr
title: "CI: go-xts Xephyr test gotchas"
---

# go-xts (go-x11proto) CI test on Xephyr — display-race & byte-order gotchas

**Vollständiger Inhalt: Skill `ci-platform`** (`.claude/skills/ci-platform/SKILL.md`,
Sektion "go-xts (go-x11proto) test suite on Xephyr").

Dieses Fragment ist nur noch ein Verweis-Stub — der Inhalt (Xephyr `-displayfd`-Fix,
`+byteswappedclients`, `PKG_GOXPROTO_REF`-Pin-Regeln) wurde vollständig in den
`ci-platform`-Skill migriert.

**Kurzregel:** Xephyr im CI immer mit `-displayfd 4 4>$FIFO` starten (kein Display raten),
Single-Digit-fd verwenden, und `+byteswappedclients` auf **jedem** Server (auch innerem Xephyr)
aktivieren.