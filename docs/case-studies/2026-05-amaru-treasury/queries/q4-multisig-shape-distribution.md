# Q4 — Multisig shape distribution

```sparql
PREFIX cardano: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#>
SELECT ?requiredSigners (COUNT(?seed) AS ?txCount)
WHERE {
  { SELECT ?seed (COUNT(DISTINCT ?sig) AS ?requiredSigners) WHERE {
      ?seed cardano:hasLatticeRole "seed" ; cardano:hasRequiredSigner ?sig .
  } GROUP BY ?seed }
  UNION
  { ?seed cardano:hasLatticeRole "seed" .
    FILTER NOT EXISTS { ?seed cardano:hasRequiredSigner ?_ }
    BIND (0 AS ?requiredSigners) }
}
GROUP BY ?requiredSigners
ORDER BY DESC(?requiredSigners)
```

| required signers | tx count |
|-----------------:|---------:|
| 4                | 1        |
| 2                | 23       |
| 1                | 6        |

The single 4-of-4 tx is the contingency disburse (highest authority).
The 2-of-N shape covers vendor-payment + reorganize. The 1-signer
shape covers swap-order opens, swap-cancel, and scoop participation.

---


Return to the [presentation](../case.md).
