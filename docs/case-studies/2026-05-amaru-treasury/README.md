# Amaru Treasury May 2026 — case-study package

This directory ships the May 2026 Amaru Treasury operator package: the
overlay declaring entities and off-chain accountability, the CIP-57
blueprint that types the Sundae order datum, the SHACL shapes that
encode the invariants, and the human-readable presentation and SPARQL
evidence. The full prose is in [`case.md`](case.md); this file
documents the reproduce pipe.

## Reproduce

```bash
cq-rdf overlay --in overlay.yaml > overlay.ttl
xargs -P8 -n1 cq-rdf body --provider blockfrost < selections.txt > bodies.ttl
cat overlay.ttl bodies.ttl \
  | cq-rdf blueprint --blueprints blueprints/ \
  > package.ttl
cq-rdf shacl --shapes shapes/ < package.ttl
```

`package.ttl` is the typed lattice the case study's SPARQL queries run
against. `cq-rdf shacl --shapes shapes/` reads it on stdin and exits
non-zero on any shape violation; a zero exit means the operator-
declared invariants hold against the real on-chain data.

`xargs -P8` provides eight-way parallel CBOR fetching against
Blockfrost; substitute Koios (`--provider koios`), a local CBOR
directory (`--provider file <path>`), or any of the other providers
documented in `cq-rdf body --help` as appropriate. With Blockfrost,
export `BLOCKFROST_PROJECT_ID` and pass `--token "$BLOCKFROST_PROJECT_ID"`
to `cq-rdf body`.

## Files in this package

| Path | Role |
|---|---|
| [`overlay.yaml`](overlay.yaml) | Operator overlay: entities, vendors, attestations, with `imports: [treasury]`. |
| [`selections.txt`](selections.txt) | One Cardano transaction id per line — the 101-tx lattice. |
| `blueprints/sundae-order-typed.cip57.json` | Vendored SundaeSwap V3 CIP-57 blueprint (Apache-2.0) — types the Sundae order datum so the SHACL shapes can reach `tx:OrderDatum_destination`. |
| [`shapes/`](shapes/README.md) | SHACL invariants: self-swap (Q11 as a shape) and attested-disbursement. |
| `queries/` | One Markdown page per SPARQL query (Q0 through Q11), explaining and exhibiting the result. Reachable via [`case.md`](case.md). |
| [`case.md`](case.md) | Operator-facing presentation. |
| [`selection.md`](selection.md) | How the 101-tx lattice was assembled. |

The operator overlay relies on the case-study-external `treasury`
vocab (declared via `imports:`); `cq-rdf overlay` emits the matching
`owl:imports` so downstream SPARQL and SHACL tools can resolve the
predicate provenance.
