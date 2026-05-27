# Q5 - Vote tallies per proposal

The lattice contains **2,374 IO vote rows** across **9 action indexes**.
The join goes through typed `cardano:GovActionId`: SPARQL follows
`?vote cardano:hasVotingAction ?action`, then reads the action's
`cardano:hasTxId` and `cardano:hasIndex`.

The IO-action filter is important:
`?actionTxid cardano:bytesHex "73e171a4..."` scopes the query to this
submission transaction. Without it, the same vote transactions also expose
unrelated governance actions co-bundled with IO votes.

Grouping by `cardano:hasIndex` is also required. All 9 IO proposals share
the same submission transaction id, so the index is the discriminator.

| Action index | Proposal | Abstain | No | Yes | Total |
| ---: | --- | ---: | ---: | ---: | ---: |
| 0 | Developer Experience | **27** | **60** | **201** | **288** |
| 1 | Cardano Upgrades | **12** | **25** | **232** | **269** |
| 2 | Consensus | **11** | **18** | **239** | **268** |
| 3 | Cardano Maintenance | **24** | **39** | **206** | **269** |
| 4 | L2 Scalability | **38** | **65** | **161** | **264** |
| 5 | Cardano High Assurance | **22** | **31** | **210** | **263** |
| 6 | Plutus | **29** | **36** | **196** | **261** |
| 7 | Blockfrost | **44** | **89** | **109** | **242** |
| 8 | Pogun | **35** | **82** | **133** | **250** |

```sparql
PREFIX cardano: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#>
SELECT ?actionTxid ?actionIndex ?verdict (COUNT(*) AS ?n)
WHERE {
  ?vote a cardano:Vote ;
        cardano:hasVotingAction ?action ;
        cardano:hasVerdict ?verdict .
  ?action cardano:hasTxId ?actionTxid ;
          cardano:hasIndex ?actionIndex .
  ?actionTxid cardano:bytesHex "73e171a4c0730b4b59ecae271ab89f12a9d56360b02920e1f95107dbdc1d6762" .
}
GROUP BY ?actionTxid ?actionIndex ?verdict
ORDER BY ?actionIndex ?verdict
```

Observed result: **27 action/verdict rows**, **2,374 votes**, and per-action
totals of `288, 269, 268, 269, 264, 263, 261, 242, 250`.

Return to the [presentation](../case.md).
