# Releasing shtpl v2

The source of truth for v2 is SHTPL_VERSION in the shtpl executable.

## Installation

Requirements: Bash 4.4+, GNU coreutils, and a writable temporary directory.

    install -m 755 shtpl "$HOME/.local/bin/shtpl"
    shtpl --version

Only the shtpl executable is required for installation.

## Procedure

1. Merge the validated PR to main after reviewing CI.
2. Verify shtpl --version and update SHTPL_VERSION for later releases.
3. Create an annotated v2.0.0 tag on the intended main commit and push that tag.
4. The tag workflow verifies version and ancestry, runs regression tests,
   creates a reproducible tarball and SHA-256 checksum, and publishes a release.

No PR or normal branch push creates a release.
