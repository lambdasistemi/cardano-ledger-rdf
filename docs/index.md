# cardano-ledger-rdf

`cardano-ledger-rdf` is the graph/RDF backend for Cardano transaction data.
It owns the `cardano:` ontology and the tools that emit canonical graphs
from transaction CBOR and project those graphs through packaged views.

## Vocabulary

The `cardano:` namespace is defined by an ontology hosted from this repo at
`https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#`. See
[Vocabulary](vocab.md) for ownership, IRI, and standard SPARQL prefix.

## Tools

- [**tx-graph**](tx-graph.md) turns Conway transaction CBOR plus
  operator [`rules.yaml`](rules-yaml.md) into Turtle or JSON-LD. It reads
  CBOR from a local file or fetches it by txid from an HTTP indexer
  (`--provider koios|blockfrost|http`).
- [**tx-view**](tx-view.md) projects a generated Turtle graph through
  packaged views (`cli-tree`, `asset-flow`, `entity-occurrences`,
  `json-ld`).

Generic transaction tools such as inspect, diff, sign, and load
generation remain `cardano-tx-tools` applications. They can depend on
this repository when their backend is a generated graph.

## Pipeline

```bash
tx-graph --rules rules/amaru-treasury.yaml > lattice.ttl
while read -r txid; do
  tx-graph --provider koios "$txid"
done < selections.txt >> lattice.ttl
arq --data lattice.ttl --query my.rq    # consume directly via Apache Jena, or any SPARQL engine
```

The SPARQL stage is offline and deterministic. The only network boundary
is `tx-graph --provider`, which fetches CBOR by txid from a koios /
blockfrost / generic-HTTP indexer; with `--provider file` (the default)
`tx-graph` reads CBOR from a local path instead.

## Library Surface

| Module family | Role |
|---------------|------|
| `Cardano.Tx.Graph.*` | RDF graph emission, operator overlays, canonical serialization. |
| `Cardano.Tx.View.*` | Packaged graph projections. |
| `Cardano.Tx.Blueprint` | CIP-57 blueprint parsing for typed graph predicates. |
| `Cardano.Tx.Decode` / `Cardano.Tx.Graph.Resolve` | Shared transaction decoding and resolved-input lookup for RDF tools. |

The repository boundary is graph/RDF. Downstream transaction diffing,
inspection, signing, and load generation remain `cardano-tx-tools`
applications.

## Release

Release automation packages `tx-graph` and `tx-view`.
Workflow secrets are populated by operators outside agent sessions.
