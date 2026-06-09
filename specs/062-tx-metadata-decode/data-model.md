# Phase 1 Data Model: metadatum vocabulary

All terms are added to the generic `cardano:` namespace
(`vocab/cardano/transactions.ttl`) and the `VocabTerm` enum in
`Cardano.Tx.Graph.Emit.Vocab` (constructor + `vocabIri` + `vocabCurie`
case). `cardano:bytesHex` already exists and is reused.

## Entities

### MetadatumEntry
A single top-level `label → value` association on an `AuxiliaryData`
node. Reached by `cardano:hasMetadatum` from the aux node.
- `cardano:metadataLabel` → `xsd:integer` (the `Word64` label)
- `cardano:metadatumValue` → a **MetadatumValue**

### MetadatumValue (abstract)
The recursive value. Always exactly one concrete kind below; every kind
is `rdfs:subClassOf cardano:MetadatumValue` so a consumer can match
`?v a cardano:MetadatumValue` regardless of kind.

| Kind class | Carries | From `Metadatum` |
|---|---|---|
| `cardano:MetaInt` | `cardano:intValue` → `xsd:integer` | `I Integer` |
| `cardano:MetaBytes` | `cardano:bytesHex` → hex string | `B ByteString` |
| `cardano:MetaText` | `cardano:textValue` → `xsd:string` | `S Text` |
| `cardano:MetaList` | ordered `cardano:hasElement` → MetadatumElement | `List [Metadatum]` |
| `cardano:MetaMap` | `cardano:hasEntry` → MetadatumMapEntry | `Map [(Metadatum,Metadatum)]` |

### MetadatumElement
A positional wrapper for one element of a `MetaList` (preserves order +
arity; never merged).
- `cardano:elementIndex` → `xsd:integer` (0-based)
- `cardano:metadatumValue` → a **MetadatumValue**

### MetadatumMapEntry
One `key → value` pair of a `MetaMap` (preserves order; key may be any
metadatum, not only a string).
- `cardano:entryIndex` → `xsd:integer` (0-based)
- `cardano:metaKey` → a **MetadatumValue**
- `cardano:metaValue` → a **MetadatumValue**

## New vocabulary terms

**Classes**: `MetadatumValue`, `MetaInt`, `MetaBytes`, `MetaText`,
`MetaList`, `MetaMap`, `MetadatumEntry`, `MetadatumElement`,
`MetadatumMapEntry`.

**Properties**: `hasMetadatum`, `metadataLabel`, `metadatumValue`,
`intValue`, `textValue`, `hasElement`, `elementIndex`, `hasEntry`,
`entryIndex`, `metaKey`, `metaValue`. (`bytesHex` reused.)

## Relationships

```text
Transaction ─hasAuxiliaryData→ AuxiliaryData ─hasMetadatum→ MetadatumEntry
                                                              ├─ metadataLabel  (xsd:integer)
                                                              └─ metadatumValue → MetadatumValue
MetadatumValue = MetaInt | MetaBytes | MetaText | MetaList | MetaMap
MetaList ─hasElement→ MetadatumElement ─(elementIndex, metadatumValue)→ MetadatumValue
MetaMap  ─hasEntry→   MetadatumMapEntry ─(entryIndex, metaKey, metaValue)→ MetadatumValue
```

## Validation rules (from spec FRs)

- Exactly one kind class per value node (FR-002, FR-005).
- `MetaList` element count == on-chain arity; no joining (FR-003, SC-002).
- `MetaMap` preserves every pair; keys are value nodes (FR-004).
- Existing `hasAuxiliaryData` / `OpaqueLeaf` / `hasRawBytes` /
  `auxiliaryDataHash` triples unchanged (FR-006).
- Deterministic ordering: ascending label; on-chain element/entry order
  with explicit 0-based indices; path-derived bnode names (FR-007).
