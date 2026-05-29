# Changelog

## Unreleased

## [0.2.5.0](https://github.com/lambdasistemi/cardano-ledger-rdf/compare/v0.2.4.0...v0.2.5.0) (2026-05-29)

### Features

* **demo:** end-to-end pipeline demo with rules + blueprints + cross-tx SPARQL on real mainnet (#62) ([cd7a9dd](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/cd7a9dd3d86572a3623e69145d3f632ed27e7e1b))

### Documentation

* **demo:** per-scope value-out and per-settlement swap-rate queries; wallet outflow ties to `SUM(cardano:hasFee)` exactly (#64) ([9f15abd](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/9f15abdea76bfa5804e9b718d4b4c2da84088d28))
* **case-studies:** replace fantasies with verified SPARQL — drop fabricated `cardano:hasLatticeRole`, fix Q5 `amaru:` prefix and Q6 truncated bech32, correct fee narrative (`71ff129b` 1.572508 ADA, not the 4-of-4 contingency disburse), label sidecar analyses (#64) ([9f15abd](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/9f15abdea76bfa5804e9b718d4b4c2da84088d28))

## [0.2.4.0](https://github.com/lambdasistemi/cardano-ledger-rdf/compare/v0.2.3.0...v0.2.4.0) (2026-05-29)

### Features

* **rules:** TxId + GovActionId leaf types for keys+bytes shape (#38) ([ab11c43](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/ab11c43131a0c94865d48dcd31463ad33e85a326))
* **vocab:** port TTL + OWL 2 RL validation gate from cardano-knowledge-maps (closes #40) (#43) ([0df38e5](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/0df38e59181ef56fba71c44b8e5220657bf75107))
* **tx:** typed native_script tree walker (multisig + timelocks) (#48) ([02a9f04](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/02a9f04fc166e815c4a860b8f99ff39d378611fb))
* **tx:** emit auxiliary data body + isValid flag (#51) ([6933c45](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/6933c45cd91197f05adaa673b928dfcbe66a8065))
* **tx:** typed certificate tree walker (stake + DRep + pool + committee) (#52) ([8257e48](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/8257e48fa240612db7636d85eede823509e592bc))
* **tx:** emit body fields 21 (current_treasury_value) and 22 (donation) (#53) ([3e264be](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/3e264bed40702e4a4e93c6bcb4f616c2025c5834))
* **tx:** typed governance-action walker (parameter_change + update_committee + new_constitution + hard_fork_initiation) (#54) ([8a2e95c](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/8a2e95c78d19e8a72c8fc3d5d09c2502b18593c1))
* **emit:** promote content-addressed bnodes to IRIs for cross-response composability (#57) ([4ef6b1a](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/4ef6b1a46d721411616c6b2f12c943d995502ad4))
* **tx-graph:** remove batch mode; single-CBOR-in, single-Turtle-out (closes #59) (#60) ([ba271f7](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/ba271f7653bc1d1bc8049141e89759af13766b90))

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
