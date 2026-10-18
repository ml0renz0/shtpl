#!/usr/bin/env bash
# Build and checksum the exact tracked sources for a release.
set -euo pipefail

if (($# != 2)); then
  printf 'Usage: %s TAG DIST_DIR\n' "$0" >&2
  exit 2
fi

tag=$1
dist_dir=$2
if [[ ! $tag =~ ^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]; then
  printf 'shtpl: invalid release tag: %s\n' "$tag" >&2
  exit 2
fi

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd -- "$repo_root"
version=${tag#v}
if [[ $(bash shtpl --version) != "shtpl $version" ]]; then
  printf 'shtpl: tag %s does not match executable version\n' "$tag" >&2
  exit 2
fi

mkdir -p -- "$dist_dir"
git archive --format=tar --prefix="shtpl-$version/" HEAD shtpl README.md LICENSE docs CHANGELOG.md |
  gzip -n -9 > "$dist_dir/shtpl-$version.tar.gz"
(cd -- "$dist_dir" && sha256sum "shtpl-$version.tar.gz" > SHA256SUMS)
