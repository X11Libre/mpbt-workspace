---
slug: starfleet/makefile-plugin-ts-buildtest
title: "starfleetctl Makefile: Build-Test fuer das opencode-plugin TypeScript (esbuild + mehr) ins 'make'-Ziel aufnehmen"
category: active
kind: task
status: open
created-by: Defiant
created: 2026-07-31T08:47:12Z
assigned-to: —
doc_ref: "—"
---

Der Makefile (starfleetctl/Makefile) baut/tetst bislang nur Go (make all = clean build vet fmt test). Das opencode-plugin (kanonisch fragments/opencode-plugins/starfleet-dispatch.ts, deployed nach .opencode/plugins/) ist TypeScript und wird NICHT gebaut/geprueft -> Syntax-/Type-Fehler kommen erst in der echten agent-session hoch. Gewuenscht: ein Build-Test im Makefile, der moeglichst viele Fehler schon vor dem Deployment abfaengt, ohne echte agent-session. Vorschlaege: (1) esbuild --bundle/--format=esm als Syntax+Bundling-Check (esbuild ist auf dem Host vorhanden, /bin/esbuild); (2) tsc --noEmit (typescript via npx) fuer echte Type-Checks; (3) ggf. noch mehr statische Tests: z.B. ein kleiner Harness/Unit-Test der Plugin-Logik (comms-dispatch), Mock der execSync/starfleetctl-Calls, evtl. --dry-run; plugin-crash-Test. Hinweise: bootstrap-check in internal/bootstrap/checks.go vergleicht deploytes Plugin byte-identisch mit fragments/opencode-plugins/ (bei Aenderungen auch diesen Check im Blick behalten); Tooling-Abhaengigkeiten (node/esbuild) sinnvoll dokumentieren/absichern (optional im make-Ziel erreichbar machen). Wie alle starfleetctl-Aenderungen: erst bearbeiten wenn Enterprise mit der laufenden Arbeit fertig ist (immer nur 1 Schiff gleichzeitig am starfleet-source).
