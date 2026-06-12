# CLAUDE.md

The agent guide for this repository is **[AGENTS.md](AGENTS.md)** — what
the repo is, how to build/test/run it, and the skills under `skills/`.
Start there.

The sections below are managed automatically by Spec Kit
(`.specify/scripts/bash/update-agent-context.sh`); leave them in place.

## Active Technologies
- Haskell, GHC 9.12.3 (`haskell.nix`, `ghc9123`) + `cardano-ledger-core` (`TxAuxData ConwayEra`), `Cardano.Ledger.Metadata` (`Metadatum(..)`), the in-repo Emit DSL (`Cardano.Tx.Graph.Emit.*`: `Triple`/`Subject`/`Object`/`tellTriple`/`vocabCurie`/`BnodeName`), `bytestring`, `text` (062-tx-metadata-decode)
- N/A — pure emission over the already-decoded `TxAuxData` value (062-tx-metadata-decode)

## Recent Changes
- 062-tx-metadata-decode: Added Haskell, GHC 9.12.3 (`haskell.nix`, `ghc9123`) + `cardano-ledger-core` (`TxAuxData ConwayEra`), `Cardano.Ledger.Metadata` (`Metadatum(..)`), the in-repo Emit DSL (`Cardano.Tx.Graph.Emit.*`: `Triple`/`Subject`/`Object`/`tellTriple`/`vocabCurie`/`BnodeName`), `bytestring`, `text`
