# mpbt util.Executor refactor (2026-09-02, Voyager)

Extracted the various exec helpers in the mpbt source (`_WORK_/mpbt/sources/mpbt`,
branch `wip/executor`) into a new `util.Executor`, as preparatory work for future
container- / sysroot- / remote-build support. Commit `30b6358` (local only, no
origin push — external repo, hand-off to praetor).

## Design

- **`core/util/executor.go`**: `Executor` interface (`Exec` / `ExecOut` /
  `ExecRetcode`) + `LocalExecutor` (default host impl). `NewLocalExecutor()`.
  - `LocalExecutor.Env` — extra `KEY=VALUE` merged over the base env.
  - `LocalExecutor.UseHostEnv` — `true` = base is `os.Environ()`; `false` =
    curated-only (for container/sysroot later, must not leak host vars).
  - `env()` builds `[base][Env][per-call extraEnv]` — later wins (precedence).
- **Env plumbing (per exec, no global os.Setenv)**:
  - `Solution.GetEnv()` → the solution `env:` block as `KEY=VALUE`.
  - `Project.Executor util.Executor` (init → `NewLocalExecutor()`).
  - `Project.PushEnv()` now feeds solution `env:` into the executor (replaces
    the old `os.Setenv` loop); resolves the `loadprj.go` `// FIXME: should be
    done per exec`.
  - `Package.executor` set in `SetProject`; `Package.GetExecutor()`.
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

## Caveats / pre-existing issues (NOT from this change)

- `go test` without `-vet=off` FAILS on a **pre-existing** `go vet` warning in
  `core/util/multiflag.go:12` (`fmt.Sprint("%+v", *m)` — a real Printf bug, output
  would be `%!v(PANIC=...)`). Suggested as a follow-up fix (separate commit).
- Behavior change to flag: `PushEnv` previously `os.Setenv`'d solution `env:`
  globally (visible to git/fetch too). Now it's scoped to build commands via the
  executor. Workspace solutions only set build-tool vars (PKG_CONFIG_PATH,
  ACLOCAL_PATH, ACLOCAL_FLAGS), so no regression there; but a solution relying on
  `env:` for git/fetch would change.
- `wip/executor` == origin/master at start; `wip/container` (Enrico) had already
  added `Solution.GetEnv()` + `ContainerRuntime` — this executor is the host-side
  counterpart and is compatible with the container design.
