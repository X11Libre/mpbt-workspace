---
slug: task-starfleetctl-github-commands-in-subcommands-untergliedern
title: "starfleetctl: GitHub-Commands in Subcommands untergliedern"
category: active
kind: "task"
status: "done"
assigned-to: "—"
created-by: "Yamato"
created: "2026-07-15T14:41:57Z"
doc_ref: "—"
---

Die starfleetctl GitHub-Befehle (pr-view, pr-ci, pr-comment, pr-label, etc.) sollten in einen 'github' Subcommand untergliedert werden, z.B. 'starfleetctl github pr view', 'starfleetctl github pr comment', etc. Struktur: starfleetctl github pr view|ci|comment|label|... + starfleetctl github issue ... + starfleetctl github release ...
