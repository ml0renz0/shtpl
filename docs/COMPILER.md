# F01 — Template-to-Bash compiler

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

## Supported syntax in F01

- Literal lines and comments
- `{{ NAME=value }}` and Bash-compatible assignments, including arrays
- `{% if condition %}`, `{% else %}`, `{% endif %}`
- `{% for expression %}`, `{% endfor %}`
- Expansion of `$NAME`, `$(command)`, and `$((expression))` at script runtime
- Existing one-level mixed blocks: `if -> for` and `for -> if`

## Deferred guarantees

F02 establishes the full arbitrary-depth nesting contract. F03 defines all
quoting/escaping and multiple-expansion semantics. F04 formalizes diagnostics
and syntax checking. The F00 pending tests remain skipped until their
respective contracts are explicitly enabled.

This compiler does **not** sandbox the generated script. As with the legacy
engine, execute only trusted templates: assignments, substitutions, and
condition/loop expressions can run arbitrary shell commands at runtime.

## Verification

- `bash tests/smoke.sh` checks default execution against the nine legacy
  golden fixtures.
- `bash tests/compile-smoke.sh` checks that compiling and running produces
  the same exact bytes and that generated scripts pass `bash -n`.
- `bats tests/compiler.bats` checks absence of compile-time side effects and
  basic block termination failures.
- The CI matrix includes Ubuntu 22.04/24.04 and Bash 4.4.
