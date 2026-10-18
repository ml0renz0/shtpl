#!/usr/bin/env bash
# F08: informative benchmark. No performance thresholds in CI.
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT

command -v /usr/bin/time >/dev/null 2>&1 || {
  printf 'F08 benchmark needs GNU /usr/bin/time\n' >&2
  exit 2
}

repetitions=${SHTPL_BENCH_REPETITIONS:-3}
if [[ ! $repetitions =~ ^[1-9][0-9]*$ ]] || ((repetitions > 20)); then
  printf 'F08: repetitions must be 1..20\n' >&2
  exit 2
fi
printf 'environment: %s\n' "$(bash --version | head -n 1)"
printf 'case,mode,iteration,wall_seconds,max_rss_kb,output_bytes\n'

for size in 128 1024 4096; do
  template="$work/$size.tpl"
  awk -v size="$size" 'BEGIN {for (i = 1; i <= size; i++) printf "line-%05d: $((2+3))\n", i}' >"$template"
  for mode in check compile render; do
    for ((iteration = 1; iteration <= repetitions; iteration++)); do
      output="$work/output"
      timings="$work/time"
      case $mode in
      check)
        /usr/bin/time -f '%e,%M' -o "$timings" bash "$root/shtpl" --check -i "$template" >"$output"
        ;;
      compile)
        /usr/bin/time -f '%e,%M' -o "$timings" bash "$root/shtpl" --compile -i "$template" >"$output"
        ;;
      render)
        /usr/bin/time -f '%e,%M' -o "$timings" bash "$root/shtpl" -i "$template" >"$output"
        ;;
      esac
      printf '%s,%s,%d,%s,%s\n' "$size" "$mode" "$iteration" "$(cat "$timings")" "$(wc -c <"$output" | tr -d ' ')"
    done
  done
done
