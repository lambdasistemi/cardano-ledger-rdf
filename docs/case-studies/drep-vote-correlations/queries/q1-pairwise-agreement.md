# Q1 - Pairwise DRep agreement

Among DRep pairs with at least 10 common selected actions, the lattice
contains **19,440** comparable pairs. The strongest pairs agree on every
common action; the weakest agree on none.

The query below first scopes votes to the 20 selected governance actions.
It then keeps only DRep/action observations with exactly one vote row, so
the correlation is not forced to choose a latest vote without block-time
data.

```sparql
PREFIX cardano: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>

SELECT ?agreementRate ?agree ?common ?voter1 ?voter2
WHERE {
  {
    SELECT ?voter1 ?voter2
           (COUNT(?actionKey) AS ?common)
           (SUM(IF(?verdict1 = ?verdict2, 1, 0)) AS ?agree)
    WHERE {
      {
        SELECT ?actionKey ?voter1 (SAMPLE(?verdict) AS ?verdict1)
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
                cardano:hasVerdict ?verdict .
          ?action cardano:hasTxId/cardano:bytesHex ?selectedTx ;
                  cardano:hasIndex ?selectedIndex .
          ?voter a cardano:VoterDRep ; cardano:hasIdentifier ?voter1 .
          BIND(CONCAT(?selectedTx, "#", STR(?selectedIndex)) AS ?actionKey)
        }
        GROUP BY ?actionKey ?voter1
        HAVING (COUNT(?vote) = 1)
      }
      {
        SELECT ?actionKey ?voter2 (SAMPLE(?verdict) AS ?verdict2)
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
                cardano:hasVerdict ?verdict .
          ?action cardano:hasTxId/cardano:bytesHex ?selectedTx ;
                  cardano:hasIndex ?selectedIndex .
          ?voter a cardano:VoterDRep ; cardano:hasIdentifier ?voter2 .
          BIND(CONCAT(?selectedTx, "#", STR(?selectedIndex)) AS ?actionKey)
        }
        GROUP BY ?actionKey ?voter2
        HAVING (COUNT(?vote) = 1)
      }
      FILTER(STR(?voter1) < STR(?voter2))
    }
    GROUP BY ?voter1 ?voter2
    HAVING (COUNT(?actionKey) >= 10)
  }
  BIND(xsd:decimal(?agree) / xsd:decimal(?common) AS ?agreementRate)
}
ORDER BY DESC(?agreementRate) DESC(?common)
LIMIT 10
```

Observed top aligned pairs:

| Agreement | Same/common | DRep 1 | DRep 2 |
| ---: | ---: | --- | --- |
| 100.0% | 20/20 | `43506c27a95547c19fc9d0e56e927487d3eb3ed00ec117ce094a74e5` | `bc094a622f7c0d0b6c0f64200404fceddd7c3666365822436df205bc` |
| 100.0% | 20/20 | `874b39ca44ab2d7d57f3f544da925a6e233931f0c84459a6a82fb0b0` | `b6f4547ad049d7443ee5695761e1aa5e446cfccf72c7ed0d8ad8edfa` |
| 100.0% | 19/19 | `43506c27a95547c19fc9d0e56e927487d3eb3ed00ec117ce094a74e5` | `98a9e2ebf6ba1eaff3321623dce2216b1eb13e0f5a0b5984c6c5bc07` |
| 100.0% | 19/19 | `43506c27a95547c19fc9d0e56e927487d3eb3ed00ec117ce094a74e5` | `fd74b7ff13ffe7fb93b5ca852605cc68dfe9a5aad9224e77aae88769` |
| 100.0% | 19/19 | `486aac40d5d3ca394f9d54323f983ae16ee674f655922c4eb889e659` | `aa61eb75dd91ff67c73ea168bb39f5fd1de0792408cb8dc2b4094ec8` |

For the divergent side, use the same query with
`ORDER BY ?agreementRate DESC(?common)`:

| Agreement | Same/common | DRep 1 | DRep 2 |
| ---: | ---: | --- | --- |
| 0.0% | 0/14 | `1189ae5e6370afc64fa39f909ebd21c1213d331c33a1fce8c61a54c0` | `7d691a83f938411ac3ab444c61a981d7985d45eec6bc0481ff23d84c` |
| 0.0% | 0/12 | `203637969179399b99a253b1da432b33e21851733186c17d0edda2e8` | `7ebb04266b02690991de47d115d8bd522fec870187ac929e45df6b81` |
| 0.0% | 0/12 | `544921061ab56efe018feaee2da97d211e90d245104e93e155d35465` | `720d9dc96aae50a558290b1a8216e3a227d619f8c23f6609aa1b0fab` |
| 0.0% | 0/12 | `544921061ab56efe018feaee2da97d211e90d245104e93e155d35465` | `ebf225e977c623db52a658d88cce7c001d7816bc750e14fd2f811043` |
| 0.0% | 0/11 | `0220eea089c69e678ae43345e6a4f92d3ac36c87b069290865978958` | `720d9dc96aae50a558290b1a8216e3a227d619f8c23f6609aa1b0fab` |

Observed result: **19,440** DRep pairs have at least 10 common selected
actions.

The 19,440 figure comes from wrapping the same `?voter1 ?voter2`
aggregation in a `COUNT(*)`. This second query drops the outer `LIMIT 10`
so the headline number is reproducible from the same lattice:

```sparql
PREFIX cardano: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>

SELECT (COUNT(*) AS ?pairs)
WHERE {
  {
    SELECT ?voter1 ?voter2
           (COUNT(?actionKey) AS ?common)
           (SUM(IF(?verdict1 = ?verdict2, 1, 0)) AS ?agree)
    WHERE {
      {
        SELECT ?actionKey ?voter1 (SAMPLE(?verdict) AS ?verdict1)
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
                cardano:hasVerdict ?verdict .
          ?action cardano:hasTxId/cardano:bytesHex ?selectedTx ;
                  cardano:hasIndex ?selectedIndex .
          ?voter a cardano:VoterDRep ; cardano:hasIdentifier ?voter1 .
          BIND(CONCAT(?selectedTx, "#", STR(?selectedIndex)) AS ?actionKey)
        }
        GROUP BY ?actionKey ?voter1
        HAVING (COUNT(?vote) = 1)
      }
      {
        SELECT ?actionKey ?voter2 (SAMPLE(?verdict) AS ?verdict2)
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
                cardano:hasVerdict ?verdict .
          ?action cardano:hasTxId/cardano:bytesHex ?selectedTx ;
                  cardano:hasIndex ?selectedIndex .
          ?voter a cardano:VoterDRep ; cardano:hasIdentifier ?voter2 .
          BIND(CONCAT(?selectedTx, "#", STR(?selectedIndex)) AS ?actionKey)
        }
        GROUP BY ?actionKey ?voter2
        HAVING (COUNT(?vote) = 1)
      }
      FILTER(STR(?voter1) < STR(?voter2))
    }
    GROUP BY ?voter1 ?voter2
    HAVING (COUNT(?actionKey) >= 10)
  }
}
```

Observed result:

```text
pairs = 19440
```

Return to the [presentation](../case.md).
