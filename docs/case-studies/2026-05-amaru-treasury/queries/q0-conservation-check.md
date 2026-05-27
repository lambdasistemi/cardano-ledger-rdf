# Q0 — Conservation check

Sanity gate: total ADA consumed by seed inputs must equal total ADA
emitted in seed outputs + total fees. Any non-zero gap is a
bug in the lattice (missing closure, predicate mismatch, …).

```sparql
PREFIX cardano: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#>

SELECT ?totalSeedInputLovelace ?totalSeedOutputLovelace ?totalSeedFee
       ((?totalSeedInputLovelace - ?totalSeedOutputLovelace - ?totalSeedFee) AS ?gap)
WHERE {
  { SELECT (SUM(?l) AS ?totalSeedInputLovelace) WHERE {
      ?seed cardano:hasLatticeRole "seed" ; cardano:hasInput ?in .
      ?in cardano:fromTxOutRef ?ref .
      ?ref cardano:hasTxId ?h ; cardano:hasIndex ?ix .
      ?h cardano:bytesHex ?parentHex .
      ?parent cardano:hasTxId/cardano:bytesHex ?parentHex ; cardano:hasOutput ?parentOut .
      ?parentOut cardano:hasIndex ?ix ; cardano:lovelace ?l .
  } }
  { SELECT (SUM(?l) AS ?totalSeedOutputLovelace) WHERE {
      ?seed cardano:hasLatticeRole "seed" ; cardano:hasOutput ?out .
      ?out cardano:lovelace ?l .
  } }
  { SELECT (SUM(?f) AS ?totalSeedFee) WHERE {
      ?seed cardano:hasLatticeRole "seed" ; cardano:hasFee ?f .
  } }
}
```

| input ADA      | output ADA     | fee ADA  | gap ADA |
|----------------|----------------|----------|---------|
| 22,186,097.902 | 22,186,077.971 | 19.931   | **0.000** |

**Books balance exactly. The lattice is conservation-complete.**

---


Return to the [presentation](../case.md).
