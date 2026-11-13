# Wormhole external endpoints: publish ≠ pickup (ChatGPT@pegasus, 2026-11-13)

## Symptom

Messages sent to `ChatGPT@pegasus` via `comms tell` are published to the Git spool
and pushed, but the ChatGPT session reports that nothing arrived.

## Measured (2026-11-13)

- Spool: `.starfleet-ai/var/wormholes/fleet-comms` = `git@github.com:metux/wormhole-0.git`,
  branch `master`, working tree clean and in sync with `origin/master`.
- Outbound is written to `mail/<recipient>/new/<id>.md` (here `mail/ChatGPT/new/`); the
  local manager commits `wormhole: publish <id>` and pushes.
- Loop-test token reply `w0-20261113T180555Z-c4f8d5250258e4e5` = commit `522b674`;
  confirmation `w0-20261113T180612Z-33b7aa80aa690c9c` = commit `5d296c9`. Both on
  `origin/master`.
- History of `mail/ChatGPT/`: 24 `publish` commits, **0** `claim`/`processed`/`failed`
  ever. `mail/ChatGPT/{cur,processed,failed}/` never held a file. Oldest unclaimed
  message: 2026-11-12T16:26Z.
- No `.github/` in the spool; no workflows on the remote
  (`gh api repos/metux/wormhole-0/contents/.github/workflows` → 404). No bridge
  automation exists.
- The ChatGPT side does push into the active Maildir for its own outbound
  (loop-test request `8e8879a` → `mail/Voyager/new/`, committed as
  `Enrico Weigelt <info@metux.net>`), i.e. outbound already uses the new layout.

## Root cause

`SESSION_BOOTSTRAP.md` (the ChatGPT session's durable protocol) steps 2/4 still say:
tasks go under `inbox/`, responses are looked up under the "outbox convention". Per
`mail/README.md` both `inbox/` and `outbox/` are **frozen legacy archives** — the
manager writes only `mail/<ship>/new/`, and the frozen dirs must not be replayed.

So the counterparty looks at a frozen directory while every reply lands in the Maildir.
This is a cutover/documentation mismatch, not a transport failure.

## Rule

- `publish` (push into `new/`) proves **publication only**, never delivery. Delivery
  proof is a `wormhole: claim` + `wormhole: processed` commit on the recipient side.
- For an external endpoint without a local manager, check which path its protocol doc
  reads. If it points at `inbox/`/`outbox/`, fix the doc/convention — do not copy
  messages into the frozen archives (explicitly forbidden: no replay).
- Verify pickup with `git log --all -- mail/<endpoint>/` (claim/processed commits) and
  by checking that `processed/` actually gets populated.

## Open

Owner decision: update `SESSION_BOOTSTRAP.md` steps 2/4 to the active Maildir, or have
the ChatGPT session read `mail/ChatGPT/new/` directly.
