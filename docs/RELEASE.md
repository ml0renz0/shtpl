# Releasing shtpl

Stable versions use Semantic Versioning and Conventional Commits. The first
formal release is **v1.0.0**, regardless of the earlier internal v2 redesign.

## Installation

Requirements: Bash 4.4+, GNU coreutils, and a writable temporary directory.

    install -m 755 shtpl "$HOME/.local/bin/shtpl"
    shtpl --version

Only the `shtpl` executable is required for installation.

## Trunk-based delivery

1. Changes arrive through short-lived PRs targeting `main`; PR CI validates
   Bash 4.4 compatibility, functional tests and distribution packaging.
2. A merge to `main` triggers the release workflow automatically. There is no
   separate push-triggered CI on feature branches.
3. If no release tag exists, the workflow bootstraps **v1.0.0**.
   Otherwise it compares commit messages since the latest reachable stable
   SemVer tag:
   - `fix:` and `perf:` trigger PATCH.
   - `feat:` triggers MINOR.
   - `type!:` and `BREAKING CHANGE:` trigger MAJOR.
   - Docs, chores and other non-releasable commits do not publish a release.
4. On a releasable merge, the workflow updates `SHTPL_VERSION` and
   `CHANGELOG.md`, creates a version commit, reruns release validation, and
   pushes the version commit plus an annotated tag.
5. After validation, it builds the deterministic source archive and SHA-256
   manifest and publishes the GitHub Release automatically.

No manual version bump or tag creation is required. `workflow_dispatch` allows
a failed publication to be retried. The workflow serializes release attempts,
and ordinary `GITHUB_TOKEN` pushes do not recursively trigger Actions runs.

## Requirements and recovery

The release job needs `contents: write` and permission to push a version
commit and tag. If branch protection later prevents GitHub Actions from pushing
to `main`, adopt an approved bot bypass or change to a release-PR flow.
Require a passing CI on PRs in repository branch protection settings.

If publication fails after committing or tagging, inspect the Actions run
before retrying; never force-push or recreate a published version tag. The
workflow's version calculation is based on stable tags and should be rerun via
`workflow_dispatch` after resolving the failure.

## Testability

`bash tests/versioning-smoke.sh` checks bootstrap, no-op, PATCH, MINOR,
MAJOR and breaking-change decisions using local temporary Git histories.

`bash tests/release-smoke.sh` builds two packages from identical tracked
sources, checks byte-for-byte reproducibility and SHA-256 manifests, extracts
the archive, tests the executable and rejects invalid or mismatched tags.

This release mechanism never executes untrusted templates; it runs only
tracked trusted repository fixtures.
