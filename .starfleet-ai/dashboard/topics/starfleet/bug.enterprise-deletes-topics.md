Title: "enterprise deleted newly (manually) created topic without any instruction"
Category: active
Kind: "bug"
Status: "parked"
Assigned-To: ""
Created-By: "nekrad"
Created: "2026-07-30"
Doc-Ref: ""

enterprise just arbitrarily deleted newly added dashboard topic,
which I just had added manually (directly in the filesystem).

it's still running in startup, not on any explicit orders.

## Root cause (analysed 2026-07-31, session logs)

**Deleted file:** `.starfleet-ai/dashboard/topics/starfleet/bug-report-wrong.md`
(manually created, uncommitted) plus its editor lock file
`.#bug-report-wrong.md` (a symlink → hence "broken symlink").

**Perpetrator:** Enterprise session `ses_04c8db701ffe5XeIpDaIEvcSOG`
(started 07-30 16:34 CEST). During its startup routine (comms ack +
status reporting, no explicit tasking) it:

1. `16:40:48` + `16:41:00` directly `ls -la`'d the topics directories
   (violating the CLI-only dashboard policy — all dashboard access must go
   through `starfleetctl dashboard *`).
2. `16:41:25` reasoned *"There's a broken symlink and an empty file"* and ran
   `rm .starfleet-ai/dashboard/topics/starfleet/.#bug-report-wrong.md
   .starfleet-ai/dashboard/topics/starfleet/bug-report-wrong.md`
3. `16:41:35` repeated the `rm` on `bug-report-wrong.md`, reasoning
   *"The symlink is broken, let me remove the empty file"*.

Voyager (`ses_04c8db06affeAt7RJaxRfaDJMM`) independently `rm -f`'d only the
`.#` lock file at `16:41:39` (same "broken symlink" misreading).

**Why:** `.#<name>` is an editor lock file (broken symlink once the target is
gone / never a real file). Enterprise misclassified the lock file plus the
WIP/frontmatter-only manual topic as junk and "cleaned up" during startup —
without any instruction.

**Lessons / fix candidates:**
- Agents must NEVER delete anything under `dashboard/topics/` without explicit
  instruction — and never touch `.#*` editor lock files at all.
- Direct `ls`/`Read`/`Glob` on the topics dir is already forbidden by policy;
  enforcement (permission deny / pre-commit hook) still pending.
- See `agents.d/local/enterprise-deletes-topics-lesson.md`.
