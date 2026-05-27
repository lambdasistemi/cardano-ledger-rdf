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
          # Same selected-action VALUES block as Q1.
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
anchored singleton observations = 1,672
all singleton observations = 4,563
```

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
