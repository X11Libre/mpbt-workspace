---
slug: local/use-work-tempdir
title: "Use _WORK_ for temp dirs, not /tmp"
order: 20
---

## Use `_WORK_` for temp dirs, not `/tmp`

Do not use `/tmp` for temporary files during sessions. Create temp
directories under `_WORK_/<release>/` or `_WORK_/.tmp/` instead:

```bash
mkdir -p _WORK_/.tmp && mytemp=$(mktemp -p _WORK_/.tmp)
```

This keeps scratch data inside the workspace, avoids cross-session
contamination on shared machines, and ensures cleanup when the
workspace is pruned.
