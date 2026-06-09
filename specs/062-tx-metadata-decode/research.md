# Phase 0 Research: Generic transaction-metadata decoding

All decisions resolve to "no NEEDS CLARIFICATION". The domain is small and
fixed (the ledger `Metadatum` type); the open questions are purely about
RDF shape and determinism.

## D1 — Source value type

- **Decision**: Decode `Cardano.Ledger.Metadata.Metadatum`, obtained from
  `TxAuxData ConwayEra` via its metadata lens (`Map Word64 Metadatum`).
  `Metadatum` is the five-constructor sum: `I Integer`, `B ByteString`,
  `S Text`, `List [Metadatum]`, `Map [(Metadatum, Metadatum)]`.
- **Rationale**: This is the canonical, already-decoded ledger
  representation the body stage hands us; decoding from it (not raw CBOR)
  keeps the feature offline and faithful.
- **Alternatives**: Re-parsing the raw CBOR — rejected (duplicate decode,
  drift risk against ledger semantics).

## D2 — Value-tree node shape (the five kinds)

- **Decision**: One typed node per kind, each a blank node typed with a
  `cardano:` class and carrying a kind-specific literal/edge:
  - integer → `cardano:MetaInt` + `cardano:intValue` (xsd:integer)
  - byte-string → `cardano:MetaBytes` + `cardano:bytesHex` (hex string)
  - text-string → `cardano:MetaText` + `cardano:textValue` (xsd:string)
  - list → `cardano:MetaList` + ordered `cardano:hasElement` edges
  - map → `cardano:MetaMap` + `cardano:hasEntry` edges
- **Rationale**: Typed nodes let a shape or query branch on kind
  (`?v a cardano:MetaText`) and never confuse bytes with text (FR-005).
  Reuses the existing `bytesHex` literal convention already in the graph.
- **Alternatives**: A single untyped literal with a datatype tag —
  rejected (loses kind for lists/maps, fragile bytes-vs-text inference).

## D3 — Lists: ordering and arity

- **Decision**: `cardano:MetaList cardano:hasElement` → element wrapper
  node carrying `cardano:elementIndex` (xsd:integer, 0-based) and
  `cardano:metadatumValue` → the element's value node. Preserve arity
  exactly; **never** merge or join elements.
- **Rationale**: Indexed wrappers are SPARQL-friendly (ORDER BY index) and
  far easier to query than `rdf:List`/`rdf:first`/`rdf:rest` chains. Arity
  preservation is the Principle III line: a chunked text value stays an
  N-element list; joining is spec 063's job (FR-003, SC-002).
- **Alternatives**: `rdf:List` collections — rejected (awkward in SPARQL,
  blank-node chain hurts determinism); flattening/joining — rejected
  (bakes a schema assumption into the core).

## D4 — Maps: keys and ordering

- **Decision**: `cardano:MetaMap cardano:hasEntry` → entry node carrying
  `cardano:entryIndex` (0-based), `cardano:metaKey` → a value node, and
  `cardano:metaValue` → a value node. Keys are full metadatum **value
  nodes**, not assumed strings.
- **Rationale**: Metadata map keys may be any metadatum (int/bytes/text);
  representing the key as a value node is faithful (FR-004) and lets a
  string-keyed map (the common case, e.g. the 1694 block) still be queried
  via `?e cardano:metaKey/cardano:textValue "body"`.
- **Alternatives**: Key as a plain literal predicate — rejected (lossy for
  non-string keys, and asymmetric with the value side).

## D5 — Determinism and ordering

- **Decision**: Emit top-level labels in ascending `Word64` order; emit map
  entries and list elements in their on-chain (canonical) order, stamped
  with explicit indices. Subject naming for value/entry/element bnodes is
  a deterministic path (e.g. `metadatum_<label>`, `…_e<entryIndex>`,
  `…_i<elementIndex>`), never counter- or hash-of-content based in a way
  that varies across runs.
- **Rationale**: Constitution II requires byte-stable Turtle (FR-007,
  SC-003). Path-derived bnode names + index stamps make the output a pure
  function of the input tree.
- **Alternatives**: Insertion-order global bnode counter — rejected (stable
  within a run but couples naming to traversal order, brittle under
  refactor); content-hash bnode ids — rejected (overkill, harder to read).

## D6 — Integration point and additivity

- **Decision**: Extend `emitAuxiliaryDataBody` (Project.hs:1205): keep the
  existing `cardano:hasAuxiliaryData` / `OpaqueLeaf` / `hasRawBytes`
  triples and the separate `cardano:auxiliaryDataHash`; **append**
  `cardano:hasMetadatum` edges from the aux node by folding the metadata
  map through the new `Emit.Metadatum` walker. An empty map emits no
  metadatum edges.
- **Rationale**: Strict additivity (FR-006) — existing goldens only gain
  triples; no consumer breaks.
- **Alternatives**: A new top-level emitter / separate aux node — rejected
  (splits the aux representation, breaks existing joins).

## D7 — Scope boundary (what we do NOT do)

- **Decision**: Decode only the metadata map. Auxiliary **scripts**
  (native/Plutus in the aux tuple) stay as today. No per-label typing,
  no chunk-joining, no CIP-25/1694 interpretation.
- **Rationale**: Principle III. Spec 063 (typed metadata schemas) owns
  label-aware interpretation and joining; this spec is the faithful
  substrate it consumes.
- **Alternatives**: Bundling typed 1694 decode here — rejected (would bake
  treasury semantics into the generic core).
