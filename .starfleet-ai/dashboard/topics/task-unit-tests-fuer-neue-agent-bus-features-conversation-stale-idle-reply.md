---
slug: task-unit-tests-fuer-neue-agent-bus-features-conversation-stale-idle-reply
title: "Unit-Tests fuer neue agent-bus Features (Conversation, stale-idle, --reply)"
category: active
kind: task
status: open
created-by: Enterprise
created: 2026-07-16T12:20:44Z
assigned-to: —
doc_ref: "—"
---

Die neuen Funktionen haben nur manuelle e2e-Checks, keine Go-Unit-Tests: agentbus.Conversation(ship), stale()-idle-Whitelist, --reply-Parsing in parsePostFlags, StatusDetail JSON read/write. Ergaenze Teste in internal/agentbus (analog touch_test.go) mit TestBus-Fixtures.
