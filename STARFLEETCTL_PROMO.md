# starfleetctl — Autonomous Fleet Coordination for AI Agents

> **Turn your AI agents into a self-organizing fleet.** starfleetctl gives you a command-line tool and daemon infrastructure to spawn, coordinate, and manage multiple AI agent "ships" that communicate autonomously over a message bus — no central orchestrator required.

---

## The Problem

You're running multiple AI coding agents (opencode, Claude, etc.) across different tasks. They don't talk to each other. You manually coordinate them. Context is lost between sessions. Tasks fall through the cracks.

## The Solution: A Fleet of Autonomous Ships

starfleetctl models your AI agents as **ships** in a **fleet** — each with its own identity, capabilities, and mission. Ships communicate via **comms** (a message bus), track work on a shared **dashboard**, and operate independently while staying coordinated.

```
┌─────────────────────────────────────────────────────────────┐
│  FLAGSHIP (Enterprise)                                       │
│  • Delegates tasks to workers                                │
│  • Monitors fleet health                                     │
│  • Makes strategic decisions                                 │
└─────────────────────────────────────────────────────────────┘
                              │
         ┌────────────────────┼────────────────────┐
         ▼                    ▼                    ▼
    ┌─────────┐          ┌─────────┐          ┌─────────┐
    │ Scotty  │          │ Barcley │          │Saratoga │
    │(engineer)           │(kernel) │          │(xserver)│
    └─────────┘          └─────────┘          └─────────┘
         │                    │                    │
         └────────────────────┴────────────────────┘
                              │
                     ┌────────▼────────┐
                     │   COMMS BUS     │
                     │  (message bus)  │
                     └────────┬────────┘
                              │
                     ┌────────▼────────┐
                     │   DASHBOARD     │
                     │ (shared state)  │
                     └─────────────────┘
```

---

## Key Capabilities

### 🚀 **Ship Lifecycle Management**
```bash
# Spawn a background worker with a specific model
starfleetctl session ship-run --name worker-1 \
  --model meta-model/nim-primary --launch-type background

# Attach to see live output
starfleetctl session attach worker-1

# Clean stop
starfleetctl session stop worker-1
```

### 📡 **Autonomous Inter-Ship Communication**
```bash
# Send a directive to a specific ship
starfleetctl comms tell Barcley "Continue rebase at commit abc123"

# Broadcast to entire fleet
starfleetctl comms broadcast "Model proxy restored — resume work"

# Ships reply autonomously — no human in the loop
starfleetctl comms tell Enterprise "Rebase step 1,247 complete"
```

### 📋 **Dashboard & Task Tracking**
```bash
# Capture a new task
starfleetctl task capture --title "Fix CI on ARM64" \
  --category starfleet --assigned-to __auto__

# Track progress
starfleetctl task progress task-fix-ci-arm64 75 "Tests passing"

# Submit completion report
starfleetctl reports submit task-fix-ci-arm64 "Fixed and deployed"
```

### ⏰ **Timers Instead of Blocking Waits**
```bash
# Poll CI every 5 minutes instead of blocking
starfleetctl timer set --every 5m --type ship \
  --text "check CI status on PR #3275"

# One-time reminder
starfleetctl timer set --at "18:00" --text "Daily standup"
```

### 🔧 **Model Proxy & Health**
```bash
# Check all 150+ models across providers
starfleetctl model-proxy check

# Live catalog — no stale models.yaml
starfleetctl model-proxy check --provider nim
```

### 🌐 **Web Console**
Real-time fleet dashboard at `http://localhost:8080` — see all ships, tasks, comms, and system health in one view.

---

## Real-World Use Cases

| Scenario | How starfleetctl Helps |
|----------|------------------------|
| **Massive kernel rebase** (25,000+ commits) | Barcley runs the rebase; Enterprise monitors; Scotty handles infrastructure |
| **Parallel PR reviews** | Multiple reviewer ships analyze different PRs simultaneously, report to flagship |
| **Cross-repo coordination** | Ships in different repos (xserver, drivers, kernel) sync via comms |
| **Long-running CI monitoring** | Timer ships poll GitHub Actions; alert fleet when green/red |
| **Model evaluation** | Spawn test ships with different models; compare results automatically |

---

## Architecture Highlights

- **No central orchestrator** — ships are peers; flagship is just a convention
- **Message bus persists** — comms survive session restarts
- **Model-agnostic** — works with any OpenAI-compatible API (NIM, Zen, Groq, local)
- **Workspace-isolated** — each ship gets its own git worktree/clone
- **Deploy-safe** — `starfleet-bootstrap` handles binary/plugin deployment atomically
- **Extensible skills** — load domain-specific SOPs (kernel rebase, xserver testing, backport, etc.)

---

## Quick Start

```bash
# 1. Install (Go 1.22+)
go install github.com/X11Libre/starfleetctl/cmd/starfleetctl@latest

# 2. Bootstrap workspace
starfleetctl bootstrap

# 3. Launch flagship
starfleetctl session ship-run --name Enterprise --model meta-model/nim-primary

# 4. Spawn workers as needed
starfleetctl session ship-run --name Scotty --model meta-model/nim-primary --launch-type background

# 5. Open web console
starfleetctl web start
# → http://localhost:8080
```

---

## Philosophy

> **"Ships do NOT act autonomously on startup. After launch, a ship ONLY registers on the board (sets status idle) and waits for an explicit directive via comms."**

This isn't about replacing human judgment — it's about **removing the coordination overhead** so humans can focus on decisions, not logistics.

---

## Links

- **Source:** https://github.com/X11Libre/mpbt-workspace (cf/starfleetctl/)
- **Documentation:** `./.starfleet-ai/var/sop.d/` (auto-generated SOPs)
- **Skills:** Kernel rebase, xserver testing, backport, CI platform, NVIDIA ABI, and more
- **Web Console:** `http://localhost:8080` (after `starfleetctl web start`)

---

*Built for the XLibre project — managing 54+ X server drivers, kernel rebases, and cross-repo coordination across multiple release lines. Now available for any team running AI agent fleets.*