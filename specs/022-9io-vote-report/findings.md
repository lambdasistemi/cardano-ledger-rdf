# Slice A Findings - 9-IO Vote SPARQL Verification

Dataset:

- CBOR cache: `/tmp/io-gov-actions/cbor/` - 1,688 files.
- Re-emitted TTL: `/tmp/io-gov-actions/ttl-v2/` - 1,688 files.
- Merged TTL: `/tmp/io-gov-actions/lattice-v2.ttl` - 11,853,818 bytes.
- Merge rule: per-file prefixes were applied to positional blank nodes only; deterministic `_:hash_*` and `_:cred_*` blank nodes were preserved so cross-transaction identifier joins remain valid.
- Submission transaction / IO governance action transaction id: `73e171a4c0730b4b59ecae271ab89f12a9d56360b02920e1f95107dbdc1d6762`.

## Q1 - Asks per proposal

Expected: 9 rows summing to 162,145,961 ADA.

Query:

```sparql
PREFIX cardano: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#>
SELECT ?proposal ?recipient ?ada
WHERE {
  ?proposal a cardano:Proposal ;
            cardano:hasGovAction ?act .
  ?act cardano:hasWithdrawal ?w .
  ?w cardano:toRewardAccount/cardano:bytesHex ?recipient ;
     cardano:hasLovelace ?lov .
  BIND(?lov / 1000000 AS ?ada)
}
ORDER BY DESC(?ada)
```

Answer:

| recipient credential | ADA |
| --- | ---: |
| `8583857e4a12ffe1e6f641a1785a0f2f036c565cfbe6ff9db8e5a469` | 62,134,630 |
| `8583857e4a12ffe1e6f641a1785a0f2f036c565cfbe6ff9db8e5a469` | 27,714,342 |
| `8583857e4a12ffe1e6f641a1785a0f2f036c565cfbe6ff9db8e5a469` | 13,103,039 |
| `8583857e4a12ffe1e6f641a1785a0f2f036c565cfbe6ff9db8e5a469` | 13,078,578 |
| `8583857e4a12ffe1e6f641a1785a0f2f036c565cfbe6ff9db8e5a469` | 12,290,000 |
| `8583857e4a12ffe1e6f641a1785a0f2f036c565cfbe6ff9db8e5a469` | 11,877,575 |
| `8583857e4a12ffe1e6f641a1785a0f2f036c565cfbe6ff9db8e5a469` | 10,425,871 |
| `8583857e4a12ffe1e6f641a1785a0f2f036c565cfbe6ff9db8e5a469` | 7,920,000 |
| `8583857e4a12ffe1e6f641a1785a0f2f036c565cfbe6ff9db8e5a469` | 3,601,926 |

Sum query result: `162145961.0` ADA across 9 rows.

Status: matches expected.

## Q2 - Single beneficiary

Expected: `n_recipients = 1`.

Query:

```sparql
PREFIX cardano: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#>
SELECT (COUNT(DISTINCT ?recipient) AS ?n_recipients)
WHERE {
  ?act a cardano:TreasuryWithdrawals .
  ?act cardano:hasWithdrawal/cardano:toRewardAccount ?recipient .
}
```

Answer: `n_recipients = 1`.

Distinct recipient credential bytes exposed by the emitter:

```text
8583857e4a12ffe1e6f641a1785a0f2f036c565cfbe6ff9db8e5a469
```

Status: count matches expected. Representation note: the emitter exposes the stake credential bytes; the raw reward-account bytes in the datum include the address header byte before this credential.

## Q3 - Single guard policy

Expected: `n_policies = 1`.

Query:

```sparql
PREFIX cardano: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#>
SELECT (COUNT(DISTINCT ?policy) AS ?n_policies)
WHERE {
  ?act a cardano:TreasuryWithdrawals ;
       cardano:hasGuardPolicy ?policy .
}
```

Answer: `n_policies = 1`.

Distinct guard policy bytes:

```text
fa24fb305126805cf2164c161d852a0e7330cf988f1fe558cf7d4a64
```

