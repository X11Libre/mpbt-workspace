---
title: "Auto-commit on `mtx/agent-config`"
order: 200
---

## Auto-commit + push on the `mtx/agent-config` branch

`mtx/agent-config` is the maintainer's **personal** branch. When the working tree is on this
branch, **commit and push changes automatically — do not stop to ask for confirmation.** This
overrides the usual "commit only when explicitly asked" default, but applies **only** on this
branch (not on `master`, `genesis`, `pr3275`, etc.).

Use `.starfleet-ai/bin/starfleetctl ws-commit` so the push goes through the clone-lock mutex (concurrent sessions share
this single working tree):

```bash
git add <paths…>                       # stage (ws-commit -a only does `git add -u`, misses new files)
./.starfleet-ai/bin/starfleetctl ws-commit -m "<concise msg>" <paths…>
# or, for all tracked changes after manually staging any new files:
./.starfleet-ai/bin/starfleetctl ws-commit -m "<concise msg>" -a
```

`ws-commit` commits and pushes in one locked step. The push target is the branch's upstream
(`origin/mtx/agent-config`), set automatically when the branch was checked out.
