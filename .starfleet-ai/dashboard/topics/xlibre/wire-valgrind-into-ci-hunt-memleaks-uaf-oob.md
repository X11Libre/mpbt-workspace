Title: "Wire valgrind (memcheck) into CI, hunt memleaks/UAF/OOB"
Category: done
Status: "**Done — PR open + fully green, awaiting praetor merge decision**"
Doc-Ref: "PR #3225 (`ci: run pyxtest under valgrind memcheck on Ubuntu`, master, single clean commit `77b2d64733`, open, not draft, mergeable)"
Migrated-From: 8cf8692b9f0057ffe44e793b35bcf7329da83d3f
Slug: wire-valgrind-into-ci-hunt-memleaks-uaf-oob

Praetor request, 2026-07-02 (see git history of this row for the full initial research/dispatch). **Gap confirmed:**
`pytest` wasn't installed in the Ubuntu CI image at all, so `pyxtest`'s existing-but-unused valgrind harness was
silently never built/run. **Shipped:** `install-pkg.sh` gains `python3-pytest`/`-timeout`/`-xdist`/`valgrind`; new
`.github/scripts/ubuntu/run-pyxtest-valgrind.sh` (builds `xorgproto` from source first, then a debug Xvfb-only config,
then `pytest --valgrind test/pyxtest/`); new dedicated CI job `xserver-build-ubuntu-valgrind` (kept separate from the
existing ubuntu lanes — valgrind is slow, pyxtest only needs Xvfb). Side effect (intentional, in the commit message):
the existing `xserver-build-ubuntu*` jobs now also run plain (non-valgrind) pyxtest for real, since `pytest` stops being
silently missing there. **One CI iteration needed:** first push failed fast — the new job's meson configure skipped the
`xorgproto`-from-source prereq step the other jobs rely on, so it saw the Ubuntu image's too-old system `presentproto`
(1.3 vs required ≥1.4); fixed by adding that same build step, confirmed via job logs (`presentproto found: YES 1.4`).
**Final CI: fully green** — 23 passed, 28 non-blocking skips (gating/dedup), 0 pending, 0 failing, including the slow
`xserver-build-solaris` (18m29s). The valgrind lane itself: 29 passed, 19 skipped, ~2min, real valgrind
1:3.22.0-0ubuntu3 on the runner. **Valgrind findings: none** — clean baseline, no leaks/invalid-access/UAF found on this
run; documented as such in the PR body rather than silently omitted. No new `@pytest.mark.valgrind` markers added — the
job's `--valgrind` CLI flag already forces the whole suite under valgrind regardless of per-test markers, so this
already covers more than just the one previously-marked test. **Not merged** — master-PR auto-merge needs an explicit
user request, which wasn't given; PR is ready and waiting on that call.
