# Q6 - Arrival-time dynamics

The current tx-graph lattice cannot answer early-vs-late voter dynamics by
itself. Vote CBOR carries the voting procedure, voter, action id, verdict,
and optional anchor, but the transaction block time used for arrival order
comes from the chain indexer. `tx-graph` does not emit that
indexer-side field.

The SPARQL boundary check is:

```sparql
PREFIX cardano: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#>
SELECT ?action ?verdict ?hasAnchor (COUNT(?vote) AS ?votes)
WHERE {
  ?vote a cardano:Vote ;
        cardano:hasVotingAction ?action ;
        cardano:hasVoter ?voter ;
        cardano:hasVerdict ?verdict .
  OPTIONAL { ?vote cardano:hasAnchor ?anchor . }
  BIND(BOUND(?anchor) AS ?hasAnchor)
}
GROUP BY ?action ?verdict ?hasAnchor
ORDER BY ?action ?verdict ?hasAnchor
LIMIT 20
```

Observed result: vote rows expose the fields above, but no
`cardano:blockTime`, `cardano:blockHeight`, or equivalent transaction-time
predicate is present in the lattice. The arrival-time question therefore
needs either a follow-up tx-graph provenance field or an explicit Koios
sidecar joined outside RDF.

The Koios sidecar used for dataset selection can compute the exploratory
number: across the selected actions, first-quartile DRep votes aligned with
the eventual DRep majority **943 of 1,270** times (**74.3%**), while
last-quartile votes aligned **1,026 of 1,270** times (**80.8%**). This is
documented here as sidecar evidence, not as a SPARQL-native case-study
claim.

Return to the [presentation](../case.md).