Status: matches expected.

## Q4 - Proposer anchor URLs

Expected: 9 URLs.

Query:

```sparql
PREFIX cardano: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#>
SELECT ?proposal ?url
WHERE {
  ?proposal a cardano:Proposal ;
            cardano:hasAnchor/cardano:anchorUrl ?url .
}
ORDER BY ?proposal ?url
```

Answer:

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

Status: matches expected.

## Q5 - Tallies per proposal via typed `gov_action_id`

Expected: 27 rows, 9 action indexes times 3 verdicts; sum 2,374. Per-action totals: 288, 269, 268, 269, 264, 263, 261, 242, 250.

The brief's sketch groups by `cardano:hasTxId`; because these 9 proposal procedures are all in the same transaction, the query also groups by typed `cardano:hasIndex`.

Query:

```sparql
PREFIX cardano: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#>
SELECT ?actionTxid ?actionIndex ?verdict (COUNT(*) AS ?n)
WHERE {
  ?vote a cardano:Vote ;
        cardano:hasVotingAction ?action ;
        cardano:hasVerdict ?verdict .
  ?action cardano:hasTxId ?actionTxid ;
          cardano:hasIndex ?actionIndex .
  ?actionTxid cardano:bytesHex "73e171a4c0730b4b59ecae271ab89f12a9d56360b02920e1f95107dbdc1d6762" .
}
GROUP BY ?actionTxid ?actionIndex ?verdict
ORDER BY ?actionIndex ?verdict
```

Answer:

| action index | Abstain | No | Yes | total |
| ---: | ---: | ---: | ---: | ---: |
| 0 | 27 | 60 | 201 | 288 |
| 1 | 12 | 25 | 232 | 269 |
| 2 | 11 | 18 | 239 | 268 |
| 3 | 24 | 39 | 206 | 269 |
| 4 | 38 | 65 | 161 | 264 |
| 5 | 22 | 31 | 210 | 263 |
| 6 | 29 | 36 | 196 | 261 |
| 7 | 44 | 89 | 109 | 242 |
| 8 | 35 | 82 | 133 | 250 |

Totals query result: 2,374 votes, 9 action indexes, 3 verdicts.

Status: matches expected after filtering to the IO submission transaction and grouping by action index.

## Q6 - DRep behaviour

Expected ballpark: `totalDReps` about 275, `monoBloc` about 129, `swingVoters` about 146.

Query:

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

Answer:

| totalDReps | monoBloc | swingVoters |
| ---: | ---: | ---: |
| 275 | 129 | 146 |

Supplemental mono-bloc detail:

| kind | DReps |
| --- | ---: |
| Abstain-only | 3 |
| No-only | 16 |
| Yes-only | 110 |
| Swing | 146 |

Status: matches expected ballpark and the 129/146 target split.

## Q7 - Anchor host distribution

Expected: top host `most-brass-sun.quicknode-ipfs.com` with about 422 votes.

Query:

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

Answer:

| host | votes |
| --- | ---: |
| `most-brass-sun.quicknode-ipfs.com` | 422 |
| `raw.githubusercontent.com` | 75 |
| `ipfs.blockfrost.dev` | 18 |
| `bafkreictyichsdlpv3yomwqtbpk57e52hwijqn3bavbsi2jg2h5tzdpjdu` | 10 |
| `adastat.net` | 9 |
| `bafkreiaabwy5svzdd4peax2oxuv32enit2epyrzpevea6egzpr77unmllq` | 9 |
| `bafkreig3lbyratuaql2jtv5vxhbojpwi5brnmjdxm5ztijpmjlytrmqkhy` | 9 |
| `bafkreihn2injrckbqyste6xetsgninwyeyx2l5udz47o3okqgb4j6x3a54` | 9 |
| `brock.tools` | 9 |
| `gateway.pinata.cloud` | 9 |
| `314pool.com` | 8 |
| `QmTKPNQaAxyM1KeoGCPNsUTYgyDo8jeYm4F1YdjDL8b1BX` | 8 |

Status: matches expected.

