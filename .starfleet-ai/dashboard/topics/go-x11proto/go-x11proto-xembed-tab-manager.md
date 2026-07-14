---
title: "go-x11proto: XEmbed tab manager (tabbed-style)"
category: active
kind: task
status: open
created-by: Enterprise
created: 2026-07-28T15:28:30Z
assigned-to: —
doc_ref: "—"
---

Implement generic XEmbed-based tab manager (suckless tabbed analogue). Requires adding XEmbed protocol support to go-x11proto first: _XEMBED_INFO/_XEMBED client messages, reparenting. Each tab = independent terminal process reparented into container window. tk/term itself never multiplexes multiple Terms.
