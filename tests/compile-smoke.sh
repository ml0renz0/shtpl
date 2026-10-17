#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT
count=0

for fixture in "$root"/tests/fixtures/*.tpl; do
  expected="${fixture%.tpl}.expected"

  bash "$root/shtpl" --compile < "$fixture" > "$work/generated.sh"
  bash -n "$work/generated.sh"
  bash "$work/generated.sh" > "$work/rendered"
  cmp -s "$expected" "$work/rendered" || {
    diff -u "$expected" "$work/rendered"
    exit 1
  }

  # Compiling the same input must yield identical bytes.
  bash "$root/shtpl" --compile < "$fixture" > "$work/repeated.sh"
  cmp -s "$work/generated.sh" "$work/repeated.sh"
  ((count += 1))
done

printf 'Compiled and checked %d baseline fixtures\n' "$count"
