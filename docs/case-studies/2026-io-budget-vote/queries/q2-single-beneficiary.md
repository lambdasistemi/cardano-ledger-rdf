# Q2 - Single beneficiary

All 9 disbursements route to **one stake credential**:
`8583857e4a12ffe1e6f641a1785a0f2f036c565cfbe6ff9db8e5a469`.

That value is the credential hash exposed by the emitter. CBOR-level
reward account bytes include the network/header byte before the credential
payload, so they can appear as `f1858385...` in lower-level decodes.

```sparql
PREFIX cardano: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#>
SELECT (COUNT(DISTINCT ?recipient) AS ?n_recipients)
WHERE {
  ?act a cardano:TreasuryWithdrawals .
  ?act cardano:hasWithdrawal/cardano:toRewardAccount ?recipient .
}
```

Observed result: `n_recipients = 1`.

Return to the [presentation](../case.md).
