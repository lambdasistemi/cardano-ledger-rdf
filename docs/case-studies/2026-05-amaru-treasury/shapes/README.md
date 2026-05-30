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

These shapes run as the last stage of the case study's reproduce
pipe documented in [`../README.md`](../README.md):

```bash
cq-rdf overlay --in overlay.yaml > overlay.ttl
xargs -P8 -n1 cq-rdf body --provider blockfrost < selections.txt > bodies.ttl
cat overlay.ttl bodies.ttl \
  | cq-rdf blueprint --blueprints blueprints/ \
  > package.ttl
cq-rdf shacl --shapes shapes/ < package.ttl
```

On the real May 2026 lattice `cq-rdf shacl` exits 0 on the
resulting `package.ttl`: every operator-issued Sundae order routes
back to `network_compliance`, and every declared off-chain vendor
is attested.

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
