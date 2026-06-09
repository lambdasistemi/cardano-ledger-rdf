# Feature Specification: Generic transaction-metadata decoding

**Feature Branch**: `062-tx-metadata-decode`  
**Created**: 2026-06-09  
**Status**: Draft  
**Input**: User description: "Decode the Conway auxiliary-data transaction-metadata map into faithful generic RDF triples (each label → a Metadatum value tree of integer/bytes/text/list/map). Stay faithful — lists stay lists, chunked text is not joined. Generic core only; no label-specific or treasury interpretation."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Reach metadata contents, not just its hash (Priority: P1)

A shape author or SPARQL auditor working with a generated transaction
graph needs to read the *contents* of a transaction's metadata — the
labels and the values nested inside them — directly as graph triples.
Today the graph carries only the opaque auxiliary-data CBOR bytes and the
auxiliary-data hash, so any question about "what does label 1694 say" is
unanswerable without leaving the graph and re-parsing CBOR by hand.

**Why this priority**: This is the keystone. Every downstream
capability — typed metadata schemas, SHACL targeting by label, and any
hygiene check that reads a metadata field — is blocked until metadata
content exists as triples. On its own it already delivers value: auditors
can query metadata.

**Independent Test**: Generate the graph for a metadata-bearing
transaction and run a SPARQL query that walks from the transaction to a
nested metadata value (e.g. label 1694 → entry "body" → entry "event");
the value comes back without touching CBOR.

**Acceptance Scenarios**:

1. **Given** a transaction whose auxiliary data carries a metadata map,
   **When** its graph is generated, **Then** the auxiliary-data node is
   related to one metadatum entry per top-level label, each carrying the
   integer label and its decoded value.
2. **Given** the generated graph, **When** an auditor queries for the
   value nested several levels inside a metadata map, **Then** the query
   resolves it through ordinary graph predicates with no CBOR parsing.

---

### User Story 2 - Faithful, lossless value tree (Priority: P1)

The decoded metadata must be a faithful mirror of the on-chain metadatum
value, so that no information is invented or lost. In particular, a text
value that on-chain is a list of 64-byte chunks must appear as a list of
elements — never silently concatenated — because joining is a
schema-level interpretation that belongs to a later, label-aware pass.

**Why this priority**: Faithfulness is what lets the generic core stay
generic (Constitution III) and lets the downstream typed pass do joining
*correctly per schema*. A lossy or pre-joined decode would bake one
schema's assumption into the core and corrupt auditing.

**Independent Test**: Take a metadata text value that is a two-element
chunk array on-chain; confirm the graph exposes a two-element ordered
list, not a single joined string.

**Acceptance Scenarios**:

1. **Given** a metadata list value, **When** the graph is generated,
   **Then** element order and arity are preserved and no elements are
   merged.
2. **Given** a metadata map value with non-string keys, **When** the
   graph is generated, **Then** every key→value pair is preserved with
   the key represented as a value node (not assumed to be a string).
3. **Given** integer, byte-string, and text-string leaf values, **When**
   the graph is generated, **Then** each is represented as a distinct,
   distinguishable kind (a hex byte value is never confused with UTF-8
   text).

---

### User Story 3 - Targetable by label, additively (Priority: P2)

A downstream consumer — the typed-metadata schema pass and SHACL
shapes — must be able to select transactions by metadata label and reach
specific fields, while everything that the graph emits today (opaque
bytes, hash) keeps working unchanged.

**Why this priority**: This is the bridge to specs 063 (typed metadata),
065 (hygiene shapes), and the registry-instance check. It depends on
Stories 1–2 and is the reason they exist, but is validated separately.

**Independent Test**: Run a query/shape that selects a transaction solely
by the presence of a given metadata label; confirm it matches the
metadata-bearing transaction and not a metadata-free one, and confirm the
pre-existing hash/raw-bytes triples are still present.

**Acceptance Scenarios**:

1. **Given** a graph with decoded metadata, **When** a consumer targets
   transactions carrying a specific label, **Then** only transactions
   with that label match.
2. **Given** the same graph, **When** a consumer reads the auxiliary-data
   hash or raw bytes, **Then** those triples are unchanged from before
   this feature.

---

### Edge Cases

- **No auxiliary data**: a transaction with no fourth-slot auxiliary data
  emits no metadatum triples (existing behavior unchanged).
- **Auxiliary data with scripts but an empty metadata map**: the
  auxiliary-data node is present, with zero metadatum entries.
- **Already-chunked long text**: a >64-byte text value stored on-chain as
  a chunk list is preserved as a list, not joined.
- **Non-string map keys**: integer or byte-string keys are preserved as
  value nodes, not coerced to strings.
- **Deep nesting**: maps within lists within maps are preserved to full
  depth.
