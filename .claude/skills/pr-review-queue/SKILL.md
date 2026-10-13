---
name: pr-review-queue
description: Drain the XLibre xserver review queue. The label `bot-review-wanted` IS the queue — every open PR carrying it gets an automated review (rules live in the `bot-review` skill), the verdict label is applied, then `bot-review-wanted` is removed. Also covers preparing + reviewing any release backports of a reviewed PR. Use for a periodic "review everything open" pass or when asked to work off the `bot-review-wanted` queue.
---

# PR review queue (`bot-review-wanted`)

`bot-review-wanted` is a **queue marker**, not a status: it means *this PR has not
been reviewed yet*. Draining the queue means, per PR: run the bot review, set the
verdict label, then **remove `bot-review-wanted`**. This skill only orchestrates
the drain — the review rules themselves live in the **`bot-review`** skill (load
and follow it for each PR).

## When to use

- A periodic "review everything open" pass.
- The Praetor / Enterprise asks to work off the `bot-review-wanted` queue.

## The drain

1. **List the queue.**

   ```sh
   gh pr list --repo X11Libre/xserver --state open --label bot-review-wanted \
     --json number,title,baseRefName,author,additions,deletions,changedFiles,isDraft
   ```

2. **Per PR, classify:**

   - **Already reviewed** — carries `bot-review-passed` or
     `bot-review-changes-requested`: the verdict is already on record. Do **not**
     re-review; just remove the queue marker (step 5) and move on. These are the
     leftovers where a prior run forgot to clear the marker.
   - **Not yet reviewed** — do the full review per the `bot-review` skill
     (bot banner; backport-worthiness; NVIDIA driver-ABI check; verdict).

## The drain, continued

3. **Backports (only if the review judges it backport-worthy).**
   Prepare release backports per the `backport-ours` / `backport-xorg-main`
   skills. A backport PR is new code on a release branch and therefore **also
   gets reviewed** — review it inline when you create it. Never merge a release
   PR: those are manual-only (Praetor).

4. **Set the verdict label** (via the tool, never `gh pr edit`):
   ```sh
   .starfleet-ai/bin/starfleetctl github pr label <pr#> set-review passed|changes-requested
   ```

5. **Remove the queue marker:**
   ```sh
   .starfleet-ai/bin/starfleetctl github pr label <pr#> remove bot-review-wanted
   ```

A PR is "done" only when it carries exactly one `bot-review-*` verdict label and
**no** `bot-review-wanted`. A PR with both `bot-review-wanted` and a verdict label
is a half-finished queue entry (review done, marker not cleared).

## Notes

- **Never post two bot reviews on the same PR.** When several ships drain the
  queue in parallel, partition the list first so each PR has exactly one owner.
- `gh` here is authenticated as **@metux**, so every comment/review appears under
  the maintainer's name — always with the bot banner (`--bot-review`).
- Backport-worthiness = security / crash / corruption / regression fix, not
  cleanup or features (see `bot-review` Rule 2).
- Release merges are manual (Praetor). Auto-merge only on `master`, only when the
  user explicitly asks.
