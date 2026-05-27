# Spec — Typed `ProposalProcedure` cluster (closes #3 + #4)

Closes [#3](https://github.com/lambdasistemi/cardano-ledger-rdf/issues/3), [#4](https://github.com/lambdasistemi/cardano-ledger-rdf/issues/4). Child of epic [#22](https://github.com/lambdasistemi/cardano-ledger-rdf/issues/22).

## Why

Today `tx-graph` emits a `ProposalProcedure ConwayEra` as one `cardano:hasRawBytes` literal under a `cardano:decodedAs "<variant>"` sub-block. Only the gov-action constructor tag is surfaced; the inner structure — deposit, return address, anchor, and per-variant payload — is buried in the CBOR hex blob.

SPARQL queries over the lattice cannot answer "how much ADA was asked across all live treasury withdrawal proposals" or "which IPFS host carries the proposer's rationale" without an out-of-band CBOR decode in Python. This spec ships the typed walker that makes those queries trivial.

## P1 user story

As an operator running governance analytics over a tx-graph lattice, I want every `cardano:Proposal` subject to expose `cardano:hasDeposit`, `cardano:hasReturnAddress`, `cardano:hasAnchor`, and a per-variant typed `cardano:hasGovAction` sub-block — so a SPARQL query joining `?proposal → ?withdrawal → ?recipient + ?lovelace` returns ADA-amount-per-beneficiary rows directly, with no CBOR decode in the consumer.

## Other user stories

- As a SPARQL author, the `transactions.ttl` vocabulary publishes the new predicates (`cardano:hasDeposit`, `cardano:hasReturnAddress`, `cardano:hasWithdrawal`, `cardano:toRewardAccount`, `cardano:hasLovelace`, `cardano:hasGuardPolicy`) and the new classes (`cardano:TreasuryWithdrawals`, `cardano:Withdrawal`) so the predicates dereference at their hosted IRIs.
- As a fixture maintainer, the goldens that exercise the existing `_:proposalDatumK cardano:hasRawBytes …` shape get re-rendered with the new typed predicates; tests are byte-stable; the `decodedAs + hasRawBytes` pair is retained alongside the typed predicates so consumers that still parse the raw bytes continue working.

## Functional requirements

- **FR-1 — Typed proposal shell (covers #4).** `buildProposalCluster` MUST emit `cardano:hasDeposit ?lovelace`, `cardano:hasReturnAddress ?credBnode`, and `cardano:hasAnchor ?anchorBnode` on every `cardano:Proposal` subject, regardless of which `GovAction` variant the proposal carries. The anchor sub-block MUST reuse the `cardano:Anchor` shape already in use for `cardano:Vote → hasAnchor` (`anchorUrl`, `anchorHash`).
- **FR-2 — Typed `TreasuryWithdrawals` body (covers #3).** For proposals whose action is `TreasuryWithdrawals`, the emitter MUST also emit one `cardano:hasWithdrawal _:withdrawalK_i` per entry in the `{reward_account → coin}` map, each pointing at a sub-block with `cardano:toRewardAccount ?credBnode` and `cardano:hasLovelace ?intLit`. When the optional guard policy is set, the emitter MUST emit `cardano:hasGuardPolicy ?scriptHashBnode`.
- **FR-3 — Vocab additions in `transactions.ttl`.** All new predicates and classes MUST be declared in `vocab/cardano/transactions.ttl` with `rdfs:label`, `rdfs:domain` (where unambiguous), `rdfs:range` (where typeable), and `dcterms:description`. Existing predicates that were silent on the proposal cluster (notably `cardano:hasAnchor` if currently scoped to votes) MUST get their `rdfs:domain` widened.
- **FR-4 — Backward-compatible coexistence.** The existing `cardano:decodedAs "<variant>"` + `cardano:hasRawBytes "<cbor-hex>"` pair on the datum sub-block is RETAINED. The typed predicates are added on the *proposal* subject, not on the datum sub-block — they coexist as parallel views.
- **FR-5 — Other gov-action variants still emit the shell only.** For `ParameterChange`, `HardForkInitiation`, `NoConfidence`, `UpdateCommittee`, `NewConstitution`, `InfoAction`, the shell predicates (FR-1) MUST be emitted. The inner per-variant typed bodies for these other constructors are out of scope (queued in #5, #6, #7).
- **FR-6 — Goldens regenerated and byte-stable.** All affected `test/fixtures/tx-graph/*/expected*.ttl` files MUST be regenerated; the test suite MUST pass byte-equality.

## Success criteria

- `nix build .#checks.x86_64-linux.{build,unit,lint}` green.
- For the 9-IO mainnet submission tx fixture (or its equivalent in the goldens harness), SPARQL `SELECT ?ada WHERE { ?p a cardano:Proposal ; cardano:hasGovAction/cardano:hasWithdrawal/cardano:hasLovelace ?ada } ORDER BY DESC(?ada)` returns 9 rows, summing to 162_145_961_000_000 lovelace (= ₳162,145,961).
- The hosted IRIs for new predicates dereference at `https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#<predicate>` (the docs-deploy job ships the updated `transactions.ttl`).

## Out of scope

- Per-variant typed bodies for the other 6 `GovAction` constructors (filed as #5, #6, #7).
- `gov_action_id` sub-node typing on votes (filed as #8 — parallel PR β).
- Decoder changes for any non-proposal-procedure raw-bytes site.
