## Barcley temp-file incident (2026-09-09)

**Problem**: Barcley left 37 untracked temp files directly in the kernel source
tree (`_WORK_/volla-kernel/sources/volla/kernel-mt8781`) during conflict resolution:
- Diff-comparison dumps: `our.c`, `their.c`, `base.c`, `merged.c` + variants
  (`_core.c`, `_fork.c`, `_kconfig`, `_proc_base.c`, `_riscv_kconfig`)
- Conflict-resolution directories: `resolve/`, `resolve_kconfig/` with
  `base`/`ours`/`theirs` files
- Backup files in subdirs: `.bak`, `.backup`, `.tmp`

**Root cause**: The `android-kernel-rebase` skill had rules about workspace
isolation (wrong branches, remotes) but **no rule about temp-file hygiene**.
Barcley ran `diff`/`git diff` and wrote output directly into the source tree.

**Fix**: Added "Temp files — NEVER in the source tree" section to the skill,
with explicit rule to use `_WORK_/volla-kernel/tmp/` for all temporary files,
and to run `git status --short` before commits to verify clean tree.

**Lesson**: Skills need explicit "don't litter in source trees" rules. AI agents
will create temp files in the most convenient location unless explicitly told
otherwise. Always include temp-file hygiene in any skill that involves file
manipulation or comparison.
