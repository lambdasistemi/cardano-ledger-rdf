# 9-IO 2026 Budget Vote Process

This case study asks what the 9 Input Output treasury-withdrawal
proposals looked like on-chain, who they paid, and how DReps voted on
them. The dataset is the 1,688-transaction lattice rooted at submission
transaction
`73e171a4c0730b4b59ecae271ab89f12a9d56360b02920e1f95107dbdc1d6762`:
one submission transaction and 1,687 vote transactions.

The report is SPARQL-driven. The typed `cardano:Proposal`,
`cardano:TreasuryWithdrawals`, and `cardano:GovActionId` predicates added
in the proposal and vote work make these questions graph traversals
instead of CBOR-specific Python decoding or string matching.

Proposal labels below use the public IO/Momentum proposal names and the
governance action index order for the shared submission transaction.[^labels]

## Asks per proposal

The 9 proposals ask for **162,145,961 ada** in total. Every row routes to
the same recipient credential; the table is ordered by the on-chain
withdrawal amount.

| Proposal | ADA ask | Recipient credential |
| --- | ---: | --- |
| Cardano Maintenance | **62,134,630** | `8583857e4a12ffe1e6f641a1785a0f2f036c565cfbe6ff9db8e5a469` |
| Consensus | **27,714,342** | `8583857e4a12ffe1e6f641a1785a0f2f036c565cfbe6ff9db8e5a469` |
| Cardano Upgrades | **13,103,039** | `8583857e4a12ffe1e6f641a1785a0f2f036c565cfbe6ff9db8e5a469` |
| Cardano High Assurance | **13,078,578** | `8583857e4a12ffe1e6f641a1785a0f2f036c565cfbe6ff9db8e5a469` |
| Pogun | **12,290,000** | `8583857e4a12ffe1e6f641a1785a0f2f036c565cfbe6ff9db8e5a469` |
| Plutus | **11,877,575** | `8583857e4a12ffe1e6f641a1785a0f2f036c565cfbe6ff9db8e5a469` |
| L2 Scalability | **10,425,871** | `8583857e4a12ffe1e6f641a1785a0f2f036c565cfbe6ff9db8e5a469` |
| Blockfrost | **7,920,000** | `8583857e4a12ffe1e6f641a1785a0f2f036c565cfbe6ff9db8e5a469` |
| Developer Experience | **3,601,926** | `8583857e4a12ffe1e6f641a1785a0f2f036c565cfbe6ff9db8e5a469` |

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

The sum was checked with the same graph path:

```sparql
PREFIX cardano: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#>
SELECT (SUM(?ada) AS ?totalAda) (COUNT(?proposal) AS ?rows)
WHERE {
  ?proposal a cardano:Proposal ;
            cardano:hasGovAction ?act .
  ?act cardano:hasWithdrawal ?w .
  ?w cardano:hasLovelace ?lov .
  BIND(?lov / 1000000 AS ?ada)
}
```

## Single beneficiary

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

## Single guard policy

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

## Proposer rationale anchors

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

## Vote tallies per proposal

The lattice contains **2,374 IO vote rows** across **9 action indexes**.
The join goes through typed `cardano:GovActionId`: SPARQL follows
`?vote cardano:hasVotingAction ?action`, then reads the action's
`cardano:hasTxId` and `cardano:hasIndex`.

The IO-action filter is important:
`?actionTxid cardano:bytesHex "73e171a4..."` scopes the query to this
submission transaction. Without it, the same vote transactions also expose
unrelated governance actions co-bundled with IO votes.

Grouping by `cardano:hasIndex` is also required. All 9 IO proposals share
the same submission transaction id, so the index is the discriminator.

| Action index | Proposal | Abstain | No | Yes | Total |
| ---: | --- | ---: | ---: | ---: | ---: |
| 0 | Developer Experience | **27** | **60** | **201** | **288** |
| 1 | Cardano Upgrades | **12** | **25** | **232** | **269** |
| 2 | Consensus | **11** | **18** | **239** | **268** |
| 3 | Cardano Maintenance | **24** | **39** | **206** | **269** |
| 4 | L2 Scalability | **38** | **65** | **161** | **264** |
| 5 | Cardano High Assurance | **22** | **31** | **210** | **263** |
| 6 | Plutus | **29** | **36** | **196** | **261** |
| 7 | Blockfrost | **44** | **89** | **109** | **242** |
| 8 | Pogun | **35** | **82** | **133** | **250** |

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

## DRep behaviour

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

## Rationale-anchor host distribution

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

> ⚠ **Workflow note**: This case study currently requires a Python preprocessing step to merge the 1,688 per-tx Turtle files into a single SPARQL-queryable file. That step will collapse to `tx-graph --in-dir cbor/ --out lattice.ttl` (one command) when [#26](https://github.com/lambdasistemi/cardano-ledger-rdf/issues/26) lands. Update this page when that PR merges.

## How to reproduce

```sh
tx-graph --in-dir cbor/ --out-dir ttl/      # 1,688 files
<merge step - to be replaced when #26 lands>
arq --data lattice.ttl --query Q.rq
```

Use the submission transaction id
`73e171a4c0730b4b59ecae271ab89f12a9d56360b02920e1f95107dbdc1d6762`
as the IO-action filter for vote queries. Reusing that filter prevents
co-bundled governance actions from leaking into the report.

[^labels]: Proposal labels and asks were reconciled against IO's 2026 proposal overview and the individual Momentum/GovernanceSpace pages for [Developer Experience](https://momentum.cardano.iog.io/proposals/developer-experience), [Cardano Upgrades](https://momentum.cardano.iog.io/proposals/cardano-upgrades), [Consensus](https://momentum.cardano.iog.io/proposals/consensus), [Cardano Maintenance](https://momentum.cardano.iog.io/proposals/cardano-maintenance), [L2 Scalability](https://momentum.cardano.iog.io/proposals/l2-scalability), [Cardano High Assurance](https://momentum.cardano.iog.io/proposals/cardano-high-assurance), [Plutus](https://momentum.cardano.iog.io/proposals/plutus), [Blockfrost](https://momentum.cardano.iog.io/proposals/blockfrost), and [Pogun](https://momentum.cardano.iog.io/proposals/pogun).
