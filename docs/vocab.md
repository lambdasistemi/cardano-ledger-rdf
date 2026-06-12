# Vocabulary

The `cardano:` predicates emitted by [`cq-rdf body`](cq-rdf.md) are defined
by an ontology owned by this repository. Treasury-accountability overlays
use the separate `treasury:` namespace so application terms do not pollute
the ledger-level Cardano vocabulary; treasury predicates are emitted by
[`cq-rdf overlay`](cq-rdf.md) when an operator `overlay.yaml` imports them.

## Namespaces and dereference URLs

| Prefix | Namespace IRI | Ontology file |
|---|---|---|
| `cardano:` | `https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#` | [`vocab/cardano/transactions.ttl`][cardano-deployed] |
| `treasury:` | `https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/treasury#` | [`vocab/treasury/overlay.ttl`][treasury-deployed] |

The namespace IRI ends in `#`; stripping the fragment yields the *base*
URL of the namespace. Each base URL serves a small landing page that
links to the canonical Turtle document, so an LLM, an RDF tool, or a
human pasting the IRI into a browser always lands on something useful:

- [`/vocab/cardano/`](vocab/cardano/index.md) — `cardano:` landing page,
  links to [`transactions.ttl`][cardano-deployed].
- [`/vocab/treasury/`](vocab/treasury/index.md) — `treasury:` landing
  page, links to [`overlay.ttl`][treasury-deployed].

The TTL sources are mirrored from the repository root verbatim:

- `vocab/cardano/transactions.ttl` (source) → [`/vocab/cardano/transactions.ttl`][cardano-deployed]
- `vocab/treasury/overlay.ttl` (source) → [`/vocab/treasury/overlay.ttl`][treasury-deployed]

[repo]: https://github.com/lambdasistemi/cardano-ledger-rdf
[cardano-ttl]: https://github.com/lambdasistemi/cardano-ledger-rdf/blob/main/vocab/cardano/transactions.ttl
[cardano-deployed]: vocab/cardano/transactions.ttl
[treasury-ttl]: https://github.com/lambdasistemi/cardano-ledger-rdf/blob/main/vocab/treasury/overlay.ttl
[treasury-deployed]: vocab/treasury/overlay.ttl

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
PREFIX cardano:  <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#>
PREFIX treasury: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/treasury#>
```

Every query under [Case studies](case-studies/index.md) opens with this
PREFIX line. Case-study `overlay.yaml` files opt in to the treasury
namespace via an `imports: [treasury]` block; predicates from
non-imported ontologies fail the YAML parser with a clear error.

## Validation

A local validation gate ([#40](https://github.com/lambdasistemi/cardano-ledger-rdf/issues/40),
ported from `cardano-knowledge-maps`) runs in CI and `nix flake check`,
and locally via `just`:

| Gate | Recipe | Script | Checks |
|---|---|---|---|
| `vocab-validate` | `just vocab-validate` | `scripts/validate-ttl.py` | TTL well-formedness of every `vocab/**/*.ttl` |
| `vocab-owl-smoke` | `just vocab-owl-smoke` | `scripts/owl-smoke.py` | OWL 2 RL inference smokes over the EYE closure |
| `vocab-accessibility` | `just vocab-accessibility` | `scripts/vocab-accessibility.py` | every term carries a label/comment for dereference |

All three are also `nix flake check` derivations (`vocab-validate`,
`vocab-owl-smoke`, `vocab-accessibility` in `nix/checks.nix`) and run on
every push.
