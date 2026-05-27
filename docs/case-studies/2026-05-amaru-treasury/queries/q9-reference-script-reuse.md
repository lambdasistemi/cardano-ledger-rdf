# Q9 — Reference-script reuse

```sparql
PREFIX cardano: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#>

SELECT ?parentTxId ?ix (COUNT(DISTINCT ?seed) AS ?usingSeedTxs)
WHERE {
  ?seed cardano:hasLatticeRole "seed" ;
        cardano:hasReferenceInput ?ref .
  ?ref cardano:fromTxOutRef ?refTxOutRef .
  ?refTxOutRef cardano:hasTxId ?h ; cardano:hasIndex ?ix .
  ?h cardano:bytesHex ?parentTxId .
}
GROUP BY ?parentTxId ?ix
ORDER BY DESC(?usingSeedTxs) ?parentTxId
LIMIT 5
```

| parent tx hash (truncated)         | output ix | seed txs reusing it |
|------------------------------------|----------:|--------------------:|
| `11ace24a7b0caad4...`              | 0         | 28                  |
| `25ba96f5deb14bb5...`              | 2         | 27                  |
| `810bfcbde85ae72f...`              | 0         | 27                  |
| `e7b395a93d49a179...`              | 2         | 27                  |

Four hot reference UTxOs carry 95%+ of the month's reference-script
usage — the canonical published treasury, swap.v2, and SundaeSwap
batcher scripts. Cardano CIP-31 reference inputs are working as
intended.

---


Return to the [presentation](../case.md).
