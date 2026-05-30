# Case Study Template

This directory is the canonical scaffold for future case studies. Keep
the dataset-selection method, txid list, operator overlay, optional
blueprints + shapes, presentation, and query evidence in separate files
so readers can reproduce the lattice and audit each numeric claim.

## Reproduce

```bash
cq-rdf overlay --in overlay.yaml > overlay.ttl
xargs -P8 -n1 cq-rdf body --provider koios < selections.txt > bodies.ttl
cat overlay.ttl bodies.ttl \
  | cq-rdf blueprint --blueprints blueprints/ \
  > package.ttl
cq-rdf shacl --shapes shapes/ < package.ttl
```

Drop the `cq-rdf blueprint` step (and pipe `cat overlay.ttl
bodies.ttl > package.ttl` directly) if the case study has no
`blueprints/`. Drop the `cq-rdf shacl` line if it has no `shapes/`.
Substitute any provider supported by `cq-rdf body` (`--provider
blockfrost --token "$BLOCKFROST_PROJECT_ID"`, `--provider file`, …).

## Files in this template

| Path | Role |
|---|---|
| [`overlay.yaml`](overlay.yaml) | Operator overlay: entities, vendors, attestations, with `imports:` if needed. |
| [`selections.txt`](selections.txt) | One Cardano transaction id per line. |
| `blueprints/` | Optional CIP-57 typed-decode schemas. |
| `queries/` | One Markdown page per SPARQL query. Reachable via [`case.md`](case.md). |
| [`case.md`](case.md) | Operator-facing presentation. |
| [`selection.md`](selection.md) | How the lattice was assembled. |
