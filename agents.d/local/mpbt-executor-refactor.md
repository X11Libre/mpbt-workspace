# mpbt util.Executor refactor (2026-09-02, Voyager)

Extracted the various exec helpers in the mpbt source (`_WORK_/mpbt/sources/mpbt`,
branch `wip/executor`) into a new `util.Executor`, as preparatory work for future
container- / sysroot- / remote-build support. Commit `30b6358` (local only, no
origin push — external repo, hand-off to praetor).

**Env-propagation bug + fix:** the solution `env:` originally did not reach
package executors, breaking the autotools drivers (`./configure: syntax error
near unexpected token \`elographics'` / `XLIBRE_INIT_MODULE_AM` left unexpanded
in configure) because ACLOCAL_PATH/ACLOCAL_FLAGS were missing at aclocal time.
Root cause: the packages were bound to their project during `LoadSolution()`,
*before* the solution `env:` was applied by the later `PushEnv()` — the env never
reached them.

**Two attempts:** `549a150` tried a shared `*util.LocalExecutor` pointer held in a
Package field (pointer receiver `SetProject`). **Superseded** by `a9135bb`
(architectural directive): Package/Project are dumb accessors on a magicdict;
magicdict stores only scalars/lists/nested dicts (NOT arbitrary Go objects);
SpecObjs like Project/Solution are api.Entry and DO round-trip in the magicdict.
So the final design removes ALL executor state from Go struct fields: it lives as
a magicdict subtree ("executor": use-host-env flag + env dict) in the Project, and
`GetExecutor()` builds a fresh `*LocalExecutor` from it on demand — so a package
that resolves its Project via `GetProject()` (magicdict round-trip) always sees the
lateste env. Verified end-to-end: real autotools Prepare for
`xf86-input-elographics` completes.
**Lessons:** (a) to make a once-global env visible to packages loaded before it is
set, don't rely on shared pointers/field-binding — keep the state in the shared
magicdict and derive on demand; (b) reconcile envholders with "Package/Project are
dumb magicdict accessors": no executor/Go-state fields on Package; mutable data in a
project magicdict subtree fetched via the project.

## Design

- **`core/util/executor.go`**: `Executor` interface (`Exec` / `ExecOut` /
  `ExecRetcode`) + `LocalExecutor` (default host impl). `NewLocalExecutor()`.
  - `LocalExecutor.Env` — extra `KEY=VALUE` merged over the base env.
  - `LocalExecutor.UseHostEnv` — `true` = base is `os.Environ()`; `false` =
    curated-only (for container/sysroot later, must not leak host vars).
  - `env()` builds `[base][Env][per-call extraEnv]` — later wins (precedence).
- **Env plumbing (per exec, no global os.Setenv)**:
  - `Solution.GetEnv()` → the solution `env:` block as `KEY=VALUE`.
  - **Project holds executor state as a magicdict subtree** (`executor` key):
    `executor::use-host-env` (bool) + `executor::env::<var>` (dict of scalars).
    `Project.Init()` creates the subtree; `Project.PushEnv()` writes the solution
    `env:` block + `use-host-env=true` into it; `Project.GetExecutor()` builds a
    fresh `*LocalExecutor` from the subtree on every call. Resolves the
    `loadprj.go` `// FIXME: should be done per exec`. Because the executor is
    derived on demand from the shared magicdict, packages loaded *before*
    `PushEnv()` still see the env — no pointer/field binding needed.
  - **Package holds no executor field.** `SetProject()` is a **value receiver**
    (dumb accessor): it only does magicdict `Put`s (Project/Solution references +
    package defaults). `Package.GetProject()` reads the `*Project` object back from
    the magicdict (Project/Solution are SpecObj = api.Entry, so they round-trip);
    `Package.GetExecutor()` delegates to `pkg.GetProject().GetExecutor()` with a
    bare host fallback.
  - The `util.Executor` interface stays in `core/util` for future non-local
    backends; the model materializes a concrete `*LocalExecutor` from the subtree
    on demand.
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
- Post-fix (549a150 → a9135bb, after the subtree refactor): `go vet` clean, `go test`
  (no -vet=off) green, and the real autotools Prepare for `xf86-input-elographics`
  runs `./autogen.sh` end-to-end (ACLOCAL_PATH present → XLIBRE M4 macro expands,
  configure completes).

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
