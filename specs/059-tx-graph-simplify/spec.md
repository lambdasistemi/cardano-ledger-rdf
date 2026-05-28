# Feature Specification: tx-graph Single-CBOR Surface

**Feature Branch**: `059-tx-graph-simplify`
**Created**: 2026-05-28
**Status**: Draft
**Input**: Issue #59: remove `tx-graph` batch mode and prove case-study composability.

## User Scenarios & Testing

### User Story 1 - Emit One Transaction Graph

As an operator, I can invoke `tx-graph` with one CBOR path, or `-` for stdin,
and receive one Turtle or JSON-LD graph on stdout or in `--out FILE`.

**Independent Test**: `tx-graph --help` does not list `--in-dir` or
`--out-dir`; one positional CBOR succeeds; multiple positional CBORs fail.

### User Story 2 - Compose A Lattice With Shell Tools

As an operator, I can concatenate single-transaction Turtle outputs to build
a SPARQL-queryable lattice without a special merge mode.

**Independent Test**: Each case study pipeline emits the rules overlay once,
loops over `cbor/*.cbor`, appends `tx-graph "$f"` output, and every fenced
SPARQL query block runs through `arq`.

### User Story 3 - Preserve Case-Study Numbers

As a reviewer, I can compare the old batch-mode lattice against the new
for-loop lattice and see identical query outputs for all three case studies.

**Independent Test**: Record pre-change `arq` outputs, re-run after switching
the pipelines, and compare row counts plus output hashes for every fenced
SPARQL block.

## Requirements

- **FR-001**: `tx-graph` MUST remove `--in-dir DIR`.
- **FR-002**: `tx-graph` MUST remove `--out-dir DIR`.
- **FR-003**: `tx-graph` MUST accept at most one positional CBOR path, with
  `-` meaning stdin.
- **FR-004**: `tx-graph --rules FILE` with no input MUST continue to emit the
  standalone rules overlay to stdout.
- **FR-005**: `--rules FILE`, `--out FILE`, and `--format turtle|json-ld`
  MUST remain supported for single-input mode.
- **FR-006**: Single-input Turtle output MUST remain SPARQL-composable when
  concatenated across transactions.
- **FR-007**: The three checked-in case-study pipelines MUST use the for-loop
  plus concatenation pattern.
- **FR-008**: Every fenced SPARQL block in the three case-study `queries/q*.md`
  files MUST run cleanly via `arq` against the new lattice.
- **FR-009**: The pre-change and post-change query outputs for all three case
  studies MUST match exactly.

## Success Criteria

- **SC-001**: `tx-graph --help` has no `--in-dir` or `--out-dir` text.
- **SC-002**: `nix develop -c just unit` exits 0.
- **SC-003**: The requested Nix checks and MkDocs strict build exit 0.
- **SC-004**: `WIP.md` records per-study baseline/new comparison tables with
  no query output differences.

## Assumptions

- Duplicate overlay triples from looping with `--rules` are RDF-idempotent.
- The operator-recommended pipeline emits the overlay once, then emits bodies
  without `--rules`, so the concatenated file stays smaller.
