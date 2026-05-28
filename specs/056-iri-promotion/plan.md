# Plan - IRI promotion for cross-response composability

Issue: [#56](https://github.com/lambdasistemi/cardano-ledger-rdf/issues/56)

## Tech Stack

- Haskell emitter under `Cardano.Tx.Graph.Emit.*`.
- Existing typed triple IR with `Subject` and `Object` carrying either blank
  nodes or IRIs.
- Hspec golden harness with `EMIT_GOLDEN_REGEN=1`.
- Apache Jena `arq` for the cat-merge SPARQL property.

## Design

Add IRI minting helpers in the lookup/emitter layer:

- `urn:cardano:tx:<txid_hex>` for transaction subjects.
- `urn:cardano:utxo:<txid_hex>:<index>` for output subjects.
- `urn:cardano:id:<LeafType>:<identifier>` for hash and credential identifiers.

Identifier literal blocks remain, but their subject becomes the identifier IRI.
Operator entity overlays keep their entity nodes while pointing
`cardano:hasIdentifier` at the same identifier IRIs.

The existing lattice bnode scoping function becomes the universal blank-node
scoping policy. `emit` applies it to every graph using the current transaction
id; lattice serialization remains idempotent by avoiding double-prefixing.
Address decomposition nodes are minted from credential hex and excluded from
transaction-id scoping.

## Golden Strategy

Regenerate every `test/fixtures/tx-graph/*/expected.ttl` through the existing
golden harness. Regenerate canonical vocabulary output if the vocab exporter
diffs. Review the cascade for only the intended identity and prefix changes.

## Query Strategy

Most case-study queries bind graph structure through predicates and do not name
blank-node labels directly. Search for literal `_:hash_` and `_:cred_`
patterns and update only the queries that depend on old bnode labels.

## Single-Slice Rationale

The transaction subject, output subject, identifier nodes, and blank-node
scoping policy are one composability contract. Splitting them would leave
intermediate commits where response Turtle still cannot be safely composed.
