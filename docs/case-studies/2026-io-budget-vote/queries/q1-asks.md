# Q1 - Asks per proposal

The 9 proposals ask for **162,145,961 ada** in total. Every row routes to
the same recipient credential; the table is ordered by the on-chain
withdrawal amount.

| Proposal | ADA ask | Recipient credential |
| --- | ---: | --- |
| Cardano Maintenance | **62,134,630** | `8583857e4a12ffe1e6f641a1785a0f2f036c565cfbe6ff9db8e5a469` |
| Consensus | **27,714,342** | `8583857e4a12ffe1e6f641a1785a0f2f036c565cfbe6ff9db8e5a469` |
| Cardano Upgrades | **13,103,039** | `8583857e4a12ffe1e6f641a1785a0f2f036c565cfbe6ff9db8e5a469` |
| Cardano High Assurance | **13,078,578** | `8583857e4a12ffe1e6f641a1785a0f2f036c565cfbe6ff9db8e5a469` |
| Pogun | **12,290,000** | `8583857e4a12ffe1e6f641a1785a0f2f036c565cfbe6ff9db8e5a469` |
| Plutus | **11,877,575** | `8583857e4a12ffe1e6f641a1785a0f2f036c565cfbe6ff9db8e5a469` |
| L2 Scalability | **10,425,871** | `8583857e4a12ffe1e6f641a1785a0f2f036c565cfbe6ff9db8e5a469` |
| Blockfrost | **7,920,000** | `8583857e4a12ffe1e6f641a1785a0f2f036c565cfbe6ff9db8e5a469` |
| Developer Experience | **3,601,926** | `8583857e4a12ffe1e6f641a1785a0f2f036c565cfbe6ff9db8e5a469` |

```sparql
PREFIX cardano: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#>
SELECT ?proposal ?recipient ?ada
WHERE {
  ?proposal a cardano:Proposal ;
            cardano:hasGovAction ?act .
  ?act cardano:hasWithdrawal ?w .
  ?w cardano:toRewardAccount/cardano:bytesHex ?recipient ;
     cardano:hasLovelace ?lov .
  BIND(?lov / 1000000 AS ?ada)
}
ORDER BY DESC(?ada)
```

The sum was checked with the same graph path:

```sparql
PREFIX cardano: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#>
SELECT (SUM(?ada) AS ?totalAda) (COUNT(?proposal) AS ?rows)
WHERE {
  ?proposal a cardano:Proposal ;
            cardano:hasGovAction ?act .
  ?act cardano:hasWithdrawal ?w .
  ?w cardano:hasLovelace ?lov .
  BIND(?lov / 1000000 AS ?ada)
}
```

Observed result: **9 rows** and `totalAda = 162145961.0`.

Return to the [presentation](../case.md).
