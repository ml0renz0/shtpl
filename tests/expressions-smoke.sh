#!/usr/bin/env bash
# shellcheck disable=SC2016
# Single-quoted fixture strings intentionally defer expansion to the generated Bash.
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT
check() {
  local name=$1 source=$2 expected=$3
  printf '%s' "$source" > "$work/input"
  printf '%s' "$expected" > "$work/expected"
  bash "$root/shtpl" --compile < "$work/input" > "$work/generated"
  bash -n "$work/generated"
  bash "$root/shtpl" < "$work/input" > "$work/direct"
  bash "$work/generated" > "$work/compiled"
  cmp "$work/expected" "$work/direct"
  cmp "$work/expected" "$work/compiled"
  bash "$root/shtpl" --compile < "$work/input" > "$work/repeated"
  cmp "$work/generated" "$work/repeated"
  printf 'PASS F03 %s\n' "$name"
}
check multiple-commands 'left=$(printf A),right=$(printf B)
' 'left=A,right=B
'
check multiple-arithmetic 'left=$((1+1)),right=$((2+2))
' 'left=2,right=4
'
check nested-substitutions 'nested=$(printf "<%s>" "$(printf inner)")
' 'nested=<inner>
'
check arrays '{{ items=(first "two words" third) }}
values=${items[0]}|${items[1]}|${items[2]}
' 'values=first|two words|third
'
check associative-arrays '{{ declare -A words=([a]=yes [b]=no) }}
values=${words[a]}|${words[b]}
' 'values=yes|no
'
check quotes-and-escapes '{{ name=world }}
quotes="$name"
escaped=\$name
# ignored=$MISSING $(exit 42)
' 'quotes="world"
escaped=$name
# ignored=$MISSING $(exit 42)
'
check marker '__SHTPL_00000001__
' '__SHTPL_00000001__
'
check trailing-backslash 'hello=\
after=ok
' 'hello=\
after=ok
'
check trailing-expansion '{{ name=world }}
hello=$name\
after=ok
' 'hello=world\
after=ok
'
check inactive-branch '{% if 1 == 0 %}
not-evaluated=$UNDEFINED $(exit 42) $((1/0))
{% else %}
active=ok
{% endif %}
' 'active=ok
'
printf 'effect=$(touch %q; printf good)\n' "$work/effect" > "$work/input"
bash "$root/shtpl" --compile < "$work/input" > "$work/generated"
[[ ! -e "$work/effect" ]]
bash "$work/generated" > "$work/result"
[[ -f "$work/effect" ]]
[[ $(cat "$work/result") == effect=good ]]
printf 'F03 expression compatibility tests passed\n'
