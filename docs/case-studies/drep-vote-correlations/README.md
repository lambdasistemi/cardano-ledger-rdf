# DRep Vote Correlations — case-study package

This directory ships the DRep Vote Correlations operator package: the
overlay declaring the two shared entities, the per-question Markdown
evidence, and the human-readable presentation. The full prose is in
[`case.md`](case.md); this file documents the reproduce pipe.

## Reproduce

```bash
cq-rdf overlay --in overlay.yaml > overlay.ttl
xargs -P8 -n1 cq-rdf body --provider koios < selections.txt > bodies.ttl
cat overlay.ttl bodies.ttl > package.ttl
```

`package.ttl` is the 5,299-tx lattice the case study's six SPARQL
queries run against. This case study uses no CIP-57 blueprints and
ships no SHACL shapes, so the `cq-rdf blueprint` and `cq-rdf shacl`
stages of the canonical pipe are dropped.

Substitute `--provider blockfrost --token "$BLOCKFROST_PROJECT_ID"`
for higher Blockfrost throughput, or any other supported provider.

## Files in this package

| Path | Role |
|---|---|
| [`overlay.yaml`](overlay.yaml) | Operator overlay: two entities (guard policy + treasury beneficiary stake credential). No `imports:` — cardano-prefix predicates only. |
| [`selections.txt`](selections.txt) | One Cardano transaction id per line — the 5,299-tx lattice (11 action submissions + 5,288 vote transactions). |
| `queries/` | One Markdown page per SPARQL query (Q1 through Q6), explaining and exhibiting the result. Reachable via [`case.md`](case.md). |
| [`case.md`](case.md) | Operator-facing presentation. |
| [`selection.md`](selection.md) | How the 5,299-tx lattice was assembled. |
