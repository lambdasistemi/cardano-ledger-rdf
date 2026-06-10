# Phase 0 Research: Typed metadata schemas

All decisions resolve to "no NEEDS CLARIFICATION". The shape is fixed by
the existing `blueprint` pass (the analog) and the 062 metadatum tree.

## D1 — A dedicated `cq-rdf metadata` subcommand (not a blueprint mode)

- **Decision**: New subcommand `cq-rdf metadata --schemas DIR`, sibling to
  `blueprint`, dispatched the same way (`metadataCommand`:
  stdin TTL → `loadMetadataSchemaDirectory` → `enrichMetadataTurtle` →
  stdout). Pipeline becomes `overlay | body | blueprint | metadata | shacl`.
- **Rationale**: `blueprint` keys CIP-57 schemas by **script hash** on
  `cardano:Output`/datum blocks; metadata schemas key by **integer label**
  on the aux node. Different input + different keying → folding into
  blueprint would tangle two unrelated matchers. A sibling pass mirrors the
  established subcommand structure (Main.hs:231-271) at low cost.
- **Alternatives**: a `blueprint --metadata-schemas` mode — rejected
  (overloads one command with two keyings). Doing it in the body emitter —
  rejected (Principle III: the emitter is generic core; label semantics are
  an extension applied later).

## D2 — Schema format: label-keyed JSON, like `*.cip57.json`

- **Decision**: One JSON file per schema, `*.schema.json`, loaded from
  `--schemas DIR` (sorted, like the blueprint loader at Main.hs:911-926).
  Each schema declares: the metadata `label` (Word64), the target namespace
  `prefix` + IRI, and an ordered list of `fields`, each `{ predicate, path,
  kind }`.
- **Rationale**: mirrors the blueprint directory convention operators
  already know; JSON is machine-checkable and diffable; one-file-per-label
  composes (drop a new schema in the dir).
- **Alternatives**: YAML (like `overlay.yaml`) — viable, rejected only for
  directory-convention symmetry with blueprints; a bespoke DSL — rejected
  (over-engineering for a flat field map).

## D3 — Tree-path navigation by map-key sequence

- **Decision**: A field `path` is an ordered list of text keys naming a
  descent through nested `MetaMap`s: at each step the engine finds the
  `cardano:hasEntry` whose `cardano:metaKey` is a `MetaText` with that
  `cardano:textValue`, and follows `cardano:metaValue`. The final node's
  value is read per the field `kind`.
- **Rationale**: the 1694 block is nested string-keyed maps
  (`body → event`, `body → justification`, top-level `instance`); a key
  path is the natural, faithful selector over the 062 tree.
- **Alternatives**: index paths — rejected (fragile to reordering);
  JSONPath/SPARQL embedded in the schema — rejected (heavyweight; the engine
  would need a query evaluator).

## D4 — `kind`: text | int | bytes | joinedText | uriList

- **Decision**: field kinds map the terminal node to a typed literal:
  `text`→`textValue`, `int`→`intValue`, `bytes`→`bytesHex`,
  `joinedText`→in-order concatenation of a `MetaList` of `MetaText`
  (`hasElement`/`elementIndex` order), `uriList`→a list of URIs from a
  `MetaList` (e.g. `references[].uri`). `joinedText` is the schema-level
  join that 062 deliberately omitted (spec FR-003, SC-002).
- **Rationale**: covers the 1694 fields exactly (`event`/`label` text,
  `justification`/`description` joinedText, `instance` text,
  `references` uriList) without a general expression language.
- **Alternatives**: a single "text" kind that auto-joins lists — rejected
  (hides the join decision; some list fields are not text).

## D5 — Project onto the Transaction subject, additively + idempotently

- **Decision**: emit `<txSubj> <prefix>:<predicate> <value> .` attached to
  the **transaction** node, appended after the original Turtle (the
  `enrichBlueprintTurtle` pattern at Main.hs:970-993), skipped if the
  predicate already appears (the blueprint idempotency check). The generic
  `cardano:` tree is never modified.
- **Rationale**: `?tx treasury:event ?e` is the most query/shape-friendly
  shape (one hop from the tx); additivity preserves the faithful tree
  (FR-004, SC-005).
- **Alternatives**: attach to the aux/entry node — rejected (extra hop for
  every query, no benefit).

## D6 — Schema-mismatch error in the schema's own namespace

- **Decision**: when a label is present but its tree does not match the
  schema (missing key, wrong kind), emit `<txSubj> <prefix>:schemaError
  "<message>" .` in the **schema's declared namespace**, leaving the generic
  tree intact — mirroring how blueprint emits `cardano:decodeError` on
  CIP-57 failure (Main.hs:1060).
- **Rationale**: keeps the generic engine free of any single namespace's
  error vocabulary; the error travels with the extension. For the 1694
  schema this is `treasury:schemaError`.
- **Alternatives**: a generic `cardano:schemaError` — rejected (would put a
  typed-schema concept in the strict `cardano:` vocab + its traceability
  gate, for no gain).

## D7 — Reuse the blueprint Turtle plumbing

- **Decision**: read the input with the existing `parseCanonicalTurtle`
  (`TurtleGraph = Map subject → block`), navigate with the existing
  `objectFor`/`literalFor` helpers, and append via the existing
  `ensureTrailingNewline` + comment-header pattern. No new RDF library.
- **Rationale**: the pass is the same shape as blueprint; reusing the
  battle-tested plumbing keeps the diff small and the output format
  identical. `treasury:` has no strict traceability gate, so additions there
  are low-friction.
- **Alternatives**: introduce `rdf4h` — rejected (a large dependency + a
  serialization-format change the repo deliberately avoids).

## D8 — Determinism

- **Decision**: emit typed predicates in schema `fields` order; bnode/URI
  naming and joins are pure functions of the input; idempotency guard.
- **Rationale**: Constitution II (byte-stable goldens, FR-009, SC-004).

## D9 — Scope: label 1694 as the only shipped schema

- **Decision**: ship `treasury-1694.schema.json` as the worked example; the
  engine is generic so CIP-25 (721) and others are just more schema files,
  out of scope here.
- **Rationale**: proves the mechanism end-to-end against the real
  contingency tx while keeping the surface minimal.
