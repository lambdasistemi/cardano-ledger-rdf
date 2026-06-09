# Quickstart: decode and query transaction metadata

Once this feature lands, the metadata map decodes into the graph
automatically — no new flag. The headline example is the Amaru
contingency-disburse tx whose label-1694 rationale block becomes
queryable triples.

## 1. Emit the graph (metadata now decoded)

```bash
# from a local CBOR file (offline):
cq-rdf body --in tx-fe2eebc8.cbor > tx.ttl

# or fetch by txid:
cq-rdf body --provider blockfrost \
  fe2eebc88c43fc50c71bf4bb276060ad77a14ef2953868379a73abd18636aa4a > tx.ttl
```

The graph now carries, in addition to the unchanged
`cardano:hasRawBytes` and `cardano:auxiliaryDataHash`:

```turtle
_:aux cardano:hasMetadatum [ cardano:metadataLabel 1694 ;
        cardano:metadatumValue [ a cardano:MetaMap ; … ] ] .
```

## 2. Query a nested metadata field (auditor UX)

Read the rationale `event` without touching CBOR:

```sparql
PREFIX cardano: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#>
SELECT ?event WHERE {
  ?tx cardano:hasAuxiliaryData ?aux .
  ?aux cardano:hasMetadatum ?m .
  ?m cardano:metadataLabel 1694 ;
     cardano:metadatumValue ?body1694 .
  ?body1694 cardano:hasEntry ?bodyEntry .
  ?bodyEntry cardano:metaKey   [ cardano:textValue "body" ] ;
             cardano:metaValue ?body .
  ?body cardano:hasEntry ?evEntry .
  ?evEntry cardano:metaKey   [ cardano:textValue "event" ] ;
           cardano:metaValue [ cardano:textValue ?event ] .
}
```

```bash
arq --data tx.ttl --query event.rq     # → "disburse"
```

## 3. Confirm chunked text stayed a list (faithfulness check)

```sparql
PREFIX cardano: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#>
SELECT (COUNT(?el) AS ?chunks) WHERE {
  ?desc a cardano:MetaList ; cardano:hasElement ?el .
  # … bound to the body.description value …
}
```

A multi-chunk `description` returns `?chunks > 1` — the core preserved
the on-chain array rather than joining it (that join is spec 063's typed
pass).

## 4. Target a transaction by label (prereq for hygiene shapes)

```sparql
ASK { ?tx cardano:hasAuxiliaryData/cardano:hasMetadatum [ cardano:metadataLabel 1694 ] }
```

This is the targeting primitive specs 063/065 build on — a shape can now
scope itself to "transactions carrying label 1694".
