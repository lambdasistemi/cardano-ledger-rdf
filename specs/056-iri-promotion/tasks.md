# Tasks - IRI promotion for cross-response composability

Issue: [#56](https://github.com/lambdasistemi/cardano-ledger-rdf/issues/56)

## Slice T056-S1

- [X] T056-S1 - Add IRI minting helpers for tx, UTxO, and identifier resources.
- [X] T056-S1 - Promote the transaction subject and `cardano:hasTxId` target to IRIs.
- [X] T056-S1 - Promote body output subjects and `cardano:hasOutput` objects to UTxO IRIs.
- [X] T056-S1 - Promote hash and credential identifier nodes to `urn:cardano:id:*` IRIs across body, witness, cert, governance, native-script, and overlay emission.
- [X] T056-S1 - Apply universal transaction-id scoping to remaining structural blank nodes and keep address-decomposition nodes credential-scoped.
- [X] T056-S1 - Add `CatMergeCompositionSpec` proving concatenated Turtle joins a spending input to the producing output.
- [X] T056-S1 - Regenerate all tx-graph `expected.ttl` goldens with `EMIT_GOLDEN_REGEN=1`.
- [X] T056-S1 - Confirm canonical vocabulary fixtures did not need regeneration.
- [X] T056-S1 - Search and update case-study query files that name old `_:hash_*` or `_:cred_*` labels directly.
- [X] T056-S1 - Extend `gate.sh` task validation for `T056-S1`.
- [X] T056-S1 - Verify unit tests, Nix checks, MkDocs strict build, and `./gate.sh origin/main..HEAD`.
- [X] T056-S1 - Commit as `feat(emit): promote content-addressed bnodes to IRIs for cross-response composability` with `Tasks: T056-S1`.
