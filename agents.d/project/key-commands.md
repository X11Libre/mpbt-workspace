---
title: "Key commands"
order: 40
---

## Key commands

Essential quick reference — full details in the `starfleetctl` skill's `reference.md`.

### Workspace setup

| command | purpose |
|---------|---------|
| `./mpbt-workspace-bootstrap [--shell-hook] [--build] [--all-releases]` | one-shot fresh-clone setup (idempotent) |
| `./install-mpbt` | `go install github.com/metux/mpbt/cmd/mpbt-builder@latest` |

### Session management

| command | purpose |
|---------|---------|
| `./run-flagship [--detach]` | start flagship session (`AGENT_ID=Enterprise`) |
| `./run-ship [--release <rel>] [--name <id>]` | start a worker session with auto-assigned ship name |
| `./run-opencode.xserver-<release>` | start opencode session for a release line |
| `scripts/agent-run <release> [...]` | launch detached tmux session |
| `scripts/agent-attach <id>` | connect controller to detached agent |

### Build / fetch

| command | purpose |
|---------|---------|
| `./run-fetch.xserver-<release>` | clone/fetch all sources for a release line |
| `./run-build.xserver-<release>` | full build, then deletes `_WORK_/<release>/install` |

### PR workflow

| command | purpose |
|---------|---------|
| `scripts/xx-make-pr.sh <commits...>` | create PR from commits on incubator branch |
| `scripts/backport-commit <release> <commit-ish\|PR#>` | one-shot backport: clone → cherry-pick → PR |
| `scripts/pr-checkout <pr#> [name]` | isolated clone for PR repair |
| `scripts/pr-amend-push <clone-dir> [files...]` | amend commit + force-push |
| `scripts/pr-set-body <pr#> <body-file>` | set PR body via REST API |
| `scripts/pr-comment <pr#> <body-file> [--bot-review]` | post PR comment |

### Fleet coordination

| command | purpose |
|---------|---------|
| `starfleetctl agent-bus status/board/tell/broadcast` | cross-session control plane |
| `starfleetctl pr-claim <pr#> ["what"]` | advisory PR-branch lock |
| `starfleetctl ws-commit -m <msg> <path...>` | atomic commit+push under clone lock |
| `starfleetctl with-clone-lock <cmd...>` | serialize mutating work in a working tree |

### CI / review

| command | purpose |
|---------|---------|
| `starfleetctl pr-ci <pr#\|URL>` | quick CI status (classified by conclusion) |
| `scripts/pr-job-logs <pr#>` | fetch raw CI job logs + failure summary |
| `starfleetctl show-branch-file <ref> <path> [symbol]` | print file at any ref via GitHub API |
| `starfleetctl backport-applies <path> <grep-ERE> [rel ...]` | check applicability across release lines |

### NVIDIA / drivers

| command | purpose |
|---------|---------|
| `scripts/nvidia-abi-check SYM ...` | classify symbols against nvidia blobs |
| `scripts/fetch-nvidia-drivers [version ...]` | download + extract nvidia `.run` installers |
| `scripts/driver-tracker [--update <issue#>]` | cross-repo driver dashboard |

### Workspace utilities

| command | purpose |
|---------|---------|
| `scripts/json validate\|pretty\|get` | JSON helper (avoid ad-hoc python3 one-liners) |
| `scripts/cancel-stale-ci [--cancel]` | cancel CI runs whose branch moved on |
| `scripts/prune-stale-ci [--delete]` | delete completed stale workflow runs |
| `starfleetctl dashboard show\|pull\|write\|commit` | DASHBOARD.md read/write cycle |
