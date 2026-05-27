# Case Study Title

State the operator question, the dataset size, and why RDF/SPARQL is the
right interface for the report.

## Dataset and queries

Dataset assembly is documented in [Dataset selection](selection.md), with
the full txid list in [`selections.txt`](selections.txt) and the entity
overlay in [`rules.yaml`](rules.yaml). Query evidence lives under
[`queries/`](queries/q-example.md).

## Entity rules

Use [`rules.yaml`](rules.yaml) to name case-study entities with the supported
tx-graph shapes: `from-address`, `script`, `asset`, `pool`, `drep`, and
`keys` plus `bytes`. The same file can also register CIP-57 blueprints and
IPFS attestations, and it can describe off-chain entities through
`paid-via`.

## Findings

Summarize the key numeric findings here and link each claim to the query
page that produces it.

## How to reproduce

```sh
./pipeline.sh out
arq --data out/lattice.ttl --query q-example.rq
```
