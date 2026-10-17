# shtpl v2 — SHell TemPLating

A compact Jinja-inspired template-to-Bash compiler for **trusted** templates.
Supports nested conditionals and loops, Bash expansions, static validation,
and execution with legacy stdin compatibility.

## CLI

    shtpl < template.tpl
    shtpl -i template.tpl -o rendered.txt
    shtpl --check -i template.tpl
    shtpl --compile -i template.tpl -o generated.sh
    shtpl --help
    shtpl --version

Use a single dash (-) for standard input or output. Output files are staged
and replaced only after success. With --check, stdout is always empty and
--output is invalid. With --compile, Bash code is generated without executing
any template expressions. Default rendering executes Bash expressions;
**never run untrusted templates**.

## Installation

    install -m 755 shtpl "$HOME/.local/bin/shtpl"

Requires Bash 4.4+ and GNU coreutils. See [compiler reference](docs/COMPILER.md),
[release process](docs/RELEASE.md), [changelog](CHANGELOG.md), and
[original sample template](shtpl.test).
