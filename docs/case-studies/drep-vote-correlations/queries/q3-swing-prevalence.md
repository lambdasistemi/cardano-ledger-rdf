# Q3 - Swing-voter prevalence

Among DReps with at least 5 unambiguous selected-action observations,
**229 of 313** changed verdict at least once. The mono-verdict population is
**84 DReps**: **82 Yes-only** and **2 No-only**.

```sparql
PREFIX cardano: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#>

SELECT
  (COUNT(?voterId) AS ?totalDReps)
  (SUM(IF(?nVerdicts = 1, 1, 0)) AS ?monoVerdictDReps)
  (SUM(IF(?nVerdicts > 1, 1, 0)) AS ?swingDReps)
WHERE {
  {
    SELECT ?voterId (COUNT(DISTINCT ?verdict) AS ?nVerdicts)
    WHERE {
      {
        SELECT ?actionKey ?voterId (SAMPLE(?rawVerdict) AS ?verdict)
        WHERE {
          VALUES (?selectedTx ?selectedIndex) {
            ("8f54d021c6e6fcdd5a4908f10a7b092fa31cd94db2e809f2e06d7ffa4d78773d" 0)
            ("47a0e7a4f9383b1afc2192b23b41824d65ac978d7741aca61fc1fa16833d1111" 0)
            ("73e171a4c0730b4b59ecae271ab89f12a9d56360b02920e1f95107dbdc1d6762" 0)
            ("73e171a4c0730b4b59ecae271ab89f12a9d56360b02920e1f95107dbdc1d6762" 1)
            ("73e171a4c0730b4b59ecae271ab89f12a9d56360b02920e1f95107dbdc1d6762" 2)
            ("73e171a4c0730b4b59ecae271ab89f12a9d56360b02920e1f95107dbdc1d6762" 3)
            ("73e171a4c0730b4b59ecae271ab89f12a9d56360b02920e1f95107dbdc1d6762" 4)
            ("73e171a4c0730b4b59ecae271ab89f12a9d56360b02920e1f95107dbdc1d6762" 5)
            ("73e171a4c0730b4b59ecae271ab89f12a9d56360b02920e1f95107dbdc1d6762" 6)
            ("73e171a4c0730b4b59ecae271ab89f12a9d56360b02920e1f95107dbdc1d6762" 8)
            ("90cf51975f9c19c291bac3e57364a89507e64daa0a2d35e356f87e6684821556" 0)
            ("8ad3d454f3496a35cb0d07b0fd32f687f66338b7d60e787fc0a22939e5d8833e" 19)
            ("d16dffbae9d86a73cb343506e6712d79c278096dc25e8ba6900eb24522726bba" 0)
            ("e5643c33f608642e329228a968770e5b19ef5f48ff1f698712e2ce864a49e3f0" 0)
            ("207b226e110e13bb18b119fcd313520e0fcd060b2bc9fb9a5e5bc6e94ab10f3b" 0)
            ("8ad3d454f3496a35cb0d07b0fd32f687f66338b7d60e787fc0a22939e5d8833e" 30)
            ("8ad3d454f3496a35cb0d07b0fd32f687f66338b7d60e787fc0a22939e5d8833e" 29)
            ("c21b00f90f18fce4003edf42b0b0d455126e01c946e80cc5341a9f9750caf795" 0)
            ("8845bfc37bb2f69e8f200fe28148b3dea3c4399b0c49ee0ed2bb4e349cab9eb7" 0)
            ("f8393f1ff814d3d52336a97712361fed933d9ef9e8d0909e1d31536a549fd22f" 0)
          }
          ?vote a cardano:Vote ;
                cardano:hasVotingAction ?action ;
                cardano:hasVoter ?voter ;
                cardano:hasVerdict ?rawVerdict .
          ?action cardano:hasTxId/cardano:bytesHex ?selectedTx ;
                  cardano:hasIndex ?selectedIndex .
          ?voter a cardano:VoterDRep ; cardano:hasIdentifier ?voterId .
          BIND(CONCAT(?selectedTx, "#", STR(?selectedIndex)) AS ?actionKey)
        }
        GROUP BY ?actionKey ?voterId
        HAVING (COUNT(?vote) = 1)
      }
    }
    GROUP BY ?voterId
    HAVING (COUNT(?actionKey) >= 5)
  }
}
```

Observed result:

```text
totalDReps = 313
monoVerdictDReps = 84
swingDReps = 229
```

Mono-verdict detail:

Observed detail: **82 Yes-only** and **2 No-only**.

Epoch-local swing rates, using selected actions submitted in the same
proposal epoch and requiring at least two observations in that epoch:

| Proposal epoch | Eligible DReps | Swing DReps | Swing rate |
| ---: | ---: | ---: | ---: |
| 576 | 213 | 90 | 42.3% |
| 603 | 212 | 10 | 4.7% |
| 612 | 196 | 12 | 6.1% |
| 632 | 261 | 126 | 48.3% |

Return to the [presentation](../case.md).
