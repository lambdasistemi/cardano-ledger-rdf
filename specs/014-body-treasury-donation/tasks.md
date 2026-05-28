# Tasks: Body Treasury Value And Donation RDF

**Input**: Design documents from `/specs/014-body-treasury-donation/`
**Prerequisites**: plan.md, spec.md

**Tests**: Required. This is a behavior-changing public RDF output slice.

## Phase 1: Tests And Fixtures

- [X] T014-S1 [US1] Add failing body-root tests for `cardano:hasCurrentTreasuryValue`, `cardano:hasDonation`, and absent/default elision in `test/Cardano/Tx/Graph/Emit/BodyRootSpec.hs`.
- [X] T014-S1 [US1] Add tx-graph fixtures 27 and 28 plus golden-suite wiring in `test/fixtures/tx-graph/` and `test/Cardano/Tx/Graph/EmitGoldenSpec.hs`.

## Phase 2: Implementation

- [X] T014-S1 [US1] Read `currentTreasuryValueTxBodyL` and `treasuryDonationTxBodyL` in `src/Cardano/Tx/Graph/Emit/Project.hs` and emit integer triples on `_:tx` only when present/non-zero.
- [X] T014-S1 [US1] Add `TermHasCurrentTreasuryValue` and `TermHasDonation` to `src/Cardano/Tx/Graph/Emit/Vocab.hs`.
- [X] T014-S1 [US1] Declare both predicates with transaction domain and integer range in `vocab/cardano/transactions.ttl` and canonical-vocab fixtures.

## Phase 3: Verification And Gate

- [X] T014-S1 [US1] Extend `gate.sh` task regex with `T014-S1`.
- [X] T014-S1 [US1] Run `nix develop -c just unit`, `nix build .#checks.x86_64-linux.{build,unit,lint,vocab-validate,vocab-owl-smoke}`, and `./gate.sh origin/main..HEAD`.

## Dependencies & Execution Order

- Tests and fixture wiring precede production emitter changes.
- Vocab registry, local vocabulary, and canonical-vocab fixtures must land with the emitter change so traceability remains strict.
- Verification runs after all source, fixture, vocabulary, and gate edits.

## Implementation Strategy

One bisect-safe commit closes all tasks. The commit body carries `Tasks: T014-S1`.
