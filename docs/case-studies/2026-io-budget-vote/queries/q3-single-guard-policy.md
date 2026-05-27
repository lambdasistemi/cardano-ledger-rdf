# Q3 - Single guard policy

All 9 proposals carry **one guard policy**:
`fa24fb305126805cf2164c161d852a0e7330cf988f1fe558cf7d4a64`.

```sparql
PREFIX cardano: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#>
SELECT (COUNT(DISTINCT ?policy) AS ?n_policies)
WHERE {
  ?act a cardano:TreasuryWithdrawals ;
       cardano:hasGuardPolicy ?policy .
}
```

The policy bytes are available directly on the identifier node:

```sparql
PREFIX cardano: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#>
SELECT DISTINCT ?policyHex
WHERE {
  ?act a cardano:TreasuryWithdrawals ;
       cardano:hasGuardPolicy/cardano:bytesHex ?policyHex .
}
ORDER BY ?policyHex
```

Observed result: `n_policies = 1`, with policy bytes
`fa24fb305126805cf2164c161d852a0e7330cf988f1fe558cf7d4a64`.

Return to the [presentation](../case.md).
