# 9-IO 2026 Budget Vote Process

This case study asks what the 9 Input Output treasury-withdrawal
proposals looked like on-chain, who they paid, and how DReps voted on
them. The dataset is the 1,688-transaction lattice rooted at submission
transaction
`73e171a4c0730b4b59ecae271ab89f12a9d56360b02920e1f95107dbdc1d6762`:
one submission transaction and 1,687 vote transactions.

The report is SPARQL-driven. The typed `cardano:Proposal`,
`cardano:TreasuryWithdrawals`, and `cardano:GovActionId` predicates added
in the proposal and vote work make the workflow one emitter command plus
SPARQL, instead of CBOR-specific Python decoding or string matching.

Proposal labels below use the public IO/Momentum proposal names and the
governance action index order for the shared submission transaction.[^labels]

## Dataset and queries

The dataset assembly is documented in [Dataset selection](selection.md),
with the full transaction list in [`selections.txt`](selections.txt),
the entity overlay in [`overlay.yaml`](overlay.yaml), and the reproduce
pipe in [`README.md`](README.md). The SPARQL evidence is split into one
page per query: [Q1 asks](queries/q1-asks.md),
[Q2 beneficiary](queries/q2-single-beneficiary.md),
[Q3 guard policy](queries/q3-single-guard-policy.md),
[Q4 anchors](queries/q4-proposer-anchors.md),
[Q5 vote tallies](queries/q5-vote-tallies.md),
[Q6 DRep behaviour](queries/q6-drep-behaviour.md), and
[Q7 anchor hosts](queries/q7-anchor-host-distribution.md).

## Entity rules

[`overlay.yaml`](overlay.yaml) names two 9-IO entities. The guard policy is
`io.budget-guard-policy`, keyed by script hash
`fa24fb305126805cf2164c161d852a0e7330cf988f1fe558cf7d4a64`. The treasury
beneficiary credential is `intersect.treasury-holding`, keyed as a
`StakeKey` with bytes
`8583857e4a12ffe1e6f641a1785a0f2f036c565cfbe6ff9db8e5a469`, so the
lattice resolves the shared beneficiary credential to its named form. The
shared governance action id remains a raw query filter because the current
`keys:` grammar has no `GovActionId` leaf type.

## Findings

### Asks per proposal

The 9 proposals ask for **162,145,961 ada** in total. Every row routes to the same recipient credential.

| Proposal | ADA ask |
| --- | ---: |
| Cardano Maintenance | **62,134,630** |
| Consensus | **27,714,342** |
| Cardano Upgrades | **13,103,039** |
| Cardano High Assurance | **13,078,578** |
| Pogun | **12,290,000** |
| Plutus | **11,877,575** |
| L2 Scalability | **10,425,871** |
| Blockfrost | **7,920,000** |
| Developer Experience | **3,601,926** |

### Single beneficiary and guard

All 9 disbursements route to **one stake credential**, `8583857e4a12ffe1e6f641a1785a0f2f036c565cfbe6ff9db8e5a469`, and all 9 proposals carry **one guard policy**, `fa24fb305126805cf2164c161d852a0e7330cf988f1fe558cf7d4a64`.

### Proposer rationale anchors

The proposal procedure shell exposes **9 proposer rationale anchors** as typed `cardano:Anchor` nodes. See [Q4](queries/q4-proposer-anchors.md) for the full IPFS URL list and query.

### Vote tallies per proposal

The lattice contains **2,374 IO vote rows** across **9 action indexes**. The typed `cardano:GovActionId` join scopes votes to the shared submission transaction and uses `cardano:hasIndex` to distinguish the 9 proposals.

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

### DRep behaviour

Across the IO-scoped vote set, **275 DReps** appear. **129** voted as a mono-bloc, while **146** changed verdict across the 9 proposals. The mono-bloc breakdown was **110 Yes-only**, **16 No-only**, and **3 Abstain-only**.

### Rationale-anchor host distribution

The IO vote set contains **928 vote rationales with anchors**. The top host is **`most-brass-sun.quicknode-ipfs.com` with 422 rationales**, about **45%** of anchored IO vote rationales. See [Q7](queries/q7-anchor-host-distribution.md) for the top-12 host table.

## How to reproduce

The reproduce pipe is documented in [`README.md`](README.md). In
summary, from this directory:

```bash
cq-rdf overlay --in overlay.yaml > overlay.ttl
xargs -P8 -n1 cq-rdf body --provider koios < selections.txt > bodies.ttl
cat overlay.ttl bodies.ttl > package.ttl

# Then run any of the 7 documented queries after saving its SPARQL block:
arq --data package.ttl --query q1-asks.rq
```

In `package.ttl`, every per-transaction-position blank node is namespaced
by its short transaction id, so positional bnodes such as `_:input1`,
`_:vote1`, and `_:proposal1` do not collide across the 1,688
transactions. Content-addressed identifiers are emitted as stable
`urn:cardano:id:*` IRIs, so cross-transaction joins work without depending
on blank-node labels. The reader does not need to apply this naming rule;
`cq-rdf body` handles it.

Use the submission transaction id
`73e171a4c0730b4b59ecae271ab89f12a9d56360b02920e1f95107dbdc1d6762`
as the IO-action filter for vote queries. Reusing that filter prevents
co-bundled governance actions from leaking into the report.

[^labels]: Proposal labels and asks were reconciled against IO's 2026 proposal overview and the individual Momentum/GovernanceSpace pages for [Developer Experience](https://momentum.cardano.iog.io/proposals/developer-experience), [Cardano Upgrades](https://momentum.cardano.iog.io/proposals/cardano-upgrades), [Consensus](https://momentum.cardano.iog.io/proposals/consensus), [Cardano Maintenance](https://momentum.cardano.iog.io/proposals/cardano-maintenance), [L2 Scalability](https://momentum.cardano.iog.io/proposals/l2-scalability), [Cardano High Assurance](https://momentum.cardano.iog.io/proposals/cardano-high-assurance), [Plutus](https://momentum.cardano.iog.io/proposals/plutus), [Blockfrost](https://momentum.cardano.iog.io/proposals/blockfrost), and [Pogun](https://momentum.cardano.iog.io/proposals/pogun).
