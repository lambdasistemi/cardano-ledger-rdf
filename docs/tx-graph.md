# tx-graph

`tx-graph` emits Conway transactions as RDF. It loads an optional
operator overlay from `rules.yaml`, decodes one or more transaction CBOR
files, resolves inputs from the in-memory lattice, and writes canonical
Turtle or JSON-LD.

```text
tx-graph — pure (rules + [cbor]) -> ttl transformation

Usage: tx-graph [--rules FILE] [--in-dir DIR] [--out-dir DIR]
                [--format FORMAT] [CBOR...]

Available options:
  --rules FILE       Operator-authored rules file (.yaml/.yml or .ttl).
                     Used alone, emits overlay-only Turtle to stdout.
  --in-dir DIR       Directory of *.cbor files. Mutually exclusive with
                     positional CBOR arguments.
  CBOR...            Conway tx CBOR file paths. '-' reads one tx from stdin.
  --out-dir DIR      Write one <txid-hex>.ttl per input into DIR.
  --format FORMAT    Output format: 'turtle' or 'json-ld'. Default: turtle.
```

## Modes

| Input | Output |
|--|--|
| `--rules FILE` only | Overlay-only Turtle from the rules file. |
| One CBOR, no `--out-dir` | One graph on stdout. |
| Multiple CBORs or `--in-dir` | One graph per transaction in `--out-dir`. |

Multiple inputs require `--out-dir`. The input lattice resolves itself:
each CBOR is indexed by computed `TxId`, and spending/reference/collateral
inputs are resolved when the parent transaction is present in the same
batch. There is no node socket or UTxO JSON flag in this repo.

## Examples

Emit only the operator overlay:

```bash
tx-graph --rules rules/amaru-treasury.yaml
```

Emit one transaction graph to stdout:

```bash
tx-graph --rules rules/amaru-treasury.yaml tx.cbor > tx.ttl
```

Emit a fetched closure as one Turtle file per transaction:

```bash
tx-fetch --out-dir lattice --depth 1 013329ee... 107e439f...
tx-graph --rules rules/amaru-treasury.yaml --in-dir lattice/cbor --out-dir lattice
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

- [rules.yaml](rewriting-rules.md) documents the overlay language.
- [tx-fetch](tx-fetch.md) fetches a CBOR closure for lattice emission.
- [tx-view](tx-view.md) projects the emitted Turtle through packaged
  views.
