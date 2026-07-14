---
title: "opencode session setup"
order: 210
---

## opencode session setup

To work with this workspace via opencode, the user needs to:

1. Install opencode (`npm i -g opencode-ai` or their distro's package)
2. Run `opencode providers` to add an API provider credential (stored globally in
   `~/.local/share/opencode/auth.json`, no project-level config needed)
3. Start a session: `./run-opencode.xserver-<release>`

The `run-opencode.*` scripts source `cf/<release>/config.sh` and export
`XLIBRE_RELEASE` so subagents know which solution and workdir to use.
