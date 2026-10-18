#!/usr/bin/env bash
# F10: literal raw blocks, required values, strict variable validation and diagnostics.
# shellcheck disable=SC2016
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
mkdir -p "$work/includes"

assert_failure() {
  local expected=$1 status=0 mode
  shift
  for mode in --check --compile execute; do
    status=0
    if [[ $mode == execute ]]; then
      bash "$root/shtpl" "$@" > "$work/out" 2> "$work/err" || status=$?
    else
      bash "$root/shtpl" "$mode" "$@" > "$work/out" 2> "$work/err" || status=$?
    fi
    if ((status != 2)) || [[ -s $work/out ]] || ! grep -Fq -- "$expected" "$work/err"; then
      printf 'FAIL F10 (mode=%s, expected=%s, status=%s)\n' "$mode" "$expected" "$status" >&2
      cat "$work/err" >&2
      return 1
    fi
  done
}

cat > "$work/raw.tpl" <<'TPL'
prefix
{% raw %}
Hello $NAME $(touch /tmp/this-must-not-run)
{% if 1 == 1 %}
{{ NAME=bad }}
# comment
trailing \
{% endraw %}
suffix=$NAME
TPL
cat > "$work/expected" <<'OUT'
prefix
Hello $NAME $(touch /tmp/this-must-not-run)
{% if 1 == 1 %}
{{ NAME=bad }}
# comment
trailing \
suffix=world
OUT

bash "$root/shtpl" -i "$work/raw.tpl" --var NAME=world > "$work/out"
cmp "$work/expected" "$work/out"
bash "$root/shtpl" --check -i "$work/raw.tpl" --var NAME=world > "$work/out"
[[ ! -s $work/out ]]
bash "$root/shtpl" --compile -i "$work/raw.tpl" --var NAME=world > "$work/generated.sh"
bash -n "$work/generated.sh"
bash "$work/generated.sh" > "$work/out"
cmp "$work/expected" "$work/out"

printf '{%% raw %%}\n{%% raw %%}\n{%% endraw %%}\n' > "$work/bad.tpl"
assert_failure 'nested raw block' -i "$work/bad.tpl"
printf '{%% endraw %%}\n' > "$work/bad.tpl"
assert_failure 'unexpected endraw' -i "$work/bad.tpl"
printf '{%% raw %%}\nhello\n' > "$work/bad.tpl"
assert_failure 'unclosed raw block' -i "$work/bad.tpl"

printf '{%% require MISSING_F10_VALUE %%}\n' > "$work/bad.tpl"
assert_failure 'missing required variable MISSING_F10_VALUE' -i "$work/bad.tpl"
printf '{%% require 12BAD %%}\n' > "$work/bad.tpl"
assert_failure 'invalid required variable' -i "$work/bad.tpl"

printf 'NAME=from-file\n' > "$work/first.vars"
printf '{%% require NAME %%}\nname=$NAME\n' > "$work/required.tpl"
bash "$root/shtpl" --check -i "$work/required.tpl" --vars-file "$work/first.vars"
bash "$root/shtpl" -i "$work/required.tpl" --var NAME=from-cli > "$work/out"
[[ $(cat "$work/out") == 'name=from-cli' ]]

printf '{%% require F10_EXTERNAL %%}\nenv=$F10_EXTERNAL\n' > "$work/env.tpl"
F10_EXTERNAL=from-env bash "$root/shtpl" -i "$work/env.tpl" > "$work/out"
[[ $(cat "$work/out") == 'env=from-env' ]]

printf 'NAME=first\nNAME=second\n' > "$work/duplicates.vars"
assert_failure 'duplicate variable NAME' --strict-vars --vars-file "$work/duplicates.vars" -i "$work/required.tpl"
printf 'NAME=second\n' > "$work/second.vars"
assert_failure 'conflicting variable NAME' --strict-vars --vars-file "$work/first.vars" --vars-file "$work/second.vars" -i "$work/required.tpl"
assert_failure 'conflicting variable NAME' --strict-vars --vars-file "$work/first.vars" --var NAME=override -i "$work/required.tpl"
assert_failure 'duplicate variable NAME' --strict-vars --var NAME=x --var NAME=y -i "$work/required.tpl"
bash "$root/shtpl" --check --strict-vars --vars-file "$work/first.vars" --var NAME=from-file -i "$work/required.tpl"
bash "$root/shtpl" --vars-file "$work/first.vars" --vars-file "$work/second.vars" -i "$work/required.tpl" > "$work/out"
[[ $(cat "$work/out") == 'name=second' ]]

printf '{%% include "includes/a.tpl" %%}\n' > "$work/main.tpl"
printf '{%% include "b.tpl" %%}\n' > "$work/includes/a.tpl"
printf '{%% require MISSING_F10_DEEP %%}\n' > "$work/includes/b.tpl"
assert_failure 'missing required variable MISSING_F10_DEEP' -i "$work/main.tpl"
grep -Fq "included from $work/includes/a.tpl:1" "$work/err"
grep -Fq "included from $work/main.tpl:1" "$work/err"

printf '{{ bad=ok; ) }}\n' > "$work/includes/b.tpl"
assert_failure 'invalid Bash syntax at template line 1' -i "$work/main.tpl"
grep -Fq "$work/includes/b.tpl" "$work/err"
grep -Fq "$work/main.tpl:1" "$work/err"

printf 'F10 language/DX features: PASS\n'
