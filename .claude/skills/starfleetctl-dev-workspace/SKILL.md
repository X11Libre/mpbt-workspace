---
name: starfleetctl-dev-workspace
description: "Workspace-specific starfleetctl development details for THIS mpbt-workspace: the mpbt dev clone and its worktrees, the .starfleet-ai deployment clone, ports, and the isolated testbed (scripts/starfleet-testbed.sh). Also states which content belongs in the shipped skill vs. this workspace skill. Load together with the starfleetctl-dev skill when working on starfleetctl here."
---

# starfleetctl development — this workspace

Die **konkreten Orte dieser Workspace** und das **isolierte Testbed**. Der generische
Entwicklungs-/Deploy-Ablauf steht im Skill **`starfleetctl-dev`** — lade beide zusammen.

## Wo gehört welcher Inhalt hin? (Abgrenzung)

Damit immer klar ist, **was wohin muß** (z.B. für LaForge als Source-Owner):

| Inhalt | Ort | verwaltet von |
|---|---|---|
| **Generische** starfleetctl-Dev-Mechanik (Claim, `make all`, `bootstrap`, Daemon-Reihenfolge, Verifikation, Pitfalls, model-proxy-Regel, `pkill`-Regel, Branch-/Test-Prinzip) | **Source**: `fragments/starfleet-skills/starfleetctl-dev/SKILL.md` | `starfleet-bootstrap` — landet (byte-identisch) in `.claude/skills/starfleetctl-dev/` |
| **Workspace-spezifisch**: mpbt-Dev-Clone-Pfad, Worktrees, Ports, Deployment-Clone, **Testbed** | **dieser Skill** (`.claude/skills/starfleetctl-dev-workspace/SKILL.md` im Workspace-Repo) | **niemand** — Bootstrap fasst ihn nicht an (bleibt versionsverwaltet im Workspace-Repo) |
| starfleet-*Werkzeug*-Referenzen (`starfleet`, `starfleet-github`, `starfleet-sessions`, `starfleet-tasks`, `starfleet-timer`) | Source: `fragments/starfleet-skills/<name>/SKILL.md` | `starfleet-bootstrap` |
| xlibre-/Projekt-Skills (`backport`, `licensing`, `x86emu`, …) | Workspace: `.claude/skills/<name>/SKILL.md` | von Hand (Workspace-Repo, `mtx/agent-config`) |

**Daumenregel:** gilt es für **jeden** starfleetctl-Checkout → Source-Fragment. Gilt es
nur für **unsere** mpbt-Workspace (Pfade, Ports, Testbed) → dieser Skill.

**Falle:** der Source-Skill wird beim Bootstrap **aus dem Fragment zurückgeschrieben**.
Wer `.claude/skills/starfleetctl-dev/SKILL.md` direkt editiert, verliert die Änderung
beim nächsten Bootstrap. Generisches gehört ins Fragment, Workspace-Spezifisches hierher.

## Orte

- **Dev-Clone (mpbt-managed):** `_WORK_/starfleetctl/sources/starfleetctl` (Branch `master`).
- **Worktrees:** `starfleetctl worktree add _WORK_/starfleetctl/sources/starfleetctl <name>`
  → `_WORK_/worktrees/starfleetctl/<name>`, Branch `wt/<name>`.
- **Deployment-Clone (generiert):** `.starfleet-ai/src/starfleetctl` — nicht editieren.
- **Bootstrap:** `./starfleet-bootstrap` (am Workspace-Root).
- **Ports live:** web `8080`, model-proxy `8443`.

## Isoliertes Testbed — `scripts/starfleet-testbed.sh`

Eine **separate Workspace** unter `_WORK_/starfleet-testbed` mit eigenem `.starfleet-ai/`,
**eigenen Ports** (web `18080`, model-proxy `18443`) und **eigener Identität**
(`Testbed`) — vollständig entkoppelt von der Live-Flotte. Gedacht, um ein
starfleetctl-Build (v.a. den model-proxy) **isoliert** durchzutesten, **bevor** es auf
`master` und live geht.

```sh
./scripts/starfleet-testbed.sh create            # bauen + installieren + conf + bootstrap
./scripts/starfleet-testbed.sh start             # model-proxy + web + timer worker
./scripts/starfleet-testbed.sh smoke             # Isolation + Health (exit 0 = gesund)
./scripts/starfleet-testbed.sh status
./scripts/starfleet-testbed.sh stop | restart
./scripts/starfleet-testbed.sh destroy           # stop + rm -rf (zurück auf Null)
./scripts/starfleet-testbed.sh shell             # Shell in der Testbed-Root
```

Binary-under-test aus **beliebigem Branch / Worktree** bauen:

```sh
./scripts/starfleet-testbed.sh create --branch <name>     # Worktree off dem Primary-Clone
./scripts/starfleet-testbed.sh create --ref <ref>         # Commit/Tag/Remote
./scripts/starfleet-testbed.sh create --dev-clone <path>  # vorhandener Clone/Worktree
./scripts/starfleet-testbed.sh sync   --branch <name>     # neu bauen + installieren
```

Hinweise:

- **`destroy` + `create`** = jederzeit ein frisches Testbed.
- `--branch`/`--ref` materialisieren einen Worktree unter
  `_WORK_/worktrees/starfleetctl/testbed-src-*`.
- Die Testbed-`model-proxy.yaml` wird von der Live-Conf kopiert, aber der
  Health-Loop ist **deaktiviert** (sonst doppelte Upstream-Probes).
- **Niemals** das Testbed-`model-proxy stop`/`destroy` mit einem Binary **älter als
  `4d7903a`** laufen lassen: ältere Builds killten den **Live-Proxy** mit (die
  Cleanup-Logik war nicht root-scoped).
- Der Live-Cron (`web autostart`) schützte vor `62ebdb8` das genestete Testbed-Web
  nicht — mit dem Fix überlebt es.
