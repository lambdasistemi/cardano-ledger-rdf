# Q8 — Scoop detection

```sparql
PREFIX cardano: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#>

SELECT ?seedTxId (COUNT(DISTINCT ?parentOut) AS ?swapOrdersConsumed)
WHERE {
  ?seed cardano:hasLatticeRole "seed" ;
        cardano:hasTxId/cardano:bytesHex ?seedTxId ;
        cardano:hasInput ?in .
  ?in cardano:fromTxOutRef ?ref .
  ?ref cardano:hasTxId ?h ; cardano:hasIndex ?ix .
  ?h cardano:bytesHex ?parentHex .
  ?parent cardano:hasTxId/cardano:bytesHex ?parentHex ; cardano:hasOutput ?parentOut .
  ?parentOut cardano:hasIndex ?ix ;
             cardano:atAddress/cardano:hasPaymentCredential/cardano:hasIdentifier ?id .
  ?id cardano:bytesHex
        "fa6a58bbe2d0ff05534431c8e2f0ef2cbdc1602a8456e4b13c8f3077" .
}
GROUP BY ?seedTxId
ORDER BY DESC(?swapOrdersConsumed)
```

| tx hash                                                              | swap orders consumed |
|----------------------------------------------------------------------|----:|
| `4e2642080c8d171aad05baed11b076de498b76acecc1c2412660048fae8aefa3`   | 9   |
| `a8bab7bfe1e2ed9d3a5b40189c8de51c5974a6e05c71fc1000a6abd57500b365`   | 1   |

Two scoops in May. The **9-order scoop dive** is the one the
operator asked to demo — `4e2642...`. The 1-order tx is a single
swap-cancel that pulls one order back out of the pool. The query
doesn't pattern-match on tx shape — it pattern-matches on
*consumption of a swap.v2 UTxO* via the closure JOIN.

---


Return to the [presentation](../case.md).
