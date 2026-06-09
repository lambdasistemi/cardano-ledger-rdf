# Contract: emitted metadata triples

The public contract of this feature is the **Turtle shape** appended to
the auxiliary-data node. It is verified by goldens. `_:aux` is the
existing `cardano:AuxiliaryData` node; bnode names below are illustrative
(real names are deterministic, path-derived).

## Per-kind shape

```turtle
# integer
_:aux cardano:hasMetadatum [ cardano:metadataLabel 674 ;
        cardano:metadatumValue [ a cardano:MetadatumValue, cardano:MetaInt ;
                                 cardano:intValue 42 ] ] .

# byte-string
[ a cardano:MetadatumValue, cardano:MetaBytes ; cardano:bytesHex "deadbeef" ] .

# text-string
[ a cardano:MetadatumValue, cardano:MetaText ; cardano:textValue "hello" ] .

# list (order + arity preserved; NOT joined)
[ a cardano:MetadatumValue, cardano:MetaList ;
  cardano:hasElement [ cardano:elementIndex 0 ; cardano:metadatumValue _:v0 ] ,
                     [ cardano:elementIndex 1 ; cardano:metadatumValue _:v1 ] ] .

# map (keys are value nodes)
[ a cardano:MetadatumValue, cardano:MetaMap ;
  cardano:hasEntry [ cardano:entryIndex 0 ;
                     cardano:metaKey   [ a cardano:MetaText ; cardano:textValue "event" ] ;
                     cardano:metaValue [ a cardano:MetaText ; cardano:textValue "disburse" ] ] ] .
```

## Worked example — the label-1694 block of tx `fe2eebc8…`

The headline golden. Abbreviated to show the structure the contract must
produce (full triples live in the golden `.ttl`):

```turtle
_:aux cardano:hasMetadatum [
  cardano:metadataLabel 1694 ;
  cardano:metadatumValue [ a cardano:MetaMap ;
    cardano:hasEntry
      [ cardano:entryIndex 0 ;
        cardano:metaKey   [ a cardano:MetaText ; cardano:textValue "body" ] ;
        cardano:metaValue [ a cardano:MetaMap ; cardano:hasEntry
          [ cardano:entryIndex 0 ;
            cardano:metaKey   [ a cardano:MetaText ; cardano:textValue "event" ] ;
            cardano:metaValue [ a cardano:MetaText ; cardano:textValue "disburse" ] ] ,
          # … label, references, description, destination, justification, context …
        ] ] ,
      [ cardano:entryIndex 1 ;
        cardano:metaKey   [ a cardano:MetaText ; cardano:textValue "instance" ] ;
        cardano:metaValue [ a cardano:MetaText ;
          cardano:textValue "7d275cf8c09fd91e73879993ef13cb73915196478d5e3777992f9888" ] ] ,
      # …
  ] ] .
```

### Contract assertions (golden-checked)

1. **C1**: `label = 1694` appears as an `xsd:integer`, not a string.
2. **C2**: `body.event` is reachable as
   `?aux cardano:hasMetadatum/cardano:metadatumValue` → MetaMap →
   `cardano:hasEntry` with `metaKey/cardano:textValue "event"` and
   `metaValue/cardano:textValue "disburse"`.
3. **C3**: the `description` value (on-chain a 2-element 64-byte chunk
   array) is a `cardano:MetaList` with **exactly two** `cardano:hasElement`
   nodes (`elementIndex` 0 and 1) — **not** a joined string (SC-002).
4. **C4**: the `instance` value `7d275cf8…f9888` is a single `MetaText`
   (the downstream registry-instance hygiene check reads it verbatim).
5. **C5**: the pre-existing `cardano:hasRawBytes` and
   `cardano:auxiliaryDataHash` triples for this tx are byte-identical to
   the pre-062 golden (additivity, FR-006).
6. **C6**: regenerating the graph twice yields byte-identical Turtle
   (SC-003).

## Negative / edge contracts

- A transaction with no auxiliary data emits **no** `cardano:hasMetadatum`
  triples.
- An auxiliary-data value with scripts but an empty metadata map emits the
  aux node with **zero** `cardano:hasMetadatum` edges.
