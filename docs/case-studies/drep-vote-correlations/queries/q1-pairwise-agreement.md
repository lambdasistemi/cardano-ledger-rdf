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
| 100.0% | 20/20 | `drep1y27qjjnz9a7q6zmvpajzqpqylnka6lpkvcm9sgjrdheqt0qq6pchw` | `drep1yfp4qmp849250svle8gw2m5jwjra86e76q8vz97wp998feg9mx9c5` |
| 100.0% | 20/20 | `drep1y2m0g4r66pyaw3p7u454wc0p4f0ygm8ueaev0mgd3tvwm7sskqwqp` | `drep1y2r5kww2gj4j6l2h7065fk5jtfhzxwf37ryygkdx4qhmpvqlah2jj` |
| 100.0% | 19/19 | `drep1y24xr6m4mkgl7e7886sk3wee7h73mcreysyvhrwzksy5ajqrv0rrv` | `drep1yfyx4tzq6hfu5w20n42ry0uc8tskaen57e2eytzwhzy7vkgqhawwu` |
| 100.0% | 19/19 | `drep1y26sfka2km0p4xw073ujdq406wxxczhdyfh9vw7yxpfselchzkdjn` | `drep1ytd2mf58tfqv78z7e99fy0gnmfep0kscclnwpvx7qvwpc5srxwg5g` |
| 100.0% | 19/19 | `drep1y27qjjnz9a7q6zmvpajzqpqylnka6lpkvcm9sgjrdheqt0qq6pchw` | `drep1y2v2ncht76apatlnxgtz8h8zy943avf7padqkkvycmzmcpcre7fek` |

For the divergent side, use the same query with
`ORDER BY ?agreementRate DESC(?common)`:

| Agreement | Same/common | DRep 1 | DRep 2 |
| ---: | ---: | --- | --- |
| 0.0% | 0/14 | `drep1yf7kjx5rlyuyzxkr4dzyccdfs8tesh29amrtcpyplu3asnqjgmdz3` | `drep1yggcntj7vdc2l3j05w0ep84ay8qjz0fnrse6rl8gccd9fsqadw3qg` |
| 0.0% | 0/12 | `drep1yf2yjggxr26kalsp3l4wutdf05s3ayxjg5gyaylp2hf4gegwceav4` | `drep1yfeqm8wfd2h9pf2c9y934qskuw3z04selrpr7esf4gdsl2c5zvpgf` |
| 0.0% | 0/12 | `drep1yf2yjggxr26kalsp3l4wutdf05s3ayxjg5gyaylp2hf4gegwceav4` | `drep1yt4lyf0fwlrz8k6j5evd3rxw0sqp67qkh36su98a97q3qsc0h03y4` |
| 0.0% | 0/12 | `drep1yfltkppxdvpxjzv3meraz9wch4fzlmy8qxr6ey57gh0khqgug8qln` | `drep1ygsrvdukj9unnxue5ffmrkjr9ve7yxz3wvccdstapmw696q8g2w9u` |
| 0.0% | 0/11 | `drep1yf7kjx5rlyuyzxkr4dzyccdfs8tesh29amrtcpyplu3asnqjgmdz3` | `drep1ygr93aecehnm95wr7ufpd2m6jyh2mc8vnr77f0w33g8upyc6m8ayz` |

Observed result: **19,440** DRep pairs have at least 10 common selected
actions.

Return to the [presentation](../case.md).
