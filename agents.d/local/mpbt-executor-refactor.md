# mpbt util.Executor refactor (2026-09-02, Voyager)

Extracted the various exec helpers in the mpbt source (`_WORK_/mpbt/sources/mpbt`,
branch `wip/executor`) into a new `util.Executor`, as preparatory work for future
container- / sysroot- / remote-build support. Commit `30b6358` (local only, no
origin push — external repo, hand-off to praetor).

**Post-hoc bugfix (commit `549a150`):** the solution `env:` did not reach package
executors, breaking the autotools drivers (`./configure: syntax error near
unexpected token \`elographics'` / `XLIBRE_INIT_MODULE_AM` left unexpanded in
configure) because ACLOCAL_PATH/ACLOCAL_FLAGS were missing at aclocal time. Two
cumulative causes: (1) `Package.SetProject` was a *value* receiver so
`pkg.executor` was never persisted; (2) `PushEnv` replaced `prj.Executor` instead
of mutating it, so packages bound during `LoadSolution` kept an env-less
executor. Fixed by pointer receiver + in-place mutation of a shared
`*util.LocalExecutor`. Regression test `core/model/executor_test.go`. Verified
end-to-end: the real autotools Prepare for `xf86-input-elographics` now completes.
**Lesson:** if a once-global env moves onto a per-project "executor" object, the
object must be a shared pointer mutated in place, and setter receivers on the
objects holding it must be pointers — otherwise late-bound values silently
disappear.

## Design

- **`core/util/executor.go`**: `Executor` interface (`Exec` / `ExecOut` /
  `ExecRetcode`) + `LocalExecutor` (default host impl). `NewLocalExecutor()`.
  - `LocalExecutor.Env` — extra `KEY=VALUE` merged over the base env.
  - `LocalExecutor.UseHostEnv` — `true` = base is `os.Environ()`; `false` =
    curated-only (for container/sysroot later, must not leak host vars).
  - `env()` builds `[base][Env][per-call extraEnv]` — later wins (precedence).
- **Env plumbing (per exec, no global os.Setenv)**:
  - `Solution.GetEnv()` → the solution `env:` block as `KEY=VALUE`.
  - `Project.Executor *util.LocalExecutor` (pointer, init → `NewLocalExecutor()`):
    **must be a shared pointer**, not an interface value copied into packages —
    bindings made during `LoadSolution` must see late env mutations.
  - `Project.PushEnv()` now feeds solution `env:` into the executor **by mutating
    the existing shared `*LocalExecutor` in place** (`UseHostEnv`/`Env`), replacing
    the old `os.Setenv` loop; resolves the `loadprj.go` `// FIXME: should be done
    per exec`. Do NOT replace `prj.Executor` with a fresh object here — packages
    bound earlier would keep the old, env-less one.
  - `Package.executor *util.LocalExecutor` set in `SetProject` (**pointer
    receiver!** — a value receiver silently discarded the assignment and
    `GetExecutor()` fell back to a bare empty executor); `Package.GetExecutor()`.
  - The `util.Executor` interface stays in `core/util` for future non-local
    backends; the model works with the concrete `*LocalExecutor` so in-place env
    mutation is shared.
- **Builders**: `BuilderBase`'s four `ExecIn*Dir` helpers funnel into one
  `execIn` → `Package.GetExecutor().Exec`. exec/cmake builders now pass only
  `DESTDIR` as extra env (the executor supplies the base env) — matches the
  `wip/container` design decision; avoids doubling `os.Environ()`.
- **tar.go** now routes through `LocalExecutor` too (was the last `exec.Command`
  outside the executor; all `exec.Command` calls are now centralized).

## Variant consolidation answer (the "prüfe ob noch nötig" question)

- `ExecCmd` vs `ExecCmdEnv` differed only by per-call env → now an executor
  property; collapsed.
- `ExecIn*Dir`/`ExecIn*DirEnv` (4)× collapsed into one `execIn` + thin helpers.
- Legacy package-level `ExecCmd`/`ExecCmdEnv`/`ExecOut`/`ExecRetcode` remain
  ONLY for host-side infra that needs no env policy: `git` fetch/rev-parse,
  `pkg-config` probe (syspackage), `gcc -dumpmachine` (project), `PostCheckoutCmd`.
  These delegate to `LocalExecutor`.

## Verification

- `go build ./...` (go 1.24.9) + repo `make` (go 1.22 via `make.conf`) both green.
- `gofmt` clean.
- `go test -vet=off ./core/util/` — new `executor_test.go` covers ExecOut trim,
  retcode (0/1/127), env precedence (host vs extra vs per-call), UseHostEnv=false.
- Smoke: solution `env:` reaches the exec-builder command (EXIT 0, stat written).
- Post-fix (549a150): `go vet` clean, `go test` (no -vet=off) green, and the real
  autotools Prepare for `xf86-input-elographics` runs `./autogen.sh` end-to-end
  (ACLOCAL_PATH present → XLIBRE M4 macro expands, configure completes).

## Caveats / pre-existing issues (NOT from this change)

- A pre-existing `go vet` warning in `core/util/multiflag.go:12`
  (`fmt.Sprint("%+v", *m)` — real Printf bug) blocked `go test` without
  `-vet=off`. **FIXED** in commit `552537e` (`fmt.Sprintf("%+v", *m)`), together
  with a second vet diagnostic in `core/model/project.go:145` (fmt.Errorf with
  3 args but only 2 verbs — err was dropped; now given an explicit `%v`).
  `go vet ./...` and `go test ./...` are now clean without any workaround.
- Behavior change to flag: `PushEnv` previously `os.Setenv`'d solution `env:`
  globally (visible to git/fetch too). Now it's scoped to build commands via the
  executor. Workspace solutions only set build-tool vars (PKG_CONFIG_PATH,
  ACLOCAL_PATH, ACLOCAL_FLAGS), so no regression there; but a solution relying on
  `env:` for git/fetch would change.
- `wip/executor` == origin/master at start; `wip/container` (Enrico) had already
  added `Solution.GetEnv()` + `ContainerRuntime` — this executor is the host-side
  counterpart and is compatible with the container design.
