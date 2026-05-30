# Q11 — Self-swap validation (operator-issued Sundae OrderDatum)

Every operator-issued Sundae V3 swap order MUST route its output
(`destination.address.payment_credential`) back to the treasury's
`amaru-treasury.network_compliance` script. The May 2026 batch
contains 21 such operator-issued orders, all targeting
`network_compliance` (script hash
`32201dc1e82708364c6c42a53f89f675314bb9ad5da2734aa10baa0d`).

"Operator-issued" is scoped by *enclosing-transaction provenance*:
the transaction creating the order must consume at least one
`network_compliance` UTxO. That subsetting matters because the
closure walk also includes third-party Sundae orders sharing the
same script address (`fa6a58bb…`), whose destinations are outside
the operator's accountability surface.

The shape of this query is **bad-rows-only**: the SELECT returns
zero rows on the real May 2026 lattice; any non-empty result is a
real invariant violation.

<div class="scrollbox" markdown>

```sparql
PREFIX cardano: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#>
PREFIX tx:      <https://lambdasistemi.github.io/cardano-rdf/fixtures/tx#>

SELECT ?txid ?datum ?destHex
WHERE {
  # Anchor: an operator-issued tx that emits an OrderDatum.
  ?tx a cardano:Transaction ;
      cardano:hasTxId/cardano:bytesHex ?txid ;
      cardano:hasOutput ?out .
  ?out cardano:hasDatum ?datum .
  ?datum tx:OrderDatum_destination ?dest .

  # Operator-issued: enclosing tx consumes a network_compliance UTxO.
  ?tx cardano:hasInput ?in .
  ?in cardano:fromTxOutRef ?ref .
  ?ref cardano:hasTxId ?parentIdNode ;
       cardano:hasIndex ?pIdx .
  ?parentTx cardano:hasTxId ?parentIdNode ;
            cardano:hasOutput ?parentOut .
  ?parentOut cardano:hasIndex ?pIdx ;
             cardano:atAddress ?parentAddr .
  ?parentAddr cardano:hasPaymentCredential ?parentPc .
  ?parentPc cardano:hasIdentifier ?parentIdent .
  ?parentIdent cardano:bytesHex
    "32201dc1e82708364c6c42a53f89f675314bb9ad5da2734aa10baa0d" .

  # Destination payment credential.
  ?dest tx:_0_address ?destAddr .
  ?destAddr tx:_0_payment_credential ?destPc .
  ?destPc tx:_0_field0 ?destIdent .
  ?destIdent cardano:bytesHex ?destHex .

  # Violation row: destination != network_compliance.
  FILTER (?destHex != "32201dc1e82708364c6c42a53f89f675314bb9ad5da2734aa10baa0d")
}
```

</div>

For the May 2026 batch this SPARQL returns **zero rows**: every
operator-issued Sundae order routes back to `network_compliance`.

This query is the human-readable explanation of the invariant.
The machine-enforced form is the SHACL shape
[`shapes/self-swap.shacl.ttl`](../shapes/self-swap.shacl.ttl), run
by `cq-rdf shacl --shapes shapes/` in the documented reproduce
pipe. Add the shape to the operator's lattice gate and a real
violation flips `cq-rdf shacl` to exit code 1 with the offending
datum bnode named in the report.

---

Return to the [presentation](../case.md).
