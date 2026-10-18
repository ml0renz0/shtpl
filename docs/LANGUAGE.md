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
