Title: "plugin_version in der Schiffs-Detailansicht anzeigen"
Category: active
Kind: task
Status: "assigned"
Created-By: "Voyager"
Created: "2026-09-30T10:54:45Z"
Assigned-To: "Laforge"
Doc-Ref: "—"
Slug: starfleet/task-plugin-version-in-schiffs-detailansicht

Das opencode-Plugin sendet plugin_version im health-Bus (fragments/opencode-plugins/starfleet-dispatch.ts L145 und L539: bus({cmd:'health', reset/touch, ..., plugin_version: PLUGIN_VERSION})), aber der Tracker uebernimmt das Feld nirgends — grep nach plugin_version/PluginVersion ueber internal/*/ liefert null Treffer ausserhalb des Plugins.

SCOPE (von McKinley praezisiert): plugin_version muss NICHT in der Schiffsliste stehen, sondern nur in der Detailansicht. Der Tracker muss das Feld also weiterfuehren; die Anzeige gehoert in die Detail-/Vollansicht eines Schiffs, nicht in die tabellarische Liste.

Warum das noetig ist: /api/ships fuehrt bei keinem Schiff ein plugin_version-Feld (alle 7 nur name, state, pid, handle, note, model, server, task). In 17936 Bus-Nachrichten existiert genau EIN Treffer fuer das Wort plugin_version — eine menschliche Meldung, kein Heartbeat. Damit ist der Rollout einer Plugin-Version nicht ablesbar; man ist auf Prozessstartzeiten angewiesen (ps -o lstart= -p <pid> gegen stat -c %y .opencode/plugins/<datei>).

Messbarer Ist-Zustand am 2026-09-30: 1 von 7 Schiffen laeuft auf v2.5.4 (Voyager, pid 10866, Prozessstart 12:43:54 nach Dateizeitstempel 12:18:24). Defiant (pid 2415, Start 29.09. 15:57), Enterprise (pid 23905, Start 29.09. 20:11), Interpid (pid 5615, Start 26.09. 10:57) laufen noch auf dem alten Stand. Ohne Versionsangabe sieht man das nicht — ein Restart pro Schiff ist noetig, das ist kein Fehler.

Additiv, kein Breaking: bestehende Clients, die kein plugin_version erwarten, muessen weiterlaufen. In der Liste bitte KEINE neue Spalte.

Verifikation: nach dem Aendern muss (a) ein laufendes Schiff mit frischem Heartbeat ein plugin_version liefern, (b) es in der Detailansicht sichtbar sein, (c) /api/ships es unveraendert um die Listenspalte belassen — und (d) sollten mehrere Schiffe unterschiedliche Versionen zeigen, muss man sie auseinander halten koennen, sonst ist die Anzeige wertlos.
