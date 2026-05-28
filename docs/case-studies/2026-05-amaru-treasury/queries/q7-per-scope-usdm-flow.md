# Q7 — Per-scope USDM flow

```sparql
PREFIX cardano: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>

SELECT ?scope (SUM(?qIn) AS ?usdm_in) (SUM(?qOut) AS ?usdm_out)
       ((SUM(?qIn) - SUM(?qOut)) AS ?net)
WHERE {
  {
    ?seed cardano:hasLatticeRole "seed" ; cardano:hasOutput ?out .
    ?out cardano:atAddress/cardano:bech32 ?bech ;
         cardano:hasAssetValue/rdf:rest*/rdf:first ?asset .
    ?asset cardano:hasIdentifier ?id ; cardano:quantity ?rawIn .
    ?id cardano:bytesHex
          "c48cbb3d5e57ed56e276bc45f99ab39abe94e6cd7ac39fb402da47ad0014df105553444d" .
    BIND (?rawIn / 1000000 AS ?qIn)
    BIND (0 AS ?qOut)
  }
  UNION
  {
    ?seed cardano:hasLatticeRole "seed" ; cardano:hasInput ?in .
    ?in cardano:fromTxOutRef ?ref .
    ?ref cardano:hasTxId ?h ; cardano:hasIndex ?ix .
    ?h cardano:bytesHex ?parentHex .
    ?parent cardano:hasTxId/cardano:bytesHex ?parentHex ; cardano:hasOutput ?parentOut .
    ?parentOut cardano:hasIndex ?ix ;
               cardano:atAddress/cardano:bech32 ?bech ;
               cardano:hasAssetValue/rdf:rest*/rdf:first ?asset .
    ?asset cardano:hasIdentifier ?id ; cardano:quantity ?rawOut .
    ?id cardano:bytesHex
          "c48cbb3d5e57ed56e276bc45f99ab39abe94e6cd7ac39fb402da47ad0014df105553444d" .
    BIND (0 AS ?qIn)
    BIND (?rawOut / 1000000 AS ?qOut)
  }
  BIND (
    IF(?bech = "addr1x8ndhlcfy30t38z0tql64fpg8ply93r37xrgvdagfpsz5nhxm0lsjfz7hzwy7kpl42jzswr7gtz8ruvxscm6sjrq9f8qruq0ae",
       "amaru-treasury.contingency",
    IF(?bech = "addr1xyezq8wpaqnssdjvd3p220uf7e6nzjae44w6yu625y965rfjyqwur6p8pqmycmzz55lcnan4x99mnt2a5fe54ggt4gxs8thzgk",
       "amaru-treasury.network_compliance",
    IF(?bech = "addr1q8qrds2nnx7clx3kcpp2l0eu45twmdcahsfu9m0xcwy59j6xz3vs0hnfaz9nhje8z34kfnds4jyk7hs6dnrag6e2lfgqtyf4rl",
       "amaru.cag-payee",
       "other"))) AS ?scope
  )
}
GROUP BY ?scope
ORDER BY ?scope
```

| scope                                     | USDM in     | USDM out    | net          |
|-------------------------------------------|------------:|------------:|-------------:|
| amaru-treasury.network_compliance         | 1,146,156.66 | 1,554,849.98 | **−408,693.32** |
| other (SundaeSwap pool, batchers)         |   490,819.15 |   500,875.83 |     **−10,056.68** |
| amaru.cag-payee                           |   418,750.00 |         0.00 |    **+418,750.00** |

**TOTAL: 2,055,725.81 in = 2,055,725.81 out, conservation exact.**

network_compliance lost 408,693 USDM net over the month — 418,750
of that went to cag-payee (vendor bridge); the 10,057 USDM
"shortfall" was absorbed by SundaeSwap batcher fees / slippage
(visible directly in the `other` row).

---


Return to the [presentation](../case.md).
