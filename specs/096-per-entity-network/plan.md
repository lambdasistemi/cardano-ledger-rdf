# Implementation Plan: per-entity network literals

**Branch**: `feat/per-entity-network` | **Date**: 2026-06-29 |
**Spec**: [spec.md](spec.md)

## Summary

Add a new flat `cardano:network` predicate for network-bearing entities in the
body graph. Keep `cardano:networkId` as the optional body-root field, and emit
the new literal additively on address decomposition subjects and existing
account-bearing cluster subjects.

## Technical Context

**Language/Version**: Haskell GHC 9.12.3  
**Primary Modules**: `Cardano.Tx.Graph.Emit.Project`,
`Cardano.Tx.Graph.Emit.Vocab`  
**Vocabulary Source**: `vocab/cardano/transactions.ttl` and generated
canonical vocab fixture  
**Testing**: Hspec golden tests via `just unit`; local gate through `just ci`

## Implementation Shape

1. Add `TermNetwork` to `VocabTerm`, `vocabIri`, and therefore `vocabCurie`.
2. Declare `cardano:network` in `vocab/cardano/transactions.ttl` with integer
   range and a description for entity/address/account network values.
3. Preserve existing `TermNetworkId` and `emitNetworkId` semantics.
4. Carry `Network` through `AddrEntry` and emit:

   ```ttl
   _:...Addr a cardano:Address ;
     cardano:bech32 "...";
     cardano:network 0 ;
     ...
   ```

5. Add a small helper that emits `cardano:network (networkToWord8 network)` on
   a supplied subject. Use it for:
   - `emitAddrEntry` address subjects.
   - `emitWithdrawalCluster` withdrawal subjects from `AccountAddress`.
   - `emitProposalShell` proposal subjects from the return `AccountAddress`.
   - `emitTreasuryWithdrawal` proposal withdrawal target subjects.
6. Regenerate goldens using `EMIT_GOLDEN_REGEN=1` for the emit golden suite.
7. Regenerate/refresh canonical vocabulary fixtures using the existing vocab
   gate/generation path if the first vocab gate reports drift.

## Owned Files For Slice

- `tx-rdf-core/src/Cardano/Tx/Graph/Emit/Vocab.hs`
- `tx-rdf-core/src/Cardano/Tx/Graph/Emit/Project.hs`
- `vocab/cardano/transactions.ttl`
- `test/fixtures/tx-graph/**/expected*.ttl`
- `test/fixtures/canonical-vocab/derived.ttl`
- Existing focused test files only if the driver needs an assertion stronger
  than the golden diff:
  `test/Cardano/Tx/Graph/EmitGoldenSpec.hs` or nearby emit specs.

## Forbidden Scope

- No downstream inspector code or repin.
- No consumer rebuild.
- No removal or rename of `cardano:networkId`.
- No unrelated fixture churn, view changes, dependency changes, or cabal
  metadata changes.

## Verification Plan

Run in `nix develop --quiet`:

- RED: `just unit match="Cardano.Tx.Graph.Emit joint Turtle goldens"`
- GREEN focused: same command after implementation and regen.
- `just vocab-validate`
- `just vocab-owl-smoke`
- `just vocab-accessibility`
- `just format`
- `just hlint`
- `./gate.sh`
- Final ticket-owner verification: `just ci`

## Navigator Checks

- Confirm the golden fixture diff is additive: `cardano:network` additions and
  expected vocab/canonical-vocab updates only.
- Confirm at least one testnet address node has `cardano:network 0`.
- Confirm at least one mainnet address node has `cardano:network 1`.
- Confirm `cardano:networkId` remains present only for transaction body
  network-id emission and is not reused for per-entity values.

## Complexity Tracking

No constitution violations are planned. The vocabulary change is intentional
and contained in this single slice.
