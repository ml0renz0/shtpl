#!/usr/bin/env bash
# F08: deterministic generated templates with an independent expected-output oracle.
# shellcheck disable=SC2016
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
seed=${SHTPL_FUZZ_SEED:-20261018}
cases=${SHTPL_FUZZ_CASES:-40}

if [[ ! $seed =~ ^[0-9]{1,9}$ ]] || [[ ! $cases =~ ^[1-9][0-9]*$ ]] || ((cases > 200)); then
  printf 'F08: use SHTPL_FUZZ_SEED (0..999999999) and SHTPL_FUZZ_CASES (1..200)\n' >&2
  exit 2
fi

random_state=$((10#$seed))
choice=0
node_id=0
case_index=0
work=$(mktemp -d)
input=$work/input.tpl
expected=$work/expected
generated=$work/generated.sh
actual=$work/actual

assert_equal() {
  local wanted=$1 got=$2 stage=$3
  if ! cmp -s "$wanted" "$got"; then
    printf 'F08: mismatch in %s\n' "$stage" >&2
    diff -u "$wanted" "$got" >&2 || :
    return 1
  fi
}

cleanup() {
  local status=$?
  if ((status != 0)); then
    printf 'F08 failed: seed=%s case=%d\n' "$seed" "$case_index" >&2
    if [[ -f $input ]]; then
      printf 'Failing template:\n' >&2
      cat -- "$input" >&2
    fi
  fi
  rm -rf -- "$work"
}
trap cleanup EXIT

choose() {
  random_state=$(((random_state * 1103515245 + 12345) & 2147483647))
  choice=$((random_state % $1))
}

leaf() {
  local target=$1
  choose 10
  case $choice in
    0)
      printf '%s\n' 'plain text' >>"$input"
      printf '%s\n' 'plain text' >>"$target"
      ;;
    1)
      printf '%s\n' 'value=$name' >>"$input"
      printf '%s\n' 'value=world' >>"$target"
      ;;
    2)
      printf '%s\n' 'arithmetic=$((2+3)),$((4*5))' >>"$input"
      printf '%s\n' 'arithmetic=5,20' >>"$target"
      ;;
    3)
      printf '%s\n' 'commands=$(printf A),$(printf B)' >>"$input"
      printf '%s\n' 'commands=A,B' >>"$target"
      ;;
    4)
      printf '%s\n' '# $(exit 99) ${UNDEFINED}' >>"$input"
      printf '%s\n' '# $(exit 99) ${UNDEFINED}' >>"$target"
      ;;
    5)
      printf '%s\n' 'unicode=ñ/漢字/🙂' >>"$input"
      printf '%s\n' 'unicode=ñ/漢字/🙂' >>"$target"
      ;;
    6)
      printf '%s\n' 'literal=\$name' >>"$input"
      printf '%s\n' 'literal=$name' >>"$target"
      ;;
    7)
      printf '%s\n' "trailing=\\" >>"$input"
      printf '%s\n' "trailing=\\" >>"$target"
      ;;
    8)
      printf '%s\n' '__SHTPL_00000001__' >>"$input"
      printf '%s\n' '__SHTPL_00000001__' >>"$target"
      ;;
    9)
      printf '\n' >>"$input"
      printf '\n' >>"$target"
      ;;
  esac
}

node() {
  local depth=$1 target=$2 kind scratch
  if ((depth == 0)); then
    leaf "$target"
    return
  fi
  choose 6
  kind=$choice
  case $kind in
    0|1)
      leaf "$target"
      ;;
    2)
      printf '{%% if 1 == 1 %%}\n' >>"$input"
      node "$((depth - 1))" "$target"
      printf '{%% endif %%}\n' >>"$input"
      ;;
    3)
      printf '{%% if 1 == 0 %%}\n' >>"$input"
      printf '%s\n' 'never=$(exit 97)' >>"$input"
      printf '{%% else %%}\n' >>"$input"
      node "$((depth - 1))" "$target"
      printf '{%% endif %%}\n' >>"$input"
      ;;
    4)
      printf '{%% for item in 1 %%}\n' >>"$input"
      node "$((depth - 1))" "$target"
      printf '{%% endfor %%}\n' >>"$input"
      ;;
    5)
      printf '{%% for item in 1 2 %%}\n' >>"$input"
      ((node_id += 1))
      scratch="$work/node-$case_index-$node_id.expected"
      : >"$scratch"
      node "$((depth - 1))" "$scratch"
      cat -- "$scratch" "$scratch" >>"$target"
      printf '{%% endfor %%}\n' >>"$input"
      ;;
  esac
}

for ((case_index = 1; case_index <= cases; case_index++)); do
  printf '%s\n' '{{ name=world }}' >"$input"
  : >"$expected"
  choose 7
  depth=$((choice + 1))
  for ((part = 0; part < 4; part++)); do
    node "$depth" "$expected"
  done

  # A final line without a source newline must still render with a newline.
  if ((case_index % 10 == 0)); then
    printf '%s' 'final-without-eol' >>"$input"
    printf '%s\n' 'final-without-eol' >>"$expected"
  fi

  bash "$root/shtpl" --check -i "$input" >"$work/checked"
  [[ ! -s $work/checked ]]
  bash "$root/shtpl" --compile -i "$input" >"$generated"
  bash -n "$generated"
  bash "$generated" >"$actual"
  cmp "$expected" "$actual"
  bash "$root/shtpl" -i "$input" >"$actual"
  cmp "$expected" "$actual"
  bash "$root/shtpl" --compile -i "$input" >"$work/repeated"
  cmp "$generated" "$work/repeated"

  if ((case_index % 7 == 0)); then
    bash "$root/shtpl" -i "$input" -o "$work/file-output"
    cmp "$expected" "$work/file-output"
  fi

  if ((case_index % 5 == 0)); then
    cp -- "$input" "$work/invalid.tpl"
    # Ensure malformed directive starts on its own line even with no final EOL.\n    printf '\n{%% endfor %%}\n' >>"$work/invalid.tpl"
    status=0
    bash "$root/shtpl" --compile -i "$work/invalid.tpl" >"$work/invalid.stdout" 2>"$work/invalid.stderr" || status=$?
    ((status == 2))
    [[ ! -s $work/invalid.stdout ]]
    grep -Fq 'unexpected endfor' "$work/invalid.stderr"
  fi
done

# Stress both breadth and nesting without relying on wall-clock thresholds.
: >"$input"
for ((depth = 0; depth < 96; depth++)); do
  printf '{%% if 1 == 1 %%}\n{%% for index%d in 1 %%}\n' "$depth" >>"$input"
done
printf 'deep-ok\n' >>"$input"
for ((depth = 95; depth >= 0; depth--)); do
  printf '{%% endfor %%}\n{%% endif %%}\n' >>"$input"
done
bash "$root/shtpl" --check -i "$input"
bash "$root/shtpl" -i "$input" >"$actual"
printf 'deep-ok\n' >"$expected"
cmp "$expected" "$actual"

awk 'BEGIN {for (i = 1; i <= 2048; i++) printf "wide-%05d\n", i}' >"$input"
bash "$root/shtpl" --compile -i "$input" >"$generated"
bash -n "$generated"
bash "$generated" >"$actual"
cmp "$input" "$actual"

printf 'F08: %d generated cases (seed=%s), depth=192 blocks, width=2048 lines: PASS\n' "$cases" "$seed"
