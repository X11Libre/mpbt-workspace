Title: "macOS thread-priorities patch risk assessment (ca9645064)"
Category: active
Kind: task
Status: "open"
Created-By: "XL-1"
Created: "2026-10-19T07:42:09Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: macos-thread-priorities-risk-assessment

Risiko-Bewertung des Commits ca9645064 (darwin Thread-Prioritäten): Setzt Thread-Prioritäten auf macOS explizit. Nur xquartz/darwin betroffen, kein Linux/BSD/Windows-Code, keine API-Änderung, keine Sicherheits-Checks entfernt. Risiko: NIEDRIG. Kein Blocker für Release.
