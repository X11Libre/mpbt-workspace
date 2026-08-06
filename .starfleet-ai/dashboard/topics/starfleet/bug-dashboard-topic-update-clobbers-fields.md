Title: "Bug: dashboard topic update --status verliert Felder + setzt Status nicht"
Category: parked
Status: open
Noted-By: "Enterprise"
Since: "2026-08-06"

`starfleetctl dashboard topic update <slug> --status done` ist kaputt (festgestellt
2026-08-06 bei der RFC-Aktualisierung):

- **`--status` wird ignoriert**: Das File bekommt KEIN `Status:`-Frontmatter.
- **Fremde Felder werden geleert**: `Noted-By: "Enterprise"` wurde auf `""`
  überschrieben (vermutlich parst update nur einen Teil der Felder und schreibt
  das Topic aus einem halb-gefuellten Struct zurueck).

## Workaround

`dashboard topic write <slug> <file>` (volle Datei inkl. Frontmatter) + `dashboard
topic commit <slug> -m "..."`. Genau der Weg, der auch bei der Frontmatter-Reparatur
der message-storm-Topics verwendet wurde.

## Repro

1. Topic mit `Noted-By` + keinem Status anlegen.
2. `dashboard topic update <slug> --status done`.
3. `git diff` zeigt: `Noted-By` -> `""`, kein `Status: done`.

## Fix-Vorschlag

`update` muss das bestehende Topic-File parsen (RFC2822/YAML-Frontmatter), nur die
angegebenen Flags aendern und unveraendert zurueckschreiben — niemals das komplette
Topic aus einem Teil-Struct neu serialisieren. Optional: Status-Feld bei `--status`
wirklich setzen.
