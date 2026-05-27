# DRep Vote Correlations Across Governance Actions

This case study asks whether DReps vote as stable blocs across multiple
Conway-era governance actions, or whether alignment changes by action type,
proposal epoch, rationale-anchor behaviour, and vote arrival order.

The dataset is a 5,299-transaction lattice: 11 action submission
transactions and 5,288 unique vote transactions covering 20 governance
actions from proposal epochs 576 through 632.

## Dataset and queries

Dataset assembly is documented in [Dataset selection](selection.md), with
the full transaction list in [`selections.txt`](selections.txt) and the
entity overlay in [`rules.yaml`](rules.yaml). SPARQL evidence is split into
one page per question: [Q1 pairwise agreement](queries/q1-pairwise-agreement.md),
[Q2 bloc detection](queries/q2-bloc-detection.md),
[Q3 swing prevalence](queries/q3-swing-prevalence.md),
[Q4 action-type correlation](queries/q4-action-type-correlation.md),
[Q5 anchor coverage](queries/q5-anchor-coverage.md), and
[Q6 arrival-time dynamics](queries/q6-arrival-time-dynamics.md).

The correlation queries use **unambiguous DRep/action observations**:
DRep/action groups with exactly one vote row. That leaves **4,563**
observations after excluding **538** revote rows, because the current
tx-graph lattice does not carry block time and therefore cannot choose the
latest vote deterministically.

## Entity rules

[`rules.yaml`](rules.yaml) names the two entities shared by all selected
treasury withdrawals. `io.budget-guard-policy` names guard policy
`fa24fb305126805cf2164c161d852a0e7330cf988f1fe558cf7d4a64`.
`intersect.treasury-holding` names stake credential
`8583857e4a12ffe1e6f641a1785a0f2f036c565cfbe6ff9db8e5a469`.

Gov action IDs remain raw query filters because the current `rules.yaml`
grammar has no `GovActionId` leaf type.

## Findings

### Pairwise DRep agreement

Among DRep pairs with at least 10 common selected actions, the lattice
contains **19,440** comparable pairs. The most-aligned pairs include exact
matches over 20, 19, and 18 common actions. The most-divergent pairs include
several pairs with **0%** agreement over 11 to 14 common actions. See
[Q1](queries/q1-pairwise-agreement.md) for the top aligned and divergent
pairs.

### Bloc detection

Using an edge threshold of at least 12 common actions and at least 90%
agreement, the agreement matrix yields **4 connected components** with at
least two DReps. The largest component has **142 DReps** and spans proposal
epochs **576 through 632**, so it is stable across the selected time range.
This clustering step is a post-process over a SPARQL-produced edge table,
not a pure SPARQL hierarchy. See [Q2](queries/q2-bloc-detection.md).

### Swing-voter prevalence

For DReps with at least 5 unambiguous selected-action votes, **229 of 313**
changed verdict at least once. The mono-verdict population is **84 DReps**:
**82 Yes-only** and **2 No-only**. Swinging is concentrated in the proposal
epochs that contain several selected treasury withdrawals: **42.3%** in
epoch 576 and **48.3%** in epoch 632. See
[Q3](queries/q3-swing-prevalence.md).

### Action-type correlation

Mean same-verdict pair rates differ sharply by action type. The single
selected `ParameterChange` action is highly concentrated at **93.2%**.
The selected `TreasuryWithdrawals` actions are much looser at **60.6%**,
while `InfoAction` lands at **79.6%**. See
[Q4](queries/q4-action-type-correlation.md).

### Voter-anchor heuristics

Among DReps with at least 5 unambiguous observations, **109** anchored at
least half of their votes and **204** did not. High-anchor DReps were not in
larger high-agreement neighbourhoods in this dataset: their average
90%-agreement degree was **13.5**, versus **19.3** for lower-anchor DReps.
See [Q5](queries/q5-anchor-coverage.md).

### Arrival-time dynamics

The current tx-graph lattice cannot answer early-vs-late voter dynamics on
its own because vote transaction block time is not emitted into RDF. The
Koios sidecar used during selection can compute the comparison, but Q6
documents it as a follow-up boundary rather than presenting it as a
SPARQL-native case-study claim. See
[Q6](queries/q6-arrival-time-dynamics.md).

## How to reproduce

```sh
# 1. Assemble cbor/ and emit the SPARQL-queryable lattice.
./pipeline.sh /tmp/io-gov-actions/drep-correlations

# 2. Extract any SPARQL block from a query page into a .rq file.
arq --data /tmp/io-gov-actions/drep-correlations/lattice.ttl --query q1.rq
```

The action filters in the query pages use `(txid, index)` pairs rather than
governance action bech32 strings. That mirrors tx-graph's typed
`cardano:GovActionId` shape: `cardano:hasTxId/cardano:bytesHex` plus
`cardano:hasIndex`.