- **Determinism**: map entries and list elements are emitted in a stable,
  canonical order so the Turtle is byte-identical across runs.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: For every transaction carrying auxiliary data with a
  non-empty metadata map, the graph MUST relate the transaction's
  auxiliary-data node to one metadatum entry per top-level label, each
  carrying the integer label and its decoded value.
- **FR-002**: Each metadatum value MUST be represented as a typed node
  tree that distinguishes the five Cardano metadatum kinds — integer,
  byte-string, text-string, list, and map.
- **FR-003**: List values MUST preserve element order and arity; the
  system MUST NOT concatenate or merge multiple elements (text-chunk
  joining is reserved for the downstream typed-metadata schema pass).
- **FR-004**: Map values MUST preserve every key→value pair, with keys
  represented as metadatum value nodes (not assumed to be strings), in a
  stable canonical key order.
- **FR-005**: Byte-string and text-string leaves MUST be distinguishable
  in the graph (a consumer can tell a hex byte value from a UTF-8 text
  value).
- **FR-006**: The pre-existing opaque auxiliary-data bytes and the
  auxiliary-data hash MUST continue to be emitted unchanged; decoded
  metadata is strictly additive.
- **FR-007**: The decode MUST be deterministic and byte-stable: identical
  input transactions MUST produce identical Turtle, with stable subject
  naming and stable entry/element ordering.
- **FR-008**: The feature MUST add only generic Cardano vocabulary and
  MUST NOT encode any label-specific (e.g. 1694) or
  application/treasury interpretation; per-label meaning is out of scope
  and handled downstream.
- **FR-009**: New vocabulary terms MUST be documented in the published
  Cardano ontology and traceable from goldens to docs.
- **FR-010**: A golden fixture MUST cover the real label-1694 metadata
  block from transaction
  `fe2eebc88c43fc50c71bf4bb276060ad77a14ef2953868379a73abd18636aa4a`,
  exercising nested maps, lists, chunked text, and an integer label.

### Constitution Alignment *(mandatory)*

- **CA-001**: This feature belongs to the **generic Cardano RDF core** —
  the transaction-body/auxiliary-data emission surface. It is not a
  packaged view, not a hosted-service boundary, and not a downstream
  consumer.
- **CA-002**: It adds generic `cardano:`-namespace vocabulary (metadatum
  value classes and the properties relating an auxiliary-data node to its
  labelled entries and value tree) and new triples on the auxiliary-data
  subject. It introduces new Turtle goldens and updates existing
  auxiliary-data goldens to include the decoded metadata. Metadatum
  value-node subject naming MUST be deterministic and stable.
- **CA-003**: **N/A** — offline only. The decode operates on
  caller-provided CBOR already resolved by the body stage; it adds no
  network boundary.
- **CA-004**: It touches the auxiliary-data emitter that originated in
  the `cardano-tx-tools` migration, but is **additive**. No deletion of
  old source is in scope.

### Key Entities

- **Metadatum entry**: the association at the top of a transaction's
  metadata between an integer **label** and its **value**.
- **Metadatum value**: the recursive value tree — one of integer,
  byte-string, text-string, list, or map — faithfully mirroring the
  on-chain metadatum.
- **Map entry**: a single key→value pair inside a metadatum map, where
  the key is itself a metadatum value.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of a transaction's metadatum tree is reachable as
  graph triples — any nested field can be retrieved by query without
  parsing CBOR.
- **SC-002**: A metadata text value split into N on-chain chunks appears
  as exactly N ordered list elements (zero joining), verified on the
  label-1694 golden.
- **SC-003**: Re-running the decode on the same transaction produces
  byte-identical Turtle across runs.
- **SC-004**: A downstream consumer can select a transaction by the
  presence of a metadata label using only the emitted triples,
  demonstrated by selecting the Amaru contingency-disburse transaction by
  its label-1694 presence.
- **SC-005**: Zero regression — every pre-existing auxiliary-data and
  auxiliary-data-hash golden still passes, with decoded metadata added.

## Assumptions

- The Cardano transaction-metadatum domain is exactly the five kinds
  (integer, byte-string, text-string, list, map); no other kinds exist.
- Decoding auxiliary-data **scripts** (native / Plutus) is out of scope
  for this feature; only the metadata map is decoded. Auxiliary scripts
  remain represented as today (or in a later spec).
- The typed interpretation of specific labels (the 1694 treasury spec,
  CIP-25, etc.) is **out of scope** and handled by the downstream
  typed-metadata schema pass (spec 063).
- Callers provide valid Conway auxiliary-data CBOR; malformed-input
  handling follows the existing emitter's behavior.
- The existing auxiliary-data body and hash emission is reused, not
  replaced; this feature only adds the decoded value tree alongside it.
