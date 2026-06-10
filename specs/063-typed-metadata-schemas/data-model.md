# Phase 1 Data Model: schema + typed treasury terms

## The metadata schema (operator asset, `*.schema.json`)

```jsonc
{
  "label": 1694,
  "prefix": "treasury",
  "namespace": "https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/treasury#",
  "fields": [
    { "predicate": "event",            "path": ["body", "event"],         "kind": "text" },
    { "predicate": "label",            "path": ["body", "label"],         "kind": "text" },
    { "predicate": "justification",    "path": ["body", "justification"], "kind": "joinedText" },
    { "predicate": "registryInstance", "path": ["instance"],              "kind": "text" },
    { "predicate": "destination",      "path": ["body", "destination", "label"], "kind": "text" },
    { "predicate": "references",       "path": ["body", "references"],    "kind": "uriList" }
  ]
}
```

| Field | Meaning |
|---|---|
| `label` | the `cardano:metadataLabel` (Word64) this schema interprets |
| `prefix` / `namespace` | the extension namespace the typed predicates land in |
| `fields[]` | ordered; each projects one typed predicate |
| `field.predicate` | local name of the emitted predicate (`treasury:event`, …) |
| `field.path` | ordered map-key descent through the `MetaMap` tree |
| `field.kind` | `text \| int \| bytes \| joinedText \| uriList` — how the terminal node becomes a literal/objects |

## Projection shape (additive, on the transaction subject)

```turtle
_:tx treasury:event            "disburse" ;
     treasury:label            "Contingency disburse" ;
     treasury:justification    "Agreed contract funding, existing and new: …" ;   # joinedText
     treasury:registryInstance "7d275cf8c09fd91e73879993ef13cb73915196478d5e3777992f9888" ;
     treasury:destination      "Core Development, Ops and Use Cases, Network Compliance treasury" ;
     treasury:references       <ipfs://bafkrei…> .
# the generic cardano: metadatum tree is unchanged
```

On schema mismatch:

```turtle
_:tx treasury:schemaError "label 1694: missing key body/event" .
```

## New `treasury:` vocabulary terms (vocab/treasury/overlay.ttl)

Properties (range noted): `event` (xsd:string), `label` (xsd:string —
human label, distinct from the integer `cardano:metadataLabel`),
`justification` (xsd:string), `registryInstance` (xsd:string — the
registry-script hash, verbatim), `destination` (xsd:string), `references`
(rdfs:Resource, repeatable), `schemaError` (xsd:string).

No new classes required for the MVP; the predicates attach to the existing
transaction subject. (`treasury:` has no strict traceability gate, so these
are documented in `overlay.ttl` for accessibility, not pinned.)

## Reads-only inputs (from spec 062, never modified)

`cardano:hasMetadatum` → `cardano:metadataLabel` / `cardano:metadatumValue`
→ `cardano:MetaMap` (`cardano:hasEntry` → `cardano:metaKey`/`metaValue`),
`cardano:MetaList` (`cardano:hasElement` → `cardano:elementIndex` +
`cardano:metadatumValue`), `cardano:MetaText` (`cardano:textValue`),
`cardano:MetaInt` (`cardano:intValue`), `cardano:MetaBytes`
(`cardano:bytesHex`).

## Validation rules (from spec FRs)

- A field path that does not resolve, or a terminal node whose kind does
  not match, → `schemaError`, generic tree intact (FR-006).
- `joinedText` concatenates `MetaList`→`MetaText` in `elementIndex` order
  (FR-003); a lone `MetaText` is a one-element join.
- Unknown label (no schema) → no output (FR-005).
- Pre-existing `cardano:` triples byte-identical (FR-004, SC-005).
- Typed predicates in schema `fields` order; deterministic (FR-009).
