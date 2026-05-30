# `cardano:` namespace

This page is the dereference target of the `cardano:` namespace IRI:

```text
https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#
```

The namespace ends in `#`; stripping the fragment lands you here. The
ontology is published as a Turtle document at

- [`transactions.ttl`](transactions.ttl)

which declares every class and predicate in the `cardano:` namespace. The
TTL source of truth lives in the repository at
[`vocab/cardano/transactions.ttl`](https://github.com/lambdasistemi/cardano-ledger-rdf/blob/main/vocab/cardano/transactions.ttl).

`cardano:` is intentionally scoped to **ledger primitives**: classes such
as `cardano:Transaction`, `cardano:Output`, `cardano:Input`,
`cardano:Datum`, `cardano:Redeemer`, `cardano:ScriptHash`, and the
predicates relating them. Application-layer concepts such as
off-chain accountability, treasury vendors, or attestations live in
their own namespaces (for example [`treasury:`](../treasury/index.md))
and are imported explicitly by operator overlays.

For ownership and the standard SPARQL `PREFIX` line, see the
[Vocabulary index](../../vocab.md).
