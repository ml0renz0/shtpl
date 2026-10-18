#!/usr/bin/env bash
# F09 language features and literal external variables.
# shellcheck disable=SC2016
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
mkdir -p "$work/parts/nested"
printf 'NAME=from-file\nCOUNT=2\nDANGEROUS=$(touch %s)\n# comment\n\n' "$work/not-executed" > "$work/first.vars"
printf 'NAME=from-second\n' > "$work/second.vars"
cat > "$work/main.tpl" <<'TPL'
{% if "$NAME" == "wrong" %}
wrong
{% elif "$NAME" == "from-cli" %}
{% include "parts/inner.tpl" %}
{% else %}
other
{% endif %}
TPL
cat > "$work/parts/inner.tpl" <<'TPL'
{% for item in 1 2 %}
item=$item/$NAME/$COUNT
{% include "nested/tail.tpl" %}
{% endfor %}
TPL
printf 'tail\n' > "$work/parts/nested/tail.tpl"
printf 'item=1/from-cli/2\ntail\nitem=2/from-cli/2\ntail\n' > "$work/expected"
bash "$root/shtpl" -i "$work/main.tpl" --vars-file "$work/first.vars" --vars-file="$work/second.vars" --var NAME=from-cli > "$work/out"
cmp "$work/expected" "$work/out"
[[ ! -e "$work/not-executed" ]]
bash "$root/shtpl" --check -i "$work/main.tpl" --vars-file "$work/first.vars" --var NAME=from-cli > "$work/out"
[[ ! -s "$work/out" ]]
bash "$root/shtpl" --compile -i "$work/main.tpl" --vars-file "$work/first.vars" --var NAME=from-cli > "$work/generated.sh"
bash -n "$work/generated.sh"
bash "$work/generated.sh" > "$work/out"
cmp "$work/expected" "$work/out"
printf '{%% include "main.tpl" %%}\n' > "$work/cycle.tpl"
printf '{%% include "cycle.tpl" %%}\n' > "$work/self.tpl"
for invalid in cycle.tpl self.tpl; do
  if [[ $invalid == cycle.tpl ]]; then
    printf '{%% include "cycle.tpl" %%}\n' > "$work/main.tpl"
  fi
  status=0
  bash "$root/shtpl" --check -i "$work/$invalid" > "$work/out" 2> "$work/err" || status=$?
  ((status == 2))
  [[ ! -s "$work/out" ]]
  grep -Fq 'include cycle' "$work/err"
done
printf '{%% elif 1 == 1 %%}\n' > "$work/bad.tpl"
status=0
bash "$root/shtpl" --check -i "$work/bad.tpl" > "$work/out" 2> "$work/err" || status=$?
((status == 2))
grep -Fq 'unexpected elif' "$work/err"
printf '{%% if 1 == 1 %%}\n{%% else %%}\n{%% elif 1 == 1 %%}\n{%% endif %%}\n' > "$work/bad.tpl"
status=0
bash "$root/shtpl" --check -i "$work/bad.tpl" > "$work/out" 2> "$work/err" || status=$?
((status == 2))
grep -Fq 'elif after else' "$work/err"
printf 'bad var name=x\n' > "$work/bad.vars"
for arg in bad-vars bad-cli missing-file; do
  status=0
  case $arg in
    bad-vars) bash "$root/shtpl" --check --vars-file "$work/bad.vars" < /dev/null > "$work/out" 2> "$work/err" || status=$? ;;
    bad-cli) bash "$root/shtpl" --check --var '1BAD=yes' < /dev/null > "$work/out" 2> "$work/err" || status=$? ;;
    missing-file) bash "$root/shtpl" --check --vars-file "$work/no.vars" < /dev/null > "$work/out" 2> "$work/err" || status=$? ;;
  esac
  ((status == 2))
  [[ ! -s "$work/out" ]]
done
printf 'F09 language features: PASS\n'
