# Spec — Typed `gov_action_id` sub-node on votes (closes #8)

Closes [#8](https://github.com/lambdasistemi/cardano-ledger-rdf/issues/8). Child of epic [#22](https://github.com/lambdasistemi/cardano-ledger-rdf/issues/22).

## Why

Today every `cardano:Vote` carries `cardano:hasVotingAction "<txid_hex>#<index>"` as a **string literal**. This is enough to identify the target action but breaks the bnode-identifier scheme used everywhere else in the emitter (`cardano:TxOutRef` for tx inputs, `cardano:Identifier` for credentials, etc.).

Consequence: SPARQL cannot join a vote's target to other places where the same `(txid, index)` pair appears (the submission tx, the parent-action chain references in `parameter_change_action` / `new_constitution` / `update_committee`) without parsing the string. The lattice-wide join `?vote → ?proposal` requires `STRSTARTS(STR(?action), "<txid>")` rather than a clean bnode equality.

## P1 user story

As a SPARQL author analysing voting patterns across the tx-graph lattice, I want `?vote cardano:hasVotingAction/cardano:hasTxId ?txidBnode` to join in one hop to `?submissionTx cardano:hasTxId ?txidBnode` — so every vote and its target proposal share a single deduplicated TxId Identifier bnode the engine collapses across files.

## Other user stories

- As a fixture maintainer, the typed `cardano:GovActionId` sub-block on votes mirrors the existing `cardano:TxOutRef` shape used for tx inputs; the predicates and bnode-naming scheme are consistent.
- As a SPARQL author querying co-vote patterns, the 1,687-tx-lattice from the 9-IO case study collapses thousands of vote subjects onto 9 GovActionId bnodes — making "which DReps voted on the same action" a graph traversal rather than a string substring match.

## Functional requirements

- **FR-1 — Typed `GovActionId` sub-block.** The `cardano:hasVotingAction` predicate MUST link a `cardano:Vote` to a typed `_:govActionIdK` bnode (class `cardano:GovActionId`) carrying `cardano:hasTxId _:hash_govactionid_<full-hex>` + `cardano:hasIndex <int>`.
- **FR-2 — TxId Identifier bnode deduplication.** The TxId bnode follows the same family-role-fullhex naming as other identifier leaves (e.g., `_:hash_govactionid_<full-hex>`); two votes targeting the same action produce two distinct vote subjects pointing at the same `_:hash_govactionid_…` bnode after canonicalization at SPARQL query time.
- **FR-3 — Coexistence (optional).** The emitter MAY keep a legacy string-literal predicate (e.g., `cardano:hasVotingActionId "<txid>#<ix>"`) alongside the typed sub-block for backwards compatibility. Judgment call — if existing consumers don't rely on it, drop it.
- **FR-4 — Vocab additions in `transactions.ttl`.** New class `cardano:GovActionId` and any new identifier leafType role declared in `transactions.ttl`. The predicate `cardano:hasVotingAction` gets its `rdfs:range` updated from `xsd:string` (or untyped) to `cardano:GovActionId`.
- **FR-5 — Goldens regenerated.** Every vote-bearing fixture under `test/fixtures/tx-graph/*/expected*.ttl` is regenerated with the new sub-block; tests pass byte-equality.

## Success criteria

- `nix build .#checks.x86_64-linux.{build,unit,lint}` green.
- For a fixture with 2+ votes targeting the same action, SPARQL `SELECT ?vote ?txid WHERE { ?vote a cardano:Vote ; cardano:hasVotingAction/cardano:hasTxId ?txid }` returns the votes paired with the same TxId Identifier bnode label.
- The 9-IO case-study report (epic #22's leaf child, lands later) can express `?vote cardano:hasVotingAction/cardano:hasTxId ?actionTxid` instead of `FILTER(STRSTARTS(STR(?actionLiteral), "73e171a4..."))`.

## Out of scope

- Typing the parent-action chain references in `parameter_change_action` / `new_constitution` / `update_committee` (filed as part of #5 and friends).
- Any changes to the proposal cluster (parallel work in worker α, branch `3-4-typed-proposal-cluster`).
