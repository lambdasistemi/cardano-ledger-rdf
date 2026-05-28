# tx-graph

`tx-graph` emits Conway transactions as RDF. It loads an optional
operator overlay from `rules.yaml`, decodes one transaction CBOR file,
and writes canonical Turtle or JSON-LD. Multi-transaction lattices are
ordinary concatenations of one-transaction Turtle streams.

```text
tx-graph — pure (rules + cbor) -> ttl transformation

Usage: tx-graph [--rules FILE] [--out FILE] [--format FORMAT] [CBOR]

Available options:
  --rules FILE       Operator-authored rules file (.yaml/.yml or .ttl).
                     Used alone, emits overlay-only Turtle to stdout.
  CBOR               Conway tx CBOR file path. '-' reads one tx from stdin.
  --out FILE         Write one graph to FILE instead of stdout.
  --format FORMAT    Output format: 'turtle' or 'json-ld'. Default: turtle.
```

## Modes

| Input | Output |
|--|--|
| `--rules FILE` only | Overlay-only Turtle from the rules file. |
| One CBOR | One graph on stdout. |
| One CBOR with `--out FILE` | One graph in `FILE`. |

Each transaction body scopes positional blank nodes with the first eight
hex characters of that transaction id. Content-addressed identifier IRIs
and `hash_` / `cred_` blank nodes are preserved for cross-transaction
joins, so concatenating Turtle output creates a SPARQL-composable lattice.
There is no node socket or UTxO JSON flag in this repo.

## Examples

Emit only the operator overlay:

```bash
tx-graph --rules rules/amaru-treasury.yaml
```

Emit one transaction graph to stdout:

```bash
tx-graph --rules rules/amaru-treasury.yaml tx.cbor > tx.ttl
```

Emit a fetched closure as one merged Turtle lattice for SPARQL:

```bash
tx-fetch --out-dir lattice --depth 1 013329ee... 107e439f...
for f in lattice/cbor/*.cbor; do
  tx-graph --rules rules/amaru-treasury.yaml "$f"
done > lattice.ttl
```

The rules overlay is semantically idempotent, so repeating
`--rules` in the loop does not change SPARQL answers. The recommended
operator pattern writes the overlay once and emits body graphs without
rules to keep the Turtle file smaller:

```bash
tx-graph --rules rules/amaru-treasury.yaml > lattice.ttl
for f in lattice/cbor/*.cbor; do
  tx-graph "$f"
done >> lattice.ttl
```

Emit JSON-LD:

```bash
tx-graph --rules rules/amaru-treasury.yaml --format json-ld tx.cbor > tx.jsonld
```

## Output

The Turtle output is byte-stable and grouped as:

1. Prefix declarations for `cardano:`, `rdfs:`, and the fixture-local
   `:` namespace.
2. Operator-declared entities and attestations from the rules overlay.
3. Transaction body triples for inputs, reference inputs, outputs,
   withdrawals, minting, certificates, collateral, governance fields,
   validity interval, fees, redeemers, and witnesses.
4. Address decomposition triples linking addresses to payment and stake
   credentials.
5. Blueprint-decoded datum/redeemer triples when a registered CIP-57
   blueprint matches the script. Decode failures retain raw bytes and add
   `cardano:decodeError`.

JSON-LD serializes the same triple set as `@context` plus a flat
`@graph`.

## See Also

- [rules.yaml](rules-yaml.md) documents the overlay language.
- [tx-fetch](tx-fetch.md) fetches a CBOR closure for lattice emission.
- SPARQL engines can consume the emitted Turtle directly.
