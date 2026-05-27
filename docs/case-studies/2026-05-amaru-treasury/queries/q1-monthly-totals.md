# Q1 — Monthly totals

```sparql
PREFIX cardano: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#>
SELECT (COUNT(?tx) AS ?seedTxCount)
       (SUM(?fee) AS ?totalFeeLovelace)
       (MIN(?fee) AS ?minFee)
       (MAX(?fee) AS ?maxFee)
WHERE { ?tx cardano:hasLatticeRole "seed" ; cardano:hasFee ?fee . }
```

| seed tx count | total fee  | min fee     | max fee     |
|---------------|-----------:|------------:|------------:|
| 30            | 19.93 ADA  | 0.244 ADA   | 1.572 ADA   |

The contingency disburse is the most expensive single tx (4-of-4
multisig + 4 reference inputs + 1 withdrawal); the cheapest are the
single-author swap-order opens.

---


Return to the [presentation](../case.md).
