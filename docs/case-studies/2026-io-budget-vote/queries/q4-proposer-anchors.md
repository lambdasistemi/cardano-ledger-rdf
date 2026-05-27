# Q4 - Proposer rationale anchors

The proposal procedure shell exposes **9 proposer rationale anchors** as
typed `cardano:Anchor` nodes. This is the field that used to be raw bytes
before the typed proposal-procedure work.

```text
ipfs://QmNqVt8X1EX9iJJXGaEeiZ5nbePL91NkZcoVedpn6gfKWA
ipfs://Qmf3GSWna8PQFF2Vi5Css4R5pvGfaVUZ1zhCfHw9LqGKNV
ipfs://QmeNzwKE9bMyr65E4Dxtvoji7WBbazXUVykqQWq1pHXZvQ
ipfs://QmVdGh1cXgsMXGRS7mzxurxtkaqhU7VJMjx4piNSSHrBs2
ipfs://QmPkZ6Azo1tJfWVRjwn8G1Qk7k1SC3Vk3L21WFPSracCzg
ipfs://QmSaGx6WutdwLgfsw34JyawNf1a7XuK1YchEerdKSp8EkT
ipfs://QmfM3VRtGvpmxTDYrgGJoPSLW41SiNyeazfjusg98jrATS
ipfs://QmZMFAZvCxW6HpRC1EKzNcensJv9N89yzKPn7uRTTJdTpx
ipfs://QmUnSimkwuaXX357ugYxDkiUMzsKTYgcWvV74xWbiXUt3Y
```

```sparql
PREFIX cardano: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#>
SELECT ?proposal ?url
WHERE {
  ?proposal a cardano:Proposal ;
            cardano:hasAnchor/cardano:anchorUrl ?url .
}
ORDER BY ?proposal ?url
```

Observed result: **9 IPFS URLs**.

Return to the [presentation](../case.md).
