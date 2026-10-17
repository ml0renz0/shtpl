#!/usr/bin/env bash
# F05 regression checks: private temp files, cleanup, signals, and input integrity.
# shellcheck disable=SC2016
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT
tmp_root="$work/tmp with spaces"
mkdir -p "$tmp_root"
export TMPDIR="$tmp_root"
count=0

assert_clean() {
  [[ -z $(find "$tmp_root" -mindepth 1 -maxdepth 1 -print -quit) ]]
}

# Permission checks are performed from the executing generated script.
export MODES="$work/modes"
cat >"$work/input" <<'EOF'
{{ probe=$(stat -c %a "$(dirname "$0")" > "$MODES"; stat -c %a "$0" >> "$MODES"; stat -c %a "$(dirname "$0")/diagnostics" >> "$MODES") }}
EOF
bash "$root/shtpl" <"$work/input" >"$work/out"
[[ $(sed -n '1p' "$MODES") == 700 ]]
[[ $(sed -n '2p' "$MODES") == 600 ]]
[[ $(sed -n '3p' "$MODES") == 600 ]]
assert_clean
((count += 1))

printf '%s\n' '{% if 1 == %}' >"$work/broken"
for mode in --check --compile execute; do
  status=0
  if [[ $mode == execute ]]; then
    bash "$root/shtpl" <"$work/broken" >"$work/out" 2>"$work/err" || status=$?
  else
    bash "$root/shtpl" "$mode" <"$work/broken" >"$work/out" 2>"$work/err" || status=$?
  fi
  ((status == 2))
  [[ ! -s $work/out ]]
  assert_clean
  ((count += 1))
done

status=0
TMPDIR="$work/missing" bash "$root/shtpl" --check <"$work/input" >"$work/out" 2>"$work/err" || status=$?
((status == 1))
grep -q 'cannot create temporary workspace' "$work/err"
[[ ! -s $work/out ]]
((count += 1))

printf '%s\n' '{{ result=$(exit 23) }}' >"$work/input"
status=0
bash "$root/shtpl" <"$work/input" >"$work/out" || status=$?
((status == 23))
assert_clean
((count += 1))

check_bytes() {
  local name=$1
  bash "$root/shtpl" --check <"$work/input" >"$work/checked"
  [[ ! -s $work/checked ]]
  bash "$root/shtpl" --compile <"$work/input" >"$work/generated"
  bash -n "$work/generated"
  bash "$root/shtpl" <"$work/input" >"$work/out"
  cmp "$work/expected" "$work/out"
  bash "$work/generated" >"$work/out"
  cmp "$work/expected" "$work/out"
  assert_clean
  ((count += 1))
  printf 'PASS F05 %s\n' "$name"
}
printf '%s\n' '__SHTPL_00000001__' >"$work/input"
cp "$work/input" "$work/expected"
check_bytes marker-collision
cat >"$work/input" <<'EOF'
ñ/漢字/🙂
# $(exit 99) `echo fail` ${MISSING}
slash=\
EOF
cp "$work/input" "$work/expected"
check_bytes unicode-literals-backslash
printf '%s' 'last line' >"$work/input"
printf '%s\n' 'last line' >"$work/expected"
check_bytes no-final-newline

awk 'BEGIN {for (i = 1; i <= 4096; i++) printf "line-%05d:%0200d\n", i, i}' >"$work/input"
cp "$work/input" "$work/expected"
check_bytes large-template

# TERM/HUP delivered to the wrapper rather than its process group.
export PIDFILE="$work/runner-pid"
cat >"$work/input" <<'EOF'
{{ pid=$BASHPID }}
{{ logged=$(printf '%s\n' "$pid" > "$PIDFILE") }}
{% for ((;;)) %}
{{ tick=$(sleep 0.05) }}
{% endfor %}
EOF
for signal in TERM HUP; do
  rm -f "$PIDFILE"
  bash "$root/shtpl" <"$work/input" >"$work/out" 2>"$work/err" &
  wrapper=$!
  for ((i = 0; i < 100; i++)); do
    [[ -s $PIDFILE ]] && break
    sleep 0.05
  done
  if [[ ! -s $PIDFILE ]]; then
    kill -TERM "$wrapper" 2>/dev/null || :
    wait "$wrapper" || :
    echo "F05: runner did not start" >&2
    exit 1
  fi
  runner=$(cat "$PIDFILE")
  kill -s "$signal" "$wrapper"
  status=0
  wait "$wrapper" || status=$?
  if [[ $signal == TERM ]]; then
    ((status == 143))
  else
    ((status == 129))
  fi
  if kill -0 "$runner" 2>/dev/null; then
    printf 'F05: runner survived %s\n' "$signal" >&2
    exit 1
  fi
  assert_clean
  ((count += 1))
done
printf 'Passed %d F05 robustness checks\n' "$count"
