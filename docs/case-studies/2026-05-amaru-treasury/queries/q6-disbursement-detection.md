# Q6 — Disbursement detection

```sparql
PREFIX cardano: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#>

SELECT ?seedTxId ?lovelaceDisbursed
WHERE {
  ?seed cardano:hasLatticeRole "seed" ;
        cardano:hasTxId/cardano:bytesHex ?seedTxId ;
        cardano:hasInput ?in ;
        cardano:hasOutput ?out .
  ?in cardano:fromTxOutRef ?ref .
  ?ref cardano:hasTxId ?h ; cardano:hasIndex ?ix .
  ?h cardano:bytesHex ?parentHex .
  ?parent cardano:hasTxId/cardano:bytesHex ?parentHex ; cardano:hasOutput ?parentOut .
  ?parentOut cardano:hasIndex ?ix ;
             cardano:atAddress/cardano:bech32 "addr1x8ndhlc...contingency" .
  ?out cardano:atAddress/cardano:bech32 "addr1xyezq8w...network_compliance" ;
       cardano:lovelace ?lovelaceDisbursed .
}
```

| tx hash                                                              | disbursed ADA |
|----------------------------------------------------------------------|--------------:|
| `18d57a4f104df4cc776104ce626958e2110122392e4c4c7671edc8861b48452e`   | 205,000.000   |

One disbursement in May: 205,000 ADA from contingency to
network_compliance. The query never needed a typed-redeemer decode —
it pattern-matches on the closure-resolved input address + the
output address.

```mermaid
flowchart LR
  parentUtxo["parent UTxO<br/>at contingency<br/>4,057,000 ADA"] -->|input| tx["tx 18d57a4f<br/>(4-of-4 multisig)"]
  tx -->|output 0<br/>3,852,000 ADA change| cont["contingency"]
  tx -->|"output 1<br/>205,000 ADA"| netcomp["network_compliance"]
  tx -->|"output 2<br/>92.14 ADA + fee"| netop["network-operator"]
```

---


Return to the [presentation](../case.md).
