---
slug: local/starfleetctl-web-frontend-testing
title: "Testing the starfleetctl web frontend (internal/web/index.html) JS with node"
order: 20
---

# Testing the starfleetctl web frontend (internal/web/index.html) JS with node

The web UI is a single embedded `internal/web/index.html` with one big `<script>`
block (go:embed). There is no JS test infra in the repo. To verify new UI JS
without a browser:

1. Extract the script block:
   ```python
   import re
   html = open('internal/web/index.html').read()
   open('/tmp/opencode/web-script.js','w').write(re.findall(r'<script>(.*?)</script>', html, re.S)[0])
   ```
2. `node --check web-script.js` for syntax.
3. For functional tests, run `eval(code)` in a node harness with a minimal DOM
   shim. Gotchas:
   - the script defines its own `const api` (fetch wrapper) — stub **`fetch`**,
     not `api`, and mimic `r.json()`.
   - top-level `refresh()` at script end touches `document.querySelector`,
     `history.replaceState` etc. and will throw with a minimal shim — harmless,
     all functions are defined before it. Stub `window`/`localStorage`/`navigator`
     /`history`/`setInterval` anyway.
   - element stub: `{ innerHTML:'', value:'' }` per id; `getElementById` returns
     persistent per-id objects so `innerHTML`/`value` round-trip.
   - harness runs in `/tmp/opencode/` (the pre-approved temp dir).

The tasks page filter/sort (status/ship/category) was verified this way (commit
2c50db3): rendering, all filters, both sort directions, dropdown population,
and the stale-filter guard.
