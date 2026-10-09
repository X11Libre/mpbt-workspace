Title: "BUG plugin: poll() markiert inbox-Nachrichten nicht als seen -> unseen-Backlog waechst unbegrenzt"
Category: active
Kind: task
Status: "open"
Created-By: "Enterprise"
Created: "2026-10-09T09:13:18Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: task-bug-plugin-poll-markiert-inbox-nachrichten-nicht-als-seen-unseen-backlog-waechst-unbegrenzt

starfleet-dispatch.ts (v2.5.4): poll() (Z.687-696) fuegt jede Inbox-ID zu 'submitted' hinzu und injiziert via promptAsync, ruft aber NIE bus({cmd:'seen_mark'}). system.transform (Z.766-769) macht es korrekt, ueberspringt aber alles, was schon in 'submitted' ist. Da poll() alle paar Sekunden laeuft und Turns seltener, greift poll() die meisten Nachrichten zuerst -> sie bleiben fuer immer in unseen/ und der Zaehler waechst (Enterprise: unseen=822, seen=401).

GEGENPROBE: manueller bus({cmd:'seen_mark',id:'m1449'}) verschiebt die Datei sofort unseen->seen. CLI ist also ok, nur der Plugin-Pfad fehlt.

NEBENRISIKO: poll() injiziert mit path:{id: currentSessionID}; ist die nicht aufgeloest (Z.685 loggt nur, bricht nicht ab), laeuft die Injection ins Leere (.catch ignore) und die Message ist trotzdem 'submitted' -> stumm verloren UND dauerhaft unseen.

FIX: in poll() nach dem Handling bus({cmd:'seen_mark', id: msg.id}) aufrufen (Spiegel von system.transform); submitted erst nach erfolgreichem Handling hinzufuegen; bei leerem currentSessionID die Injection ueberspringen (nicht still verlieren). PLUGIN_VERSION bumpen.

IMPACT: flottenweit — jedes Schiff mit diesem Plugin hat denselben Backlog.

Quelle (tool-owned): _WORK_/starfleetctl/sources/starfleetctl/fragments/opencode-plugins/starfleet-dispatch.ts. Nach Fix: make all, commit+push, ./starfleet-bootstrap, PLUGIN_VERSION-Verify.
