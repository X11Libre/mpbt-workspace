#!/usr/bin/env bash
#
# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright © 2026 Enrico Weigelt, metux IT consult
#
# Full health check for the starfleet web console.
#
# Why this exists: a plain HTTP 200 does NOT prove the frontend works. The
# console is one inline <script> block; a JS syntax error leaves HTML+CSS
# perfectly rendered while nothing is loaded and nothing is clickable. This
# was observed on 2026-10-06/08 (commit 1a23e4b decoded the HTML entities in
# escAttr(), turning a valid JS literal into a parse error). So the check has
# three layers:
#
#   1. transport   - HTTP 200 on / and on the JSON APIs
#   2. source      - the SERVED page parses as JS and carries the known fixes
#   3. behaviour   - a real headless Chromium renders, clicks and switches tabs
#
# Usage: web-frontend-check.sh [base-url]
# Exit:  0 = healthy, 1 = problem found.

set -uo pipefail

BASE="${1:-http://127.0.0.1:8080}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Temp stays inside the workspace (_WORK_/tmp), never outside it.
WSROOT="$(cd "$HERE/.." && pwd)"
if [ -d "$WSROOT/_WORK_/tmp" ]; then TMPBASE="$WSROOT/_WORK_/tmp"; else TMPBASE="${TMPDIR:-$WSROOT/_WORK_}"; fi
mkdir -p "$TMPBASE"
TMP="$(mktemp -d "$TMPBASE/webcheck.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

FAIL=0
ok()  { printf 'PASS  %s%s\n' "$1" "${2:+  ($2)}"; }
bad() { printf 'FAIL  %s%s\n' "$1" "${2:+  ($2)}"; FAIL=1; }

# --- 1. transport ---------------------------------------------------------
for path in / /api/identity /api/board /api/ships; do
    code=$(curl -s -o "$TMP/out" -w '%{http_code}' --max-time 10 "$BASE$path" || echo 000)
    if [ "$code" = 200 ]; then ok "HTTP 200 $path"; else bad "HTTP 200 $path" "got $code"; fi
done

board=$(curl -s --max-time 10 "$BASE/api/board" || echo '[]')
ships=$(printf '%s' "$board" | python3 -c "import json,sys; print(len(json.load(sys.stdin)))" 2>/dev/null || echo 0)
if [ "${ships:-0}" -gt 0 ]; then ok "/api/board liefert Schiffe" "$ships"
else bad "/api/board liefert Schiffe" "0"; fi

# --- 2. source: the SERVED page must parse as JS --------------------------
curl -s --max-time 10 "$BASE/" > "$TMP/index.html" || true

# The known-broken form: a JS string literal destroyed by HTML-entity decoding.
broken=$(grep -c "'''" "$TMP/index.html" || true)
if [ "$broken" = 0 ]; then ok "keine kaputten Hochkommata-Literale im Script"
else bad "keine kaputten Hochkommata-Literale im Script" "$broken gefunden"; fi

if grep -q "function escAttr(s){ return esc(s).replace(/\"/g,'&quot;')" "$TMP/index.html"; then
    ok "escAttr mit korrekten HTML-Entities"
else
    bad "escAttr mit korrekten HTML-Entities"
fi

python3 - "$TMP/index.html" "$TMP/script.js" <<'PY'
import re, sys
html = open(sys.argv[1], encoding='utf-8', errors='replace').read()
blocks = re.findall(r'<script[^>]*>(.*?)</script>', html, re.S)
open(sys.argv[2], 'w', encoding='utf-8').write(blocks[0] if blocks else '')
PY
if node --check "$TMP/script.js" >/dev/null 2>&1; then
    ok "ausgeliefertes Script parst (node --check)"
else
    bad "ausgeliefertes Script parst (node --check)" "$(node --check "$TMP/script.js" 2>&1 | tail -2 | tr '\n' ' ')"
fi

# --- 3. behaviour: render + click in a real browser -----------------------
if command -v node >/dev/null 2>&1 && [ -f "$HERE/web-frontend-browser-check.mjs" ]; then
    if node "$HERE/web-frontend-browser-check.mjs" "$BASE/" 30; then
        ok "Browser-End-to-End (render/click/tab)"
    else
        bad "Browser-End-to-End (render/click/tab)"
    fi
else
    bad "Browser-End-to-End (render/click/tab)" "node oder Check-Skript fehlt"
fi

echo
if [ "$FAIL" = 0 ]; then echo "web-frontend-check: HEALTHY ($BASE)"; else echo "web-frontend-check: PROBLEM ($BASE)"; fi
exit "$FAIL"
