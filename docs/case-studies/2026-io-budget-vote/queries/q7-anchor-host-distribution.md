# Q7 - Anchor host distribution

The IO vote set contains **928 vote rationales with anchors**. The top
host is **`most-brass-sun.quicknode-ipfs.com` with 422 rationales**:
about **45%** of anchored IO vote rationales.

| Host | Vote rationales |
| --- | ---: |
| `most-brass-sun.quicknode-ipfs.com` | **422** |
| `raw.githubusercontent.com` | **75** |
| `ipfs.blockfrost.dev` | **18** |
| `bafkreictyichsdlpv3yomwqtbpk57e52hwijqn3bavbsi2jg2h5tzdpjdu` | **10** |
| `adastat.net` | **9** |
| `bafkreiaabwy5svzdd4peax2oxuv32enit2epyrzpevea6egzpr77unmllq` | **9** |
| `bafkreig3lbyratuaql2jtv5vxhbojpwi5brnmjdxm5ztijpmjlytrmqkhy` | **9** |
| `bafkreihn2injrckbqyste6xetsgninwyeyx2l5udz47o3okqgb4j6x3a54` | **9** |
| `brock.tools` | **9** |
| `gateway.pinata.cloud` | **9** |
| `314pool.com` | **8** |
| `QmTKPNQaAxyM1KeoGCPNsUTYgyDo8jeYm4F1YdjDL8b1BX` | **8** |

```sparql
PREFIX cardano: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#>
SELECT ?host (COUNT(?vote) AS ?n)
WHERE {
  ?vote a cardano:Vote ;
        cardano:hasVotingAction ?action ;
        cardano:hasAnchor/cardano:anchorUrl ?url .
  ?action cardano:hasTxId/cardano:bytesHex "73e171a4c0730b4b59ecae271ab89f12a9d56360b02920e1f95107dbdc1d6762" .
  BIND(REPLACE(STR(?url), "^[a-z]+://([^/]+).*", "$1") AS ?host)
}
GROUP BY ?host
ORDER BY DESC(?n)
LIMIT 12
```

The denominator is:

```sparql
PREFIX cardano: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#>
SELECT (COUNT(?vote) AS ?totalAnchoredVotes)
WHERE {
  ?vote a cardano:Vote ;
        cardano:hasVotingAction ?action ;
        cardano:hasAnchor/cardano:anchorUrl ?url .
  ?action cardano:hasTxId/cardano:bytesHex "73e171a4c0730b4b59ecae271ab89f12a9d56360b02920e1f95107dbdc1d6762" .
}
```

Observed result: top host `most-brass-sun.quicknode-ipfs.com = 422`;
denominator `totalAnchoredVotes = 928`.

The host regex `^[a-z]+://([^/]+).*` extracts the authority component of
URLs with a `host/path` shape. For `ipfs://<cid>` URLs there is no host
segment, so `REPLACE` leaves the input unchanged and the row's "host"
appears as the bare CID (e.g. `bafkrei...` or `Qm...`). Those rows are
the gatewayless IPFS rationales; they are not a real per-host bucket.

Return to the [presentation](../case.md).
