#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
count=0

for fixture in "$root"/tests/fixtures/*.tpl; do
  name="$(basename "${fixture%.tpl}")"
  printf 'Checking %s ... ' "$name"
  bash "$root/tests/assert-fixture.sh" "$name"
  printf 'OK\n'
  ((count += 1))
done

printf 'Passed %d baseline fixtures\n' "$count"
