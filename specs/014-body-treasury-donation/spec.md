# Feature Specification: Body Treasury Value And Donation RDF

**Feature Branch**: `014-body-treasury-donation`
**Created**: 2026-05-28
**Status**: Draft
**Input**: User description: "Emit Conway transaction body fields 21 current_treasury_value and 22 donation as typed integer RDF triples."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Treasury Body Fields Are Visible (Priority: P1)

Cardano RDF consumers can inspect Conway transaction body treasury accounting fields without decoding the original CBOR body map.

**Why this priority**: These are existing Cardano ledger fields currently dropped by the RDF emitter, so graph consumers cannot query complete body semantics.

**Independent Test**: A synthetic Conway transaction with only `current_treasury_value` set emits `cardano:hasCurrentTreasuryValue` on `_:tx`, and a synthetic transaction with only `donation` set emits `cardano:hasDonation` on `_:tx`.

**Acceptance Scenarios**:

1. **Given** a transaction body with field 21 set to a coin value, **When** RDF is emitted, **Then** `_:tx cardano:hasCurrentTreasuryValue <integer>` appears.
2. **Given** a transaction body with field 22 set to a positive coin value, **When** RDF is emitted, **Then** `_:tx cardano:hasDonation <integer>` appears.
3. **Given** a transaction body where both fields are absent/defaulted, **When** RDF is emitted, **Then** neither predicate appears.

### Edge Cases

- Donation is represented by the ledger lens as `Coin 0` when absent; the emitter treats zero as absent and emits only positive donations.
- Existing fixtures that do not set either body field remain byte-stable.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST emit `cardano:hasCurrentTreasuryValue` as an `xsd:integer`-compatible Turtle integer literal when Conway transaction body field 21 is present.
- **FR-002**: System MUST emit `cardano:hasDonation` as an `xsd:integer`-compatible Turtle integer literal when Conway transaction body field 22 is present with a positive coin value.
- **FR-003**: System MUST declare both predicates in the transaction vocabulary with `rdfs:domain cardano:Transaction` and `rdfs:range xsd:integer`.
- **FR-004**: System MUST elide both predicates when the corresponding body fields are absent/defaulted.

### Constitution Alignment *(mandatory)*

- **CA-001**: This belongs to the generic Cardano RDF core transaction graph emitter.
- **CA-002**: Public RDF vocabulary grows by two additive predicates on `cardano:Transaction`; new fixtures and goldens pin the output while existing fixtures remain byte-stable.
- **CA-003**: N/A; graph emission remains offline from caller-provided transaction data and fixture files.
- **CA-004**: N/A; no `cardano-tx-tools` source deletion or migration removal is in scope.

### Key Entities *(include if feature involves data)*

- **Transaction**: Existing transaction body subject `_:tx`; receives optional integer predicates for fields 21 and 22.
- **Coin**: Ledger lovelace amount rendered as a Turtle integer literal.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Unit tests prove `hasCurrentTreasuryValue` emits when set and is absent when unset.
- **SC-002**: Unit tests prove `hasDonation` emits when positive and is absent when zero.
- **SC-003**: Golden fixtures 27 and 28 include the two new predicates independently.
- **SC-004**: `just unit`, Nix checks, and `./gate.sh origin/main..HEAD` pass after implementation.

## Assumptions

- Ledger field 21 is read through `currentTreasuryValueTxBodyL`.
- Ledger field 22 is read through `treasuryDonationTxBodyL`; `Coin 0` is the decoded absence/default.
- No downstream view or SPARQL projection needs a special subnode for these scalar body fields.
