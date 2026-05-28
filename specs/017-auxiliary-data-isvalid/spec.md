# Feature Specification: Auxiliary Data Body + isValid RDF

**Feature Branch**: `17-auxiliary-data-isvalid`
**Created**: 2026-05-28
**Status**: Draft
**Input**: Worker brief for issue #17

## User Stories & Tests

### User Story 1 - Reconstruct auxiliary data from RDF (Priority: P1)

As a transaction RDF consumer, I need the transaction's auxiliary data body
emitted as raw CBOR when it is present, so metadata-bearing Conway
transactions can be reconstructed without relying only on the auxiliary-data
hash.

**Independent Test**: Emit a transaction with `auxDataTxL = SJust _` and assert
the RDF contains `cardano:hasAuxiliaryData` pointing to an
`cardano:AuxiliaryData, cardano:OpaqueLeaf` node whose `cardano:hasRawBytes`
matches the ledger CBOR serialization of the auxiliary data.

### User Story 2 - Preserve phase-2 validity flag (Priority: P1)

As a transaction RDF consumer, I need every transaction RDF root to expose
`isValidTxL`, including `IsValid False`, so scripts-failed/collateral-paid
transactions do not silently reconstruct as valid.

**Independent Test**: Emit a transaction with `isValidTxL = IsValid False` and
assert the transaction block contains `cardano:isValid
"false"^^xsd:boolean`.

### User Story 3 - Keep existing fixtures byte-stable except the new flag (Priority: P2)

As a fixture maintainer, I need existing metadata-free goldens regenerated
with only the unconditional `cardano:isValid "true"^^xsd:boolean` delta, so
the change remains reviewable and deterministic.

**Independent Test**: Regenerate the existing `tx-graph` goldens and review
their diffs for the single added `isValid true` predicate on metadata-free
transactions.

## Requirements

- **FR-001**: The emitter MUST write `cardano:isValid` on every
  `cardano:Transaction` subject.
- **FR-002**: `cardano:isValid` MUST be serialized as an `xsd:boolean` literal
  and MUST reflect `isValidTxL`.
- **FR-003**: The emitter MUST write `cardano:hasAuxiliaryData` only when
  `auxDataTxL` is `SJust`.
- **FR-004**: The auxiliary-data node MUST be typed as both
  `cardano:AuxiliaryData` and `cardano:OpaqueLeaf`.
- **FR-005**: The auxiliary-data node MUST carry `cardano:hasRawBytes` equal
  to the ledger CBOR serialization of the auxiliary data body.
- **FR-006**: Existing `cardano:auxiliaryDataHash` emission MUST remain in
  place and continue to use the existing Identifier shape.
- **FR-007**: `vocab/cardano/transactions.ttl` and the local vocab registry
  MUST declare `cardano:isValid`, `cardano:hasAuxiliaryData`, and
  `cardano:AuxiliaryData`.
- **FR-008**: Golden fixtures MUST include at least one auxiliary-data
  transaction and at least one `IsValid False` transaction.
- **FR-009**: The gate script MUST accept the issue #17 task trailer
  `Tasks: T017-S1`.

## Success Criteria

- **SC-001**: `nix develop --quiet -c just unit` exits 0.
- **SC-002**: `nix build .#checks.x86_64-linux.{build,unit,lint,vocab-validate,vocab-owl-smoke}` exits 0.
- **SC-003**: `./gate.sh origin/main..HEAD` exits 0 after the single commit.
- **SC-004**: Review of regenerated goldens confirms pre-existing
  metadata-free fixtures only gained the unconditional `isValid true`
  predicate.

## Clarifications

- The CDDL source is Conway `transaction = [ transaction_body,
  transaction_witness_set, isValid : bool, auxiliary_data / null ]`.
- The ledger sources are `isValidTxL` and `auxDataTxL`.
