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

## Follow-up analysis (2026-09-10, from opencode session store)

Analyzing Barcley's session in `~/.local/share/opencode/opencode.db`
(session `ses_f7987c4f9ffe...`) revealed **why** the temp files happened — a
cascade of failed approaches to resolve a Kconfig conflict:

1. **Built an AWK script line-by-line with ~30 individual `echo '...'` appends**
   instead of one `cat > file << 'EOF'` heredoc. Hugely token-wasteful.
2. **Heredoc in a `cd &&` chain**: `> file << 'EOF'` in the middle of a
   `&&` chain → bash parsed the AWK code as shell commands
   (`BEGIN: Kommando nicht gefunden`).
3. **Path typo**: `/home/nekrad/src/xom/mpbt-workspace/tmp/` (missing 'r' in
   "xorg") → "Datei oder Verzeichnis nicht gefunden".
4. **`/tmp/opencode/` denied** by the permission model.
5. **`git rebase --continue` without `GIT_EDITOR=:`** → terminal-setup error in
   auto mode. Must always use `GIT_EDITOR=: git rebase --continue`.
6. **`git show :1:path` fails on unmerged files** — use `:2:` (ours) or `:3:`
   (theirs).
7. Finally resolved all 5 conflicting files correctly with
   `for f in $(git diff --name-only --diff-filter=U); do git show :2:$f > $f; done`.

**Correct approaches for Kconfig/file conflict resolution** (all simple):
- `git checkout --ours <file>` / `git checkout --theirs <file>` then `git add`
- `git show :2:<file> > <file>` / `git show :3:<file> > <file>`
- Manual merge by editing the conflicted file directly (read the
  `<<<<<<<`/`=======`/`>>>>>>>` markers)

**NEVER**: hand-rolled AWK/sed scripts, line-number-based `sed -i "${line}a..."`,
`resolve_*` temp dirs.

The `android-kernel-rebase` skill now documents all of this (commit 4e0025585d).
