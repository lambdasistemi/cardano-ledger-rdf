# Changelog

## Unreleased

### Added

* **tx-graph:** `--provider koios|blockfrost|http` (with `--token` /
  `--url`) fetches the input CBOR by txid from an HTTP indexer. The
  default `--provider file` keeps the positional argument as a local
  CBOR path. Fetched output is byte-identical to the file path, so
  lattices stay composable.

### Removed

* **tx-graph:** remove batch-mode `--in-dir` and `--out-dir`; compose
  multi-transaction lattices with shell loops and Turtle concatenation.
* **tx-fetch:** retire the standalone closure fetcher; its role is now
  `tx-graph --provider`.

## [0.2.3.0](https://github.com/lambdasistemi/cardano-ledger-rdf/compare/v0.2.2.0...v0.2.3.0) (2026-05-27)

### Features

* **vocab:** import transactions.ttl + serve at /vocab/cardano (IRI still old) ([bd33594](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/bd335946cda439966bb50cd97267f6e05a648c96))
* **vocab:** re-host vocab IRI to cardano-ledger-rdf ([fcc4121](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/fcc4121cfe1dab2aa8825198cd99e077e34c382c))
* **emitter:** typed gov_action_id sub-block on votes (mirror TxOutRef pattern) ([2bab0dd](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/2bab0dd5f4a41452b0f8119cc8283c476aa39652))
* **emitter:** typed proposal_procedure shell (deposit + return_address + anchor) ([69836d0](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/69836d08d89f64cfe569254c26631dc7e0922dae))
* **emitter:** typed TreasuryWithdrawals body (recipient + lovelace + guard policy) ([67da0a1](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/67da0a1cf43c38b4cd0445d14ac1ba51779f4161))
* **emitter:** tx-graph lattice-mode --in-dir + --out FILE (single merged Turtle) ([e9b7a95](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/e9b7a9525564a3dc5846c96b735e18698940c73b))

### Bug Fixes

* **ci:** release-planner back to ubuntu-latest ([777f494](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/777f49464f18284d7a53e439fac380a5d015d2d9))

## [0.2.2.0](https://github.com/lambdasistemi/cardano-ledger-rdf/releases/tag/v0.2.2.0) (2026-05-26)

### Features

* Initial `cardano-ledger-rdf` repository extraction from the graph/RDF surface of `cardano-tx-tools`.
* Ship the RDF pipeline executables: `tx-fetch`, `tx-graph`, and `tx-view`.
* Keep `tx-graph` as a pure local transformation over operator rules plus transaction CBOR lattices.
* Keep `tx-view` as the packaged projection layer over generated Turtle graphs.
* Port Linux AppImage/DEB/RPM and Darwin/Homebrew release automation for the three RDF executables only.

### Removed

* Do not ship `tx-inspect`, `tx-diff`, `tx-sign`, `tx-validate`, or `cardano-tx-generator` from this repository.
* Drop the node-to-client resolver sublibrary and generator sublibrary from this package.

### Notes

`cardano-tx-tools` remains the downstream home for generic transaction
applications. It may depend on this repository when those applications
consume `tx-graph` output.
