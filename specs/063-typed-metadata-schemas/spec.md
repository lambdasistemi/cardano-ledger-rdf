# Feature Specification: Typed metadata schemas

**Feature Branch**: `063-typed-metadata-schemas`  
**Created**: 2026-06-09  
**Status**: Draft  
**Input**: Interpret known transaction-metadata labels against operator-supplied schemas, projecting the generic `cardano:` metadatum tree (spec 062) into typed predicates in an explicit extension namespace — starting with the SundaeSwap/Amaru treasury label 1694. Enables registry-instance hygiene and SHACL targeting by label. Generic core untouched (Principle III).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Read metadata fields by name, not by tree-walk (Priority: P1)

An auditor or shape author has a transaction graph whose metadata is
decoded into the generic `cardano:` tree (spec 062): label → `MetaMap` →
`hasEntry` → `metaKey`/`metaValue`. To ask "what is this disburse's
`event`?" they must walk several blank-node hops by string key. With an
operator-supplied **schema** for a known label, the field is projected to
a single typed predicate — `?tx treasury:event ?e` — so the question is
one triple, not a traversal.

**Why this priority**: This is the payoff of the whole metadata line. The
generic tree (062) is faithful but verbose; typed projection is what makes
metadata *usable* by shapes and queries. Everything downstream (hygiene
shapes, the registry-instance check, label targeting) depends on it.

**Independent Test**: Run the schema-application pass with the label-1694
schema over the contingency-disburse graph; a query for `treasury:event`
returns `"disburse"` directly, with no `metaKey`/`metaValue` hops.

**Acceptance Scenarios**:

1. **Given** a graph with a generic metadatum tree at a label, and a
   schema registered for that label, **When** the pass runs, **Then**
   each schema-named field is emitted as a typed predicate on (or linked
   from) the transaction.
2. **Given** no schema for a label, **When** the pass runs, **Then** that
   label's generic tree is left untouched and no typed predicates are
   invented.

### User Story 2 - Schema-level joining and faithful, additive projection (Priority: P1)

The treasury spec stores long text (e.g. `justification`, `description`)
as a list of ≤64-byte chunks — which spec 062 deliberately preserved as a
`MetaList` rather than joining. A schema can declare such a field as
"joined text", so the typed projection yields one coherent string while
the generic chunk list stays intact (the projection is **additive**).

**Why this priority**: Joining is the schema-level concern 062 explicitly
deferred (Principle III: the generic core must not assume one schema's
chunking). A hygiene check like "justification is non-empty" needs the
joined value; auditing needs the faithful chunks. Both must coexist.

**Independent Test**: A two-chunk `justification` projects to one
`treasury:justification` string equal to the concatenation, while the
original two-element `MetaList` remains in the graph.

**Acceptance Scenarios**:

1. **Given** a schema field marked as joined text over a `MetaList` of
   `MetaText`, **When** the pass runs, **Then** the typed predicate
   carries the in-order concatenation and the generic list is unchanged.
2. **Given** the projection, **When** any pre-existing `cardano:` triple
   is inspected, **Then** it is byte-identical to before the pass
   (strictly additive).

### User Story 3 - Enable registry-instance hygiene and label targeting (Priority: P2)

The typed projection exposes the treasury `instance` (registry-script
hash) verbatim as `treasury:registryInstance`, and a typed marker
(`treasury:event` / a label class) by which a SHACL shape can **target**
the transaction class. This is the bridge to the hygiene army (spec 065):
a shape can assert `registryInstance` equals the correct scope's registry
hash (the upstream-typo catcher) and scope itself to "contingency
disburse" transactions.

**Why this priority**: It is the reason 063 exists, but it is validated
independently of the projection mechanics. It depends on US1/US2.

**Independent Test**: A shape/query selects the contingency-disburse tx by
`treasury:event = "disburse"` (and a contingency marker) and reads
`treasury:registryInstance`; a metadata-free tx does not match.

**Acceptance Scenarios**:

1. **Given** the typed graph, **When** a consumer targets transactions by
   a schema-projected field, **Then** only transactions carrying that
   label/field match.
2. **Given** the typed graph, **When** a consumer reads
   `treasury:registryInstance`, **Then** it equals the on-chain
   `instance` value verbatim (suitable for an equality hygiene check).

### Edge Cases

- **Unknown label**: no schema → generic tree untouched, no typed output.
- **Label present but tree shape mismatches the schema** (missing field,
  wrong kind): the pass reports a typed *decode error* (mirroring how
  CIP-57 blueprint decoding surfaces failures) rather than silently
  emitting a wrong value; the generic tree is still left intact.
- **Joined field that is a single `MetaText`** (not a list): treated as a
  one-element join (the value itself).
- **Non-text inside a list declared as joined text**: a typed decode
  error, not a coerced string.
