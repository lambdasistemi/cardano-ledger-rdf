# Plan — Typed governance-action walker

## Tech Stack

- Haskell library package `cardano-ledger-rdf`
- `src/Cardano/Tx/Graph/Emit/Project.hs` for proposal dispatch
- `src/Cardano/Tx/Graph/Emit/GovAction.hs` for the focused action walker
- `src/Cardano/Tx/Graph/Emit/Vocab.hs` plus `vocab/cardano/transactions.ttl` for term coverage
- Golden fixtures under `test/fixtures/tx-graph`

## Slices

### Slice T005-S1 — ParameterChange

Add the typed action walker for constructor id `0`, covering optional prior action, protocol-parameter update fields, execution costs/limits, voting thresholds, and optional policy hash.

### Slice T006-S1 — UpdateCommittee

Add typed committee-update emission for constructor id `4`, including prior action, removals, additions with term limits, and new quorum.

### Slice T007-S1 — NewConstitution and HardForkInitiation

Add typed emission for constructor ids `5` and `1`, including constitution anchor/guardrail script and protocol-version major/minor fields.

## Verification

Regenerate the four new goldens, run the local unit suite, run the Nix checks required by the worker brief, and finish with the commit gate over `origin/main..HEAD`.
