# cardano-ledger-rdf

`cardano-ledger-rdf` is the graph/RDF backend for Cardano transaction data.
It owns the reusable Haskell library plus the tools that build and
consume transaction graphs:

| Tool | Role |
|------|------|
| `tx-graph` | Convert Conway transaction CBOR plus operator rules into canonical Turtle or JSON-LD. Reads CBOR from a local file or fetches it by txid from an HTTP indexer (`--provider koios\|blockfrost\|http`). |
| `tx-view` | Project a generated Turtle graph through packaged views such as `cli-tree`, `asset-flow`, `entity-occurrences`, or `json-ld`. |

Generic applications such as transaction diffing, inspecting, signing,
validating, and load generation belong in `cardano-tx-tools`. That
suite can depend on this repository when those applications are backed
by `tx-graph` output.

Documentation: <https://lambdasistemi.github.io/cardano-ledger-rdf/>.

## Workflow

```bash
tx-graph --rules rules/amaru-treasury.yaml > lattice.ttl
while read -r txid; do
  tx-graph --provider koios "$txid"
done < selections.txt >> lattice.ttl
arq --data lattice.ttl --query my.rq    # consume directly via Apache Jena, or any SPARQL engine
```

`tx-graph --provider` is the only network boundary in the core pipeline:
it fetches CBOR by txid from a koios / blockfrost / generic-HTTP indexer.
With `--provider file` (the default) `tx-graph` reads CBOR from a local
path, and the overlay + SPARQL stages are offline transformations over
local files.

## Library

The main library contains:

| Module family | Role |
|---------------|------|
| `Cardano.Tx.Graph.*` | RDF graph emission, operator entity overlays, canonical Turtle/JSON-LD serialization. |
| `Cardano.Tx.View.*` | Packaged graph projections used by `tx-view` and future HTTP services. |
| `Cardano.Tx.Blueprint` | CIP-57 blueprint parsing for typed datum/redeemer predicates. |
| `Cardano.Tx.Decode` / `Cardano.Tx.Graph.Resolve` | Shared transaction decoding and resolved-input lookup for RDF tools. |

The repository boundary is graph/RDF. Downstream transaction diffing,
inspection, validation, and signing applications can depend on this
library instead of being owned here.

## Release

Release automation packages only the RDF tools:

```bash
nix build .#tx-graph-linux-release-artifacts
nix build .#tx-view-linux-release-artifacts
```

Darwin/Homebrew artifacts are built by the corresponding GitHub
Actions workflows for the same executables.

## Develop

```bash
nix develop --quiet -c just build
nix develop --quiet -c just ci
nix flake check --no-eval-cache
```

Specs and per-feature design notes live under `specs/`.

## License

[Apache 2.0](LICENSE).