- **Multiple labels with schemas in one tx**: each projected independently.
- **Determinism**: typed predicates are emitted in a stable order so the
  Turtle is byte-stable.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A schema-application pass MUST read a graph carrying the
  generic `cardano:` metadatum tree and, for every label with a
  registered schema, emit typed predicates derived from that label's tree.
- **FR-002**: Schemas MUST be operator-supplied assets (one or more,
  loaded from a caller-named location), each binding a metadata label to a
  set of typed predicates in an explicitly named extension namespace and
  the path through the metadatum tree that produces each.
- **FR-003**: A schema field MAY declare "joined text"; for such a field
  the typed value MUST be the in-order concatenation of a `MetaList` of
  `MetaText` chunks (the schema-level join that the generic decode omits).
- **FR-004**: Projection MUST be strictly additive — every pre-existing
  `cardano:` triple is unchanged; only typed extension triples are added.
- **FR-005**: A label with no registered schema MUST be left as its
  generic tree, with no invented typed predicates.
- **FR-006**: A tree that does not match its schema MUST surface a typed
  decode error rather than emit a wrong value, leaving the generic tree
  intact.
- **FR-007**: The treasury `instance` field of label 1694 MUST be
  projected verbatim as a typed predicate suitable for an equality check.
- **FR-008**: The projection MUST expose a typed marker by which a SHACL
  shape can target transactions of a known metadata class (e.g. by the
  projected `event`/label).
- **FR-009**: Output MUST be deterministic and byte-stable for identical
  inputs (stable predicate order, stable subject naming).
- **FR-010**: The generic ENGINE MUST contain no label-specific or
  treasury business semantics; all label meaning lives in the
  operator-supplied schema and its extension namespace (Principle III).
- **FR-011**: A label-1694 schema (the SundaeSwap/Amaru treasury spec)
  MUST ship as the worked example, projecting at least `event`, `label`,
  `justification` (joined), `references`, `registryInstance`, and
  `destination`.
- **FR-012**: A golden fixture MUST cover the label-1694 projection on the
  contingency-disburse transaction.

### Constitution Alignment *(mandatory)*

- **CA-001**: Split by Principle III. The **engine** (the schema-application
  pass) is a generic pipeline stage in the core — it applies any schema and
  knows no business semantics, mirroring how `cq-rdf blueprint` applies
  CIP-57 blueprints. The **1694 schema** and the **treasury:** typed
  predicates are an **explicit extension** (operator asset + extension
  namespace), not core.
- **CA-002**: Adds the schema-application pass and typed `treasury:`
  metadata predicates to the graph; extends the `treasury:` ontology with
  the new typed-metadata terms; introduces new goldens. Reads (does not
  modify) the `cardano:` metadatum vocab from 062.
- **CA-003**: **N/A** — offline. Reads caller-provided Turtle on stdin and
  local schema files; adds no network boundary.
- **CA-004**: Additive; no `cardano-tx-tools` source deleted.

### Key Entities

- **Metadata schema**: an operator-supplied binding of a metadata label to
  typed predicates in a named extension namespace, including each field's
  path through the generic metadatum tree and whether it is joined text.
- **Typed metadata projection**: the set of extension-namespace triples a
  schema produces for one transaction's labelled metadata.
- **Typed decode error**: the marker emitted when a label's tree does not
  match its schema (analogous to the CIP-57 `decodeError`).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A nested metadata field reachable in N blank-node hops in the
  generic tree is reachable as a single typed predicate after the pass.
- **SC-002**: A two-chunk text field projects to one joined string equal to
  the concatenation, with the original chunk list still present.
- **SC-003**: The contingency-disburse tx is selectable by its projected
  metadata class and exposes `registryInstance` verbatim — the two
  primitives spec 065's hygiene shapes need.
- **SC-004**: Re-running the pass on the same input yields byte-identical
  Turtle.
- **SC-005**: Zero regression — every pre-existing `cardano:` triple
  (incl. the 062 metadatum tree) is unchanged after projection.

## Assumptions

- Builds on spec 062: the generic `cardano:` metadatum tree is present in
  the input graph; 063 reads it and never re-decodes CBOR.
- The pass is a distinct pipeline stage (a `cq-rdf metadata --schemas DIR`
  step, or a metadata-typing mode of `blueprint`) sitting after body/decode
  and before `shacl`; the exact surface is a plan decision.
- Schema scope for this spec is the label-1694 treasury spec as the worked
  example; the engine is generic so further labels (CIP-25, etc.) are
  additional schemas, out of scope here.
- The hygiene shapes that *consume* `registryInstance` and the label marker
  are spec 065; this spec only delivers the primitives they need.
- Schema authoring format (the exact mapping DSL) is a plan/contract
  detail; the spec fixes only its required expressive power (label →
  namespaced typed fields, tree paths, joined-text flag).
