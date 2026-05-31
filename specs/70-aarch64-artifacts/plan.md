# Implementation Plan: Symmetric Linux Release Artifacts

**Branch**: `feat/add-aarch64-linux-artifacts-appimage-musl-via-dev-`
**Spec**: `specs/70-aarch64-artifacts/spec.md`

## Technical Context

**Language/Version**: Haskell, GHC 9.12.3 via `haskell.nix`
**Primary Dependencies**: `haskell.nix`, `flake-parts`, `NixOS/bundlers`,
`paolino/dev-assets`
**Testing**: Nix evaluation, local x86_64 Linux artifact builds, GitHub
Actions arm evaluation and release matrix smoke
**Project Type**: Haskell library plus CLI executables and release packaging

## Constitution Check

- Cardano RDF product boundary: PASS. This only changes packaging for the RDF
  executables owned by this repository.
- Stable vocabulary and reproducible graphs: PASS. No RDF vocabulary or graph
  serialization behavior changes.
- Offline determinism and network boundaries: PASS. CLI behavior is unchanged;
  release workflows use explicit GitHub Actions network setup.
- Hackage-ready Haskell packages: PASS. No package metadata or source package
  behavior changes.
- Spec-first, test-driven, verified changes: PASS. This spec, plan, and task
  list define the slices before implementation. For release packaging, RED is
  represented by evaluating/building the old missing outputs before GREEN
  wiring and then rerunning the concrete artifact gates.
- Migration without premature deletion: PASS. No `cardano-tx-tools` source is
  deleted or modified.

## Slice Breakdown

### Slice 1 - Spec Kit Scaffold

Create this `spec.md`, `plan.md`, and `tasks.md` set. Record the target
artifact matrix, pin choices, local proof limits, and CI proof obligations.

### Slice 2 - Nix Linux Artifact Matrix

Pin `dev-assets` to `b901b08ce8d2e290d84e323486f7fa216b190df9`, add
`aarch64-linux` to `systems`, derive per-system musl executables from
`project.projectCross`, call `inputs.dev-assets.lib.mkLinuxArtifacts`, switch
the smoke app to `inputs.dev-assets.lib.mkLinuxArtifactSmoke`, update
`flake.lock`, and remove the obsolete per-repository Linux release Nix files.

### Slice 3 - GitHub Actions Arm Matrix

Update `.github/workflows/release.yml` to run the Linux release action across
`x86_64` and `aarch64` runners with runner-specific Nix setup. Update
`.github/workflows/ci.yml` with the arm dry-run cache gate for
`.#packages.aarch64-linux.cq-rdf`.

## Local Verification Plan

1. Evaluate old missing aarch64 output or removed lib references as the RED
   signal where practical.
2. Run `nix flake show` or targeted `nix eval` for the new outputs after
   each Nix slice.
3. Run local x86_64 Linux artifact builds for `cq-rdf` and `tx-view` release
   outputs to prove the glibc packages, musl tarballs, and shared smoke app.
4. Push the branch and use GitHub Actions for native aarch64 proof.

## Risks

- aarch64 CI may cold-build dependencies on the first run. The CI cache gate
  must fail fast if GHC itself would be built from source.
- Static musl linking may expose a missing static library. If that happens,
  stop and write a parent Q-file rather than patching `dev-assets` or copying
  `cardano-tx-tools`-specific fixes blindly.
- The branch name currently tracks `origin/main`; force pushes must use
  `--force-with-lease` only after confirming the PR branch exists remotely.
