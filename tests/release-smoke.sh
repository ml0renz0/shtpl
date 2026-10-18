#!/usr/bin/env bash
# Verify the exact release packaging path without publishing a tag.
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT

version=$(bash "$root/shtpl" --version)
version=${version#shtpl }
tag="v$version"
for target in "$work/dist1" "$work/dist2"; do
  bash "$root/scripts/package-release.sh" "$tag" "$target"
  (cd -- "$target" && sha256sum -c SHA256SUMS)
done

archive="shtpl-$version.tar.gz"
cmp "$work/dist1/$archive" "$work/dist2/$archive"
cmp "$work/dist1/SHA256SUMS" "$work/dist2/SHA256SUMS"
mkdir -p -- "$work/unpacked"
tar -xzf "$work/dist1/$archive" -C "$work/unpacked"
package="$work/unpacked/shtpl-$version"
for required in shtpl README.md LICENSE CHANGELOG.md docs/RELEASE.md; do
  [[ -f "$package/$required" ]]
done
[[ -x "$package/shtpl" ]]
[[ ! -e "$package/tests" ]]
[[ $(bash "$package/shtpl" --version) == "shtpl $version" ]]
printf '%s\n' 'release smoke' | bash "$package/shtpl" > "$work/rendered"
grep -qx 'release smoke' "$work/rendered"

for invalid in 'v01.2.3' 'v0.0.0-not-a-release' 'not-a-tag'; do
  if bash "$root/scripts/package-release.sh" "$invalid" "$work/invalid" >/dev/null 2>&1; then
    printf 'Unexpectedly accepted tag %s\n' "$invalid" >&2
    exit 1
  fi
done
if [[ $tag != v0.0.0 ]]; then
  if bash "$root/scripts/package-release.sh" v0.0.0 "$work/mismatch" >/dev/null 2>&1; then
    printf 'Unexpectedly accepted a mismatched version\n' >&2
    exit 1
  fi
fi
printf 'Release packaging and checksum smoke checks passed\n'
