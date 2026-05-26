# tx-lattice

`scripts/tx-lattice` is a thin Bash wrapper around
[`tx-fetch`](tx-fetch.md) and [`tx-graph`](tx-graph.md). It fetches a
CBOR closure for one or more seed transaction ids, then emits one Turtle
graph per CBOR in the closure.

It is a development convenience script, not a released executable. The
released tools are `tx-fetch`, `tx-graph`, and `tx-view`.

## Quickstart

```bash
nix build .#tx-fetch .#tx-graph .#tx-view

export BLOCKFROST_PROJECT_ID=mainnet...

./scripts/tx-lattice \
  --rules rules/amaru-treasury.yaml \
  --out-dir ./out \
  --network mainnet \
  --depth 1 \
  18d57a4f3094228a05c4d9b04ac41ad07f97c11a3cfff8c30b7d7f902c2306c0
```

This writes fetched CBORs under `out/cbor/` and emitted Turtle files as
`out/<txid>.ttl`.

Then project one graph through a packaged view:

```bash
./result/bin/tx-view --graph ./out/<txid>.ttl --view cli-tree
```

Or run a SPARQL query across all emitted graphs:

```bash
nix-shell -p apache-jena --run \
  "sparql $(printf -- '--data %s ' ./out/*.ttl) --query my-query.rq"
```

## CLI Surface

```text
tx-lattice [--rules rules.yaml] --out-dir DIR
           [--network mainnet|preprod|preview] [--depth N]
           <txId1> <txId2> ... <txIdN>
```

- `--rules` is optional. When present, the same operator overlay is fed
  to every `tx-graph` invocation.
- `--out-dir` is required.
- `--network` selects the Blockfrost host. Default: `mainnet`.
- `--depth` is passed to `tx-fetch`. Default: `1`.

## Environment

| Variable | Meaning |
|--|--|
| `BLOCKFROST_PROJECT_ID` | Required by `tx-fetch`. |
| `TX_FETCH_EXE` | Optional path to a `tx-fetch` binary. |
| `TX_GRAPH_EXE` | Optional path to a `tx-graph` binary. |

## Known Limitations

The lattice closes transaction-input parents, but it does not infer
business intent on its own. For swap-order outputs, the graph can name
the script that holds funds immediately; finding the eventual human
recipient requires either a cross-transaction JOIN through the scoop
transaction or a blueprint-decoded datum field that exposes the recipient
credential.

## See Also

- [tx-fetch](tx-fetch.md) fetches the CBOR closure.
- [tx-graph](tx-graph.md) emits canonical Turtle/JSON-LD.
- [tx-view](tx-view.md) projects generated graphs.
- [rules.yaml](rewriting-rules.md) documents the operator overlay.
