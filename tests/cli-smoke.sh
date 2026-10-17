#!/usr/bin/env bash
# shellcheck disable=SC2016
# Literal Bash expressions in templates must not be evaluated by this test.
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
tool="$root/shtpl"
printf '%s\n' 'hello from file' >"$work/input.tpl"
[[ $(bash "$tool" --version) == 'shtpl 2.0.0' ]]
bash "$tool" --help | grep -q -- '--output FILE'
bash "$tool" -i "$work/input.tpl" -o "$work/output"
cmp "$work/input.tpl" "$work/output"
bash "$tool" --input="$work/input.tpl" --output="$work/output"
cmp "$work/input.tpl" "$work/output"
bash "$tool" --compile -i "$work/input.tpl" -o "$work/generated.sh"
bash -n "$work/generated.sh"
bash "$work/generated.sh" >"$work/rendered"
cmp "$work/input.tpl" "$work/rendered"
bash "$tool" --check --input="$work/input.tpl" >"$work/empty"
[[ ! -s $work/empty ]]
bash "$tool" -i - -o "$work/output" <"$work/input.tpl"
cmp "$work/input.tpl" "$work/output"
bash "$tool" -i "$work/input.tpl" -o "$work/input.tpl"
cmp "$work/output" "$work/input.tpl"
printf '%s\n' keep >"$work/output"
printf '%s\n' '{% if 1 == %}' >"$work/invalid.tpl"
status=0
bash "$tool" -i "$work/invalid.tpl" -o "$work/output" 2>"$work/err" || status=$?
((status == 2))
grep -qx keep "$work/output"
printf '%s\n' before '{{ r=$(exit 23) }}' >"$work/runtime.tpl"
status=0
bash "$tool" -i "$work/runtime.tpl" -o "$work/output" 2>"$work/err" || status=$?
((status == 23))
grep -qx keep "$work/output"
for args in '--check --output foo' '--compile --check' '--input' '--output' '--wat' '--input='; do
  status=0
  # shellcheck disable=SC2086
  bash "$tool" $args >"$work/empty" 2>"$work/err" || status=$?
  ((status == 2))
  [[ ! -s $work/empty ]]
done
[[ -z $(find "$work" -maxdepth 1 -name '.shtpl.*' -print -quit) ]]
printf 'Passed F06 CLI checks\n'
