# Tasks: depend on cardano-tx-tools:tx-build, delete the local builder copy

**Branch**: `refactor/86-tx-build-dependency` · **Plan**: ./plan.md

## Slice S1 — README integration-policy paragraph

- [X] T086-S1 Add the "Relationship to cardano-tx-tools" policy to
  README.md (single source of truth = tx-build, test-suite-only dep
  here; cardano-tx-tools consumes cq-rdf at the CLI boundary, never by
  linking this library); gate green; commit
  `docs: record the CLI-boundary integration policy with cardano-tx-tools`.

## Slice S2 — inline ConwayTx, delete Cardano.Tx.Ledger

- [X] T086-S2 Move `ConwayTx` to `Cardano.Tx.Decode` (exported, with
  haddock); retarget every in-repo `import Cardano.Tx.Ledger` to
  `Cardano.Tx.Decode`; delete `src/Cardano/Tx/Ledger.hs` and its
  exposed-modules entry; full gate green; goldens byte-identical;
  commit `refactor: inline ConwayTx into Cardano.Tx.Decode, drop Cardano.Tx.Ledger`.

## Slice S3 — pin tx-build, atomic swap + deletion (BLOCKED by cardano-tx-tools#127)

- [X] T086-S3 Pin cardano-tx-tools at the post-#127 SHA
  (`source-repository-package` + nix32 `--sha256:` comment, plus
  `-build-node-tools` flag stanza if the solver needs it); add
  `cardano-tx-tools:tx-build` to test-suite build-depends; delete
  `src/Cardano/Tx/{Build,Balance,Evaluate,Witnesses,Deposits,Scripts,Credentials,Inputs}.hs`,
  `test/Cardano/Tx/BuildSpec.hs`, `test/Cardano/Tx/Build/MinUtxoSpec.hs`
  and their cabal entries; adapt fixture call sites only if the
  reconciled API demands it; full gate green; goldens byte-identical;
  commit `refactor: swap the local builder copy for cardano-tx-tools:tx-build`.

## Finalization

- [ ] T086-F PR body audit (living document), label + assignee set,
  CI green, mark ready, ask parent for merge confirmation via Q-file.
