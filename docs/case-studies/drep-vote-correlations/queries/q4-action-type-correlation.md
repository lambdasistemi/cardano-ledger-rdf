# Q4 - Action-type correlation

The selected action types have different same-verdict concentration. The
rate below is computed within each action first as same-verdict DRep pairs
divided by all DRep pairs, then summed by action type.

| Action type | Actions | Same-verdict pairs | All pairs | Same-verdict rate |
| --- | ---: | ---: | ---: | ---: |
| ParameterChange | 1 | 24,547 | 26,335 | 93.2% |
| UpdateCommittee | 1 | 31,929 | 35,511 | 89.9% |
| InfoAction | 5 | 108,532 | 136,311 | 79.6% |
| TreasuryWithdrawals | 12 | 179,631 | 296,648 | 60.6% |
| NewConstitution | 1 | 13,904 | 26,796 | 51.9% |

```sparql
PREFIX cardano: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>

SELECT ?actionType
       (COUNT(?actionKey) AS ?actions)
       (SUM(?samePairsForAction) AS ?sameVerdictPairs)
       (SUM(?allPairsForAction) AS ?allPairs)
       (xsd:decimal(SUM(?samePairsForAction)) / xsd:decimal(SUM(?allPairsForAction)) AS ?sameVerdictRate)
WHERE {
  {
    SELECT ?actionType ?actionKey
           (SUM(?samePairsForVerdict) AS ?samePairsForAction)
           (SAMPLE(?allPairsForVerdict) AS ?allPairsForAction)
    WHERE {
      {
        SELECT ?actionType ?actionKey ?verdict
               ((COUNT(?voterId) * (COUNT(?voterId) - 1)) / 2 AS ?samePairsForVerdict)
               (SAMPLE(?allPairs) AS ?allPairsForVerdict)
        WHERE {
      {
        SELECT ?actionType ?actionKey ?voterId (SAMPLE(?rawVerdict) AS ?verdict)
        WHERE {
          {
            SELECT DISTINCT ?selectedTx (COALESCE(?typedName, ?datumType) AS ?actionType)
            WHERE {
              VALUES ?selectedTx {
                "8f54d021c6e6fcdd5a4908f10a7b092fa31cd94db2e809f2e06d7ffa4d78773d"
                "47a0e7a4f9383b1afc2192b23b41824d65ac978d7741aca61fc1fa16833d1111"
                "73e171a4c0730b4b59ecae271ab89f12a9d56360b02920e1f95107dbdc1d6762"
                "90cf51975f9c19c291bac3e57364a89507e64daa0a2d35e356f87e6684821556"
                "8ad3d454f3496a35cb0d07b0fd32f687f66338b7d60e787fc0a22939e5d8833e"
                "d16dffbae9d86a73cb343506e6712d79c278096dc25e8ba6900eb24522726bba"
                "e5643c33f608642e329228a968770e5b19ef5f48ff1f698712e2ce864a49e3f0"
                "207b226e110e13bb18b119fcd313520e0fcd060b2bc9fb9a5e5bc6e94ab10f3b"
                "c21b00f90f18fce4003edf42b0b0d455126e01c946e80cc5341a9f9750caf795"
                "8845bfc37bb2f69e8f200fe28148b3dea3c4399b0c49ee0ed2bb4e349cab9eb7"
                "f8393f1ff814d3d52336a97712361fed933d9ef9e8d0909e1d31536a549fd22f"
              }
              ?tx a cardano:Transaction ;
                  cardano:hasTxId/cardano:bytesHex ?selectedTx ;
                  cardano:hasProposal ?proposal .
              OPTIONAL {
                ?proposal cardano:hasGovAction ?govAction .
                VALUES ?typedClass {
                  cardano:TreasuryWithdrawals
                  cardano:ParameterChange
                  cardano:UpdateCommittee
                  cardano:NewConstitution
                  cardano:HardForkInitiation
                }
                ?govAction a ?typedClass .
                BIND(STRAFTER(STR(?typedClass), "#") AS ?typedName)
              }
              OPTIONAL { ?proposal cardano:hasDatum/cardano:decodedAs ?datumType . }
            }
          }
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
        GROUP BY ?actionType ?actionKey ?voterId
        HAVING (COUNT(?vote) = 1)
      }
      {
        SELECT ?actionKey (((COUNT(?voterId) * (COUNT(?voterId) - 1)) / 2) AS ?allPairs)
        WHERE {
          {
            SELECT ?actionKey ?voterId
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
                    cardano:hasVoter ?voter .
              ?action cardano:hasTxId/cardano:bytesHex ?selectedTx ;
                      cardano:hasIndex ?selectedIndex .
              ?voter a cardano:VoterDRep ; cardano:hasIdentifier ?voterId .
              BIND(CONCAT(?selectedTx, "#", STR(?selectedIndex)) AS ?actionKey)
            }
            GROUP BY ?actionKey ?voterId
            HAVING (COUNT(?vote) = 1)
          }
        }
        GROUP BY ?actionKey
      }
    }
    GROUP BY ?actionType ?actionKey ?verdict
  }
}
GROUP BY ?actionType ?actionKey
  }
}
GROUP BY ?actionType
ORDER BY DESC(?sameVerdictRate)
```

Observed result: `ParameterChange = 93.2%`, `UpdateCommittee = 89.9%`,
`InfoAction = 79.6%`, `TreasuryWithdrawals = 60.6%`, and
`NewConstitution = 51.9%`. The query now reads emitted typed governance
action classes for `ParameterChange`, `UpdateCommittee`,
`NewConstitution`, and `TreasuryWithdrawals`; `InfoAction` still comes from
the proposal datum fallback because it is not emitted as a typed action
class in this lattice.

Return to the [presentation](../case.md).
