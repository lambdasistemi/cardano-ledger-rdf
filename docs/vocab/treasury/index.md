# `treasury:` namespace

This page is the dereference target of the `treasury:` namespace IRI:

```text
https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/treasury#
```

The namespace ends in `#`; stripping the fragment lands you here. The
ontology is published as a Turtle document at

- [`overlay.ttl`](overlay.ttl)

which declares every class and predicate in the `treasury:` namespace.
The TTL source of truth lives in the repository at
[`vocab/treasury/overlay.ttl`](https://github.com/lambdasistemi/cardano-ledger-rdf/blob/main/vocab/treasury/overlay.ttl).

`treasury:` carries the **treasury-overlay** vocabulary: off-chain
entity declarations, attestations, vendor accountability. It exists so
the ledger-level [`cardano:`](../cardano/index.md) namespace is not
polluted by application terms. Case-study `overlay.yaml` files opt in
to this vocabulary via an explicit `imports: [treasury]` block;
predicates from non-imported ontologies fail the parser with a clear
error.

The emitted overlay Turtle declares
`owl:imports <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/treasury/overlay>`
so downstream consumers (SPARQL engines, SHACL, LLMs) can resolve
predicate provenance.

For ownership and the standard SPARQL `PREFIX` line, see the
[Vocabulary index](../../vocab.md).
