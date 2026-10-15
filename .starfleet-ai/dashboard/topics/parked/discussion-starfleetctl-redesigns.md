Title: "Diskussion: starfleetctl-Umbauten (message-keys, web-selection, reports-format) — nach dem Release"
Category: parked
Kind: task
Status: "open"
Created-By: "Enterprise"
Created: "2026-10-15T11:05:15Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: parked/discussion-starfleetctl-redesigns

Parked: Sammlung der Umbauten/Design-Entscheidungen, die NICHT in den Release-Scope gehoerten. Ausloeser: der .seq-Reset-Vorfall (ID-Inversion) + Praetor-Fragen waehrend der Bug-Runde.

## 1. Message-Keys: Sequenz vs. random vs. zeit-sortierbar
Ist-Zustand: IDs `mNNNN` aus `MsgDir/.seq`. Robust gemacht (nextID monoton = max(.seq, hoechste vorhandene)+1; Web-Selektion nach mtime) — aber zwei Restpunkte:
- `.seq` ist eine EINZELNE, ephemere Dotfile unter `var/comms/` → kann verloren/ersetzt werden. Belegt: Zaehler fiel von ~m4513 auf m0001 (neue IDs < alte); m0001 existierte an zwei Daten.
- „neueste N" braucht seither Zeit → `stat()` pro Nachrichtendatei. Gemessen: stat 4550 Dateien = 19,4 ms, readdir allein 5,3 ms (Mehrkosten ~14 ms/Aufruf).

Optionen:
- (a) ZEIT-SORTIERBARER Key (ULID/KSUID-Stil): `<zero-padded Zeit><kurz random>`. Kein Zaehler (keine Reset/Kollisionsklasse), Sortierung = Dateiname (kein stat, kein Cache). Empfehlung.
- (b) Pure random + Sortierung nach Zeit: braucht stat() (~19 ms) oder einen Cache (map[id]->mtime, Invalidierung ueber Verzeichnis-mtime/Anzahl) — Cache nur in langlebigen Prozessen (web/timer); CLI (eigener Prozess je Aufruf) kann nicht cachen.
- (c) Sequenz behalten (Status quo nach den Fixes) — am wenigsten invasiv.
Aufwand (a): betrifft `parseIDNum`, `mfile(n)`, Attachment-Namen (`id__…`), `ReplyTo`-Refs, `comms get`, Web-Sortierung; Alt-`mNNNN` muessen koexistieren (Comparator fuer beide Formen). Kein Release-Scope.
Empfehlung: (a) als eigener, bewusster Umbau nach LaForges Rueckkehr.

## 2. Web-Selektion
Nach Fix A (conversationFiles sortiert nach mtime) korrekt fuer beide Key-Schemata. Bei (a) wieder guenstiger (Dateiname-Sort). Bis dahin werden die ~14 ms stat/Aufruf akzeptiert.

## 3. Reports-Format
- ENTSCHIEDEN (Praetor 2026-10-15): Format bleibt RFC822; NUR der Dateisuffix `.json` wird korrigiert (kein JSON-Rueckbau).
- OFFEN: Suffix-Wahl (`.eml` vs `.rfc822`) + Migration der 5 Altdateien.
- OFFEN: expliziter Git-commit/push-Pfad in `internal/reports` (analog `dashboard topic commit`), damit Agent-Disziplin nicht Traeger der Git-Persistenz ist. Vorschlag von Defiant, nicht gemessen.
- Doku-/Kommentar-Korrekturen dazu sind bereits umgesetzt (Commit 75cb494).

## 4. seen/-Retention (optional)
`comms prune` raeumt verbrauchte Direktiven jetzt tatsaechlich (Fix E). Auto-Pruning bewusst NICHT gebaut (Praetor). `BusTTL` = 900 s steuert die „stale"-Grenze — ggf. separat ueberdenken.

## Refs
Bugs (gefixt): bug-comms-ack-nicht-idempotent, bug-web-recent-msgs-per-id-nach-reset.
Meldungen: Defiant m4514/m4520, Praetor-Entscheidung via Defiant m4522/m4523.
