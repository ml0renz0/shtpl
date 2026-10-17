# F00 — Legacy baseline and CI contract

## Immutable reference

- Repository: `ml0renz0/shtpl`
- Reference branch: `main`
- Legacy commit: `31798223cfbc12a98c9c6d6de5c1e20add8e8aea`
- Original `shtpl` Git blob: `9235c424de06f5e2e23b438d2e60416c07205568`
- Reference date: 2026-10-17

**The engine and existing demo (`shtpl`, `shtpl.test`, `README.md`) are unchanged in F00.**
The commit and blob hashes above, rather than a moving branch name, are the
reference points when comparing a rewritten engine with legacy behavior.

## What blocks CI now

- `bash -n shtpl` verifies Bash syntax.
- ShellCheck and shfmt are mandatory for *new test harness shell scripts*.
- Bats asserts exact output and successful exit status against deterministic
  fixtures on Ubuntu 22.04 and 24.04.
- A separate Bash-only runner compares fixture output byte-for-byte under Bash
  4.4, 5.1, and 5.2 (versions correspond to CI environments; actual version is
  printed for the Ubuntu jobs).
- Original `shtpl` ShellCheck findings and shfmt differences are collected as
  downloadable CI artifacts, but do not block F00: resolving them could change
  legacy execution, which is explicitly out of scope.

Run locally (after installing Bats, ShellCheck, and shfmt):

    bash -n shtpl
    bash tests/smoke.sh
    bats tests/baseline.bats tests/known-issues.bats
    shellcheck -s bash tests/*.sh
    shfmt -ln bash -i 2 -d tests/*.sh

## Proven legacy contract (golden fixtures)

The nine enabled fixtures cover:

1. Literal output, comments and blank lines.
2. Scalar variable definition/expansion.
3. `if` true path and `else` path.
4. Basic `for` loops.
5. One `for` directly within an `if`.
6. One `if` directly within a `for`.
7. A single arithmetic and command substitution on separate lines; escaped `$`.
8. Final input line that has no newline.

Each fixture has an `.tpl` input and a `.expected` exact output, with no use of
`$RANDOM`, system hostname, user databases, time, or host-specific output.
The existing `shtpl.test` remains an example, **not** a test oracle.

## Known limitations: pending, never green-washed

`tests/known-issues.bats` contains skipped, executable future contracts with
inputs and desired output in `tests/fixtures/pending/`. These are **not**
considered supported or passing in F00:

- Same-type nesting: `for` inside `for`, `if` inside `if`.
- Depth three: `for → if → for`, `if → for → if`.
- Two `$(...)` command substitutions on one line.
- Two `$((...))` arithmetic substitutions on one line.

The legacy source also explicitly states that invalid syntax is not checked
before execution, and delimiter whitespace is strict. These limitations remain
part of the known-debt inventory, not new feature guarantees.

## Evolution rules

1. Add an expected behavior fixture and an initially failing test before
   implementing each feature.
2. Unskip the relevant pending contract when its behavior is implemented.
3. Keep the original legacy fixtures unchanged; intentional breaking changes
   require an explicit contract update and a release note.
4. A green CI must mean every enabled test actually passed. Skipped contracts
   and non-blocking legacy lint debt must remain visible in reports.
5. No releases or automatic merges are configured in F00.

**Important:** a template can execute shell commands as the user running
`shtpl`. The tests only exercise trusted fixtures; they are not a sandbox or a
security validation of untrusted input.
