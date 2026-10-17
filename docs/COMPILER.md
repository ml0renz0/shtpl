# F01–F04 — Template-to-Bash compiler, Bash expressions, and diagnostics

Shtpl compiles the template from standard input into an executable Bash program:

```sh
shtpl --check < example.tpl
shtpl --compile < example.tpl > example.sh
bash -n example.sh
bash example.sh

# Default execution path compiles to a temporary script, then runs it.
shtpl < example.tpl
```

Compilation performs **no shell evaluation**. Assignments (`{{ NAME=value }}`),
conditionals (`{% if ... %}`), loops (`{% for ... %}`) and text expansions are
emitted as Bash statements. They are evaluated only when the generated program
is executed. Comments beginning with optional whitespace and `#` remain literal.

Generated text uses Bash here-documents so double quotes, expansions, and
command substitutions do not need to be evaluated by the compiler. Output
includes a newline after the final template line, matching the legacy contract.
The compiler uses Bash built-ins for scanning and emits deterministic output.

## Supported syntax

- Literal lines and comments
- `{{ NAME=value }}` and Bash-compatible assignments, including arrays
- `{% if condition %}`, `{% else %}`, `{% endif %}`
- `{% for expression %}`, `{% endfor %}`
- Expansion of `$NAME`, `$(command)`, and `$((expression))` at script runtime
- Arbitrary nesting of `if` and `for` in any combination, including siblings and empty blocks

## Deferred guarantees

F02 establishes the arbitrary-depth nesting contract, tracking branch state at
each nesting level. Each `else` belongs to the most recent open `if` and may
occur only once. Misplaced `else`, `endif`, `endfor`, and unterminated blocks
cause a compile-time exit status of 2. Empty `if` / `else` / `for` bodies are
valid.

F03 validates multiple substitutions, quoting, escaping, arrays, inactive branch
isolation and trailing backslashes. All originally pending contracts are active.
F04 adds `--check`, compile-time validation of the generated script with
`bash -n`, and diagnostics translated to template source line numbers. It
also identifies malformed/unknown directives, block opening locations, and
incorrect block endings. Invalid templates are rejected with exit status 2
before any generated Bash is executed. `--check` emits nothing to stdout and
executes no template commands; `--compile` emits no Bash on validation failure.

Bash syntax validation checks **the generated Bash grammar**, not the result of
evaluating an expansion. In particular, `bash -n` does not fully parse the
contents of unquoted heredocs, and therefore cannot guarantee that arbitrary
runtime substitutions inside template text will succeed. Errors reported at
end-of-file can sometimes be mapped only to the final nearby source line.

Examples of diagnostics:

```text
shtpl: unexpected endfor at line 2 (expected to close if opened at line 1)
shtpl: invalid Bash syntax at template line 2 (generated line 6): syntax error near unexpected token ...
```

Successful `--check` and `--compile` return 0 without executing template
commands. Neither is a security sandbox; running templates remains reserved
for trusted inputs.

This compiler does **not** sandbox the generated script. As with the legacy
engine, execute only trusted templates: assignments, substitutions, and
condition/loop expressions can run arbitrary shell commands at runtime.

F03 expands Bash expressions only at execution time, never during compilation.
Comment-only lines remain literal; inline comments are ordinary template text.
Only trusted templates should be executed. Quote characters in template text
are literal, not shell quoting operators. Trailing backslashes are preserved.

## Verification

- `bash tests/smoke.sh` checks default execution against the nine legacy
  golden fixtures.
- `bash tests/compile-smoke.sh` checks that compiling and running produces
  the same exact bytes and that generated scripts pass `bash -n`.
- `bats tests/compiler.bats tests/known-issues.bats` checks compile-time side
  effects, block validation, and the four formerly pending F02 fixtures.
- `bash tests/nesting-smoke.sh` verifies ten-level static nesting, dynamically
  generated 32-level nesting, sibling blocks, empty bodies, both execution
  modes, and seven structural error cases.
- `bash tests/expressions-smoke.sh` checks F03 expression/escaping regressions.
- `bash tests/diagnostics-smoke.sh` checks F04 validation and diagnostic cases,
  including output/side-effect isolation, in all existing Bash CI matrices.
- The CI matrix includes Ubuntu 22.04/24.04 and Bash 4.4.
