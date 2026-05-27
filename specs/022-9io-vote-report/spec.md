# Spec — Case study: the 9-IO 2026-budget treasury withdrawal vote

Closes epic [#22](https://github.com/lambdasistemi/cardano-ledger-rdf/issues/22). Depends on #3, #4, #8 (merged via PR #23 and PR #24).

## Why

We can now express, in SPARQL over a tx-graph lattice, the questions that previously required out-of-band CBOR decoding in Python:

- Per-proposal ADA asks and beneficiary stake addresses (via `cardano:hasGovAction/cardano:hasWithdrawal`)
- Per-proposal proposer rationale anchor URLs (via `cardano:hasAnchor`)
- Vote totals broken down by proposal AND voter role (via the typed `cardano:GovActionId` join)
- Bloc analysis, swing voters, and rationale-anchor host distribution

This case study turns the typed-emitter advances into an evidence-backed operator narrative.

## P1 user story

As an operator looking at the merged decoder work and wanting to know "what did the 9 IO treasury proposals actually look like on-chain, and who voted how on them", I want a single docs page that answers each question with both prose AND the SPARQL that produced the number — so the report is reproducible against any tx-graph lattice and serves as the executable demo for the typed predicates.

## Other user stories

- As a reviewer of the typed-emitter work, the page demonstrates that #3, #4, #8 are not theoretical wins: each predicate they added gets exercised by a real query against the 9-IO mainnet data and that query returns a numeric answer.
- As a future case-study author, the page is the template: title, dataset summary, query section, prose interpretation, sources.

## Functional requirements

- **FR-1 — Asks per proposal.** A SPARQL query joining `cardano:Proposal → cardano:hasGovAction → cardano:hasWithdrawal → (cardano:toRewardAccount, cardano:hasLovelace)` returns 9 rows (one per IO proposal) with the recipient stake credential and the ADA amount. The total MUST equal ₳162,145,961 (the on-chain sum that we already verified by Python CBOR decode earlier in the session).
- **FR-2 — Single beneficiary.** A query MUST surface that all 9 withdrawals route to one stake credential hash `f18583857e4a12ffe1e6f641a1785a0f2f036c565cfbe6ff9db8e5a469`.
- **FR-3 — Single guard policy.** A query MUST surface that all 9 proposals carry the same guard `cardano:hasGuardPolicy` script hash `fa24fb305126805cf2164c161d852a0e7330cf988f1fe558cf7d4a64`.
- **FR-4 — Proposer rationale anchors.** A query over `cardano:Proposal → cardano:hasAnchor → cardano:anchorUrl` exposes the proposer's anchor URLs (this is `#4` shell territory — was raw bytes before).
- **FR-5 — Vote tallies via typed gov_action_id.** A query joining `?vote/hasVotingAction/hasTxId` to `?proposal/hasTxId` enumerates vote rows per proposal without a `STRSTARTS` string trick (this exercises `#8`). Tallies per (proposal, verdict) MUST equal the Koios-confirmed numbers (288, 269, 268, 269, 264, 263, 261, 242, 250 vote rows across the 9 actions; sum 2,374).
- **FR-6 — Bloc + swing voter SPARQL.** Reproduce the "47 all-Yes / 11 all-No / 146 swing voters" finding via SPARQL.
- **FR-7 — Rationale-anchor host distribution.** Reproduce the "422 votes link to most-brass-sun.quicknode-ipfs.com" finding via SPARQL over `cardano:Vote → cardano:hasAnchor → cardano:anchorUrl`.
- **FR-8 — Page lives in MkDocs.** `docs/case-studies/2026-io-budget-vote.md` registered in `mkdocs.yml`; the page builds and dereferences at the deployed URL.
- **FR-9 — Every numeric claim has a sibling SPARQL.** No hard-coded numbers without a query that produces them.

## Success criteria

- `mkdocs build` clean; page renders.
- All listed SPARQL queries execute against a real lattice (re-emitted using the merged emitter binary) and produce the documented numbers.
- The page passes a self-test: a small CI helper (or smoke script) loads the lattice into ARQ and re-runs the listed queries, checking each against the documented number.

## Dataset

- Submission tx: `73e171a4c0730b4b59ecae271ab89f12a9d56360b02920e1f95107dbdc1d6762`
- Vote txs: 1,687 unique
- CBOR cache already on disk at `/tmp/io-gov-actions/cbor/*.cbor` (1,688 files; fetched via Koios earlier this session). Re-emit via `tx-graph --in-dir /tmp/io-gov-actions/cbor --out-dir /tmp/io-gov-actions/ttl-v2` using the post-merge emitter.

## Out of scope

- New typed-walker work (the 9 remaining audit tickets #5, #6, #7, #9–#14 stay queued).
- Live CI gate for the SPARQL self-test — judgment call whether to add it now or leave as a follow-up.
- Cross-budget comparison (only the 9-IO batch is in scope).
