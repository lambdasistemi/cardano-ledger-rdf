# Feature Specification: Symmetric Linux Release Artifacts

**Feature Branch**: `feat/add-aarch64-linux-artifacts-appimage-musl-via-dev-`
**Created**: 2026-05-31
**Status**: Draft
**Input**: Issue #70: add aarch64-linux artifacts via the shared dev-assets
Linux release library.

## User Scenarios & Testing

### User Story 1 - Download Arm64 Linux Artifacts

As an `aarch64-linux` user, I can download AppImage, DEB, RPM, and static
musl tarball artifacts for `cq-rdf` and `tx-view` from release automation.

**Independent Test**: The release workflow runs the Linux bundle matrix on
`ubuntu-24.04-arm`, uploads per-executable aarch64 artifacts, and smokes the
artifact contents through the shared `dev-assets` action.

### User Story 2 - Preserve Existing Linux Artifacts

As an `x86_64-linux` user, I continue to receive AppImage, DEB, RPM, and
static musl tarball artifacts for `cq-rdf` and `tx-view`.

**Independent Test**: Local `nix build` of the x86_64 Linux release artifact
outputs succeeds and produces the shared artifact layout.

### User Story 3 - Keep Darwin Homebrew Unchanged

As a macOS user, I continue to receive the existing Darwin Homebrew artifacts
without Linux artifact refactoring changing their packages or formulas.

**Independent Test**: The implementation does not alter Darwin Homebrew
workflow wiring or the Darwin package definitions except where shared local
helpers remain referenced unchanged.

## Requirements

- **FR-001**: `flake.nix` MUST include `aarch64-linux` in the flake systems.
- **FR-002**: `flake.nix` MUST replace the per-repository Linux release
  derivation with `inputs.dev-assets.lib.mkLinuxArtifacts`.
- **FR-003**: The shared Linux artifact call MUST pass `pkgs`, `system`,
  executable name, package version, the glibc executable package, the raw
  musl executable package, and `inputs.bundlers`.
- **FR-004**: The Linux artifact smoke app MUST come from
  `inputs.dev-assets.lib.mkLinuxArtifactSmoke`.
- **FR-005**: `nix/linux-release.nix` and `nix/linux-artifact-smoke.nix` MUST
  be removed after their replacements are wired.
- **FR-006**: Static musl executables MUST be selected from
  `project.projectCross.musl64` on `x86_64-linux` and
  `project.projectCross.aarch64-multiplatform-musl` on `aarch64-linux`.
- **FR-007**: The musl package passed to the shared Linux artifact library
  MUST be the raw executable output, not the glibc wrapper.
- **FR-008**: `dev-assets` MUST be pinned to
  `b901b08ce8d2e290d84e323486f7fa216b190df9`.
- **FR-009**: The `bundlers` input MUST remain compatible with the
  `dev-assets` pin and resolve to the `NixOS/bundlers` `7bb70086` revision.
- **FR-010**: `.github/workflows/release.yml` MUST add an architecture matrix
  covering `x86_64` on `nixos` and `aarch64` on `ubuntu-24.04-arm`.
- **FR-011**: The release workflow MUST use `cachix/cachix-action@v17` on the
  self-hosted `nixos` runner and `paolino/dev-assets/setup-nix` on the arm
  runner.
- **FR-012**: `.github/workflows/ci.yml` MUST add an `aarch64-eval` job that
  dry-runs `.#packages.aarch64-linux.cq-rdf` and fails if GHC would be built
  from source.
- **FR-013**: Existing Darwin Homebrew release wiring MUST remain in place.
- **FR-014**: The implementation MUST NOT add `cardano-tx-tools`-specific
  rocksdb, blockio, liburing, or numactl fixes unless a local link failure
  proves the need.

## Success Criteria

- **SC-001**: x86_64 local `nix build` of Linux release artifacts exits 0 for
  the release executable set that can be built on this machine.
- **SC-002**: The aarch64 evaluation CI job exits 0 on `ubuntu-24.04-arm`.
- **SC-003**: The Linux release workflow is green for both `x86_64` and
  `aarch64` matrix entries in the draft PR.
- **SC-004**: `nix/linux-release.nix` and `nix/linux-artifact-smoke.nix` no
  longer exist at HEAD.
- **SC-005**: The PR remains draft until the parent verifies and merges.

## Assumptions

- `cardano-ledger-rdf` has no rocksdb dependency, so the static musl link does
  not need the `cardano-tx-tools` rocksdb static-link module.
- Native aarch64 Linux evaluation and artifact builds are proven in GitHub
  Actions because this x86_64 worktree has no arm builder.
- `tx-graph` remains a compatibility executable in this repository, but the
  target symmetric artifact acceptance is for `cq-rdf` and `tx-view`.
