# Feature Specification: per-entity network literals

**Feature Branch**: `feat/per-entity-network`  
**Created**: 2026-06-29  
**Status**: Draft  
**Input**: GitHub issue #96: emit a flat per-entity network literal so
downstream inspector SHACL can validate every network-bearing output/account
against the expected chain.

## User Scenarios & Testing

### User Story 1 - Inspector network validation input (Priority: P1)

The transaction RDF graph exposes the network of every output address and
reward-account-like body target as a flat integer literal so the downstream
inspector can run network-consistency SHACL without parsing bech32 strings.

**Why this priority**: The body root already emits `cardano:networkId` for the
optional transaction body field. That is not enough for validating individual
outputs, withdrawals, proposal return accounts, or treasury-withdrawal targets.

**Independent Test**: Golden Turtle fixtures show `cardano:network 0` or
`cardano:network 1` added on each network-bearing subject while existing
`cardano:bech32`, credential, and structural triples remain.

**Acceptance Scenarios**:

1. **Given** an output address on testnet, **When** `cq-rdf body` emits the
   address decomposition block, **Then** the address subject carries
   `cardano:network 0`.
2. **Given** an output address on mainnet, **When** `cq-rdf body` emits the
   address decomposition block, **Then** the address subject carries
   `cardano:network 1`.
3. **Given** withdrawal, proposal return, or treasury-withdrawal account data
   with an `AccountAddress` network, **When** the body walker emits its current
   account-bearing cluster, **Then** the cluster subject also carries the flat
   `cardano:network` literal.
4. **Given** the existing transaction body `networkId`, **When** emission runs,
   **Then** `cardano:networkId` remains body-level only and is not renamed or
   removed.

## Requirements

### Functional Requirements

- **FR-001**: Add a new vocabulary term `cardano:network`, distinct from the
  existing body-root `cardano:networkId`.
- **FR-002**: Emit `cardano:network` additively on each address node emitted
  by the address decomposition registry.
- **FR-003**: Emit `cardano:network` additively on withdrawal account clusters,
  proposal return-account clusters, and proposal treasury-withdrawal target
  clusters where the ledger value carries a network.
- **FR-004**: Literal values MUST use `networkToWord8`: `0` for testnet and
  `1` for mainnet.
- **FR-005**: Existing bech32, credential, identifier, txOutRef, and body-level
  `networkId` triples MUST remain in place.
- **FR-006**: Regenerated golden Turtle fixtures MUST show additive
  `cardano:network` triples and no unrelated churn.

### Constitution Alignment

- **CA-001**: The feature is generic Cardano RDF vocabulary and graph
  extraction, not downstream inspector implementation.
- **CA-002**: The new vocabulary term is intentional vocabulary drift and must
  update `Vocab.hs`, `vocab/cardano/transactions.ttl`, and canonical vocab
  fixtures in the same slice.
- **CA-003**: RDF output remains deterministic. Predicate placement must be
  stable and golden-backed.
- **CA-004**: No network fetching, consumer rebuild, or downstream inspector
  repin is in scope.

## Success Criteria

- **SC-001**: Focused tests fail before the emitter change because expected
  goldens do not contain `cardano:network`.
- **SC-002**: After implementation and regen, fixture diffs are additive for
  `cardano:network` plus required vocabulary/canonical-vocab updates.
- **SC-003**: At least one checked golden confirms an `addr_test...` address
  has `cardano:network 0`, and at least one checked golden confirms an
  `addr1...` mainnet address has `cardano:network 1`.
- **SC-004**: Local verification passes: focused emit golden unit, full unit,
  format, hlint, vocab gates, and the repo gate.

## Assumptions

- Reward/stake accounts, proposal return accounts, and treasury-withdrawal
  targets are currently represented by existing cluster subjects that point to
  stake credential identifiers, not by standalone reward-account subjects.
  The additive literal belongs on those existing account-bearing subjects.
- Downstream inspector SHACL and dependency repin are separate follow-up work.
