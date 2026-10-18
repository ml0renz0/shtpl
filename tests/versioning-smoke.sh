#!/usr/bin/env bash
# Conventional-commit version selection: first, patch, minor, major and no-op.
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
repo="$work/repo"
git init -q "$repo"
git -C "$repo" config user.name 'shtpl CI'
git -C "$repo" config user.email 'ci@example.invalid'
printf 'baseline\n' >"$repo/file"
git -C "$repo" add file
git -C "$repo" commit -qm 'chore: initialize'
[[ $(bash "$root/scripts/next-version.sh" "$repo") == v1.0.0 ]]

git -C "$repo" tag -am initial v1.0.0
[[ -z $(bash "$root/scripts/next-version.sh" "$repo") ]]
git -C "$repo" commit -q --allow-empty -m 'docs: update README'
[[ -z $(bash "$root/scripts/next-version.sh" "$repo") ]]

git -C "$repo" commit -q --allow-empty -m 'fix(cli): correct output'
[[ $(bash "$root/scripts/next-version.sh" "$repo") == v1.0.1 ]]
git -C "$repo" tag -am patch v1.0.1

git -C "$repo" commit -q --allow-empty -m 'feat(cli): support another option'
[[ $(bash "$root/scripts/next-version.sh" "$repo") == v1.1.0 ]]
git -C "$repo" tag -am minor v1.1.0

git -C "$repo" commit -q --allow-empty -m 'refactor: change API' -m 'BREAKING CHANGE: contract altered'
[[ $(bash "$root/scripts/next-version.sh" "$repo") == v2.0.0 ]]
git -C "$repo" tag -am major v2.0.0

git -C "$repo" commit -q --allow-empty -m 'feat(parser)!: remove legacy grammar'
[[ $(bash "$root/scripts/next-version.sh" "$repo") == v3.0.0 ]]
git -C "$repo" tag -am next-major v3.0.0

git -C "$repo" commit -q --allow-empty -m 'Merge pull request #123' -m 'fix: repair exit code'
[[ $(bash "$root/scripts/next-version.sh" "$repo") == v3.0.1 ]]
printf 'Versioning smoke checks passed\n'
