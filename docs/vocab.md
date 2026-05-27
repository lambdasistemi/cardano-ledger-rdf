# Vocabulary

The `cardano:` predicates emitted by [`tx-graph`](tx-graph.md) and referenced
from every query in the case studies are defined by an ontology owned by this
repository.

## IRI

```text
https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#
```

The IRI is hosted by the GitHub Pages site of
[`lambdasistemi/cardano-ledger-rdf`][repo]. The TTL source lives at
[`vocab/cardano/transactions.ttl`][ttl] and is published verbatim under
[`/vocab/cardano/transactions.ttl`][deployed] of the deployed docs site, so
the IRI dereferences.

[repo]: https://github.com/lambdasistemi/cardano-ledger-rdf
[ttl]: https://github.com/lambdasistemi/cardano-ledger-rdf/blob/main/vocab/cardano/transactions.ttl
[deployed]: vocab/cardano/transactions.ttl

## Ownership

`lambdasistemi/cardano-ledger-rdf` is the source of truth for the
`cardano:` namespace. Changes go through PRs on this repo; downstream
consumers (the case studies here, `cardano-tx-tools`, the
`cardano-knowledge-maps` graph browser) pin against tagged releases.

The vocabulary was migrated from `cardano-knowledge-maps` in
[#19](https://github.com/lambdasistemi/cardano-ledger-rdf/issues/19) so
the ontology now travels with the code that emits its predicates.

## Standard prefix in SPARQL

```sparql
PREFIX cardano: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#>
```

Every query under [Case studies](case-studies/index.md) opens with this
PREFIX line.

## Validation

A local validation gate (TTL well-formedness + OWL 2 RL inference smokes)
is being ported from `cardano-knowledge-maps`; see
[#40](https://github.com/lambdasistemi/cardano-ledger-rdf/issues/40).
