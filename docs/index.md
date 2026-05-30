# cardano-ledger-rdf

`cardano-ledger-rdf` is the graph/RDF backend for Cardano transaction data.
It owns the `cardano:` and `treasury:` ontologies and the runtime that
projects ledger data into RDF and runs typed-decode and SHACL validation
passes over it.

!!! tip "New here? Start with the [Demo](demo.md)"
    The [end-to-end demo](demo.md) walks the `cq-rdf body | tx-view`
    pipeline on a real mainnet transaction — bare vs. operator-typed —
    then composes the whole May 2026 Amaru treasury batch into one
    lattice and answers cross-tx SPARQL questions, with a recorded
    terminal cast.

## Vocabularies

Two namespaces, each with a published ontology:

| Prefix | Namespace IRI | Layer |
|---|---|---|
| `cardano:` | `https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#` | Ledger primitives (`Transaction`, `Output`, `Datum`, …) |
| `treasury:` | `https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/treasury#` | Treasury / accountability overlay (`OffChainEntity`, `paidVia`, `attests`, …) |

See [Vocabulary](vocab.md) for ownership, dereference URLs, and the
standard SPARQL prefix block.

## Tools

- [**cq-rdf**](cq-rdf.md) is the runtime. Four subcommands — `overlay`,
  `body`, `blueprint`, `shacl` — each a pure function with a narrow IO
  contract that composes with the others through shell pipes.
- [**tx-view**](tx-view.md) projects a generated Turtle graph through
  packaged views (`cli-tree`, `asset-flow`, `entity-occurrences`,
  `json-ld`).
- [`tx-graph`](tx-graph.md) is a deprecated one-release compatibility
  symlink to `cq-rdf body`.

Generic transaction tools such as inspect, diff, sign, and load
generation remain `cardano-tx-tools` applications. They can depend on
this repository when their backend is a generated graph.

## Pipeline

The canonical four-stage pipe — emit overlay, fan out one body per
txid, run the typed-decode pass, validate against SHACL:

```bash
cq-rdf overlay --in overlay.yaml > overlay.ttl
xargs -P8 -n1 cq-rdf body --provider blockfrost < selections.txt > bodies.ttl
cat overlay.ttl bodies.ttl \
  | cq-rdf blueprint --blueprints blueprints/ \
  > package.ttl
cq-rdf shacl --shapes shapes/ < package.ttl
arq --data package.ttl --query my.rq    # consume via Apache Jena or any SPARQL engine
```

The SPARQL stage is offline and deterministic. The only network
boundary is `cq-rdf body --provider`, which fetches CBOR by txid from a
koios / blockfrost / generic-HTTP indexer; with `--provider file` (the
default) `cq-rdf body` reads CBOR from a local path instead.

Case studies under [Case studies](case-studies/index.md) ship this
exact pipe in their `README.md`, plus their `overlay.yaml`,
`selections.txt`, `blueprints/`, and `shapes/`.

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

Release automation packages `cq-rdf`, `tx-view`, and the deprecated
`tx-graph` compatibility symlink. Workflow secrets are populated by
operators outside agent sessions.
