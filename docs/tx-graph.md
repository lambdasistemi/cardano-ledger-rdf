# tx-graph

`tx-graph` emits Conway transactions as RDF. It loads an optional
operator overlay from `rules.yaml`, decodes one transaction CBOR, and
writes canonical Turtle or JSON-LD. The CBOR comes from a local file
(the default) or is fetched by txid from an HTTP indexer via
`--provider`. Multi-transaction lattices are ordinary concatenations of
one-transaction Turtle streams.

```text
tx-graph — pure (rules + cbor) -> ttl transformation

Usage: tx-graph [--rules FILE]
                [--provider PROVIDER [--token TOKEN] [--url URL]]
                (CBOR-or-TXID)
                [--in FILE] [--out FILE] [--format FORMAT]

Available options:
  --rules FILE       Operator-authored rules file (.yaml/.yml or .ttl).
                     Used alone, emits overlay-only Turtle to stdout.
  --provider PROVIDER  CBOR source: file | koios | blockfrost | http
                     (default: file). With a fetching provider the
                     positional argument / --in is a 64-hex txid.
  --token TOKEN      Bearer / API token (blockfrost project_id;
                     optional koios / http bearer).
  --url URL          Provider base URL. Required for 'http'; overrides
                     the default for koios / blockfrost.
  CBOR               Conway tx CBOR file path (file mode) or a txid
                     (provider mode). '-' reads one tx from stdin.
  --in FILE          Read input from FILE instead of the positional.
  --out FILE         Write one graph to FILE instead of stdout.
  --format FORMAT    Output format: 'turtle' or 'json-ld'. Default: turtle.
```

## Modes

| Input | Output |
|--|--|
| `--rules FILE` only | Overlay-only Turtle from the rules file. |
| One CBOR (file) | One graph on stdout. |
| `--provider koios <txid>` | Fetched CBOR emitted as one graph on stdout. |
| One CBOR with `--out FILE` | One graph in `FILE`. |

## Providers

With `--provider`, the positional argument / `--in` is interpreted as a
64-hex transaction id and `tx-graph` fetches the CBOR before emitting.
The emitted graph is byte-identical to emitting the same CBOR read from
a local file, so a fetched lattice composes exactly like an on-disk one.

| Provider | Endpoint | Auth |
|--|--|--|
| `koios` | `POST <url>/tx_cbor` (default `https://api.koios.rest/api/v1`) | optional `--token` bearer (free public tier) |
| `blockfrost` | `GET <url>/txs/<txid>/cbor` (default `https://cardano-mainnet.blockfrost.io/api/v0`) | `--token` sent as `project_id` (required) |
| `http` | `GET <url>/<txid>` (generic indexer) | optional `--token` bearer; `--url` required |

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

Emit a fetched lattice as one merged Turtle stream for SPARQL, fetching
each transaction by txid from koios:

```bash
tx-graph --rules rules/amaru-treasury.yaml > lattice.ttl
while read -r txid; do
  tx-graph --provider koios "$txid"
done < selections.txt >> lattice.ttl
```

The rules overlay is semantically idempotent, so writing it once before
the loop (rather than repeating `--rules` per transaction) keeps the
Turtle file smaller without changing SPARQL answers. The same pattern
works against local CBOR files in `--provider file` mode:

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
- SPARQL engines can consume the emitted Turtle directly.
