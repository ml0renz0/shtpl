#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
name="${1:?usage: assert-fixture.sh <fixture-name>}"
input="$root/tests/fixtures/$name.tpl"
expected="$root/tests/fixtures/$name.expected"

if [[ ! -f "$input" || ! -f "$expected" ]]; then
  printf 'Missing fixture or expectation for %s\n' "$name" >&2
  exit 2
fi

actual="$(mktemp)"
trap 'rm -f "$actual"' EXIT

if ! bash "$root/shtpl" < "$input" > "$actual"; then
  printf 'SHTPL failed for %s\n' "$name" >&2
  exit 1
fi

diff -u "$expected" "$actual"
