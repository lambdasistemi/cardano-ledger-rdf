# cardano-ledger-rdf

`cardano-ledger-rdf` turns any Cardano transaction into a deterministic
RDF graph that two people can actually *use*: **transaction authors**
checking a transaction against an application's rules *before* they sign
it, and **auditors** querying and classifying what happened on-chain
across a whole lattice of transactions. Both run on the same generic
engine; what teaches it a particular application's language is a bundle
of RDF assets the application developer ships.

!!! tip "New here? Start with the [Demo](demo.md)"
    The [end-to-end demo](demo.md) walks the `cq-rdf body | tx-view`
    pipeline on a real mainnet transaction — bare vs. operator-typed —
    then composes the whole May 2026 Amaru treasury batch into one
    lattice and answers cross-tx SPARQL questions, with a recorded
    terminal cast.

## Two personas, one artefact

| Persona | When | What they run | What they get |
|---|---|---|---|
| **Author** | before signing / submitting | `cq-rdf shacl --shapes app-shapes/` over the transaction they just built | a gate: non-zero exit + a readable, domain-level violation, so a non-conforming tx never reaches a co-signer |
| **Auditor** | after the fact | the *same* shapes + SPARQL over a lattice of on-chain txids | a classifier: conforms ⇒ built by the canonical pipeline; violates ⇒ foreign / off-spec |

The author gate and the auditor classifier are not two tools — they are
the same graph and the same shapes, pointed at different inputs.

## App-developer-parametrized RDF assets

The engine is generic; an application is expressed as a small bundle of
RDF assets the developer ships and parametrizes:

| Asset | Slot | Parametrizes |
|---|---|---|
| **overlay** | `cq-rdf overlay` | the app's entities, labels, attestations |
| **blueprints** | `cq-rdf blueprint` | typed datum/redeemer decode (CIP-57) |
| **metadata schemas** | `cq-rdf metadata` *(landing)* | typed interpretation of the app's transaction-metadata labels |
| **shapes** | `cq-rdf shacl` | SHACL conformance + hygiene constraints |

Case studies under [Case studies](case-studies/index.md) ship exactly
this bundle — their `overlay.yaml`, `selections.txt`, `blueprints/`,
`shapes/`, and queries — alongside the canonical pipe in their
`README.md`. The [2026-05 Amaru treasury](case-studies/2026-05-amaru-treasury/README.md)
study is the worked canary.

## Vocabularies

Two namespaces, each with a published ontology — the generic core and an
example explicit extension:

| Prefix | Namespace IRI | Layer |
|---|---|---|
| `cardano:` | `https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#` | Ledger primitives (`Transaction`, `Output`, `Datum`, metadata, …). The generic core. |
| `treasury:` | `https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/treasury#` | An accountability overlay (`OffChainEntity`, `paidVia`, `attests`, …). An explicit, app-shaped extension. |

The core models Cardano, never a single application's business
semantics; an app's meaning lives in its assets and its own extension
namespace. See [Vocabulary](vocab.md) for ownership, dereference URLs,
and the standard SPARQL prefix block.

## Pipeline

The canonical four-stage pipe — emit the app overlay, fan out one body
per txid, run the typed-decode pass, then validate against the app's
shapes (author gate) or query the lattice (auditor):

```bash
cq-rdf overlay --in overlay.yaml > overlay.ttl
xargs -P8 -n1 cq-rdf body --provider blockfrost < selections.txt > bodies.ttl
cat overlay.ttl bodies.ttl \
  | cq-rdf blueprint --blueprints blueprints/ \
  > package.ttl
cq-rdf shacl --shapes shapes/ < package.ttl     # author gate
arq --data package.ttl --query my.rq            # auditor: Apache Jena or any SPARQL engine
```

The SPARQL and SHACL stages are offline and deterministic. The only
network boundary is `cq-rdf body --provider`, which fetches CBOR by txid
from a koios / blockfrost / generic-HTTP indexer; with `--provider file`
(the default) `cq-rdf body` reads CBOR from a local path instead.

## Tools

- [**cq-rdf**](cq-rdf.md) is the runtime. Four subcommands — `overlay`,
  `body`, `blueprint`, `shacl` — each a pure function with a narrow IO
  contract that composes through shell pipes.
- [**tx-view**](tx-view.md) projects a generated Turtle graph through
  packaged views (`cli-tree`, `asset-flow`, `entity-occurrences`,
  `json-ld`).
- [`tx-graph`](tx-graph.md) is a deprecated one-release compatibility
  symlink to `cq-rdf body`.

Generic transaction tools such as inspect, diff, sign, and load
generation remain `cardano-tx-tools` applications. They can depend on
this repository when their backend is a generated graph.

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
