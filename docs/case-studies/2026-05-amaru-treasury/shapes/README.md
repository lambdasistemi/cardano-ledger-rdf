# SHACL shapes — Amaru Treasury May 2026

This directory ships the operator-authored SHACL shapes that the
May 2026 case study enforces as invariants. Each `*.shacl.ttl`
file declares one invariant; `cq-rdf shacl --shapes <dir>` runs
every shape in the directory in one pass and exits non-zero on
violations.

## Shapes shipped

| Shape file | Invariant |
|---|---|
| [`self-swap.shacl.ttl`](self-swap.shacl.ttl) | Every operator-issued Sundae OrderDatum routes its output back to `network_compliance`. Machine form of [Q11](../queries/q11-self-swap-validation.md). |
| [`attested-disbursement.shacl.ttl`](attested-disbursement.shacl.ttl) | Every `treasury:OffChainEntity` declared with `treasury:paidVia` has at least one `treasury:Attestation` linked. |

## Reproduce on the May 2026 lattice

```bash
# Build the lattice (existing dev artefact; Phase 5 of #66 retires it).
[KOIOS_TOKEN=...] ./pipeline.sh ./out

# Type the lattice with the Sundae blueprint, then validate it.
cat ./out/lattice.ttl \
  | cq-rdf blueprint --blueprints ../../../test/fixtures/tx-graph/blueprints/sundaeswap-v3/ \
  | cq-rdf shacl    --shapes    shapes/
```

On the real May 2026 lattice this pipe exits 0: every operator-
issued Sundae order routes back to `network_compliance`, and every
declared off-chain vendor is attested.

## Notes

- `cq-rdf shacl` autoscans the directory for `*.shacl.ttl` files;
  add a shape by dropping a new `*.shacl.ttl` file in here.
- Shapes use `sh:sparql` constraints when the path through the
  graph navigates blank nodes or predicates that aren't simple
  property paths (the self-swap shape is the typical case).
- The `tx:` prefix used by `self-swap.shacl.ttl` resolves to
  `https://lambdasistemi.github.io/cardano-rdf/fixtures/tx#` —
  that is the namespace `cq-rdf` body and blueprint passes bind
  `:` to inside each emitted transaction block.
