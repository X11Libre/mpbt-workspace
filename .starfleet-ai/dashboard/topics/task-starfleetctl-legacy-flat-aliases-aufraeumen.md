---
slug: task-starfleetctl-legacy-flat-aliases-aufraeumen
title: "starfleetctl: legacy flache PR/CI/Backport-Aliase entfernen"
category: active
kind: task
status: open
created-by: Enterprise
created: 2026-07-15T16:39:47Z
assigned-to: —
doc_ref: "—"
---

Nach der Gruppierung der GitHub-Commands unter 'github ...' bleiben die flachen Aliase (pr-view, pr-ci, pr-claim, backport-applies, ci-cancel-stale, xx-make-pr, show-pr-conflict, mk-agent-clone, ...) vorerst als Delegates in cmd/starfleetctl/main.go erhalten. Sobald alle Skills (.claude/skills/*) und settings.json-Pfade auf die 'github ...'-Form umgestellt sind, die flachen Cases entfernen.
