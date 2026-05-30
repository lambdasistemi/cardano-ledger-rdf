# Case Study Title

State the operator question, the dataset size, and why RDF/SPARQL is the
right interface for the report.

## Dataset and queries

Dataset assembly is documented in [Dataset selection](selection.md), with
the full txid list in [`selections.txt`](selections.txt), the entity
overlay in [`overlay.yaml`](overlay.yaml), and the reproduce pipe in
[`README.md`](README.md). Query evidence lives under
[`queries/`](queries/q-example.md).

## Entity rules

Use [`overlay.yaml`](overlay.yaml) to name case-study entities with the
supported `cq-rdf overlay` shapes: `from-address`, `script`, `asset`,
`pool`, `drep`, and `keys` plus `bytes`. The same file can also describe
off-chain entities through `paid-via` (with `imports: [treasury]`) and
declare IPFS-anchored attestations.

## Findings

Summarize the key numeric findings here and link each claim to the query
page that produces it.

## How to reproduce

See [`README.md`](README.md) for the full reproduce pipe. In summary,
from this directory:

```bash
cq-rdf overlay --in overlay.yaml > overlay.ttl
xargs -P8 -n1 cq-rdf body --provider koios < selections.txt > bodies.ttl
cat overlay.ttl bodies.ttl > package.ttl
arq --data package.ttl --query q-example.rq
```
