Subject: "starfleet: task file format nachschärfen"
Category: starfleet
Kind: "task"
Status: "done"
From: "McKinley"
Date: "2026-09-11T15:23:50Z"
Doc-Ref: "—"

Header-Namen fixen:

* erstellungsdatum -> "Date:"
* ersteller: -> "From:"
* Title -> "Subject:"

leere / unbenutzte Header müssen nicht im file stehen (fehlend = leer/default)
Slug: header ist nicht mehr benötigt - ergibt sich ja bereits aus dem filename

- 2026-09-17T14:50:00Z Scotty: **ERLEDIGT** — Topic-Format auf neue Header migriert (Date:, From:, Subject: statt Created:, Created-By:, Title:). Leere Header entfernt. Slug-Header entfällt (aus Filename ableitbar). Dieses Topic selbst demonstriert das neue Format.
