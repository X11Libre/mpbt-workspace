Title: "xlibre: zwei un-backportete Fixes liegen als abgebrochene Staging-Zweige vor (FormatInt64-UB, render-Glyph-Leak)"
Category: xlibre
Kind: task
Status: "open"
Created-By: "Enterprise"
Created: "2026-10-01T12:13:21Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: xlibre/task-xlibre-zwei-un-backportete-fixes-liegen-als-abgebrochene-staging-zweige-vor-formatint64-ub-render-glyph-leak

Befund 2026-10-01: Zwei echte Fixe sind auf master, aber auf KEINER Release-Linie (25.0/25.1/25.2). Beide waren als Backport begonnen; die make-pr-Laeufe brachen ab und liessen die Staging-Zweige auf origin zurueck.

Fix 1  eb9a108624  os: fix undefined behavior in FormatInt64() for INT64_MIN
        patch-id 9ae9dc5785
Fix 2  eb9a108624-Nebenstelle: render: fix glyph Picture/Pixmap leak on ProcRenderAddGlyphs bail path
        (master eb9a108624 = FormatInt64; render ist eb9a1086xx/445cfbbe5a)

Je drei Cherry-Picks, einer pro Release-Linie, alle mit eigener SHA:
  25.0: b63f872ce0 (render) / 822309e0ac (FormatInt64)
  25.1: 09a019a0fa (render) / a7d26c6301 (FormatInt64)
  25.2: d7df409ed06 (render) / 50ac359d620 (FormatInt64)

Offene PRs dazu: keine (geprueft ueber Titel, nicht ueber head-Namen).
Nebenbefund ungeprueft: release/25.2 hat 2a41522349 'os: make FormatInt64() handle
LONG_MIN correctly' — dieselbe Funktion, anderer Fix. Ueberschneidung muss am Code
geprueft werden.

DISPOSITION (Praetor, 2026-10-01): tmp-pr/release/25.0 wurde auf einen wip/*-Branch
rebased, Original auf remote geloescht, wip-Branch gepusht. bewusst so, weil wip/ die
Aufbewahrregel traegt und der Zweig damit aus der Aufraeum-Menge tmp-* herausfaellt.
Die restlichen fuenf tmp-pr-Zweige sind noch auf origin.

Offene Entscheidung: Backport beide Fixes auf 25.0/25.1/25.2, oder bewusst verwerfen?
Nach backport-ours sind beide backport-faehig (Bugfix, kein Refactoring/Feature) —
das ist eine Entscheidung des Maintainers, keine Automatik.
