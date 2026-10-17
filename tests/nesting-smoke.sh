#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT
count=0

for fixture in "$root"/tests/fixtures/f02/*.tpl; do
  expected="${fixture%.tpl}.expected"
  bash "$root/shtpl" --compile <"$fixture" >"$work/generated.sh"
  bash -n "$work/generated.sh"
  bash "$work/generated.sh" >"$work/output"
  diff -u "$expected" "$work/output"
  bash "$root/shtpl" <"$fixture" >"$work/output"
  diff -u "$expected" "$work/output"
  ((count += 1))
done

# Alternate 32 nested conditionals/loops to verify depth is not hard-coded.
for ((depth = 0; depth < 16; depth++)); do
  printf '{%% for idx%d in 1 %%}\n' "$depth" >>"$work/deep.tpl"
  printf '{%% if %sidx%d == 1 %%}\n' '$' "$depth" >>"$work/deep.tpl"
done
printf 'deep=ok\n' >>"$work/deep.tpl"
for ((depth = 15; depth >= 0; depth--)); do
  printf '{%% endif %%}\n{%% endfor %%}\n' >>"$work/deep.tpl"
done
printf 'deep=ok\n' >"$work/deep.expected"
bash "$root/shtpl" --compile <"$work/deep.tpl" >"$work/generated.sh"
bash -n "$work/generated.sh"
bash "$work/generated.sh" >"$work/output"
diff -u "$work/deep.expected" "$work/output"
bash "$root/shtpl" <"$work/deep.tpl" >"$work/output"
diff -u "$work/deep.expected" "$work/output"
((count += 1))

assert_compile_error() {
  local name=$1 expected=$2 status=0
  bash "$root/shtpl" --compile <"$work/$name.tpl" >"$work/generated.sh" 2>"$work/error" || status=$?
  if (( status != 2 )) || ! grep -Fq -- "$expected" "$work/error"; then
    printf 'Expected exit 2 with "%s" for %s; got exit %d:\n' "$expected" "$name" "$status" >&2
    cat "$work/error" >&2
    return 1
  fi
  ((count += 1))
}

printf '{%% else %%}\n' >"$work/orphan-else.tpl"
assert_compile_error orphan-else 'unexpected else at line 1'
printf '{%% endif %%}\n' >"$work/orphan-endif.tpl"
assert_compile_error orphan-endif 'unexpected endif at line 1'
printf '{%% endfor %%}\n' >"$work/orphan-endfor.tpl"
assert_compile_error orphan-endfor 'unexpected endfor at line 1'
printf '{%% if 1 == 1 %%}\n{%% endfor %%}\n' >"$work/mismatch.tpl"
assert_compile_error mismatch 'unexpected endfor at line 2'
printf '{%% if 1 == 1 %%}\n{%% else %%}\n{%% else %%}\n{%% endif %%}\n' >"$work/duplicate-else.tpl"
assert_compile_error duplicate-else 'duplicate else at line 3'
printf '{%% for x in 1 %%}\n{%% else %%}\n{%% endfor %%}\n' >"$work/else-in-for.tpl"
assert_compile_error else-in-for 'unexpected else at line 2'
printf '{%% for x in 1 %%}\n{%% if 1 == 1 %%}\n{%% endif %%}\n' >"$work/unclosed.tpl"
assert_compile_error unclosed 'unclosed for block'

printf 'Passed %d F02 nesting and structural checks\n' "$count"
