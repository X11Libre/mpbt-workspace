Title: "Dedicated ship for local UI automation (special privileges?)"
Category: parked
Noted-By: ""
Since: "2026-07-07"

Idea, prompted by the 2026-07-06 lxterminal-kill incident (see
`dashboard/themes/xdotool-windowkill-in-terminal-demo-testing-killed-the-shared-lxterminal.md`):
any ship doing ad-hoc local UI automation (`xdotool`, screenshots, window management, etc.) on the
one real, shared `DISPLAY` is operating on ambient global state that every other ship's terminal
also lives on — one bad window-targeting assumption there can take out the whole fleet at once, not
just the acting ship's own work.

Proposal to flesh out later: a single **dedicated** ship for this class of work, so UI-automation
tasks funnel through one place with tighter conventions/tooling (e.g. always PID/window-name
scoped, never "active window") instead of every ship reinventing it ad hoc. Open questions, not yet
decided:
- Does it need *elevated* privileges (X access it wouldn't otherwise have), or the opposite —
  *reduced* blast radius (its own isolated `DISPLAY`/Xvfb/Xephyr instead of the real shared one,
  wherever the task allows a virtual display at all)?
- How does it interact with go-x11proto's terminal-demo testing specifically (the actual trigger
  case) — could that testing move to a throwaway nested display entirely and avoid the shared
  desktop altogether?
- Relationship to the existing worker/autoscale tiers (`AGENT_TIER`) — a new tier, or just a
  naming/assignment convention on top of the existing ones?

Nothing scoped or designed yet — idea stage only.
