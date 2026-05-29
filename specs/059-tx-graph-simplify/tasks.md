# Tasks: tx-graph Single-CBOR Surface

## Setup

- [X] T059-S1-001 Read constitution, worker brief, and issue #59.
- [X] T059-S1-002 Build the pre-change `tx-graph` executable.
- [X] T059-S1-003 Fetch or reuse CBORs for the three case studies.

## Baseline Proof

- [X] T059-S1-004 Emit old batch-mode lattices for all three case studies.
- [X] T059-S1-005 Run every fenced SPARQL block via `arq`.
- [X] T059-S1-006 Record baseline row counts and hashes in `WIP.md`.

## Implementation

- [X] T059-S1-007 Remove `--in-dir` and `--out-dir` from `app/tx-graph/Main.hs`.
- [X] T059-S1-008 Reject multiple positional CBOR inputs.
- [X] T059-S1-009 Preserve overlay-only, `--rules`, `--out`, and `--format`.
- [X] T059-S1-010 Update CLI smoke tests for the simplified surface.
- [X] T059-S1-011 Switch all three case-study pipelines to the for-loop pattern.
- [X] T059-S1-012 Update `docs/tx-graph.md` and related docs.
- [X] T059-S1-013 Update `CHANGELOG.md` and `gate.sh`.

## Post-Change Proof

- [X] T059-S1-014 Rebuild `tx-graph`.
- [X] T059-S1-015 Re-run the switched pipelines or equivalent local lattice emission.
- [X] T059-S1-016 Re-run every fenced SPARQL block via `arq`.
- [X] T059-S1-017 Compare pre/post row counts and hashes for every query.
- [X] T059-S1-018 Record the comparison table in `WIP.md`.

## Verification

- [X] T059-S1-019 Verify `tx-graph --help` excludes removed flags.
- [X] T059-S1-020 Run `nix develop -c just unit`.
- [X] T059-S1-021 Run requested Nix checks.
- [X] T059-S1-022 Run `nix develop -c mkdocs build --strict`.
- [X] T059-S1-023 Run `./gate.sh origin/main..HEAD`.
- [X] T059-S1-024 Commit one bisect-safe slice with `Tasks: T059-S1`.
