# Q6 - DRep behaviour

Across the IO-scoped vote set, **275 DReps** appear. **129** voted as a
mono-bloc, while **146** changed verdict across the 9 proposals. The
mono-bloc breakdown was **110 Yes-only**, **16 No-only**, and
**3 Abstain-only**.

That means more than half of the participating DReps did not treat the 9
requests as a single package. They split their vote by proposal.

```sparql
PREFIX cardano: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#>
SELECT
  (COUNT(?voterId) AS ?totalDReps)
  (SUM(IF(?n = 1, 1, 0)) AS ?monoBloc)
  (SUM(IF(?n > 1, 1, 0)) AS ?swingVoters)
WHERE {
  SELECT ?voterId (COUNT(DISTINCT ?v) AS ?n)
  WHERE {
    ?vote a cardano:Vote ;
          cardano:hasVotingAction ?action ;
          cardano:hasVoter ?voter ;
          cardano:hasVerdict ?v .
    ?action cardano:hasTxId/cardano:bytesHex "73e171a4c0730b4b59ecae271ab89f12a9d56360b02920e1f95107dbdc1d6762" .
    ?voter a cardano:VoterDRep ; cardano:hasIdentifier ?voterId .
  }
  GROUP BY ?voterId
}
```

The mono-bloc detail comes from the same IO-filtered voter grouping:

```sparql
PREFIX cardano: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#>
SELECT ?kind (COUNT(?voterId) AS ?n)
WHERE {
  {
    SELECT ?voterId (COUNT(DISTINCT ?v) AS ?nVerdicts) (SAMPLE(?v) AS ?onlyVerdict)
    WHERE {
      ?vote a cardano:Vote ;
            cardano:hasVotingAction ?action ;
            cardano:hasVoter ?voter ;
            cardano:hasVerdict ?v .
      ?action cardano:hasTxId/cardano:bytesHex "73e171a4c0730b4b59ecae271ab89f12a9d56360b02920e1f95107dbdc1d6762" .
      ?voter a cardano:VoterDRep ; cardano:hasIdentifier ?voterId .
    }
    GROUP BY ?voterId
  }
  BIND(IF(?nVerdicts > 1, "swing", STR(?onlyVerdict)) AS ?kind)
}
GROUP BY ?kind
ORDER BY ?kind
```

Observed result: `totalDReps = 275`, `monoBloc = 129`,
`swingVoters = 146`; mono-bloc detail is Yes-only `110`, No-only `16`,
and Abstain-only `3`.

Return to the [presentation](../case.md).
