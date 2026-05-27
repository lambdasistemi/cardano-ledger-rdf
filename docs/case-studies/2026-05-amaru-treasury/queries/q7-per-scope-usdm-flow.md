# Q7 — Per-scope USDM flow

```sparql
# Same closure JOIN as Q3 but counts USDM instead of lovelace.
# Full query at queries/07-usdm-scope-flow.rq.
SELECT ?scope (SUM(?qIn) AS ?usdm_in) (SUM(?qOut) AS ?usdm_out)
       ((SUM(?qIn) - SUM(?qOut)) AS ?net)
WHERE { /* IN: seed outputs at ?bech with USDM   */
        /* OUT: closure-resolved seed input UTxOs at ?bech with USDM */
        /* BIND ?bech → ?scope (entity slug or "other") */
}
GROUP BY ?scope
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
