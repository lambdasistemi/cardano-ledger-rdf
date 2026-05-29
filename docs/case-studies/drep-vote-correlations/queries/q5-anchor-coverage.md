# Q5 - Voter-anchor heuristics

For DReps with at least 5 unambiguous selected-action observations, **109**
anchored at least half of their votes and **204** did not. High-anchor DReps
were not in larger high-agreement neighbourhoods in this dataset: their
average 90%-agreement degree was **13.5**, versus **19.3** for lower-anchor
DReps.

The first query computes per-DRep anchor coverage over the same
unambiguous-observation set used by Q1 through Q4.

```sparql
PREFIX cardano: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>

SELECT ?bucket (COUNT(?voterId) AS ?drepCount)
WHERE {
  {
    SELECT ?voterId
           (COUNT(?actionKey) AS ?n)
           (SUM(?hasAnchor) AS ?anchored)
    WHERE {
      {
        SELECT ?actionKey ?voterId
               (SAMPLE(IF(BOUND(?anchor), 1, 0)) AS ?hasAnchor)
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
          OPTIONAL { ?vote cardano:hasAnchor ?anchor . }
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
  BIND(IF(xsd:decimal(?anchored) / xsd:decimal(?n) >= 0.5,
          "anchorCoverage>=50%",
          "anchorCoverage<50%") AS ?bucket)
}
GROUP BY ?bucket
ORDER BY ?bucket
```

Observed result:

```text
anchorCoverage>=50% = 109
anchorCoverage<50% = 204
```

[sidecar analysis, not the displayed query] Anchored singleton observations
**1,672** out of **4,563** total singleton observations. These two totals
are not produced by the displayed SELECT (which buckets DReps, not raw
observations); they are computed from the same unambiguous-observation
set as a sidecar sum of `?hasAnchor` and a count of `?actionKey`.

The typed certificate walker also makes DRep registration and update
anchors queryable when those certificates are present in the lattice. The
selected vote-correlation transaction set contains no anchored `RegDRep` or
`UpdateDRep` certificates, so there is no manifesto-side split to join into
this case-study result:

```sparql
PREFIX cardano: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#>

SELECT (COUNT(?cert) AS ?drepAnchorCerts)
WHERE {
  VALUES ?certType { cardano:RegDRep cardano:UpdateDRep }
  ?cert a ?certType ;
        cardano:hasAnchor ?anchor .
}
```

Observed result: `drepAnchorCerts = 0`.

The neighbourhood-size comparison joins this coverage table to the Q1 edge
extract filtered to `agreementRate >= 0.90`. That join is a matrix
post-process because SPARQL produces the edge table, while the degree
summary is easier and clearer after materialising the edges.

Observed result:

| Bucket | DReps | Average 90%-agreement degree | Median degree |
| --- | ---: | ---: | ---: |
| anchorCoverage>=50% | 109 | 13.5 | 3 |
| anchorCoverage<50% | 204 | 19.3 | 5 |

Return to the [presentation](../case.md).
