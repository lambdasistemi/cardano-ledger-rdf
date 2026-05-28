# Feature Specification: Typed Certificate Walker

**Feature Branch**: `certs-typed-walker`
**Created**: 2026-05-28
**Status**: Draft

## User Stories & Testing

### User Story 1 - Query Conway stake credential certificates (Priority: P1)

Operators can query Conway stake registration, unregistration, and
registration-plus-delegation certificates without unpacking opaque CBOR.

**Acceptance Scenarios**:

1. Given a transaction with `reg_cert`, the emitted graph has a typed
   certificate with stake credential and deposit triples.
2. Given a transaction with `stake_reg_deleg_cert`,
   `vote_reg_deleg_cert`, or `stake_vote_reg_deleg_cert`, the emitted
   graph includes the stake credential, delegation target(s), and
   deposit triples.

### User Story 2 - Query DRep certificates and anchors (Priority: P1)

Operators can query DRep registration, unregistration, and update
certificates, including optional anchors as structured nodes.

**Acceptance Scenarios**:

1. Given a DRep registration certificate with an anchor, the graph links
   the DRep credential, deposit, and a typed anchor.
2. Given a DRep update certificate without an anchor, the graph omits
   the anchor edge while retaining the DRep credential.

### User Story 3 - Query pool registration and retirement (Priority: P1)

Operators can query pool parameters, relays, metadata, and retirement
epoch directly from the certificate graph.

**Acceptance Scenarios**:

1. Given a pool registration certificate, the graph has a typed
   `PoolParams` node carrying operator, VRF key hash, pledge, cost,
   margin, reward account, owners, relays, and optional metadata.
2. Given a pool retirement certificate, the graph links the pool
   operator and retirement epoch.

### User Story 4 - Query committee hot/cold credentials (Priority: P1)

Operators can query committee hot-key authorization and cold-key
resignation certificates without reading opaque CBOR.

**Acceptance Scenarios**:

1. Given an authorization certificate, the graph links distinct cold and
   hot committee credentials.
2. Given a resignation certificate with an anchor, the graph links the
   cold credential and structured anchor.

## Requirements

- **FR-001**: The emitter MUST type Conway `reg_cert`,
  `unreg_cert`, `stake_reg_deleg_cert`, `vote_reg_deleg_cert`, and
  `stake_vote_reg_deleg_cert`.
- **FR-002**: The emitter MUST type Conway `reg_drep_cert`,
  `unreg_drep_cert`, and `update_drep_cert`.
- **FR-003**: The emitter MUST type pool registration and retirement
  certificates, including pool parameters, relays, and metadata.
- **FR-004**: The emitter MUST type committee hot/cold certificates with
  distinct cold and hot credential identifier leaf types.
- **FR-005**: The vocabulary MUST declare every emitted class and
  predicate, and emitted CURIEs MUST pass strict traceability.
- **FR-006**: Existing pre-Conway stake registration and deregistration
  behavior MUST remain unchanged.
- **FR-007**: Fixtures MUST include at least one transaction per
  certificate family and regenerate goldens for existing fixtures whose
  certs become typed.

## Success Criteria

- **SC-001**: `nix develop --quiet -c just unit` exits 0.
- **SC-002**: `nix build .#checks.x86_64-linux.{build,unit,lint,vocab-validate,vocab-owl-smoke}` exits 0.
- **SC-003**: `./gate.sh origin/main..HEAD` exits 0.
