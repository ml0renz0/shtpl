#!/usr/bin/env bash
# Determine the next stable SemVer tag from Conventional Commits on the trunk.
set -euo pipefail

if (($# > 1)); then
  printf 'Usage: %s [REPO_ROOT]\n' "$0" >&2
  exit 2
fi

root=${1:-"$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"}
git -C "$root" rev-parse --verify HEAD >/dev/null

latest=
tag_pattern='^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$'
while IFS= read -r candidate; do
  if [[ $candidate =~ $tag_pattern ]]; then
    latest=$candidate
    break
  fi
done < <(git -C "$root" tag --merged HEAD --list 'v*' --sort=-version:refname)

# This repository has no formal release yet. Bootstrap at v1.0.0.
if [[ -z $latest ]]; then
  printf 'v1.0.0\n'
  exit 0
fi

version=${latest#v}
IFS=. read -r major minor patch <<<"$version"
level=0
commit_pattern='^([[:alpha:]]+)(\([^)]*\))?(!)?:[[:space:]]+'
while IFS= read -r line; do
  if [[ $line =~ ^BREAKING[[:space:]-]CHANGE: ]]; then
    level=3
  elif [[ $line =~ $commit_pattern ]]; then
    kind=${BASH_REMATCH[1]}
    breaking=${BASH_REMATCH[3]}
    if [[ -n $breaking ]]; then
      level=3
    elif [[ $kind == feat ]] && ((level < 2)); then
      level=2
    elif [[ $kind == fix || $kind == perf ]] && ((level < 1)); then
      level=1
    fi
  fi
done < <(git -C "$root" log --format=%B "$latest..HEAD")

case $level in
  3) ((major += 1)); minor=0; patch=0 ;;
  2) ((minor += 1)); patch=0 ;;
  1) ((patch += 1)) ;;
  0) exit 0 ;;
esac
printf 'v%d.%d.%d\n' "$major" "$minor" "$patch"
