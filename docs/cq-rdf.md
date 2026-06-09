# cq-rdf

`cq-rdf` (Cardano + RDF) is the runtime that projects Cardano ledger
data into RDF. It ships four orthogonal subcommands that compose with
each other via plain shell pipes. There is no meta-orchestrator
subcommand and no recipe file — composition is the operator's
documented `bash` pipe.

The same four subcommands serve two consumers: a transaction **author**
runs the pipe over a tx they just built and reads `shacl` as a pre-sign
gate; an **auditor** runs it over a lattice of on-chain txids and reads
`shacl` + SPARQL as a classifier. Both are parametrized by the same
app-shipped assets — see [For app developers](for-app-developers.md).

| Subcommand | Pure function | Reads | Writes |
|---|---|---|---|
| [`overlay`](#overlay) | operator YAML → overlay TTL | `--in overlay.yaml` (or stdin) | overlay-only Turtle |
| [`body`](#body) | one tx CBOR or txid → body TTL | positional / `--in` / `--provider … <txid>` | one body's Turtle |
| [`blueprint`](#blueprint) | TTL → typed TTL (CIP-57 pass) | stdin | stdin extended with typed triples |
| [`shacl`](#shacl) | TTL → SHACL report (non-zero on violation) | stdin | SHACL validation report |

```text
Usage: cq-rdf COMMAND

  Pure subcommands: overlay (YAML/Turtle to overlay TTL), body (txid/CBOR to
  body TTL), blueprint (TTL to typed TTL), and shacl (TTL to validation
  report).

Available commands:
  overlay     Read an overlay YAML/Turtle file and emit overlay-only Turtle.
  body        Read one transaction CBOR path/stdin or fetch one txid via
              --provider, then emit body-only RDF.
  blueprint   Read Turtle on stdin and append CIP-57 typed datum triples.
  shacl       Read Turtle on stdin and emit a SHACL validation report.
```

## Composing a lattice

The shape every case study follows. Each step is visible, every input
file is named, and every output is a Turtle stream that concatenates
cleanly with the next stage:

```bash
cq-rdf overlay --in overlay.yaml > overlay.ttl
xargs -P8 -n1 cq-rdf body --provider blockfrost < selections.txt > bodies.ttl
cat overlay.ttl bodies.ttl \
  | cq-rdf blueprint --blueprints blueprints/ \
  > package.ttl
cq-rdf shacl --shapes shapes/ < package.ttl
```

The first line emits the operator overlay once; the second fetches and
emits one body per txid in parallel; the third concatenates them and
runs the CIP-57 typed-decode pass; the fourth validates the result
against the operator's SHACL shapes (non-zero exit on violation).

## `overlay`

Pure YAML/Turtle → Turtle. No provider, no network, no CBOR decoding.
The output declares its `owl:imports` block so downstream consumers can
resolve vocabulary provenance.

```text
Usage: cq-rdf overlay [--in FILE] [--out FILE]

  --in FILE                Read overlay YAML/Turtle from FILE; '-' or
                           omitted reads stdin.
  --out FILE               Write overlay Turtle to FILE instead of stdout.
```

See [`overlay.yaml`](overlay-yaml.md) for the input format: the
`imports:` block, entity declarations, blueprints, attestations.

## `body`

One transaction at a time. Reads either a Conway tx CBOR (positional /
`--in`) or fetches one by txid via `--provider`. Parallelism is the
operator's choice — `xargs -P`, GNU `parallel`, a `while read` loop —
since the function is pure per transaction.

```text
Usage: cq-rdf body [--provider PROVIDER] [--token TOKEN] [--url URL]
                   [CBOR|TXID] [--in FILE] [--out FILE] [--format FORMAT]

  --provider PROVIDER      CBOR source: file | koios | blockfrost | http
                           (default: file). With a fetching provider the
                           positional argument / --in is a 64-hex txid.
  --token TOKEN            Bearer / API token for the provider.
  --url URL                Provider base URL.
  CBOR|TXID                Conway tx CBOR file path, '-' for stdin, or
                           a txid with --provider.
  --format FORMAT          Output format: 'turtle' or 'json-ld'.
```

| Provider | Endpoint | Auth |
|---|---|---|
| `koios` | `POST <url>/tx_cbor` (default `https://api.koios.rest/api/v1`) | optional `--token` bearer |
| `blockfrost` | `GET <url>/txs/<txid>/cbor` (default `https://cardano-mainnet.blockfrost.io/api/v0`) | `--token` sent as `project_id` (required) |
| `http` | `GET <url>/<txid>` | optional `--token` bearer; `--url` required |

The emitted graph is byte-identical between the providers and a local
CBOR file, so fetched lattices compose exactly like on-disk ones.

## `blueprint`

Reads a Turtle lattice on stdin, scans the `--blueprints DIR` directory
for `*.cip57.json` schemas keyed by validator hash, decodes any datums
or redeemers it matches, and appends typed sub-triples. Idempotent.

```text
Usage: cq-rdf blueprint --blueprints DIR

  --blueprints DIR         Directory containing *.cip57.json blueprint files.
```

Decode failures keep the raw bytes and add `cardano:decodeError`.

## `shacl`

Reads a Turtle lattice on stdin, loads every `*.shacl.ttl` in
`--shapes DIR`, runs SHACL validation, and exits non-zero on
violations. An empty conformance report is a pass.

```text
Usage: cq-rdf shacl --shapes DIR [--out FILE] [--severity SEVERITY]

  --shapes DIR             Directory containing *.shacl.ttl shape files.
  --out FILE               Write the SHACL report to FILE.
  --severity SEVERITY      Failure threshold: violation or warning.
                           (default: ShaclViolationOnly)
```

This is how a case study expresses invariants such as *every swap that
involves the treasury returns to the treasury* or *every disbursement
has an off-chain attestation* — see the
[May 2026 Amaru Treasury shapes](case-studies/2026-05-amaru-treasury/shapes/README.md).

## Output

The Turtle output of `cq-rdf body` is byte-stable and grouped as:

1. Prefix declarations for `cardano:`, `rdfs:`, and the fixture-local
   `:` namespace.
2. Transaction body triples for inputs, reference inputs, outputs,
   withdrawals, minting, certificates, collateral, governance fields,
   validity interval, fees, redeemers, and witnesses.
3. Address decomposition triples linking addresses to payment and
   stake credentials.

`cq-rdf overlay` emits its own `owl:Ontology` block declaring
`owl:imports` for every resolved vocabulary, followed by entity and
attestation triples. `cq-rdf blueprint` appends typed datum/redeemer
triples in place. `cq-rdf shacl` emits a standard SHACL conformance
report.

JSON-LD (via `cq-rdf body --format json-ld`) serializes the same triple
set as `@context` plus a flat `@graph`.

## See also

- [`overlay.yaml`](overlay-yaml.md) — the operator overlay format.
- [`tx-view`](tx-view.md) — packaged projections over an emitted graph.
- [`tx-graph`](tx-graph.md) — deprecated one-release compatibility
  symlink for the previous CLI shape.
