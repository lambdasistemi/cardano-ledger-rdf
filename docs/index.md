# cardano-rdf

`cardano-rdf` is the graph/RDF backend for Cardano transaction data.
It owns the tools that fetch transaction CBOR, emit canonical graphs,
and project those graphs through packaged views.

## Tools

- [**tx-fetch**](tx-fetch.md) fetches seed transaction ids and their
  parent CBOR closure into a local lattice.
- [**tx-graph**](tx-graph.md) turns Conway transaction CBOR plus
  operator rules into Turtle or JSON-LD.

Generic transaction tools such as inspect, diff, sign, validate, and
load generation remain `cardano-tx-tools` applications. They can depend
on this repository when their backend is a generated graph.

## Pipeline

```bash
tx-fetch --out-dir lattice/cbor --depth 1 <seed-txid> ...
tx-graph --rules rules/amaru-treasury.yaml --in-dir lattice/cbor --out lattice.ttl
arq --data lattice.ttl --query my.rq    # consume directly via Apache Jena, or any SPARQL engine
```

The graph and SPARQL stages are offline and deterministic. `tx-fetch`
is the boundary that talks to Blockfrost-compatible chain APIs.

## Library Surface

| Module family | Role |
|---------------|------|
| `Cardano.Tx.Graph.*` | RDF graph emission, operator overlays, canonical serialization. |
| `Cardano.Tx.View.*` | Packaged graph projections. |
| `Cardano.Tx.Blueprint` | CIP-57 blueprint parsing for typed graph predicates. |
| `Cardano.Tx.Decode` / `Cardano.Tx.Graph.Resolve` | Shared transaction decoding and resolved-input lookup for RDF tools. |

The repository boundary is graph/RDF. Downstream transaction diffing,
inspection, validation, signing, and load generation remain
`cardano-tx-tools` applications.

## Release

Release automation packages `tx-graph` and `tx-fetch`. Workflow secrets
are populated by operators outside agent sessions.
