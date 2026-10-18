#!/usr/bin/env bash
# Commit-ready version and changelog update (does not tag or publish).
set -euo pipefail

if (($# != 1)) || [[ ! $1 =~ ^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]; then
  printf 'Usage: %s vMAJOR.MINOR.PATCH\n' "$0" >&2
  exit 2
fi

tag=$1
version=${tag#v}
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd -- "$root"
[[ $(grep -c '^SHTPL_VERSION=' shtpl) == 1 ]]
sed -i -E "s/^SHTPL_VERSION=[0-9]+\.[0-9]+\.[0-9]+$/SHTPL_VERSION=$version/" shtpl
[[ $(bash shtpl --version) == "shtpl $version" ]]

if grep -Fqx "## $version (pending release tag)" CHANGELOG.md; then
  sed -i "s/^## $version (pending release tag)$/## $version/" CHANGELOG.md
elif ! grep -Fqx "## $version" CHANGELOG.md; then
  temp=$(mktemp)
  trap 'rm -f -- "$temp"' EXIT
  {
    printf '# Changelog\n\n## %s\n\n' "$version"
    latest=
    while IFS= read -r candidate; do
      if [[ $candidate =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        latest=$candidate
        break
      fi
    done < <(git tag --merged HEAD --list 'v*' --sort=-version:refname)
    count=0
    if [[ -n $latest ]]; then
      while IFS= read -r subject; do
        if [[ $subject =~ ^(feat|fix|perf|refactor)(\([^)]*\))?(!)?: ]]; then
          printf -- '- %s\n' "$subject"
          ((count += 1))
        fi
      done < <(git log --no-merges --format=%s "$latest..HEAD")
    fi
    if ((count == 0)); then
      printf '%s\n' '- See the GitHub Release for generated change notes.'
    fi
    printf '\n'
    tail -n +2 CHANGELOG.md
  } >"$temp"
  cat -- "$temp" > CHANGELOG.md
fi
