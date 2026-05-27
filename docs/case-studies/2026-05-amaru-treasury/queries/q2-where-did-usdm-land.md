# Q2 — Where did USDM land?

```sparql
PREFIX cardano: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
SELECT ?destBech32 (SUM(?qty) AS ?usdmReceived)
WHERE {
  ?seed cardano:hasLatticeRole "seed" ; cardano:hasOutput ?out .
  ?out cardano:atAddress/cardano:bech32 ?destBech32 ;
       cardano:hasAssetValue/rdf:rest*/rdf:first ?asset .
  ?asset cardano:hasIdentifier ?id ; cardano:quantity ?qty .
  ?id cardano:bytesHex
        "c48cbb3d5e57ed56e276bc45f99ab39abe94e6cd7ac39fb402da47ad0014df105553444d" .
}
GROUP BY ?destBech32
ORDER BY DESC(?usdmReceived)
```

| destination (truncated)        | USDM         |
|--------------------------------|-------------:|
| `addr1xyezq8w...` (network_compliance) | 1,146,156.66 |
| `addr1z8srqftq...` (SundaeSwap pool)   |   490,819.15 |
| `addr1q8qrds2n...` (cag-payee)         |   418,750.00 |

The biggest USDM bucket lands back on network_compliance — those
are change outputs from swap orders that completed. The
418,750 USDM at cag-payee is the bridge-out for May's vendor
invoices.

---


Return to the [presentation](../case.md).
