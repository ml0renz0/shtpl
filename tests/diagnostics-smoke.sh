#!/usr/bin/env bash
# F04: syntax and structural diagnostics, source locations, and safety.
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT
count=0

assert_failure() {
  local name=$1 source=$2 diagnostic=$3 mode status
  printf '%s' "$source" >"$work/input.tpl"
  for mode in --check --compile execute; do
    status=0
    if [[ $mode == execute ]]; then
      bash "$root/shtpl" <"$work/input.tpl" >"$work/output" 2>"$work/stderr" || status=$?
    else
      bash "$root/shtpl" "$mode" <"$work/input.tpl" >"$work/output" 2>"$work/stderr" || status=$?
    fi
    if ((status != 2)) || [[ -s $work/output ]] || ! grep -Fq -- "$diagnostic" "$work/stderr"; then
      printf 'FAIL F04 %s (%s): status %d, expected diagnostic "%s"\n' "$name" "$mode" "$status" "$diagnostic" >&2
      cat "$work/stderr" >&2
      return 1
    fi
  done
  ((count += 1))
}

assert_failure orphan-else '{% else %}
' 'unexpected else at line 1'
assert_failure orphan-endif '{% endif %}
' 'unexpected endif at line 1'
assert_failure orphan-endfor '{% endfor %}
' 'unexpected endfor at line 1'
assert_failure mismatched-block '{% if 1 == 1 %}
{% endfor %}
' 'unexpected endfor at line 2 (expected to close if opened at line 1)'
assert_failure duplicate-else '{% if 1 == 1 %}
{% else %}
{% else %}
{% endif %}
' 'duplicate else at line 3 (if opened at line 1)'
assert_failure else-in-for '{% for x in 1 %}
{% else %}
{% endfor %}
' 'unexpected else at line 2 (inside for opened at line 1)'
assert_failure unclosed-for '{% for x in 1 %}
{% if 1 == 1 %}
{% endif %}
' 'unclosed for block opened at line 1'
assert_failure unclosed-if '{% if 1 == 1 %}
' 'unclosed if block opened at line 1'
assert_failure unknown-directive '{% include example %}
' 'invalid directive at line 1'
assert_failure malformed-directive '{% if 1 == 1
' 'invalid directive at line 1'
assert_failure invalid-if-condition 'first
{% if 1 == %}
{% endif %}
' 'invalid Bash syntax at template line 2'
assert_failure invalid-loop '{% for i in 1 2; echo unsafe %}
{% endfor %}
' 'invalid Bash syntax at template line 1'
assert_failure invalid-assignment '{{ broken=(one }}
' 'invalid Bash syntax at template line 1'

# --check and --compile only parse/validate, never evaluate template commands.
marker="$work/runtime-effect"
printf 'effect=$(touch %q; printf done)\n' "$marker" >"$work/valid.tpl"
for mode in --check --compile; do
  bash "$root/shtpl" "$mode" <"$work/valid.tpl" >"$work/output"
  [[ ! -e $marker ]] || { printf 'FAIL F04 unexpected %s side effect\n' "$mode" >&2; exit 1; }
  if [[ $mode == --check ]]; then
    [[ ! -s $work/output ]] || { printf 'FAIL F04 --check emits stdout\n' >&2; exit 1; }
  else
    bash -n "$work/output"
  fi
  ((count += 1))
done
bash "$root/shtpl" <"$work/valid.tpl" >"$work/output"
[[ -e $marker ]] && [[ $(cat "$work/output") == effect=done ]]
((count += 1))

# Invalid Bash anywhere in the template must prevent previous commands executing.
rm -f -- "$marker"
printf 'effect=$(touch %q)\n{{ broken=(one }}\n' "$marker" >"$work/invalid.tpl"
status=0
bash "$root/shtpl" <"$work/invalid.tpl" >"$work/output" 2>"$work/stderr" || status=$?
((status == 2)) && [[ ! -e $marker ]] && [[ ! -s $work/output ]]
((count += 1))

# Validate from stdin and confirm no stdout even for empty input.
: >"$work/empty.tpl"
bash "$root/shtpl" --check <"$work/empty.tpl" >"$work/output"
[[ ! -s $work/output ]]
((count += 1))

printf 'Passed %d F04 validation and diagnostics checks\n' "$count"
