# F09 — Language extensions and external variables

The v2.1 language feature set adds `elif`, static relative includes and
external scalar values. These features are available in rendering, `--compile`
and `--check` while preserving original stdin templates.

## Example

```bash
shtpl -i ./page.tpl --vars-file ./dev.vars --var NAME=override -o page.txt
```

```text
# dev.vars (literal data, not sourced as shell code)
NAME=Example
COUNT=2
GREETING=Hello world
```

```text
{% if "$COUNT" == "1" %}
one
{% elif "$COUNT" == "2" %}
{% include "fragments/two.tpl" %}
{% else %}
other
{% endif %}
```

- `--vars-file FILE` (also `--var-file`) can be supplied repeatedly.
  A later file overrides earlier files. Blank lines and comment-only lines
  starting with optional whitespace followed by `#` are ignored.
- `--var NAME=VALUE` can be supplied repeatedly. It takes priority over
  every vars file regardless of CLI argument order; later `--var` entries win.
- A variable name follows `[A-Za-z_][A-Za-z0-9_]*`. All values are literal
  single-line strings, including spaces, `=`, `$`, and `$(...)`. The loader
  does not invoke `source` or `eval`. Quotes in files are literal characters,
  not shell quotation syntax; no interpolation or recursive expansion occurs.
- CLI-provided values become ordinary Bash variables in the generated program,
  before any template assignments. Thus explicit assignments *inside* a template
  can override them. `--check` validates the variables file and template
  without executing generated Bash.
- `{% include "path/to/fragment.tpl" %}` is compiled statically, not at
  rendering time. Relative paths resolve against the including file; stdin
  resolves relative to the working directory. Nested includes work, cycles
  and missing files report errors, and 64 active files are supported at most.
  Each included file must balance its own `if` and `for` blocks. This
  prevents a fragment from opening a block closed by a different file.
- `elif` is permitted only inside `if`, before any `else`. Multiple
  `elif` branches are supported. The first matching branch executes.
- The template and included files must be trusted: inclusion does not create
  a security boundary and the generated Bash remains executable code.


## F10 — Literal blocks, declarations and development diagnostics

### Literal blocks

Use \`{% raw %}\` / \`{% endraw %}\` to output lines **verbatim**,
without expanding Bash expressions, interpreting \`{{ ... }}\` assignments,
or parsing template directives:

\`\`\`text
{% raw %}
The text $HOME and $(echo hello) is printed literally.
{% if 1 == 1 %}
{% endraw %}
\`\`\`

Directives must occupy a complete line exactly. Raw blocks must open and
close within the same file; nested raw blocks, stray \`endraw\` and
unterminated raw blocks are rejected with exit status 2. An empty raw block
is allowed. The compiler emits quoted here-documents for raw lines; no shell
substitutions in those lines are executed. \`--check\` and \`--compile\` do
not execute any template code.

### Required variables

\`{% require NAME %}\` declares a required, externally supplied scalar
variable. Declarations are checked at compile time, including in statically
included files and within conditionals, for all three modes
(render, \`--check\`, \`--compile\`).

\`\`\`text
{% require APP_NAME %}
Application: $APP_NAME
\`\`\`

A requirement is satisfied by \`--var\`, any \`--vars-file\`, or an
**exported environment variable** of the invoking \`shtpl\` process.
An empty but present value is valid. Assignment inside the template does
**not** satisfy a requirement: declarations describe external inputs and
are validated without running template code. A missing variable produces a
clear error with its file and source line. Variable names must follow
\`[A-Za-z_][A-Za-z0-9_]*\`. A \`--compile\` output may rely on inherited
environment variables; run the emitted Bash with the same environment or
pass the value explicitly when compiling. This is not static inference of
every \`$NAME\` reference; Bash runtime \`set -u\` still applies.

### Strict validation of variable precedence

By default, F09 semantics remain unchanged:

1. Later \`--vars-file\` entries override earlier ones.
2. \`--var\` overrides all files regardless of argument order.
3. Runtime assignments **in the template** override both.
4. Without explicit values, exported environment variables are inherited.

\`--strict-vars\` is an **opt-in audit** that fails before compilation if
a name is supplied more than once from the same source, or if different
sources supply different values for that name. Errors identify the variable,
its current origin and previous origin. Repeating the same value across
different sources is allowed. Use normal mode for intentional layered
overrides; use strict mode to catch duplicate keys and unexpected
configuration conflicts. Neither mode evaluates file contents as Bash.

Example:

\`\`\`bash
shtpl --check --strict-vars -i app.tpl --vars-file common.vars --vars-file prod.vars
\`\`\`

### Diagnostic provenance

Parse errors in nested included files now report the immediately failing
file and the include call sites, each with its source line. Generated Bash
syntax errors also map back to a source file/line and print an inclusion
chain (for example \`root.tpl:2 -> fragments/inner.tpl:4\`).
No include stack is executed at render time: includes remain static,
and relative paths and the F09 cycle/depth checks are unchanged.

The F10 regression suite exercises invalid/missing values, empty and
malformed raw blocks, literal command substitutions, nested includes,
source mapping, Bash 4.4, and opt-in precedence conflicts.
