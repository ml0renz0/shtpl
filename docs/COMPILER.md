# F01–F02 — Template-to-Bash compiler with arbitrary nesting

Shtpl compiles the template from standard input into an executable Bash program:

```sh
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

F03 will formalize quoting/escaping and multiple-expansion semantics; F04 will
extend diagnostics and syntax checking. Only the F03 pending tests remain skipped.

This compiler does **not** sandbox the generated script. As with the legacy
engine, execute only trusted templates: assignments, substitutions, and
condition/loop expressions can run arbitrary shell commands at runtime.

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
- The CI matrix includes Ubuntu 22.04/24.04 and Bash 4.4.
