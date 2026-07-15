---
slug: flyingtux-master-python-2-only-syntax-in-deploy-py
title: "FlyingTux `master`: Python-2-only Syntax in `deploy.py`"
category: parked
noted_by: "agent, 2026-07-02 (bei der mpbt-Solution-Integration entdeckt)"
since: "2026-07-02"
migrated_from: 8cf8692b9f0057ffe44e793b35bcf7329da83d3f
---

`src/imagebuilder/flyingtux/app/deploy.py` hat `chmod(scriptname, 0755)` — ein alter Oktal-Literal ohne `0o`-Präfix, unter Python 3 ein `SyntaxError` (nicht nur eine Warnung). Verhindert jeden `python -m compileall`/`ast.parse`-Smoketest über den Baum. Nicht Teil der mpbt-Integration gefixt (out of scope) — eigener kleiner Python-3-Kompatibilitäts-Fix, wenn `master` mal angefasst wird.
