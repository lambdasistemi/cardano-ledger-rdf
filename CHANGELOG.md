# Changelog

## Unreleased

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
