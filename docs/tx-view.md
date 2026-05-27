# tx-view

`tx-view` reads one canonical Turtle graph file and renders a named
packaged projection. It is the local, offline presentation step after
[`tx-graph`](tx-graph.md) has emitted `.ttl`.

```bash
tx-view --graph lattice.ttl --view cli-tree
```

```text
tx-view - packaged-view dispatcher over canonical Turtle graphs

Usage: tx-view --graph FILE [--view NAME] [--out FILE]

Available options:
  --graph FILE   Canonical Turtle graph file (from tx-graph).
  --view NAME    Packaged view name. Default: "cli-tree".
  --out FILE     Output destination. Default: stdout.
  -h,--help      Show the help text.
```

## Inputs

`--graph FILE` must point at a single `.ttl` file in the canonical Turtle
subset emitted by `tx-graph`. The command has no network access and does
not read CBOR, rules, or a directory of graphs.

The file may be a one-transaction graph or a merged lattice emitted by
`tx-graph --in-dir DIR --out lattice.ttl`. The `json-ld` and
`entity-occurrences` views project the parsed file as a whole. The
transaction-shaped text views, `cli-tree` and `asset-flow`, render the
first `cardano:Transaction` subject found by the current in-repo reader;
for per-transaction presentation, run them against per-transaction `.ttl`
files from `tx-graph --out-dir`.

Use `--out FILE` to write the rendered bytes to a file instead of stdout:

```bash
tx-view --graph lattice.ttl --view json-ld --out lattice.jsonld
```

## Packaged Views

### cli-tree

Text tree for a transaction body: inputs, reference inputs, outputs,
assets, datum/reference-script details, minting, withdrawals,
certificates, proposals, collateral, and fee. This is the default view.

```bash
tx-view --graph tx.ttl --view cli-tree
```

### asset-flow

Tab-separated rows summarising value movement as
`assetClass quantity source destination`, including ADA, native assets,
mint rows, and withdrawals.

```bash
tx-view --graph tx.ttl --view asset-flow
```

### entity-occurrences

Tab-separated rows summarising operator-declared entities and the number
of explicit identifier leaf sites on each declaration.

```bash
tx-view --graph lattice.ttl --view entity-occurrences
```

### json-ld

Deterministic JSON-LD projection of the parsed Turtle graph, with the same
subjects, predicates, and objects represented under `@context` and
`@graph`.

```bash
tx-view --graph lattice.ttl --view json-ld
```

## Shipped SPARQL Contract

`views/no-stub-triples.rq` is shipped with the repository as a SPARQL
gate/query contract. It finds `cardano:Input` or `cardano:Output` subjects
that have only their `rdf:type` triple, which would indicate an emitted
stub. It is not a current `tx-view --view` name.

Run it directly with a SPARQL engine:

```bash
arq --data lattice.ttl --query views/no-stub-triples.rq
```

## Direct SPARQL

Packaged views are convenience projections. For custom analysis, query the
same Turtle graph directly:

```bash
arq --data lattice.ttl --query my.rq
```

This is the right path for questions that are not one of the packaged
`tx-view --view` names.
