# Tasks: Symmetric Linux Release Artifacts

## Slice 1 - Spec Kit Scaffold

- [X] T70-S1 Read the worker brief, issue #70, repository constitution, and
  relevant release files; create spec, plan, and task artifacts.

## Slice 2 - Nix Linux Artifact Matrix

- [ ] T70-S2 Pin `dev-assets` to the required commit and refresh `flake.lock`
  while preserving the compatible `NixOS/bundlers` revision.
- [ ] T70-S2 Add `aarch64-linux` to `systems`.
- [ ] T70-S2 Add per-system musl component selection for `x86_64-linux` and
  `aarch64-linux`.
- [ ] T70-S2 Replace the local Linux release derivation with
  `inputs.dev-assets.lib.mkLinuxArtifacts`.
- [ ] T70-S2 Replace the local Linux artifact smoke app with
  `inputs.dev-assets.lib.mkLinuxArtifactSmoke`.
- [ ] T70-S2 Delete `nix/linux-release.nix` and
  `nix/linux-artifact-smoke.nix`.
- [ ] T70-S2 Verify the new Nix outputs with targeted eval/build commands.
- [ ] T70-S2 Commit one bisect-safe Nix slice with `Tasks: T70-S2`.

## Slice 3 - GitHub Actions Arm Matrix

- [ ] T70-S3 Add the release workflow architecture matrix for `x86_64` and
  `aarch64`.
- [ ] T70-S3 Use runner-specific Nix setup with `cachix/cachix-action@v17`
  on `nixos` and `paolino/dev-assets/setup-nix` on arm.
- [ ] T70-S3 Pin `paolino/dev-assets` workflow actions to the required
  `b901b08ce8d2e290d84e323486f7fa216b190df9` commit.
- [ ] T70-S3 Add the `aarch64-eval` CI job with the GHC source-build guard.
- [ ] T70-S3 Verify workflow syntax and push the draft PR branch.
- [ ] T70-S3 Commit one bisect-safe workflow slice with `Tasks: T70-S3`.

## Final PR Proof

- [ ] T70-F1 Build local x86_64 Linux release artifacts for the requested
  executables.
- [ ] T70-F1 Open or update the draft PR for issue #70.
- [ ] T70-F1 Confirm GitHub Actions is green for the x86_64 and aarch64
  release matrix plus `aarch64-eval`.
- [ ] T70-F1 Append `COMPLETE` with the PR URL after the full matrix is green.
